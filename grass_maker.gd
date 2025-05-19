extends Node3D

@export var chunk_size:int = 128
@export var GRASS_PER_REGION:int = 1024
@onready var spatial_partitioning: SpatialPartitioning = $"../SpatialPartitioning"
var height_lookup
@export var multi_mesh_mesh:ArrayMesh
@onready var target_terrain_mesh:MeshInstance3D = $"../Terrain"

func _ready() -> void:
	#target_terrain_mesh.create_convex_collision()
	var chunk_map = spatial_partitioning.chunk_map
	chunk_size = spatial_partitioning.chunk_size
	height_lookup = spatial_partitioning.height_lookup

	for idx in chunk_map.keys():
		var mm_instance = MultiMeshInstance3D.new()
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = GRASS_PER_REGION

		# Calculate chunk origin in world space
		var chunk_origin_local = spatial_partitioning.aabb.position + Vector3(idx.x * chunk_size, 0, idx.y * chunk_size)
		var chunk_origin_global = target_terrain_mesh.global_transform * chunk_origin_local
		var chunk_origin_local_in_parent = self.to_local(chunk_origin_global)

		# Configure MultiMeshInstance3D
		mm_instance.transform.origin = chunk_origin_local_in_parent
		mm_instance.multimesh = mm
		mm.mesh = multi_mesh_mesh
		add_child(mm_instance)

		# Populate MultiMesh transforms
		for i in range(GRASS_PER_REGION):
			var local_x = randf() * chunk_size
			var local_z = randf() * chunk_size

			# Calculate world position for height sampling
			var world_x = chunk_origin_global.x + local_x
			var world_z = chunk_origin_global.z + local_z
			var y = sample_terrain_height(world_x, world_z)

			# Calculate local y position relative to chunk origin
			var local_y = y - chunk_origin_global.y

			# Set instance transform relative to chunk origin
			var _transform = Transform3D().translated(Vector3(local_x, local_y, local_z))
			mm.set_instance_transform(i, _transform)

func sample_terrain_height(x: float, z: float) -> float:
	var grid_size := 1.0  # Must match SpatialPartitioning's grid_size

	# Convert to terrain's local space
	var world_pos = Vector3(x, 0, z)
	var local_pos = target_terrain_mesh.global_transform.affine_inverse() * world_pos

	# Find the 4 nearest grid points
	var x0 = snapped(local_pos.x, grid_size)
	var x1 = x0 + grid_size
	var z0 = snapped(local_pos.z, grid_size)
	var z1 = z0 + grid_size

	# Get heights for surrounding grid points
	var h00 = spatial_partitioning.height_lookup.get(Vector2(x0, z0), 0.0)
	var h01 = spatial_partitioning.height_lookup.get(Vector2(x0, z1), 0.0)
	var h10 = spatial_partitioning.height_lookup.get(Vector2(x1, z0), 0.0)
	var h11 = spatial_partitioning.height_lookup.get(Vector2(x1, z1), 0.0)

	# Bilinear interpolation
	var x_ratio = (local_pos.x - x0) / grid_size
	var z_ratio = (local_pos.z - z0) / grid_size
	var interpolated_height = lerp(
		lerp(h00, h10, x_ratio),
		lerp(h01, h11, x_ratio),
		z_ratio
	)

	# Convert back to global space
	var global_height = target_terrain_mesh.global_transform * Vector3(0, interpolated_height, 0)
	return global_height.y
