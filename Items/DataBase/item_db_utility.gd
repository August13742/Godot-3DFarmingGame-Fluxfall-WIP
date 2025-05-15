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
	return "ERROR" if loaded_item == null else get_item_resource(key).display_name

func get_item_texture(key:ItemDB.Keys)->Texture2D:
	var loaded_item:ItemResource = get_item_resource(key)
	return null if loaded_item == null else get_item_resource(key).icon
