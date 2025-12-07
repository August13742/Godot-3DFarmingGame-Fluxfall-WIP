using Godot;

namespace CharacterControl
{
    public class Locomotion_Grounded : HFSMState<HFSMCharacter3D>
{
    public override void Update(double delta)
    {
        // 1. Check Transitions that apply to ALL grounded states
        if (!Agent.IsOnFloor())
        {
            Machine.ChangeState<Locomotion_Airbourne>();
            return;
        }

        // 2. Logic for "Being on Ground" (Gravity clamping)
        if (Agent.Velocity.Y < 0) 
            Agent.Velocity = Agent.Velocity with { Y = 0 };
    }

    public override bool HandleEvent(ActionEvent evt)
    {
        if (evt.Type == ActionEvent.ActionType.Jump)
        {
            Machine.ChangeState<Locomotion_Jump>();
            return true;
        }
        return base.HandleEvent(evt);
    }
}
}