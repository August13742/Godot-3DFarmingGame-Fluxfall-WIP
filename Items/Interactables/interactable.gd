extends Area3D
class_name Interactable


@export var prompt := "interact"


func start_interaction() -> void:
	EventSystem.emit_INT_begin_interaction()
