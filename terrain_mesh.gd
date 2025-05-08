extends MeshInstance3D


@export var terrain_config: TerrainMaterialConfig = preload("uid://talvqn2yl87u")



func _ready():
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = preload("uid://dmwo2goh4ood")
	material_override = shader_mat
	apply_shader(material_override)

func apply_shader(material: ShaderMaterial):
	var count = terrain_config.terrain_materials.size()

	material.set_shader_parameter("max_height",40)



	for i in range(count):
		var layer = terrain_config.terrain_materials[i]

		#print("texture%d"%i)
		print(layer.name)
		material.set_shader_parameter("colour%d" % i, layer.colour)
		material.set_shader_parameter("threshold%d" % i, layer.height_threshold)
		material.set_shader_parameter("sharpness%d" % i, layer.blend_sharpness)
		material.set_shader_parameter("texture%d"%i,layer.texture)
	material.set_shader_parameter("layer_count", count)
	print(count)
	#print("Uniforms:", (material.shader as Shader).get_shader_uniform_list())
