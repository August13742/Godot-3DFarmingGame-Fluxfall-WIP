@tool
extends ConfirmationDialog

@export var dialogue_size: Vector2i = Vector2i(500, 700)

signal callable_selected(callable_name: StringName)

@onready var custom_list: ItemList = %CustomList
@onready var builtin_list: ItemList = %BuiltinList
@onready var tab_container: TabContainer = $TabContainer

enum CallableType { SIGNAL, METHOD }
var _target_node: Node
var _callable_type: CallableType

func _ready() -> void:
	confirmed.connect(_on_confirmed)

	custom_list.item_activated.connect(_on_confirmed)
	builtin_list.item_activated.connect(_on_confirmed)

func popup_for_selection(target: Node, type: CallableType) -> void:
	_target_node = target
	_callable_type = type
	
	title = "Select a %s" % ["Signal", "Method"][type]
	custom_list.clear()
	builtin_list.clear()

	if not is_instance_valid(_target_node):
		popup_centered(dialogue_size)
		return

	var custom_callables: PackedStringArray = []
	var builtin_callables: PackedStringArray = []
	var script: Script = _target_node.get_script()
	var custom_callable_names: Dictionary = {}

	if is_instance_valid(script):
		var script_callables: Array = []
		if type == CallableType.SIGNAL:
			script_callables = script.get_script_signal_list()
		else:
			script_callables = script.get_script_method_list()
		for item in script_callables:
			custom_callable_names[item.name] = true

	var all_callables: Array = []
	if type == CallableType.SIGNAL:
		all_callables = _target_node.get_signal_list()
	else:
		all_callables = _target_node.get_method_list()
		
	for item in all_callables:
		if custom_callable_names.has(item.name):
			custom_callables.append(item.name)
		elif not item.name.begins_with("_"):
			builtin_callables.append(item.name)

	custom_callables.sort()
	builtin_callables.sort()
	
	for callable_name in custom_callables:
		custom_list.add_item(callable_name)
	for callable_name in builtin_callables:
		builtin_list.add_item(callable_name)
	
	popup_centered(dialogue_size)

func _on_confirmed(_index: int = -1) -> void:
	var active_list: ItemList
	
	# Determine which list is active based on the current tab
	if tab_container.current_tab == 0:
		active_list = custom_list
	else:
		active_list = builtin_list
		
	var selected_items: PackedInt32Array = active_list.get_selected_items()
	if selected_items.is_empty():
		return
		
	var selected_name: StringName = active_list.get_item_text(selected_items[0])
	emit_signal(&"callable_selected", selected_name)
	hide()
