extends Node
## Singleton NPCJobBoard


signal job_lists_changed

enum AgentStatus { Idle, Active, Unknown }

## periodically try to assign pending jobs
@export var job_assignment_attempt_interval:float = 5.0 
var _job_templates: Dictionary[String,JobData] = {} ## lazy caches jobs to avoid constant disk lookup

var _pending_jobs:Array[JobInstance] = []
var _active_jobs:Dictionary[int,JobInstance] = {}           # job_id -> JobInstance
var _idle_agents:Dictionary[int,WorkerAgent] = {}           # worker_id -> agent
var _all_agents:Dictionary[int,WorkerAgent] = {}            # worker_id -> agent
var _agent_jobs:Dictionary[int,int] = {}                    # worker_id -> job_id

var _locks: Dictionary = {}                        # lock_key:String -> job_id:int



var _next_job_id: int = 0 # jobInstance UID counter, practically impossible to overflow (int is 8 bit in gd)
var internal_timer:float = 0
func _ready() -> void:
	NPCEventSystem.job_opportunity_created.connect(_on_job_opportunity_created)

func _process(delta: float) -> void:
	internal_timer+=delta
	if internal_timer >= job_assignment_attempt_interval:
		internal_timer = 0
		_try_to_assign_jobs()
		
func register_idle_agent(agent: WorkerAgent) -> void:
	_all_agents[agent.worker_id] = agent
	_idle_agents[agent.worker_id] = agent
	_agent_jobs.erase(agent.worker_id)   # no longer on a job
	job_lists_changed.emit()
	call_deferred("_try_to_assign_jobs")

func unregister_agent(agent: WorkerAgent) -> void:
	_idle_agents.erase(agent.worker_id)
	_all_agents.erase(agent.worker_id)
	_agent_jobs.erase(agent.worker_id)
	job_lists_changed.emit()


## Checks if an agent meets a job's requirements.
## On success, returns a payload Dictionary with context (e.g., which item to use).
## On failure, returns empty.
func _check_agent_requirements(agent: WorkerAgent, template: JobData) -> Dictionary:
	var payload := {&"bindings": {}, &"preflight_passed": false}

	# --- Skill Check ---
	for skill_name in template.required_skills:
		if agent.skills.get(skill_name, 0) < template.required_skills[skill_name]:
			return {} # FAILED: Skill level too low.

	# --- Item Requirement Check ---
	var cap_script: Script
	var choice_id: StringName
	
	for req: ItemRequirement in template.item_requirements:
		var key: StringName = req.binding_key
		if key == &"":
			# No binding requested. Just gate-check.
			match req.type:
				ItemRequirement.Type.SPECIFIC_ITEM:
					if not agent.inventory.has_item(req.required_item_id(), req.amount):
						return {}
				ItemRequirement.Type.BY_CAPABILITY:
					cap_script = req.required_capability_script()
					if not cap_script: return {}
					var inst = agent.inventory.get_first_item_with_capability(cap_script)
					if not inst or inst.count < req.amount: return {}
			continue

		# Binding requested: choose concrete item id
		match req.type:
			ItemRequirement.Type.SPECIFIC_ITEM:
				choice_id = req.required_item_id()
				if not agent.inventory.has_item(choice_id, req.amount):
					return {}
			ItemRequirement.Type.BY_CAPABILITY:
				cap_script = req.required_capability_script()
				if not cap_script: return {}
				var inst = agent.inventory.get_first_item_with_capability(cap_script)
				if not inst or inst.count < req.amount:
					return {}
				choice_id = inst.id

		payload.bindings[key] = {
			&"item_id": choice_id,
			&"amount": req.amount,
			&"consumed": req.is_consumed,
			&"capability_script": cap_script
		}

	payload.preflight_passed = true
	return payload # SUCCESS: All requirements met.
""" return example
{
  "seed": { item_id="tomato_seed", amount=1, consumed=true, capability_script=SeedCapability },
  "water": { item_id="watering_can", amount=1, consumed=false, capability_script=WateringCapability }
}
"""


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
	
	job_lists_changed.emit()

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
	_agent_jobs[agent.worker_id] = job.unique_id

	NPCEventSystem.job_assigned.emit(job, agent.worker_id)
	job_lists_changed.emit()

func _try_to_assign_jobs() -> void:
	if _pending_jobs.is_empty() or _idle_agents.is_empty(): return
	_pending_jobs.sort_custom(func(a,b): return a.priority > b.priority) # dsc sort

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
		_agent_jobs.erase(job.assigned_agent_id)
		
		NPCEventSystem.job_finished.emit(job_id, success)
		job_lists_changed.emit()
		
#region Query API
func get_pending_jobs() -> Array[JobInstance]: return _pending_jobs
func get_active_jobs()  -> Array[JobInstance]: return _active_jobs.values()
func get_idle_agents()  -> Array[WorkerAgent]: return _idle_agents.values()
func get_all_agents()   -> Array[WorkerAgent]: return _all_agents.values()

# Always return from _all_agents. You were returning only idle agents before.
func get_agent(worker_id:int) -> WorkerAgent:
	return _all_agents.get(worker_id, null)

func get_agent_status(worker_id:int) -> int:
	if _idle_agents.has(worker_id): return AgentStatus.Idle
	if _agent_jobs.has(worker_id):  return AgentStatus.Active
	return AgentStatus.Unknown

func get_agent_job(worker_id:int) -> int:
	return _agent_jobs.get(worker_id, -1)

#endregion

#region Debug Helpers
func debug_requeue(job_id:int) -> bool:
	var j: JobInstance = _active_jobs.get(job_id)
	if j == null: return false
	_release_lock(j)
	j.status = JobInstance.Status.Pending
	j.assigned_agent_id = -1
	j.current_task_index = 0
	_pending_jobs.append(j)
	_active_jobs.erase(job_id)
	job_lists_changed.emit()
	return true

func debug_cancel(job_id:int) -> bool:
	# Try active
	var j: JobInstance = _active_jobs.get(job_id)
	if j:
		_active_jobs.erase(job_id)
		_release_lock(j)
		job_lists_changed.emit()
		return true
	# Try pending
	for i in _pending_jobs.size():
		if _pending_jobs[i].unique_id == job_id:
			_release_lock(_pending_jobs[i])
			_pending_jobs.remove_at(i)
			job_lists_changed.emit()
			return true
	return false

#endregion
