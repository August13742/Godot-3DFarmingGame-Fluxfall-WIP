class_name BulletinConfig

## usually this is called "billboard" but since that's a property in Control Nodes, using Bulletin Instead
enum Keys {
	InteractionPrompt,
}

const BULLETIN_PATHS:= {
	Keys.InteractionPrompt:"uid://dvivjx2b5ig3l" # interaction_prompt.tscn
}

static func get_bulletin(key:Keys)->Bulletin:
	return load(BULLETIN_PATHS.get(key)).instantiate()
