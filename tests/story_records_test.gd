extends SceneTree

const StoryRecordsClass := preload("res://scripts/story/StoryRecords.gd")
const StoryRunPresentationClass := preload("res://scripts/story/StoryRunPresentation.gd")
const TEST_USERNAME := "__story_records_test__"

func _init() -> void:
	_test_record_comparisons()
	_test_isolation_and_all_stages()
	_test_migration_validation_and_merge()
	_test_store_transaction_and_pruning()
	print("Story Records tests passed: comparisons, epsilon ties, zero damage, multi-record, 25 stages, isolation, migration, validation, merge, persistence, history pruning")
	quit(0)

func _run_record(stage_id: String, run_id: String, time: float, damage: float, mutators: Array = [], difficulty: String = "normal", context: String = "story", completed: bool = true, timestamp: int = 1000) -> Dictionary:
	return {
		"record_version":1, "run_id":run_id, "context":context, "stage_id":stage_id,
		"stage_name":stage_id, "chapter":int(stage_id.substr(2, 1)), "difficulty":difficulty,
		"timestamp":timestamp, "completed":completed, "duration_seconds":time, "final_level":5,
		"mutator_ids":mutators.duplicate(), "challenge_score":StoryMutators.reward_bonus(mutators),
		"mastery_completed":[], "mastery_newly_earned":[], "skills":[], "rings":[], "artifacts":[],
		"damage_summary":[], "total_damage":100.0, "damage_taken":damage, "healing":0.0,
		"kills":1, "boss_damage":0.0, "revives":0, "damage_coverage":1.0,
	}

func _test_record_comparisons() -> void:
	var first := StoryRecordsClass.evaluate_run({}, _run_record("ch1_1", "first", 100.0, 100.0, ["glass_capy"]))
	assert(bool(first.eligible))
	assert(bool(first.first_record))
	assert((first.changes as Array).size() == 3)
	assert(not StoryRunPresentationClass.personal_record_comparison(first).contains("NEW BEST"))
	var records: Dictionary = first.updated_records
	assert(is_equal_approx(float(records.ch1_1.best_time.value), 100.0))
	assert(is_equal_approx(float(records.ch1_1.lowest_damage.value), 100.0))
	assert(is_equal_approx(float(records.ch1_1.highest_challenge.value), 0.20))
	var ties := StoryRecordsClass.evaluate_run(records, _run_record("ch1_1", "ties", 99.995, 99.995, ["glass_capy"]))
	assert((ties.changes as Array).is_empty())
	var worse := StoryRecordsClass.evaluate_run(records, _run_record("ch1_1", "worse", 120.0, 150.0, []))
	assert((worse.changes as Array).is_empty())
	var multiple := StoryRecordsClass.evaluate_run(records, _run_record("ch1_1", "multiple", 80.0, 40.0, ["glass_capy", "no_healing"], "hard"))
	assert((multiple.changes as Array).size() == 3)
	assert(StoryRunPresentationClass.record_result_text(multiple).begins_with("NEW RECORDS"))
	assert(StoryRunPresentationClass.personal_record_comparison(multiple).count("NEW BEST") == 3)
	records = multiple.updated_records
	var perfect := StoryRecordsClass.evaluate_run(records, _run_record("ch1_1", "perfect", 90.0, 0.0, ["glass_capy"]))
	assert((perfect.changes as Array).size() == 1)
	assert(str((perfect.changes as Array)[0].record) == "lowest_damage")
	assert(StoryRunPresentationClass.record_result_text(perfect).contains("PERFECT CLEAR"))
	var repeated_zero := StoryRecordsClass.evaluate_run(perfect.updated_records, _run_record("ch1_1", "zero-again", 90.0, 0.0, []))
	assert((repeated_zero.changes as Array).is_empty())
	var fake_challenge := _run_record("ch1_1", "fake", 200.0, 200.0)
	fake_challenge["challenge_score"] = 1.0
	var fake_evaluation := StoryRecordsClass.evaluate_run({}, fake_challenge)
	assert(not (fake_evaluation.current as Dictionary).has("highest_challenge"))

func _test_isolation_and_all_stages() -> void:
	for context in ["story_dev_test", "boss_practice", "dungeon"]:
		var rejected := StoryRecordsClass.evaluate_run({}, _run_record("ch1_1", context, 50.0, 0.0, [], "normal", context))
		assert(not bool(rejected.eligible))
		assert((rejected.updated_records as Dictionary).is_empty())
	var failed := StoryRecordsClass.evaluate_run({}, _run_record("ch1_1", "failed", 50.0, 0.0, [], "normal", "story", false))
	assert(not bool(failed.eligible))
	var retry := StoryRecordsClass.evaluate_run(failed.updated_records, _run_record("ch1_1", "retry-success", 65.0, 25.0, ["glass_capy", "no_healing"]))
	assert(bool(retry.eligible))
	assert(is_equal_approx(float(retry.current.highest_challenge.value), 0.50))
	assert(str(retry.current.highest_challenge.run_id) == "retry-success")
	var records: Dictionary = {}
	for chapter in range(1, 6):
		for stage in range(1, 6):
			var stage_id := "ch%d_%d" % [chapter, stage]
			var evaluation := StoryRecordsClass.evaluate_run(records, _run_record(stage_id, stage_id, 100.0 + stage, float(chapter * stage)))
			records = evaluation.updated_records
	assert(records.size() == 25)
	assert(StoryRecordsClass.sanitize_records(records).size() == 25)

