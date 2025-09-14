class_name JobData extends Resource



@export var priority: int = 0
@export var required_skills: Dictionary[StringName, int]

@export var item_requirements: Array[ItemRequirement]

@export var task_list: Array[JobTask]
