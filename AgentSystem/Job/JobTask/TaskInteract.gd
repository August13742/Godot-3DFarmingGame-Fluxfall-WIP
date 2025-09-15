class_name JobTask_Interact extends JobTask

@export var method_to_call: StringName
@export var animation_to_play: StringName
@export var required_binding: StringName = &""    # e.g. &"seed"
@export var pass_agent_inventory: bool = true

func _init():
	type = JobTask.Type.Interact
