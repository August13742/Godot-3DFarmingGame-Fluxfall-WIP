extends IJobTask
class_name PlantTask

func can_execute(worker: WorkerAgent, job: FarmJob) -> bool:
	var bed := worker.get_node_or_null(job.bed) as CropBed
	if not bed or not (bed.machine.current_state is CropEmptyState):
		return false

	if not worker.inventory:
		return false
	
	var available_seed = worker.inventory.get_first_item_with_capability(SeedCapability)
	
	## --- CRITICAL DEBUG BLOCK ---
	#print("--- [PlantTask VALIDATION] ---")
	#print("Worker '%s' is checking for seeds." % worker.name)
	#print("Result of inventory.get_first_item_with_capability: ", available_seed)
	#print("can_execute will return: ", available_seed != null)
	#print("--------------------------")
	## --- END DEBUG BLOCK ---
	
	return available_seed != null

func execute(worker: WorkerAgent, job: FarmJob) -> bool:
	var bed := worker.get_node_or_null(job.bed) as CropBed
	if not bed: return false

	# Find the specific seed to plant (this logic is now duplicated from the check, which is fine).
	var seed_to_plant: ItemInstance = worker.inventory.get_first_item_with_capability(SeedCapability)
	if not seed_to_plant:
		return false # Failsafe in case inventory changed while walking.

	worker.use_item(seed_to_plant.id)
	bed.start_interaction(worker)
	return true
