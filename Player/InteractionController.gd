class_name InteractionController extends Node

@onready var player: PlayerController = owner
@onready var camera: ThirdPersonARPGCamera = get_tree().get_first_node_in_group("player_camera")

var is_action_obstructed: bool = false
var last_prompt_text := ""

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(camera):
		return

	var aim_data: Dictionary = camera.get_aim_target()

	_update_head_look(aim_data.point)
	_check_for_interactable(aim_data)
	_check_action_obstruction(aim_data)

	if Input.is_action_just_pressed("interact"):
		handle_interaction(aim_data)

func _update_head_look(target_point: Vector3) -> void:
	player.head.look_at(target_point, Vector3.UP)

func _check_action_obstruction(aim_data: Dictionary) -> void:
	var target_point: Vector3 = aim_data.point
	var intended_collider: Object = aim_data.collider

	# If the camera isn't aiming at anything specific, there's nothing to be obstructed from.
	# We can treat the path as clear unless the hand-ray hits something very close.
	if intended_collider == null:
		is_action_obstructed = false
		GameManager.set_reticle_obstructed(is_action_obstructed)
		return

	var hand_position: Vector3 = player.right_hand.global_position
	var direction_to_target: Vector3 = (target_point - hand_position).normalized()

	var space_state: PhysicsDirectSpaceState3D = owner.get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(hand_position, hand_position + direction_to_target * 100.0)
	params.exclude = [player]
	var result: Dictionary = space_state.intersect_ray(params)

	if not result:
		# Ray from hand hit nothing, so path to the intended target must be clear.
		is_action_obstructed = false
	else:
		# Is the object we hit DIFFERENT from the intended target?
		var hit_collider: Object = result.collider
		is_action_obstructed = (hit_collider != intended_collider)


	GameManager.set_reticle_obstructed(is_action_obstructed)


func _check_for_interactable(aim_data: Dictionary) -> void:
	var collider: Object = aim_data.collider

	if not (collider is Interactable):
		_clear_prompt()
		return

	var interactable: Interactable = collider as Interactable
	interactable.update_prompt(player)
	var new_prompt: String = interactable.prompt

	if new_prompt != last_prompt_text:
		last_prompt_text = new_prompt
		if new_prompt.is_empty():
			EventSystem.emit_BUL_destroy_bulletin(BulletinConfig.Keys.InteractionPrompt)
		else:
			EventSystem.emit_BUL_create_bulletin(BulletinConfig.Keys.InteractionPrompt, new_prompt)

func handle_interaction(aim_data: Dictionary) -> void:
	var collider: Object = aim_data.collider

	# Prioritize interaction with Interactable objects.
	if collider is Interactable:
		(collider as Interactable).start_interaction(player)
		return

	# If not looking at an Interactable, perform the default action (e.g., swing tool).
	if not is_action_obstructed:
		# player.perform_action(aim_data.point)
		print("Performing default action towards: ", aim_data.point)
	else:
		print("Action obstructed!")

func _clear_prompt() -> void:
	if not last_prompt_text.is_empty():
		last_prompt_text = ""
		EventSystem.emit_BUL_destroy_bulletin(BulletinConfig.Keys.InteractionPrompt)
