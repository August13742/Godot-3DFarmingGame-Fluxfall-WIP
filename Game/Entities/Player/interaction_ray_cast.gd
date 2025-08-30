extends RayCast3D

var is_hitting:bool = false

func check_interaction() -> void:
	if is_colliding():
		var collider := get_collider()
		if not (collider is Interactable):
			return

		collider.update_prompt(owner)

		if !is_hitting:
			is_hitting = true
			EventSystem.emit_BUL_create_bulletin(BulletinConfig.Keys.InteractionPrompt, collider.prompt)

		if Input.is_action_just_pressed("interact"):
			collider.start_interaction(owner) # Pass the player as the source

	elif is_hitting:
		is_hitting = false
		EventSystem.emit_BUL_destroy_bulletin(BulletinConfig.Keys.InteractionPrompt)
