class_name ItemInstance
'''
represents items in a player's inventory, holds mutable state
'''
extends RefCounted

var id: StringName
var count: int = 1

# Add other mutable properties here as needed, e.g.:
# var durability: int = 100
