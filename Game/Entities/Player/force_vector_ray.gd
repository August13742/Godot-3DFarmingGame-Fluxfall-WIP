extends RayCast3D
class_name ForceVectorRay

var source:Node3D
var is_hitting:bool = false


func _ready() -> void:
	_late_init.call_deferred()

func _late_init()->void:
	source = owner.right_hand


func check_interaction() -> void:
	if is_colliding():
		var collider := get_collider()
		if !(collider is Interactable): return

		if Input.is_action_just_pressed("force"):

			if collider is Interactable:
				get_collider().start_interaction(source)

		elif Input.is_action_just_pressed("interact"):

			if collider is Interactable:
				get_collider().start_interaction()

		if !is_hitting:
			is_hitting = true
			EventSystem.emit_BUL_create_bulletin(BulletinConfig.Keys.InteractionPrompt, collider.prompt)
			# connected by UILayer:bulletin controller

	elif is_hitting:
		is_hitting = false
		EventSystem.emit_BUL_destroy_bulletin(BulletinConfig.Keys.InteractionPrompt)
