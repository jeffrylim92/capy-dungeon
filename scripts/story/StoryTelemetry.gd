class_name StoryTelemetry
extends RefCounted

const SCHEMA_VERSION: int = 1
const MAX_EVENTS: int = 128
const MAX_EVENT_DATA_FIELDS: int = 24
const MAX_ARRAY_ITEMS: int = 24

const STAGE_METRIC_FIELDS: Dictionary = {
	"ch1_1":["route_complete", "target_alive", "escort_command", "route_choice"],
	"ch1_2":["timer_complete", "target_alive", "growth_resolved", "finale_complete"],
	"ch1_3":["required_completed", "feeding_sacs_resolved", "foreman_resolved", "supplies_secured"],
	"ch1_4":["required_completed", "gate_crossed", "key_enemy_held", "route_complete"],
	"ch1_5":["barrage_phases_completed", "boss_defeated", "finale_complete"],
	"ch2_1":["braziers_lit", "active_braziers", "cold_exposure", "warmth_stabilized"],
	"ch2_2":["captives_extracted", "captives_refrozen", "prisons_destroyed", "jailer_elite_resolved"],
	"ch2_3":["runes_correct", "sequence_reveal_complete", "final_rune_activated", "spreading_freeze_resolved"],
	"ch2_4":["clues_found", "wrong_chests", "tablets_inspected", "mimic_defeated"],
	"ch2_5":["crystals_broken", "armour_transitions", "cold_exposure", "boss_defeated"],
	"ch3_1":["pools_purified", "nodes_resolved", "all_pools_stable", "corruption"],
	"ch3_2":["tracking_phases_complete", "correct_routes", "wrong_routes", "boss_defeated"],
	"ch3_3":["regions_complete", "ingredients_contaminated", "ingredient_case_extracted"],
	"ch3_4":["vial_integrity", "route_checkpoints", "route", "altar_cured"],
	"ch3_5":["ingredients_submitted", "purity", "heat", "boss_defeated"],
	"ch4_1":["ore_delivered", "ore_stolen", "heat", "cart_reached_extraction"],
	"ch4_2":["mechanisms_powered", "route_nodes", "mandatory_jam_active", "stabilization_complete"],
	"ch4_3":["golems_captured", "capture_pending", "capture_channel_active", "assistance_resolved"],
	"ch4_4":["components_collected", "relic_choice", "relic_choice_committed", "boss_defeated"],
	"ch4_5":["regulators_disabled", "boss_regulator_phases_completed", "heat", "shutdown_complete", "boss_defeated"],
	"ch5_1":["selected_route", "alert", "lockdowns", "mechanisms_disabled", "final_threshold_crossed"],
	"ch5_2":["spirits_saved", "spirits_lost", "seals_stable", "abyss_pressure", "portal_sealed"],
	"ch5_3":["rooms_completed", "wrong_choices", "abyss_pressure", "guardian_defeated"],
	"ch5_4":["sync_failures", "sync_succeeded", "route_prepared", "eclipse_pressure", "elite_disruptions"],
	"ch5_5":["anchors_destroyed", "crown_sections_broken", "crown_cycles", "desperation_entered", "boss_defeated"],
}

