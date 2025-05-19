extends Node
class_name SpatialPartitioning

## move to saved resource when terrain is finalised. There really is no reason for this to be real-time
@export var target_mesh:Mesh
@export var chunk_size = 64
@onready var debug_parent := Node3D.new()
var aabb:AABB
var chunk_map := {}
var height_lookup := {}
func _ready() -> void:
	aabb= target_mesh.get_aabb()
	var vertices := target_mesh.get_faces() as Array


# Custom sort: first by x, then by z
	vertices.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		if a.x == b.x:
			return a.z < b.z
		return a.x < b.x
	)

	vertices = PackedVector3Array(vertices)
	build_height_lookup(vertices)
	#print(aabb)

	var size = aabb.size
	var chunk_counts = Vector3i(
		ceili(size.x / chunk_size),
		ceili(size.y / chunk_size),
		ceili(size.z / chunk_size)
	)

	print("Chunk grid size: ", chunk_counts)

	for v in vertices:
		var idx = get_chunk_index(v)
		if not chunk_map.has(idx):
			var new_chunk = Chunk.new()
			new_chunk.index = idx
			new_chunk.vertices = PackedVector3Array()
			chunk_map[idx] = new_chunk
		chunk_map[idx].vertices.append(v)

	#print(chunk_map[Vector2i(0,0)])

## ========= DEBUG DRAW
	#add_child(debug_parent)
#
	#for v in chunk_map[Vector2i(0,0)]:
		#var marker := MeshInstance3D.new()
		#marker.mesh = SphereMesh.new()
		#marker.transform.origin = v
		#marker.scale = Vector3(5,5,5) # debug sphere
		#debug_parent.add_child(marker)

func get_chunk_index(pos: Vector3) -> Vector2i:
	var local_pos = pos - aabb.position
	return Vector2i(
		int(local_pos.x / chunk_size),
		int(local_pos.z / chunk_size)
	)
# In SpatialPartitioning.gd
func build_height_lookup(vertices: PackedVector3Array):
	height_lookup.clear()
	var grid_size := 0.1  # Adjust this based on your terrain density

	# First pass: Collect all heights per grid cell
	var height_grid := {}
	for v in vertices:
		var grid_x = snapped(v.x, grid_size)
		var grid_z = snapped(v.z, grid_size)
		var key := Vector2(grid_x, grid_z)

		if not height_grid.has(key):
			height_grid[key] = []
		height_grid[key].append(v.y)

	# Second pass: Average heights in each cell
	for key in height_grid:
		var heights = height_grid[key]
		var average_height = heights.reduce(func(acc, h): return acc + h) / heights.size()
		height_lookup[key] = average_height


class Chunk:
	var vertices:PackedVector3Array
	var index:Vector2i
	var boundary_low:Vector2
	var boundary_high:Vector2
