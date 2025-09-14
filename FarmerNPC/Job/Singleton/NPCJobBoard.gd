extends Node
## Singleton NPCJobBoard

## periodically try to assign pending jobs
@export var job_assignment_attempt_interval:float = 5.0 
var _job_templates: Dictionary[String,JobData] = {} ## lazy caches jobs to avoid constant disk lookup
var _pending_jobs:Array[JobInstance] = []
var _active_jobs:Dictionary[int,JobInstance] = {} # uid:JInst
var _idle_agents:Dictionary[int,WorkerAgent] = {} #workerID:reference
var _locks: Dictionary = {}                        # lock_key:String -> job_id:int

var _next_job_id: int = 0 # jobInstance UID counter, practically impossible to overflow
var internal_timer:float = 0
func _ready() -> void:
	NPCEventSystem.job_opportunity_created.connect(_on_job_opportunity_created)

func _process(delta: float) -> void:
	internal_timer+=delta
	if internal_timer >= job_assignment_attempt_interval:
		internal_timer = 0
		_try_to_assign_jobs()
		
func register_idle_agent(agent:WorkerAgent):
	_idle_agents[agent.worker_id] = agent
	_try_to_assign_jobs()

## Checks if an agent meets a job's requirements.
## On success, returns a payload Dictionary with context (e.g., which item to use).
## On failure, returns empty.
func _check_agent_requirements(agent: WorkerAgent, template: JobData) -> Dictionary:
	var payload := {} # This will store the context for the JobInstance

	# --- Skill Check ---
	for skill_name in template.required_skills:
		var required_level = template.required_skills[skill_name]
		var agent_level = agent.skills.get(skill_name, 0)
		if agent_level < required_level:
			return {} # FAILED: Skill level too low.

	# --- Item Requirement Check ---
	for req in template.item_requirements:
		var item_id_to_use: StringName
		
		match req.type:
			ItemRequirement.Type.SPECIFIC_ITEM:
				var requested_item_id:StringName = req.required_item_id()
				if not agent.inventory.has_item(requested_item_id, req.amount):
					return {} # FAILED: Lacks specific item.
				item_id_to_use = requested_item_id

			ItemRequirement.Type.BY_CAPABILITY:
				var cap_script = req.required_capability_script()
				if not cap_script:
					return {} # FAILED: Invalid capability name.
				
				var item_instance = agent.inventory.get_first_item_with_capability(cap_script)
				if not item_instance or item_instance.count < req.amount:
					return {} # FAILED: Lacks an item with this capability.
				
				item_id_to_use = item_instance.id
		
		# SUCCESS: If this item is a consumable, add it to the payload
		# so the UseItem task knows which concrete item to remove.
		if req.is_consumed:
			# We create a payload key based on the requirement's capability or item ID.
			payload[&"consume_item"] = true
			payload[&"item_to_consume"] = item_id_to_use
			payload[&"amount"] = req.amount
	payload[&"preflight_passed"] = true
	return payload # SUCCESS: All requirements met.
	


func _generate_new_uid() -> int:
	var id = _next_job_id
	_next_job_id += 1
	return id

func _load_template_and_cache(template_path:String)->JobData:
	if _job_templates.has(template_path): return _job_templates.get(template_path)
	_job_templates[template_path] = load(template_path)
	return _job_templates[template_path]

func _has_duplicate_pending(j: JobInstance) -> bool:
	var key := j.lock_key
	for p in _pending_jobs:
		if p.lock_key == key:
			# Optional merge:
			p.priority = max(p.priority, j.priority)
			p.target_pos = j.target_pos
			p.payload.merge(j.payload, true)
			return true
	return false

func _acquire_lock(job: JobInstance) -> bool:
	if _locks.has(job.lock_key):
		return false
	_locks[job.lock_key] = job.unique_id
	return true

func _release_lock(job: JobInstance) -> void:
	_locks.erase(job.lock_key)

func _on_job_opportunity_created(params: Dictionary) -> void:
	var template := _load_template_and_cache(params["template_path"])
	var job := JobInstance.new()
	job.unique_id = _generate_new_uid()
	job.template = template
	job.priority = template.priority
	job.target_path = params["target_path"]
	job.target_pos = params.get("target_pos", Vector3.ZERO)
	job.payload = params.get("payload", {})
	job.lock_key = "%s|%s" % [template.resource_path, job.target_path]
	if _locks.has(job.lock_key): return
	if _has_duplicate_pending(job): return
	_pending_jobs.append(job)

func _assign_job_to_agent(job:JobInstance,agent:WorkerAgent, payload:Dictionary)->void:
	if _locks.get(job.lock_key, -1) != job.unique_id:
		push_error("Activate without lock: %s" % job.lock_key)
		return

	job.assigned_agent_id = agent.worker_id
	job.status = JobInstance.Status.Active
	job.payload = payload
	
	_pending_jobs.erase(job)
	_active_jobs[job.unique_id] = job
	_idle_agents.erase(agent.worker_id)

	NPCEventSystem.job_assigned.emit(job, agent.worker_id)

func _try_to_assign_jobs() -> void:
	if _pending_jobs.is_empty() or _idle_agents.is_empty(): return
	_pending_jobs.sort_custom(func(a,b): return a.priority > b.priority) # asc sort

	var jobs_to_remove = []
	for job in _pending_jobs:
		if _idle_agents.is_empty():break

		var result = _find_best_agent_for_job(job)
		var agent: WorkerAgent = result.agent
		var payload: Dictionary = result.payload
		
		if agent:
			_acquire_lock(job)
			_assign_job_to_agent(job,agent, payload)
			jobs_to_remove.append(job)

	for job in jobs_to_remove: # less array restructuring
		_pending_jobs.erase(job)

func _pick_any_idle_agent()->WorkerAgent:
	return _idle_agents.get((_idle_agents.keys()).pick_random())

func _find_best_agent_for_job(job:JobInstance)->Dictionary:
	var best_agent:WorkerAgent = null
	var best_payload: Dictionary = {}
	var best_score:float = -1.0

	for agent in _idle_agents.values():
		var requirement_payload:Dictionary = _check_agent_requirements(agent, job.template)
		if requirement_payload.is_empty(): 
			continue
		

		var distance_sq:float= agent.global_position.distance_squared_to(job.target_pos)
		if distance_sq < 0.01: distance_sq = 0.01 # avoid /0

		# urgent task prefers clostest agent. TODO: add more scoring
		var score = (job.priority ** 2) / distance_sq
		if score > best_score:
			best_score = score
			best_agent = agent
			best_payload = requirement_payload
	return { "agent": best_agent, "payload": best_payload }

func finish_job(job_id:int, success:bool):
	var job:JobInstance = _active_jobs.get(job_id)
	if job:
		job.status = JobInstance.Status.Complete if success else JobInstance.Status.Failed
		_active_jobs.erase(job_id)
		_release_lock(job)
		NPCEventSystem.job_finished.emit(job_id, success)
