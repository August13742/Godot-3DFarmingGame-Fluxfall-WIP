extends Node

@export var main_camera:Camera3D
@export var follow_cam:ThirdPersonObserverCamera



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("set_camera_1"):
		main_camera.current = true
		follow_cam.set_process(false)
	elif event.is_action_pressed("set_camera_2"):
		follow_cam.camera.current = true
		follow_cam.set_process(true)
