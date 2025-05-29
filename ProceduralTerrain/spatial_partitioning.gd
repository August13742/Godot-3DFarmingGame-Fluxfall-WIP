extends Node
class_name SpatialPartitioning

@export var target_terrain_mesh: MeshInstance3D
@export var target_mesh: Mesh
@export var chunk_size = 64

var aabb: AABB
var chunk_map: = {}

func _ready() -> void:
	aabb = target_terrain_mesh.get_aabb()
	var vertices := target_mesh.get_faces() as Array

	# Remove duplicates
	var unique_set := {}
	for v in vertices:
		unique_set[v] = true
	vertices = PackedVector3Array(unique_set.keys())

	for v in vertices:
		var idx = get_chunk_index(v)
		if not chunk_map.has(idx):
			var new_chunk = Chunk.new()
			new_chunk.index = idx
			new_chunk.vertices = PackedVector3Array()
			chunk_map[idx] = new_chunk
		chunk_map[idx].vertices.append(v)

func get_chunk_index(pos: Vector3) -> Vector2i:
	var local_pos = pos - aabb.position
	return Vector2i(
		int(local_pos.x / chunk_size),
		int(local_pos.z / chunk_size)
	)

class Chunk:
	var vertices: PackedVector3Array
	var index: Vector2i
