class_name JobEmitterComponent extends Node


@export var job_template:JobData
## The signal on the parent node that this component listens to.
@export var trigger_signal: StringName
## Which argument of the signal to check (0 for the first, 1 for the second, etc.).
@export var argument_index: int = 0
## How to compare the signal's value to our target value.
@export var condition: Condition = Condition.EQUALS
## The value to check for. Can be a StringName, bool, int, float, etc.
@export var activation_value: Variant

enum Condition { EQUALS, NOT_EQUALS, GREATER_THAN, LESS_THAN }

var _opportunity_posted := false

func _ready() -> void:

	if not owner.has_signal(trigger_signal):
		push_error("Parent of JobEmitterComponent must have defined 'trigger_signal' signal.")
		return

	owner.connect(trigger_signal,_on_trigger_signal_received)


func _on_trigger_signal_received(...args)->void:
	if args.size() <= argument_index:
		return # Signal has fewer arguments than we are trying to check.

	var received_value = args[argument_index]
	var condition_met:bool = false
	# Perform type check before comparison for magnitude operators
	if condition == Condition.GREATER_THAN or condition == Condition.LESS_THAN:
		if typeof(received_value) != typeof(activation_value):
			push_warning("JobEmitterComponent: Type mismatch for magnitude comparison.")
			return # Abort comparison to prevent crash
			
	match condition:
		Condition.EQUALS:
			condition_met = (received_value == activation_value)
		Condition.NOT_EQUALS:
			condition_met = (received_value != activation_value)
		Condition.GREATER_THAN:
			condition_met = (received_value > activation_value)
		Condition.LESS_THAN:
			condition_met = (received_value < activation_value)

	if condition_met and not _opportunity_posted:
		_post_opportunity()
	elif not condition_met and _opportunity_posted:
		_opportunity_posted = false

func _post_opportunity()->void:
	_opportunity_posted = true

	if !is_instance_valid(owner): return
	var params := {
		&"template_path": job_template.resource_path,
		&"target_path": owner.get_path(),
		&"target_pos": owner.global_position, # Useful for agent distance checks
		&"payload": {} # For future use, can pass extra data here
	}
	NPCEventSystem.job_opportunity_created.emit(params)
