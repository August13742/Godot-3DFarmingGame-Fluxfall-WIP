extends Resource
class_name ItemResource

@export var id: StringName
@export var display_name: String
@export var icon: CompressedTexture2D
@export var stack_size: int = 99
@export_multiline var description:String = "just a humble %s."%display_name
@export var tags: PackedStringArray
@export var capabilities: Array[ItemCapability]


func get_capability(T_script: Script) -> ItemCapability:
	for c in capabilities:
		if c != null and c.get_script() == T_script:
			return c
	return null

func has_capability(T_script): return get_capability(T_script) != null
