extends Node3D

class_name CraftingTable


@export var crafting_menu_ui = preload("uid://c1w6mvkqn1h1h")

func _ready():
	EventSystem.INT_begin_interaction.connect(_on_interact)


func _on_interact():
	var crafting_menu:Control = crafting_menu_ui.instantiate()
	get_tree().get_first_node_in_group("ui_layer").add_child(crafting_menu)
