extends Node
## Singleton NPCEventSystem

# ignore IDE warning. Intended.
## emitted by JobEmitterComponent, to NPCJobBoard
@warning_ignore("unused_signal")
signal job_opportunity_created(params: Dictionary)  # {template_path:String, target_path:NodePath, payload:Dictionary}

## emitted by NPCJobBoard, to all WorkerAgent
@warning_ignore("unused_signal")
signal job_assigned(job: JobInstance, agent_id: int)

## emitted by NPCTaskProcessor to the WorkerAgent
@warning_ignore("unused_signal")
signal job_task_completed(job_instance_id: int, agent_id: int, success: bool)

## emitted by NPCJobBoard, to WorkerAgent that did the job
@warning_ignore("unused_signal")
signal job_finished(job_instance_id: int, success: bool)
