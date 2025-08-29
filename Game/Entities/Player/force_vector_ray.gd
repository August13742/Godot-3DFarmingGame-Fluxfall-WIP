extends ShapeCast3D
class_name ForceVectorRay

var source:Node3D
var is_hitting:bool = false


func _ready() -> void:
	_late_init.call_deferred()

func _late_init()->void:
	source = owner.right_hand

var last_prompt_text := ""

func check_interaction() -> void:
	if is_colliding():
		var collider = get_collider(0)
		if not (collider is Interactable):
			# We are hitting something, but it's not interactable.
			# Clear the prompt if it was showing before.
			if last_prompt_text != "":
				last_prompt_text = ""
				EventSystem.emit_BUL_destroy_bulletin(BulletinConfig.Keys.InteractionPrompt)
			return

		var interactable: Interactable = collider

		# 1. Tell the interactable to update its internal prompt based on our state.
		interactable.update_prompt(owner) # 'owner' is the PlayerController

		var new_prompt := interactable.prompt

		# 3. If the prompt text has changed, update UI.
		if new_prompt != last_prompt_text:
			last_prompt_text = new_prompt
			if new_prompt == "":
				EventSystem.emit_BUL_destroy_bulletin(BulletinConfig.Keys.InteractionPrompt)
			else:
				EventSystem.emit_BUL_create_bulletin(BulletinConfig.Keys.InteractionPrompt, new_prompt)

		if Input.is_action_just_pressed("interact"):
			interactable.start_interaction(owner)

	else:
		if last_prompt_text != "":
			last_prompt_text = ""
			EventSystem.emit_BUL_destroy_bulletin(BulletinConfig.Keys.InteractionPrompt)
