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
func add_item(item_id: StringName, amount: int = 1) -> int:
	var remaining := amount
	var template: ItemResource = ItemRegistry.get_by_id(item_id)
	if not template:
		push_error("Inventory: Attempted to add invalid item ID: %s" % item_id)
		return remaining # Return the full amount, as nothing was added.

	var max_stack := template.stack_size

	# First pass: try to stack into existing slots.
	for slot in inventory:
		if not slot.is_empty() and slot.item_instance.id == item_id:
			var instance = slot.item_instance
			if instance.count < max_stack:
				var can_add:int = min(remaining, max_stack - instance.count)
				instance.count += can_add
				remaining -= can_add
				update_inventory(slot)
				if remaining == 0:
					return 0

	# Second pass: fill empty slots.
	if remaining > 0:
		for slot in inventory:
			if slot.is_empty():
				var new_instance := ItemInstance.new()
				new_instance.id = item_id
				
				var can_add:int = min(remaining, max_stack)
				new_instance.count = can_add
				remaining -= can_add

				slot.item_instance = new_instance
				update_inventory(slot)
				if remaining == 0:
					return 0
	
	# If items still remain, the inventory is full.
	return remaining

## Removes an item from this specific inventory.
func remove_item(item_id: StringName, amount: int = 1) -> int:
	var to_remove := amount
	var removed_count := 0

	# Iterate backwards to handle slot clearing safely if you were modifying the array.
	# Not strictly necessary here but good practice.
	for i in range(inventory.size() - 1, -1, -1):
		var slot = inventory[i]
		if not slot.is_empty() and slot.item_instance.id == item_id:
			var instance = slot.item_instance
			var remove_from_stack:int = min(to_remove, instance.count)

			instance.count -= remove_from_stack
			to_remove -= remove_from_stack
			removed_count += remove_from_stack

			if instance.count <= 0:
				slot.clear() # Sets instance to null.

			update_inventory(slot)

			if to_remove == 0:
				break
	
	return removed_count # Return how many were actually removed.
	
func get_item_count(item_id: StringName) -> int:
	var total_count := 0
	for slot in inventory:
		if not slot.is_empty() and slot.item_instance.id == item_id:
			total_count += slot.item_instance.count
	return total_count
	
func update_inventory(slot:InventorySlot):
	EventSystem.emit_INV_item_pickup_successful(slot)
