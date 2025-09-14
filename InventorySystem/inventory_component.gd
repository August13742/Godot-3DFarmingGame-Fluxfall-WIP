extends Node
class_name InventoryComponent
enum Category {
	UNCATEGORIZED,
	PLAYER,
	NPC,
	STORAGE_CONTAINER,
	MERCHANT,
	QUEST_ITEM_HOLDER
}
@export var category: Category = Category.UNCATEGORIZED
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
		return remaining

	var max_stack := template.stack_size

	# First pass: stack
	for slot in inventory:
		if not slot.is_empty() and slot.item_instance.id == item_id and slot.item_instance.count < max_stack:
			var can_add: int = min(remaining, max_stack - slot.item_instance.count)
			slot.item_instance.count += can_add
			remaining -= can_add
			update_inventory(slot)
			if remaining == 0: break

	# Second pass: fill empty if amount exceeds previous slot's capacity
	if remaining > 0:
		for slot in inventory:
			if slot.is_empty():
				var new_instance := ItemInstance.new()
				new_instance.id = item_id
				
				var can_add: int = min(remaining, max_stack)
				new_instance.count = can_add
				remaining -= can_add
				
				slot.item_instance = new_instance
				update_inventory(slot)
				if remaining == 0: break

	var total_added = amount - remaining
	if total_added > 0:
		_push_item_notification(item_id, total_added)

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

## Checks if any single item type in the inventory has the specified capability and meets the minimum stack size.
func has_stack_with_capability(capability_script: Script, min_stack_size: int = 1) -> bool:
	if min_stack_size <= 0: return true

	var all_owned_with_cap := get_all_owned_items_with_capability(capability_script)
	for count in all_owned_with_cap.values():
		if count >= min_stack_size:
			return true
			
	return false
	
## Checks if the combined total of all items with a given capability meets the required amount.
func has_total_with_capability(capability_script: Script, required_total: int = 1) -> bool:
	if required_total <= 0: return true

	var count_so_far := 0
	var items_with_cap: Dictionary = ItemDatabase.get_all_item_with_capability(capability_script)

	if items_with_cap.is_empty(): return false

	for slot in inventory:
		if not slot.is_empty() and items_with_cap.has(slot.item_instance.id):
			count_so_far += slot.item_instance.count
			if count_so_far >= required_total:
				return true
	
	return false
func get_all_owned_items_with_capability(capability_script: Script) -> Dictionary:
	var result: Dictionary[StringName, int] = {}
	
	var items_with_cap: Dictionary = ItemDatabase.get_all_item_with_capability(capability_script)
	if items_with_cap.is_empty():
		return result

	for slot in inventory:
		if not slot.is_empty():
			var item_id: StringName = slot.item_instance.id

			if items_with_cap.has(item_id):
				result[item_id] = result.get(item_id, 0) + slot.item_instance.count
				
	return result

func update_inventory(slot:InventorySlot):
	EventSystem.emit_INV_item_pickup_successful(slot)

func get_first_item_with_capability(capability_script: Script) -> ItemInstance:
	for slot in inventory:
		if not slot.is_empty():
			# Get the item's static data once
			var item_template: ItemResource = ItemDatabase.get_item_by_id(slot.item_instance.id)
			# Check the template directly
			if item_template and item_template.has_capability(capability_script):
				return slot.item_instance # Success, return immediately
	return null
