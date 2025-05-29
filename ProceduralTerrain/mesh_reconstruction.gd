extends MeshInstance3D

@export var mesh_data = preload("res://ProceduralTerrain/TerrainData/terrain_data2.tres")
@export var terrain_config: TerrainMaterialConfig = preload("uid://talvqn2yl87u")



func _ready() -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in mesh_data.vertex_positions:
		st.add_vertex(vertex)
	for uv in mesh_data.uvs:
		st.set_uv(uv)
	for triangle_vertex in mesh_data.triangle_vertices_indexes:
		st.add_index(triangle_vertex.x)
		st.add_index(triangle_vertex.y)
		st.add_index(triangle_vertex.z)


	st.index()
	st.generate_normals()
	mesh = st.commit()
	create_trimesh_collision.call_deferred()


	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = preload("uid://dmwo2goh4ood")
	material_override = shader_mat
	apply_shader(material_override)




func apply_shader(material: ShaderMaterial):
	var count = terrain_config.terrain_materials.size()

	material.set_shader_parameter("max_height",42)



	for i in range(count):
		var layer = terrain_config.terrain_materials[i]

		#print("texture%d"%i)
		print(layer.name)
		material.set_shader_parameter("colour%d" % i, layer.colour)
		material.set_shader_parameter("threshold%d" % i, layer.start_threshold)
		material.set_shader_parameter("sharpness%d" % i, layer.blend_sharpness)
		material.set_shader_parameter("texture%d"%i,layer.texture)
	material.set_shader_parameter("layer_count", count)
	print(count)
	#print("Uniforms:", (material.shader as Shader).get_shader_uniform_list())
