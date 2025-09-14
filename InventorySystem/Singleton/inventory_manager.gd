extends Node

## The central registry for all inventories in the game.
var inventories: Dictionary = {}
## A direct reference to the player's inventory for convenient access.
var player_inventory: InventoryComponent = null

signal request_refresh
## Registers an inventory component and connects to its owner's exit signal. Should be called automatically by Inventory Component
func register_inventory(target: Node, inventory: InventoryComponent):
	var target_id = target.get_instance_id()
	if inventories.has(target_id):
		push_warning("Inventory for target %s (ID: %s) is already registered." % [target.name, target_id])
		return

	inventories[target_id] = inventory
	# If the target is the player, also store the direct reference.
	if target.is_in_group("player"):
		player_inventory = inventory

	# CRITICAL: Connect to the target's exit signal to auto-unregister.
	target.tree_exiting.connect(_on_target_exiting.bind(target_id))
	print("Registered inventory for: %s (ID: %s)" % [target.name, target_id])


## Retrieves an inventory component using its owner node.
func get_inventory(target: Node) -> InventoryComponent:
	if not target is Node: return null
	var target_id = target.get_instance_id()
	return inventories.get(target_id, null)

## Returns an array of all inventories that match a given category.
func get_inventories_by_category(category_to_find: InventoryComponent.Category) -> Array[InventoryComponent]:
	var results: Array[InventoryComponent] = []
	for inventory in inventories.values():
		if inventory.category == category_to_find:
			results.append(inventory)
	return results
	
## Callback to clean up the dictionary when an inventory owner is freed.
func _on_target_exiting(target_id: int):
	if inventories.has(target_id):
		inventories.erase(target_id)
		# If the player's inventory is being removed, clear the direct reference.
		if player_inventory and player_inventory.owner.get_instance_id() == target_id:
			player_inventory = null
		print("Unregistered inventory for target ID: %s" % target_id)

func swap_items(source_inv, source_idx: int, target_inv, target_idx: int):
	if not source_inv or not target_inv:
		print("tried to swap but inv is null")
		return

	# Get the item instances from the source and target slots.
	var source_item = source_inv.inventory[source_idx].item_instance
	var target_item = target_inv.inventory[target_idx].item_instance

	# Swap the item instances.
	source_inv.inventory[source_idx].item_instance = target_item
	target_inv.inventory[target_idx].item_instance = source_item

	request_refresh.emit(source_inv.inventory[source_idx])
	request_refresh.emit(target_inv.inventory[target_idx])

## Transfers an item from a source inventory to a target inventory.
## Returns 'true' if the entire transfer was successful.
func transfer_item(source_inv: InventoryComponent, target_inv: InventoryComponent, item_id: StringName, amount: int) -> bool:
	if not source_inv or not target_inv: return false

	# Check if the source has enough items to begin with.
	if not source_inv.has_item(item_id, amount):
		return false

	# Perform the removal. assume remove_item returns 'true' on full success.
	var removal_success = source_inv.remove_item(item_id, amount)
	if not removal_success:
		# This case is tricky. It implies a partial removal might have happened.
		# A more robust system might need transaction logic, but for now, we assume failure.
		# We might need to add back what was partially removed.
		# For simplicity, we'll rely on a well-behaved remove_item.
		return false

	# Add the items to the target. 'add_item' returns the remainder.
	var remaining = target_inv.add_item(item_id, amount)

	if remaining > 0:
		# The target inventory was full. We need to give the items back to the source.
		source_inv.add_item(item_id, remaining)
		return false

	return true
