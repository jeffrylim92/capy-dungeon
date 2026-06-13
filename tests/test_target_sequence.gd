extends SceneTree

## Tests for TargetSequence.
## Run:  godot --headless --script tests/test_target_sequence.gd

func _init() -> void:
	var failures := 0
	failures += _run("peek returns N items", _test_peek)
	failures += _run("advance moves head", _test_advance)
	failures += _run("seeded sequences are reproducible", _test_seeded)
	failures += _run("never repeats same id back-to-back", _test_no_repeat)
	failures += _run("matches uses current head", _test_matches)
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

func _test_peek() -> bool:
	var t := TargetSequence.new(42)
	return t.peek(3).size() == 3

func _test_advance() -> bool:
	var t := TargetSequence.new(42)
	var first := t.current()
	t.advance()
	return t.current() != first or t.peek(1)[0] == t.current()

func _test_seeded() -> bool:
	var a := TargetSequence.new(123)
	var b := TargetSequence.new(123)
	return a.peek(8) == b.peek(8)

func _test_no_repeat() -> bool:
	var t := TargetSequence.new(7)
	var seq := t.peek(50)
	for i in range(1, seq.size()):
		if seq[i] == seq[i - 1]:
			return false
	return true

func _test_matches() -> bool:
	var t := TargetSequence.new(99)
	return t.matches(t.current()) and not t.matches("definitely-not-a-fruit")
