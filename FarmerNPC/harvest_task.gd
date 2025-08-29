extends IJobTask
class_name HarvestTask

func can_execute(worker, job: FarmJob) -> bool:
	var bed := worker.get_node_or_null(job.bed) as CropBed
	return bed and (bed.machine.current_state is CropHarvestableState)

func execute(worker, job: FarmJob) -> bool:
	var bed := worker.get_node_or_null(job.bed) as CropBed
	if not bed: return false

	# Bare hands harvest; CropBed uses yield_id internally
	worker.clear_active_item()
	bed.start_interaction(worker)
	return true
