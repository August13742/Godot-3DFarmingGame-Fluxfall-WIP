extends Interactable
class_name Pickuppable


@export var item_id: StringName

var homing_target: Node3D
var homing_speed: float = 10.0

func _ready() -> void:
	set_physics_process(false)
#func start_interaction() -> void:
	#EventSystem.emit_INT_begin_interaction()


func start_interaction(_source:Node3D = null) -> void:
	EventSystem.emit_INV_try_pick_up_item(item_id,func():pass)
	fly_to_source(_source)
	#EventSystem.emit_INT_begin_interaction()



func fly_to_source(_source: Node3D) -> void:
	homing_target = _source
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if homing_target:
		owner.global_position = owner.global_position.move_toward(homing_target.global_position, homing_speed * delta)
		if global_position.distance_to(homing_target.global_position) < 0.05:
			destroy_self()

func destroy_self() -> void:
	owner.queue_free()
