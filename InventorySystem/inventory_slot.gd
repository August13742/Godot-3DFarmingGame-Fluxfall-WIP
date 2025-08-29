class_name InventorySlot
extends RefCounted

var item_instance: ItemInstance = null
var parent_inventory: Node = null # Will be InventoryComponent or ToolbarComponent

func is_empty() -> bool:
	return item_instance == null

func clear()->void:
	item_instance = null

func get_parent_inventory() -> Node:
	return parent_inventory
