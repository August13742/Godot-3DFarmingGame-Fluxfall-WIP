extends Node

## The central registry for all inventories in the game.
var inventories: Dictionary = {}
## A direct reference to the player's inventory for convenient access.
var player_inventory: InventoryComponent = null


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


## Callback to clean up the dictionary when an inventory owner is freed.
func _on_target_exiting(target_id: int):
	if inventories.has(target_id):
		inventories.erase(target_id)
		# If the player's inventory is being removed, clear the direct reference.
		if player_inventory and player_inventory.owner.get_instance_id() == target_id:
			player_inventory = null
		print("Unregistered inventory for target ID: %s" % target_id)
