extends Node
class_name InventoryComponent


@export var inventory_size:int = 28

var inventory:Array[InventorySlot] = []


func _enter_tree() -> void:
	if owner.is_in_group(&"player"):
		EventSystem.INV_try_pick_up_item.connect(_on_try_to_pick_up_item)

func _ready():
	inventory.resize(inventory_size)
	for i in inventory_size:
		inventory[i] = InventorySlot.new()
		inventory[i].parent_inventory = self
	InventoryManager.register_inventory(owner, self)

## @experimental does not handle if inventory is too full
func _on_try_to_pick_up_item(item_id:StringName, destroy_pickuppable:Callable) -> void:
	var amount := 1
	var remaining := add_item(item_id, amount)
	var added := amount - remaining
	if added <= 0:
		print("Inventory is Too FULL")
		return

	destroy_pickuppable.call()


func count_free_slots()->int:
	var free:=0
	for slot in inventory:
		if slot.is_empty():
			free +=1
	return free

func _push_item_notification(item_id:StringName,added:int):
	var tmpl: ItemResource = ItemDatabase.get_item_by_id(item_id)
	var key := StringName("loot:" + String(item_id))
	NotificationSystem.item_added(tmpl.display_name, added, 1, tmpl.icon, key)

## @experimental does not handle if inventory is too full
func add_item(item_id: StringName, amount: int = 1) -> int:
	var remaining := amount
	var template: ItemResource = ItemDatabase.get_item_by_id(item_id)
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
					_push_item_notification(item_id,can_add)
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
					_push_item_notification(item_id,can_add)
					return 0

	# If items still remain, the inventory is full.
	return remaining

## Removes a specific amount of an item.
## Returns 'true' ONLY if the full amount was successfully removed.
func remove_item(item_id: StringName, amount: int = 1) -> bool:
	# First, check if we even have enough to remove.
	if not has_item(item_id, amount):
		return false

	var to_remove := amount

	# Iterate backwards to safely handle clearing slots.
	for i in range(inventory.size() - 1, -1, -1):
		var slot = inventory[i]
		if not slot.is_empty() and slot.item_instance.id == item_id:
			var instance = slot.item_instance
			var remove_from_stack: int = min(to_remove, instance.count)

			instance.count -= remove_from_stack
			to_remove -= remove_from_stack

			if instance.count <= 0:
				slot.clear()

			update_inventory(slot)

			if to_remove == 0:
				break # We've removed everything we need to.

	# If to_remove is 0, the operation was a complete success.
	return to_remove == 0

func get_item_count(item_id: StringName) -> int:
	var total_count := 0
	for slot in inventory:
		if not slot.is_empty() and slot.item_instance.id == item_id:
			total_count += slot.item_instance.count
	return total_count

## Checks if the inventory contains at least a certain amount of an item.
func has_item(item_id: StringName, amount: int = 1) -> bool:
	return get_item_count(item_id) >= amount

func update_inventory(slot:InventorySlot):
	EventSystem.emit_INV_item_pickup_successful(slot)

func get_first_item_with_capability(capability_script:Script) -> ItemInstance:
	var items_with_capability: Dictionary = ItemDatabase.get_all_with_capability(capability_script)

	if items_with_capability.is_empty():
		return null

	for slot in inventory:
		if not slot.is_empty():
			if items_with_capability.has(slot.item_instance.id):
				return slot.item_instance # Found the first match.

	return null
