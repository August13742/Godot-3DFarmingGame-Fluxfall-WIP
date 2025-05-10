extends CanvasLayer

@export var player_menu := preload("uid://q81mp7mnrdap")

var player_menu_scene:CanvasItem
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		if player_menu_scene == null:
			player_menu_scene = player_menu.instantiate()
			self.add_child(player_menu_scene)
			player_menu_scene.visible = false

		player_menu_scene.visible = false if player_menu_scene.visible else true
