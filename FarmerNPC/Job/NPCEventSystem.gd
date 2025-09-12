extends Node
## Singleton

signal job_opportunity_created(params: Dictionary)  # {template_path:String, target_path:NodePath, payload:Dictionary}
signal job_assigned(job: JobInstance, agent_id: int)
signal job_task_completed(job_instance_id: int, agent_id: int, success: bool)
signal job_finished(job_instance_id: int, success: bool)
signal job_released(job_instance_id: int, reason: StringName)
