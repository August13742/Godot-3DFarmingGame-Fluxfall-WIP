extends Node


var item_data := preload("res://Items/DataBase/item_db.gd")



func get_item_resource(key:ItemDB.Keys) -> ItemResource:
	return load(ItemDB.PATHS.get(key))

func get_stack_size(key:ItemDB.Keys)->int:
	return get_item_resource(key).stack_size

func get_item_name(key:ItemDB.Keys)->String:
	return get_item_resource(key).display_name

func get_item_texture(key)->Texture2D:
	if key is ItemDB.Keys:
		return get_item_resource(key).icon
	return null
