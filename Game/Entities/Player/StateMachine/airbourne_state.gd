extends State
class_name AirbourneState




func enter():

	animation_player.play("Jump_Start")
	animation_player.animation_set_next("Jump_Start","Jump")
	animation_player.animation_set_next("Jump","Jump_Land")

	if root_entity.state_machine_debug:
		print("[Debug/States]: Entering Airbourne")

func update(delta):
	var input_dir:Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var speed:float = root_entity.sprint_speed if Input.is_action_pressed("sprint") else root_entity.normal_speed
	var direction:Vector3 = root_entity.transform.basis * Vector3(input_dir.x, 0, input_dir.y)

	var accel:float = root_entity.air_acceleration
	root_entity.velocity.x = move_toward(root_entity.velocity.x, direction.x * speed, accel * delta)
	root_entity.velocity.z = move_toward(root_entity.velocity.z, direction.z * speed, accel * delta)
	root_entity.velocity.y = move_toward(root_entity.velocity.y, root_entity.terminal_fall_velocity, root_entity.gravity * delta)

	root_entity.move_and_slide()

	if root_entity.is_on_floor():
		animation_player.play("Jump_Land")
		if input_dir.length() > 0:
			owner.change_state("Sprint" if Input.is_action_pressed("sprint") else "Walk")
		else:
			owner.change_state("Idle")

func can_jump() -> bool:
	return false  # disable jumping when airborne

func exit():
	pass
