class_name InteractionController extends Node

@onready var player: PlayerController = owner
@onready var right_hand: Node3D = player.right_hand

@onready var camera: ThirdPersonARPGCamera = get_tree().get_first_node_in_group("player_camera")

var last_prompt_text := ""

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(camera):
		return

	var aim_data: Dictionary = camera.get_aim_target()
	check_interaction(aim_data)

func check_interaction(aim_data: Dictionary) -> void:
	var collider: Object = aim_data.collider

	if not (collider is Interactable):
		# Clear UI prompt if it was showing
		_clear_prompt()
		return

	var interactable: Interactable = collider as Interactable
	
	# Update the prompt based on player state
	interactable.update_prompt(player)
	var new_prompt: String = interactable.prompt

	if new_prompt != last_prompt_text:
		last_prompt_text = new_prompt
		if new_prompt.is_empty():
			EventSystem.emit_BUL_destroy_bulletin(BulletinConfig.Keys.InteractionPrompt)
		else:
			EventSystem.emit_BUL_create_bulletin(BulletinConfig.Keys.InteractionPrompt, new_prompt)

	if Input.is_action_just_pressed("interact"):
		interactable.start_interaction(player)

func _clear_prompt() -> void:
	if not last_prompt_text.is_empty():
		last_prompt_text = ""
		EventSystem.emit_BUL_destroy_bulletin(BulletinConfig.Keys.InteractionPrompt)
