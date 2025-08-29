extends Node
## singleton
signal job_posted(job: FarmJob)
signal job_completed(job: FarmJob, success: bool)

var _jobs: Array[FarmJob] = []
var _reservations := {}   # NodePath -> worker_id

func post(job: FarmJob) -> void:
	if typeof(job.type) != TYPE_INT:
		push_error("JobBoard.post: job.type not set"); return
	# de-dupe: one job per bed+type
	for j in _jobs:
		if j.type == job.type and j.bed == job.bed:
			return
	_jobs.append(job)
	_jobs.sort_custom(func(a,b): return a.priority > b.priority)
	job_posted.emit(job)

func try_reserve_best(worker_id: int, worker_pos: Vector3) -> FarmJob:
	var best_job: FarmJob = null
	var best_score_sq := -1.0

	for j in _jobs:
		if not j.is_reserved():
			# No get_node() needed! Just use the cached position.
			var distance_sq = worker_pos.distance_squared_to(j.target_pos)
			if distance_sq < 0.01: distance_sq = 0.01
			
			var score_sq = (j.priority * j.priority) / distance_sq
			if score_sq > best_score_sq:
				best_score_sq = score_sq
				best_job = j
	
	if best_job:
		best_job.reserved_by = worker_id
		_reservations[best_job.bed] = worker_id
		return best_job

	# If no job was found, return null.
	return null

			

func release(job: FarmJob) -> void:
	if not job: return
	job.reserved_by = -1
	if _reservations.get(job.bed, -1) == -1: return
	_reservations.erase(job.bed)

func complete(job: FarmJob, success: bool) -> void:
	release(job)
	_jobs.erase(job)
	job_completed.emit(job, success)

func _is_bed_reserved(bed_path: NodePath) -> bool:
	return _reservations.has(bed_path)