const STAGE_COVERAGE: Dictionary = {
	"ch1_1":{"primary":"escort route completion", "failure":"Scout survival", "choice":"command and route"},
	"ch1_2":{"primary":"defence timer completion", "failure":"shrine survival", "choice":"growth resolution"},
	"ch1_3":{"primary":"required objectives completed", "failure":"optional supplies lost", "choice":"foreman resolution"},
	"ch1_4":{"primary":"keys delivered", "failure":"key recovery pressure", "choice":"gate crossing"},
	"ch1_5":{"primary":"barrage phases completed", "failure":"boss defeat gate", "choice":"finale completion"},
	"ch2_1":{"primary":"braziers lit", "failure":"cold exposure", "choice":"active brazier stability"},
	"ch2_2":{"primary":"captives extracted", "failure":"captives refrozen", "choice":"prisons destroyed"},
	"ch2_3":{"primary":"runes completed", "failure":"wrong rune mistakes", "choice":"sequence completion"},
	"ch2_4":{"primary":"mimic defeated", "failure":"wrong chests", "choice":"clues and tablets"},
	"ch2_5":{"primary":"armour transitions", "failure":"cold exposure", "choice":"crystals broken"},
	"ch3_1":{"primary":"pools purified", "failure":"corruption pressure", "choice":"nodes resolved"},
	"ch3_2":{"primary":"tracking phases", "failure":"wrong routes", "choice":"correct routes"},
	"ch3_3":{"primary":"regions completed", "failure":"ingredient contamination", "choice":"case extraction"},
	"ch3_4":{"primary":"vial delivery", "failure":"vial integrity and retries", "choice":"route selected"},
	"ch3_5":{"primary":"brew and boss completion", "failure":"heat pressure", "choice":"final purity"},
	"ch4_1":{"primary":"ore delivered", "failure":"ore stolen and heat", "choice":"extraction reached"},
	"ch4_2":{"primary":"stabilization complete", "failure":"mandatory jam", "choice":"mechanisms and route"},
	"ch4_3":{"primary":"golems captured", "failure":"invalid capture pressure", "choice":"capture channel state"},
	"ch4_4":{"primary":"relic components", "failure":"guardian defeat", "choice":"relic choice"},
	"ch4_5":{"primary":"regulators disabled", "failure":"heat and protected floor", "choice":"shutdown phases"},
	"ch5_1":{"primary":"final threshold crossed", "failure":"alert and lockdowns", "choice":"infiltration route"},
	"ch5_2":{"primary":"spirits saved and portal sealed", "failure":"spirits lost", "choice":"seal stability"},
	"ch5_3":{"primary":"rooms completed", "failure":"wrong mirrors", "choice":"labyrinth choices"},
	"ch5_4":{"primary":"synchronization succeeded", "failure":"sync failures", "choice":"route preparation"},
	"ch5_5":{"primary":"ritual and boss completion", "failure":"protected ritual pressure", "choice":"anchor and crown progression"},
}

static var _attempt_sequence: int = 0

var _debug_enabled: bool = OS.is_debug_build()
var _stage_label: String = "C0S0"
var _stage_id: String = ""
var _chapter_id: String = "ch0"
var _difficulty: String = "normal"
var _mutators: Array[String] = []
var _challenge_score: float = 0.0
var _test_mode: bool = false
var _run_context: String = "story"
var _run_id: String = ""
var _started_msec: int = 0
var _active_seconds: float = 0.0
var _active_time_synced: bool = false
var _once: Dictionary = {}
var _events: Array[Dictionary] = []
var _sink: Callable = Callable()
var _current_phase: String = "setup"
var _phase_started_seconds: float = 0.0
var _terminal: bool = false
var _deaths: int = 0
var _objective_failures: int = 0
var _story_enemies_spawned: int = 0
var _peak_active_story_enemies: int = 0
var _optional_supplies_lost: int = 0
var _recoveries: int = 0
var _phase_count: int = 0
var _role_encounters: Dictionary = {}
var _role_pressure: Dictionary = {}
var _mistakes: Dictionary = {}
var _protected_damage_rejections: Dictionary = {}
var _build_summary: Dictionary = {}
var _mastery_failed: Dictionary = {}
var _mastery_earned: Array[String] = []
var _mastery_new: Array[String] = []

func start(stage: Dictionary, test_mode: bool = false, build_profile: Dictionary = {}, run_context: String = "story") -> void:
	_stage_id = str(stage.get("id", "unknown"))
	_chapter_id = "ch%d" % int(stage.get("chapter", 0))
	_difficulty = str(stage.get("difficulty", "normal")).strip_edges().to_lower()
	_mutators = _canonical_ids(stage.get("mutators", []) as Array)
	_challenge_score = snappedf(float(stage.get("mutator_reward_bonus", 0.0)), 0.001)
	_test_mode = test_mode
	_run_context = _canonical_context(run_context, test_mode)
	_stage_label = "C%dS%d" % [int(stage.get("chapter", 0)), int(stage.get("chapter_stage", 0))]
	_run_id = _new_run_id(_stage_id)
	_started_msec = Time.get_ticks_msec()
	_active_seconds = 0.0
	_active_time_synced = false
	_current_phase = "setup"
	_phase_started_seconds = 0.0
	_terminal = false
	_deaths = 0
	_objective_failures = 0
	_story_enemies_spawned = 0
	_peak_active_story_enemies = 0
	_optional_supplies_lost = 0
	_recoveries = 0
	_phase_count = 0
	_once.clear()
	_events.clear()
	_role_encounters.clear()
	_role_pressure.clear()
	_mistakes.clear()
	_protected_damage_rejections.clear()
	_mastery_failed.clear()
	_mastery_earned.clear()
	_mastery_new.clear()
	_build_summary = compact_build(build_profile)
	_emit("story_stage_started", {"schema_version":SCHEMA_VERSION, "stage_label":_stage_label, "mutator_count":_mutators.size(), "challenge_score":_challenge_score, "build":_build_summary})
	_emit("story_phase_entered", {"phase_id":"setup", "phase_index":0})
	_debug("Attempt started · run_id=%s · context=%s" % [_run_id, _run_context])

