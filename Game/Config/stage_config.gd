class_name StageConfig

enum Keys {
	Island,
	Test,
}

const STAGE_PATH:= {
	Keys.Island:"uid://37ea3gb4pcdi",
	Keys.Test:"uid://dptyxxs3uol81"
}

static func get_stage(key:Keys)->Node:
	return load(STAGE_PATH.get(key)).instantiate()
