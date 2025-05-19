@tool
extends EditorScript


var header := "## AUTO-GENERATED FILE. DO NOT EDIT.\n"


var key_enum := "enum Keys {\n\tNULL,\n"
var path_dict := "const PATHS: Dictionary = {\n"
var enum_string_mapping := "const ITEM_IDS: Dictionary = {\n\tKeys.NULL: null,\n"

var craftable_map := "const CRAFTABLES: Dictionary = {\n"

var index := 1
var craftable_index := 0


func _run():
	header += "class_name ItemDB\n\n"


	process_dir("res://Items/Resources")
	key_enum += "}\n\n"
	enum_string_mapping += "}\n\n"
	path_dict += "}\n\n"
	craftable_map += "}\n\n"

	var full_output := header + key_enum + enum_string_mapping + path_dict + craftable_map

	var f := FileAccess.open("res://Items/DataBase/item_db.gd", FileAccess.WRITE)
	f.store_string(full_output)
	f.close()

	print_debug("✔ Generated %d item keys, %d craftables." % [index, craftable_index])


func process_dir(path: String):
	var dir := DirAccess.open(path)
	if not dir:
		push_error("Directory not found: %s" % path)
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		var full_path = path + "/" + file_name
		if dir.current_is_dir():
			process_dir(full_path)
		elif file_name.ends_with(".tres"):
			var resource := load(full_path)
			var id
			if resource is ItemResource:
				id = resource.item_id
				if id == "":
					push_warning("Item resource '%s' has no item_id" % file_name)
				else:
					var key_name = id.to_pascal_case()
					key_enum += "\t%s,\n" % key_name
					enum_string_mapping += "\tKeys.%s:\"%s\",\n"%[key_name,id]
					path_dict += "\t\"%s\": \"%s\",\n" % [id, full_path]

					if resource is CraftableResource:
						craftable_map += "\t\"%s\": PATHS[\"%s\"],\n" % [id, id]
						craftable_index += 1

					index += 1
			else:
				push_warning("File '%s' is not a valid ItemResource" % file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
