extends Control
class_name CraftingMenu

@onready var craftables_list: ItemList = %CraftablesList
@onready var target_item_icon: TextureRect = %TargetItemIcon
@onready var item_name: Label = %ItemName
@onready var item_description: Label = %ItemDescription
@onready var tag_icon: TextureRect = %TagIcon

@onready var crafting_slot_container: HBoxContainer = %CraftingSlotContainer

@onready var craft_button: Button = %CraftButton
@export var crafting_slot_scene:PackedScene = preload("uid://df0q2yifj6pdv")

var item_cache: Array[ItemResource] = []

func _ready() -> void:

	for item_id in ItemRegistry.by_id:
		var item_resource: ItemResource = ItemRegistry.get_by_id(item_id)

		if item_resource and item_resource.has_capability(CraftingCapability):
			craftables_list.add_item(item_resource.display_name, item_resource.icon)
			item_cache.append(item_resource)

	craftables_list.item_selected.connect(_on_craftable_selected)
	craft_button.pressed.connect(_on_button_pressed)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

var can_craft: bool = false
var current_craft_resource: ItemResource = null # Store the full resource

func _on_craftable_selected(index: int):

	for child in crafting_slot_container.get_children():
		child.queue_free()

	current_craft_resource = item_cache[index]

	target_item_icon.texture = current_craft_resource.icon
	item_name.text = current_craft_resource.display_name
	item_description.text = current_craft_resource.description

	var player_inventory = InventoryManager.get_inventory(get_tree().get_first_node_in_group("player"))
	if not player_inventory:
		push_error("CraftingMenu: Player inventory not found.")
		craft_button.disabled = true
		return

	var crafting_cap: CraftingCapability = current_craft_resource.get_capability(CraftingCapability)
	if not crafting_cap:
		push_error("Item '%s' is in crafting list but has no CraftingCap." % current_craft_resource.id)
		return

	var can_craft_all = true # Assume true, invalidate if any are missing

	for material_id in crafting_cap.required_materials:
		var required_amt = crafting_cap.required_materials[material_id]
		var material_resource: ItemResource = ItemRegistry.get_by_id(material_id)
		if not material_resource:
			push_warning("Invalid material ID '%s' in recipe for '%s'" % [material_id, current_craft_resource.id])
			continue

		var crafting_slot = crafting_slot_scene.instantiate()
		crafting_slot_container.add_child(crafting_slot)
		crafting_slot.icon.texture = material_resource.icon

		var owned_count = player_inventory.get_item_count(material_id)

		crafting_slot.count.text = "%d / %d" % [owned_count, required_amt]
		if owned_count < required_amt:
			crafting_slot.count.add_theme_color_override("font_color", Color.FIREBRICK)
			can_craft_all = false

	can_craft = can_craft_all
	craft_button.disabled = not can_craft_all

func _on_button_pressed():
	if can_craft and craft_item():
		print("Crafted successfully!")
		# Refresh the view to show updated material counts
		_on_craftable_selected(craftables_list.get_selected_items()[0])
	else:
		print("Craft failed.")

func craft_item() -> bool:
	if not current_craft_resource: return false

	var player_inventory = InventoryManager.get_inventory(get_tree().get_first_node_in_group("player"))
	var crafting_cap: CraftingCapability = current_craft_resource.get_capability(CraftingCapability)

	# This pre-check is technically redundant if `can_craft` is trusted, but it's safe.
	for material_id in crafting_cap.required_materials:
		var required_amt = crafting_cap.required_materials[material_id]
		if player_inventory.get_item_count(material_id) < required_amt:
			return false # Failsafe check

	# Remove required materials using the inventory's own logic.
	for material_id in crafting_cap.required_materials:
		var required_amt = crafting_cap.required_materials[material_id]
		player_inventory.remove_item(material_id, required_amt)

	# Add the crafted item.
	var add_result = player_inventory.add_item(current_craft_resource.id, 1) # Assumes crafting yields 1
	if add_result != 0:
		push_warning("Inventory full. Crafted item was not added.")
		# Optional: Drop item in world here.

	return true

func _exit_tree() -> void:
	get_tree().paused = false
	Input.set_deferred("mouse_mode",Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free.call_deferred()
