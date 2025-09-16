class_name AgentState_MoveToTarget extends AgentStateBase

var _target_pos: Vector3
var _stuck_time: float = 0.0
var _last_distance_to_target: float = INF

func enter(payload: Dictionary = {}) -> void:
	if not payload.has("target"):
		push_error("MoveToTarget state entered without a 'target' in payload.")
		machine.change_state(WorkerAgentStateMachine.StateKey.Idle); return

	_target_pos = payload["target"]
	_stuck_time = 0.0
	
	var map_rid: RID = agent.get_world_3d().navigation_map
	var safe_target: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, _target_pos)
	agent.nav.set_target_position(safe_target)
	
	var final_pos: Vector3 = agent.nav.get_final_position()
	_last_distance_to_target = agent.global_position.distance_to(final_pos)

	agent.is_moving = true
	animator.travel("Move")

func update(delta: float) -> void:
	if agent.nav.is_navigation_finished():
		agent.is_moving = false
		agent.velocity = Vector3.ZERO
		agent._on_task_completed(agent._current_job.unique_id, agent.worker_id, true)
		return

	# Stuck detection
	var current_distance: float = agent.global_position.distance_to(agent.nav.get_final_position())
	if current_distance >= _last_distance_to_target - agent.move_eps:
		_stuck_time += delta
	else:
		_stuck_time = 0
	_last_distance_to_target = current_distance

	if _stuck_time > agent.max_stuck_time_tolerance:
		print_debug("AGENT %d FAILED (Stuck)" % agent.worker_id)
		agent.is_moving = false
		agent._on_task_completed(agent._current_job.unique_id, agent.worker_id, false)
		return

	# navigation velocity update
	var next_pos: Vector3 = agent.nav.get_next_path_position()
	var direction: Vector3 = (next_pos - agent.global_position).normalized()
	var desired_velocity: Vector3 = direction * agent.speed
	agent.nav.set_velocity(desired_velocity)

	# Rotation logic
	if direction.length_squared() > 0.001:
		var target_angle: float = atan2(-direction.x, -direction.z)
		agent.visuals.rotation.y = lerp_angle(agent.visuals.rotation.y, target_angle, delta * agent.rotation_speed)
