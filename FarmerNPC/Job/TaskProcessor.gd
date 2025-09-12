extends Node
## singleton, NPC system function database

signal task_completed


var _task_runners := {
	&"MoveTo": _execute_move_to,
	&"Validate": _execute_validate,
	&"UseItem": _execute_use_item,
	&"UseTool": _execute_use_tool,
	&"Interact": _execute_interact,
}
## _execute_[taskname] template

	
func execute_task(task: Dictionary, agent: WorkerAgent, job: JobInstance) -> void:
	var t: StringName = task.get("type")
	var fn: Callable = _task_runners.get(t, Callable())
	if fn.is_valid():
		fn.call(task.get("params", {}), agent, job)
		
func _complete(job_id:int, agent_id:int, ok:bool=true)->void:
	NPCEventSystem.job_task_completed.emit(job_id, agent_id, ok)
	
#region Executer Logics
func _execute_move_to()->void:
	pass
	
func _execute_validate()->void:
	pass
	
func _execute_use_item()->void:
	pass
	
func _execute_use_tool()->void:
	pass
	
func _execute_interact()->void:
	pass
	
#endregion
