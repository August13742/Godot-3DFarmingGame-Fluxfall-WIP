extends Node

@export_range(1,5,1) var lod:int = 1

@export var border_size:int = 101

@export var height_map:Dictionary[Vector2,float]
@export var height_multiplier =25
@export var noise_scale:float  = 200
@export var height_curve:Curve = preload("uid://be2gvrsocxjv7")


var simplification_increment:int
var mesh_size_unsimplified:int = 0
var mesh_size:int =0

var noise
var noise_seed:int = 137
@export var noise_fractal_type:FastNoiseLite.FractalType
var height_min:float = 0
var height_max:float = 0
var height_sum:float = 0
var height_average:float = 0
var vertices = PackedVector3Array()
var uvs = PackedVector2Array()
var triangles = PackedVector3Array()

func get_noise_normalised(x:float,z:float):
	return (noise.get_noise_2d(x,z) + 1)/2


func _ready():
	simplification_increment = lod * 2
	border_size += simplification_increment
	noise = FastNoiseLite.new()
	var frequency:float = 1/noise_scale
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 3
	noise.frequency = frequency
	noise.seed = noise_seed
	generate_mesh()


func generate_mesh():
	mesh_size = border_size - 2 * simplification_increment
	mesh_size_unsimplified = border_size -2

	var top_left_x:float = (mesh_size_unsimplified-1)/-2.0
	var top_left_z:float = (mesh_size_unsimplified-1)/2.0

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)


	var index_map:Dictionary[Vector2i,int] = {}

	var mesh_index = 0

## Seamless setup from my Unity project, doesn't work in Godot because index cannot be negative, WIP
	#var border_index = -1
	#for y in range(0,border_size,simplification_increment):
		#for x in range(0,border_size,simplification_increment):
			#var is_border = (x==0) or (y==0) or (x == border_size-1) or (y == border_size -1)
			#var percent = Vector2(
				#(x - simplification_increment)/ float(mesh_size),
				#(y - simplification_increment) / float(mesh_size))
			##var height = randf_range(1,10) ## place holder for noise height
			#var height = 1
			#var pos:Vector3 = Vector3(
				#top_left_x+percent.x * mesh_size_unsimplified,
				#height,
				#top_left_z - percent.y * mesh_size_unsimplified)
			#vertices.append(pos)
			#uvs.append(percent)
			#index_map[Vector2i(x,y)] = border_index if is_border else mesh_index
#
			#st.set_uv(percent)
			#st.add_vertex(pos)
#
			#if is_border:
				#border_index -= 1
			#else:
				#mesh_index += 1


	var ctr:int = 0
	for y in range(0,border_size,simplification_increment):
		for x in range(0,border_size,simplification_increment):
			var percent = Vector2(
				(x - simplification_increment)/ float(mesh_size),
				(y - simplification_increment) / float(mesh_size))
			#var height = randf_range(1,10) ## place holder for noise height

			var pos:Vector3 = Vector3(
				top_left_x+percent.x * mesh_size_unsimplified,
				0,
				top_left_z - percent.y * mesh_size_unsimplified)
			var noise_value:float = get_noise_normalised(pos.x,pos.z)
			var height = height_curve.sample(noise_value) * height_multiplier

			if height > height_max:
				height_max = height
			elif height < height_min:
				height_min = height
			height_sum += height
			ctr+=1
			pos.y = height
			vertices.append(pos)
			uvs.append(percent)
			index_map[Vector2i(x,y)] = mesh_index

			st.set_uv(percent)
			st.add_vertex(pos)
			mesh_index += 1

	height_average = height_sum/ctr
	printt(height_max, height_min, height_average)
	for y in range(0,border_size - simplification_increment,simplification_increment):
		for x in range(0,border_size - simplification_increment,simplification_increment):
			var a = index_map[Vector2i(x,y)] # 0,0
			var b = index_map[Vector2i(x+simplification_increment,y)]# 1,0
			var c = index_map[Vector2i(x,y+simplification_increment)]# 0,1
			var d = index_map[Vector2i(x+simplification_increment,y+simplification_increment)]# 1,1
			if a >= 0 and b >= 0 and c >= 0:
				st.add_index(a)
				st.add_index(c)
				st.add_index(b)
				st.add_index(b)
				st.add_index(c)
				st.add_index(d)
				triangles.append(Vector3(a,c,b))
				triangles.append(Vector3(b,c,d))

	st.index()
	st.generate_normals()

	var mesh = st.commit()

	var new_scene = MeshInstance3D.new()
	new_scene.mesh = mesh


	var packed_scene = PackedScene.new()
	packed_scene.pack(new_scene)

	var error = ResourceSaver.save(packed_scene,"res://terrain2.tscn")
	if error != OK:
		print("Failed to save mesh scene:", error)
	else:
		print("Mesh saved successfully.")

	var data = TerrainData.new()
	data.vertex_positions = vertices
	data.triangle_vertices_indexes = triangles
	data.height_multiplier = height_multiplier
	data.highest_height = height_max
	data.lowest_height = height_min
	data.height_mean = height_average
	printt(data.triangle_vertices_indexes.size(),data.triangle_vertices_indexes.size())
	ResourceSaver.save(data, "res://ProceduralTerrain/TerrainData/terrain_data2.tres")
