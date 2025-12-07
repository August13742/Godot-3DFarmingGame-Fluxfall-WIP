using Godot;

namespace CharacterControl
{
    public class Locomotion_Airbourne : HFSMState<HFSMCharacter3D>
    {
        public override void Enter()
        {
            Agent.AnimArbiter.Request(AnimationChannel.Locomotion, "FallLoop", 1.0f);
        }

        public override void Update(double delta)
        {
            // 1. Landing Check
            if (Agent.IsOnFloor() && Agent.Velocity.Y <= 0) // Only land if falling/flat
            {
                // Decide sub-state based on input
                if (Agent.InputInterface.WorldMovementIntent.LengthSquared() > 0.01f)
                    Machine.ChangeState<Locomotion_Move>();
                else
                    Machine.ChangeState<Locomotion_Idle>();
                return;
            }
        }

        public override LocomotionInstruction GetLocomotionInstruction()
        {
            // Generic Air Control (Low friction, moderate control)
            return new LocomotionInstruction(0, VelocityMode.Dampen)
                .WithVelocity(Agent.InputInterface.WorldMovementIntent * (Agent.MoveSpeed * 0.5f))
                .WithFacingMode(FacingMode.FaceMovement);
        }
    }
}