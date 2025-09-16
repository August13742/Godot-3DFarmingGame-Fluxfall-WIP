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

## &"consume_item", &"item_to_consume", &"amount", &"preflight_passed"
var payload: Dictionary = {}

var runtime_targets:Dictionary[StringName,Node] # e.g., {&"job_target": CropBed3}
var assigned_agent_id:int = -1
var current_task_index:int = 0
var status: Status = Status.Pending

var max_retries: int = 3
var retry_count: int = 0

#region Debug UI Helpers
func binding_summary() -> String:
	var parts: Array[String] = []
	var bindings: Dictionary = payload.get("bindings", {})
	for k in bindings.keys():
		var b: Dictionary = bindings[k]
		var s := "%s:%s×%d%s" % [
			String(k),
			String(b.get(&"item_id", &"")),
			int(b.get(&"amount", 1)),
			"(cons)" if b.get(&"consumed", false) else ""
		]
		parts.append(s)
	return ", ".join(parts)

func template_name() -> String:
	return template.resource_path.get_file() if template and template.resource_path else "<none>"

#endregion
