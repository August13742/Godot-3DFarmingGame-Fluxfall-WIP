@tool
extends Control
class_name RadialMenu

@export_tool_button("Generate") var generate:Callable = _generate
const ICON_SIZE := Vector2(32,32)

@export var inner_colour:Color

@export var textures:Array[Texture2D] = []
@export var texture_scale:int = 3

@export var outer_radius:int = 320
@export var outer_fill_colour:Color
@export var inner_radius: int = 80

@export var inner_fill_colour:Color
@export var outline_width:float = 4
@export var line_colour:Color
@export_range(1,12,1) var num_slices: int = 3

@export var offset_angle_deg:float = 45:
	set(num):
		offset_angle_deg = num
		offset_angle_rad = deg_to_rad(num)

var offset_angle_rad:float = deg_to_rad(offset_angle_deg)
@export var slice_seperation:float = 4
## how much radius extends when selected
@export var highlight_extension_factor:float = 1.5
var slices:Array[RadialMenuSlice] = []


func _generate()->void:
	## 1. Clear existing slices to prevent duplication.
	## Iterate backwards to safely remove items from the array being iterated over.
	for i in range(get_child_count() - 1, -1, -1):
		var child = get_child(i)
		if child is RadialMenuSlice:
			child.queue_free() # Removes the node from the scene tree.
	slices.clear()

	## 2. Generate new slices.
	if num_slices == 0:
		return # Avoid division by zero.

	var per_slice_rad:float = TAU / num_slices
	for i in range(num_slices):
		# The clamp logic was redundant; i is always in range.
		# The original calculation was correct, this is just a minor simplification.
		var angle_from = per_slice_rad * i - offset_angle_rad
		var angle_to = per_slice_rad * (i + 1) - offset_angle_rad

		var slice:RadialMenuSlice = RadialMenuSlice.new(
				angle_from,
				angle_to,
				outer_radius,
				outer_fill_colour,
				slice_seperation,
				highlight_extension_factor
			)

		add_child(slice)

		## 3. Set owner to ensure the node is saved with the scene.
		## This is the critical missing step.
		if Engine.is_editor_hint():
			slice.owner = get_tree().edited_scene_root

func _ready() -> void:
	if !Engine.is_editor_hint():
		_generate()



class RadialMenuSlice extends Polygon2D:

	var rad_from:float
	var rad_to:float
	var total_rad:float

	var _radius:float
	var colour:Color
	var line_width:float

	var curve_resolution:int = 32
	var points_extended:= PackedVector2Array()

	var extension_factor:float = 1
	func _init(_rad_from,_rad_to,radius,_colour,_line_width,_extension_factor) -> void:
		self.rad_from = _rad_from
		self.rad_to = _rad_to
		self.total_rad = rad_to-rad_from
		self._radius = radius
		self.colour = _colour
		self.line_width = _line_width

		self.polygon = make_slice()
		self.color = colour
		self.extension_factor = _extension_factor

	func make_slice() -> PackedVector2Array:
		var points := PackedVector2Array()
		points.append(Vector2.ZERO) ## first index is origin
		for i in range(self.curve_resolution + 1):
			var t = i / float(self.curve_resolution)
			var theta = rad_from + t * (rad_to - rad_from)
			var to_append:Vector2 = Vector2(cos(theta) * self._radius, sin(theta) * self._radius)
			points.append(to_append)
			points_extended.append(to_append*self.extension_factor)
		return points
