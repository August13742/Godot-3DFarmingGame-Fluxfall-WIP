extends Node2D

@export var radius: float = 100.0
@export var thickness: float = 100.0
@export_range(0.0, 360.0, 0.1) var slice_angle: float = 60.0
@export var resolution: int = 16 # number of segments per slice arc

func _ready():
	var poly = Polygon2D.new()
	add_child(poly)
	poly.polygon = make_slice(slice_angle, radius, resolution)
	poly.color = Color(0.2, 0.2, 0.2, 0.8) # semi-transparent dark

func make_slice(angle_deg: float, r: float, steps: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	points.append(Vector2.ZERO)  # center

	var angle_rad = deg_to_rad(angle_deg)
	for i in range(steps + 1):
		var t = i / float(steps)
		var theta = t * angle_rad
		var x = cos(theta) * r
		var y = sin(theta) * r
		points.append(Vector2(x, y))

	return points
