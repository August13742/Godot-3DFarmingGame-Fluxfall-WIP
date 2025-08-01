extends Node


var bulletins :Dictionary[BulletinConfig.Keys,Control] = {}

func _enter_tree() -> void:
	EventSystem.BUL_create_bulletin.connect(_on_create_bulletin)
	EventSystem.BUL_destroy_bulletin.connect(_on_destroy_bulletin)

func _on_create_bulletin(key:BulletinConfig.Keys, extra_arg = null)->void:
	if bulletins.has(key):
		return

	var new_bulletin := BulletinConfig.get_bulletin(key)
	new_bulletin.initialise(extra_arg)
	add_child(new_bulletin)
	bulletins[key] = new_bulletin

func _on_destroy_bulletin(key:BulletinConfig.Keys)->void:
	if !bulletins.has(key):
		return

	bulletins[key].queue_free()
	bulletins.erase(key)
