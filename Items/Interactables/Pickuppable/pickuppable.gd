extends Interactable
class_name Pickuppable


@export var item_id: StringName
@onready var parent:Node3D = get_parent()

func start_interaction() -> void:
	EventSystem.emit_INV_try_pick_up_item(item_id,destroy_self)



func destroy_self() -> void:
	parent.queue_free()
