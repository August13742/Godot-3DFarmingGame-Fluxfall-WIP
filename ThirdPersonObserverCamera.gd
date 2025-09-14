# ThirdPersonObserverCamera.gd
# A third-person camera script designed to follow and orbit a target node (e.g., an NPC)
# without affecting the target's movement or rotation.
#
# REQUIRED SCENE SETUP:
# Node3D (this script is attached here)
# ├── SpringArm3D
# │   └── Camera3D
#
# The script rotates the root Node3D to handle orbit, and lerps its position to follow the target.
# The SpringArm3D handles camera distance and collision, preventing it from clipping through objects.

extends Node3D
class_name ThirdPersonObserverCamera

## The node this camera will follow. Assign this in the Inspector.
@export var target: Node3D

# -- MOUSE CONTROL --
@export_group("Mouse Settings")
## The base sensitivity for mouse movement.
@export var mouse_sensitivity: float = 0.25
## Clamps the vertical rotation to prevent flipping over.
@export var min_pitch_degrees: float = -60.0
@export var max_pitch_degrees: float = 75.0
## Smoothing applied to mouse input to prevent jerky movement. Higher values mean faster response.
@export var mouse_smoothing_speed: float = 20.0

# -- FOLLOW BEHAVIOR --
@export_group("Follow Settings")
## The vertical offset from the target's origin for the camera to pivot around.
@export var pivot_y_offset: float = 1.5
## How quickly the camera catches up to the target's position. Higher values are faster.
@export var follow_smoothing_speed: float = 15.0

# -- ZOOM / DISTANCE --
@export_group("Zoom Settings")
@export var default_distance: float = 4.0
@export var min_distance: float = 1.0
@export var max_distance: float = 10.0
@export var zoom_speed: float = 0.5

# -- INTERNAL VARIABLES --
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera:Camera3D = $SpringArm3D/Camera3D
var _raw_mouse_delta := Vector2.ZERO
var _smoothed_mouse_delta := Vector2.ZERO


func _ready() -> void:
	if not is_instance_valid(target):
		push_error("Camera target is not set or is invalid. Disabling process.")
		set_process(false)
		return
	
	spring_arm.spring_length = default_distance
	
	# Lock the mouse cursor to the game window.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	global_position = target.global_position


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_raw_mouse_delta += event.relative

	# Handle zooming with the mouse wheel.
	if event.is_action_pressed("camera_zoom_in"):
		spring_arm.spring_length = clampf(spring_arm.spring_length - zoom_speed, min_distance, max_distance)
	if event.is_action_pressed("camera_zoom_out"):
		spring_arm.spring_length = clampf(spring_arm.spring_length + zoom_speed, min_distance, max_distance)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		push_warning("Camera target has become invalid.")
		set_physics_process(false)
		return

	var target_position = target.global_position + Vector3.UP * pivot_y_offset
	global_position = global_position.lerp(target_position, 1.0 - exp(-delta * follow_smoothing_speed))

	_smoothed_mouse_delta = _smoothed_mouse_delta.lerp(_raw_mouse_delta, 1.0 - exp(-delta * mouse_smoothing_speed))
	_handle_rotation(_smoothed_mouse_delta)
	
	_raw_mouse_delta = Vector2.ZERO


func _handle_rotation(relative_delta: Vector2) -> void:
	# Horizontal rotation (Yaw) around the Y-axis.
	rotate_y(deg_to_rad(-relative_delta.x * mouse_sensitivity))
	
	# Vertical rotation (Pitch) around the X-axis.
	rotate_object_local(Vector3.RIGHT, deg_to_rad(-relative_delta.y * mouse_sensitivity))
	
	# Clamp the vertical rotation to prevent the camera from going upside down.
	rotation.x = clampf(rotation.x, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
