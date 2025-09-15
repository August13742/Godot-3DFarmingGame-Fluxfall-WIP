class_name JobTask_Interact extends JobTask

@export var method_to_call: StringName
@export var animation_to_play: StringName # Optional animation
@export var pass_agent_inventory := false
func _init():
	type = JobTask.Type.Interact
