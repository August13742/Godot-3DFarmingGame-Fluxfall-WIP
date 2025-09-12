class_name WorkerAgent extends CharacterBody3D


@onready var visuals: Node3D = $Visuals
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var animation_tree: AnimationTree = $AnimationTree
@export var speed := 3.5
@export var rotation_speed := 5.0
@export var worker_id := randi()

enum State{ Idle,Executing }
var _current_job: JobInstance

var _state := State.Idle

func _ready() -> void:
	NPCJobBoard.register_idle_agent(self)
	NPCEventSystem.job_assigned.connect(_on_job_assigned)
	NPCEventSystem.job_finished.connect(_on_job_finished)


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
	var task_data:Dictionary = _current_job.template.task_list[_current_job.current_task_index]
	NPCTaskProcessor.execute_task(task_data, self, _current_job)
	

func _on_task_completed(job_id:int, agent_id:int, ok:bool) -> void:
	if not _current_job or agent_id != worker_id or job_id != _current_job.unique_id: return
	if not ok:
		NPCJobBoard.fail_job(job_id, "task_failed")
		return
	_current_job.current_task_index += 1
	if _current_job.current_task_index >= _current_job.template.task_list.size():
		NPCJobBoard.finish_job(job_id, true)
	else:
		_execute_current_task()