func _test_migration_validation_and_merge() -> void:
	var history := [_run_record("ch2_2", "old", 140.0, 300.0), _run_record("ch2_2", "new", 120.0, 350.0, ["no_healing"], "hard", "story", true, 2000)]
	var migrated := StoryRecordsClass.migrate({}, history, {"ch3_3":{"best_seconds":95.5, "difficulty":"nightmare", "updated_at":3000}})
	assert(is_equal_approx(float(migrated.ch2_2.best_time.value), 120.0))
	assert(is_equal_approx(float(migrated.ch2_2.lowest_damage.value), 300.0))
	assert(is_equal_approx(float(migrated.ch3_3.best_time.value), 95.5))
	assert(not (migrated.ch3_3 as Dictionary).has("lowest_damage"))
	assert(StoryRecordsClass.migrate({}, [], {"ch5_5":{"latest_seconds":40.0}}).is_empty())
	var history_without_damage := _run_record("ch1_4", "missing-damage", 88.0, 10.0)
	history_without_damage.erase("damage_taken")
	var sanitized_without_damage := StoryStore._sanitize_run_record(history_without_damage)
	assert(not sanitized_without_damage.has("damage_taken"))
	assert(not (StoryRecordsClass.migrate({}, [sanitized_without_damage], {})["ch1_4"] as Dictionary).has("lowest_damage"))
	assert(StoryRecordsClass.migrate(migrated, history, {"ch3_3":{"best_seconds":95.5}}) == migrated)
	var corrupt := {
		"ch1_1":{"best_time":{"value":-1.0}, "lowest_damage":{"value":NAN}, "highest_challenge":{"value":INF}},
		"ch9_9":{"best_time":{"value":1.0}}, "ch1_2":"bad",
		"ch1_3":{"best_time":{"value":75.0, "difficulty":"impossible", "mutator_ids":["a", "a", "b", "c", "d"], "run_id":"ok", "timestamp":-4}},
	}
	var clean := StoryRecordsClass.sanitize_records(corrupt)
	assert(clean.size() == 1)
	assert(str(clean.ch1_3.best_time.difficulty).is_empty())
	assert((clean.ch1_3.best_time.mutator_ids as Array).is_empty())
	assert(int(clean.ch1_3.best_time.timestamp) == 0)
	var local: Dictionary = StoryRecordsClass.evaluate_run({}, _run_record("ch4_4", "local", 100.0, 100.0, ["glass_capy"])).updated_records
	var remote: Dictionary = StoryRecordsClass.evaluate_run({}, _run_record("ch4_4", "remote", 90.0, 120.0, ["no_healing"])).updated_records
	var merged := StoryRecordsClass.merge_records(local, remote)
	assert(str(merged.ch4_4.best_time.run_id) == "remote")
	assert(str(merged.ch4_4.lowest_damage.run_id) == "local")
	assert(str(merged.ch4_4.highest_challenge.run_id) == "remote")

func _test_store_transaction_and_pruning() -> void:
	StoryStore.purge_user(TEST_USERNAME)
	ProgressionStore.purge_user(TEST_USERNAME)
	StoryStore.replace_profile(TEST_USERNAME, {"cleared":["ch2_3"], "results":{"ch2_3":{"best_seconds":77.25, "difficulty":"hard", "updated_at":900}}})
	var migrated_profile := StoryStore.load_profile(TEST_USERNAME)
	assert(is_equal_approx(float(StoryStore.personal_record(migrated_profile, "ch2_3").best_time.value), 77.25))
	assert(not StoryStore.personal_record(migrated_profile, "ch2_3").has("lowest_damage"))
	assert(StoryStore.load_profile(TEST_USERNAME).story_records == migrated_profile.story_records)
	StoryStore.purge_user(TEST_USERNAME)
	StoryStore.replace_profile(TEST_USERNAME, {"cleared":["ch1_5"], "difficulty_clears":{"ch1_5":"normal"}, "mastery":{}})
	var first_result := StoryStore.record_clear(TEST_USERNAME, "ch1_1", {"elapsed":100.0, "kills":1, "level":5, "difficulty":"normal", "mutators":[], "mastery_earned":[], "run_record":_run_record("ch1_1", "store-first", 100.0, 80.0)})
	assert(bool((first_result.record_evaluation as Dictionary).eligible))
	var persisted := StoryStore.load_profile(TEST_USERNAME)
	assert(is_equal_approx(float(StoryStore.personal_record(persisted, "ch1_1").best_time.value), 100.0))
	var second_result := StoryStore.record_clear(TEST_USERNAME, "ch1_1", {"elapsed":90.0, "kills":1, "level":5, "difficulty":"hard", "mutators":["glass_capy"], "mastery_earned":[], "run_record":_run_record("ch1_1", "store-second", 90.0, 70.0, ["glass_capy"], "hard")})
	assert((second_result.record_evaluation.changes as Array).size() == 3)
	persisted = StoryStore.load_profile(TEST_USERNAME)
	assert(StoryStore.highest_cleared_difficulty_name(persisted, "ch1_1") == "Hard")
	var history: Array = []
	for index in 25:
		history.append(_run_record("ch1_1", "new-%d" % index, 200.0 + index, 200.0, [], "normal", "story", true, 5000 + index))
	persisted["story_run_history"] = StoryStore.merge_story_run_history(history, [])
	StoryStore.replace_profile(TEST_USERNAME, persisted)
	var reloaded := StoryStore.load_profile(TEST_USERNAME)
	assert(StoryStore.story_run_history(reloaded).size() == StoryStore.MAX_STORY_RUN_HISTORY)
	assert(StoryStore.personal_record_run(reloaded, "store-second").is_empty())
	assert(str(StoryStore.personal_record(reloaded, "ch1_1").best_time.run_id) == "store-second")
	StoryStore.purge_user(TEST_USERNAME)
	ProgressionStore.purge_user(TEST_USERNAME)
