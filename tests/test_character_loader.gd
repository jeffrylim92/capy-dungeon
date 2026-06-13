extends SceneTree

## Tests for CharacterLoader and CharacterData.
## Run:  godot --headless --script tests/test_character_loader.gd

func _init() -> void:
	var failures := 0
	failures += _run("loads at least one character", _test_loads_some)
	failures += _run("characters have non-empty ids", _test_ids)
	failures += _run("characters are sorted by id", _test_sorted)
	failures += _run("default brown capy is present", _test_brown_present)
	if failures == 0:
		print("\nAll tests passed.")
		quit(0)
	else:
		printerr("\n%d test(s) failed." % failures)
		quit(1)

func _run(name: String, fn: Callable) -> int:
	var ok: bool = fn.call()
	print(("PASS " if ok else "FAIL ") + name)
	return 0 if ok else 1

func _test_loads_some() -> bool:
	return CharacterLoader.load_all().size() > 0

func _test_ids() -> bool:
	for c in CharacterLoader.load_all():
		if String(c.id).is_empty():
			return false
	return true

func _test_sorted() -> bool:
	var chars := CharacterLoader.load_all()
	for i in range(1, chars.size()):
		if String(chars[i - 1].id) > String(chars[i].id):
			return false
	return true

func _test_brown_present() -> bool:
	for c in CharacterLoader.load_all():
		if c.id == &"capy_brown":
			return true
	return false
