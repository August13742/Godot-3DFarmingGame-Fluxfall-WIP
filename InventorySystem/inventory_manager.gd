extends Node

@export var inventory_size:int = 30

var inventory:Array[Slot] = []



func _enter_tree() -> void:
	EventSystem.INV_try_pick_up_item.connect(_on_try_to_pick_up_item)
	
func _ready():
	inventory.resize(inventory_size)
	for i in inventory_size:
		inventory[i] = Slot.new()
	
## @experimental does not handle if inventory is too full
func _on_try_to_pick_up_item(item_key:ItemDB.Keys, destroy_pickuppable:Callable) -> void:
	if add_item(item_key) != 0:
		print("Inventory is Too FULL")
		return
	destroy_pickuppable.call()

	
func get_free_slots()->bool:
	var free:=0
	for slot in inventory:
		if slot.is_empty():
			free +=1
	return free

## @experimental does not handle if inventory is too full
func add_item(item_key:ItemDB.Keys, amount:int = 1)-> int:
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

class Slot:
	var item_key = null
	var count:int = 0
	
	func is_empty() -> bool:
		if item_key == null:
			count = 0
			return true
		return false
