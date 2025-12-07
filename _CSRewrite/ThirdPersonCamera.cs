using Godot;

namespace CharacterControl{
    public partial class ThirdPersonCamera : Node3D
    {
        [ExportGroup("Targeting")]
        [Export] public Node3D FollowTarget { get; set; }
        [Export] public Vector3 TargetOffset { get; set; } = new Vector3(0, 1.8f, 0); // Shoulder/Head height

        [ExportGroup("Settings")]
        [Export] public float MouseSensitivity { get; set; } = 0.003f;
        [Export] public float SmoothFactor { get; set; } = 20.0f;
        [Export] public float Distance { get; set; } = 4.0f;
        [Export] public Vector2 PitchLimits { get; set; } = new Vector2(-70, 75);

        // Nodes
        private SpringArm3D _springArm;
        private Camera3D _cam;

        // State
        private Vector2 _mouseInput;
        private float _currentPitch;
        private float _currentYaw;

        public override void _Ready()
        {
            _springArm = GetNode<SpringArm3D>("SpringArm3D");
            _cam = _springArm.GetNode<Camera3D>("Camera3D");
            
            // Detach from parent if needed to prevent jitter, 
            // or ensure this node is a sibling of the character, not a child.
            TopLevel = true; 
            
            Input.MouseMode = Input.MouseModeEnum.Captured;
            
            // Initialise based on current rotation
            Vector3 rot = RotationDegrees;
            _currentPitch = rot.X;
            _currentYaw = rot.Y;
        }

        public override void _UnhandledInput(InputEvent @event)
        {
            if (@event is InputEventMouseMotion mm)
            {
                _mouseInput += mm.Relative;
            }
        }

        public override void _PhysicsProcess(double delta)
        {
            if (FollowTarget == null) return;

            // 1. Follow Position (Instant or smoothed)
            // Using GlobalPosition directly is best for PhysicsProcess to prevent jitter
            GlobalPosition = FollowTarget.GlobalPosition + TargetOffset;

            // 2. Process Rotation Input (Smoothed)
            if (_mouseInput.LengthSquared() > 0.001f)
            {
                _currentYaw -= _mouseInput.X * MouseSensitivity * (float)delta * 50f; // Scale for feel
                _currentPitch -= _mouseInput.Y * MouseSensitivity * (float)delta * 50f;
                _currentPitch = Mathf.Clamp(_currentPitch, PitchLimits.X, PitchLimits.Y);
                
                _mouseInput = Vector2.Zero; // Consume
            }

            // 3. Apply Rotation
            // We rotate the SpringArm for Pitch, and the Pivot (this node) for Yaw
            // This prevents the camera rolling weirdly.
            Rotation = new Vector3(0, Mathf.DegToRad(_currentYaw), 0);
            _springArm.Rotation = new Vector3(Mathf.DegToRad(_currentPitch), 0, 0);
            _springArm.SpringLength = Distance; // Apply zoom logic here if needed
        }

        // Helper for the InputController
        public Vector3 GetForwardBasis()
        {
            // We want the direction the camera is facing, but FLAT on the ground (Y=0)
            // The Pivot (this node) only rotates on Y, so its Basis.Z is perfect.
            return -GlobalTransform.Basis.Z; 
        }
        
        public Vector3 GetRightBasis()
        {
            return GlobalTransform.Basis.X;
        }
    }
}