extends SceneTree

const StoryMutatorsClass := preload("res://scripts/story/StoryMutators.gd")

func _init() -> void:
	_test_definitions()
	_test_unlocks_and_compatibility()
	_test_stage_restrictions()
	_test_reward_cap_and_runtime_config()
	print("Story Mutator tests passed: 15 definitions · unlocks · compatibility · restrictions · reward cap")
	quit(0)

func _test_definitions() -> void:
	assert(StoryMutatorsClass.DEFINITIONS.size() == 15)
	assert(StoryMutatorsClass.validate_definitions().is_empty())
	var ids: Array[String] = []
	for definition_variant in StoryMutatorsClass.DEFINITIONS:
		var item := definition_variant as Dictionary
		var mutator_id := str(item.get("id", ""))
		assert(not mutator_id.is_empty())
		assert(mutator_id not in ids)
		assert(not str(item.get("name", "")).is_empty())
		assert(not str(item.get("description", "")).is_empty())
		ids.append(mutator_id)

func _test_unlocks_and_compatibility() -> void:
	var new_profile := {"cleared":[]}
	assert(not StoryMutatorsClass.is_unlocked(new_profile, "glass_capy"))
	var chapter_one_profile := {"cleared":["ch1_5"]}
	assert(StoryMutatorsClass.is_unlocked(chapter_one_profile, "glass_capy"))
	assert(not StoryMutatorsClass.is_unlocked(chapter_one_profile, "frostbite"))
	var chapter_three_profile := {"cleared":["ch1_5", "ch3_5"]}
	assert(StoryMutatorsClass.is_unlocked(chapter_three_profile, "frostbite"))
	assert(not StoryMutatorsClass.is_unlocked(chapter_three_profile, "relentless"))
	var complete_profile := {"cleared":["ch1_5", "ch3_5", "ch5_5"]}
	assert(StoryMutatorsClass.selection_issue(complete_profile, "ch4_2", ["no_healing"], "scarce_recovery").contains("Incompatible"))
	var selected := StoryMutatorsClass.sanitize_selection(complete_profile, "ch4_2", ["glass_capy", "elite_hunt", "frostbite", "empowered_enemies", "glass_capy"])
	assert(selected == ["glass_capy", "elite_hunt", "frostbite"])

func _test_stage_restrictions() -> void:
	assert(not StoryMutatorsClass.stage_restriction("relentless", "ch5_1").is_empty())
	assert(not StoryMutatorsClass.stage_restriction("relentless", "ch5_3").is_empty())
	assert(not StoryMutatorsClass.stage_restriction("pressure_wave", "ch5_3").is_empty())
	assert(StoryMutatorsClass.stage_restriction("volatile_enemies", "ch4_3").is_empty())
	for stage_index in StoryStore.stage_count():
		var stage := StoryStore.stage(stage_index)
		var configured := StoryStore.configure_run(stage, "nightmare", ["glass_capy", "volatile_enemies", "corrupted_ground"], {}, true)
		assert((configured.get("mutators", []) as Array).size() <= StoryMutatorsClass.MAX_ACTIVE)
		assert(str(configured.get("difficulty", "")) == "nightmare")

func _test_reward_cap_and_runtime_config() -> void:
	var all_ids: Array[String] = []
	for definition_variant in StoryMutatorsClass.DEFINITIONS:
		all_ids.append(str((definition_variant as Dictionary).get("id", "")))
	assert(StoryMutatorsClass.reward_multiplier(all_ids) == StoryMutatorsClass.REWARD_MULTIPLIER_CAP)
	var config := StoryMutatorsClass.runtime_config("ch1_5", ["glass_capy", "heavy_armour", "no_healing"])
	assert(is_equal_approx(float(config.player_damage), 1.35))
	assert(is_equal_approx(float(config.player_max_hp), 0.65))
	assert(is_equal_approx(float(config.player_speed), 0.85))
	assert(is_equal_approx(float(config.damage_taken), 0.80))
	assert(not bool(config.healing_enabled))
	var eclipse_config := StoryMutatorsClass.runtime_config("ch5_4", ["heavy_armour", "frostbite"])
	assert(is_equal_approx(float(eclipse_config.player_speed), 0.92))
