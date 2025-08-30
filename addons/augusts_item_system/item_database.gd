@tool
extends Node
# Singleton Item Database, managed by the Item System Plugin.

# --- Configuration ---
# These paths are now read from Project Settings to make the plugin portable.
var source_directory: String
var catalogue_save_path: String

# Project Settings paths defined by the plugin.
const SOURCE_DIR_SETTING = "augusts_item_system/database/source_directory"
const SAVE_PATH_SETTING = "augusts_item_system/database/catalogue_save_path"


# --- Editor Tool ---
@export_tool_button("Rebuild Database & Generate Catalogue") var _generate_catalogue_button: Callable = _force_build_and_save_catalogue


# --- Indexed Databases ---
var items_by_id := {}
var capabilities_by_type := {}


func _enter_tree():
	# Load from project settings
	_load_configuration()
	
	# At runtime, always build the database from the filesystem's source of truth.
	# We prevent this from running automatically in the editor to avoid unwanted builds
	# every time the scene is loaded. The editor build is manual via the button.
	if not Engine.is_editor_hint():
		_build_databases()


func _load_configuration():
	source_directory = ProjectSettings.get_setting(SOURCE_DIR_SETTING, "res://items")
	catalogue_save_path = ProjectSettings.get_setting(SAVE_PATH_SETTING, "res://generated/item_catalogue.tres")


## (Editor-Only) The single entry point for the Inspector tool button.
func _force_build_and_save_catalogue():
	if not Engine.is_editor_hint():
		print_rich("[color=orange][ItemDatabase] This function is for editor use only.[/color]")
		return
	
	print("[ItemDatabase] Editor tool: Forcing database rebuild and saving catalogue...")
	_load_configuration() # Ensure paths are up-to-date before running
	_build_databases()
	_save_catalogue_resource()
	print("[ItemDatabase] Editor tool: Process complete.")


## Builds all in-memory item databases from scratch by scanning the project files.
func _build_databases():
	print("[ItemDatabase] Starting database build from: %s" % source_directory)
	items_by_id.clear()
	capabilities_by_type.clear()
	
	var all_item_resources: Array[ItemResource] = []
	_scan_for_resources(source_directory, all_item_resources)
	
	for item in all_item_resources:
		if item == null:
			push_warning("Found a null item resource during scan.")
			continue
		if item.id == StringName(""):
			push_error("Item missing ID at path: %s" % item.resource_path)
			continue
		if items_by_id.has(item.id):
			push_error("Duplicate item ID found: '%s'" % item.id)
			continue
		
		items_by_id[item.id] = item
		
		for cap in item.capabilities:
			if cap == null:
				push_warning("Item '%s' has a null capability slot." % item.id)
				continue
			
			var cap_type = cap.get_script()
			if not capabilities_by_type.has(cap_type):
				capabilities_by_type[cap_type] = {}
			
			capabilities_by_type[cap_type][item.id] = cap
			
	print("[ItemDatabase] Build complete. Registered %d items and %d capability types." % [items_by_id.size(), capabilities_by_type.size()])


## Performs a recursive scan of a directory to find all ItemResource files.
func _scan_for_resources(path: String, results: Array[ItemResource]):
	var dir = DirAccess.open(path)
	if not dir:
		push_error("ItemDatabase: Failed to open directory: %s" % path)
		return

	for file_name in dir.get_files():
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var resource = load(path.path_join(file_name))
			if resource is ItemResource:
				results.append(resource)

	for dir_name in dir.get_directories():
		if dir_name.begins_with("."):
			continue
		_scan_for_resources(path.path_join(dir_name), results)


## (Editor-Only) Populates and saves an ItemCatalogue resource to disk.
func _save_catalogue_resource():
	var catalogue = ItemCatalogue.new()
	catalogue.items_by_id = items_by_id
	
	var serializable_caps := {}
	for script_key in capabilities_by_type:
		var path_key = script_key.resource_path
		serializable_caps[path_key] = capabilities_by_type[script_key]
	catalogue.capabilities_by_script_path = serializable_caps
	
	DirAccess.make_dir_recursive_absolute(catalogue_save_path.get_base_dir())
	
	var save_result = ResourceSaver.save(catalogue, catalogue_save_path)
	if save_result == OK:
		print("[ItemDatabase] Designer catalogue successfully saved to: %s" % catalogue_save_path)
	else:
		push_error("[ItemDatabase] Failed to save designer catalogue. Error code: %s" % save_result)


# --- Public API ---

func get_item_by_id(id: StringName) -> ItemResource:
	return items_by_id.get(id, null)

func get_capability_for_item(item_id: StringName, capability_script: Script) -> ItemCapability:
	if capabilities_by_type.has(capability_script):
		return capabilities_by_type[capability_script].get(item_id, null)
	return null

func get_all_with_capability(capability_script: Script) -> Dictionary:
	return capabilities_by_type.get(capability_script, {})
