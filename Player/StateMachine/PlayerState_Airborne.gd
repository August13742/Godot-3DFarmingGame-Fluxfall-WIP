class_name PlayerState_Airborne extends PlayerStateBase

func enter() -> void:
	if animator:
		animator.travel(&"Airbourne")

func update(delta: float) -> void:
	var pc: PlayerController = root as PlayerController
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var speed: float = pc.sprint_speed if Input.is_action_pressed("sprint") else pc.normal_speed
	var dir3: Vector3 = root.transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)

	var accel: float = pc.air_acceleration
	root.velocity.x = move_toward(root.velocity.x, dir3.x * speed, accel * delta)
	root.velocity.z = move_toward(root.velocity.z, dir3.z * speed, accel * delta)
	root.velocity.y = move_toward(root.velocity.y, pc.terminal_fall_velocity, pc.gravity * delta)
	root.move_and_slide()

	if root.is_on_floor():
		if input_dir.length() > 0.0:
			machine.change_state(PlayerStateMachine.StateKey.Sprint if \
			Input.is_action_pressed("sprint") else PlayerStateMachine.StateKey.Walk)
		else:
			machine.change_state(PlayerStateMachine.StateKey.Idle)

func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	# No mid-air jump by default
	pass

func can_jump() -> bool:
	return false
