@tool
extends MeshInstance3D

@export_range(0.05, 5.0, 0.01) var half_width := 0.5 : set = _set_half_width
@export_range(0.10, 10.0, 0.01) var height := 1.6    : set = _set_height
@export_enum("2-way", "4-way") var cross := 1        : set = _set_cross
@export var generate_in_editor := true               : set = _set_generate

func _ready() -> void:
	if Engine.is_editor_hint() and generate_in_editor:
		_rebuild()

func _set_half_width(v: float) -> void:
	half_width = v
	if Engine.is_editor_hint() and generate_in_editor: _rebuild()

func _set_height(v: float) -> void:
	height = v
	if Engine.is_editor_hint() and generate_in_editor: _rebuild()

func _set_cross(v: int) -> void:
	cross = v
	if Engine.is_editor_hint() and generate_in_editor: _rebuild()

func _set_generate(v: bool) -> void:
	generate_in_editor = v
	if Engine.is_editor_hint(): _rebuild()

func add_quad(deg: float, verts: PackedVector3Array, uvs: PackedVector2Array,
			 normals: PackedVector3Array, idx: PackedInt32Array) -> void:
	var rot := Basis().rotated(Vector3.UP, deg_to_rad(deg))
	var y0 := 0.0
	var y1 := height

	var p0 := rot * Vector3(-half_width, y0, 0)
	var p1 := rot * Vector3( half_width, y0, 0)
	var p2 := rot * Vector3( half_width, y1, 0)
	var p3 := rot * Vector3(-half_width, y1, 0)

	var normal := rot * Vector3.FORWARD

	var base := verts.size()
	verts.push_back(p0); verts.push_back(p1); verts.push_back(p2); verts.push_back(p3)

	for i in range(4):
		normals.push_back(normal)

	uvs.push_back(Vector2(0,1)); uvs.push_back(Vector2(1,1)); uvs.push_back(Vector2(1,0)); uvs.push_back(Vector2(0,0))

	idx.push_back(base); idx.push_back(base+1); idx.push_back(base+2)
	idx.push_back(base); idx.push_back(base+2); idx.push_back(base+3)

func _rebuild() -> void:
	var m := ArrayMesh.new()
	var verts := PackedVector3Array()
	var uvs  := PackedVector2Array()
	var normals := PackedVector3Array()
	var idx  := PackedInt32Array()

	add_quad(0.0, verts, uvs, normals, idx)
	add_quad(180.0, verts, uvs, normals, idx)
	if cross == 1:
		add_quad(90.0, verts, uvs, normals, idx)
		add_quad(270.0, verts, uvs, normals, idx)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX]  = idx

	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = m

func bake_to_file(path: String = "res://CropSystem/imposter_plant_cross.res") -> void:
	if mesh == null:
		push_error("No mesh to save.")
		return

	mesh.resource_name = "imposter_plant_cross"
	mesh.take_over_path(path)

	var err := ResourceSaver.save(mesh, path)
	if err != OK:
		push_error("ResourceSaver.save failed: %s" % err)
	else:
		print("Saved: ", path)
