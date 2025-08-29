extends Node
class_name FarmSensor



func _ready():
	EventSystem.GAME_NEW_DAY.connect(_scan_and_post)
	EventSystem.CROP_growth_tick_emitted.connect(_scan_and_post)
	_scan_and_post() # Initial scan on ready

func _scan_and_post():
	#print("--- FarmSensor: Starting new job scan. ---") # DEBUG
	for bed in get_tree().get_nodes_in_group("crop_beds"):
		if not (bed is CropBed): continue

		# PLANT
		if bed.machine.current_state is CropEmptyState:
			_post_once(FarmJob.Type.PLANT, bed)
		# HARVEST
		if bed.machine.current_state is CropHarvestableState:
			_post_once(FarmJob.Type.HARVEST, bed)

		# WATER
		if not bed.hydrated and not bed.always_hydrated:
			_post_once(FarmJob.Type.WATER, bed)

func _post_once(t: FarmJob.Type, bed: CropBed, payload := {}):
	var job := FarmJob.new()
	job.type = t
	job.bed = bed.get_path()
	job.target_pos = bed.global_transform.origin

	match t:
		FarmJob.Type.HARVEST: job.priority = 100
		FarmJob.Type.PLANT:   job.priority = 80
		FarmJob.Type.WATER:   job.priority = 50
	job.payload = payload
	JobBoard.post(job)
