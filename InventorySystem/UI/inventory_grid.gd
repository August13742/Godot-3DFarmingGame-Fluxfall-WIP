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
		var inventory_slot_scene:InventorySlotUI = inventory_slot_ui.instantiate()
		add_child(inventory_slot_scene)

		inventory_slot_scene.connected_inventory_slot = inventory.inventory[i]
		inventory.inventory[i].connected_inventory_scene = inventory_slot_scene

		update_texture_and_count.call_deferred(inventory_slot_scene)


func update_texture_and_count(inventory_slot_scene:InventorySlotUI):
	var texture:Texture2D = ItemDBUtility.get_item_texture(inventory_slot_scene.connected_inventory_slot.item_id)
	if texture == null:
		inventory_slot_scene.slot_counter_label.text = ""
		return

	inventory_slot_scene.texture = \
			ItemDBUtility.get_item_texture(inventory_slot_scene.connected_inventory_slot.item_id)

	inventory_slot_scene.slot_counter_label.text = str(inventory_slot_scene.connected_inventory_slot.count)


func _on_item_pickup_successful(slot:InventorySlot):
	update_texture_and_count(slot.connected_inventory_scene)
