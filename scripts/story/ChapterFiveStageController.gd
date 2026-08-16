class_name ChapterFiveStageController
extends RefCounted

const MIRROR_SYMBOLS: Array[String] = ["SUN", "MOON", "STAR", "EYE", "CROWN", "ROOT"]
const MIRROR_DIRECTIONS: Array[String] = ["LEFT", "RIGHT", "UP"]
const ANCHOR_ABILITIES: Dictionary = {"dominion":"summons", "ruin":"corruption", "reflection":"mirrored_projectiles"}

var stage_number: int = 0
var phase: String = "setup"
var flags: Dictionary = {}
var counters: Dictionary = {}
var meters: Dictionary = {}
var timers: Dictionary = {}
var route: String = ""
var mirror_history: Array[String] = []
var mirror_room: Dictionary = {}

func reset(next_stage_number: int) -> void:
	stage_number = next_stage_number
	phase = "setup"
	flags = {
		"transition_pending": false,
		"primary_complete": false,
		"boss_spawned": false,
		"boss_defeated": false,
	}
	counters = {}
	meters = {"abyss_pressure": 0.0, "alert": 0.0, "eclipse_pressure": 0.0}
	timers = {}
	route = ""
	mirror_history.clear()
	mirror_room.clear()

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

func record_anchor_destroyed(anchor_type: String) -> int:
	if not ANCHOR_ABILITIES.has(anchor_type) or flag("anchor_%s_destroyed" % anchor_type):
		return count("anchors_destroyed")
	set_flag("anchor_%s_destroyed" % anchor_type)
	return add_count("anchors_destroyed")

func boss_ability_enabled(ability: String) -> bool:
	for anchor_type in ANCHOR_ABILITIES:
		if str(ANCHOR_ABILITIES[anchor_type]) == ability:
			return not flag("anchor_%s_destroyed" % str(anchor_type))
	return false

func generate_mirror_room(room_index: int, seed_value: int) -> Dictionary:
	mirror_room = build_mirror_room(room_index, seed_value, mirror_history)
	return mirror_room

func remember_mirror() -> void:
	var correct_index: int = int(mirror_room.get("correct", -1))
	var mirrors: Array = mirror_room.get("mirrors", []) as Array
	if correct_index >= 0 and correct_index < mirrors.size():
		mirror_history.append(str((mirrors[correct_index] as Dictionary).get("symbol", "")))

static func build_mirror_room(room_index: int, seed_value: int, history: Array[String] = []) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + room_index * 7919
	var symbols: Array[String] = MIRROR_SYMBOLS.duplicate()
	for index in range(symbols.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var swap_value: String = symbols[index]
		symbols[index] = symbols[swap_index]
		symbols[swap_index] = swap_value
	var mirrors: Array[Dictionary] = []
	for index in 3:
		mirrors.append({"symbol":symbols[index], "direction":MIRROR_DIRECTIONS[(index + room_index) % 3], "pulses":index + 1})
	var correct: int = rng.randi_range(0, 2)
	var correct_mirror: Dictionary = mirrors[correct]
	var clue: String
	match room_index:
		0:
			clue = "The true path bears the %s sigil." % str(correct_mirror.symbol)
		1:
			clue = "Seek %s reflected %s; symbol and direction must both match." % [str(correct_mirror.symbol), str(correct_mirror.direction)]
		2:
			var false_index: int = (correct + 1) % 3
			clue = "Two inscriptions agree: %s and %d pulses. Ignore the false inscription claiming %s." % [str(correct_mirror.symbol), int(correct_mirror.pulses), str((mirrors[false_index] as Dictionary).symbol)]
		_:
			var remembered: String = history[-1] if not history.is_empty() else str(correct_mirror.symbol)
			var remembered_found: bool = false
			for index in 3:
				if str(mirrors[index].symbol) == remembered:
					correct = index
					correct_mirror = mirrors[index]
					remembered_found = true
					break
			if not remembered_found:
				var replacement: Dictionary = mirrors[correct]
				replacement["symbol"] = remembered
				mirrors[correct] = replacement
				correct_mirror = replacement
			clue = "Journal sequence: %s. Repeat the most recent sigil: %s." % [" → ".join(history), remembered]
	return {"room":room_index, "mirrors":mirrors, "correct":correct, "clue":clue, "unique":true}

static func validate_mirror_room(room: Dictionary) -> bool:
	var mirrors: Array = room.get("mirrors", []) as Array
	var correct: int = int(room.get("correct", -1))
	if mirrors.size() != 3 or correct < 0 or correct >= mirrors.size() or str(room.get("clue", "")).is_empty():
		return false
	var signatures: Dictionary = {}
	for mirror_variant in mirrors:
		var mirror: Dictionary = mirror_variant as Dictionary
		var signature: String = "%s:%s:%d" % [str(mirror.get("symbol", "")), str(mirror.get("direction", "")), int(mirror.get("pulses", 0))]
		if signatures.has(signature):
			return false
		signatures[signature] = true
	return true

func completion_state() -> Dictionary:
	var state: Dictionary = flags.duplicate(true)
	state.merge(counters, true)
	state.merge(meters, true)
	state["chapter_five_phase"] = phase
	state["selected_route"] = route
	state["mirror_history_size"] = mirror_history.size()
	return state
