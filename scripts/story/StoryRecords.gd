class_name StoryRecords
extends RefCounted

const StoryMutatorsClass := preload("res://scripts/story/StoryMutators.gd")
const VERSION: int = 1
const TIME_EPSILON: float = 0.01
const DAMAGE_EPSILON: float = 0.01
const CHALLENGE_EPSILON: float = 0.0001
const DIFFICULTY_IDS := ["normal", "hard", "nightmare"]
const METRICS := ["best_time", "lowest_damage", "highest_challenge"]

static func valid_stage_id(stage_id: String) -> bool:
	if not stage_id.begins_with("ch"):
		return false
	var parts := stage_id.trim_prefix("ch").split("_")
	return parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int() and int(parts[0]) in range(1, 6) and int(parts[1]) in range(1, 6)

static func sanitize_records(value: Variant) -> Dictionary:
	var output: Dictionary = {}
	if typeof(value) != TYPE_DICTIONARY:
		return output
	for stage_variant in value as Dictionary:
		var stage_id := str(stage_variant)
		if not valid_stage_id(stage_id):
			continue
		var raw_stage: Variant = (value as Dictionary)[stage_variant]
		if typeof(raw_stage) != TYPE_DICTIONARY:
			continue
		var clean_stage: Dictionary = {}
		for metric in METRICS:
			var clean := _sanitize_metric((raw_stage as Dictionary).get(metric), metric, stage_id)
			if not clean.is_empty():
				clean_stage[metric] = clean
		if not clean_stage.is_empty():
			output[stage_id] = clean_stage
	return output

static func stage_record(records: Variant, stage_id: String) -> Dictionary:
	return (sanitize_records(records).get(stage_id, {}) as Dictionary).duplicate(true)

static func evaluate_run(records_value: Variant, run_value: Variant) -> Dictionary:
	var records := sanitize_records(records_value)
	if typeof(run_value) != TYPE_DICTIONARY:
		return {"eligible":false, "updated_records":records, "changes":[], "first_record":false, "current":{}}
	var run: Dictionary = run_value as Dictionary
	var stage_id := str(run.get("stage_id", ""))
	if not valid_stage_id(stage_id) or not bool(run.get("completed", false)) or str(run.get("context", "story")) != "story":
		return {"eligible":false, "updated_records":records, "changes":[], "first_record":false, "current":stage_record(records, stage_id)}
	var current: Dictionary = (records.get(stage_id, {}) as Dictionary).duplicate(true)
	var first_record := current.is_empty()
	var changes: Array[Dictionary] = []
	var context := _run_context(run, stage_id)
	if _valid_number(run.get("duration_seconds")):
		var time_value := float(run.get("duration_seconds", 0.0))
		if time_value > 0.0:
			_compare_metric(current, "best_time", time_value, true, TIME_EPSILON, context, changes)
		elif OS.is_debug_build():
			push_warning("[StoryRecords][%s] Ignoring non-positive clear time." % stage_id)
	if _valid_number(run.get("damage_taken")):
		var damage_value := float(run.get("damage_taken", -1.0))
		if damage_value >= 0.0:
			_compare_metric(current, "lowest_damage", damage_value, true, DAMAGE_EPSILON, context, changes)
	var challenge_value := StoryMutatorsClass.reward_bonus(context.get("mutator_ids", []) as Array)
	if challenge_value > 0.0:
		_compare_metric(current, "highest_challenge", challenge_value, false, CHALLENGE_EPSILON, context, changes)
	if not current.is_empty():
		records[stage_id] = current
	return {"eligible":true, "updated_records":records, "changes":changes, "first_record":first_record, "current":current.duplicate(true), "stage_id":stage_id}

static func migrate(records_value: Variant, history_value: Variant, results_value: Variant) -> Dictionary:
	var records := sanitize_records(records_value)
	if typeof(history_value) == TYPE_ARRAY:
		var history: Array = (history_value as Array).duplicate(true)
		history.reverse()
		for run_variant in history:
			var evaluation := evaluate_run(records, run_variant)
			records = evaluation.get("updated_records", records) as Dictionary
	if typeof(results_value) == TYPE_DICTIONARY:
		for stage_variant in results_value as Dictionary:
			var stage_id := str(stage_variant)
			if not valid_stage_id(stage_id) or typeof((results_value as Dictionary)[stage_variant]) != TYPE_DICTIONARY:
				continue
			var result: Dictionary = (results_value as Dictionary)[stage_variant] as Dictionary
			if not _valid_number(result.get("best_seconds")) or float(result.get("best_seconds", 0.0)) <= 0.0:
				continue
			var legacy_run := {"context":"story", "completed":true, "stage_id":stage_id, "duration_seconds":float(result.get("best_seconds", 0.0)), "difficulty":str(result.get("difficulty", "")), "mutator_ids":[], "run_id":"", "timestamp":maxi(0, int(result.get("updated_at", 0)))}
			var evaluation := evaluate_run(records, legacy_run)
			records = evaluation.get("updated_records", records) as Dictionary
	return records

