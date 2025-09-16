class_name PlayerState_Walk extends PlayerStateBase

func enter() -> void:
	if animator:
		animator.travel(&"Walk")

func update(delta: float) -> void:
	var pc: PlayerController = root as PlayerController
	var input_dir: Vector2 = pc.current_input_direction
	if input_dir.length() == 0.0:
		machine.change_state(PlayerStateMachine.StateKey.Idle); return
	if Input.is_action_pressed(&"sprint"):
		machine.change_state(PlayerStateMachine.StateKey.Sprint); return
	if not root.is_on_floor():
		machine.change_state(PlayerStateMachine.StateKey.Airborne); return

	var accel: float = pc.ground_acceleration
	var speed: float = pc.normal_speed
	var dir3: Vector3 = root.transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	root.velocity.x = move_toward(root.velocity.x, dir3.x * speed, accel * delta)
	root.velocity.z = move_toward(root.velocity.z, dir3.z * speed, accel * delta)
	root.velocity.y = -0.1
	root.move_and_slide()

func exit() -> void:
	pass

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"jump") and can_jump():
		jump()
