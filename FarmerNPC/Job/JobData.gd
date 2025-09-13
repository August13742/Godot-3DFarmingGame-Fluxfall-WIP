class_name JobData extends Resource



@export var priority:int = 0
@export var required_skills:Dictionary[StringName,int] # skill name, skill level

## The sequence of steps to complete the job. Each Dictionary is a single task, defined by its type and params
@export var task_list: Array[JobTask]
# [{ "type": JobData.Task.MoveTo, "params": {"target_key": "job_target", "stop_radius": 0.6} }]
