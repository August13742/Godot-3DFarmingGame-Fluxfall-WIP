extends Node


var item_data := preload("res://Items/DataBase/item_db.gd")



func get_item_resource(key:ItemDB.Keys) -> ItemResource:
	if key == ItemDB.Keys.NULL:
		return null
	return load(ItemDB.PATHS.get(key))

func get_stack_size(key:ItemDB.Keys)->int:
	var loaded_item:ItemResource = get_item_resource(key)
	return 0 if loaded_item == null else loaded_item.stack_size

func get_item_name(key:ItemDB.Keys)->String:
	var loaded_item:ItemResource = get_item_resource(key)
	return "ERROR" if loaded_item == null else loaded_item.display_name

func get_item_texture(key:ItemDB.Keys)->Texture2D:
	var loaded_item:ItemResource = get_item_resource(key)
	return null if loaded_item == null else loaded_item.icon


func get_craftable_recipe(key:ItemDB.Keys)->Dictionary[ItemDB.Keys,int]:
	var loaded_item:CraftableResource = load(ItemDB.PATHS.get(key))
	var recipe:Dictionary = loaded_item.required_material
	return {} if loaded_item == null else recipe
