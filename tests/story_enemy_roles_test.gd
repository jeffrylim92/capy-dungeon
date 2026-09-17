extends SceneTree

const RolesClass := preload("res://scripts/story/StoryEnemyRoles.gd")

func _init() -> void:
	_test_roster_metadata()
	_test_all_stage_profiles_and_budgets()
	_test_story_target_allowlist()
	_test_role_combination_safety()
	_test_long_running_caps()
	print("Story Enemy Role tests passed: metadata · 25 stages · targeting · combinations · stable caps")
	quit(0)

func _test_roster_metadata() -> void:
	assert(RolesClass.validate().is_empty())
	assert(RolesClass.ROLES.size() == 10)
	assert(RolesClass.primary_role("normal") == "chaser")
	assert(RolesClass.primary_role("normal_tank") == "tank")
	assert(RolesClass.primary_role("normal_fast") == "charger")
	assert(RolesClass.primary_role("role_zoner") == "zoner")
	assert(RolesClass.primary_role("role_sniper") == "sniper")
	assert(RolesClass.primary_role("role_support") == "support")
	assert(RolesClass.primary_role("role_controller") == "controller")
	assert(RolesClass.primary_role("role_summoner") == "summoner")
	assert(RolesClass.roles_for("normal_tank", "c2_jailer_1") == ["disruptor", "controller"])
	assert(RolesClass.roles_for("normal_fast", "c4_ore_thief") == ["thief"])
	assert(RolesClass.roles_for("normal_tank", "c4_repair_drone") == ["support"])
	# Boss kinds never enter generic role composition.
	assert(RolesClass.roles_for("abyss_king_boss", "abyss_king").is_empty())

func _test_all_stage_profiles_and_budgets() -> void:
	assert(RolesClass.STAGE_PROFILES.size() == 25)
	for chapter in range(1, 6):
		for stage in range(1, 6):
			var stage_id := "ch%d_%d" % [chapter, stage]
			assert(not RolesClass.stage_profile(stage_id).is_empty())
			for rank in 3:
				for rotation in 8:
					var kinds := RolesClass.composition(stage_id, rank, 12, rotation)
					assert(kinds.size() == 12)
					var complex_cost := 0
					for kind in kinds:
						var role := RolesClass.primary_role(str(kind))
						if role != "chaser":
							complex_cost += int(RolesClass.ROLE_COSTS.get(role, 0))
					assert(complex_cost <= [2, 4, 6][rank])
	assert("summoner" not in RolesClass.stage_roles("ch4_4", 1))
	assert("summoner" in RolesClass.stage_roles("ch4_4", 2))
	assert(RolesClass.stage_roles("ch1_5", 2).is_empty())
	assert(RolesClass.stage_roles("ch5_3", 2).is_empty())

func _test_story_target_allowlist() -> void:
	assert(RolesClass.can_target_story_prop("ch1_2", "disruptor", "shrine"))
	assert(not RolesClass.can_target_story_prop("ch1_2", "chaser", "shrine"))
	assert(RolesClass.can_target_story_prop("ch4_1", "thief", "c4_ore_bag"))
	assert(not RolesClass.can_target_story_prop("ch4_1", "thief", "c4_mining_cart"))
	assert(RolesClass.can_target_story_prop("ch5_2", "disruptor", "released_soul"))
	for protected_kind in ["scout", "antidote_vial", "c4_golem", "regulator"]:
		assert(not RolesClass.can_target_story_prop("ch3_4", "zoner", protected_kind))

func _test_role_combination_safety() -> void:
	assert(RolesClass.complexity(["chaser", "sniper"]) == 3)
	assert(RolesClass.complexity(["tank", "support"]) == 3)
	assert(RolesClass.complexity(["zoner", "charger"]) == 4)
	assert(RolesClass.complexity(["controller", "sniper"]) == 4)
	assert(RolesClass.complexity(["thief", "chaser"]) == 3)
	assert(RolesClass.complexity(["disruptor", "chaser"]) == 3)
	assert(RolesClass.complexity(["summoner", "support"]) == 5)
	var healed_hp := 20.0
	for _cast in 20:
		healed_hp = RolesClass.support_healed_hp(healed_hp, 100.0, 0.16)
	assert(is_equal_approx(healed_hp, 85.0))
	assert(RolesClass.controller_slow_duration(9.0) <= 0.85)
	assert(RolesClass.charger_speed(1000.0) * 0.55 <= 308.0)

func _test_long_running_caps() -> void:
	# Two Summoners repeatedly casting must stabilize: two children per owner and
	# the global cap both remain enforced, even under Nightmare/Relentless cadence.
	var owner_counts := [0, 0]
	var global_count := 0
	for _minute_tick in 600:
		for owner_index in 2:
			if RolesClass.can_add_summon(owner_counts[owner_index], global_count, 2, 12 + global_count):
				owner_counts[owner_index] += 1
				global_count += 1
	assert(owner_counts == [2, 2])
	assert(global_count == 4)
	assert(global_count <= RolesClass.max_summons(2))
	assert(RolesClass.max_hazards(0) == 4)
	assert(RolesClass.max_hazards(2) == 8)
	assert(RolesClass.max_active_normal(0, true) < RolesClass.max_active_normal(0, false))
