class_name ActionResult extends RefCounted

var ok:bool = false
var consume: Dictionary = {} # { item_id: StringName, amount: int }, optional


static func from_variant(v) -> ActionResult:
	if v is ActionResult:
		return v
	var r := ActionResult.new()
	r.ok = bool(v)
	return r
