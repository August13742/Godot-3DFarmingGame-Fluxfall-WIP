@tool
extends Resource
class_name ItemCatalogue

## A list of all item resources, can be populated automatically.
@export var items: Array[ItemResource]

## --- Automation Tool ---
@export_group("Automation")
## The root folder to scan recursively for ItemResource (.tres) files.
@export var source_directory: String = "res://items/Resources"

@export_tool_button("Populate from Path (Recursive)") var populate_from_path:Callable = _populate_items


func _populate_items():
	if not Engine.is_editor_hint():
		return

	print("[ItemCatalogue] Starting recursive scan from: ", source_directory)
	items.clear()
	_scan_directory_recursively(source_directory)
	print("[ItemCatalogue] Population complete. Found %d items." % items.size())


func _scan_directory_recursively(path: String):
	var dir = DirAccess.open(path)
	if not dir:
		push_error("ItemCatalogue: Failed to open directory: %s" % path)
		return

	# Iterate through every file and folder in the current directory.
	for file_name in dir.get_files():
		var full_path = path.path_join(file_name)
		var resource = load(full_path)
		
		if resource is ItemResource:
			items.append(resource)
		# No warning for non-ItemResource files to keep the log clean.


	# find all subdirectories and dive into them
	for dir_name in dir.get_directories():
		var subdir_path = path.path_join(dir_name)
		_scan_directory_recursively(subdir_path) # recursive call.
