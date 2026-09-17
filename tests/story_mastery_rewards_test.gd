extends SceneTree

const TEST_USER := "__chapter_mastery_rewards_test__"

func _init() -> void:
	StoryStore.purge_user(TEST_USER)
	_test_configuration_and_thresholds()
	_test_existing_save_migration()
	_test_independent_one_time_claims()
	StoryStore.purge_user(TEST_USER)
	print("Story Mastery Reward tests passed: 4/7/12/15 stars · migration · independent one-time claims")
	quit(0)

func _test_configuration_and_thresholds() -> void:
	assert(StoryStore.validate_mastery_rewards().is_empty())
	assert(StoryStore.CHAPTER_MASTERY_REWARDS.size() == 15)
	var four_stars := _chapter_profile(1, 4)
	assert(StoryStore.available_mastery_rewards(four_stars, 1).is_empty())
	var seven_stars := _chapter_profile(1, 7)
	assert(_available_thresholds(seven_stars, 1) == [5])
	seven_stars["difficulty_clears"] = {"ch1_1":"nightmare"}
	seven_stars["results"] = {"ch1_1":{"difficulty":"nightmare", "mutators":["glass_capy", "elite_hunt"]}}
	assert(_available_thresholds(seven_stars, 1) == [5])
	assert(int(StoryStore.mastery_reward("ch1_mastery_5").get("materials", 0)) == 1)
	var twelve_stars := _chapter_profile(1, 12)
	assert(_available_thresholds(twelve_stars, 1) == [5, 10])
	var fifteen_stars := _chapter_profile(1, 15)
	assert(_available_thresholds(fifteen_stars, 1) == [5, 10, 15])
	assert(StoryStore.chapter_mastery(fifteen_stars, 1) == 15)

func _test_existing_save_migration() -> void:
	var old_profile := _chapter_profile(2, 12)
	old_profile.erase("mastery_rewards_claimed")
	StoryStore.replace_profile(TEST_USER, old_profile)
	var migrated := StoryStore.load_profile(TEST_USER)
	assert((migrated.get("mastery_rewards_claimed", []) as Array).is_empty())
	assert(_available_thresholds(migrated, 2) == [5, 10])

func _test_independent_one_time_claims() -> void:
	var profile := _chapter_profile(3, 15)
	profile["materials"] = 10
	StoryStore.replace_profile(TEST_USER, profile)
	var ten_star := StoryStore.claim_mastery_reward(TEST_USER, 3, "ch3_mastery_10")
	assert(bool(ten_star.get("ok", false)))
	assert(int(ten_star.get("materials", 0)) == 2)
	assert(int(StoryStore.load_profile(TEST_USER).get("materials", 0)) == 12)
	var duplicate := StoryStore.claim_mastery_reward(TEST_USER, 3, "ch3_mastery_10")
	assert(not bool(duplicate.get("ok", false)))
	assert(int(StoryStore.load_profile(TEST_USER).get("materials", 0)) == 12)
	assert(bool(StoryStore.claim_mastery_reward(TEST_USER, 3, "ch3_mastery_5").get("ok", false)))
	assert(bool(StoryStore.claim_mastery_reward(TEST_USER, 3, "ch3_mastery_15").get("ok", false)))
	var reloaded := StoryStore.load_profile(TEST_USER)
	assert(int(reloaded.get("materials", 0)) == 17)
	assert((reloaded.get("mastery_rewards_claimed", []) as Array).size() == 3)
	assert(StoryStore.available_mastery_rewards(reloaded, 3).is_empty())
	assert(not bool(StoryStore.claim_mastery_reward(TEST_USER, 3, "ch3_mastery_5").get("ok", false)))
	assert(int(StoryStore.load_profile(TEST_USER).get("materials", 0)) == 17)

func _chapter_profile(chapter_number: int, stars: int) -> Dictionary:
	var profile := {"cleared":[], "difficulty_clears":{}, "claimed_chapters":[], "mastery_rewards_claimed":[], "mastery":{}, "materials":0, "story_complete":false}
	var mastery: Dictionary = profile["mastery"] as Dictionary
	var remaining := clampi(stars, 0, 15)
	for stage_number in range(1, 6):
		var stage_id := "ch%d_%d" % [chapter_number, stage_number]
		var earned: Array[String] = []
		for objective_variant in StoryStore.mastery_objectives(stage_id):
			if remaining <= 0:
				break
			earned.append(str((objective_variant as Dictionary).get("id", "")))
			remaining -= 1
		mastery[stage_id] = earned
	profile["mastery"] = mastery
	return profile

func _available_thresholds(profile: Dictionary, chapter_number: int) -> Array[int]:
	var thresholds: Array[int] = []
	for reward in StoryStore.available_mastery_rewards(profile, chapter_number):
		thresholds.append(int(reward.get("threshold", 0)))
	return thresholds
