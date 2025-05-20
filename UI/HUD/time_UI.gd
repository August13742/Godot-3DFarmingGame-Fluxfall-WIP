extends Label

func _ready() -> void:
	TimeManager.update_timer_ui.connect(_on_update)

	


func _on_update(hour:int,minute:int,day:int):
	self.text = TimeUtility.format_seconds_to_string(hour, minute)
	self.text += "\nDay: %d"%day
