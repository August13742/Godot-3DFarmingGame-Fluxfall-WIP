@tool
extends Node
# Singleton Item Database, managed by the Item System Plugin.

# --- Configuration ---
# These paths are read from Project Settings to make the plugin portable.
var source_directory: String
var catalogue_save_path: String
var handlers_directory: String
# Project Settings paths defined by the plugin.
const SOURCE_DIR_SETTING = "augusts_item_system/database/source_directory"
const SAVE_PATH_SETTING = "augusts_item_system/database/catalogue_save_path"
const HANDLERS_DIR_SETTING = "augusts_item_system/database/handlers_directory"

# --- Editor Tool ---
@export_tool_button("Rebuild Database & Generate Catalogue") var _generate_catalogue_button: Callable = _force_build_and_save_catalogue


# --- Indexed Databases ---
var items_by_id := {}
var capabilities_by_type := {}
var handler_registry := {}

func _enter_tree():
	_load_configuration()
	if not Engine.is_editor_hint():
		_build_and_validate()


func _load_configuration():
	source_directory = ProjectSettings.get_setting(SOURCE_DIR_SETTING, "res://items/resources")
	catalogue_save_path = ProjectSettings.get_setting(SAVE_PATH_SETTING, "res://items/generated/item_catalogue.tres")
	handlers_directory = ProjectSettings.get_setting(HANDLERS_DIR_SETTING, "res://items/handlers")

#region Database Auto-Construction
func _build_and_validate():
	"""The main entry point for the runtime build process."""
	_register_handlers_automatically()
	_build_databases()
	_validate_system_integrity()

func _register_handlers_automatically():
	"""
	Scans the designated handlers directory, automatically registers all valid
	capability handlers based on a strict naming convention.
	Convention: 'ExampleCapability' -> 'ExampleHandler'
	"""
	handler_registry.clear()
	print("[ItemDatabase] Starting automatic handler registration from: %s" % handlers_directory)

	var handler_scripts = _scan_for_scripts_in_dir(handlers_directory)

	for handler_script in handler_scripts:
		var handler_instance = handler_script.new()
		if not handler_instance is CapabilityHandler:
			push_warning("Script '%s' is in handlers directory but does not extend CapabilityHandler." % handler_script.resource_path)
			continue

		# Infer the capability name from the handler name via convention.
		var handler_name = handler_script.resource_path.get_file().replace(".gd", "")
		if not handler_name.ends_with("Handler"):
			push_error("Handler script '%s' does not follow the '...Handler.gd' naming convention." % handler_script.resource_path)
			continue

		var capability_name = handler_name.replace("Handler", "Capability")

		var capability_script_path = "res://addons/augusts_item_system/capabilities/%s.gd" % capability_name.to_snake_case()

		var capability_script = load(capability_script_path)
		if not capability_script:
			push_error("Could not find matching capability script for handler '%s' at expected path '%s'." % [handler_name, capability_script_path])
			continue

		handler_registry[capability_script] = handler_instance

	print("[ItemDatabase] Automatically registered %d capability handlers." % handler_registry.size())

func _validate_system_integrity():
	"""
	(Runtime-Only) Verifies that every ActionableCapability discovered
	during the build has a corresponding handler registered.
	"""
	if Engine.is_editor_hint(): return

	var validation_passed = true
	print("[ItemDatabase] Running system integrity validation...")

	for cap_script in capabilities_by_type.keys():
		if not cap_script.new() is ActionableCapability:
			continue

		if not handler_registry.has(cap_script):
			push_error("VALIDATION FAILED: The ActionableCapability '%s' has no registered handler. Ensure a correctly named handler exists in the '%s' directory." % [cap_script.resource_path, handlers_directory])
			validation_passed = false

	if validation_passed:
		print("[ItemDatabase] System integrity validation passed.")

func _scan_for_scripts_in_dir(path: String) -> Array[Script]:
	"""Helper function to recursively find all GDScript files in a directory."""
	var scripts: Array[Script] = []
	var dir = DirAccess.open(path)
	if not dir:
		push_warning("Could not open directory for script scan: %s" % path)
		return scripts

	for file_name in dir.get_files():
		if file_name.ends_with(".gd"):
			var script = load(path.path_join(file_name))
			if script:
				scripts.append(script)

	for dir_name in dir.get_directories():
		if dir_name.begins_with("."): continue
		scripts.append_array(_scan_for_scripts_in_dir(path.path_join(dir_name)))

	return scripts


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
#endregion

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

## (Editor-Only) Populates and saves an ItemCatalogue resource to disk.
func _save_catalogue_resource():
	var catalogue = ItemCatalogue.new()
	catalogue.items_by_id = items_by_id

	var serializable_caps := {}
	var capabilities_by_name = {}
	for script_key in capabilities_by_type:
		var path_key = script_key.resource_path
		serializable_caps[path_key] = capabilities_by_type[script_key]
		var cap_name = script_key.get_global_name().replace("Capability","")
		capabilities_by_name[cap_name] = capabilities_by_type[script_key]

		
	catalogue.capabilities_by_type_path = serializable_caps
	catalogue.capabilities_by_name = capabilities_by_name

	DirAccess.make_dir_recursive_absolute(catalogue_save_path.get_base_dir())

	var save_result = ResourceSaver.save(catalogue, catalogue_save_path)
	if save_result == OK:
		print("[ItemDatabase] Designer catalogue successfully saved to: %s" % catalogue_save_path)
	else:
		push_error("[ItemDatabase] Failed to save designer catalogue. Error code: %s" % save_result)


#region Public API
func get_item_by_id(id: StringName) -> ItemResource:
	return items_by_id.get(id, null)

func get_capability_resource_for_item(item_id: StringName, capability_script: Script) -> ItemCapability:
	if capabilities_by_type.has(capability_script):
		return capabilities_by_type[capability_script].get(item_id, null)
	return null

func get_all_items_with_capability(capability_class_name: Script) -> Dictionary:
	return capabilities_by_type.get(capability_class_name, {})

#endregion
