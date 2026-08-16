class_name ChapterThreeStageController
extends RefCounted

var stage_number: int = 0
var phase: String = "setup"
var flags: Dictionary = {}
var counters: Dictionary = {}
var timers: Dictionary = {}
var meters: Dictionary = {}
var recipe: Array[int] = []
var region_order: Array[int] = []

func reset(next_stage_number: int) -> void:
	stage_number = next_stage_number
	phase = "setup"
	flags = {"transition_pending":false, "primary_complete":false, "boss_spawned":false, "boss_defeated":false}
	counters = {}
	timers = {}
	meters = {"corruption":0.0}
	recipe.clear()
	region_order.clear()

func enter(next_phase: String) -> String:
	var previous: String = phase
	phase = next_phase
	flags["transition_pending"] = false
	return previous

func set_flag(key: String, value: bool = true) -> void: flags[key] = value
func flag(key: String) -> bool: return bool(flags.get(key, false))
func set_count(key: String, value: int) -> void: counters[key] = value
func count(key: String) -> int: return int(counters.get(key, 0))
func add_count(key: String, amount: int = 1) -> int:
	var value: int = count(key) + amount
	counters[key] = value
	return value
func set_timer(key: String, value: float) -> void: timers[key] = value
func tick_timer(key: String, delta: float) -> float:
	var value: float = maxf(0.0, float(timers.get(key, 0.0)) - delta)
	timers[key] = value
	return value
func timer(key: String) -> float: return float(timers.get(key, 0.0))
func set_meter(key: String, value: float) -> void: meters[key] = clampf(value, 0.0, 100.0)
func meter(key: String) -> float: return float(meters.get(key, 0.0))
func adjust_meter(key: String, amount: float) -> float:
	set_meter(key, meter(key) + amount)
	return meter(key)

func completion_state() -> Dictionary:
	var state: Dictionary = flags.duplicate(true)
	state.merge(counters, true)
	state.merge(meters, true)
	state["chapter_three_phase"] = phase
	state["recipe_size"] = recipe.size()
	return state
