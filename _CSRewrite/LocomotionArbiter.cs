using Godot;
using System.Collections.Generic;

namespace CharacterControl
{
    public class LocomotionArbiter
    {
        public struct PhysicsResult
        {
            public Vector3 Velocity;
            public float TargetRotationY; //z,x rotation rarely matters
            public bool ApplyRotation;
        }
        private const int PRIORITY_THRESHOLD_LOCK = 100;
        
        public PhysicsResult Resolve(
        HFSMCharacter3D character, LocomotionInstruction actionCmd, List<LocomotionInstruction> statusCmd, double delta )
        {
            var winner = actionCmd;
            // Status effects (Knockbacks) usually win if they have high priority (Stun)
            // Or they just add forces. Let's assume StatusCmds are purely additive forces 
            // OR high-priority overrides (like being frozen).
            foreach (var cmd in statusCmd)
            {
                if (cmd.Priority > winner.Priority) winner = cmd;
            }
            // 2. Accumulate Forces (Impulses)
            // We accumulate impulses from ALL commands, not just the winner, 
            // to ensure a Recoil doesn't cancel out a Knockback entirely.
            Vector3 totalImpulse = Vector3.Zero;
            if (actionCmd.VelMode == VelocityMode.Accumulate) totalImpulse += actionCmd.TargetVelocity;
            foreach (var cmd in statusCmd)
            {
                if (cmd.VelMode == VelocityMode.Accumulate) totalImpulse += cmd.TargetVelocity;
            }

            PhysicsResult result = new PhysicsResult();
            Vector3 currentVel = character.Velocity;

            // 3. resolve velocity
            if (winner.VelMode == VelocityMode.Dampen)
            {
                // simple exponential decay
                float alpha = Mathf.Clamp(1.0f - Mathf.Pow(0.5f, (float)delta / winner.DampenHalfLife),0f,1f);
                result.Velocity = currentVel.Lerp(winner.TargetVelocity, alpha);
            }
            else
            {
                //default: preserve momentum
                result.Velocity = currentVel;
            }

            //add accumulated impulse
            result.Velocity += totalImpulse;

            // gravity
            if (!winner.IgnoreGravity)
            {
                result.Velocity.Y -= (float)delta * character.Gravity;
            }
            // 4. Resolve Rotation
            result.ApplyRotation = false;
            result.TargetRotationY = character.Rotation.Y;
            switch (winner.Facing)
            {
                case FacingMode.FaceMovement:
                    //only rotate if moving significantly
                    Vector3 flatVel = new(result.Velocity.X, 0, result.Velocity.Z);
                    if (flatVel.LengthSquared() > 0.1f)
                    {
                        result.TargetRotationY = Mathf.Atan2(flatVel.X, flatVel.Z);
                        result.ApplyRotation = true;
                    }
                    break;
                case FacingMode.FaceTarget:
                    if (winner.TargetNode != null && GodotObject.IsInstanceValid(winner.TargetNode))
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
                        result.TargetRotationY = Mathf.Atan2(diff.X,diff.Z);
                        result.ApplyRotation = true;
                    }
                    break;
            }
            return result;

        }
    }
}