extends Node3D
class_name HeadRayManager

@onready var force_vector_ray:ShapeCast3D = $ForceVector
@onready var interaction_ray:RayCast3D = $InteractionRayCast
var force_enabled:bool = true


func _physics_process(_delta: float) -> void:
	if force_vector_ray.enabled:
		force_vector_ray.check_interaction()
	else:
		interaction_ray.check_interaction()
