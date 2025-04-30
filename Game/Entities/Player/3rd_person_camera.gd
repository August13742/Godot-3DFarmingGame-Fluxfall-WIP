extends Node3D
class_name ThirdPersonCamera

var mouse_sensitivity:float = 0.05


func _ready() -> void:
	if "mouse_sensitivity" in owner:
		mouse_sensitivity = owner.mouse_sensitivity


func _input(event:InputEvent):
	if event is InputEventMouseMotion:
		look_around(event.relative)


func look_around(relative:Vector2,_delta:float=1):
	#camera_pivot.rotate_y(-relative.x * mouse_sensitivity)
#
	#camera_pivot.rotate_x(-relative.y * mouse_sensitivity)
	#camera_pivot.rotation_degrees.x = clampf(camera_pivot.rotation_degrees.x,-60,60)
	'''
	above is a classic pitfall using rotate() instead of direct angle manipulation.
	rotating x or y would cause the following x/y to not be the same as before,
	hence introducing unwanted z-axis rotation, as well as unintented behaviours
	'''
	rotation.y += -relative.x * mouse_sensitivity
	rotation.x += -relative.y * mouse_sensitivity
	rotation_degrees.x = clampf(rotation_degrees.x,-60,80)
