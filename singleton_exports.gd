extends Node



@export_category("TimeManager")
@export_range( 0.0, 24., 0.0001 ) var day_time:float = 9.
@export_range( 1, 365, 1 ) var day_of_year : int = 1
@export_range(1,7200,1) var time_scale:int = 60

func _enter_tree() -> void:
	TimeManager.day_time = day_time
	TimeManager.day_of_year = day_of_year
	TimeManager.time_scale = time_scale

	self.queue_free()
