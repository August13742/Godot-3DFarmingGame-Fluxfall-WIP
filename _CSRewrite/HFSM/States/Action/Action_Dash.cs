using Godot;

namespace CharacterControl
{
    public class Action_Dash : HFSMState<HFSMCharacter3D>
    {
        private double _timer;
        private const double DASHTIME = 0.2f;
        private Vector3 _dashVelocity;

        public override void Enter()
        {
            _timer = 0;
            
            // Calculate dash vector (Logic moved here or passed via blackboard)
            Vector3 moveIntent = Agent.InputInterface.MovementIntent;
            Vector3 dir = moveIntent.LengthSquared() > 0.01f 
                ? moveIntent.Normalized() 
                : -Agent.Visuals.GlobalTransform.Basis.Z; // Backstep

            _dashVelocity = dir * 20.0f; // Dash speed
        }

        public override void Update(double delta)
        {
            _timer += delta;
            if (_timer > DASHTIME)
            {
                Machine.ChangeState<Action_Ready>();
            }
        }

        public override LocomotionInstruction GetLocomotionInstruction()
        {
            // High Priority (100)
            // Set Velocity Immediately (Override gravity and friction)
            // Face the dash direction
            return new LocomotionInstruction(100, VelocityMode.SetImmediate)
                .WithVelocity(_dashVelocity)
                .WithFacingPos(Agent.GlobalPosition + _dashVelocity);
        }
    }
}