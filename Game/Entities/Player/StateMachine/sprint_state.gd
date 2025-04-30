extends State
class_name SprintState


var player:CharacterBody3D

func enter():
	player = owner.root_entity

	player.animation_player.play("Run")
	player.animation_player.speed_scale = 1.25

	if player.state_machine_debug:
		print("[Debug/States]: Entering SPRINT")

func update(delta):
	var input_dir:Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_dir.length() == 0:
		owner.change_state("Idle")
		return
	if !Input.is_action_pressed("sprint"):
		owner.change_state("Walk")
		return
	if !player.is_on_floor():
		owner.change_state("Airbourne")
		return

	var accel:float = player.ground_acceleration
	var speed:float = player.sprint_speed
	var direction:Vector3 = player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	player.velocity.x = move_toward(player.velocity.x, direction.x * speed, accel * delta)
	player.velocity.z = move_toward(player.velocity.z, direction.z * speed, accel * delta)

	player.velocity.y = -0.01
	player.move_and_slide()

func exit():
	player.animation_player.speed_scale = 1
