extends Object
class_name InventorySlot


var item_key:ItemDB.Keys = ItemDB.Keys.NULL
var count:int = 0
var connected_inventory_scene:InventorySlotUI = null


func is_empty() -> bool:
	if item_key == ItemDB.Keys.NULL:
		count = 0
		return true
	return false
