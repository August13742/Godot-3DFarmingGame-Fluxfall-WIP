using Godot;
using System;
using System.Collections.Generic;


namespace CharacterControl
{
    public partial class HFSMCharacter3D:CharacterBody3D
    {
        [Export] public bool DebugMode = false;
        //components
        [Export] public AnimationPlayer Animator {get;private set;}
        public Node3D Visuals {get;private set;}

        
        [ExportCategory("Locomotion")]
        [Export] public float MoveSpeed { get; private set; } = 8.0f;
        [Export] public float SprintSpeed { get; private set; } = 12.0f;
        [Export] public float AngularSpeed{get;private set;} = 15f;

        // Acceleration: How fast we reach Target Speed (Time to reach ~63% of target)
        // Lower is snappier, Higher is floatier.
        [Export] public float AccelerationTime { get; private set; } = 0.1f; 
        [Export] public float DecelerationTime { get; private set; } = 0.15f; 
        [Export] public float AirControlTime { get; private set; } = 0.8f; // Harder to turn in air
        [Export] public float Gravity{get;private set;} = 25f;
        [Export] public float TerminalVelocity { get; private set; } = 50f;

        // --- INTERNAL SYSTEMS ---
        public ControlInterface InputInterface { get; private set; } = new();
        public HFSM<HFSMCharacter3D> ActionHFSM { get; private set; }
        public HFSM<HFSMCharacter3D> LocomotionHFSM { get; private set; }
        public LocomotionArbiter LocoArbiter { get; private set; } = new();
        public AnimationArbiter AnimArbiter { get; private set; }

        public bool IsSprinting => LocomotionHFSM.CurrentState is Locomotion_Sprint;
        public bool IsAirborne => !IsOnFloor();

        public override void _Ready()
        {
            Visuals = GetNode<Node3D>("Visuals");
            AnimArbiter = new AnimationArbiter(Animator);
            // --- LOCOMOTION ---
            LocomotionHFSM = new HFSM<HFSMCharacter3D>(this, "Loco");
            if (DebugMode) LocomotionHFSM.DebugMode = true;
            // Create Parents
            var grounded = new Locomotion_Grounded();
            var airbourne = new Locomotion_Airbourne();
            LocomotionHFSM.AddState(grounded);
            LocomotionHFSM.AddState(airbourne);

            // Create Children (Inject Parent Type)
            LocomotionHFSM.AddState(new Locomotion_Idle(), typeof(Locomotion_Grounded));
            LocomotionHFSM.AddState(new Locomotion_Move(), typeof(Locomotion_Grounded));
            LocomotionHFSM.AddState(new Locomotion_Sprint(), typeof(Locomotion_Grounded));
            
            LocomotionHFSM.AddState(new Locomotion_Jump()); // Standalone or child of Grounded? 
                                                            // Usually standalone transition.

            LocomotionHFSM.Init(typeof(Locomotion_Idle));


            // --- ACTION ---
            ActionHFSM = new HFSM<HFSMCharacter3D>(this, "Action");
            if (DebugMode) ActionHFSM.DebugMode = true;

            // Create Parent
            var root = new Action_Root();
            ActionHFSM.AddState(root);

            // Create Children
            ActionHFSM.AddState(new Action_Ready(), typeof(Action_Root));
            // Attacks/Dash usually don't need the Root update logic (switching ready states)
            // so they can be root-level siblings
            ActionHFSM.AddState(new Action_Dash()); 
            ActionHFSM.AddState(new Action_Attack1());
            // ActionHFSM.AddState(new Action_Attack2());

            ActionHFSM.Init(typeof(Action_Ready));
        }

        public override void _PhysicsProcess(double delta)
        {
            // 1. Process Input Events
            while (InputInterface.TryDequeueEvent(out var evt))
            {
                if (!ActionHFSM.HandleEvent(evt)) LocomotionHFSM.HandleEvent(evt);
            }

            // 2. Update FSMs
            ActionHFSM.Update(delta);
            LocomotionHFSM.Update(delta);

            // 3. Gather Instructions
            var actionCmd = ActionHFSM.GetInstruction();
            var locoCmd = LocomotionHFSM.GetInstruction();
            var statusCmds = new List<LocomotionInstruction> { locoCmd };

            // 4. Resolve Conflicts (Arbiter decides WHAT to do)
            var result = LocomotionArbiter.Resolve(this, actionCmd, statusCmds);

            // 5. Integrate Physics (Character decides HOW to do it)
            IntegrateMovement(result, delta);

            // 6. Animation
            AnimArbiter.Update();
        }
        private void IntegrateMovement(LocomotionArbiter.PhysicsResult request, double delta)
        {
            // A. Separate Vertical and Horizontal
            float yVel = Velocity.Y;
            Vector3 xzVel = new (Velocity.X, 0, Velocity.Z);

            // B. Apply Gravity (if not ignored)
            if (!request.IgnoreGravity)
            {
                yVel -= Gravity * (float)delta;
                yVel = Mathf.Max(yVel, -TerminalVelocity);
            }
            
            // C. Apply Impulses (e.g. Jump, Recoil) - Immediate Additive
            if (request.AccumulatedImpulse != Vector3.Zero)
            {
                Vector3 impulse = request.AccumulatedImpulse;
                // Add Y component to Y
                yVel += impulse.Y;
                // Add XZ component to XZ
                xzVel += new Vector3(impulse.X, 0, impulse.Z);
            }

            // D. Apply Horizontal Locomotion (The Motion Model)
            switch (request.VelMode)
            {
                case VelocityMode.SetImmediate:
                    // Dash / Teleport
                    xzVel = new Vector3(request.TargetVelocity.X, 0, request.TargetVelocity.Z);
                    if (request.TargetVelocity.Y != 0) yVel = request.TargetVelocity.Y;
                    break;

                case VelocityMode.Dampen:
                    // 1. Determine Target (XZ only)
                    Vector3 targetXZ = new Vector3(request.TargetVelocity.X, 0, request.TargetVelocity.Z);
                    
                    // 2. Determine "Halflife" (Acceleration tuning)
                    // If the request specifies a custom halflife, use it. Otherwise use defaults.
                    float smoothTime = request.CustomDamping > 0 ? request.CustomDamping : AccelerationTime;

                    // Contextual Tuning:
                    if (!IsOnFloor()) 
                    {
                        smoothTime = AirControlTime;
                    }
                    else if (targetXZ.LengthSquared() < 0.01f) 
                    {
                        // We are trying to stop
                        smoothTime = DecelerationTime;
                    }

                    // 3. Exponential Decay (Frame-rate independent Lerp)
                    xzVel = MathsUtility.ExpDecay(xzVel, targetXZ, smoothTime, (float)delta);
                    break;
            }

            // E. Recombine and Move
            Velocity = new Vector3(xzVel.X, yVel, xzVel.Z);
            MoveAndSlide();

            // F. Apply Rotation
            if (request.ApplyRotation)
            {
                Vector3 rot = Visuals.Rotation;
                rot.Y = Mathf.LerpAngle(rot.Y, request.TargetRotationY, AngularSpeed * (float)delta);
                Visuals.Rotation = rot;
            }
        }
    }
}