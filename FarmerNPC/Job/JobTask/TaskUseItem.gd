class_name JobTask_UseItem extends JobTask

@export var item_id: StringName
@export var amount: int = 1
@export var animation_to_play: StringName # Optional animation
func _init():
	type = JobTask.Type.UseItem
