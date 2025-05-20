extends Node3D

@export var chunk_size: int = 64
@export var GRASS_PER_REGION: int = 1024
@export var multi_mesh_mesh: ArrayMesh
@onready var spatial_partitioning: SpatialPartitioning = $"../SpatialPartitioning"
@onready var target_terrain_mesh: MeshInstance3D = $"../StaticBody3D/Terrain"
var camera: Camera3D
@export var cull_distance := 80
@onready var _cull_distance:= cull_distance*cull_distance
@export var grass_shader_material := preload("uid://bm3i4ub665khr")
@export var cast_shadow:bool = true
func _ready() -> void:
	var chunk_map = spatial_partitioning.chunk_map
	chunk_size = spatial_partitioning.chunk_size
	var aabb = spatial_partitioning.aabb

	for idx in chunk_map.keys():
		var mm_instance = MultiMeshInstance3D.new()
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = GRASS_PER_REGION

		# World position of chunk origin
		var chunk_origin_local = spatial_partitioning.aabb.position + Vector3(idx.x * chunk_size, 0, idx.y * chunk_size)
		var chunk_origin_global = target_terrain_mesh.global_transform * chunk_origin_local
		var chunk_origin_local_in_parent = self.to_local(chunk_origin_global)

		mm_instance.transform.origin = chunk_origin_local_in_parent
		mm_instance.multimesh = mm
		mm_instance.material_override = grass_shader_material

		mm_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mm.mesh = multi_mesh_mesh
		add_child(mm_instance)

		## culling
		mm_instance.set_meta("world_center", chunk_origin_global + Vector3(chunk_size * 0.5, 0, chunk_size * 0.5))
		mm_instance.set_meta("bounding_radius", chunk_size * 0.75)  # or tighter fit if needed


		for i in range(GRASS_PER_REGION):
			var local_x = randf() * chunk_size
			var local_z = randf() * chunk_size
			var world_x = chunk_origin_global.x + local_x
			var world_z = chunk_origin_global.z + local_z

			var y = sample_height_raycast(world_x, world_z)
			var local_y = y - chunk_origin_global.y

			var xf = Transform3D().translated(Vector3(local_x, local_y, local_z))
			mm.set_instance_transform(i, xf)

	_late_init.call_deferred()

func _late_init()->void:
	camera = get_viewport().get_camera_3d()


func _process(_delta: float) -> void:
	if camera == null:
		return

	for mm in get_children():
		if not mm is MultiMeshInstance3D:
			continue

		var center: Vector3 = mm.get_meta("world_center")
		var dist := camera.global_transform.origin.distance_squared_to(center)
		mm.visible = dist < _cull_distance


func sample_height_raycast(x: float, z: float) -> float:
	var aabb = spatial_partitioning.aabb
	var from = Vector3(x, aabb.position.y + aabb.size.y + 10.0, z)
	var to = Vector3(x, aabb.position.y - 10.0, z)

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = target_terrain_mesh.get_parent().collision_layer
	query.exclude = [self]

	var space := get_world_3d().direct_space_state
	var result := space.intersect_ray(query)
	return result.position.y if result.has("position") else aabb.position.y
