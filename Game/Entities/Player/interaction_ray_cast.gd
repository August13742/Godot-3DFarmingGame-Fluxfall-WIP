extends RayCast3D



func check_interaction() -> void:
	if is_colliding():
		print("hi")
	if is_colliding() && Input.is_action_just_pressed("interact"):
		var collider := get_collider()
		if collider is Interactable:
			get_collider().start_interaction()
