extends Node


var player_inventory:InventoryComponent = null

func register_inventory(_owner:Node, inventory:InventoryComponent):
	if _owner.is_in_group("player"):
		player_inventory = inventory
	# Extend to handle more inventories like chest, npc

func get_inventory(_owner:Node) -> InventoryComponent:
	if _owner.is_in_group("player"):
		return player_inventory
	return null

func remove_item_from_inventory(inventory, item_key, amount):
	var to_remove = amount
	for slot in inventory:
		if slot.item_key == item_key and slot.count > 0:
			var remove_now = min(slot.count, to_remove)
			slot.count -= remove_now
			to_remove -= remove_now
			if slot.count == 0:
				slot.item_key = ItemDB.Keys.NULL
			if to_remove == 0:
				break
	return amount - to_remove

func add_item_to_inventory(inventory, item_key:ItemDB.Keys, amount:int = 1)-> int:
	var remaining := amount
	var max_stack := ItemDBUtility.get_stack_size(item_key)

	## try to stack into existing slot first
	for slot in inventory:
		if slot.item_key == item_key and slot.count < max_stack:
			var can_add:int = min(max_stack - slot.count, remaining)
			slot.count += can_add
			remaining -= can_add
			if remaining == 0:
				printt(ItemDBUtility.get_item_name(slot.item_key),slot.count)

				return 0

	## try empty slots
	for slot in inventory:
		if slot.is_empty():
			slot.item_key = item_key
			slot.count = min(remaining, max_stack)
			remaining -= slot.count
			if remaining == 0:
				printt(ItemDBUtility.get_item_name(slot.item_key),slot.count)

				return 0 ## if none left inventory has capacity
	return remaining ## inventory is too full
