extends SceneTree

## Minimal runnable tests for ComboSystem (no GUT dependency).
## Run:  godot --headless --script tests/test_combo_system.gd

func _init() -> void:
	var failures := 0
	failures += _run("hit increments count", _test_hit_increments)
	failures += _run("miss resets count", _test_miss_resets)
	failures += _run("multiplier scales with count", _test_multiplier)
	failures += _run("multiplier is capped", _test_multiplier_cap)
	failures += _run("milestone fires once", _test_milestone_once)
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

func _test_hit_increments() -> bool:
	var c := ComboSystem.new()
	c.register_hit("apple")
	c.register_hit("apple")
	return c.count == 2

func _test_miss_resets() -> bool:
	var c := ComboSystem.new()
	c.register_hit("apple")
	c.register_hit("apple")
	c.register_miss()
	return c.count == 0

func _test_multiplier() -> bool:
	var c := ComboSystem.new()
	for i in range(10):
		c.register_hit("apple")
	return abs(c.multiplier() - 1.4) < 0.001

func _test_multiplier_cap() -> bool:
	var c := ComboSystem.new()
	for i in range(500):
		c.register_hit("apple")
	return c.multiplier() == 3.0

func _test_milestone_once() -> bool:
	var c := ComboSystem.new()
	var hits := [0]
	c.milestone_reached.connect(func(_n: int) -> void: hits[0] += 1)
	for i in range(10):
		c.register_hit("apple")
	# stays at 10, no new milestone
	return hits[0] == 1
