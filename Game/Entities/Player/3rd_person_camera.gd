extends Node3D
class_name ThirdPersonCamera

var mouse_sensitivity:float = 0.35
@onready var camera:Camera3D = $%Camera3D
@onready var target_entity:Node3D = get_tree().get_first_node_in_group("player")


@export_range(0.01,1,0.01) var mouse_sensitivity_percent = 1 :
	set(num):
		mouse_sensitivity_percent = num
		mouse_sensitivity *= num
		mouse_sensitivity = clampf(mouse_sensitivity,0.0035,0.35)

@export var angular_velocity = 4

## how to the right or left is the camera
@export var camera_x_offset:float = 10
## how far behind is the camera
@export var camera_z_offset:float = 2
## how high the camera floats above pivot
@export var camera_y_offset:float = 0.5
## how high pivot is above character, set this so that it's at the eye
@export var y_tracking_offset:float = 1.8
@export var max_ray_length:int = 10
@export var camera_acceleration_smoothing := 25
@export var camera_raycast_debug:bool = false


func _ready() -> void:
	$SpringArm3D.position += Vector3(camera_x_offset,camera_y_offset,camera_z_offset)
	
	if "angular_velocity" in target_entity:
		angular_velocity = target_entity.angular_velocity
	if "mouse_sensitivity_percent" in target_entity:
		mouse_sensitivity_percent = target_entity.mouse_sensitivity_percent


var smoothed_mouse_delta := Vector2.ZERO
var raw_mouse_delta := Vector2.ZERO

func _input(event:InputEvent):
	if event is InputEventMouseMotion:
		raw_mouse_delta += event.relative


func _process(delta: float) -> void:
	smoothed_mouse_delta = smoothed_mouse_delta.lerp(raw_mouse_delta, 1 - exp(-delta * 20))
	look_around(smoothed_mouse_delta, delta)
	raw_mouse_delta = Vector2.ZERO


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
	rotation.y += -relative.x * mouse_sensitivity * _delta
	rotation.x += -relative.y * mouse_sensitivity * _delta
	rotation_degrees.x = clampf(rotation_degrees.x,-70,75)


var direction_to_look_at:Vector3 = Vector3.ZERO
func _physics_process(_delta: float) -> void:
	position = target_entity.position
	#position = position.lerp(target_entity.position,1 - exp(-_delta * camera_acceleration_smoothing))
	position.y = target_entity.position.y + y_tracking_offset

	direction_to_look_at = get_lookat_direction()
	rotate_head_ray(direction_to_look_at,_delta)
	
	if target_entity.state_machine.current_state == target_entity.state_machine.states["Walk"] \
	|| target_entity.state_machine.current_state == target_entity.state_machine.states["Sprint"]:
		var flat_input_direction = Vector2(
			Input.get_action_strength("move_forward")-Input.get_action_strength("move_backward"),
			Input.get_action_strength("move_right")-Input.get_action_strength("move_left")).normalized()
			
		var current_yaw = target_entity.visuals.rotation.y
		var target_yaw = atan2(flat_input_direction.y, -flat_input_direction.x)
		target_entity.visuals.rotation.y = lerp_angle(current_yaw, target_yaw, angular_velocity * _delta)

		rotate_root_towards_cursor(direction_to_look_at,_delta)


func get_lookat_direction() -> Vector3:
	var mouse_position:Vector2 = get_viewport().get_mouse_position()

	var ray_origin:Vector3 = camera.project_ray_origin(mouse_position)
	var ray_direction:Vector3 = camera.project_ray_normal(mouse_position)
	if ray_direction.y ==  0:
		return Vector3.ZERO 	# too flat, skip rotation

	var ground_y:float = target_entity.global_position.y



	var t:float = (ground_y - ray_origin.y) / ray_direction.y

	t = clampf(t,camera_z_offset + 4,max_ray_length)
	var intersection := ray_origin + ray_direction * t


	# Flattened direction
	var to_target:Vector3 = intersection - target_entity.global_position
	
	if Vector3(to_target.x, 0, to_target.z).length_squared() < 0.005:

		return Vector3.ZERO
	# --- DEBUG DRAWING ---
	if camera_raycast_debug:
		DebugDraw3D.draw_line(ray_origin, ray_origin + ray_direction * 5.0, Color.RED)
		DebugDraw3D.draw_line(ray_origin, intersection, Color.YELLOW)
		DebugDraw3D.draw_sphere(intersection, 0.1, Color.GREEN)
		DebugDraw3D.draw_line(target_entity.global_position, intersection, Color.BLUE)
		
	return to_target
		
func rotate_head_ray(to_target: Vector3, _delta: float):
	var ray = target_entity.interaction_ray_cast
	var tgt = target_entity.global_position + to_target
	var direction = tgt - ray.global_position

	if abs(direction.normalized().dot(Vector3.UP)) > 0.999:
		# Too vertical, skip to prevent twist
		return

	ray.look_at(tgt, Vector3.UP)

func rotate_root_towards_cursor(to_target:Vector3,_delta:float):
	if to_target == Vector3.ZERO:
		return 

	# --- ROTATION LOGIC ---

	var target_rotation:float = atan2(-to_target.x, -to_target.z) # flip to - if model faces -z
	var current_rotation:Vector3 = target_entity.rotation
	
	target_entity.rotation.y = lerp_angle(current_rotation.y, target_rotation, angular_velocity * _delta)
	
