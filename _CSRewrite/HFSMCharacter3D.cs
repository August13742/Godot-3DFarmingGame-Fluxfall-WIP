using Godot;
using System;
using System.Collections.Generic;

namespace CharacterControl
{
    public partial class HFSMCharacter3D:CharacterBody3D
    {
        //components
        [Export] public AnimationPlayer Animator {get;private set;}
        public Node3D Visuals {get;private set;}

        //brain
        public ControlInterface InputInterface{get;private set;} = new();

        // HFSMs
        public HFSM<HFSMCharacter3D> ActionHFSM {get;private set;}
        public HFSM<HFSMCharacter3D> LocomotionHFSM {get;private set;}

        // arbiters
        public LocomotionArbiter LocoArbiter{get;private set;} = new();
        public AnimationArbiter AnimArbiter{get;private set;}
        [Export]public float Gravity{get;private set;} = 9.8f;
        [Export]public float MoveSpeed{get;private set;} = 9.8f;
        [Export]public float SprintSpeed{get;private set;} = 9.8f;

        public bool IsSprinting => LocomotionHFSM.CurrentState is Locomotion_Sprint;
        public bool IsAirborne => !IsOnFloor();

        public override void _Ready()
        {
            AnimArbiter = new AnimationArbiter(Animator);
            // --- LOCOMOTION ---
            LocomotionHFSM = new HFSM<HFSMCharacter3D>(this, "Loco");
            
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
            // 1. Process Input Queue
            // Feed events to Action FSM first. If not consumed, feed to Locomotion.
            while (InputInterface.TryDequeueEvent(out var evt))
            {
                if (!ActionHFSM.HandleEvent(evt))
                {
                    LocomotionHFSM.HandleEvent(evt);
                }
            }

            // 2. Update FSM Logic
            ActionHFSM.Update(delta);
            LocomotionHFSM.Update(delta);

            // 3. Gather Instructions (The "Ask")
            var actionCmd = ActionHFSM.GetInstruction();
            var locoCmd = LocomotionHFSM.GetInstruction();
            
            // We treat Locomotion FSM as the "Base Status" in this architecture, 
            // or we can treat it as a secondary source. 
            // Ideally, LocomotionHFSM provides the "Default" movement, 
            // and ActionHFSM provides "Overrides" (Dash, Rooting).
            // Let's bundle locoCmd into the "status commands" list for the Arbiter 
            // OR pass it as a low-priority default.
            
            var statusCmds = new List<LocomotionInstruction>(); 
            statusCmds.Add(locoCmd); // Add locomotion state output

            // 4. Resolve Physics (The "Solver")
            var result = LocomotionArbiter.Resolve(this, actionCmd, statusCmds, delta);

            // 5. Apply Physics
            Velocity = result.Velocity;
            if (result.ApplyRotation)
            {
                // Rotate the Visuals node, not the physics collider (usually safer) 
                // OR rotate the whole body if cylinder collider.
                Vector3 rot = Visuals.Rotation;
                rot.Y = Mathf.LerpAngle(rot.Y, result.TargetRotationY, 15f * (float)delta);
                Visuals.Rotation = rot;
            }
            
            // Custom gravity logic here if not handled in Arbiter
            MoveAndSlide();

            // 6. Update Animation
            AnimArbiter.Update();
        }
    }
}