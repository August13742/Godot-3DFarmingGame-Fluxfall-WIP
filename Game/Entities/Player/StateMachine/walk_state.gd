extends State
class_name WalkState




func enter():
	animation_player.play("Walk",0.5)
	animation_player.speed_scale = 0.75
	if root_entity.state_machine_debug:
		print("[Debug/States]: Entering WALK")


func update(delta):
	var input_dir:Vector2 = root_entity.current_input_direction
	if input_dir.length() == 0:
		owner.change_state(StateMachine.Idle)
		return
	if Input.is_action_pressed("sprint"):
		owner.change_state(StateMachine.Sprint)
		return
	if !root_entity.is_on_floor():
		owner.change_state(StateMachine.Airbourne)
		return


	var accel:float = root_entity.ground_acceleration
	var speed:float = root_entity.normal_speed
	var direction:Vector3 = root_entity.transform.basis * Vector3(input_dir.x, 0, input_dir.y)

	root_entity.velocity.x = move_toward(root_entity.velocity.x, direction.x * speed, accel * delta)
	root_entity.velocity.z = move_toward(root_entity.velocity.z, direction.z * speed, accel * delta)

	root_entity.velocity.y = -0.01  # stick to ground
	root_entity.move_and_slide()

func exit():
	animation_player.speed_scale = 1
