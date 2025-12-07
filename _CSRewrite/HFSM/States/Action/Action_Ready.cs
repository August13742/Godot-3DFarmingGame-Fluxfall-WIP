using Godot;

namespace CharacterControl
{
    public class Action_Ready : HFSMState<HFSMCharacter3D>
    {
        public override void Update(double delta)
        {
            // --- BOILERPLATE START ---
            Parent?.Update(delta);
            if (Machine.CurrentState != this) return;
            // --- BOILERPLATE END ---
        }

        public override bool HandleEvent(ActionEvent evt)
        {
            switch (evt.Type)
            {
                case ActionEvent.ActionType.Attack:
                    // Context Sensitivity
                    if (Agent.IsSprinting)
                    {
                        // Machine.ChangeState<Action_AttackSprint>();
                    }
                        
                    else 
                        Machine.ChangeState<Action_Attack1>();
                    return true;

                case ActionEvent.ActionType.Dash:
                    // Calculate Dash Direction here
                    var moveIntent = Agent.InputInterface.MovementIntent;
                    var dashDir = moveIntent.LengthSquared() > 0.01f ? moveIntent.Normalized() : -Agent.Visuals.GlobalBasis.Z;
                    
                    // Ideally pass this via a Blackboard/Property, simplified here:
                    // Agent.DesiredDashDirection = dashDir; 
                    
                    Machine.ChangeState<Action_Dash>();
                    return true;
            }
            return base.HandleEvent(evt);
        }

        // Returns Prio 0 (Do Nothing), letting Locomotion FSM control the character.
        public override LocomotionInstruction GetLocomotionInstruction() => new(0);
    }
}