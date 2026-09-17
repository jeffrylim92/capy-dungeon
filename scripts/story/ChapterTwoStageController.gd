class_name ChapterTwoStageController
extends RefCounted

const MIMIC_CHEST_COUNT: int = 6

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

static func build_mimic_layout(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var real_chest: int = rng.randi_range(0, MIMIC_CHEST_COUNT - 1)
	var safe_chests: Array[int] = []
	for chest_index in MIMIC_CHEST_COUNT:
		if chest_index != real_chest:
			safe_chests.append(chest_index)
	for index in range(safe_chests.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var swap_value: int = safe_chests[index]
		safe_chests[index] = safe_chests[swap_index]
		safe_chests[swap_index] = swap_value
	return {"real_chest":real_chest, "safe_chests":safe_chests}

static func validate_mimic_layout(layout: Dictionary) -> bool:
	var real_chest: int = int(layout.get("real_chest", -1))
	var safe_chests: Array = layout.get("safe_chests", []) as Array
	if real_chest < 0 or real_chest >= MIMIC_CHEST_COUNT or safe_chests.size() != MIMIC_CHEST_COUNT - 1:
		return false
	var seen: Dictionary = {}
	for safe_variant in safe_chests:
		var safe_chest: int = int(safe_variant)
		if safe_chest < 0 or safe_chest >= MIMIC_CHEST_COUNT or safe_chest == real_chest or seen.has(safe_chest):
			return false
		seen[safe_chest] = true
	return seen.size() == MIMIC_CHEST_COUNT - 1

func completion_state() -> Dictionary:
	var result: Dictionary = flags.duplicate(true)
	result.merge(counters, true)
	result["chapter_two_phase"] = phase
	result["cold_exposure"] = cold_exposure
	return result
