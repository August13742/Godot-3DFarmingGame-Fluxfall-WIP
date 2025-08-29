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
	
	var new_items: Array[ItemResource] = []
	_scan_directory_recursively(source_directory, new_items)
	self.items = new_items
	
	print("[ItemCatalogue] Population complete. Found %d items." % items.size())


func _scan_directory_recursively(path: String, results: Array[ItemResource]):
	var dir = DirAccess.open(path)
	if not dir:
		push_error("ItemCatalogue: Failed to open directory: %s" % path)
		return

	# Iterate through every file in the current directory.
	for file_name in dir.get_files():
		var full_path = path.path_join(file_name)
		# Load the resource but don't assume its type yet.
		var resource = load(full_path)
		
		if resource is ItemResource:
			# Append to the temporary 'results' array.
			results.append(resource)

	# Now, find all subdirectories and continue the scan.
	for dir_name in dir.get_directories():
		var subdir_path = path.path_join(dir_name)
		# Pass the same 'results' array down the recursion.
		_scan_directory_recursively(subdir_path, results)
