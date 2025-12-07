using Godot;
using System;
namespace CharacterControl
{
    public class Action_Attack1 : ActionAttackStates
    {
        protected override float Duration { get; } = 1f;
        protected override float DamagePoint { get; } = 2f;
        protected override Type NextComboState { get; } = null;
        protected override StringName AnimName { get; } = "attack1";
    }
}