func configure_sink(sink: Callable) -> void:
	_sink = sink

func set_debug_enabled(enabled: bool) -> void:
	_debug_enabled = enabled

func sync_active_time(active_seconds: float) -> void:
	if is_nan(active_seconds) or is_inf(active_seconds):
		return
	_active_seconds = maxf(_active_seconds, maxf(0.0, active_seconds))
	_active_time_synced = true

func elapsed_seconds() -> float:
	if _active_time_synced:
		return _active_seconds
	if _started_msec <= 0:
		return 0.0
	return float(Time.get_ticks_msec() - _started_msec) / 1000.0

func run_id() -> String:
	return _run_id

func context() -> String:
	return _run_context

func is_terminal() -> bool:
	return _terminal

func events() -> Array[Dictionary]:
	return _events.duplicate(true)

func event_count(event_name: String = "") -> int:
	if event_name.is_empty():
		return _events.size()
	var count: int = 0
	for event in _events:
		if str(event.get("event_name", "")) == event_name:
			count += 1
	return count

func log_event(message: String) -> void:
	_debug(message)

func log_once(key: String, message: String) -> void:
	if _once.has(key):
		return
	_once[key] = true
	_debug(message)

func phase_changed(previous: String, current: String) -> void:
	if previous == current or _terminal:
		return
	var now := elapsed_seconds()
	_emit("story_phase_completed", {"phase_id":previous, "duration_seconds":snappedf(maxf(0.0, now - _phase_started_seconds), 0.01), "next_phase_id":current})
	_current_phase = current
	_phase_started_seconds = now
	_phase_count += 1
	_emit("story_phase_entered", {"phase_id":current, "phase_index":_phase_count})

func objective_spawned(objective: String, counters: String = "") -> void:
	_emit("story_objective_started", {"objective_id":objective, "counter_snapshot":counters})

func objective_completed(objective: String, counters: String = "") -> void:
	_emit("story_objective_completed", {"objective_id":objective, "counter_snapshot":counters})

func objective_failed(objective: String, reason: String, recoverable: bool = false) -> void:
	_objective_failures += 1
	_emit("story_objective_failed", {"objective_id":objective, "reason_id":reason, "recoverable":recoverable})

func victory_requested(reason: String) -> void:
	_emit_once("victory_request:%s:%s" % [_current_phase, reason], "story_victory_requested", {"reason_id":reason, "phase_id":_current_phase})

func victory_rejected(reason: String, snapshot: String) -> void:
	_emit_once("victory_rejected:%s:%s" % [_current_phase, reason], "story_victory_rejected", {"reason_id":reason, "phase_id":_current_phase, "state_snapshot":snapshot})

func victory_accepted(reason: String) -> void:
	_emit_once("victory_accepted", "story_victory_accepted", {"reason_id":reason, "phase_id":_current_phase})

func failure(reason: String) -> void:
	if reason != "player_defeated":
		objective_failed(_stage_id, reason, true)
	else:
		_debug("Failure: %s" % reason)

func player_death(source_id: String = "unknown") -> void:
	_deaths += 1
	_emit("story_player_defeated", {"death_index":_deaths, "source_id":source_id if not source_id.is_empty() else "unknown", "phase_id":_current_phase})

