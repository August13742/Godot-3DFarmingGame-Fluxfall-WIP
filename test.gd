@tool
extends EditorScript


var header := "## AUTO-GENERATED FILE. DO NOT EDIT.\n"


var key_enum := "enum Keys {\n\tNULL,\n"
var path_dict := "const PATHS: Dictionary = {\n\t0: null,\n"

var craftable_enum := "enum Craftables {\n"
var craftable_map := "const CRAFTABLES: Dictionary = {\n"

var index := 1
var craftable_index := 0


func _run():
	header += "class_name Item1DB\n\n"


	process_dir("res://Items/Resources")
	key_enum += "}\n\n"
	path_dict += "}\n\n"
	craftable_enum += "}\n\n"
	craftable_map += "}\n\n"

	var full_output := header + key_enum + path_dict + craftable_enum + craftable_map

	var f := FileAccess.open("res://Items/DataBase/item_db1.gd", FileAccess.WRITE)
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
					path_dict += "\t%d: \"%s\",\n" % [index, full_path]

					if resource is CraftableResource:
						craftable_enum += "\t%s,\n" % key_name
						craftable_map += "\tCraftables.%s: Keys.%s,\n" % [key_name, key_name]
						craftable_index += 1

					index += 1
			else:
				push_warning("File '%s' is not a valid ItemResource" % file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
