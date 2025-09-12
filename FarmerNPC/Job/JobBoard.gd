extends Node
## Singleton


var _job_templates: Dictionary[String,JobData] = {} ## lazy caches jobs to avoid constant disk lookup
var _pending_jobs:Array[JobInstance] = []
var _active_jobs:Dictionary[int,JobInstance] = {} # uid:JInst
var _idle_agents:Dictionary[int,WorkerAgent] = {} #workerID:reference
var _locks: Dictionary = {}                        # lock_key:String -> job_id:int

var _next_job_id: int = 0 # jobInstance UID counter, practically impossible to overflow
var internal_timer:float = 0
func _ready() -> void:
	NPCEventSystem.job_opportunity_created.connect(_on_job_opportunity_created)
	

func register_idle_agent(agent:WorkerAgent):
	_idle_agents[agent.worker_id] = agent
	_try_to_assign_jobs()

	
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
	var tpl := _load_template_and_cache(params["template_path"])
	var job := JobInstance.new()
	job.unique_id = _generate_new_uid()
	job.template = tpl
	job.priority = tpl.priority
	job.target_path = params["target_path"]
	job.target_pos = params.get("target_pos", Vector3.ZERO)
	job.payload = params.get("payload", {})
	job.lock_key = "%s|%s" % [tpl.resource_path, job.target_path]
	if _locks.has(job.lock_key): return
	if _has_duplicate_pending(job): return
	_pending_jobs.append(job)

func _assign_job_to_agent(job:JobInstance,agent:WorkerAgent)->void:
	if _locks.get(job.lock_key, -1) != job.unique_id:
		push_error("Activate without lock: %s" % job.lock_key)
		return
		
	job.assigned_agent_id = agent.worker_id
	job.status = JobInstance.Status.Active
	_pending_jobs.erase(job)
	_active_jobs[job.unique_id] = job
	_idle_agents.erase(agent.worker_id)
	
	NPCEventSystem.job_assigned.emit(job, agent.worker_id)
	
func _try_to_assign_jobs(limit:int = 99) -> void:
	if _pending_jobs.is_empty() or _idle_agents.is_empty(): return
	_pending_jobs.sort_custom(func(a,b): return a.priority > b.priority) # asc sort
	var picks := mini(limit, mini(_pending_jobs.size(), _idle_agents.size()))
	for i in picks:
		var job := _pending_jobs[0]
		var agent := _pick_any_idle_agent()  # placeholder
		if agent:
			_acquire_lock(job)
			_assign_job_to_agent(job, agent)

func _pick_any_idle_agent()->WorkerAgent:
	return _idle_agents.get((_idle_agents.keys()).pick_random())
	
func _find_best_agent_for_job(_job:JobInstance)->WorkerAgent:
	return _idle_agents.get((_idle_agents.keys())[0]) ## placeholder

func finish_job(job_id:int, success:bool):
	var job:JobInstance = _active_jobs.get(job_id)
	if job:
		job.status = JobInstance.Status.Complete if success else JobInstance.Status.Failed
		_active_jobs.erase(job_id)
		_release_lock(job)
		NPCEventSystem.job_finished.emit(job_id, success)
