extends CharacterBody3D

@export var normal_speed := 10.0
@export var sprint_speed := 15.0
@export var air_acceleration := 5.0
@export var ground_acceleration := 60.0
@export var jump_force := 5.0
@export var gravity := 9.8
@export var terminal_fall_velocity := -30.0
@export var mouse_sensitivity := 0.005

@onready var visuals := $VisualControl
@onready var skin := $VisualControl/sophia
#@onready var camera := $CameraPivot/Camera3D
#@onready var camera_pivot := $CameraPivot
@onready var state_machine := $StateMachine
@export var state_machine_debug:bool = false

@onready var animation_player:AnimationPlayer = $VisualControl/sophia/AnimationPlayer

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	state_machine.update(delta)

func _input(event):
	state_machine.handle_input(event)

#func look_around(relative: Vector2):
	#camera_pivot.rotation.y += -relative.x * mouse_sensitivity
	#camera_pivot.rotation.x += -relative.y * mouse_sensitivity
	#camera_pivot.rotation_degrees.x = clampf(camera_pivot.rotation_degrees.x, -60, 80)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		match(Input.mouse_mode):
			Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
