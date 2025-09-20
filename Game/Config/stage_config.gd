class_name StageConfig

enum Keys {
	Island,
	Test,
}

const STAGE_PATH:= {
	Keys.Island:"uid://37ea3gb4pcdi",
	Keys.Test:"res://Stages/props_display_clean.tscn"
}

static func get_stage(key:Keys)->Node:
	return load(STAGE_PATH.get(key)).instantiate()
