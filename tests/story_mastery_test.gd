extends SceneTree

func _init() -> void:
	_test_definitions()
	_test_merge_and_totals()
	_test_reward_configuration()
	print("Story Mastery tests passed: 25 stages, 75 unique objectives, 15 reward milestones")
	quit(0)

func _test_definitions() -> void:
	assert(StoryStore.MASTERY_OBJECTIVES.size() == 25)
	var ids: Dictionary = {}
	for stage_index in StoryStore.stage_count():
		var stage_id := str(StoryStore.stage(stage_index).get("id", ""))
		var objectives: Array = StoryStore.mastery_objectives(stage_id)
		assert(objectives.size() == 3)
		for objective_variant in objectives:
			var objective: Dictionary = objective_variant as Dictionary
			var objective_id := str(objective.get("id", ""))
			assert(not objective_id.is_empty())
			assert(not str(objective.get("title", "")).is_empty())
			assert(not str(objective.get("description", "")).is_empty())
			assert(not ids.has(objective_id))
			ids[objective_id] = true
	assert(ids.size() == 75)

func _test_merge_and_totals() -> void:
	var old_profile := {"cleared":["ch1_1"]}
	assert(StoryStore.stage_mastery(old_profile, "ch1_1") == 0)
	assert(StoryStore.chapter_mastery(old_profile, 1) == 0)
	assert(StoryStore.campaign_mastery(old_profile) == 0)
	var profile := {"cleared":["ch1_1"], "mastery":{}}
	var objectives: Array = StoryStore.mastery_objectives("ch1_1")
	var first_id := str((objectives[0] as Dictionary).id)
	var second_id := str((objectives[1] as Dictionary).id)
	var third_id := str((objectives[2] as Dictionary).id)
	assert(StoryStore.merge_mastery_profile(profile, "ch1_1", [first_id]).size() == 1)
	assert(StoryStore.merge_mastery_profile(profile, "ch1_1", [second_id]).size() == 1)
	assert(StoryStore.stage_mastery(profile, "ch1_1") == 2)
	assert(StoryStore.merge_mastery_profile(profile, "ch1_1", [first_id]).is_empty())
	assert(StoryStore.stage_mastery(profile, "ch1_1") == 2)
	assert(StoryStore.merge_mastery_profile(profile, "ch1_1", [third_id]).size() == 1)
	assert(StoryStore.stage_mastery(profile, "ch1_1") == 3)
	assert(StoryStore.merge_mastery_profile(profile, "ch1_1", ["invalid_mastery_id"]).is_empty())
	assert(StoryStore.stage_mastery(profile, "ch1_1") == 3)
	var arbitrary_profile := {"mastery":{"ch1_1":[first_id, third_id]}}
	assert(StoryStore.stage_mastery(arbitrary_profile, "ch1_1") == 2)
	assert(second_id not in StoryStore.earned_mastery(arbitrary_profile, "ch1_1"))
	var malformed_profile := {"mastery":{"ch1_1":[first_id, first_id, "invalid_mastery_id"]}}
	assert(StoryStore.stage_mastery(malformed_profile, "ch1_1") == 1)
	for chapter_number in range(1, 6):
		for stage_number in range(1, 6):
			var stage_id := "ch%d_%d" % [chapter_number, stage_number]
			var all_ids: Array[String] = []
			for objective_variant in StoryStore.mastery_objectives(stage_id): all_ids.append(str((objective_variant as Dictionary).id))
			StoryStore.merge_mastery_profile(profile, stage_id, all_ids)
	assert(StoryStore.chapter_mastery(profile, 1) == 15)
	assert(StoryStore.campaign_mastery(profile) == 75)

func _test_reward_configuration() -> void:
	assert(StoryStore.validate_mastery_rewards().is_empty())
	assert(StoryStore.CHAPTER_MASTERY_REWARDS.size() == 15)
	for chapter_number in range(1, 6):
		var thresholds: Array[int] = []
		for reward in StoryStore.chapter_mastery_rewards(chapter_number):
			thresholds.append(int(reward.get("threshold", 0)))
		assert(thresholds == [5, 10, 15])
