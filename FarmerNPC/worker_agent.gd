extends CharacterBody3D
class_name WorkerAgent

@onready var visuals: Node3D = $Visuals
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $AnimationTree
@export var speed := 3.5
@export var rotation_speed := 5.0
@export var worker_id := randi()

var current_job: FarmJob

var _state: StringName = &"idle"

# The public property that other parts of the script will use.
var state: StringName:
	get: return _state
	set(new_state):
		# Don't do anything if the state isn't actually changing.
		if _state == new_state:
			return

		# --- EXIT LOGIC (Optional) ---
		# match _state:
		#     &"move":
		#         print("Exiting move state.")

		_state = new_state

		# --- ENTER LOGIC ---
		_on_state_entered(_state)
var inventory: InventoryComponent
var active_item_id: StringName = &""
var is_ready := false
var animation_state_machine:AnimationNodeStateMachinePlayback
# task registry
var tasks: Dictionary = {
	FarmJob.Type.WATER: WaterTask.new(),
	FarmJob.Type.PLANT: PlantTask.new(),
	FarmJob.Type.HARVEST: HarvestTask.new()
}

func _ready():

	nav.radius = 0.35                       # ~= capsule radius; too small = corner bumper cars
	nav.path_desired_distance = 0.35        # skip to next corner sooner
	nav.target_desired_distance = 0.60      # stop before jamming into the bed edge

	# Local avoidance (RVO)
	nav.avoidance_enabled = true
	nav.neighbor_distance = 2.0             # who to consider
	nav.max_neighbors = 8
	nav.time_horizon = 1.2                  # anticipate near-future collisions
	nav.avoidance_priority = 0.5
	nav.velocity_computed.connect(_on_velocity_computed)
	inventory = InventoryManager.get_inventory(self)
	_add_debug_items()
	# Wait one frame before allowing the agent to start working.
	animation_state_machine = animation_tree.get("parameters/StateMachine/playback")

	call_deferred("_initialise_agent")

func _on_state_entered(new_state: StringName):
	if not animation_state_machine: return

	match new_state:
		&"idle", &"validate":
			animation_state_machine.travel("Idle")

		&"move":
			animation_state_machine.travel("Move")

		&"execute":
			# Example: Trigger a one-shot "Work" animation, but don't have it yet
			#animation_state_machine.travel("Work")
			pass
func _initialise_agent():
	is_ready = true

func _add_debug_items()->void:
	inventory.add_item(&"tomato_seed",99)
	inventory.add_item(&"watering_can",1)
	inventory.add_item(&"wheat_seed",99)

func _physics_process(delta):

	match state:
		&"idle":
			# Guard clause: Don't do anything until the agent is initialised.
			if not is_ready: return

			current_job = JobBoard.try_reserve_best(worker_id,global_position)
			if current_job:
				state = &"validate"

		&"validate":
			var task := _task()
			if task and task.can_execute(self, current_job):
				var bed := get_node_or_null(current_job.bed) as CropBed
				if bed:
					_set_nav_target(bed.global_transform.origin)
					state = &"move"
				else:
					print("[Worker %d] Validate: FAILED. can_execute() returned false." % worker_id)
					JobBoard.release(current_job)
					current_job = null
					state = &"idle"
			else:
				JobBoard.release(current_job)
				current_job = null
				state = &"idle"

		&"move":
			_move_step(delta)

		&"execute":
			var ok := _task().execute(self, current_job)
			JobBoard.complete(current_job, ok)
			current_job = null
			state = &"idle"

# --- Helper Functions ---
func get_active_item_id() -> StringName:
	return active_item_id

var _stuck_time:float = 0
var _last_progress:float = 0
func _move_step(delta):
	if nav.is_navigation_finished():
		state = &"execute"
		nav.set_velocity(Vector3.ZERO)
		return
	var next := nav.get_next_path_position()
	var dir := (next - global_transform.origin)
	dir.y = 0.0
	if visuals and dir.length() > 0.001:
		var target_angle = atan2(-dir.x, -dir.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, delta * rotation_speed)

	dir = dir.normalized()
	var desired := dir * speed
	nav.set_velocity(desired)  # avoidance will answer back in _on_velocity_computed
	var goal := nav.get_target_position()
	var d := global_transform.origin.distance_to(goal)
	if d > _last_progress - 0.02:  # no progress
		_stuck_time += delta
	else:
		_stuck_time = 0.0
	_last_progress = d

	if _stuck_time > 1.0:
		var jitter := Vector3(randf() - 0.5, 0, randf() - 0.5).normalized() * 0.4
		_set_nav_target(goal + jitter)
		_stuck_time = 0.0

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	# keep gravity
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	if not is_on_floor(): velocity.y -= 10.0 * get_physics_process_delta_time()
	else: velocity.y = 0.0
	move_and_slide()

func _set_nav_target(target_pos: Vector3):
	var map_rid = get_world_3d().get_navigation_map()
	var closest_point_on_mesh = NavigationServer3D.map_get_closest_point(map_rid, target_pos)
	nav.set_target_position(closest_point_on_mesh)

func _task() -> IJobTask:
	return tasks.get(current_job.type, null)

func use_tool(tool_id: StringName):
	self.active_item_id = tool_id

func use_item(item_id: StringName):
	self.active_item_id = item_id

func clear_active_item():
	self.active_item_id = &""
