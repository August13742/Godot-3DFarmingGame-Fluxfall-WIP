extends Node

class_name Crop

## How many stages the visual of the crop changes
@export var actual_stages:int = 4
## fake stages for shrinking growth time variance
@export var stages_for_calculation:int = 40
## chance for growth per growth_tick
@export var growth_chance:float = 0.75

@onready var crop_pivot:Node3D = $%CropPivot
@onready var crop:Node3D =crop_pivot.get_child(0)
@onready var collision:CollisionShape3D = $CropPivot/Pickuppable/CollisionShape3D

var stages_per_visual_change:int

enum Stages{
	Seed,
	Stage1,
	Stage2,
	Stage3,
	Harvestable
}

@export var models:Array[Mesh]


var current_stage:Stages = Stages.Seed
var current_calculation_stage:int = 0
var can_harvest:bool = false
func _ready() -> void:
	EventSystem.CROP_growth_tick_emitted.connect(_on_growth_tick_emitted)
	@warning_ignore("integer_division")
	stages_per_visual_change = stages_for_calculation / actual_stages

func grow()->void:
	current_calculation_stage += 1
	var target_stage:int = floori(current_calculation_stage/(stages_per_visual_change as float))
	if target_stage != (current_stage as int):
		current_stage = target_stage as Stages
		if current_stage == Stages.Harvestable:
			collision.disabled = false
		crop_pivot.scale = Vector3.ONE * target_stage

func _on_growth_tick_emitted()->void:
	if current_stage == Stages.Harvestable: return

	if randf()<growth_chance:
		grow()
