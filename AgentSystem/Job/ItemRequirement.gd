@tool
extends Resource
class_name ItemRequirement

## A data resource that defines an item requirement for a job.
## Can be a specific item (e.g., "tomato_seed") or a category of item
## defined by a capability (e.g., any item with "SeedCapability").
## This script uses custom Inspector logic to provide a user-friendly editor workflow.

# The type of requirement this is.
enum Type { SPECIFIC_ITEM, BY_CAPABILITY }

# --- EXPORTED PROPERTIES ---

@export var type: Type = Type.SPECIFIC_ITEM:
	set(v):
		if type == v: return
		type = v
		# Clear backing fields when type changes to reset state
		_item = null
		_example_item = null
		_cap_script = null
		_cap_choices_names.clear()
		_cap_choices_scripts.clear()
		_warning_message = ""
		notify_property_list_changed()

@export_range(1, 999, 1) var amount: int = 1
@export var is_consumed: bool = true
@export var binding_key: StringName = &""  # e.g. &"seed", &"water"
# --- INTERNAL STATE (Backing Fields) ---
var _item: ItemResource
var _example_item: ItemResource
var _cap_script: Script
var _cap_choices_names: Array[String] = []
var _cap_choices_scripts: Array[Script] = []
var _cap_choice_idx: int = -1
var _warning_message: String = ""

# --- PUBLIC API ---
func required_item_id() -> StringName:
	return _item.id if _item else StringName("")

func required_capability_script() -> Script:
	return _cap_script

# ---------- INSPECTOR OVERRIDES ----------

## This function tells the Godot Inspector what properties to display.
func _get_property_list() -> Array:
	var p: Array = []
	match type:
		Type.SPECIFIC_ITEM:
			p.append({
				"name": "item", "type": TYPE_OBJECT,
				"hint": PROPERTY_HINT_RESOURCE_TYPE, "hint_string": "ItemResource",
				"usage": PROPERTY_USAGE_DEFAULT
			})
		Type.BY_CAPABILITY:
			p.append({
				"name": "example_item", "type": TYPE_OBJECT,
				"hint": PROPERTY_HINT_RESOURCE_TYPE, "hint_string": "ItemResource",
				"usage": PROPERTY_USAGE_DEFAULT, "class_name": "ItemResource"
			})

			if not _warning_message.is_empty():
				p.append({
					"name": "WARNING", "type": TYPE_STRING,
					"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY
				})

			if _cap_choices_names.size() > 1:
				p.append({
					"name": "capability_desired", "type": TYPE_INT,
					"hint": PROPERTY_HINT_ENUM, "hint_string": ",".join(_cap_choices_names),
					"usage": PROPERTY_USAGE_DEFAULT
				})

			if _cap_script:
				p.append({
					"name": "resolved_capability", "type": TYPE_STRING,
					"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY
				})
	return p

## This function provides the current value for the properties defined above.
func _get(p_name):
	match p_name:
		"item": return _item
		"example_item": return _example_item
		"capability_desired": return max(_cap_choice_idx, 0)
		"resolved_capability": return _cap_script.get_global_name() if _cap_script else &""
		"WARNING": return _warning_message
		_: return null

## This function is called when the user changes a property in the Inspector.
func _set(p_name, value) -> bool:
	match p_name:
		"item":
			_item = value
			return true
		"example_item":
			_example_item = value
			_resolve_capability_desired()
			return true
		"capability_desired":
			var idx := int(value)
			if idx >= 0 and idx < _cap_choices_scripts.size():
				_cap_choice_idx = idx
				_cap_script = _cap_choices_scripts[idx]
				notify_property_list_changed() # Refresh to show the resolved capability
			return true
		_: return false

## This is the core logic that inspects the example item.
func _resolve_capability_desired():
	_cap_script = null
	_cap_choices_names.clear()
	_cap_choices_scripts.clear()
	_cap_choice_idx = -1
	_warning_message = ""

	if _example_item == null:
		notify_property_list_changed()
		return

	var caps: Array = _example_item.capabilities
	for cap in caps:
		if cap and cap.get_script():
			var s: Script = cap.get_script()
			_cap_choices_names.append(s.get_global_name())
			_cap_choices_scripts.append(s)

	if _cap_choices_scripts.is_empty():
		_warning_message = "ERROR: The provided 'Example Item' has no capabilities."

	elif _cap_choices_scripts.size() == 1:
		_cap_script = _cap_choices_scripts[0]
		_cap_choice_idx = 0

	# rebuild Inspector UI based on the new state
	notify_property_list_changed()
