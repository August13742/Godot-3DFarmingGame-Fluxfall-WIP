extends Interactable
class_name Pickuppable


@export var item_key: ItemConfig.Keys
@onready var parent:Node3D = get_parent()

func start_interaction() -> void:
	EventSystem.emit_ITEM_picked_up(parent)
	parent.queue_free()
