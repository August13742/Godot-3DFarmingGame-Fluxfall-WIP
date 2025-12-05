using Godot;
using System;
namespace CharacterControl
{
#region Locomotion Definitions
    [Flags] public enum AxisMask { None = 0, X = 1, Y = 2, Z = 4, XZ = 5, XYZ = 7 }
    public enum FacingMode 
    { 
        Keep,           // Don't touch rotation
        FaceMovement,   // Rotate towards Velocity (Standard locomotion)
        FaceTarget,     // Rotate towards a specific Node3D (Combat lock-on)
        FacePosition,   // Rotate towards a specific Vector3 (Mouse aim/Skillshot)
    }
    public enum VelocityMode
    {
        None,           // Apply nothing (Standard friction applies)
        SetImmediate,   // Hard override (Teleport/Snap)
        Dampen,         // Smooth stop (Friction)
        Accumulate      // Additive (Knockback/Explosions)
    }
    public static class AnimationChannel
    {
        public const int Locomotion = 0;
        public const int Action = 1;
        public const int Reaction = 2; //hitstun
        public const int Cinematic = 3;
        public const int Count = 4; // tootal size
    }
#endregion
public record struct LocomotionInstruction
{
    public int Priority           { get; init; }
    public VelocityMode VelMode   { get; init; }
    public Vector3 TargetVelocity { get; init; }
    public AxisMask DampenAxis    { get; init; }
    public float DampenHalfLife   { get; init; }
    public bool IgnoreGravity     { get; init; }

    public FacingMode Facing          { get; init; }
    public Vector3? ExplicitFacingPos { get; init; }
    public Node3D TargetNode          { get; init; }

    public bool LockMovement { get; init; }
    public float SpeedScale  { get; init; }

    public LocomotionInstruction(int priority, VelocityMode velMode = VelocityMode.None)
    {
        Priority = priority;
        VelMode = velMode;
        TargetVelocity = Vector3.Zero;
        DampenAxis = AxisMask.XZ;
        DampenHalfLife = 0.1f;
        IgnoreGravity = false;
        Facing = FacingMode.FaceMovement;
        ExplicitFacingPos = null;
        TargetNode = null;
        LockMovement = false;
        SpeedScale = 1.0f;
    }

    public LocomotionInstruction WithVelocity(Vector3 v)
        => this with { TargetVelocity = v };

    public LocomotionInstruction WithImpulse(Vector3 v)
        => this with { TargetVelocity = v, VelMode = VelocityMode.Accumulate };

    public LocomotionInstruction WithFacingPos(Vector3 pos)
        => this with { Facing = FacingMode.FacePosition, ExplicitFacingPos = pos };

    public LocomotionInstruction WithFacingTarget(Node3D target)
        => this with { Facing = FacingMode.FaceTarget, TargetNode = target };
}

}