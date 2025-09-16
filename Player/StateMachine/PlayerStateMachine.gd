class_name PlayerStateMachine extends Node

enum StateKey { Idle, Walk, Sprint, Airborne }

var current_state: PlayerStateBase
var states: Dictionary = {}  # int -> PlayerStateBase

@onready var root_entity: CharacterBody3D = owner as CharacterBody3D
@onready var animator: AnimationNodeStateMachinePlayback = %AnimationTree.get("parameters/Locomotion/playback")

func _ready() -> void:
	_construct_states()
	change_state(StateKey.Idle)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func change_state(key: int) -> void:
	if current_state:
		current_state.exit()
	current_state = states.get(key)
	if current_state:
		current_state.enter()

func _construct_states() -> void:
	states[StateKey.Idle] = PlayerState_Idle.new().init(self, root_entity, animator)
	states[StateKey.Walk] = PlayerState_Walk.new().init(self, root_entity, animator)
	states[StateKey.Sprint] = PlayerState_Sprint.new().init(self, root_entity, animator)
	states[StateKey.Airborne] = PlayerState_Airborne.new().init(self, root_entity, animator)
