@tool
extends CanvasItem

#@export_tool_button("Generate")
@onready var per_slice_rad:float = TAU / owner.num_slices
func _ready() -> void:
	queue_redraw()


func _draw()->void:

	for i in range(owner.num_slices):

			var left:int = clamp(i,0,owner.num_slices)
			#var right:int = clamp(i+1,0,owner.num_slices)
			draw_line(Vector2.ZERO, owner.outer_radius*Vector2.from_angle(per_slice_rad*left),
			owner.line_colour,owner.outline_width)


	draw_circle(Vector2.ZERO,owner.inner_radius,owner.inner_fill_colour,true,-1,true)
	draw_circle(Vector2.ZERO,owner.inner_radius,owner.line_colour,false,owner.outline_width,true) ## inner outline
	draw_circle(Vector2.ZERO,owner.outer_radius,owner.line_colour,false,owner.outline_width,true) ## outer outline
