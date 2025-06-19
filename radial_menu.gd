extends Control

const ICON_SIZE := Vector2(32,32)

@export var background_colour:Color
@export var outer_radius:int = 256
@export var line_colour:Color
@export var inner_radius:int = 64
@export var inner_colour:Color
@export var line_width:int = 4
@export var outer_colour:Color
@export_range(3,12,1) var options:int = 4
@export var degree_offset:float = 0.0
@export var textures:Array[Texture2D] = []
@export var texture_scale:int = 3

# New properties for selection effect
@export var highlight_outer_radius_increase: float = 20.0
@export var highlight_inner_radius_decrease: float = 10.0
@export var highlight_line_colour: Color = Color.WHITE
@export var highlight_outer_slice_colour: Color = Color.YELLOW
@export var highlight_inner_slice_colour: Color = Color.BLUE
@export var highlight_line_width_increase: float = 2.0
@export var highlight_duration: float = 0.15 # Tween duration

signal option_selected(index: int, name: String)

var _current_hovered_option_index: int = -1
var _tweening_properties: Dictionary = {} # Store tweened properties for each slice

# Tween specific variables (per-slice properties) - These will be modified directly by setters
var _animated_outer_radius: Array[float] = []
var _animated_inner_radius: Array[float] = []
var _animated_line_colour: Array[Color] = []
var _animated_outer_slice_colour: Array[Color] = []
var _animated_inner_slice_colour: Array[Color] = []
var _animated_line_width: Array[float] = []
var _animated_line_width_start: Array[float] = [] # Line width for the start boundary of each slice
var _animated_line_width_end: Array[float] = []   # Line width for the end boundary of each slice

func _ready():
	# Initialise animated properties
	for i in range(options):
		_animated_outer_radius.append(float(outer_radius))
		_animated_inner_radius.append(float(inner_radius))
		_animated_line_colour.append(line_colour)
		_animated_outer_slice_colour.append(outer_colour)
		_animated_inner_slice_colour.append(inner_colour)
		_animated_line_width.append(float(line_width))
		_animated_line_width_start.append(float(line_width))
		_animated_line_width_end.append(float(line_width))
	queue_redraw()

func _draw():
	var offset := ICON_SIZE / 2.0
	draw_circle(Vector2.ZERO, outer_radius, background_colour)

	var segment_offset_rad: float = deg_to_rad(degree_offset)

	if options >= 3:
		for i in range(options):
			var current_outer_radius:float = _animated_outer_radius[i]
			var current_inner_radius:float = _animated_inner_radius[i]
			var current_line_colour:Color = _animated_line_colour[i]
			var current_outer_slice_colour:Color = _animated_outer_slice_colour[i]
			var current_inner_slice_colour:Color = _animated_inner_slice_colour[i]

			var start_rads: float = TAU * i / (options) + segment_offset_rad
			var end_rads: float = TAU * (i + 1) / (options) + segment_offset_rad

			# --- Draw the STARTING radial divider line for this slice ---
			var line_start_point := Vector2.from_angle(start_rads)
			draw_line(
				line_start_point * current_inner_radius,
				line_start_point * current_outer_radius,
				current_line_colour,
				_animated_line_width_start[i],
				false
			)

			# --- Draw the ENDING radial divider line for this slice ---
			var line_end_point := Vector2.from_angle(end_rads)
			draw_line(
				line_end_point * current_inner_radius,
				line_end_point * current_outer_radius,
				current_line_colour, # Use the animated line color for THIS slice
				_animated_line_width_end[i], # Use the end line width for THIS slice
				false
			)

			# --- Draw texture and arcs for the slice ---
			var mid_rads: float = (start_rads + end_rads) / 2.0 * -1
			var radius_mid = (current_inner_radius + current_outer_radius) / 2.0

			var draw_pos = radius_mid * Vector2.from_angle(mid_rads) - offset * texture_scale
			if i < textures.size() and textures[i] != null:
				draw_texture_rect(textures[i], Rect2(draw_pos, texture_scale * ICON_SIZE), false)

			# Draw the outer arc for the current slice.
			# You might choose which line width to use for the arcs, or average them,
			# or keep a separate _animated_arc_line_width. For simplicity, let's use start_line_width.
			draw_arc(Vector2.ZERO, current_outer_radius, start_rads, end_rads, 256, current_outer_slice_colour, _animated_line_width_start[i], false)
			# Draw the inner arc for the current slice.
			draw_arc(Vector2.ZERO, current_inner_radius, start_rads, end_rads, 256, current_inner_slice_colour, _animated_line_width_start[i], false)


# --- Setter functions for array elements (for Tweening) ---
func set_animated_outer_radius_at_index(value: float, index: int):
	if index >= 0 and index < _animated_outer_radius.size():
		_animated_outer_radius[index] = value
		queue_redraw()

func set_animated_inner_radius_at_index(value: float, index: int):
	if index >= 0 and index < _animated_inner_radius.size():
		_animated_inner_radius[index] = value
		queue_redraw()

func set_animated_line_colour_at_index(value: Color, index: int):
	if index >= 0 and index < _animated_line_colour.size():
		_animated_line_colour[index] = value
		queue_redraw()

func set_animated_outer_slice_colour_at_index(value: Color, index: int):
	if index >= 0 and index < _animated_outer_slice_colour.size():
		_animated_outer_slice_colour[index] = value
		queue_redraw()

