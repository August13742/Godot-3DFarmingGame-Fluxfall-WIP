@abstract class_name PlayerStateBase extends RefCounted

var machine: PlayerStateMachine
var root: CharacterBody3D
var animator: AnimationNodeStateMachinePlayback

func init(p_machine: PlayerStateMachine, p_root: CharacterBody3D, p_animator: AnimationNodeStateMachinePlayback) -> PlayerStateBase:
	machine = p_machine
	root = p_root
	animator = p_animator
	return self

@abstract func enter() -> void
@abstract func update(delta: float) -> void
@abstract func exit() -> void
@abstract func handle_input(event: InputEvent) -> void

func can_jump() -> bool:
	return true

func jump() -> void:
	root.velocity.y = (root as PlayerController).jump_force
	machine.change_state(PlayerStateMachine.StateKey.Airborne)
