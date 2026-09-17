extends SceneTree

const BuildClass := preload("res://scripts/story/StoryBuildCapabilities.gd")

func _init() -> void:
	_test_metadata_and_neutral_profile()
	_test_elemental_and_category_profiles()
	_test_equipment_and_mutators()
	_test_stage_caps_and_puzzle_neutrality()
	print("Story Build Capability tests passed: tags · equipment · mutators · 25-stage caps · puzzle neutrality")
	quit(0)

func _test_metadata_and_neutral_profile() -> void:
	assert(BuildClass.validate().is_empty())
	var neutral := BuildClass.calculate([])
	for capability in BuildClass.CAPABILITIES:
		assert(is_zero_approx(BuildClass.score(neutral, capability)))
	for entry in BuildClass.SYNERGIES:
		assert(float(entry.get("cap", 0.0)) <= 0.20)
		assert(float(BuildClass.synergy(str(entry.stage), str(entry.mechanic), neutral).bonus) == 0.0)

func _test_elemental_and_category_profiles() -> void:
	var fire := BuildClass.calculate([{"id":"fireball", "level":5}])
	assert(BuildClass.tier(fire, "fire") == "strong")
	assert(BuildClass.score(fire, "projectile") > 0.0)
	var brazier := BuildClass.synergy("ch2_1", "brazier_decay", fire)
	assert(float(brazier.bonus) > 0.05 and float(brazier.bonus) <= 0.10)

	var ice := BuildClass.calculate([{"id":"blizzard", "level":5, "evolution":"absolute_zero"}])
	assert(BuildClass.score(ice, "ice") >= 0.90)
	assert(float(BuildClass.synergy("ch4_1", "mining_heat", ice).bonus) <= 0.10)

	var lightning := BuildClass.calculate([{"id":"thunder_god_pulse", "level":5}])
	assert(float(BuildClass.synergy("ch4_5", "regulator_channel", lightning).bonus) > 0.05)

	var fusion := BuildClass.calculate([{"id":"toxic_lightning", "level":5}])
	assert(BuildClass.score(fusion, "poison") > 0.0)
	assert(BuildClass.score(fusion, "lightning") > 0.0)
	assert(BuildClass.score(fusion, "aoe") > 0.0)

	var companion := BuildClass.calculate([{"id":"hawk_companion", "level":3}])
	assert(BuildClass.score(companion, "companion") > 0.0)
	assert(BuildClass.score(companion, "projectile") > 0.0)

func _test_equipment_and_mutators() -> void:
	var equipment := BuildClass.calculate([], {"move_speed":30.0, "projectile_spd":0.18, "aoe_radius":0.12, "regen":4.0, "max_hp_pct":0.16}, 14)
	assert(BuildClass.score(equipment, "mobility") > 0.0)
	assert(BuildClass.score(equipment, "projectile") > 0.0)
	assert(BuildClass.score(equipment, "aoe") > 0.0)
	assert(BuildClass.score(equipment, "sustain") > 0.0)
	assert(BuildClass.score(equipment, "defence") > 0.0)

	var glass := BuildClass.calculate([], {"skill_dmg":0.50}, 10, {"player_damage":1.35})
	assert(BuildClass.score(glass, "fire") == 0.0)
	assert(BuildClass.score(glass, "projectile") == 0.0)
	var heavy := BuildClass.calculate([], {}, 10, {"damage_taken":0.80})
	assert(BuildClass.score(heavy, "defence") > 0.0)
	var no_healing := BuildClass.calculate([{"id":"regen", "level":3}], {"regen":5.0}, 10, {"healing_enabled":false})
	assert(BuildClass.score(no_healing, "sustain") == 0.0)
	for profile_id in BuildClass.DEV_PROFILE_IDS:
		if profile_id == "current": continue
		var dev_profile := BuildClass.dev_profile(profile_id)
		assert(not dev_profile.is_empty())
	assert(BuildClass.score(BuildClass.dev_profile("projectile_aoe"), "projectile") == 1.0)
	assert(BuildClass.score(BuildClass.dev_profile("projectile_aoe"), "aoe") == 1.0)

func _test_stage_caps_and_puzzle_neutrality() -> void:
	var extreme := BuildClass.calculate([
		{"id":"inferno_thunder", "level":5, "evolution":"overdrive"},
		{"id":"frozen_lance", "level":5, "evolution":"ascendant"},
		{"id":"toxic_lightning", "level":5},
		{"id":"regen", "level":3},
	], {"move_speed":30.0, "max_hp_pct":0.25, "projectile_spd":0.20, "aoe_radius":0.15}, 16, {"damage_taken":0.80})
	for entry in BuildClass.SYNERGIES:
		var result := BuildClass.synergy(str(entry.stage), str(entry.mechanic), extreme)
		assert(float(result.bonus) <= float(entry.cap))
		assert(float(result.bonus) <= 0.20)
	for puzzle_stage in ["ch2_4", "ch5_3"]:
		assert(BuildClass.stage_synergies(puzzle_stage).is_empty())
	# Runes may reduce a wrong-answer consequence, but never expose correctness.
	var rune_entries := BuildClass.stage_synergies("ch2_3")
	assert(rune_entries.size() == 1)
	assert(str(rune_entries[0].mechanic) == "wrong_rune_recovery")
	for chapter in range(1, 6):
		for stage in range(1, 6):
			var stage_id := "ch%d_%d" % [chapter, stage]
			for line in BuildClass.stage_display_lines(stage_id):
				assert(not line.to_lower().contains("required"))
