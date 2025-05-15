extends Node3D


func _ready():
	print(ItemDB.Keys.Plant)
	print(ItemDBUtility.get_stack_size(ItemDB.Keys.Plant))
	print(ItemDBUtility.get_item_name(ItemDB.Keys.Plant))

	pass
