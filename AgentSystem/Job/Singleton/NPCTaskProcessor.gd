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
	## Self-use only; job.payload must include concrete item
	## WARNING currently no job should use this, not before item handler implementation
	var item_id: StringName = job.payload.get(&"item_to_consume", &"")
	var amount := int(job.payload.get(&"amount", 1))
	
	if item_id == &"" or amount <= 0:
		_complete(job.unique_id, agent.worker_id, false); return

	if not agent.inventory.has_item(item_id, amount):
		_complete(job.unique_id, agent.worker_id, false); return

	var ok := agent.inventory.remove_item(item_id, amount)
	if ok and task.animation_to_play:
		agent.play_action_animation(task.animation_to_play)

	_complete(job.unique_id, agent.worker_id, ok)

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
	var target := get_node_or_null(job.target_path)
	if not is_instance_valid(target) or not target.has_method(task.method_to_call):
		_complete(job.unique_id, agent.worker_id, false)
		printerr("Tried to execute Interact but Target Or Method to Call not Valid")
		return
		
	if task.animation_to_play: 
		agent.play_action_animation(task.animation_to_play)
		
	# build context
	var context:ActionContext = ActionContext.new()
	context.agent = agent
	context.inventory = agent.inventory if task.pass_agent_inventory else null
	context.job = job
	
	# if action needs bound item, resolve then sanity check
	if task.required_binding != &"":
		var bind:Dictionary = job.payload.get(&"bindings",{}).get(task.required_binding,{})
		if bind.is_empty():
			_complete(job.unique_id,agent.worker_id,false); return
			
		context.binding_key = task.required_binding
		context.item_id = bind.get(&"item_id",&"")
		context.amount = int(bind.get(&"amount",1))
		context.capability_script = bind.get(&"capability_script")
		context.item_template = ItemDatabase.get_item_by_id(context.item_id)
		
		# verify item still exist (in case item lost during previous tasks)
		## TODO? if cap requirement, scan for alternative item
		if not agent.inventory.has_item(context.item_id,max(context.amount,1)):
			_complete(job.unique_id,agent.worker_id, false); return
			
	# call target and normalise return
	var result:ActionResult = ActionResult.from_variant(target.call(task.method_to_call, context))
	var ok:bool = result.ok
	
	# if success, consume item
	if ok and not result.consume.is_empty():
		var consume_id:StringName = result.consume.get(&"item_id",&"")
		var consume_amount:int = int(result.consume.get(&"amount",1))
		if consume_id != &"" and consume_amount >0:
			ok = agent.inventory.remove_item(consume_id,consume_amount)
		
	# fallback:req said consumable but target didn't specify consume
	if ok and task.required_binding != &"" and result.consume.is_empty():
		var fallback:Dictionary = job.payload.get(&"bindings",{}).get(task.required_binding,{})
		if fallback.get(&"consumed",false):
			ok = agent.inventory.remove_item(context.item_id,max(context.amount,1))
	
	_complete(job.unique_id,agent.worker_id,ok)


#endregion
