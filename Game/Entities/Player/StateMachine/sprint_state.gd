extends State
class_name SprintState

func enter():
	state_machine_animator.travel(&"Sprint")
	if root_entity.state_machine_debug:
		print("[Debug/States]: Entering SPRINT")

func update(delta):
	var input_dir:Vector2 = root_entity.current_input_direction

	if input_dir.length() == 0:
		owner.change_state(StateMachine.Idle)
		return

	if !Input.is_action_pressed("sprint"):
		owner.change_state(StateMachine.Walk)
		return

	if !root_entity.is_on_floor():
		owner.change_state(StateMachine.Airbourne)
		return


	var accel:float = root_entity.ground_acceleration
	var speed:float = root_entity.sprint_speed
	var direction:Vector3 = root_entity.transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	root_entity.velocity.x = move_toward(root_entity.velocity.x, direction.x * speed, accel * delta)
	root_entity.velocity.z = move_toward(root_entity.velocity.z, direction.z * speed, accel * delta)

	root_entity.velocity.y = -0.01
	root_entity.move_and_slide()
