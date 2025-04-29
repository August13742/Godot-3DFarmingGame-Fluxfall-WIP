extends CharacterBody3D


@export var normal_speed:float = 10
@export var sprint_speed:float = 15

## lower means less responsive when in air
@export var air_acceleration:float = 5
@export var ground_acceleration:float = 60

@export var jump_force:float = 5
@export var gravity:float = 9.8
@export var terminal_fall_velocity = -30.0
@export var mouse_sensitivity:float = 0.005

@onready var visuals:Node3D = $VisualControl
@onready var head:Node3D = $VisualControl/sophia
@onready var camera:Camera3D = $CameraPivot/Camera3D
var is_sprinting:bool = false
var speed:float

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	

var movespeed:float = normal_speed
func _physics_process(delta):
	movespeed = sprint_speed if Input.is_action_pressed("sprint") else normal_speed

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var target_velocity = transform.basis * Vector3(input_dir.x, 0, input_dir.y) * movespeed
	
	var accel = ground_acceleration if is_on_floor() else air_acceleration

	## Horizontal velocity smoothing
	velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)

	# Vertical control
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_force
		else:
			velocity.y = -0.01  # stick to ground
	else:
		# Smooth gravity toward terminal fall
		velocity.y = move_toward(velocity.y, terminal_fall_velocity, gravity * delta)
	
	move_and_slide()

func _input(event:InputEvent):
	if event is InputEventMouseMotion:
		look_around(event.relative)
		
		
func look_around(relative:Vector2):
	rotate_y(-relative.x * mouse_sensitivity)
	#rotation_degrees.y = clampf(rotation_degrees.y,-85,85)
	head.rotate_x(relative.y * mouse_sensitivity)
	head.rotation_degrees.x = clampf(head.rotation_degrees.x,-80,80)
	
	
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		match(Input.mouse_mode):
			Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
