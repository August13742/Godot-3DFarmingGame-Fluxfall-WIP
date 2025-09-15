@tool
extends EditorPlugin


const CALLABLE_SELECTOR = preload("res://addons/augusts_utilities/src/CallableSelector/CallableSelectorPlugin.gd")
var callable_selector_plugin = CALLABLE_SELECTOR.new()

func _enter_tree():
	add_inspector_plugin(callable_selector_plugin)

func _exit_tree():
	remove_inspector_plugin(callable_selector_plugin)
