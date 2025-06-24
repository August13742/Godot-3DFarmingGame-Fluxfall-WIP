extends Node

## Billboard System
signal BUL_create_bulletin(key:int, prompt:String)
signal BUL_destroy_bulletin(key:int)

func emit_BUL_create_bulletin(key:int, prompt:String):
	BUL_create_bulletin.emit(key,prompt)

func emit_BUL_destroy_bulletin(key:int):
	BUL_destroy_bulletin.emit(key)

## Crop System
signal CROP_growth_tick_emitted
func emit_CROP_growth_tick_emitted():
	CROP_growth_tick_emitted.emit()

## Inventory System
signal INV_try_pick_up_item(item_id:StringName,follow_up:Callable)
signal INV_item_pickup_successful(slot:InventorySlot)
func emit_INV_try_pick_up_item(item_id:StringName,follow_up:Callable):
	INV_try_pick_up_item.emit(item_id,follow_up)

func emit_INV_item_pickup_successful(slot:InventorySlot):
	INV_item_pickup_successful.emit(slot)


#signal INT_begin_interaction(station_type,follow_up:Callable)
signal INT_begin_interaction(follow_up:Callable)
func emit_INT_begin_interaction(follow_up:Callable=do_nothing):
	INT_begin_interaction.emit(follow_up)
func do_nothing():
	pass


## Game Events
signal GAME_NEW_DAY
func emit_GAME_NEW_DAY():
	GAME_NEW_DAY.emit()
