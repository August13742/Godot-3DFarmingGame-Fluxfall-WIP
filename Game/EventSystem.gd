extends Node


signal BUL_create_bulletin(key:int, prompt:String)
signal BUL_destroy_bulletin(key:int)

func emit_BUL_create_bulletin(key:int, prompt:String):
	BUL_create_bulletin.emit(key,prompt)

func emit_BUL_destroy_bulletin(key:int):
	BUL_destroy_bulletin.emit(key)

signal INV_try_pick_up_item(item_key:ItemDB.Keys,follow_up:Callable)

func emit_INV_try_pick_up_item(item_key:ItemDB.Keys,follow_up:Callable):
	INV_try_pick_up_item.emit(item_key,follow_up)
