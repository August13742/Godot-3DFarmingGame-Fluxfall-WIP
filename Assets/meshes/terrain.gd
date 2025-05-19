extends MeshInstance3D

func create_terrain_collision(terrain_mesh: Mesh, parent: StaticBody3D) -> void:
	var collider := CollisionShape3D.new()
	collider.shape = terrain_mesh.create_trimesh_shape()
	parent.add_child(collider)


func _ready() -> void:
	create_terrain_collision.call_deferred(mesh,get_parent())
