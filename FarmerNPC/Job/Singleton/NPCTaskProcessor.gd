extends Node
## singleton, NPC system function database, NPCTaskProcessor



var _task_runners:Dictionary[JobTask.Type,Callable]= {
	JobTask.Type.MoveTo: _execute_move_to,
	JobTask.Type.Validate: _execute_validate,
	JobTask.Type.UseItem: _execute_use_item,
	JobTask.Type.EquipTool: _execute_equip_tool,
	JobTask.Type.Interact: _execute_interact,
}
## _execute_[taskname] template


func execute_task(task: JobTask, agent: WorkerAgent, job: JobInstance) -> void:
	var function: Callable = _task_runners.get(task.type, Callable())
	if function.is_valid():
		function.call(task, agent, job)

func _complete(job_id:int, agent_id:int, ok:bool=true)->void:
	NPCEventSystem.job_task_completed.emit(job_id, agent_id, ok)

#region Executer Logics
func _execute_move_to(_task: JobTask_MoveTo, agent: WorkerAgent, job: JobInstance)->void:
	# agent's _physics_process will handle the rest and report completion.
	var target_pos = job.target_pos
	agent.move_to(target_pos)
	# _complete is handled by agent

func _execute_validate(task: JobTask_Validate, agent: WorkerAgent, job: JobInstance) -> void:
	var target_node := get_node_or_null(job.target_path)
	var validation_method: StringName = task.validation_method

	if is_instance_valid(target_node) and target_node.has_method(validation_method):
		var is_valid: bool = target_node.call(validation_method)
		_complete(job.unique_id, agent.worker_id, is_valid)
	else:
		_complete(job.unique_id, agent.worker_id, false)

func _execute_use_item(task: JobTask_UseItem, agent: WorkerAgent, job: JobInstance) -> void:
	if &"" == job.payload.get(&"consume_item",&""):
		push_error("This Job is should not include Task: UseItem")
		return
	var item_id_to_use: StringName = job.payload.get(&"item_to_consume")
	
	var was_successful: bool = agent.inventory.remove_item(item_id_to_use, job.payload.get(&"amount"))

	if was_successful and task.animation_to_play:
		agent.play_action_animation(task.animation_to_play)
	_complete(job.unique_id, agent.worker_id, was_successful)

func _execute_equip_tool(task: JobTask_EquipTool, agent: WorkerAgent, job: JobInstance) -> void:
	if agent.inventory.has_item(task.tool_id):
		agent.active_tool_id = task.tool_id

		if task.animation_to_play:
			agent.play_action_animation(task.animation_to_play)

		# agent has the tool.
		_complete(job.unique_id, agent.worker_id, true)
	else:
		# Agent lacks the required tool, the task fails.
		_complete(job.unique_id, agent.worker_id, false)

func _execute_interact(task: JobTask_Interact, agent: WorkerAgent, job: JobInstance) -> void:
	var target_node := get_node_or_null(job.target_path)
	var method_to_call: StringName = task.method_to_call

	if is_instance_valid(target_node) and target_node.has_method(method_to_call):
		if task.animation_to_play:
			agent.play_action_animation(task.animation_to_play)

		var success: bool
		if task.pass_agent_inventory:
			# Call the method and pass the agent's inventory as an argument
			success = target_node.call(method_to_call, agent.inventory)
		else:
			target_node.call(method_to_call)
			success = true # Assume success if no return value is expected

		_complete(job.unique_id, agent.worker_id, success)
	else:
		_complete(job.unique_id, agent.worker_id, false)

#endregion
