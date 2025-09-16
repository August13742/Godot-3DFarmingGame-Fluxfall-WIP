class_name AgentState_PerformTask extends AgentStateBase

var _timer: SceneTreeTimer

func enter(payload: Dictionary = {}) -> void:
	var anim_name: StringName = payload.get(&"animation_to_play", &"Interact")
	var duration: float = payload.get(&"duration", 1.0)

	agent.nav.set_velocity(Vector3.ZERO)
	
	if duration <= 0:
		_on_task_finished(true)
		return

	animator.travel(anim_name)

	_timer = machine.get_tree().create_timer(duration)
	_timer.timeout.connect(_on_task_finished.bind(true))



func _on_task_finished(ok: bool) -> void:
	if machine.current_state != self:
		return
		
	if agent._current_job:
		printt(agent._current_job.unique_id, agent.worker_id, ok)
		agent._on_task_completed(agent._current_job.unique_id, agent.worker_id, ok)
