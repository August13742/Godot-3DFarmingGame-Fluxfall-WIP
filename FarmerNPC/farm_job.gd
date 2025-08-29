extends Resource
class_name FarmJob

enum Type { WATER, PLANT, HARVEST }
@export var type: Type
@export var bed: NodePath
@export var priority := 0
@export var payload := {}
@export var target_pos: Vector3
var reserved_by := -1
func is_reserved() -> bool: return reserved_by != -1
