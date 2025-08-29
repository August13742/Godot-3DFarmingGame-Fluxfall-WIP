extends IJobTask
class_name WaterTask

func can_execute(worker, job: FarmJob) -> bool:
	var bed := worker.get_node_or_null(job.bed) as CropBed
	if not bed: return false
	return not bed.hydrated

func execute(worker, job: FarmJob) -> bool:
	var bed := worker.get_node_or_null(job.bed) as CropBed
	if not bed: return false
	# Use worker as source so crop bed reads active item/tool
	worker.use_tool(&"watering_can")  # sets active item id
	bed.start_interaction(worker)
	return true
