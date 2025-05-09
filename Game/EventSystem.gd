extends Node


signal BUL_create_bulletin(key:int, prompt:String)
signal BUL_destroy_bulletin(key:int)

func emit_BUL_create_bulletin(key:int, prompt:String):
	BUL_create_bulletin.emit(key,prompt)

func emit_BUL_destroy_bulletin(key:int):
	BUL_destroy_bulletin.emit(key)

signal ITEM_picked_up(node:Node)

func emit_ITEM_picked_up(node:Node):
	ITEM_picked_up.emit(node)
