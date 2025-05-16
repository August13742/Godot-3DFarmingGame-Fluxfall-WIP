extends Node


signal BUL_create_bulletin(key:int, prompt:String)
signal BUL_destroy_bulletin(key:int)

func emit_BUL_create_bulletin(key:int, prompt:String):
	BUL_create_bulletin.emit(key,prompt)

func emit_BUL_destroy_bulletin(key:int):
	BUL_destroy_bulletin.emit(key)



signal INV_try_pick_up_item(item_key:ItemDB.Keys,follow_up:Callable)
signal INV_item_pickup_successful(slot:InventorySlot)
func emit_INV_try_pick_up_item(item_key:ItemDB.Keys,follow_up:Callable):
	INV_try_pick_up_item.emit(item_key,follow_up)

func emit_INV_item_pickup_successful(slot:InventorySlot):
	INV_item_pickup_successful.emit(slot)


#signal INT_begin_interaction(station_type,follow_up:Callable)
signal INT_begin_interaction()
func emit_INT_begin_interaction():
	INT_begin_interaction.emit()
