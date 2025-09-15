@tool
extends EditorProperty

const Dialogue := preload("res://addons/augusts_utilities/src/CallableSelector/CallableSelectorDialogue.gd")
var dialog_scene: PackedScene = preload("res://addons/augusts_utilities/src/CallableSelector/CallableSelectorDialogue.tscn")
var dialog_instance: ConfirmationDialog

var line_edit: LineEdit = LineEdit.new()
var button: Button = Button.new()

var _callable_type: int
var _target_property_name: StringName = &""

func setup(type_str: String, target_prop: StringName) -> void:
	if type_str == "signal":
		_callable_type = Dialogue.CallableType.SIGNAL
	else:
		_callable_type = Dialogue.CallableType.METHOD
	_target_property_name = target_prop

func _init() -> void:
	var hbox := HBoxContainer.new()
	add_child(hbox)
	line_edit.editable = false
	line_edit.focus_mode = FOCUS_NONE
	hbox.add_child(line_edit)
	line_edit.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	button.text = "..."
	hbox.add_child(button)
	button.pressed.connect(_on_button_pressed)

func _update_property() -> void:
	var current_value: StringName = get_edited_object()[get_edited_property()]
	line_edit.text = str(current_value)

func _on_button_pressed() -> void:
	var target_node: Node = _get_target_node()
	if not is_instance_valid(target_node):
		push_warning("CallableSelector: Target node is not valid.")
		return

	dialog_instance = dialog_scene.instantiate()
	get_tree().root.add_child(dialog_instance)
	
	dialog_instance.callable_selected.connect(_on_callable_selected)
	dialog_instance.popup_for_selection(target_node, _callable_type)

func _get_target_node() -> Node:
	var edited_object: Object = get_edited_object()
	
	# Default target is the owner of the node being edited
	var default_target: Node = edited_object.owner if edited_object is Node else null
	
	if _target_property_name == &"":
		return default_target

	# If a target property is specified, try to use it
	if edited_object.has_method("get") and edited_object.get(_target_property_name) is NodePath:
		var node_path: NodePath = edited_object.get(_target_property_name)
		if edited_object is Node and not node_path.is_empty():
			var node_from_path: Node = edited_object.get_node(node_path)
			if is_instance_valid(node_from_path):
				return node_from_path # Success

	push_warning("CallableSelector: Could not find a valid node from property '%s'." % _target_property_name)
	return default_target # Fallback to default.


func _on_callable_selected(callable_name: StringName) -> void:
	emit_changed(get_edited_property(), callable_name)
	line_edit.text = str(callable_name)
	
	if is_instance_valid(dialog_instance):
		dialog_instance.queue_free()
