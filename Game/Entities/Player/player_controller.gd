extends CharacterBody3D


@export var angular_velocity:= 8
@export var normal_speed := 10.0
@export var sprint_speed := 15.0
@export var air_acceleration := 5.0
@export var ground_acceleration := 60.0
@export var jump_force := 5.0
@export var gravity := 9.8
@export var terminal_fall_velocity := -30.0

@export_range(0.01,1,0.01) var mouse_sensitivity_percent = 0.8

@onready var visuals := $VisualControl
@onready var skin := $VisualControl/Mannequin

@onready var state_machine := $StateMachine
@export var state_machine_debug:bool = false

@onready var animation_player:AnimationPlayer = $VisualControl/Mannequin/AnimationPlayer

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	state_machine.update(delta)

func _input(event):
	state_machine.handle_input(event)



func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		match(Input.mouse_mode):
			Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
