class_name JobTask_Validate extends JobTask

@export var method_to_call: StringName
@export var animation_to_play: StringName # Optional animation

func _init():
	type = JobTask.Type.Validate
