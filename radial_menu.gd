@tool
extends Control

const ICON_SIZE:=64
@export var background_colour:Color
@export var outer_radius:int = 256
@export var line_colour:Color
@export var inner_radius:int = 64
@export var line_width:int = 4
@export var outer_colour:Color
@export_range(3,12,1) var options:int = 4
@export var degree_offset:float

var rads_storage:Array[Vector2] = []
func _draw():
	var offset := ICON_SIZE/2.
	draw_circle(Vector2.ZERO,outer_radius,background_colour)
	draw_arc(Vector2.ZERO,inner_radius,0,TAU,128,line_colour,line_width,true)

	if options >=3:
		for i in range(options):
			var rads := TAU*i/options
			var point := Vector2.from_angle(rads+deg_to_rad(degree_offset))
			rads_storage.append(point)
			draw_line(
				point*inner_radius,
				point*outer_radius,
				line_colour,
				line_width,
				true
			)
	draw_arc(Vector2.ZERO,outer_radius,0,TAU,128,outer_colour,line_width,true)

	var flexible_area:int = outer_radius - inner_radius
	var area_midpoint:float = flexible_area/2.
	print(area_midpoint*rads_storage[0])
#@onready var texture_rect: TextureRect = $TextureRect


func _ready():
	pass
