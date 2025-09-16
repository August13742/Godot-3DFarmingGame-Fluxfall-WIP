class_name AgentState_PerformTask extends AgentStateBase

var _timer: SceneTreeTimer

func enter(payload: Dictionary = {}) -> void:
	var anim_name: StringName = payload.get("animation_name", &"Idle")
	var duration: float = payload.get("duration", 1.0)

	if duration <= 0:
		_on_task_finished(true)
		return

	animator.travel(anim_name)

	_timer = machine.get_tree().create_timer(duration)
	_timer.timeout.connect(_on_task_finished.bind(true))

func exit() -> void:
	# If the state is exited prematurely (e.g.,cancelled), clean up timer.
	if _timer and _timer.is_valid():
		_timer.timeout.disconnect(_on_task_finished)

func _on_task_finished(ok: bool) -> void:
	if agent._current_job:
		agent._on_task_completed(agent._current_job.unique_id, agent.worker_id, ok)
