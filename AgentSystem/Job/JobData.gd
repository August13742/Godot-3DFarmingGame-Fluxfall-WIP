class_name JobData extends Resource



@export var priority: int = 0
@export var is_persistent: bool = false # Set to true for jobs that must not be dropped.

@export var skill_requirements: Dictionary[StringName, int]

@export var item_requirements: Array[ItemRequirement]
@export var task_list: Array[JobTask]
