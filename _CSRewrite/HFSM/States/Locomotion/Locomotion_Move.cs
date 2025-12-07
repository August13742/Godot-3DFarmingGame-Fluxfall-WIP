using Godot;

namespace CharacterControl
{
    public class Locomotion_Move : HFSMState<HFSMCharacter3D>
    {
        public override void Enter()
        {
            Parent?.Enter();
            Agent.AnimArbiter.Request(AnimationChannel.Locomotion, "Walk", 1.0f);
        }

        public override void Update(double delta)
        {
            Parent?.Update(delta);
            if (Machine.CurrentState != this) return;


            // Logic: Stop or Sprint
            if (Agent.InputInterface.WorldMovementIntent.LengthSquared() < 0.01f)
            {
                Machine.ChangeState<Locomotion_Idle>();
                return;
            }

            if (Agent.InputInterface.IsSprintHeld)
            {
                Machine.ChangeState<Locomotion_Sprint>();
            }
        }

        public override LocomotionInstruction GetLocomotionInstruction()
        {
            // Priority 1
            // Target: Input * Speed
            // Damping: 0 (Use Blackboard default Accel/Decel)
            return new LocomotionInstruction(1, VelocityMode.Dampen)
                .WithVelocity(Agent.InputInterface.WorldMovementIntent * Agent.MoveSpeed)
                .WithFacingMode(FacingMode.FaceMovement);
        }
    }
}
