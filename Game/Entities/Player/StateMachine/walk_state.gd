extends State
class_name WalkState


var player:CharacterBody3D

func enter():
	player = owner.root_entity
	player.animation_player.play("Run")
	if player.state_machine_debug:
		print("[Debug/States]: Entering WALK")

func update(delta):
	var input_dir:Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_dir.length() == 0:
		owner.change_state("Idle")
		return
	if Input.is_action_pressed("sprint"):
		owner.change_state("Sprint")
		return
	if !player.is_on_floor():
		owner.change_state("Airbourne")
		return


	var accel:float = player.ground_acceleration
	var speed:float = player.normal_speed
	var direction:Vector3 = player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)

	player.velocity.x = move_toward(player.velocity.x, direction.x * speed, accel * delta)
	player.velocity.z = move_toward(player.velocity.z, direction.z * speed, accel * delta)

	player.velocity.y = -0.01  # stick to ground
	player.move_and_slide()
