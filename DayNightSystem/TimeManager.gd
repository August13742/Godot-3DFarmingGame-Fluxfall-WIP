extends Node
## AUTOLOAD

## Assumes `game_time` is updated externally each frame.

var game_time: float = 6.0 # External input: current game time in hours (0–24)
var current_date: int = 1
var total_days_in_a_cycle: int = 365

var current_hour: int
var current_minute: int

var growth_tick_manager:PackedScene = preload("uid://doxoimixlbpq")
var _last_ui_minute: int = -1

signal update_timer_ui(hour: int, minute: int, day: int)
signal minute_changed

func _ready() -> void:
	var growth_tick_manager_scene:Node = growth_tick_manager.instantiate()
	self.add_child(growth_tick_manager_scene)

var previous_minute:int = 0
func _process(_delta: float) -> void:
	current_hour = floori(game_time)
	current_minute = floori((game_time - current_hour) * 60)

	## dealing with high time scale skipping minutes
	var skipped = (current_minute - previous_minute + 60) % 60
	for i in range(1, skipped + 1):
		var minute = (previous_minute + i) % 60
		minute_changed.emit()

		# Emit update every 10 minutes
		if minute % 10 == 0:
			_last_ui_minute = minute
			update_timer_ui.emit(current_hour, minute, current_date)

	previous_minute = current_minute
