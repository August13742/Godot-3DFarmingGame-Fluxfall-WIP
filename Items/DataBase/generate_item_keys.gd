@tool
extends EditorScript

func _run():
	var header := "## AUTO-GENERATED FILE. DO NOT EDIT.\n"
	header += "class_name ItemDB\n\n"
	var key_output := "enum Keys {\n\tNULL,\n"
	var path_output := "const PATHS:Dictionary = {\n\t0: null,\n"
	var dir := DirAccess.open("res://Items/Resources/")
	if not dir:
		push_error("Directory not found: res://Items/Resources/")
		return

	var index := 1
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres") and not dir.current_is_dir():
			var path = "res://Items/Resources/" + file_name
			var resource:= load(path)
			if resource is ItemResource:
				var id = resource.item_id
				if id == "":
					push_warning("Item resource '%s' has no item_id" % file_name)
				else:
					key_output += "\t%s,\n" % [id.to_pascal_case()]
					path_output += "\t%d: \"%s\",\n"%[index,path]
					index += 1
			else:
				push_warning("File '%s' is not a valid ItemResource" % file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	key_output += "}\n\n\n"
	path_output += "}\n\n"

	var f := FileAccess.open("res://Items/DataBase/item_db.gd", FileAccess.WRITE)
	f.store_string(header+key_output+path_output)
	f.close()

	print_debug("✔ ItemKeys generation complete with [%d] Keys."%index)
