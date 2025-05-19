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

var item_cache:Array[CraftableResource] = []
var key_cache:Array[StringName] = []
func _ready() -> void:
	## change target enum for unlocked recipe instead of everything
	for craftable in ItemDB.CRAFTABLES:
		var craftable_item:CraftableResource = load(ItemDB.CRAFTABLES[craftable])

		craftables_list.add_item(craftable_item.display_name,craftable_item.icon)
		item_cache.append(craftable_item)
		key_cache.append(craftable)



	craftables_list.item_selected.connect(_on_craftable_selected)
	craft_button.pressed.connect(_on_button_pressed)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

var can_craft:bool = false
var current_item:int
var current_craft:StringName
func _on_craftable_selected(index:int):
	# Clear previous slots
	for child in crafting_slot_container.get_children():
		child.queue_free()
	current_item = index
	var craftable_item = item_cache[index]
	current_craft = key_cache[index]

	target_item_icon.texture = craftable_item.icon
	item_name.text = craftable_item.display_name
	item_description.text = craftable_item.description

	var can_craft_all = true  # Assume true, invalidate if any are missing

	for item_id in craftable_item.required_material.keys():
		var required_amt = craftable_item.required_material[item_id]
		var resource = ItemDBUtility.get_item_resource(item_id)
		var crafting_slot = crafting_slot_scene.instantiate()
		crafting_slot_container.add_child(crafting_slot)
		crafting_slot.icon.texture = resource.icon

		# Count total owned for this material
		var owned_count = 0
		for slot in InventoryManager.get_inventory(get_tree().get_first_node_in_group("player")).inventory:
			if slot.item_id == item_id:
				owned_count += slot.count

		crafting_slot.count.text = "%d / %d" % [owned_count, required_amt]
		if owned_count < required_amt:
			crafting_slot.count.add_theme_color_override("font_color", Color(1,0,0))
			can_craft_all = false

	can_craft = can_craft_all
	craft_button.disabled = not can_craft_all

func _on_button_pressed():
	if can_craft and craft_item(current_craft):
		print("Crafted successfully!")
	else:
		print("Craft failed.")

func craft_item(target_item: StringName) -> bool:
	var craftable_item = ItemDBUtility.get_item_resource(target_item)
	if not craftable_item:
		push_error("Invalid craftable item key: %s" % str(target_item))
		return false

	# verify have enough of each required material
	var player_inventory = InventoryManager.get_inventory(get_tree().get_first_node_in_group("player")).inventory
	for item_id in craftable_item.required_material.keys():
		var required_amt = craftable_item.required_material[item_id]
		var owned_count = 0
		for slot in player_inventory:
			if slot.item_id == item_id:
				owned_count += slot.count
		if owned_count < required_amt:
			print("Not enough %s to craft %s" % [ItemDBUtility.get_item_name(item_id), ItemDBUtility.get_item_name(target_item)])
			return false  # Insufficient materials

	# Remove required materials
	for item_id in craftable_item.required_material.keys():
		var required_amt = craftable_item.required_material[item_id]
		var removed = InventoryManager.remove_item_from_inventory(player_inventory,item_id, required_amt)
		if removed < required_amt:
			push_error("Material removal failed for %s" % ItemDBUtility.get_item_name(item_id))
			return false

	# Add the crafted item(s)
	var add_result = InventoryManager.add_item_to_inventory(player_inventory, target_item, 1) # Assume craft yields 1
	if add_result != 0:
		push_warning("Crafted item could not be fully added to inventory (inventory full).")
		## add Optional here: Drop item in world, etc.

	_on_craftable_selected(current_item) ## refreshes page
	return true

func _exit_tree() -> void:
	get_tree().paused = false
	Input.set_deferred("mouse_mode",Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free.call_deferred()
