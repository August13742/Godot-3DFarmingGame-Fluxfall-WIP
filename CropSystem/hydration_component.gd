extends Interactable
class_name HydrationComponent

@onready var collision:CollisionShape3D = $%HydrationCollision
signal hydrate
func start_interaction(_source:Node3D = null) -> void:
	hydrate.emit()


func collision_on():
	collision.disabled = false

func collision_off():
	collision.disabled = true
