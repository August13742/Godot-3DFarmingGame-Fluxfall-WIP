using Godot;

namespace CharacterControl
{
    public class Locomotion_Idle : HFSMState<HFSMCharacter3D>
    {
        public override void Enter()
        {
            Parent?.Enter(); // Optional
            Agent.AnimArbiter.Request(AnimationChannel.Locomotion, "Idle", 1.0f);
        }

        public override void Update(double delta)
        {
            Parent?.Update(delta);
            if (Machine.CurrentState != this) return;


            // Logic: Start Moving
            if (Agent.InputInterface.WorldMovementIntent.LengthSquared() > 0.01f)
            {
                if (Agent.InputInterface.IsSprintHeld)
                    Machine.ChangeState<Locomotion_Sprint>();
                else
                    Machine.ChangeState<Locomotion_Move>();
            }
        }

        public override LocomotionInstruction GetLocomotionInstruction()
        {
            // Apply Friction
            return new LocomotionInstruction(1, VelocityMode.Dampen)
                .WithVelocity(Vector3.Zero)
                .WithFacingMode(FacingMode.Keep);
        }
    }
}