extends SceneTree

const BossPresentation := preload("res://scripts/story/StoryBossPresentation.gd")

func _init() -> void:
	_test_brew_quality()
	_test_component_identity()
	_test_profiles()
	print("Story boss presentation tests passed: identity · phase status · protected-state messaging")
	quit(0)

func _test_brew_quality() -> void:
	assert(BossPresentation.brew_quality(100.0) == "PURE")
	assert(BossPresentation.brew_quality(80.0) == "PURE")
	assert(BossPresentation.brew_quality(79.9) == "STABLE")
	assert(BossPresentation.brew_quality(55.0) == "STABLE")
	assert(BossPresentation.brew_quality(54.9) == "VOLATILE")

func _test_component_identity() -> void:
	assert(BossPresentation.crystal_system(0) == "FROST BEAM")
	assert(BossPresentation.crystal_system(2) == "ARMOUR REGENERATION")
	assert(BossPresentation.regulator_system(3) == "HEAT PULSE")
	assert("SUMMONS" in BossPresentation.anchor_name("dominion"))
	assert("CORRUPTION" in BossPresentation.anchor_name("ruin"))
	assert("PROJECTILES" in BossPresentation.anchor_name("reflection"))

func _test_profiles() -> void:
	var crestkeeper := BossPresentation.profile("ch1_5", {"phase":"rotating_barrage", "barrage_phases_completed":2})
	assert(str(crestkeeper.get("name", "")) == "CRESTKEEPER")
	assert("BANKS 1/3" in str(crestkeeper.get("status", "")))
	var colossus := BossPresentation.profile("ch2_5", {"crystals_broken":3})
	assert(str(colossus.get("phase", "")) == "TRUE CORE")
	assert("CORE EXPOSED" in str(colossus.get("status", "")))
	var behemoth := BossPresentation.profile("ch4_5", {"regulators_disabled":4})
	assert("CORE EXPOSED" in str(behemoth.get("phase", "")))
	var ritual := BossPresentation.profile("ch5_5", {"phase":"ritual_anchors", "anchors_destroyed":1})
	assert("RITUAL SHIELD" in str(ritual.get("status", "")))
	var crown := BossPresentation.profile("ch5_5", {"phase":"abyss_crown", "crown_sections_broken":2, "crown_vulnerable":true})
	assert("CROWN VULNERABLE" in str(crown.get("status", "")))
	var desperation := BossPresentation.profile("ch5_5", {"phase":"desperation"})
	assert(str(desperation.get("phase", "")) == "DESPERATION")
