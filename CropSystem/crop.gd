extends Node

class_name Crop

## How many stages the visual of the crop changes
@export var actual_stages:int = 4
## fake stages for shrinking growth time variance
@export var stages_for_calculation:int = 40
## chance for growth per growth_tick
@export var growth_chance:float = 0.75

@onready var crop_pivot:Node3D = $%CropPivot
@onready var crop:BillboardPlant =crop_pivot.get_child(0)
@onready var harvest_collision:CollisionShape3D = $%HarvestCollision

@onready var hydration_component:HydrationComponent = $%HydrationComponent
var stages_per_visual_change:int
@export var always_hydrated:bool = true
var hydrated:bool = true:
	set(_a):
		if always_hydrated:
			hydrated = true

enum Stage{
	Seed,
	Stage1,
	Stage2,
	Stage3,
	Harvestable
}

var current_stage:Stage = Stage.Seed
var current_calculation_stage:int = 0
var can_harvest:bool = false
func _ready() -> void:
	EventSystem.CROP_growth_tick_emitted.connect(_on_growth_tick_emitted)
	EventSystem.GAME_NEW_DAY.connect(_reset_hydration_on_day_changed)

	@warning_ignore("integer_division")
	stages_per_visual_change = floori(stages_for_calculation / actual_stages)
	hydration_component.hydrate.connect(_on_hydrate)

	apply_billboard_stage(crop.imposter_mesh,crop.billboard_resource,current_stage)

func grow()->void:
	current_calculation_stage += 1
	var target_stage:int = floori(current_calculation_stage/(stages_per_visual_change as float))
	if target_stage != (current_stage as int):
		current_stage = target_stage as Stage
		if current_stage == Stage.Harvestable:
			harvest_collision.disabled = false
		apply_billboard_stage(crop.imposter_mesh,crop.billboard_resource,current_stage)

func _on_growth_tick_emitted()->void:
	if current_stage == Stage.Harvestable: return

	if randf()<growth_chance && hydrated:
		grow()

func apply_billboard_stage(mesh_ins: MeshInstance3D, plant_res: BillboardPlantResource, stage: int, base_height: float = 1.0) -> void:
	var p := plant_res.get_stage_params(stage, base_height)
	var mat := mesh_ins.get_active_material(0)

	if mat == null or not (mat is ShaderMaterial):
		mat = ShaderMaterial.new()
		mat.shader = preload("uid://bj6xhasqh07b7")
		mesh_ins.set_surface_override_material(0, mat)

	if not mat.resource_local_to_scene:
		mat = mat.duplicate()
		mat.resource_local_to_scene = true
		mesh_ins.set_surface_override_material(0, mat)

	mat.set_shader_parameter("albedo_tex", plant_res.textures[stage])
	mat.set_shader_parameter("uv_rect", p["uv_rect"])
	mat.set_shader_parameter("scale_factor", p["scale_factor"])
	mat.set_shader_parameter("vertical_offset", p["vertical_offset"])

func _reset_hydration_on_day_changed():
	hydrated = false
	if current_stage != Stage.Harvestable:
		hydration_component.collision_on()

func _on_hydrate():
	hydrated = true
	hydration_component.collision_off()
