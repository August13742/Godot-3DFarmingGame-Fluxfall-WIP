class_name JobTask_EquipTool extends JobTask

@export var tool_id:StringName
@export var animation_to_play: StringName # Optional animation

func _init():
	type = JobTask.Type.EquipTool
