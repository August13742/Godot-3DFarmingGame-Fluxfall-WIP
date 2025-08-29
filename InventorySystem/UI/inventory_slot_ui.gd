extends TextureRect
class_name InventorySlotUI


@onready var item_icon: TextureRect = %ItemIcon
@onready var slot_texture = item_icon.texture
@onready var slot_counter_label:Label = $%Counter

var connected_inventory_slot:InventorySlot = null
func _get_drag_data(_at_position: Vector2) -> Variant:
	if connected_inventory_slot.is_empty():
		return null

	# Package the necessary data.
	var data = {
		"source_slot_index": self.get_index(), # The slot's position in the grid
		"source_inventory": connected_inventory_slot.get_parent_inventory(), # A reference to the Inventory/Toolbar component
		"item": connected_inventory_slot.item_instance,
	}

	# Create a preview that follows the mouse.
	var preview := TextureRect.new()
	preview.size = Vector2(128, 128)
	preview.expand_mode = TextureRect.ExpandMode.EXPAND_FIT_HEIGHT_PROPORTIONAL
	preview.texture = item_icon.texture # The item's icon
	set_drag_preview(preview)
	
	return data
	
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("source_inventory")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var source_inventory = data["source_inventory"]
	var source_slot_index = data["source_slot_index"]
	
	var target_inventory = connected_inventory_slot.get_parent_inventory()
	var target_slot_index = self.get_index()

	# To prevent bugs, don't drop an item onto itself.
	if source_inventory == target_inventory and source_slot_index == target_slot_index:
		return
		
	InventoryManager.swap_items(
		source_inventory,
		source_slot_index,
		target_inventory,
		target_slot_index
	)
