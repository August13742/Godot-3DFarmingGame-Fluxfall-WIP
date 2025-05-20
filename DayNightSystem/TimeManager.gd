extends Node

var game_time:float = 6. ## init state is 6 am
var time_speed:int = 120 ## 5 minute = 1 game hour
var time_elapsed:float= 0.

func _process(delta):
	var scaled_delta_time:float = delta * time_speed
	time_elapsed += scaled_delta_time
	game_time = fmod((game_time + scaled_delta_time/60),24.)

	if time_elapsed >= 10.:
		_update_timer_UI()

func _update_timer_UI():
	time_elapsed = 0
	pass
