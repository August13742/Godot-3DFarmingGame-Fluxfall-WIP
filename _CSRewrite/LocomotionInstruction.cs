using Godot;
namespace HFSM
{
    public struct LocomotionInstruction
    {
        public enum VelocityType { None, SetImmediate, Dampen }
        public enum FacingType { Keep, FaceMovement, FaceTarget, FaceExplicit }
        
        [Flags] public enum AxisMask { None = 0, X = 1, Y = 2, Z = 4, XZ = 5, XYZ = 7 }
        public enum Priority{LOW=0,ACTION=100,HIGH=200,STUN=500}

        // Data
        public int Priority;
        public bool LockMovement;
        public bool IgnoreGravity;
        
        // Physics
        public Vector3 AddImpulse; // Additive (Frame specific)
        public bool ImpulseRelativeToFacing;
        
        // Velocity Overrides
        public VelocityType VelocityCommand;
        public Vector3 VelocityTarget;
        public float VelocityDampingHalfLife;
        public AxisMask VelocityDampenAxis;
        
        // Facing
        public FacingType FacingPolicy;
        public Vector3 ExplicitFacingDirection;
        public bool ReverseFacing;
        
        // One-shot logic handling (State resets this, Arbiter consumes it)
        public bool FacingOneShot; 

        public float MaxSpeedScale;

        // Default Constructor Helper
        public static LocomotionInstruction Default()
        {
            return new LocomotionInstruction
            {
                Priority = PRIORITY_LOW,
                MaxSpeedScale = 1.0f,
                VelocityDampingHalfLife = 0.12f,
                VelocityDampenAxis = AxisMask.XZ,
                ImpulseRelativeToFacing = true
            };
        }
    }

    // 2. Locomotion Input (The "Resolved" result)
    public struct LocomotionInput
    {
        public bool AllowMovement;
        public Vector3 TotalImpulse;
        
        // Velocity Resolution
        public LocomotionInstruction.VelocityType VelocityCommand;
        public Vector3 VelocityTarget;
        public float VelocityDampingHalfLife;
        public LocomotionInstruction.AxisMask VelocityDampenAxis;
        public bool IgnoreGravity;
        
        // Facing Resolution
        public LocomotionInstruction.FacingType FacingPolicy;
        public Vector3 ExplicitFacingDirection;
        public bool ReverseFacing;
    }
}