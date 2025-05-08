extends Node3D


@onready var mesh :MeshInstance3D= $Mesh
@export var terrain_config: TerrainMaterialConfig = preload("uid://talvqn2yl87u")



func _ready():
	apply_shader(mesh.material_override)

func apply_shader(material: ShaderMaterial):
	var count = terrain_config.terrain_materials.size()
	count = clamp(count, 0, 7) # shader currently supports 7 max

	material.set_shader_parameter("max_height",25)



	for i in range(count):
		print("hi")
		var layer = terrain_config.terrain_materials[i]
		#material.set_shader_parameter("texture%d"%i, layer.texture)
		#print("texture%d"%i)

		material.set_shader_parameter("colour%d" % i, layer.colour)
		material.set_shader_parameter("threshold%d" % i, layer.height_threshold)
		material.set_shader_parameter("sharpness%d" % i, layer.blend_sharpness)
		material.set_shader_parameter("texture%d"%i,layer.texture)
	material.set_shader_parameter("layer_count", count)
	print("Uniforms:", (material.shader as Shader).get_shader_uniform_list())
