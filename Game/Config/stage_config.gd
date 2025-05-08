class_name StageConfig

enum Keys {
	Island,
}

const STAGE_PATH:= {
	Keys.Island:"uid://37ea3gb4pcdi",
}

static func get_stage(key:Keys)->Node:
	return load(STAGE_PATH.get(key)).instantiate()
