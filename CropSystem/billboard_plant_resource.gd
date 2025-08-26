@tool
extends Resource
class_name BillboardPlantResource

@export var textures:Dictionary[Crop.Stage,CompressedTexture2D] = {
	Crop.Stage.Seed:null,
	Crop.Stage.Stage1:null,
	Crop.Stage.Stage2:null,
	Crop.Stage.Stage3:null,
	Crop.Stage.Harvestable:null
	}

@export_range(0.0, 1.0, 0.01) var alpha_thresh := 0.10 : set = _set_thresh
@export var recompute_now := false : set = _set_recompute

# Baked data (persisted in .tres). Keys are stage ints.
@export var uv_rect_by_stage: Dictionary = {}
@export var vmax_by_stage:    Dictionary = {}
@export var vsize_by_stage:   Dictionary = {}
@export var yoff_by_stage:    Dictionary = {}
@export var hscale_by_stage:  Dictionary = {}

func _set_thresh(v: float) -> void:
	alpha_thresh = v
	if Engine.is_editor_hint():
		_recompute_all()

func _set_recompute(v: bool) -> void:
	if v and Engine.is_editor_hint():
		_recompute_all()
	# Reset the checkbox so it can be clicked again
	recompute_now = false

func _debug_alpha(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var min_a := 1.0
	var max_a := 0.0
	var nonzero := 0
	for y in range(h):
		for x in range(w):
			var a := img.get_pixel(x, y).a
			if a < min_a: min_a = a
			if a > max_a: max_a = a
			if a > 0.0: nonzero += 1
	print("format=", img.get_format(), " used_rect=", img.get_used_rect(),
		  " min_a=", min_a, " max_a=", max_a, " nonzero=", nonzero, "/", w*h)

func _recompute_all() -> void:
	print("Recomputing billboard data...")

	uv_rect_by_stage.clear()
	vmax_by_stage.clear()
	vsize_by_stage.clear()
	yoff_by_stage.clear()
	hscale_by_stage.clear()

	for stage in textures.keys():
		var tex := textures[stage] as Texture2D
		if not is_instance_valid(tex):
			continue

		var img: Image = tex.get_image()
		if not is_instance_valid(img):
			continue

		if img.is_compressed():
			img.decompress()

		_debug_alpha(img)

		var bbox_uv: Rect2 = _measure_alpha_bbox_uv(img, alpha_thresh)
		uv_rect_by_stage[stage] = bbox_uv

		# Calculate parameters
		var vmax := bbox_uv.position.y + bbox_uv.size.y
		var vsize :float= max(bbox_uv.size.y, 0.001)

		vmax_by_stage[stage] = vmax
		vsize_by_stage[stage] = vsize
		yoff_by_stage[stage] = -(1.0 - vmax)
		hscale_by_stage[stage] = vsize

		print("Stage ", stage, ": UV Rect=", bbox_uv, " VMax=", vmax, " VSize=", vsize)

func _measure_alpha_bbox_uv(img: Image, thresh: float) -> Rect2:
	var w := img.get_width()
	var h := img.get_height()

	if w == 0 or h == 0:
		return Rect2(0, 0, 0, 0)

	var min_x := w
	var min_y := h
	var max_x := 0
	var max_y := 0
	var found_pixel := false

	# Find bounding box of pixels with alpha above threshold
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > thresh:
				found_pixel = true
				if x < min_x: min_x = x
				if y < min_y: min_y = y
				if x > max_x: max_x = x
				if y > max_y: max_y = y

	if not found_pixel:
		return Rect2(0, 0, 1, 1)  # Default to full texture if no pixels found

	# Convert to UV coordinates (normalized)
	return Rect2(
		float(min_x) / w,
		float(min_y) / h,
		float(max_x - min_x + 1) / w,
		float(max_y - min_y + 1) / h
	)

func get_stage_params(stage: int, base_height: float) -> Dictionary:
	var uv := uv_rect_by_stage.get(stage, Rect2(0,0,1,1)) as Rect2
	var yoff := (yoff_by_stage.get(stage, 0.0) as float) * base_height
	var hsc := (hscale_by_stage.get(stage, 1.0) as float) * base_height
	return { "uv_rect": uv, "y_offset": yoff, "height_scale": hsc }
