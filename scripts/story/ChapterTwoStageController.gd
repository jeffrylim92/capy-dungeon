class_name ChapterTwoStageController
extends RefCounted

var stage_number: int = 0
var phase: String = "setup"
var cold_exposure: float = 0.0
var flags: Dictionary = {}
var counters: Dictionary = {}
var timers: Dictionary = {}

func reset(next_stage_number: int) -> void:
	stage_number = next_stage_number
	phase = "setup"
	cold_exposure = 0.0
	flags = {
		"transition_pending": false,
		"primary_complete": false,
		"finale_complete": false,
		"boss_spawned": false,
		"boss_defeated": false,
		"all_armour_transitions_complete": false,
	}
	counters = {}
	timers = {}

func enter(next_phase: String) -> String:
	var previous: String = phase
	phase = next_phase
	flags["transition_pending"] = false
	return previous

func set_flag(key: String, value: bool = true) -> void:
	flags[key] = value

func flag(key: String) -> bool:
	return bool(flags.get(key, false))

func set_count(key: String, value: int) -> void:
	counters[key] = value

func count(key: String) -> int:
	return int(counters.get(key, 0))

func add_count(key: String, amount: int = 1) -> int:
	var value: int = count(key) + amount
	counters[key] = value
	return value

func set_timer(key: String, value: float) -> void:
	timers[key] = value

func tick_timer(key: String, delta: float) -> float:
	var value: float = maxf(0.0, float(timers.get(key, 0.0)) - delta)
	timers[key] = value
	return value

func timer(key: String) -> float:
	return float(timers.get(key, 0.0))

func completion_state() -> Dictionary:
	var result: Dictionary = flags.duplicate(true)
	result.merge(counters, true)
	result["chapter_two_phase"] = phase
	result["cold_exposure"] = cold_exposure
	return result
