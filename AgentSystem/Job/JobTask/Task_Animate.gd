class_name JobTask_Animate extends JobTask

@export var animation_to_play: StringName = &""
@export_range(0.1, 60.0, 0.1) var duration: float = 2.0

func _init() -> void:
	type = JobTask.Type.Animate
