extends Bulletin

var prompt_text:String = ""

func initialise(prompt) -> void:
	if prompt is String:
		prompt_text = prompt



func _ready():
	$Label.text = "[" + InputmapHelper.get_first_key_mapped_to_action_as_string("interact") + "] " + prompt_text
