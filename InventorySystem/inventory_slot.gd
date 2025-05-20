extends RefCounted
class_name InventorySlot


var item_id:StringName = &"null"
var count:int = 0
var connected_inventory_scene:InventorySlotUI = null


func is_empty() -> bool:
	return item_id == &"null"
