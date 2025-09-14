class_name JobTask_MoveTo extends JobTask

@export var animation_to_play: StringName # Optional animation

func _init():
	type = JobTask.Type.MoveTo
