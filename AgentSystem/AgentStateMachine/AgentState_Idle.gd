class_name AgentState_Idle extends AgentStateBase

func enter(_payload: Dictionary = {}) -> void:
	agent.is_moving = false
	agent.nav.set_velocity(Vector3.ZERO)
	animator.travel(&"Idle")
	# Make self available for work
	NPCJobBoard.register_idle_agent(agent)

func update(_delta: float) -> void:
	# Does nothing. Waits to be assigned a job.
	pass
