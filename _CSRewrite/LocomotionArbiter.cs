using Godot;
using System.Collections.Generic;

namespace CharacterControl
{
    public class LocomotionArbiter
    {
        public struct PhysicsResult
        {
            // The "Winner's" desired velocity state
            public Vector3 TargetVelocity;
            public VelocityMode VelMode;
            public bool IgnoreGravity;
            
            // If the winner provides specific tuning (e.g. ice, slow-motion), else 0
            public float CustomDamping; 

            // Sum of all one-shot forces this frame
            public Vector3 AccumulatedImpulse;

            // Rotation
            public float TargetRotationY;
            public bool ApplyRotation;
        }

        public static PhysicsResult Resolve(
            HFSMCharacter3D character, 
            LocomotionInstruction actionCmd, 
            List<LocomotionInstruction> statusCmds)
        {
            // 1. Determine Winner
            var winner = actionCmd;
            foreach (var cmd in statusCmds)
            {
                if (cmd.Priority > winner.Priority) winner = cmd;
            }

            // 2. Accumulate Impulses (From everyone, even losers)
            Vector3 totalImpulse = Vector3.Zero;
            if (actionCmd.VelMode == VelocityMode.Accumulate) totalImpulse += actionCmd.TargetVelocity;
            foreach (var cmd in statusCmds)
            {
                if (cmd.VelMode == VelocityMode.Accumulate) totalImpulse += cmd.TargetVelocity;
            }

            PhysicsResult result = new PhysicsResult
            {
                TargetVelocity = winner.TargetVelocity,
                VelMode = winner.VelMode,
                IgnoreGravity = winner.IgnoreGravity,
                CustomDamping = winner.DampenHalfLife, // Pass through
                AccumulatedImpulse = totalImpulse,
                ApplyRotation = false,
                TargetRotationY = character.Rotation.Y
            };

            // 3. Resolve Rotation Target
            switch (winner.Facing)
            {
                case FacingMode.FaceMovement:
                    // We check the Character's CURRENT velocity for rotation to look natural
                    Vector3 flatVel = new Vector3(character.Velocity.X, 0, character.Velocity.Z);
                    // Or check Input Intent if Velocity is zero (snappier turn-on-spot)
                    if (flatVel.LengthSquared() < 0.1f) 
                        flatVel = character.InputInterface.WorldMovementIntent;

                    if (flatVel.LengthSquared() > 0.1f)
                    {
                        result.TargetRotationY = Mathf.Atan2(flatVel.X, flatVel.Z);
                        result.ApplyRotation = true;
                    }
                    break;

                case FacingMode.FaceTarget:
                    if (GodotObject.IsInstanceValid(winner.TargetNode))
                    {
                        Vector3 diff = winner.TargetNode.GlobalPosition - character.GlobalPosition;
                        result.TargetRotationY = Mathf.Atan2(diff.X, diff.Z);
                        result.ApplyRotation = true;
                    }
                    break;

                case FacingMode.FacePosition:
                    if (winner.ExplicitFacingPos.HasValue)
                    {
                        Vector3 diff = winner.ExplicitFacingPos.Value - character.GlobalPosition;
                        result.TargetRotationY = Mathf.Atan2(diff.X, diff.Z);
                        result.ApplyRotation = true;
                    }
                    break;
            }

            return result;
        }
    }
}