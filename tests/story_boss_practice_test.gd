extends SceneTree

const PracticeClass := preload("res://scripts/story/StoryBossPractice.gd")

func _init() -> void:
	_test_roster_and_spoiler_unlocks()
	_test_difficulty_clear_access()
	_test_configuration_isolation()
	_test_retry_reconstruction()
	_test_phase_contracts()
	_test_brew_presets()
	print("Story Boss Practice tests passed: roster · unlocks · difficulty clears · isolation · 20 retry configs · phases · brew presets")
	quit(0)

func _test_roster_and_spoiler_unlocks() -> void:
	assert(PracticeClass.BOSS_STAGE_IDS == ["ch1_5", "ch2_5", "ch3_5", "ch4_5", "ch5_5"])
	var profile := {"cleared":["ch1_5", "ch2_5"]}
	assert(PracticeClass.unlocked(profile, "ch1_5"))
	assert(not PracticeClass.unlocked(profile, "ch3_5"))
	assert(PracticeClass.unlocked(profile, "ch3_5", true))
	assert(not PracticeClass.is_boss_stage("ch2_4"))

func _test_difficulty_clear_access() -> void:
	var profile := {"cleared":["ch2_5"], "difficulty_clears":{"ch2_5":"hard"}}
	assert(PracticeClass.difficulty_available(profile, "ch2_5", "normal"))
	assert(PracticeClass.difficulty_available(profile, "ch2_5", "hard"))
	assert(not PracticeClass.difficulty_available(profile, "ch2_5", "nightmare"))
	assert(PracticeClass.difficulty_available({}, "ch2_5", "nightmare", true))

func _test_configuration_isolation() -> void:
	var profile := {"cleared":["ch5_5"], "difficulty_clears":{"ch5_5":"normal"}, "mastery":{"ch5_5":["existing"]}, "materials":17}
	var before := profile.duplicate(true)
	var configured := PracticeClass.configure(StoryStore.stage(24), "normal", [], profile, "desperation", "stable")
	assert(profile == before)
	assert(str(configured.get("run_context", "")) == "boss_practice")
	assert(str(configured.get("practice_phase", "")) == "desperation")
	assert(bool(configured.get("practice_rewards_disabled", false)))
	assert(not PracticeClass.progression_allowed(str(configured.get("run_context", ""))))
	assert(PracticeClass.progression_allowed("story"))
	assert(PracticeClass.configure(StoryStore.stage(24), "normal", [], {}, "full").is_empty())
	assert(PracticeClass.configure(StoryStore.stage(24), "hard", [], profile, "full").is_empty())

func _test_phase_contracts() -> void:
	for stage_id in PracticeClass.BOSS_STAGE_IDS:
		var seen: Dictionary = {}
		for phase_variant in PracticeClass.phases(stage_id):
			var phase_id := str((phase_variant as Dictionary).get("id", ""))
			assert(not phase_id.is_empty())
			assert(not seen.has(phase_id))
			seen[phase_id] = true
		assert(seen.has("full"))
	assert(PracticeClass.phase_complete("ch1_5", "emitter_barrage", {"barrage_phases_completed":3}))
	assert(PracticeClass.phase_complete("ch2_5", "armour_systems", {"crystals_broken":3}))
	assert(PracticeClass.phase_complete("ch5_5", "abyss_crown", {"crown_destroyed":true}))
	assert(not PracticeClass.phase_complete("ch5_5", "abyss_crown", {"crown_destroyed":false}))

func _test_retry_reconstruction() -> void:
	var profile := {"cleared":["ch4_5"], "difficulty_clears":{"ch4_5":"nightmare"}, "mastery":{"ch4_5":["keep"]}, "materials":29}
	var before := profile.duplicate(true)
	for retry_index in 20:
		var configured := PracticeClass.configure(StoryStore.stage(19), "nightmare", [], profile, "shutdown_pressure")
		assert(str(configured.get("run_context", "")) == "boss_practice", str(retry_index))
		assert(str(configured.get("practice_phase", "")) == "shutdown_pressure", str(retry_index))
		assert(profile == before, str(retry_index))

func _test_brew_presets() -> void:
	assert(PracticeClass.brew_purity("volatile") == 45.0)
	assert(PracticeClass.brew_purity("stable") == 65.0)
	assert(PracticeClass.brew_purity("pure") == 85.0)
