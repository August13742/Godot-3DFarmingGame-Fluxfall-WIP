extends Control

@onready var slot_container: GridContainer = $MarginContainer/GridContainer

var toolbar_component: ToolbarComponent = null

func _ready():
	# Wait until the scene tree is ready to ensure the player exists.
	call_deferred("initialise_hotbar")

func initialise_hotbar():
	# Find the player's toolbar data component.
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("ToolbarComponent"):
		toolbar_component = player.get_node("ToolbarComponent")
	else:
		push_error("HotbarController: Could not find player's ToolbarComponent.")
		return
	
	# Connect to signals to stay in sync with data changes.
	toolbar_component.active_slot_changed.connect(_on_active_slot_changed)
	InventoryManager.request_refresh.connect(_on_inventory_refresh_requested)

	# Perform the initial UI setup: link UI slots to data slots.
	bind_slots_to_data()
	# Set the initial highlight based on the active slot.
	_on_active_slot_changed(toolbar_component.active_slot_index)
	
func bind_slots_to_data():
	if not toolbar_component: return

	var ui_slots = slot_container.get_children()
	var data_slots = toolbar_component.slots
	var slot_count = min(ui_slots.size(), data_slots.size())

	for i in range(slot_count):
		var ui_slot: InventorySlotUI = ui_slots[i]
		var data_slot: InventorySlot = data_slots[i]
		
		ui_slot.connected_inventory_slot = data_slot
		update_slot_visuals(ui_slot)
		
func _unhandled_input(event: InputEvent):
	if not toolbar_component: return

	# Loop through keys 1-9 and then 0.
	for i in range(10):
		# This maps keyboard key '1' to index 0, '2' to 1, ..., '0' to 9.
		var key_index = i
		var action_name = "hotbar_%d" % ((key_index + 1) % 10) 

		if event.is_action_pressed(action_name):
			toolbar_component.set_active_slot(key_index)
			get_viewport().set_input_as_handled()
			
func update_slot_visuals(ui_slot: InventorySlotUI):
	var data_slot = ui_slot.connected_inventory_slot
	if not data_slot or data_slot.is_empty():
		ui_slot.item_icon.texture = null
		ui_slot.slot_counter_label.text = ""
		return
		
	var instance = data_slot.item_instance
	var template = ItemDatabase.get_item_by_id(instance.id)
	
	ui_slot.item_icon.texture = template.icon
	ui_slot.slot_counter_label.text = str(instance.count) if instance.count > 1 else ""
func _on_active_slot_changed(new_index: int):
	var ui_slots = slot_container.get_children()
	for i in range(ui_slots.size()):
		var ui_slot: InventorySlotUI = ui_slots[i]
		if i == new_index:
			ui_slot.self_modulate = Color.WHITE # Highlighted
		else:
			ui_slot.self_modulate = Color(0.6, 0.6, 0.6) # Dimmed
func _on_inventory_refresh_requested(target_slot_data: InventorySlot):
	for ui_slot in slot_container.get_children():
		if ui_slot.connected_inventory_slot == target_slot_data:
			update_slot_visuals(ui_slot)
			return
