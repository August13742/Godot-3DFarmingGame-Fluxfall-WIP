class_name JobInstance extends RefCounted

## implementing "remaining tasks" might be a bad idea
## for example, if a task requires walking to somewhere, then if we mark it as completed
## if it then gets dropped, the next agent would never know to move there again

enum Status{ Pending,Active,Complete,Failed }

var unique_id:int
var template: JobData # ref to blueprint
var priority:int = 0
var lock_key: String = ""                 # e.g., "%s|%s" % [template.resource_path, target_path]
var target_path: NodePath
var target_pos: Vector3
var payload: Dictionary = {}

var runtime_targets:Dictionary[StringName,Node] # e.g., {&"job_target": CropBed3}
var assigned_agent_id:int = -1
var current_task_index:int = 0
var status: Status = Status.Pending
