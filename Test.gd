extends Node

		
func _ready() -> void:
	var test:StringName = &""
	print_debug(test)
	print_debug(test == null)
	print_debug(test == &"")
	print_debug(&"")
