extends AnimationPlayer


signal foot_step
func _on_foot_on_ground()->void:
	foot_step.emit()
