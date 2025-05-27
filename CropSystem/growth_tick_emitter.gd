extends Node

## with time_scale of 60 this equates to 1 real life seconds per check (I = 60)
@export var tick_interval:int = 1
@export_range(0,1,0.01) var tick_chance:float = 0.2
var interval_counter:int = 0

func _ready() -> void:
	late_init.call_deferred()

func late_init()->void:
	TimeManager.time_changed.connect(_on_time_changed)


func _on_time_changed():
	interval_counter += 1
	if interval_counter >= tick_interval:
		interval_counter = 0
		if attempt_growth_tick():

			EventSystem.emit_CROP_growth_tick_emitted()


func attempt_growth_tick()->bool:
	print("attempting growth tick")
	return true if randf()<tick_chance else false
