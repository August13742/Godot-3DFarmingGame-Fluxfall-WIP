extends Node


func _ready() -> void:
	#print(ItemDBUtility.get_craftable_recipe(ItemDB.CRAFTABLES[0] as ItemDB.Keys))
	var dict = {"a":1,"b":2}
	for item in dict:
		print(item)
