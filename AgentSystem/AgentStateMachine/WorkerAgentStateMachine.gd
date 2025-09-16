class_name WorkerAgentStateMachine extends Node

enum StateKey { Idle, Moving, PerformingTask }

var current_state: AgentStateBase
var states: Dictionary = {}

@onready var agent: WorkerAgent = owner as WorkerAgent
@onready var animator: AnimationNodeStateMachinePlayback = %AnimationTree.get("parameters/StateMachine/playback")

func _ready() -> void:
	_construct_states()
	# Initial state is Idle
	change_state(StateKey.Idle)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func change_state(key: StateKey, payload: Dictionary = {}) -> void:
	if current_state:
		current_state.exit()
	
	var new_state: AgentStateBase = states.get(key)
	if new_state:
		current_state = new_state
		current_state.enter(payload)
	else:
		push_warning("Attempted to change to an invalid state: %s" % StateKey.keys()[key])

func _construct_states() -> void:
	states[StateKey.Idle] = AgentState_Idle.new().init(self, agent, animator)
	states[StateKey.Moving] = AgentState_MoveToTarget.new().init(self, agent, animator)
	states[StateKey.PerformingTask] = AgentState_PerformTask.new().init(self, agent, animator)
