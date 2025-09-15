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

class_name ThirdPersonObserverCamera extends Node3D


@export var target: Node3D

@export_group("Mouse Settings")
@export var mouse_sensitivity: float = 0.25
@export var min_pitch_degrees: float = -60.0
@export var max_pitch_degrees: float = 75.0
@export var mouse_smoothing_speed: float = 20.0

@export_group("Follow Settings")
@export var pivot_y_offset: float = 1.5
@export var follow_smoothing_speed: float = 15.0


@export_group("Zoom Settings")
@export var default_distance: float = 4.0
@export var min_distance: float = 1.0
@export var max_distance: float = 10.0
@export var zoom_speed: float = 0.5

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var _raw_mouse_delta := Vector2.ZERO
var _smoothed_mouse_delta := Vector2.ZERO
var _desired_distance: float
var _active: bool = false

func _ready() -> void:
	_desired_distance = clampf(default_distance, min_distance, max_distance)
	spring_arm.spring_length = _desired_distance

	if is_instance_valid(target):
		global_position = target.global_position


func enable(v: bool) -> void:
	_active = v
	set_process(v)
	set_physics_process(v)



# Public API

func follow(node: Node3D) -> void:
	target = node

func focus_on(t: Variant, snap: bool = true) -> void:
	# Accept Node3D or Vector3
	var pos: Vector3
	if t is Node3D:
		target = t
		pos = t.global_position
	else:
		target = null
		pos = Vector3(t)

	# Move pivot near target and look at it
	var pivot := pos + Vector3(0, pivot_y_offset, 0)
	if snap:
		global_position = pivot
	else:
		global_position = global_position.lerp(pivot, 0.6)

	# Yaw so forward faces the point of interest if we have a previous offset
	var to_cam := (global_position - pos)
	if to_cam.length() < 0.01:
		to_cam = -transform.basis.z
	var yaw := atan2(to_cam.x, to_cam.z)
	rotation.y = yaw
	rotation.x = clampf(rotation.x, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))

func set_distance(d: float, lerp_time: float = 0.0) -> void:
	_desired_distance = clampf(d, min_distance, max_distance)
	if lerp_time <= 0.0:
		spring_arm.spring_length = _desired_distance

func set_angles(yaw_deg: float, pitch_deg: float) -> void:
	rotation.y = deg_to_rad(yaw_deg)
	rotation.x = clampf(deg_to_rad(pitch_deg), deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))

# Input
func _blocked() -> bool:
	return not _active or GameManager.is_ui_blocking()
	
func _input(event: InputEvent) -> void:
	if _blocked():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_raw_mouse_delta += event.relative
	if event.is_action_pressed("camera_zoom_in"):
		_desired_distance = clampf(_desired_distance - zoom_speed, min_distance, max_distance)
	if event.is_action_pressed("camera_zoom_out"):
		_desired_distance = clampf(_desired_distance + zoom_speed, min_distance, max_distance)

func _physics_process(delta: float) -> void:
	# Always follow target position, even if UI blocks rotation
	if is_instance_valid(target):
		var target_position = target.global_position + Vector3.UP * pivot_y_offset
		global_position = global_position.lerp(target_position, 1.0 - exp(-delta * follow_smoothing_speed))

	if _blocked():
		_raw_mouse_delta = Vector2.ZERO
		return

	_smoothed_mouse_delta = _smoothed_mouse_delta.lerp(_raw_mouse_delta, 1.0 - exp(-delta * mouse_smoothing_speed))
	_handle_rotation(_smoothed_mouse_delta)
	_raw_mouse_delta = Vector2.ZERO

	# smooth distance
	if absf(spring_arm.spring_length - _desired_distance) > 0.001:
		spring_arm.spring_length = lerpf(spring_arm.spring_length, _desired_distance, 1.0 - exp(-delta * 10.0))

		
func _handle_rotation(relative_delta: Vector2) -> void:
	rotate_y(deg_to_rad(-relative_delta.x * mouse_sensitivity))
	rotate_object_local(Vector3.RIGHT, deg_to_rad(-relative_delta.y * mouse_sensitivity))
	rotation.x = clampf(rotation.x, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))
