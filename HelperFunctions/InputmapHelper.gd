extends Object ## aka no extend
class_name InputmapHelper

static func get_first_key_mapped_to_action_as_string(action_name: String) -> String:
	var normalized_name := action_name.to_lower()
	for name in InputMap.get_actions():
		if name.to_lower() == normalized_name:
			var events = InputMap.action_get_events(name)
			if events.size() > 0 and events[0] is InputEventKey:
				var key_event := events[0] as InputEventKey
				return OS.get_keycode_string(key_event.physical_keycode)
			break
	push_warning("%s Action Not Found" % action_name)
	return ""
