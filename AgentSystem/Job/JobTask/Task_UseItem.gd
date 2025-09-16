class_name JobTask_UseItem extends JobTask

enum Target{Self,Objective}

#@export var item_from_payload_key: StringName
#@export var amount: int = 1
@export var target_to_use_item_on:Target
@export var animation_to_play: StringName # Optional animation
func _init():
	type = JobTask.Type.UseItem
