using Godot;

namespace CharacterControl
{
    public class Locomotion_Jump : HFSMState<HFSMCharacter3D>
    {
        public override void Enter()
        {
            Agent.AnimArbiter.Request(AnimationChannel.Locomotion, "Jump", 1.0f);
        }

        public override void Update(double delta)
        {
            // Apply force for 1 frame then switch to air
            Machine.ChangeState<Locomotion_Airbourne>();
        }

        public override LocomotionInstruction GetLocomotionInstruction()
        {
            // Priority 10 to override any ground friction
            return new LocomotionInstruction(10, VelocityMode.Accumulate)
                .WithImpulse(Vector3.Up * 8.0f); // Jump Force
        }
    }
}