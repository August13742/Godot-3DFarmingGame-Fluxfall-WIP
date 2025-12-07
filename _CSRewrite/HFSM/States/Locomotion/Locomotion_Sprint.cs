using Godot;

namespace CharacterControl
{
    public class Locomotion_Sprint: HFSMState<HFSMCharacter3D>
    {
        public override void Enter()
            {
                Parent?.Enter();
                Agent.AnimArbiter.Request(AnimationChannel.Locomotion, "Sprint", 1.0f);
            }

            public override void Update(double delta)
            {
                Parent?.Update(delta);
                if (Machine.CurrentState != this) return;


                // Logic: Stop or Walk
                if (Agent.InputInterface.WorldMovementIntent.LengthSquared() < 0.01f)
                {
                    Machine.ChangeState<Locomotion_Idle>();
                    return;
                }

                if (!Agent.InputInterface.IsSprintHeld)
                {
                    Machine.ChangeState<Locomotion_Move>();
                }
            }

            public override LocomotionInstruction GetLocomotionInstruction()
            {
                // Standard Movement
                return new LocomotionInstruction(2, VelocityMode.Dampen)
                    .WithVelocity(Agent.InputInterface.WorldMovementIntent * Agent.SprintSpeed)
                    .WithFacingMode(FacingMode.FaceMovement); // Default facing
            }
        
    }
}