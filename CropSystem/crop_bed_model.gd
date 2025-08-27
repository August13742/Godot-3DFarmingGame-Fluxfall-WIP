extends Node3D
class_name CropBedModel

@onready var dirt: MeshInstance3D = $Dirt
@export var dirt_colour_dry:Color = Color(0.4, 0.208, 0.161, 1.0)
@export var dirt_colour_wet:Color = Color(0.25, 0.13, 0.1, 1.0)
@onready var dirt_material:StandardMaterial3D = dirt.get_active_material(0)
