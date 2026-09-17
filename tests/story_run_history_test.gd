extends SceneTree

const TEST_USERNAME := "__story_run_history_test__"

func _init() -> void:
	_test_empty_migration_and_persistence()
	_test_merge_cap_and_malformed_records()
	print("Story Run History tests passed: empty migration, persistence, merge, cap, malformed skip, compact size")
	quit(0)

func _record(index: int, run_id: String = "") -> Dictionary:
	return {
		"record_version":1,
		"run_id":run_id if not run_id.is_empty() else "run-%02d" % index,
		"context":"story",
		"stage_id":"ch%d_%d" % [index % 5 + 1, index % 5 + 1],
		"stage_name":"Saved Stage %d" % index,
		"chapter":index % 5 + 1,
		"difficulty":["normal", "hard", "nightmare"][index % 3],
		"timestamp":1000 + index,
		"completed":true,
		"duration_seconds":120.0 + index,
		"final_level":8,
		"mutator_ids":["glass_capy"],
		"mastery_completed":["c1s1_scout_safe"],
		"mastery_newly_earned":[],
		"skills":[{"id":"fireball", "name":"Fireball", "level":5, "evolution":"", "evolution_name":""}],
		"rings":[{"id":"ring-1", "name":"Test Ring", "attr":"skill_dmg", "value":0.12, "rarity":"rare", "tier":2}],
		"artifacts":[{"id":"artifact_infernal_heart_1", "name":"Infernal Heart", "rarity":"epic", "effects":{"skill_dmg":0.12}, "run_effects":{}}],
		"damage_summary":[{"source_id":"fireball", "damage":800.0}],
		"total_damage":800.0,
		"damage_taken":90.0,
		"healing":25.0,
		"kills":20,
		"boss_damage":250.0,
		"revives":0,
		"damage_coverage":1.0,
	}

func _test_empty_migration_and_persistence() -> void:
	assert(not StoryStore.make_story_run_id().is_empty())
	StoryStore.purge_user(TEST_USERNAME)
	StoryStore.replace_profile(TEST_USERNAME, {"cleared":["ch1_1"]})
	var migrated := StoryStore.load_profile(TEST_USERNAME)
	assert(migrated.has("story_run_history"))
	assert((migrated.story_run_history as Array).is_empty())
	migrated["story_run_history"] = [_record(1), _record(2)]
	StoryStore.replace_profile(TEST_USERNAME, migrated)
	var reloaded := StoryStore.load_profile(TEST_USERNAME)
	assert(StoryStore.story_run_history(reloaded).size() == 2)
	assert(str(StoryStore.story_run_history(reloaded)[0].run_id) == "run-02")
	StoryStore.purge_user(TEST_USERNAME)

func _test_merge_cap_and_malformed_records() -> void:
	var local: Array = []
	for index in 25:
		local.append(_record(index))
	local.append({"run_id":"broken", "completed":true})
	local.append({"run_id":"dev", "stage_id":"ch1_1", "completed":true, "context":"story_dev_test"})
	var newer_duplicate := _record(99, "run-24")
	newer_duplicate["timestamp"] = 9999
	newer_duplicate["total_damage"] = 999.0
	var merged := StoryStore.merge_story_run_history(local, [newer_duplicate])
	assert(merged.size() == StoryStore.MAX_STORY_RUN_HISTORY)
	assert(str(merged[0].run_id) == "run-24")
	assert(is_equal_approx(float(merged[0].total_damage), 999.0))
	var ids: Dictionary = {}
	for record in merged:
		assert(not ids.has(str(record.run_id)))
		ids[str(record.run_id)] = true
	assert(JSON.stringify({"story_run_history":merged}).length() < 100000)
	var profile := {"story_run_history":[]}
	var appended := StoryStore._append_story_run_profile(profile, _record(1), ["c1s1_scout_safe"])
	assert(not appended.is_empty())
	assert("c1s1_scout_safe" in (appended.mastery_newly_earned as Array))
	var practice := _record(2); practice["context"] = "boss_practice"
	assert(StoryStore._append_story_run_profile(profile, practice, []).is_empty())