func story_enemy_spawned(tag: String, active_count: int, _required_remaining: int = 0, _optional_remaining: int = 0, primary_role: String = "") -> void:
	_story_enemies_spawned += 1
	_peak_active_story_enemies = maxi(_peak_active_story_enemies, active_count)
	var role := primary_role.strip_edges().to_lower()
	if not role.is_empty():
		_role_encounters[role] = int(_role_encounters.get(role, 0)) + 1
	if tag.contains("boss") or tag in ["crestkeeper", "frost_colossus", "frost_mimic", "abyss_king"]:
		boss_spawned(tag)

func story_enemy_defeated(primary_role: String = "", boss_id: String = "") -> void:
	var role := primary_role.strip_edges().to_lower()
	if not role.is_empty():
		var key := "%s_defeated" % role
		_role_pressure[key] = int(_role_pressure.get(key, 0)) + 1
	if not boss_id.is_empty():
		_emit_once("boss_defeated:%s" % boss_id, "story_boss_defeated", {"boss_id":boss_id, "phase_id":_current_phase})

func role_event(role_id: String, mechanic_id: String, amount: int = 1) -> void:
	var key := "%s:%s" % [role_id, mechanic_id]
	_role_pressure[key] = int(_role_pressure.get(key, 0)) + maxi(1, amount)
	_emit_once("role_pressure:%s" % key, "story_enemy_role_pressure", {"role_id":role_id, "mechanic_id":mechanic_id})

func recovery(event_name: String) -> void:
	_recoveries += 1
	_emit("story_objective_recovered", {"recovery_id":event_name, "recovery_index":_recoveries})

func optional_supply_lost() -> void:
	_optional_supplies_lost += 1
	mistake("optional_supply_lost", {"count":_optional_supplies_lost})

func retry(reason: String = "restart") -> void:
	_emit("story_objective_retried", {"reason_id":reason})

func stage_retried(reason: String = "restart") -> void:
	_emit("story_stage_retried", {"reason_id":reason, "previous_run_id":_run_id})

func mistake(mistake_id: String, data: Dictionary = {}) -> void:
	var count := int(_mistakes.get(mistake_id, 0)) + 1
	_mistakes[mistake_id] = count
	var payload := data.duplicate(true)
	payload["mistake_id"] = mistake_id
	payload["count"] = count
	_emit("story_mistake", payload)

func build_updated(build_profile: Dictionary) -> void:
	var next_summary := compact_build(build_profile)
	if next_summary == _build_summary:
		return
	_build_summary = next_summary
	_emit("story_build_updated", {"build":_build_summary})

func mutator_triggered(mutator_id: String) -> void:
	var key := "mutator:%s" % mutator_id
	_role_pressure[key] = int(_role_pressure.get(key, 0)) + 1
	_emit_once(key, "story_mutator_triggered", {"mutator_id":mutator_id})

func boss_spawned(boss_id: String) -> void:
	_emit_once("boss_spawned:%s" % boss_id, "story_boss_spawned", {"boss_id":boss_id, "phase_id":_current_phase})

func boss_mechanic(boss_id: String, mechanic_id: String, data: Dictionary = {}) -> void:
	var payload := data.duplicate(true)
	payload["boss_id"] = boss_id
	payload["mechanic_id"] = mechanic_id
	payload["phase_id"] = _current_phase
	_emit("story_boss_mechanic", payload)

func protected_damage_rejected(target_id: String, reason_id: String) -> void:
	var key := "%s:%s" % [target_id, reason_id]
	_protected_damage_rejections[key] = int(_protected_damage_rejections.get(key, 0)) + 1
	_emit_once("protected:%s" % key, "story_protected_damage_rejected", {"target_id":target_id, "reason_id":reason_id})

func mastery_failed(objective_id: String, reason: String) -> void:
	_mastery_failed[objective_id] = reason
	_emit("story_mastery_failed", {"objective_id":objective_id, "reason_id":reason})

func mastery_final(earned_value: Variant, failed_value: Variant = {}, test_mode: bool = false) -> void:
	_mastery_earned.clear()
	if earned_value is Array:
		_mastery_earned = _canonical_ids(earned_value as Array)
	else:
		for index in maxi(0, int(earned_value)):
			_mastery_earned.append("legacy_star_%d" % (index + 1))
	if failed_value is Dictionary:
		_mastery_failed = (failed_value as Dictionary).duplicate(true)
	elif failed_value is bool:
		test_mode = bool(failed_value)
	_emit("story_mastery_result", {"earned_ids":_mastery_earned, "earned_count":_mastery_earned.size(), "failed":_mastery_failed, "eligible_count":maxi(0, 3 - _mastery_failed.size()), "persisted":false, "test_mode":test_mode})

