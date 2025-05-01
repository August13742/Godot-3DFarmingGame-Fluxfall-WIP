extends Node3D
class_name ThirdPersonCamera

var mouse_sensitivity:float = 0.05
@onready var camera:Camera3D = $Camera3D
@export var angular_acceleration = 4
@onready var target_entity:Node3D = get_tree().get_first_node_in_group("player")

@export var camera_z_offset:float = 2
## how high the camera floats above pivot
@export var camera_y_offset:float = 0.5
## how high pivot is above character, set this so that it's at the eye
@export var y_tracking_offset:float = 1.3
@export var max_ray_t:int = 50

@export var camera_raycast_debug:bool = false
func _ready() -> void:
	camera.position.z += camera_z_offset
	camera.position.y += camera_y_offset
	if "mouse_sensitivity" in target_entity:
		mouse_sensitivity = target_entity.mouse_sensitivity
	if "angular_acceleration" in target_entity:
		angular_acceleration = target_entity.angular_acceleration



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
	position = target_entity.position
	position.y += y_tracking_offset


	if target_entity.state_machine.current_state == target_entity.state_machine.states["Walk"] \
	|| target_entity.state_machine.current_state == target_entity.state_machine.states["Sprint"]:
		rotate_root_towards_cursor(_delta)

func rotate_root_towards_cursor(_delta:float):
	var mouse_position:Vector2 = get_viewport().get_mouse_position()
	var ray_origin:Vector3 = camera.project_ray_origin(mouse_position)
	var ray_direction:Vector3 = camera.project_ray_normal(mouse_position)

	var ground_y:float = target_entity.global_position.y
	if ray_direction.y == 0: return

	var t = (ground_y - ray_origin.y) / ray_direction.y
	t = clamp(t, camera_z_offset+1, max_ray_t)
	var intersection:Vector3 = ray_origin + ray_direction * t

	# Flattened direction
	var to_target:Vector3 = intersection - target_entity.global_position
	to_target.y = 0
	if to_target.length_squared() < 0.001: return

	# --- ROTATION LOGIC ---
	var target_rotation:float = atan2(-to_target.x, -to_target.z) # flipped due to model orientation
	var current_rotation:Vector3 = target_entity.rotation
	target_entity.rotation.y = lerp_angle(current_rotation.y, target_rotation, angular_acceleration * _delta)

	# --- DEBUG DRAWING ---
	if camera_raycast_debug:
		DebugDraw3D.draw_line(ray_origin, ray_origin + ray_direction * 5.0, Color.RED)
		DebugDraw3D.draw_line(ray_origin, intersection, Color.YELLOW)
		DebugDraw3D.draw_sphere(intersection, 0.1, Color.GREEN)
		DebugDraw3D.draw_line(target_entity.global_position, intersection, Color.BLUE)
		DebugDraw3D.draw_text(intersection + Vector3.UP * 0.3, "Intersection", 10,Color.WHITE)
