class_name StoryTelemetry
extends RefCounted

var _enabled: bool = OS.is_debug_build()
var _stage_label: String = "C0S0"
var _stage_id: String = ""
var _test_mode: bool = false
var _started_msec: int = 0
var _once: Dictionary = {}
var _phase_started_msec: int = 0
var _current_phase: String = "setup"
var _deaths: int = 0
var _objective_failures: int = 0
var _story_enemies_spawned: int = 0
var _peak_active_story_enemies: int = 0
var _optional_supplies_lost: int = 0
var _final_phase_duration: float = 0.0

func start(stage: Dictionary, test_mode: bool = false) -> void:
	_stage_id = str(stage.get("id", "unknown"))
	_test_mode = test_mode
	_stage_label = "C%dS%d" % [int(stage.get("chapter", 0)), int(stage.get("chapter_stage", 0))]
	_started_msec = Time.get_ticks_msec()
	_phase_started_msec = _started_msec
	_current_phase = "setup"
	_deaths = 0
	_objective_failures = 0
	_story_enemies_spawned = 0
	_peak_active_story_enemies = 0
	_optional_supplies_lost = 0
	_final_phase_duration = 0.0
	_once.clear()
	log_event("Stage started: %s" % _stage_id)

func elapsed_seconds() -> float:
	if _started_msec <= 0:
		return 0.0
	return float(Time.get_ticks_msec() - _started_msec) / 1000.0

func log_event(message: String) -> void:
	if not _enabled:
		return
	var mode_tag: String = "[TEST]" if _test_mode else ""
	print("[Story]%s[%s][%.2fs] %s" % [mode_tag, _stage_label, elapsed_seconds(), message])

func log_once(key: String, message: String) -> void:
	if _once.has(key):
		return
	_once[key] = true
	log_event(message)

func phase_changed(previous: String, current: String) -> void:
	if previous == current:
		return
	var now: int = Time.get_ticks_msec()
	var phase_duration: float = float(now - _phase_started_msec) / 1000.0
	log_event("Phase ended: %s · duration=%.2fs" % [previous, phase_duration])
	log_event("Phase started: %s" % current)
	_current_phase = current
	_phase_started_msec = now

func objective_spawned(objective: String, counters: String = "") -> void:
	log_event("Objective spawned: %s%s" % [objective, " · " + counters if not counters.is_empty() else ""])

func objective_completed(objective: String, counters: String = "") -> void:
	log_event("Objective completed: %s%s" % [objective, " · " + counters if not counters.is_empty() else ""])

func victory_requested(reason: String) -> void:
	log_event("Victory requested: %s" % reason)

func victory_rejected(reason: String, snapshot: String) -> void:
	log_event("Victory rejected: %s%s" % [reason, " · " + snapshot if not snapshot.is_empty() else ""])

func victory_accepted(reason: String) -> void:
	_final_phase_duration = float(Time.get_ticks_msec() - _phase_started_msec) / 1000.0
	log_event("Victory accepted: %s · total_elapsed=%.2fs" % [reason, elapsed_seconds()])
	if _enabled:
		var mode_tag: String = "[TEST]" if _test_mode else ""
		print("[Story]%s[%s] COMPLETE\nDuration: %.1fs\nDeaths: %d\nObjective failures: %d\nOptional supplies lost: %d\nStory enemies spawned: %d\nPeak active Story enemies: %d\nFinal phase duration: %.1fs" % [mode_tag, _stage_label, elapsed_seconds(), _deaths, _objective_failures, _optional_supplies_lost, _story_enemies_spawned, _peak_active_story_enemies, _final_phase_duration])

func failure(reason: String) -> void:
	if reason != "player_defeated":
		_objective_failures += 1
	log_event("Failure: %s · total_elapsed=%.2fs" % [reason, elapsed_seconds()])

func player_death() -> void:
	_deaths += 1
	log_event("Player death: %d" % _deaths)

func story_enemy_spawned(tag: String, active_count: int, required_remaining: int = 0, optional_remaining: int = 0) -> void:
	_story_enemies_spawned += 1
	_peak_active_story_enemies = maxi(_peak_active_story_enemies, active_count)
	log_event("Story enemy spawned: %s · active=%d · required_remaining=%d · optional_remaining=%d" % [tag, active_count, required_remaining, optional_remaining])

func recovery(event_name: String) -> void:
	log_event("Recovery: %s" % event_name)

func optional_supply_lost() -> void:
	_optional_supplies_lost += 1
	log_event("Optional supply lost: %d" % _optional_supplies_lost)

func retry(reason: String = "restart") -> void:
	log_event("Retry or restart: %s" % reason)