func mastery_persisted(new_value: Variant, test_mode: bool) -> void:
	_mastery_new.clear()
	if new_value is Array:
		_mastery_new = _canonical_ids(new_value as Array)
	_emit("story_mastery_persisted", {"newly_earned_ids":_mastery_new, "newly_earned_count":_mastery_new.size() if new_value is Array else maxi(0, int(new_value)), "persisted":not test_mode, "test_mode":test_mode})

func stage_completed(duration_seconds: float, final_state: Dictionary = {}, run_summary: Dictionary = {}, history_run_id: String = "") -> void:
	if _terminal:
		return
	sync_active_time(duration_seconds)
	var payload := _terminal_summary(final_state, run_summary)
	payload["history_run_id"] = history_run_id
	_emit("story_stage_completed", payload)
	_terminal = true

func stage_failed(reason_id: String, duration_seconds: float, final_state: Dictionary = {}, run_summary: Dictionary = {}, death_source_id: String = "unknown") -> void:
	if _terminal:
		return
	sync_active_time(duration_seconds)
	var payload := _terminal_summary(final_state, run_summary)
	payload["reason_id"] = reason_id
	payload["death_source_id"] = death_source_id if not death_source_id.is_empty() else "unknown"
	_emit("story_stage_failed", payload)
	_terminal = true

func stage_abandoned(reason_id: String, duration_seconds: float, final_state: Dictionary = {}, run_summary: Dictionary = {}) -> void:
	if _terminal:
		return
	sync_active_time(duration_seconds)
	var payload := _terminal_summary(final_state, run_summary)
	payload["reason_id"] = reason_id
	_emit("story_stage_abandoned", payload)
	_terminal = true

func summary() -> Dictionary:
	return {"run_id":_run_id, "run_context":_run_context, "stage_id":_stage_id, "difficulty":_difficulty, "mutator_ids":_mutators.duplicate(), "challenge_score":_challenge_score, "active_seconds":snappedf(elapsed_seconds(), 0.01), "phase_id":_current_phase, "phase_count":_phase_count, "deaths":_deaths, "objective_failures":_objective_failures, "recoveries":_recoveries, "optional_supplies_lost":_optional_supplies_lost, "story_enemies_spawned":_story_enemies_spawned, "peak_active_story_enemies":_peak_active_story_enemies, "role_encounters":_role_encounters.duplicate(true), "role_pressure":_role_pressure.duplicate(true), "mistakes":_mistakes.duplicate(true), "protected_damage_rejections":_protected_damage_rejections.duplicate(true), "build":_build_summary.duplicate(true), "mastery_earned_ids":_mastery_earned.duplicate(), "mastery_newly_earned_ids":_mastery_new.duplicate()}

static func compact_build(build_profile: Dictionary) -> Dictionary:
	var tiers: Dictionary = build_profile.get("tiers", {}) as Dictionary
	var scores: Dictionary = build_profile.get("scores", {}) as Dictionary
	var active_tiers: Dictionary = {}
	var active_scores: Dictionary = {}
	for capability in StoryBuildCapabilities.CAPABILITIES:
		var tier := str(tiers.get(capability, "none"))
		if tier == "none":
			continue
		active_tiers[capability] = tier
		active_scores[capability] = snappedf(clampf(float(scores.get(capability, 0.0)), 0.0, 1.0), 0.01)
	var result := {"tiers":active_tiers, "scores":active_scores}
	if build_profile.has("dev_override"):
		result["dev_override"] = str(build_profile.get("dev_override", ""))
	return result

