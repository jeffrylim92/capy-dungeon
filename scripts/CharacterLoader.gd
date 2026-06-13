class_name CharacterLoader
extends RefCounted

## Discovers every CharacterData .tres file under `res://resources/characters/`.
## Sorted by id for deterministic order.

const CHAR_DIR := "res://resources/characters/"

static func load_all() -> Array[CharacterData]:
	var out: Array[CharacterData] = []
	var dir := DirAccess.open(CHAR_DIR)
	if dir == null:
		push_warning("CharacterLoader: directory not found: %s" % CHAR_DIR)
		return out
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and _is_resource_file(file_name):
			var path := CHAR_DIR + file_name
			var res := load(path)
			if res is CharacterData:
				out.append(res)
			else:
				push_warning("CharacterLoader: %s is not CharacterData" % path)
		file_name = dir.get_next()
	dir.list_dir_end()
	out.sort_custom(func(a: CharacterData, b: CharacterData) -> bool:
		return String(a.id) < String(b.id))
	return out

static func _is_resource_file(name: String) -> bool:
	# Editor may produce .tres or imported .res / .remap variants.
	if name.ends_with(".remap"):
		name = name.trim_suffix(".remap")
	return name.ends_with(".tres") or name.ends_with(".res")
