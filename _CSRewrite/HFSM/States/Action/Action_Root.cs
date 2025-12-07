

namespace CharacterControl
{
    public class Action_Root : HFSMState<HFSMCharacter3D>
    {
        public override void Update(double delta)
        {
            // Logic: Swap between Ground/Air Ready states passively
            // We only do this if the CURRENT state is one of the Ready states.
            
            bool isGrounded = Agent.IsOnFloor();
            var currentType = Machine.CurrentState.GetType();

            if (currentType == typeof(Action_Ready) && !isGrounded)
            {
                Machine.ChangeState<Action_Ready_Airbourne>();
            }
            else if (currentType == typeof(Action_Ready_Airbourne) && isGrounded)
            {
                Machine.ChangeState<Action_Ready>();
            }
        }
    }
}