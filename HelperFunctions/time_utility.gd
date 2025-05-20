extends Object

## Helper Functions Related to GameTime Calculation
class_name TimeUtility


## Calculate Minute, remaining Seconds from Seconds input
static func get_minute_seconds(seconds:float) -> Array[int]:
	var minutes:int = floor(seconds / 60)
	var remaining_seconds:int = floor(seconds - minutes * 60)
	return [minutes,remaining_seconds]


## 	Calculate Minute, remaining Seconds from Seconds input, Output as String "00:00"
static func get_time_as_string(seconds:float):
	var time = get_minute_seconds(seconds)
	return str(time[0]) + ":" + "%02d" %time[1]

## 	Expects Argument (minutes,seconds)
static func format_seconds_to_string(minutes:int,seconds:int):
	return str(minutes) + ":" + "%02d" %seconds
