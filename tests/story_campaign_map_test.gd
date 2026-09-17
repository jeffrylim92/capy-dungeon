extends SceneTree

const CampaignMap := preload("res://scripts/story/StoryCampaignMap.gd")

func _init() -> void:
	_test_configuration()
	_test_fresh_profile()
	_test_mid_campaign_profile()
	_test_unclaimed_chapter_gate()
	_test_chapter_and_campaign_completion()
	_test_mastery_and_difficulty_display()
	_test_read_only_state_derivation()
	print("Story Campaign Map tests passed: 25 stages · fresh/mid/complete saves · Mastery · difficulty · read-only state")
	quit(0)

func _test_configuration() -> void:
	assert(CampaignMap.validate().is_empty())
	assert(StoryStore.stage_count() == 25)
	for map_width in [720.0, 1080.0, 1440.0]:
		var previous_y := -1.0
		for stage_index in StoryStore.stage_count():
			var position := CampaignMap.stage_position(stage_index, map_width, 1220.0, 180.0, 340.0)
			var half_width := 325.0 if (stage_index + 1) % 5 == 0 else 285.0
			assert(position.y > previous_y)
			assert(position.x - half_width >= 0.0)
			assert(position.x + half_width <= map_width)
			previous_y = position.y

func _test_fresh_profile() -> void:
	var profile := _profile([])
	var first := CampaignMap.stage_state(profile, 0)
	var second := CampaignMap.stage_state(profile, 1)
	assert(bool(first.unlocked))
	assert(bool(first.current))
	assert(not bool(first.cleared))
	assert(not bool(second.unlocked))
	assert(CampaignMap.current_stage_index(profile) == 0)

func _test_mid_campaign_profile() -> void:
	var cleared := _stage_ids_through(6)
	var profile := _profile(cleared)
	profile["claimed_chapters"] = [1]
	assert(CampaignMap.current_stage_index(profile) == 7)
	assert(bool(CampaignMap.stage_state(profile, 6).cleared))
	assert(bool(CampaignMap.stage_state(profile, 7).current))
	assert(not bool(CampaignMap.stage_state(profile, 8).unlocked))
	var chapter_one := CampaignMap.chapter_state(profile, 1)
	assert(bool(chapter_one.complete))
	assert(int(chapter_one.cleared) == 5)

func _test_unclaimed_chapter_gate() -> void:
	var profile := _profile(_stage_ids_through(4))
	assert(CampaignMap.current_stage_index(profile) == 4)
	assert(bool(CampaignMap.stage_state(profile, 4).cleared))
	assert(not bool(CampaignMap.stage_state(profile, 5).unlocked))
	assert(not CampaignMap.path_active(profile, 4))
	profile["claimed_chapters"] = [1]
	assert(CampaignMap.path_active(profile, 4))

func _test_chapter_and_campaign_completion() -> void:
	var chapter_profile := _profile(_stage_ids_through(14))
	chapter_profile["claimed_chapters"] = [1, 2, 3]
	assert(bool(CampaignMap.chapter_state(chapter_profile, 3).complete))
	assert(CampaignMap.current_stage_index(chapter_profile) == 15)
	var complete_profile := _profile(_stage_ids_through(24))
	complete_profile["story_complete"] = true
	assert(CampaignMap.campaign_complete(complete_profile))
	assert(CampaignMap.current_stage_index(complete_profile) == 24)
	assert(not bool(CampaignMap.stage_state(complete_profile, 24).current))

func _test_mastery_and_difficulty_display() -> void:
	var profile := _profile(["ch2_4"])
	var objectives := StoryStore.mastery_objectives("ch2_4")
	profile["mastery"] = {"ch2_4":[str((objectives[0] as Dictionary).id), str((objectives[1] as Dictionary).id)]}
	profile["difficulty_clears"] = {"ch2_4":"hard"}
	var state := CampaignMap.stage_state(profile, StoryStore.stage_index("ch2_4"))
	assert(int(state.mastery) == 2)
	assert(not bool(state.mastered))
	assert(str(state.highest_difficulty) == "HARD")
	profile["mastery"] = {"ch2_4":objectives.map(func(item: Dictionary) -> String: return str(item.id))}
	assert(bool(CampaignMap.stage_state(profile, StoryStore.stage_index("ch2_4")).mastered))
	var chapter_state := CampaignMap.chapter_state(profile, 2)
	assert(int(chapter_state.mastery) == 3)
	assert(not bool(chapter_state.mastered))
	assert(int(chapter_state.mastery_rewards_available) == 0)

func _test_read_only_state_derivation() -> void:
	var profile := _profile(_stage_ids_through(10))
	profile["difficulty_clears"] = {"ch1_5":"nightmare"}
	profile["mastery"] = {"ch1_5":["c1s5_emitter_breaker"]}
	var before := profile.duplicate(true)
	for stage_index in StoryStore.stage_count():
		CampaignMap.stage_state(profile, stage_index)
	for chapter_number in range(1, 6):
		CampaignMap.chapter_state(profile, chapter_number)
	assert(profile == before)

func _profile(cleared: Array) -> Dictionary:
	return {"cleared":cleared.duplicate(), "difficulty_clears":{}, "mastery":{}, "claimed_chapters":[], "story_complete":false}

func _stage_ids_through(last_index: int) -> Array[String]:
	var ids: Array[String] = []
	for stage_index in range(last_index + 1):
		ids.append(str(StoryStore.stage(stage_index).id))
	return ids
