extends SceneTree

func _init() -> void:
	_test_complete_configuration()
	_test_normal_is_unchanged()
	_test_unlocks_and_monotonic_merge()
	_test_mastery_is_shared()
	print("Story difficulty tests passed: 25 stages · Normal parity · unlock chain · monotonic merge")
	quit(0)

func _test_complete_configuration() -> void:
	assert(StoryStore.STORY_DIFFICULTY_IDS == ["normal", "hard", "nightmare"])
	assert(StoryStore.STAGE_DIFFICULTY_RULES.size() == StoryStore.stage_count())
	for stage_index in StoryStore.stage_count():
		var stage_id := str(StoryStore.stage(stage_index).get("id", ""))
		assert(StoryStore.STAGE_DIFFICULTY_RULES.has(stage_id))
		for difficulty_id in ["hard", "nightmare"]:
			var config := StoryStore.difficulty_config(stage_id, difficulty_id)
			assert(not str(config.get("summary", "")).is_empty())
			assert(float(config.get("reinforcement_interval", 0.0)) > 0.0)
			assert(int(config.get("reinforcement_count", 0)) > 0)
		assert(float(StoryStore.difficulty_config(stage_id, "hard").enemy_hp) < float(StoryStore.difficulty_config(stage_id, "nightmare").enemy_hp))
		assert(float(StoryStore.difficulty_config(stage_id, "hard").enemy_damage) < float(StoryStore.difficulty_config(stage_id, "nightmare").enemy_damage))

func _test_normal_is_unchanged() -> void:
	for stage_index in StoryStore.stage_count():
		var original := StoryStore.stage(stage_index)
		var normal := StoryStore.apply_difficulty(original, "normal")
		assert(str(normal.difficulty) == "normal")
		assert(float(normal.enemy_hp) == float(original.enemy_hp))
		assert(float(normal.enemy_damage) == float(original.enemy_damage))
		assert(float(normal.enemy_speed) == float(original.enemy_speed))
		assert(str(normal.objective) == str(original.objective))
		assert((normal.objective_config as Dictionary) == (original.objective_config as Dictionary))

func _test_unlocks_and_monotonic_merge() -> void:
	var new_profile := {"cleared":[], "difficulty_clears":{}}
	assert(StoryStore.difficulty_unlocked(new_profile, "ch1_1", "normal"))
	assert(not StoryStore.difficulty_unlocked(new_profile, "ch1_1", "hard"))
	assert(not StoryStore.difficulty_unlocked(new_profile, "ch1_1", "nightmare"))
	assert(StoryStore.merge_difficulty_clear_profile(new_profile, "ch1_1", "normal"))
	assert(StoryStore.difficulty_unlocked(new_profile, "ch1_1", "hard"))
	assert(not StoryStore.difficulty_unlocked(new_profile, "ch1_1", "nightmare"))
	assert(StoryStore.merge_difficulty_clear_profile(new_profile, "ch1_1", "hard"))
	assert(StoryStore.difficulty_unlocked(new_profile, "ch1_1", "nightmare"))
	assert(StoryStore.merge_difficulty_clear_profile(new_profile, "ch1_1", "nightmare"))
	assert(not StoryStore.merge_difficulty_clear_profile(new_profile, "ch1_1", "normal"))
	assert(not StoryStore.merge_difficulty_clear_profile(new_profile, "ch1_1", "hard"))
	assert(StoryStore.highest_cleared_difficulty(new_profile, "ch1_1") == 2)
	var legacy_profile := {"cleared":["ch2_3"]}
	assert(StoryStore.highest_cleared_difficulty(legacy_profile, "ch2_3") == 0)
	assert(StoryStore.difficulty_unlocked(legacy_profile, "ch2_3", "hard"))

func _test_mastery_is_shared() -> void:
	var profile := {"cleared":["ch1_1"], "difficulty_clears":{"ch1_1":"hard"}, "mastery":{}}
	var objectives: Array = StoryStore.mastery_objectives("ch1_1")
	var normal_star := str((objectives[0] as Dictionary).id)
	var nightmare_star := str((objectives[1] as Dictionary).id)
	assert(StoryStore.merge_mastery_profile(profile, "ch1_1", [normal_star]).size() == 1)
	assert(StoryStore.merge_difficulty_clear_profile(profile, "ch1_1", "nightmare"))
	assert(StoryStore.merge_mastery_profile(profile, "ch1_1", [nightmare_star]).size() == 1)
	assert(StoryStore.stage_mastery(profile, "ch1_1") == 2)
