@tool
class_name ProceduralMesh
extends MeshInstance3D


var surface_tool = SurfaceTool
var border_size = 100

var mesh_vertex_index:int = 0
var border_vertex_index:int = -1

var vertices = PackedVector3Array()
var triangles:Array[int]
var uvs = PackedVector2Array()

var border_vertices = PackedVector3Array()
var border_triangles:Array[int]

var bordering_triangle_index:int = 0
var triangle_index:int = 0


func initiate():
	vertices.resize(border_size * border_size)
	triangles.resize((border_size-1)*(border_size-1))

	border_vertices.resize(border_size * 4 + 4)
	border_triangles.resize(24*border_size)

	uvs.resize(border_size*border_size)

func add_vertex(vertex_position:Vector3, uv:Vector2, vertex_index:int):
		if (vertex_index < 0):
			border_vertices [-vertex_index - 1] = vertex_position;
		else:
			vertices [vertex_index] = vertex_position;
			uvs [vertex_index] = uv;

func add_triangles(a:int, b:int, c:int):
	if (a<0 || b<0 || c<0):
		border_triangles[bordering_triangle_index] = a
		border_triangles[bordering_triangle_index+1] = b
		border_triangles[bordering_triangle_index+2] = c
		bordering_triangle_index += 3
	else:
		triangles[triangle_index] = a
		triangles[triangle_index+1] = b
		triangles[triangle_index+2] = c
		triangle_index += 3


func surface_normal_from_indices(index_a:int,index_b:int,index_c:int):
	var point_a:Vector3 = border_vertices[-index_a-1] if index_a < 0 else vertices[index_a]
	var point_b:Vector3 = border_vertices[-index_b-1] if index_b < 0 else vertices[index_b]
	var point_c:Vector3 = border_vertices[-index_c-1] if index_c < 0 else vertices[index_c]

	var side_ab: Vector3 = point_b - point_a
	var side_ac: Vector3 = point_c - point_a

	return side_ab.cross(side_ac).normalized()


func calculate_normals()->Vector3:
	var vertex_normals = PackedVector3Array()
	vertex_normals.resize(vertices.size())
	@warning_ignore("integer_division")
	var triangle_count:int = (triangles.size()/3)
	for i in range (triangle_count):
		var normal_triangle_index:int = i*3
		var vertex_index_a = triangles[normal_triangle_index]
		var vertex_index_b = triangles[normal_triangle_index+1]
		var vertex_index_c = triangles[normal_triangle_index+2]

		var triangle_normal:Vector3 = surface_normal_from_indices(vertex_index_a,vertex_index_b,vertex_index_c)
		vertex_normals[vertex_index_a] += triangle_normal
		vertex_normals[vertex_index_b] += triangle_normal
		vertex_normals[vertex_index_c] += triangle_normal

	@warning_ignore("integer_division")
	var bordering_triangle_count:int = border_triangles.size() /3
	for i in range(bordering_triangle_count):
		var normal_triangle_index:int = i*3
		var vertex_index_a:int = border_triangles[normal_triangle_index]
		var vertex_index_b:int = border_triangles[normal_triangle_index+1]
		var vertex_index_c:int = border_triangles[normal_triangle_index+2]
		var triangle_normal:Vector3 = surface_normal_from_indices(vertex_index_a,vertex_index_b,vertex_index_c)
		if (vertex_index_a >= 0):
			vertex_normals[vertex_index_a]+= triangle_normal
		if (vertex_index_b >= 0):
			vertex_normals[vertex_index_b]+= triangle_normal
		if (vertex_index_c >= 0):
			vertex_normals[vertex_index_c]+= triangle_normal
	for i in range(vertex_normals.size()):
		vertex_normals[i].normalized()

	return vertex_normals

var baked_normals = PackedVector3Array()
func bake_normals():
	baked_normals = calculate_normals()

func create_mesh():
	pass
