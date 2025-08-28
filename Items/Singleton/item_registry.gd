extends Node
## Singleton 
@onready var catalogue: ItemCatalogue = preload("uid://racjysve07av")

var by_id := {}
# Add other indexed dictionaries here (by_tag, etc.) as needed

func _ready():
	_build()

func _build():
	if not catalogue:
		push_error("ItemRegistry: Catalog not assigned!")
		return

	for item in catalogue.items:
		if item == null:
			push_warning("Found a null item in the catalog.")
			continue
		if item.id == StringName(""):
			push_error("Item missing ID at path: %s" % item.resource_path)
			continue
		if by_id.has(item.id):
			push_error("Duplicate item ID found: %s" % item.id)
			continue

		by_id[item.id] = item

func get_by_id(id: StringName) -> ItemResource:
	return by_id.get(id, null)
