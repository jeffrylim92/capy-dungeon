class_name CharacterLoader
extends RefCounted

## Discovers every CharacterData .tres file under `res://resources/characters/`.
## Sorted by id for deterministic order.

const CHAR_DIR := "res://resources/characters/"

## Known character IDs used as fallback when DirAccess fails (e.g. on some Android builds).
const _KNOWN_IDS: Array[String] = [
	"capy_archer", "capy_assassin", "capy_brown",
	"capy_chef", "capy_swamp", "capy_wizard", "capy_zoomer",
]

static func load_all() -> Array[CharacterData]:
	var out: Array[CharacterData] = []
	var dir := DirAccess.open(CHAR_DIR)
	if dir == null:
		DebugLog.log("CharacterLoader: DirAccess.open('%s') failed (err %d) — using fallback" % [
			CHAR_DIR, DirAccess.get_open_error()])
		return _load_fallback()
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
	DebugLog.log("CharacterLoader: loaded %d characters via DirAccess" % out.size())
	if out.is_empty():
		DebugLog.log("CharacterLoader: DirAccess returned empty — trying fallback")
		return _load_fallback()
	return out

static func _load_fallback() -> Array[CharacterData]:
	var out: Array[CharacterData] = []
	for char_id in _KNOWN_IDS:
		for ext: String in [".tres", ".res"]:
			var path := CHAR_DIR + char_id + ext
			if ResourceLoader.exists(path):
				var res := load(path)
				if res is CharacterData:
					out.append(res)
				break
	DebugLog.log("CharacterLoader: fallback loaded %d characters" % out.size())
	out.sort_custom(func(a: CharacterData, b: CharacterData) -> bool:
		return String(a.id) < String(b.id))
	return out

static func _is_resource_file(name: String) -> bool:
	# Editor may produce .tres or imported .res / .remap variants.
	if name.ends_with(".remap"):
		name = name.trim_suffix(".remap")
	return name.ends_with(".tres") or name.ends_with(".res")
