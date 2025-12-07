using Godot;

namespace CharacterControl
{
    public partial class PlayerInputController : Node
    {
        [Export] public HFSMCharacter3D Character {get; private set;}
        [Export] public Camera3D _camera; // Assign camera
        [Export] public Vector2 RawInput{get;private set;} // Assign camera

        public override void _PhysicsProcess(double delta)
        {
            Character.InputInterface.Reset();

            // 1. Get Raw Input
            RawInput = Input.GetVector("move_left", "move_right", "move_forward", "move_backward");
            
            if (RawInput.LengthSquared() > 0.01f)
            {
                // 2. Camera Relative Math
                Vector3 camForward = _camera.GlobalBasis.Z;
                Vector3 camRight = _camera.GlobalBasis.X;

                camForward.Y = 0; camForward = camForward.Normalized();
                camRight.Y = 0; camRight = camRight.Normalized();

                Vector3 worldIntent = (camForward * RawInput.Y) + (camRight * RawInput.X);
                
                // 3. Feed the Interface
                Character.InputInterface.WorldMovementIntent = worldIntent;
            }

            // 4. Handle Actions
            
        }
        public override void _Input(InputEvent @event)
        {
            if (Input.IsActionJustPressed("attack")) 
                Character.InputInterface.QueueEvent(new ActionEvent(ActionEvent.ActionType.Attack));
                
            if (Input.IsActionJustPressed("dash"))
                Character.InputInterface.QueueEvent(new ActionEvent(ActionEvent.ActionType.Dash));

        }
    }
}