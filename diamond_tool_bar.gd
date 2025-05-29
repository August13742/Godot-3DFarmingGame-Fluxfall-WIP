extends Control

@onready var top_panel:Control = $Top
@onready var left_panel:Control = $Left
@onready var right_panel:Control = $Right
@onready var bottom_panel:Control = $Bottom

var current_tween: Tween = null
var is_selected:bool = false
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select_toolbar"):
		is_selected = true
		scale_to(Vector2.ONE * 1.5, 0.5)
	elif event.is_action_released("select_toolbar"):
		is_selected = false
		scale_to(Vector2.ONE, 0.1)

	if event is InputEventMouseMotion and is_selected:
		var local_mouse_pos = get_local_mouse_position()
		update_selected_tab(local_mouse_pos)

func update_selected_tab(pos: Vector2) -> void:
	var angle = pos.angle()  # Radians, from X+ CCW

	# Normalize to 0–2π for easier comparison
	if angle < 0.0:
		angle += TAU

	# Divide circle into quadrants
	if angle >= PI * 7 / 4 or angle < PI / 4:
		select_tab("right")
	elif angle >= PI / 4 and angle < PI * 3 / 4:
		select_tab("top")
	elif angle >= PI * 3 / 4 and angle < PI * 5 / 4:
		select_tab("left")
	else:
		select_tab("bottom")

func select_tab(name: String) -> void:

	print("Selected tab:", name)

func scale_to(target_scale: Vector2, duration: float) -> void:
	if current_tween:
		current_tween.kill()  # stop existing tween safely
	current_tween = create_tween().set_parallel(true)
	current_tween.tween_property(self, "scale", target_scale, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
