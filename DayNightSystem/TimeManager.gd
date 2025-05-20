extends Node


## Assumes `game_time` is updated externally each frame.

var game_time: float = 6.0 # External input: current game time in hours (0–24)
var current_date: int = 1
var total_days_in_a_cycle: int = 365

var current_hour: int
var current_minute: int


var _last_ui_minute: int = -1

signal update_timer_ui(hour: int, minute: int, day: int)

func _process(_delta: float) -> void:
	# Decompose time
	current_hour = floori(game_time)
	current_minute = floori((game_time - current_hour) * 60)
	# Only emit if minute is a multiple of 10 and not already emitted
	if current_minute % 10 == 0 and current_minute != _last_ui_minute:
		_last_ui_minute = current_minute
		update_timer_ui.emit(current_hour, current_minute, current_date)


func _on_minute_changed() -> void:
	# React to minute change, e.g., for simulation logic
	pass
