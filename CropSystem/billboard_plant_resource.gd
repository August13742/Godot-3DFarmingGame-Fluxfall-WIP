@tool
extends Resource
class_name BillboardPlantResource

@export var textures:Dictionary[CropBed.Stage,CompressedTexture2D] = {
	CropBed.Stage.Seed:null,
	CropBed.Stage.Stage1:null,
	CropBed.Stage.Stage2:null,
	CropBed.Stage.Stage3:null,
	CropBed.Stage.Harvestable:null
}

@export_range(0.0, 1.0, 0.01) var alpha_thresh := 0.10 : set = _set_thresh
# Minimum scale to ensure visibility
@export_range(0.05, 2.0, 0.05) var min_visible_scale := 0.05
@export_tool_button("Recompute Data") var recompute_action:Callable = _recompute_all
# Baked data
@export var uv_rect_by_stage: Dictionary = {}
@export var scale_factors_by_stage: Dictionary = {}
@export var vertical_offsets_by_stage: Dictionary = {}

func _set_thresh(v: float) -> void:
	alpha_thresh = v
	if Engine.is_editor_hint():
		_recompute_all()

func _recompute_all() -> void:
	print("Recomputing billboard data...")

	uv_rect_by_stage.clear()
	scale_factors_by_stage.clear()
	vertical_offsets_by_stage.clear()

	# First pass: collect all natural sizes
	var natural_sizes = {}
	for stage in textures.keys():
		var tex := textures[stage] as Texture2D
		if not is_instance_valid(tex):
			continue

		var img: Image = tex.get_image()
		if not is_instance_valid(img):
			continue

		if img.is_compressed():
			img.decompress()

		# Get the used rect and texture dimensions
		var used_rect: Rect2i = img.get_used_rect()
		var tex_width := img.get_width()
		var tex_height := img.get_height()

		if tex_width == 0 or tex_height == 0:
			continue

		# Calculate UV rectangle
		var uv_rect := Rect2(
			float(used_rect.position.x) / tex_width,
			float(used_rect.position.y) / tex_height,
			float(used_rect.size.x) / tex_width,
			float(used_rect.size.y) / tex_height
		)

		uv_rect_by_stage[stage] = uv_rect
		natural_sizes[stage] = uv_rect.size.y

		print("Stage ", stage, ": Natural Size=", uv_rect.size.y)

	# Find the maximum size for normalization
	var max_size = 0.0
	for size in natural_sizes.values():
		if size > max_size:
			max_size = size

	# Second pass: calculate scale factors with minimum visibility constraint
	for stage in natural_sizes.keys():
		var natural_size = natural_sizes[stage]
		var normalized_size = natural_size / max_size

		# Apply minimum scale constraint
		var scale_factor = max(normalized_size, min_visible_scale)
		scale_factors_by_stage[stage] = scale_factor

		# Calculate vertical offset to position the plant at the bottom
		var uv_rect = uv_rect_by_stage[stage]
		var vertical_offset = (1.0 - uv_rect.size.y) * 0.5 - uv_rect.position.y
		vertical_offsets_by_stage[stage] = vertical_offset

		print("Stage ", stage, ": UV Rect=", uv_rect,
			  " Scale Factor=", scale_factor,
			  " Vertical Offset=", vertical_offset)

func get_stage_params(stage: int, base_height: float) -> Dictionary:
	var uv :Rect2= uv_rect_by_stage.get(stage, Rect2(0,0,1,1))
	var scale_factor :float= scale_factors_by_stage.get(stage, 1.0)
	var vertical_offset :float= vertical_offsets_by_stage.get(stage, 0.0)

	return {
		"uv_rect": uv,
		"scale_factor": scale_factor * base_height,
		"vertical_offset": vertical_offset * base_height
	}
