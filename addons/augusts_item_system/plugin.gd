@tool
extends EditorPlugin


const ITEM_DATABASE_SINGLETON_NAME = "ItemDatabase"
const ADDON_BASE_PATH = "res://addons/augusts_item_system"
const ITEM_DATABASE_SCRIPT_PATH = ADDON_BASE_PATH+"/item_database.gd"

# Define paths for the new project settings
const SOURCE_DIR_SETTING = "augusts_item_system/database/source_directory"
const SAVE_PATH_SETTING = "augusts_item_system/database/catalogue_save_path"


func _enter_tree():
	# --- Create Project Settings ---
	# This makes the plugin configurable from the Project > Project Settings menu.
	_define_project_setting(SOURCE_DIR_SETTING, "res://Items/Resources", TYPE_STRING, PROPERTY_HINT_DIR)
	_define_project_setting(SAVE_PATH_SETTING, "res://Items/_Generated/item_catalogue.tres", TYPE_STRING, PROPERTY_HINT_FILE, "*.tres")

	# --- Register Singleton ---
	add_autoload_singleton(ITEM_DATABASE_SINGLETON_NAME, ITEM_DATABASE_SCRIPT_PATH)

	# --- Register Custom Types ---
	add_custom_type("ItemResource", "Resource",
	preload(ADDON_BASE_PATH+"/item_resource.gd"),
	preload(ADDON_BASE_PATH+"/icons/icon_parchment.png"))
	add_custom_type("ItemCapability", "Resource",
	preload(ADDON_BASE_PATH+"/item_capability.gd"),
	preload(ADDON_BASE_PATH+"/icons/icon_gear.png")
	)

	add_tool_menu_item("Item System/Rebuild Catalogue", _on_rebuild)


func _exit_tree():
	# Clean up when the plugin is disabled to keep the project clean.
	remove_autoload_singleton(ITEM_DATABASE_SINGLETON_NAME)
	remove_custom_type("ItemResource")
	remove_custom_type("ItemCapability")
	remove_tool_menu_item("Item System/Rebuild Catalogue")
	# Note: Project settings are not removed automatically. This is standard Godot behavior.


## Helper to create a new project setting if it doesn't already exist.
func _define_project_setting(name: String, default_value, type: int, hint: int = PROPERTY_HINT_NONE, hint_string: String = ""):
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, default_value)

	var setting_info = {
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string
	}
	ProjectSettings.add_property_info(setting_info)

## (Editor-Only) Callback for the "Item System/Rebuild Catalogue" menu item.
func _on_rebuild():
	# We don't get the singleton, as it only exists at runtime.
	# Instead, we create a temporary instance of the database script
	# to gain access to its editor-only building functions.
	var db_script = load(ADDON_BASE_PATH+"/item_database.gd")
	if not db_script:
		push_error("[ItemSystem] Could not load the ItemDatabase script.")
		return

	var temp_db_instance = db_script.new()

	var editor_root = EditorInterface.get_editor_main_screen()
	editor_root.add_child(temp_db_instance)

	temp_db_instance._force_build_and_save_catalogue()
	temp_db_instance.queue_free()

	print_rich("[color=green][ItemSystem] Rebuild process finished. Check output log for details.[/color]")
