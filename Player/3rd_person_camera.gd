extends Node3D
class_name ThirdPersonARPGCamera

## Mouse and Camera Orbit
@export_range(0.01, 1.0, 0.01) var mouse_sensitivity_percent: float = 1.0:
	set(value):
		mouse_sensitivity_percent = value
		mouse_sensitivity = BASE_MOUSE_SENSITIVITY * mouse_sensitivity_percent

const BASE_MOUSE_SENSITIVITY: float = 0.35
var mouse_sensitivity: float = 0.35

@export var angular_velocity: float = 4.0
@export var camera_acceleration_smoothing: float = 25.0

## Offsets and Positioning
@export var camera_x_offset: float = 0.0 # How far right/left the camera is from the pivot.
@export var camera_z_offset: float = 0.0 # How far behind the camera is from the pivot.
@export var camera_y_offset: float = 0.0 # How high the camera floats above the pivot.
@export var y_tracking_offset: float = 1.8 # How high the pivot is above the character (e.g., at eye level).

## Interaction and Debugging
@export var debug_shapecast: bool = false

# --- Scene Node References ---
@onready var camera: Camera3D = %Camera3D
@onready var interaction_shapecast: ShapeCast3D = %InteractionShapeCast 
@onready var target_entity: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
@onready var target_entity_head:Node3D = target_entity.head
@onready var target_entity_skin:Node3D = target_entity.skin
# --- Internal State ---
var _raw_mouse_delta: Vector2 = Vector2.ZERO
var _smoothed_mouse_delta: Vector2 = Vector2.ZERO


func _ready() -> void:
	$SpringArm3D.position = Vector3(camera_x_offset, camera_y_offset, camera_z_offset)
	
	# Attempt to pull configuration from the target entity.
	if "angular_velocity" in target_entity:
		angular_velocity = target_entity.get("angular_velocity")
	if "mouse_sensitivity_percent" in target_entity:
		mouse_sensitivity_percent = target_entity.get("mouse_sensitivity_percent")

func get_aim_target() -> Dictionary:
	interaction_shapecast.force_shapecast_update()
	if interaction_shapecast.is_colliding():
		return {
			"collider": interaction_shapecast.get_collider(0),
			"point": interaction_shapecast.get_collision_point(0)
		}
	return {"collider": null, "point": interaction_shapecast.to_global(interaction_shapecast.target_position)}

	
func _input(event: InputEvent) -> void:
	if GameManager.is_ui_blocking():
		return
	if event is InputEventMouseMotion:
		_raw_mouse_delta += event.relative


func _physics_process(delta: float) -> void:
	if not camera.current or not is_instance_valid(target_entity):
		return

	global_position = target_entity.global_position + Vector3.UP * y_tracking_offset
	
	if GameManager.is_ui_blocking():
		# Prevent camera jump when UI closes by clearing pending input
		_raw_mouse_delta = Vector2.ZERO
		_smoothed_mouse_delta = Vector2.ZERO
		return

	var smoothing_factor: float = 1.0 - exp(-delta * camera_acceleration_smoothing)
	_smoothed_mouse_delta = _smoothed_mouse_delta.lerp(_raw_mouse_delta, smoothing_factor)
	_apply_camera_orbit(_smoothed_mouse_delta, delta)
	_raw_mouse_delta = Vector2.ZERO

	# Get the 3D aim data for head tracking and potential interactions.
	var aim_data: Dictionary = get_aim_target()
	var look_at_point: Vector3 = aim_data.point
	
	# The head should always track the 3D cursor's world position.
	_rotate_head(look_at_point)

	# --- Player Rotation Logic ---
	# player root and skin only rotate if player is actively moving
	var horizontal_velocity: Vector2 = Vector2(target_entity.velocity.x, target_entity.velocity.z)
	if horizontal_velocity.length_squared() > 0.01:
		# Create a stable, 2D planar direction from the camera's transform.
		var look_direction_planar: Vector3 = -camera.global_transform.basis.z
		look_direction_planar.y = 0
		
		# Only rotate if the vector is valid
		if look_direction_planar.length_squared() > 0.001:
			look_direction_planar = look_direction_planar.normalized()
			_rotate_player_root(look_direction_planar, delta)
		
		_rotate_player_skin(delta)
	

func _apply_camera_orbit(relative: Vector2, delta: float) -> void:
	# Applies mouse movement to the camera pivot's rotation
	rotation.y += -relative.x * mouse_sensitivity * delta
	rotation.x += -relative.y * mouse_sensitivity * delta
	rotation_degrees.x = clampf(rotation_degrees.x, -70.0, 75.0)



func _rotate_head(target_point: Vector3) -> void:
	# Rotates the player's head node to look at a specific world-space point.
	if not is_instance_valid(target_entity_head):
		return
	
	# Avoid gimbal lock when looking straight up or down.
	var direction_to_target: Vector3 = (target_point - target_entity_head.global_position).normalized()
	if abs(direction_to_target.dot(Vector3.UP)) > 0.999:
		return

	target_entity_head.look_at(target_point, Vector3.UP)


func _rotate_player_root(look_direction: Vector3, delta: float) -> void:
	if look_direction == Vector3.ZERO:
		return

	var target_rotation_y: float = atan2(-look_direction.x, -look_direction.z)
	target_entity.rotation.y = lerp_angle(target_entity.rotation.y, target_rotation_y, angular_velocity * delta)


func _rotate_player_skin(delta: float) -> void:
	# Rotates the visual mesh (skin) to face the direction of player input.
	if not is_instance_valid(target_entity_skin):
		return
		
	var current_input: Vector2 = target_entity.get(&"current_input_direction")
	if current_input.length_squared() < 0.01:
		return

	var target_visual_yaw: float = atan2(-current_input.x, -current_input.y)
	target_entity_skin.rotation.y = lerp_angle(target_entity_skin.rotation.y, target_visual_yaw, angular_velocity * delta)
