extends SceneTree

const ProtectionClass := preload("res://scripts/story/StoryDamageProtection.gd")

func _init() -> void:
	_test_frost_colossus_gate()
	_test_blight_tyrant_gate()
	_test_golem_capture_floor()
	_test_meltdown_boss_floor()
	_test_abyss_king_phase_floors()
	print("Story high-damage tests passed: Colossus · Tyrant signature · Golem floor · Behemoth floor · Abyss phase floors")
	quit(0)

func _test_frost_colossus_gate() -> void:
	assert(is_equal_approx(ProtectionClass.clamp_hp("frost_colossus", -1000000000.0, 1000.0, {"crystals_broken":0}), 1.0))
	assert(ProtectionClass.minimum_hp("frost_colossus", 1000.0, {"crystals_broken":3}) == 0.0)

func _test_blight_tyrant_gate() -> void:
	for damage_source in ["crit", "projectile", "aoe", "dot", "companion", "ultimate"]:
		assert(is_equal_approx(ProtectionClass.clamp_hp("c3_blight_tyrant", -1000000000.0, 1000.0, {"arena_rooted":false}), 550.0), damage_source)
	assert(ProtectionClass.minimum_hp("c3_blight_tyrant", 1000.0, {"arena_rooted":true}) == 0.0)

func _test_golem_capture_floor() -> void:
	for damage_source in ["crit", "projectile", "aoe", "dot", "companion", "ultimate", "chain", "environment"]:
		var remaining_hp := ProtectionClass.clamp_hp("c4_golem_1", 1000.0 - 1000000000.0, 1000.0)
		assert(is_equal_approx(remaining_hp, 200.0), damage_source)

func _test_meltdown_boss_floor() -> void:
	assert(is_equal_approx(ProtectionClass.clamp_hp("c4_thunderforge_behemoth", -1000000000.0, 1000.0, {"shutdown_complete":false}), 250.0))
	assert(ProtectionClass.minimum_hp("c4_thunderforge_behemoth", 1000.0, {"shutdown_complete":true}) == 0.0)

func _test_abyss_king_phase_floors() -> void:
	assert(is_equal_approx(ProtectionClass.clamp_hp("abyss_king", -1000000000.0, 1000.0, {"final_phase_entered":false}), 720.0))
	assert(is_equal_approx(ProtectionClass.clamp_hp("abyss_king", -1000000000.0, 1000.0, {"final_phase_entered":true, "phase":"final_boss_a"}), 650.0))
	assert(is_equal_approx(ProtectionClass.clamp_hp("abyss_king", -1000000000.0, 1000.0, {"final_phase_entered":true, "phase":"final_boss_b"}), 350.0))
	assert(is_equal_approx(ProtectionClass.clamp_hp("abyss_king", -1000000000.0, 1000.0, {"final_phase_entered":true, "phase":"final_boss_c"}), 220.0))
	assert(ProtectionClass.minimum_hp("abyss_king", 1000.0, {"final_phase_entered":true, "phase":"desperation"}) == 0.0)
	assert(ProtectionClass.minimum_hp("ordinary_enemy", 1000.0) == 0.0)
