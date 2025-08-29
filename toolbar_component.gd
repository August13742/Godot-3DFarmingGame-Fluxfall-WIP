class_name ToolbarComponent
extends Node

signal active_slot_changed(new_index: int)

# The array should hold InventorySlot objects, just like the main inventory.
var slots: Array[InventorySlot] = []
var active_slot_index: int = -1

func _ready():
	# Define the number of slots for the toolbar.
	var toolbar_size = 10 
	slots.resize(toolbar_size)
	
	for i in range(toolbar_size):
		var new_slot = InventorySlot.new()
		new_slot.parent_inventory = self 
		slots[i] = new_slot
		
	# Add a seed for testing purposes.
	_add_test_item()

func set_active_slot(index: int):
	if index == active_slot_index: return

	if index >= 0 and index < slots.size():
		active_slot_index = index
	else:
		active_slot_index = -1

	active_slot_changed.emit(active_slot_index)

func get_active_item() -> ItemInstance:
	if active_slot_index != -1 and not slots[active_slot_index].is_empty():
		return slots[active_slot_index].item_instance
	return null

# Helper function for testing.
func _add_test_item():
	var seed_instance = ItemInstance.new()
	seed_instance.id = &"tomato_seed"
	seed_instance.count = 20
	# Place the item instance inside the InventorySlot wrapper at index 0.
	slots[0].item_instance = seed_instance
	
	var water_instance = ItemInstance.new()
	water_instance.id = &"watering_can"
	water_instance.count = 1
	# Place the item instance inside the InventorySlot wrapper at index 0.
	slots[3].item_instance = water_instance
	
	