func set_animated_inner_slice_colour_at_index(value: Color, index: int):
	if index >= 0 and index < _animated_inner_slice_colour.size():
		_animated_inner_slice_colour[index] = value
		queue_redraw()

func set_animated_line_width_at_index(value: float, index: int):
	if index >= 0 and index < _animated_line_width.size():
		_animated_line_width[index] = value
		queue_redraw()

func set_animated_line_width_start_at_index(value: float, index: int):
	if index >= 0 and index < _animated_line_width_start.size():
		_animated_line_width_start[index] = value
		queue_redraw()

func set_animated_line_width_end_at_index(value: float, index: int):
	if index >= 0 and index < _animated_line_width_end.size():
		_animated_line_width_end[index] = value
		queue_redraw()
# -----------------------------------------------------------

func get_selected_segment_index(local_mouse_pos: Vector2) -> int:
	# Check if mouse is outside the outer circle, or inside the inner circle (hole)
	var dist = local_mouse_pos.length()
	if dist < inner_radius or dist > outer_radius:
		return -1 # Mouse is not over any segment where selection is active

	var angle = local_mouse_pos.angle()

	if angle < 0.0:
		angle += TAU

	var adjusted_angle = angle - deg_to_rad(degree_offset)
	if adjusted_angle < 0.0:
		adjusted_angle += TAU

	var segment_width = TAU / float(options)
	var selected_index = floor(adjusted_angle / segment_width)

	return int(selected_index)

func update_selection(local_mouse_pos: Vector2):
	var new_selected_index = get_selected_segment_index(local_mouse_pos)

	if new_selected_index != _current_hovered_option_index:
		# First, reset the previously hovered option (if any)
		if _current_hovered_option_index != -1:
			reset_slice_visuals(_current_hovered_option_index)

		_current_hovered_option_index = new_selected_index

		if _current_hovered_option_index != -1:
			# Apply highlight to the newly selected option
			highlight_slice(_current_hovered_option_index)

			var option_names = ["Bottom", "Left", "Top", "Right"] # Assuming 4 options
			if _current_hovered_option_index < option_names.size():
				emit_signal("option_selected", _current_hovered_option_index, option_names[_current_hovered_option_index])
			else:
				emit_signal("option_selected", _current_hovered_option_index, "Option " + str(_current_hovered_option_index))
		else:
			emit_signal("option_selected", -1, "None") # Signal that no option is selected


# Helper function to get or create a Tween for a slice
func _get_slice_tween(index: int) -> Tween:
	var tween_key = "slice_tween_" + str(index)
	if _tweening_properties.has(tween_key) and _tweening_properties[tween_key] != null:
		_tweening_properties[tween_key].kill() # Stop existing tween

	var new_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_tweening_properties[tween_key] = new_tween
	return new_tween

func highlight_slice(index: int):
	if index < 0 or index >= options: return

	var tween = _get_slice_tween(index)

	# Pop out effect (these remain the same as they were already correctly indexed to slice 'i')
	tween.tween_method(set_animated_outer_radius_at_index.bind(index), _animated_outer_radius[index], outer_radius + highlight_outer_radius_increase, highlight_duration)
	tween.tween_method(set_animated_inner_radius_at_index.bind(index), _animated_inner_radius[index], inner_radius - highlight_inner_radius_decrease, highlight_duration)

	# Color change (these also remain the same as they were correctly indexed to slice 'i')
	tween.tween_method(set_animated_line_colour_at_index.bind(index), _animated_line_colour[index], highlight_line_colour, highlight_duration)
	tween.tween_method(set_animated_outer_slice_colour_at_index.bind(index), _animated_outer_slice_colour[index], highlight_outer_slice_colour, highlight_duration)
	tween.tween_method(set_animated_inner_slice_colour_at_index.bind(index), _animated_inner_slice_colour[index], highlight_inner_slice_colour, highlight_duration)

	# Line width change for BOTH START and END radial lines of the current slice
	tween.tween_method(set_animated_line_width_start_at_index.bind(index), _animated_line_width_start[index], line_width + highlight_line_width_increase, highlight_duration)
	tween.tween_method(set_animated_line_width_end_at_index.bind(index), _animated_line_width_end[index], line_width + highlight_line_width_increase, highlight_duration)


func reset_slice_visuals(index: int):
	if index < 0 or index >= options: return

	var tween = _get_slice_tween(index)

	# Reset (these remain the same)
	tween.tween_method(set_animated_outer_radius_at_index.bind(index), _animated_outer_radius[index], outer_radius, highlight_duration)
	tween.tween_method(set_animated_inner_radius_at_index.bind(index), _animated_inner_radius[index], inner_radius, highlight_duration)
	tween.tween_method(set_animated_line_colour_at_index.bind(index), _animated_line_colour[index], line_colour, highlight_duration)
	tween.tween_method(set_animated_outer_slice_colour_at_index.bind(index), _animated_outer_slice_colour[index], outer_colour, highlight_duration)
	tween.tween_method(set_animated_inner_slice_colour_at_index.bind(index), _animated_inner_slice_colour[index], inner_colour, highlight_duration)

	# Reset line width for BOTH START and END radial lines of the current slice
	tween.tween_method(set_animated_line_width_start_at_index.bind(index), _animated_line_width_start[index], line_width, highlight_duration)
	tween.tween_method(set_animated_line_width_end_at_index.bind(index), _animated_line_width_end[index], line_width, highlight_duration)
