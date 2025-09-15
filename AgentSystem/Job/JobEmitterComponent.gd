class_name JobEmitterComponent extends Node


@export var job_template:JobData


var _trigger_signal:StringName = &""
## The signal on the parent node that this component listens to.
@export_placeholder("@Callable(signal)") var trigger_signal: String :
	set(val):
		trigger_signal= val
		_trigger_signal = StringName(val)

## Which argument of the signal to check (0 for the first, 1 for the second, etc.).
@export var argument_index: int = 0
## How to compare the signal's value to our target value.
@export var condition: Condition = Condition.EQUALS
## The value to check for. Can be a StringName, bool, int, float, etc.
@export var activation_value: Variant

var _validation_method:StringName = &""
## (Optional) A method on the owner that must return true for the job to be posted.
@export_placeholder("@Callable") var validation_method: String :
	set(val):
		validation_method = val
		_validation_method = StringName(val)

enum Condition { EQUALS, NOT_EQUALS, GREATER_THAN, LESS_THAN }
var _opportunity_posted := false

func _ready() -> void:
	if not owner.has_signal(_trigger_signal):
		push_error("JobEmitterComponent: owner missing signal '%s'." % String(_trigger_signal))
		return

	owner.connect(_trigger_signal,_on_trigger_signal_received)


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

	if condition_met:
		# Perform secondary validation if a method is specified.
		if _validation_method != &"":
			if owner.has_method(_validation_method):
				if not owner.call(_validation_method):
					condition_met = false # Validation failed, override condition.
			else:
				push_warning("JobEmitterComponent: validation_method '%s' not found on owner." % validation_method)
				condition_met = false # Treat as failure if method is missing.
				
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
