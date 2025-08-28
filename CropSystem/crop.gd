extends Node3D
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
@onready var harvest_collision: CollisionShape3D = crop_component.harvest_collision
@onready var hydration_component: HydrationComponent = %HydrationComponent
#endregion

enum Stage { Seed, Stage1, Stage2, Stage3, Harvestable }
var machine: CropStateMachine

func _ready() -> void:
	# This calculation is context-specific, so it stays here.
	@warning_ignore("integer_division")
	stages_per_visual_change = max(1, floori(stages_for_calculation / max(1, actual_stages)))
	
	# Initialize the state machine and give it a reference to this context.
	machine = CropStateMachine.new()
	machine.initialise(self)

	# Connect signals once. They will be delegated to the machine.
	EventSystem.CROP_growth_tick_emitted.connect(_on_growth_tick_emitted)
	EventSystem.GAME_NEW_DAY.connect(_reset_hydration_on_day_changed)
	hydration_component.hydrate.connect(_on_hydrate)

#region Public API (for Player/NPCs)
func plant(seed_resource: BillboardPlantResource) -> void:
	machine.on_plant(seed_resource)

func harvest() -> void:
	machine.on_harvest()
#endregion

#region Signal Handlers (delegated to machine)
func _on_growth_tick_emitted() -> void:
	machine.on_growth_tick()

func _on_hydrate() -> void:
	self.hydrated = true
	crop_bed_model.dirt_material.albedo_color = crop_bed_model.dirt_colour_wet
	hydration_component.collision_off()
	machine.on_hydrate()

func _reset_hydration_on_day_changed():
	self.hydrated = false
	if not crop_bed_model.dirt_material.resource_local_to_scene:
		crop_bed_model.dirt_material = crop_bed_model.dirt_material.duplicate(true)
	crop_bed_model.dirt_material.albedo_color = crop_bed_model.dirt_colour_wet
	# Let the current state decide how to react to a new day.
	machine.on_new_day()
#endregion

#region Utility Functions (callable by states)
func apply_billboard_stage(plant_res: BillboardPlantResource, stage: int) -> void:

	if not plant_res.has_stage(stage): return
	
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
#endregion
