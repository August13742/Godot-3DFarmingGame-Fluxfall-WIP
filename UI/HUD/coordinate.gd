extends Label

@onready var target_entity:Node3D = get_tree().get_first_node_in_group("player")

func _physics_process(_delta: float) -> void:
	self.text = "%s"%target_entity.global_position
