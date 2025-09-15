@tool
extends EditorInspectorPlugin

const EditorPropertyCallable := preload("res://addons/augusts_utilities/src/CallableSelector/EditorPropertyCallable.gd")

func _can_handle(_object: Object) -> bool:
	return true

func _parse_property(object: Object, type: int, name: String, hint_type: int, hint_string: String, usage: int, wide: bool) -> bool:
	# We only care about StringName properties with our custom hint.
	if type != TYPE_STRING or not hint_string.begins_with("@Callable"):
		return false

	# --- PARSE HINT STRING ---
	# Example: @callable(signal, my_target_node)
	var parts_str: String = hint_string.get_slice("(", 1).get_slice(")", 0)
	var parts: PackedStringArray = parts_str.split(",", false) # Split by comma, don't allow empty parts

	if parts.is_empty():
		push_warning("Hint string '@Callable' is missing arguments. Expected @Callable(type, [target_property]).")
		return false

	var callable_type_str: String = parts[0].strip_edges()
	var target_property_name: StringName = &""
	if parts.size() > 1:
		target_property_name = parts[1].strip_edges()

	# --- CREATE CUSTOM EDITOR ---
	var editor_property := EditorPropertyCallable.new()
	editor_property.setup(callable_type_str, target_property_name)
	
	add_property_editor(name, editor_property)
	return true
