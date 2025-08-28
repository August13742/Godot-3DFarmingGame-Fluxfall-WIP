class_name InventorySlot
extends RefCounted

var item_instance: ItemInstance = null
var connected_inventory_scene: InventorySlotUI = null

func is_empty() -> bool:
	return item_instance == null

func clear():
	item_instance = null
