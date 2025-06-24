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
@export var camera_x_offset:float = 0
## how far behind is the camera
@export var camera_z_offset:float = 0
## how high the camera floats above pivot
@export var camera_y_offset:float = 0
## how high pivot is above character, set this so that it's at the eye
@export var y_tracking_offset:float = 1.8
@export var max_ray_length:int = 5
@export var camera_acceleration_smoothing := 25
@export var debug_raycast:bool = false


# Variables to store raycast debug data
var ray_origin_debug: Vector3 = Vector3.ZERO
var ray_end_debug: Vector3 = Vector3.ZERO
var intersection_point_debug: Vector3 = Vector3.ZERO
var look_direction_debug: Vector3 = Vector3.ZERO


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

func look_around(relative:Vector2,_delta:float=1):
	rotation.y += -relative.x * mouse_sensitivity * _delta
	rotation.x += -relative.y * mouse_sensitivity * _delta
	rotation_degrees.x = clampf(rotation_degrees.x,-70,75)

var direction_to_look_at:Vector3 = Vector3.ZERO
func _physics_process(_delta: float) -> void:

	smoothed_mouse_delta = smoothed_mouse_delta.lerp(raw_mouse_delta, 1 - exp(-_delta * 20))
	look_around(smoothed_mouse_delta, _delta)
	raw_mouse_delta = Vector2.ZERO

	position = target_entity.position
	position.y = target_entity.position.y + y_tracking_offset

	direction_to_look_at = get_lookat_direction()
	rotate_head_ray(direction_to_look_at,_delta)

	if target_entity.state_machine.current_state == target_entity.state_machine.states[StateMachine.Walk] \
	|| target_entity.state_machine.current_state == target_entity.state_machine.states[StateMachine.Sprint]:
		var current_input:Vector2 = target_entity.current_input_direction
		var current_visual_yaw:float = target_entity.skin.rotation.y
		var target_visual_yaw:float = atan2(-current_input.x,-current_input.y)
		target_entity.skin.rotation.y = lerp_angle(current_visual_yaw, target_visual_yaw, angular_velocity * _delta)
		rotate_root_towards_cursor(direction_to_look_at,_delta)

	# --- Debug Drawing
	if debug_raycast:
		pass


func rotate_root_towards_cursor(to_target:Vector3,_delta:float):
	if to_target == Vector3.ZERO:
		return

	var target_rotation:float = atan2(-to_target.x, -to_target.z) ## = atan2(-z,x) + pi/2, since model default 90 (facing -z, 0 rad is +X)
	var current_rotation:Vector3 = target_entity.rotation

	target_entity.rotation.y = lerp_angle(current_rotation.y, target_rotation, angular_velocity * _delta)

func get_lookat_direction() -> Vector3:
	var screen_center = get_viewport().get_visible_rect().size / 2
	var ray_origin:Vector3 = camera.project_ray_origin(screen_center)
	var ray_direction:Vector3 = camera.project_ray_normal(screen_center)

	# Store for debugging
	ray_origin_debug = ray_origin
	ray_end_debug = ray_origin + ray_direction * max_ray_length

	if ray_direction.y == 0:
		return Vector3.ZERO

	var intersection := ray_origin + ray_direction * max_ray_length

	# Store for debugging
	intersection_point_debug = intersection

	var to_target:Vector3 = intersection - target_entity.global_position

	if Vector3(to_target.x, 0, to_target.z).length_squared() < 0.005:
		look_direction_debug = Vector3.ZERO # Ensure debug variable is also reset
		return Vector3.ZERO

	look_direction_debug = to_target # Store for debugging

	return to_target

func rotate_head_ray(to_target: Vector3, _delta: float):
	var ray = target_entity.head
	var target = target_entity.global_position + to_target

	var direction = target - ray.global_position

	if abs(direction.normalized().dot(Vector3.UP)) > 0.999:
		return

	ray.look_at(target, Vector3.UP)
