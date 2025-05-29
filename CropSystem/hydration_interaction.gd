extends Node3D

class_name HydrateCrop



func _ready():
	EventSystem.INT_begin_interaction.connect(_on_interact)


func _on_interact():
	owner.hydrate.emit()
