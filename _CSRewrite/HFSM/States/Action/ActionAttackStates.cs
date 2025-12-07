using Godot;
using System;

namespace CharacterControl
{
    public abstract class ActionAttackStates : HFSMState<HFSMCharacter3D>
    {
        protected float Timer;
        protected bool AttackQueued;
        
        // Configuration per attack
        protected abstract float Duration { get; }
        protected abstract float DamagePoint { get; } // When hitbox activates
        protected virtual float CancelWindowStart { get; } = 0f;  // When we can dash/combo out
        protected abstract Type NextComboState { get; }
        protected abstract StringName AnimName { get; }

        public override void Enter()
        {
            Timer = 0;
            AttackQueued = false;
            
            // Request Animation (Action Channel, High Priority)
            Agent.AnimArbiter.Request(AnimationChannel.Action, AnimName, 1.0f, true);
            
            // Optional: slight forward step (Root Motion emulation)
            Agent.Velocity += Agent.Visuals.GlobalBasis.Z * 2.0f; 
        }

        public override void Update(double delta)
        {
            // Note: We usually DO NOT call Parent.Update() here.
            // Why? Because Action_Root might try to switch us to "ReadyAirbourne" if we jump.
            // But we are attacking! We want to finish the attack even if we fall off a ledge.
            
            Timer += (float)delta;

            if (Timer >= Duration)
            {
                if (AttackQueued)
                    Machine.ChangeState(NextComboState); // Next in chain
                else
                    Machine.ChangeState<Action_Ready>();
            }
        }

        public override bool HandleEvent(ActionEvent evt)
        {
            // Buffer the next attack
            if (evt.Type == ActionEvent.ActionType.Attack)
            {
                // Only allow buffering if we are past a certain point
                if (Timer > 0.1f) AttackQueued = true; 
                return true;
            }

            // Animation Canceling (Dash/Block)
            if (Timer > CancelWindowStart)
            {
                if (evt.Type == ActionEvent.ActionType.Dash)
                {
                    Machine.ChangeState<Action_Dash>();
                    return true;
                }
            }
            
            return false;
        }

        public override LocomotionInstruction GetLocomotionInstruction()
        {
            // Priority 100 (Action).
            // VelocityMode.Dampen with 0 velocity = Friction Stop.
            // LockMovement = true prevents the Locomotion FSM from applying move inputs.
            // FacingMode.Keep = Don't rotate while swinging.
            
            var instr = new LocomotionInstruction(100, VelocityMode.Dampen)
                .WithVelocity(Vector3.Zero);
                
            // Allow slight rotation adjustment during Windup phase only (Dark Souls style)
            if (Timer < DamagePoint)
            {
                // If player is holding input, rotate towards it slowly
                instr = instr.WithFacingMode(FacingMode.FaceMovement); 
            }
            else
            {
                instr = instr.WithFacingMode(FacingMode.Keep);
            }

            return instr;
        }
    }
}