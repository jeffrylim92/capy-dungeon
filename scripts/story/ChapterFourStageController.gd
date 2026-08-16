class_name ChapterFourStageController
extends RefCounted

var stage_number: int = 0
var phase: String = "setup"
var flags: Dictionary = {}
var counters: Dictionary = {}
var meters: Dictionary = {}
var timers: Dictionary = {}
var sequence: Array[int] = []

func reset(next_stage_number: int) -> void:
	stage_number = next_stage_number
	phase = "setup"
	flags = {
		"transition_pending": false,
		"primary_complete": false,
		"boss_spawned": false,
		"boss_defeated": false,
		"final_phase_entered": false,
	}
	counters = {}
	meters = {"heat": 30.0}
	timers = {}
	sequence.clear()

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
func set_meter(key: String, value: float) -> void: meters[key] = clampf(value, 0.0, 100.0)
func meter(key: String) -> float: return float(meters.get(key, 0.0))
func adjust_meter(key: String, amount: float) -> float:
	set_meter(key, meter(key) + amount)
	return meter(key)
func set_timer(key: String, value: float) -> void: timers[key] = value
func timer(key: String) -> float: return float(timers.get(key, 0.0))
func tick_timer(key: String, delta: float) -> float:
	var value: float = maxf(0.0, timer(key) - delta)
	timers[key] = value
	return value

func completion_state() -> Dictionary:
	var state: Dictionary = flags.duplicate(true)
	state.merge(counters, true)
	state.merge(meters, true)
	state["chapter_four_phase"] = phase
	state["shutdown_sequence_size"] = sequence.size()
	return state
