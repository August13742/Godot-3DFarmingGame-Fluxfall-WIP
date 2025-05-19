extends Node
class_name InventoryComponent


@export var inventory_size:int = 28

var inventory:Array[InventorySlot] = []


func _enter_tree() -> void:
	EventSystem.INV_try_pick_up_item.connect(_on_try_to_pick_up_item)

func _ready():
	inventory.resize(inventory_size)
	for i in inventory_size:
		inventory[i] = InventorySlot.new()

	if owner.is_in_group("player"):
		InventoryManager.register_inventory(owner, self)

## @experimental does not handle if inventory is too full
func _on_try_to_pick_up_item(item_id:StringName, destroy_pickuppable:Callable) -> void:
	if add_item(item_id) != 0:
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
func add_item(item_id:StringName, amount:int = 1)-> int:
	var remaining := amount
	var max_stack := ItemDBUtility.get_stack_size(item_id)

	## try to stack into existing slot first
	for slot in inventory:
		if slot.item_id == item_id and slot.count < max_stack:
			var can_add:int = min(max_stack - slot.count, remaining)
			slot.count += can_add
			remaining -= can_add
			update_inventory(slot)
			if remaining == 0:
				printt(ItemDBUtility.get_item_name(slot.item_id),slot.count)

				return 0

	## try empty slots
	for slot in inventory:
		if slot.is_empty():
			slot.item_id = item_id
			slot.count = min(remaining, max_stack)
			remaining -= slot.count
			update_inventory(slot)
			if remaining == 0:
				printt(ItemDBUtility.get_item_name(slot.item_id),slot.count)

				return 0 ## if none left inventory has capacity
	return remaining ## inventory is too full

func remove_item(item_id: StringName, amount: int = 1) -> int:
	var to_remove := amount
	for slot in inventory:
		if slot.item_id == item_id and slot.count > 0:
			var remove_now:int = min(slot.count, to_remove)
			slot.count -= remove_now
			to_remove -= remove_now
			update_inventory(slot)
			if slot.count == 0:
				slot.item_id = &"null"  # Mark as empty, triggers is_empty() in slot.
			if to_remove == 0:
				break
	return amount - to_remove  # Returns how many items were actually removed.

func update_inventory(slot:InventorySlot):
	EventSystem.emit_INV_item_pickup_successful(slot)
