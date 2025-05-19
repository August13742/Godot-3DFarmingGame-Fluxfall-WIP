extends Node

var item_db := preload("res://Items/DataBase/item_db.gd")

func get_item_resource(id: StringName) -> ItemResource:
	var path = item_db.PATHS.get(String(id).to_lower())
	return null if path == null else load(path)

func get_stack_size(id: StringName) -> int:
	var item = get_item_resource(id)
	return 0 if item == null else item.stack_size

func get_item_name(id: StringName) -> String:
	var item = get_item_resource(id)
	return "ERROR" if item == null else item.display_name

func get_item_texture(id: StringName) -> Texture2D:
	var item = get_item_resource(id)
	return null if item == null else item.icon

func get_craftable_recipe(id: StringName) -> Dictionary:
	var item = get_item_resource(id)
	return {} if item == null or not (item is CraftableResource) else item.required_material
