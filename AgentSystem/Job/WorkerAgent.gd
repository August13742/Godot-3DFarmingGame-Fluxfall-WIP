class_name WorkerAgent extends CharacterBody3D


@onready var visuals: Node3D = $Visuals
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine: WorkerAgentStateMachine = $WorkerAgentStateMachine

@export var speed := 3.5
@export var rotation_speed := 5.0
@export var worker_id := get_instance_id()
@export var max_stuck_time_tolerance:float = 10.0


var _current_job: JobInstance
var is_moving := false
var move_eps :float = max(0.01, speed * 0.1) # 10% of 1s travel

var inventory: InventoryComponent
var active_tool_id:StringName = &"empty"

var skills: Dictionary[StringName,int] = { &"farming": 1} ## placeholder skills

func _ready() -> void:
	nav.velocity_computed.connect(_on_velocity_computed)

	# enable RVO
	nav.avoidance_enabled = true
	nav.radius = 0.35
	nav.path_desired_distance = 0.35
	nav.target_desired_distance = 0.60
	nav.neighbor_distance = 3.0
	nav.max_neighbors = 8
	nav.time_horizon = 1.0
	nav.avoidance_priority = randf_range(0.4, 0.6)

	inventory = InventoryManager.get_inventory(self)
	_add_debug_items()
	
	await get_tree().process_frame
	NPCJobBoard.register_idle_agent(self)
	NPCEventSystem.job_assigned.connect(_on_job_assigned)


func _add_debug_items()->void:
	inventory.add_item(&"tomato_seed",99)
	inventory.add_item(&"watering_can",1)
	inventory.add_item(&"wheat_seed",99)
	

# for RVO avoidance
func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if not is_moving:
		velocity = Vector3.ZERO
	else:
		velocity.x = safe_velocity.x
		velocity.z = safe_velocity.z
	
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * get_physics_process_delta_time()
	move_and_slide()

func _on_job_assigned(job: JobInstance, agent_id: int) -> void:
	if agent_id != self.worker_id: return
	_current_job = job
	_execute_current_task()

func _on_job_finished(job_id: int, _success: bool) -> void:
	if _current_job and _current_job.unique_id == job_id:
		_current_job = null
		state_machine.change_state(WorkerAgentStateMachine.StateKey.Idle)


func _execute_current_task() -> void:
	var task_data: JobTask = _current_job.template.task_list[_current_job.current_task_index]
	
	# Example of dispatching tasks to states
	match task_data.type:
		JobTask.Type.MoveTo:
			var payload: Dictionary = {"target": task_data.target_position}
			state_machine.change_state(WorkerAgentStateMachine.StateKey.Moving, payload)
		JobTask.Type.Animate:
			var payload: Dictionary = {
				"animation_name": task_data.animation_name,
				"duration": task_data.duration
			}
			state_machine.change_state(WorkerAgentStateMachine.StateKey.PerformingTask, payload)
		_:
			push_warning("Unhandled task type: %s" % task_data.type)
			_on_task_completed(_current_job.unique_id, worker_id, false)
			

func _on_task_completed(job_id: int, agent_id: int, ok: bool) -> void:
	if not _current_job or agent_id != worker_id or job_id != _current_job.unique_id: return
	
	if not ok:
		NPCJobBoard.finish_job(job_id, false)
		return
		
	_current_job.current_task_index += 1
	if _current_job.current_task_index >= _current_job.template.task_list.size():
		NPCJobBoard.finish_job(job_id, true)
	else:
		_execute_current_task()
