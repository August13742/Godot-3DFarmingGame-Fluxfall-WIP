class_name HeadRayManager extends Node3D

@onready var force_vector_ray:ShapeCast3D = $ForceVector
var force_enabled:bool = true
var item_collection_pivot:Node3D

func _physics_process(_delta: float) -> void:
	force_vector_ray.check_interaction()
