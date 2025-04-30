extends State
class_name AirbourneState


var player:CharacterBody3D

func enter():
	player = owner.root_entity
	if player.is_on_floor() and Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_force

	player.animation_player.play("Jump")
	if player.state_machine_debug:
		print("[Debug/States]: Entering Airbourne")

func update(delta):
	var input_dir:Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var speed:float = player.sprint_speed if Input.is_action_pressed("sprint") else player.normal_speed
	var direction:Vector3 = player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)

	var accel:float = player.air_acceleration
	player.velocity.x = move_toward(player.velocity.x, direction.x * speed, accel * delta)
	player.velocity.z = move_toward(player.velocity.z, direction.z * speed, accel * delta)
	player.velocity.y = move_toward(player.velocity.y, player.terminal_fall_velocity, player.gravity * delta)

	player.move_and_slide()

	if player.is_on_floor():
		if input_dir.length() > 0:
			owner.change_state("Sprint" if Input.is_action_pressed("sprint") else "Walk")
		else:
			owner.change_state("Idle")
