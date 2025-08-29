extends GridContainer
class_name InventoryGrid

@export var inventory_slot_ui:PackedScene = preload("uid://c8ig8nq7ir5ki")
@export var inventory_size = 28
@export var target_entity:Node

var target_inventory:InventoryComponent

func _ready():
	EventSystem.INV_item_pickup_successful.connect(_on_item_pickup_successful)
	_initiate.call_deferred()

func _initiate():
	var inventory = InventoryManager.player_inventory
	if inventory == null:
		print_debug("[Debug/Referencing]: Player inventory not yet registered.")
		return

	inventory_size = inventory.inventory_size
	for i in range(inventory_size):
		var inventory_slot_scene: InventorySlotUI = inventory_slot_ui.instantiate()
		add_child(inventory_slot_scene)

		inventory_slot_scene.connected_inventory_slot = inventory.inventory[i]
		update_texture_and_count.call_deferred(inventory_slot_scene)
	
	InventoryManager.request_refresh.connect(_on_refresh_requested)
		


func update_texture_and_count(inventory_slot_scene: InventorySlotUI):
	var inventory_slot_data: InventorySlot = inventory_slot_scene.connected_inventory_slot
	
	if inventory_slot_data.is_empty():

		inventory_slot_scene.item_icon.texture = null
		inventory_slot_scene.slot_counter_label.text = ""
		return

	var instance: ItemInstance = inventory_slot_data.item_instance
	var template: ItemResource = ItemRegistry.get_by_id(instance.id)

	if not template:
		push_error("Inventory UI: Could not find template for item ID: %s" % instance.id)
		return

	inventory_slot_scene.item_icon.texture = template.icon
	
	# Show count only if greater than 1
	if instance.count > 1:
		inventory_slot_scene.slot_counter_label.text = str(instance.count)
	else:
		inventory_slot_scene.slot_counter_label.text = ""

func _on_item_pickup_successful(slot: InventorySlot):
	update_texture_and_count(slot.connected_inventory_scene)

func _on_refresh_requested(target_slot_data: InventorySlot) -> void:
	for child in get_children():
		if child is InventorySlotUI:
			var ui_slot: InventorySlotUI = child
			if ui_slot.connected_inventory_slot == target_slot_data:
				update_texture_and_count(ui_slot)
				return
