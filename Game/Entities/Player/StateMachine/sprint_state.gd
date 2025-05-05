extends State
class_name SprintState


#var player:CharacterBody3D

func enter():
	root_entity = owner.root_entity
	root_entity.animation_player.play("Sprint_Enter",1)
	root_entity.animation_player.queue("Sprint")

	if root_entity.state_machine_debug:
		print("[Debug/States]: Entering SPRINT")

var transition_to_walk_timer:Timer= null

func update(delta):
	var input_dir:Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	if input_dir.length() == 0:
		if transition_to_walk_timer:
			transition_to_walk_timer.queue_free()
			transition_to_walk_timer = null
		root_entity.animation_player.play("Sprint_Exit")
		owner.change_state("Idle")
		return

	if !Input.is_action_pressed("sprint"):
		if transition_to_walk_timer == null:
			transition_to_walk_timer = Timer.new()
			transition_to_walk_timer.wait_time = 0.5
			transition_to_walk_timer.one_shot = true
			transition_to_walk_timer.timeout.connect(_on_sprint_release_timeout)
			add_child(transition_to_walk_timer)
			transition_to_walk_timer.start()
	else:
		if transition_to_walk_timer:
			transition_to_walk_timer.queue_free()
			transition_to_walk_timer = null

	if !root_entity.is_on_floor():
		if transition_to_walk_timer:
			transition_to_walk_timer.queue_free()
			transition_to_walk_timer = null
		owner.change_state("Airbourne")
		return

	var accel:float = root_entity.ground_acceleration
	var speed:float = root_entity.sprint_speed
	var direction:Vector3 = root_entity.transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	root_entity.velocity.x = move_toward(root_entity.velocity.x, direction.x * speed, accel * delta)
	root_entity.velocity.z = move_toward(root_entity.velocity.z, direction.z * speed, accel * delta)

	root_entity.velocity.y = -0.01
	root_entity.move_and_slide()

func _on_sprint_release_timeout():
	if is_instance_valid(owner):
		owner.change_state("Walk")