static func stage_metrics(stage_id: String, state: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for field_variant in STAGE_METRIC_FIELDS.get(stage_id, []) as Array:
		var field := str(field_variant)
		if state.has(field):
			result[field] = _sanitize_value(state[field])
	return result

static func stage_coverage() -> Dictionary:
	return STAGE_COVERAGE.duplicate(true)

static func _canonical_context(requested: String, test_mode: bool) -> String:
	if requested == "boss_practice":
		return "boss_practice"
	if test_mode or requested in ["story_test", "story_dev_test"]:
		return "story_dev_test"
	return "story"

static func _canonical_ids(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		var id := str(value).strip_edges().to_lower()
		if not id.is_empty() and id not in result:
			result.append(id)
	result.sort()
	return result

static func _new_run_id(stage_id: String) -> String:
	_attempt_sequence += 1
	return "%s-%d-%d-%d" % [stage_id, int(Time.get_unix_time_from_system() * 1000.0), Time.get_ticks_usec(), _attempt_sequence]

func _terminal_summary(final_state: Dictionary, run_summary: Dictionary) -> Dictionary:
	return {
		"active_seconds":snappedf(elapsed_seconds(), 0.01),
		"phase_id":_current_phase,
		"phase_count":_phase_count,
		"final_phase_duration":snappedf(maxf(0.0, elapsed_seconds() - _phase_started_seconds), 0.01),
		"outcomes":{"deaths":_deaths, "objective_failures":_objective_failures, "recoveries":_recoveries, "optional_supplies_lost":_optional_supplies_lost},
		"enemy_aggregate":{"story_enemies_spawned":_story_enemies_spawned, "peak_active_story_enemies":_peak_active_story_enemies},
		"role_encounters":_role_encounters.duplicate(true),
		"role_pressure":_role_pressure.duplicate(true),
		"mistakes":_mistakes.duplicate(true),
		"protected_damage_rejections":_protected_damage_rejections.duplicate(true),
		"build":_build_summary.duplicate(true),
		"mastery":{"earned_ids":_mastery_earned.duplicate(), "newly_earned_ids":_mastery_new.duplicate(), "failed":_mastery_failed.duplicate(true)},
		"stage_metrics":stage_metrics(_stage_id, final_state),
		"run_summary":_sanitize_value(run_summary),
	}

func _emit_once(key: String, event_name: String, event_data: Dictionary) -> void:
	if _once.has(key):
		return
	_once[key] = true
	_emit(event_name, event_data)

func _emit(event_name: String, event_data: Dictionary = {}) -> void:
	if _run_id.is_empty():
		return
	var event := {"event_name":event_name, "timestamp":int(Time.get_unix_time_from_system() * 1000.0), "run_id":_run_id, "run_context":_run_context, "stage_id":_stage_id, "chapter_id":_chapter_id, "difficulty":_difficulty, "mutator_ids":_mutators.duplicate(), "event_data":_sanitize_value(event_data)}
	if _events.size() >= MAX_EVENTS:
		_events.pop_front()
	_events.append(event)
	if _sink.is_valid():
		_sink.call(event.duplicate(true))
	_debug("%s · %s" % [event_name, JSON.stringify(event.get("event_data", {}))])

func _debug(message: String) -> void:
	if not _debug_enabled:
		return
	var root_tag := "[BossPractice]" if _run_context == "boss_practice" else "[Story]"
	var mode_tag := "[TEST]" if _run_context == "story_dev_test" else ""
	print("%s%s[%s][%s][%.2fs] %s" % [root_tag, mode_tag, _difficulty.to_upper(), _stage_label, elapsed_seconds(), message])

static func _sanitize_value(value: Variant, depth: int = 0) -> Variant:
	if depth >= 5:
		return str(value).left(160)
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT:
			return value
		TYPE_FLOAT:
			var number := float(value)
			return snappedf(number, 0.001) if not is_nan(number) and not is_inf(number) else 0.0
		TYPE_STRING, TYPE_STRING_NAME:
			return str(value).left(240)
		TYPE_ARRAY:
			var output: Array = []
			var source := value as Array
			for index in mini(source.size(), MAX_ARRAY_ITEMS):
				output.append(_sanitize_value(source[index], depth + 1))
			return output
		TYPE_DICTIONARY:
			var output: Dictionary = {}
			var source := value as Dictionary
			var count: int = 0
			for key_variant in source:
				if count >= MAX_EVENT_DATA_FIELDS:
					break
				output[str(key_variant).left(80)] = _sanitize_value(source[key_variant], depth + 1)
				count += 1
			return output
		_:
			return str(value).left(160)
