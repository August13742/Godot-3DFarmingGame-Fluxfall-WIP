extends Control

@onready var bottom: Control = $Bottom
@onready var left: Control = $Left
@onready var top: Control = $Top
@onready var right: Control = $Right

@export var highlight_colour:Color

@onready var radial_menu: Node # Assuming your RadialMenu node is named 'RadialMenu'

var current_tween: Tween = null
var is_selected:bool = false
var control_index_mapped:Array[Control] = []
func _ready():
	# Connect the signal from the radial menu to a method in this script
	_late_init.call_deferred()
		# It's good practice to ensure the radial_menu node exists and has the signal

func _late_init()->void:
	radial_menu = owner.get_node("RadialMenu")

	if radial_menu:
		radial_menu.option_selected.connect(_on_radial_menu_option_selected)
	control_index_mapped = [bottom,left,top,right]



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select_toolbar"):
		is_selected = true
		scale_to(Vector2.ONE * 1.5, 0.5)
		radial_menu.visible = true
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	elif event.is_action_released("select_toolbar"):
		is_selected = false
		scale_to(Vector2.ONE, 0.1)
		#_on_radial_menu_option_selected(-1, "None") # Deselect when button released
		radial_menu.visible = false
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

		if selected_index!=-1:
			control_index_mapped[selected_index].panel.self_modulate = highlight_colour
			control_index_mapped[selected_index].scale = Vector2.ONE*1.2

			if previous_index != -1:
				control_index_mapped[previous_index].panel.self_modulate = Color.WHITE
				control_index_mapped[previous_index].scale = Vector2.ONE
			previous_index = selected_index
		else:
			for control in control_index_mapped:
				control.panel.self_modulate = Color.WHITE
				control.scale = Vector2.ONE
		get_tree().paused = false
	if event is InputEventMouseMotion and is_selected:

		var local_mouse_pos = radial_menu.get_local_mouse_position() # Get mouse position relative to the radial menu
		# Pass the local mouse position to the radial menu for selection logic
		if radial_menu:
			radial_menu.update_selection(local_mouse_pos)
		get_tree().paused = true

# This method will be called when the radial menu emits the 'option_selected' signal
var selected_index:int = -1
var previous_index:int = -1
func _on_radial_menu_option_selected(index: int, _name: String) -> void:
		selected_index = index




func scale_to(target_scale: Vector2, duration: float) -> void:
	if current_tween:
		current_tween.kill() # stop existing tween safely
	current_tween = create_tween().set_parallel(true)
	current_tween.tween_property(self, "scale", target_scale, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
