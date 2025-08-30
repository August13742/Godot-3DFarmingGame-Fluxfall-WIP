extends Interactable
class_name CropBed

#region Data & Properties
## How many visual stages the crop has.
@export var actual_stages: int = 4
## Internal stages for finer growth calculation.
@export var stages_for_calculation: int = 40
## Chance for growth per growth_tick.
@export var growth_chance: float = 0.75
## For debugging: forces the bed to always be hydrated.
@export var always_hydrated: bool = false

# --- State Data (managed by states, stored here) ---
var hydrated: bool = false:
	set(value):
		hydrated = value
		if always_hydrated:
			hydrated = true
var crop_resource: BillboardPlantResource
var current_stage: Stage = Stage.Seed
var current_calculation_stage: int = 0
var stages_per_visual_change: int
#endregion

#region Node References
@onready var crop_bed_model: CropBedModel = %CropBedModel
@onready var crop_component: Node3D = %CropComponent
@onready var crop: BillboardPlant = crop_component.billboard_plants
# --- DELETED REFERENCES ---
# @onready var harvest_collision: CollisionShape3D = crop_component.harvest_collision
# @onready var hydration_component: HydrationComponent = %HydrationComponent
#endregion

enum Stage { Seed, Stage1, Stage2, Stage3, Harvestable }
var machine: CropStateMachine

func _ready() -> void:
	@warning_ignore("integer_division")
	stages_per_visual_change = max(1, floori(stages_for_calculation / max(1, actual_stages)))

	machine = CropStateMachine.new()
	machine.initialise(self)

	# Connect signals once. They will be delegated to the machine.
	EventSystem.CROP_growth_tick_emitted.connect(_on_growth_tick_emitted)
	EventSystem.GAME_NEW_DAY.connect(_reset_hydration_on_day_changed)


#region Public API (for Player/NPCs)
func plant(seed_resource: BillboardPlantResource) -> void:
	machine.on_plant(seed_resource)

func harvest() -> void:
	machine.on_harvest()
#endregion

#region Signal Handlers (delegated to machine)
func _on_growth_tick_emitted() -> void:
	machine.on_growth_tick()

func _try_to_hydrate() -> void:
	if hydrated: return

	self.hydrated = true
	crop_bed_model.update_dirt_appearance(true)
	machine.on_hydrate()


func _reset_hydration_on_day_changed():
	self.hydrated = false
	crop_bed_model.update_dirt_appearance(false)
	machine.on_new_day()

#endregion

#region Utility Functions (callable by states)
func apply_billboard_stage(plant_res: BillboardPlantResource, stage: int) -> void:

	if not plant_res.has_stage_texture(stage): return

	if not is_instance_valid(plant_res) or not is_instance_valid(crop):
		return

	var mesh_ins = crop.imposter_mesh
	if not mesh_ins: return
	var p := plant_res.get_stage_params(stage)
	var mat := mesh_ins.get_active_material(0)

	if not (mat is ShaderMaterial):
		mat = ShaderMaterial.new()
		mat.shader = preload("uid://bj6xhasqh07b7")
		mesh_ins.set_surface_override_material(0, mat)

	if not mat.resource_local_to_scene:
		mat = mat.duplicate(true)
		mesh_ins.set_surface_override_material(0, mat)

	mat.set_shader_parameter("albedo_tex", plant_res.textures[stage])
	mat.set_shader_parameter("uv_rect", p["uv_rect"])
	mat.set_shader_parameter("scale_factor", p["scale_factor"])
	mat.set_shader_parameter("vertical_offset", p["vertical_offset"])

func update_prompt(source: Node = null) -> void:
	var current_prompt = ""
	if not source or not source.has_method("get_active_item_id"):
		self.prompt = ""
		return

	var active_item_id: StringName = source.get_active_item_id()
	var active_item_template: ItemResource = ItemRegistry.get_by_id(active_item_id)


	# Priority 1: Check for specific tool interactions.
	if active_item_template:
		if active_item_template.has_capability(WateringCapability) and not hydrated:
			current_prompt = "Water"
		elif active_item_template.has_capability(SeedCapability) and machine.current_state is CropEmptyState:
			current_prompt = "Plant %s" % active_item_template.display_name

	# Priority 2: Check for default actions if no tool-based prompt was set.
	if current_prompt == "" and machine.current_state is CropHarvestableState:
		var yield_id = crop_resource.harvest_yield_id
		var yield_item_template: ItemResource = ItemRegistry.get_by_id(yield_id)

		if yield_item_template:
			# We found the item, so use its display name.
			current_prompt = "Harvest %s" % yield_item_template.display_name
		else:
			# Fallback in case the ID is invalid.
			current_prompt = "Harvest"

	self.prompt = current_prompt


# helper function to check for any seed in the inventory.
func _inventory_has_seeds(inventory: InventoryComponent) -> bool:
	for slot in inventory.inventory:
		if not slot.is_empty():
			var item_template = ItemRegistry.get_by_id(slot.item_instance.id)
			if item_template and item_template.has_capability(SeedCapability):
				return true # Found at least one seed.
	return false # No seeds found.
#endregion

#region Interaction
func start_interaction(source: Node = null) -> void:
	#print("Interaction started...") # DEBUG
	if not source or not source.has_method("get_active_item_id"): return

	var inventory: InventoryComponent = InventoryManager.get_inventory(source)
	if not inventory: return

	var active_item_id: StringName = source.get_active_item_id()
	var active_item_template: ItemResource = ItemRegistry.get_by_id(active_item_id)
	#print("...Source: %s, Active Item ID: '%s'" % [source.name, active_item_id]) # DEBUG

	if active_item_template:
		#print("...Active item template is valid: %s" % active_item_template.id) # DEBUG
		if active_item_template.has_capability(WateringCapability):
			_try_to_hydrate()
			return
		elif active_item_template.has_capability(SeedCapability) and machine.current_state is CropEmptyState:
			#print("...Attempting to plant.") # DEBUG
			_try_to_plant(inventory, active_item_template)
			return

	# Priority 2: If no specific tool was used, check for default contextual actions.
	if machine.current_state is CropHarvestableState:
		#print("...Attempting to harvest.") # DEBUG
		_try_to_harvest(inventory)
		return
	#print("...No valid action found.")
# --- Private Helper for Planting ---
func _try_to_plant(inventory: InventoryComponent, seed_template: ItemResource):
	var seed_cap: SeedCapability = seed_template.get_capability(SeedCapability)
	if not seed_cap or not seed_cap.plant_resource:
		push_error("Seed item %s has a faulty SeedCapability." % seed_template.id)
		return

	var plant_res = seed_cap.plant_resource
	machine.on_plant(plant_res)

	if not machine.current_state is CropEmptyState:
		inventory.remove_item(seed_template.id, 1)


# --- Private Helper for Harvesting (now just needs inventory) ---
func _try_to_harvest(inventory: InventoryComponent):
	if not "harvest_yield_id" in crop_resource:
		push_error("Crop resource '%s' is missing harvest_yield_id." % crop_resource.resource_path)
		return

	var yield_id = crop_resource.harvest_yield_id
	var yield_amount = crop_resource.get("harvest_yield_amount")
	if yield_amount == null: yield_amount = 1

	var remaining = inventory.add_item(yield_id, yield_amount)

	if remaining == 0:
		machine.on_harvest()
	else:
		print("Inventory is full, cannot harvest.")
#endregion
