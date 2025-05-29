extends Node
## AUTOLOAD


const HOURS_IN_DAY : float = 24.0
const DAYS_IN_YEAR : int = 365
@export_range( 0.0, HOURS_IN_DAY, 0.0001 ) var day_time : float = 0.0 :
	set( value ) :
		day_time = value
		if day_time < 0.0 :
			day_time += HOURS_IN_DAY
			day_of_year -= 1
		elif day_time > HOURS_IN_DAY :
			day_time -= HOURS_IN_DAY
			day_of_year += 1
		if stellar_body_rotation_component != null:
			stellar_body_rotation_component.day_time = day_time

@export_range( 1, DAYS_IN_YEAR, 1 ) var day_of_year : int = 1 :
	set( value ) :
		day_of_year = value
		if stellar_body_rotation_component != null:
			stellar_body_rotation_component.day_of_year = day_of_year

@export var time_scale:int = 7200
@export var start_hour:int = 9
var stellar_body_rotation_component:StellarBodyRotation = null


var current_hour: int
var current_minute: int

var growth_tick_manager:PackedScene = preload("uid://doxoimixlbpq")
var _last_ui_minute: int = -1

signal update_timer_ui(hour: int, minute: int, day: int)
signal minute_changed
signal day_changed

func _ready() -> void:
	var growth_tick_manager_scene:Node = growth_tick_manager.instantiate()
	self.add_child(growth_tick_manager_scene)
	late_init()

func late_init():
	day_time = start_hour



var previous_minute:int = 0
var previous_day:int = 0
var date_changed:bool = false


func _process(_delta: float) -> void:

	var scaled_hours = _delta * time_scale / 3600.0  # Convert seconds → hours
	day_time += scaled_hours  # triggers setter


	current_hour = floori(day_time)
	current_minute = floori((day_time - current_hour) * 60)


	## dealing with high time scale skipping minutes
	var skipped = (current_minute - previous_minute + 60) % 60
	for i in range(1, skipped + 1):
		var minute = (previous_minute + i) % 60
		minute_changed.emit()

		# Emit update every 10 minutes
		if minute % 10 == 0:
			_last_ui_minute = minute
			update_timer_ui.emit(current_hour, minute, day_of_year)

	previous_minute = current_minute
	if previous_day != day_of_year:
		previous_day = day_of_year
		date_changed = true
		day_changed.emit()

	if date_changed && current_hour == 6:
		date_changed = false
		EventSystem.emit_GAME_NEW_DAY()