static func merge_records(local_value: Variant, remote_value: Variant) -> Dictionary:
	var merged := sanitize_records(local_value)
	var remote := sanitize_records(remote_value)
	for stage_variant in remote:
		var stage_id := str(stage_variant)
		var local_stage: Dictionary = (merged.get(stage_id, {}) as Dictionary).duplicate(true)
		var remote_stage: Dictionary = remote[stage_id] as Dictionary
		for metric in METRICS:
			if not remote_stage.has(metric):
				continue
			if not local_stage.has(metric):
				local_stage[metric] = (remote_stage[metric] as Dictionary).duplicate(true)
				continue
			var local_metric: Dictionary = local_stage[metric] as Dictionary
			var remote_metric: Dictionary = remote_stage[metric] as Dictionary
			var local_number := float(local_metric.get("value", 0.0))
			var remote_number := float(remote_metric.get("value", 0.0))
			var remote_better: bool = (remote_number > local_number + CHALLENGE_EPSILON) if metric == "highest_challenge" else (remote_number < local_number - (TIME_EPSILON if metric == "best_time" else DAMAGE_EPSILON))
			var tied := is_equal_approx(remote_number, local_number)
			if remote_better or (tied and str(local_metric.get("run_id", "")).is_empty() and not str(remote_metric.get("run_id", "")).is_empty()):
				local_stage[metric] = remote_metric.duplicate(true)
		merged[stage_id] = local_stage
	return merged

static func _compare_metric(stage_record_value: Dictionary, metric: String, value: float, lower_is_better: bool, epsilon: float, context: Dictionary, changes: Array[Dictionary]) -> void:
	var previous: Dictionary = stage_record_value.get(metric, {}) as Dictionary
	var first := previous.is_empty()
	var previous_value := float(previous.get("value", 0.0))
	var improved: bool = (first or value < previous_value - epsilon) if lower_is_better else (first or value > previous_value + epsilon)
	if not improved:
		return
	var next := context.duplicate(true)
	next["value"] = value
	stage_record_value[metric] = next
	changes.append({"record":metric, "first":first, "value":value, "previous":previous_value if not first else null, "delta":absf(previous_value - value) if not first else 0.0})

static func _run_context(run: Dictionary, stage_id: String = "") -> Dictionary:
	var difficulty := str(run.get("difficulty", ""))
	if difficulty not in DIFFICULTY_IDS:
		difficulty = ""
	var raw_mutators: Variant = run.get("mutator_ids", [])
	var requested_mutators: Array = []
	if typeof(raw_mutators) == TYPE_ARRAY:
		for mutator_variant in raw_mutators as Array:
			if typeof(mutator_variant) == TYPE_STRING and not str(mutator_variant).is_empty() and str(mutator_variant) not in requested_mutators:
				requested_mutators.append(str(mutator_variant).left(64))
				if requested_mutators.size() >= StoryMutatorsClass.MAX_ACTIVE:
					break
	var mutators := StoryMutatorsClass.sanitize_selection({}, stage_id, requested_mutators, true) if valid_stage_id(stage_id) else requested_mutators.filter(func(mutator_id: String) -> bool: return not StoryMutatorsClass.definition(mutator_id).is_empty())
	return {"difficulty":difficulty, "mutator_ids":mutators, "run_id":str(run.get("run_id", "")).left(96), "timestamp":maxi(0, int(run.get("timestamp", 0)))}

static func _sanitize_metric(value: Variant, metric: String, stage_id: String) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var raw: Dictionary = value as Dictionary
	if not _valid_number(raw.get("value")):
		return {}
	var number := float(raw.get("value", 0.0))
	if (metric == "best_time" and number <= 0.0) or (metric != "best_time" and number < 0.0) or (metric == "highest_challenge" and (number <= 0.0 or number > StoryMutatorsClass.REWARD_MULTIPLIER_CAP - 1.0 + CHALLENGE_EPSILON)):
		return {}
	var clean := _run_context(raw, stage_id)
	clean["value"] = number
	return clean

static func _valid_number(value: Variant) -> bool:
	if not (value is int or value is float):
		return false
	var number := float(value)
	return not is_nan(number) and not is_inf(number)
