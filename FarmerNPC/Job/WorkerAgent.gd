class_name WorkerAgent extends CharacterBody3D


@onready var visuals: Node3D = $Visuals
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $AnimationTree
@export var speed := 3.5
@export var rotation_speed := 5.0
@export var worker_id := get_instance_id()
@export var max_stuck_time_tolerance:float = 2.0

var animation_state_machine: AnimationNodeStateMachinePlayback

enum State{ Idle,Executing }
var _current_job: JobInstance
var _state := State.Idle
var is_moving := false
var _stuck_time := 0.0
var _last_pos := Vector3.ZERO

var inventory: InventoryComponent
var active_tool_id:StringName = &"empty"

var skills: Dictionary[StringName,int] = { &"farming": 1} ## placeholder skills
var move_eps :float = max(0.01, speed * 0.05) # 5% of 1s travel
func _ready() -> void:
	animation_state_machine = animation_tree.get("parameters/StateMachine/playback")
	nav.velocity_computed.connect(_on_velocity_computed)

	# enable RVO
	nav.avoidance_enabled = true
	nav.radius = 0.35
	nav.path_desired_distance = 0.35
	nav.target_desired_distance = 0.60
	nav.neighbor_distance = 2.0
	nav.max_neighbors = 8
	nav.time_horizon = 1.2
	nav.avoidance_priority = 0.5

	inventory = InventoryManager.get_inventory(self)
	NPCJobBoard.register_idle_agent(self)
	NPCEventSystem.job_assigned.connect(_on_job_assigned)
	NPCEventSystem.job_finished.connect(_on_job_finished)
	NPCEventSystem.job_task_completed.connect(_on_task_completed)
	_add_debug_items.call_deferred()


func _add_debug_items()->void:
	inventory.add_item(&"tomato_seed",99)
	inventory.add_item(&"watering_can",1)
	inventory.add_item(&"wheat_seed",99)
	
func move_to(target_position: Vector3) -> void:
	var map_rid = get_world_3d().navigation_map
	var safe_target = NavigationServer3D.map_get_closest_point(map_rid, target_position)

	nav.set_target_position(safe_target)
	is_moving = true

	_stuck_time = 0
	_last_pos = global_position

	if animation_state_machine:
		animation_state_machine.travel("Move")

func _physics_process(delta: float) -> void:
	if !is_moving:
		nav.set_velocity(Vector3.ZERO)
		return

	# stuck detection
	if global_position.distance_to(_last_pos) < move_eps: _stuck_time += delta
	else: _stuck_time = 0

	_last_pos = global_position

	if _stuck_time > max_stuck_time_tolerance:
		# task failed
		is_moving = false
		nav.set_velocity(Vector3.ZERO)
		_on_task_completed(_current_job.unique_id, self.worker_id,false)
		return

	if nav.is_navigation_finished():
		is_moving = false
		velocity = Vector3.ZERO
		move_and_slide()

		if animation_state_machine:
			animation_state_machine.travel("Idle")

		_on_task_completed(_current_job.unique_id, self.worker_id, true)
		return

	var next_pos := nav.get_next_path_position()
	var direction:= (next_pos - global_position).normalized()
	var desired_velocity := direction * speed
	nav.set_velocity(desired_velocity)

	# rotate to look at where direction.
	if direction.length_squared() > 0.001:
		var target_angle = atan2(-direction.x, -direction.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, delta * rotation_speed)


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting(
			"physics/3d/default_gravity") * get_physics_process_delta_time()
	move_and_slide()

func _on_job_assigned(job:JobInstance,agent_id) -> void:
	if agent_id != self.worker_id: return
	_current_job = job
	_state = State.Executing
	_execute_current_task()

func _on_job_finished(job_id:int,_success:bool)->void:
	if _current_job && _current_job.unique_id == job_id:
		_current_job = null
		_state = State.Idle
		NPCJobBoard.register_idle_agent(self)

func _execute_current_task()->void:
	var task_data:JobTask = _current_job.template.task_list[_current_job.current_task_index]
	NPCTaskProcessor.execute_task(task_data, self, _current_job)


func _on_task_completed(job_id:int, agent_id:int, ok:bool) -> void:
	if not _current_job or agent_id != worker_id or job_id != _current_job.unique_id: return
	if not ok:
		NPCJobBoard.finish_job(job_id, false)
		return
	_current_job.current_task_index += 1
	if _current_job.current_task_index >= _current_job.template.task_list.size():
		NPCJobBoard.finish_job(job_id, true)
	else:
		_execute_current_task()
