extends Node3D
class_name ThirdPersonCamera

var mouse_sensitivity:float = 0.05
@onready var camera:Camera3D = $Camera3D
var rotation_speed = 3


func _ready() -> void:
	if "mouse_sensitivity" in owner:
		mouse_sensitivity = owner.mouse_sensitivity


func _input(event:InputEvent):
	if event is InputEventMouseMotion:
		look_around(event.relative)


func look_around(relative:Vector2,_delta:float=1):
	#camera_pivot.rotate_y(-relative.x * mouse_sensitivity)
#
	#camera_pivot.rotate_x(-relative.y * mouse_sensitivity)
	#camera_pivot.rotation_degrees.x = clampf(camera_pivot.rotation_degrees.x,-60,60)
	'''
	above is a classic pitfall using rotate() instead of direct angle manipulation.
	rotating x or y would cause the following x/y to not be the same as before,
	hence introducing unwanted z-axis rotation, as well as unintented behaviours
	'''
	rotation.y += -relative.x * mouse_sensitivity
	rotation.x += -relative.y * mouse_sensitivity
	rotation_degrees.x = clampf(rotation_degrees.x,-60,80)


func _process(_delta: float) -> void:
	if owner.state_machine.current_state == owner.state_machine.states["Walk"] \
	|| owner.state_machine.current_state == owner.state_machine.states["Sprint"]:
		print("working")
		rotate_root_towards_cursor(_delta)

func rotate_root_towards_cursor(_delta:float):
	var mouse_position:Vector2 = get_viewport().get_mouse_position()
	var ray_origin:Vector3 = camera.project_ray_origin(mouse_position) # get mouse position on screen in 3D space
	var ray_direction:Vector3 = camera.project_ray_normal(mouse_position)

	# Define ground plane (y = transform.origin.y)
	var ground_y:float = owner.global_position.y
	if ray_direction.y == 0: return #avoid when ray is parallel to ground

	# intersect ray with plane

	# how far along the ray need to go from its origin before it hits the ground plane
	var t = (ground_y - ray_origin.y) / ray_direction.y

	var intersection:Vector3 = ray_origin + ray_direction * t

	# flattened direction from player to intersection
	var to_target:Vector3 = intersection - owner.global_position
	to_target.y = 0
	if to_target.length_squared()<0.001: return

	#rotate towards found direction
	var target_rotation:float = atan2(to_target.x, to_target.z)
	var current_rotation:Vector3 = owner.rotation
	#owner.rotation.y = lerp_angle(current_rotation.y, -target_rotation, rotation_speed * _delta)
	owner.rotation.y = target_rotation
