extends Node
class_name StageController

func _ready() -> void:
	change_stage(StageConfig.Keys.Test)


func change_stage(key:StageConfig.Keys)->void:
	for child in get_children():
		child.queue_free()

	var new_stage:Node = StageConfig.get_stage(key)
	add_child(new_stage)
