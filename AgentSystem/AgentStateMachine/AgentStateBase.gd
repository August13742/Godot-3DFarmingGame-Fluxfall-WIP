@abstract class_name AgentStateBase extends RefCounted

var machine: WorkerAgentStateMachine
var agent: WorkerAgent
var animator: AnimationNodeStateMachinePlayback

func init(p_machine: WorkerAgentStateMachine, p_agent: WorkerAgent, p_animator: AnimationNodeStateMachinePlayback) -> AgentStateBase:
	machine = p_machine
	agent = p_agent
	animator = p_animator
	return self

func enter(_payload: Dictionary = {}) -> void:
	pass

func update(_delta: float) -> void:
	pass

func exit() -> void:
	pass
