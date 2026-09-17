extends SceneTree

const CombatReadabilityClass := preload("res://scripts/CombatReadability.gd")
const CombatVFXClass := preload("res://scripts/CombatVFX.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_objective_priority()
	_test_damage_number_modes()
	var host := Node2D.new()
	root.add_child(host)
	var vfx := CombatVFXClass.new()
	host.add_child(vfx)
	var readability := CombatReadabilityClass.new()
	host.add_child(readability)
	readability.configure({
		"effect_intensity":1.0,
		"player_effects":"high",
		"player_outline":1.0,
		"damage_numbers":"critical_only",
	})
	await process_frame
	assert(readability.z_index > vfx.z_index)
	readability.update_snapshot({
		"boss_telegraphs":[{"kind":"circle", "pos":Vector2.ZERO, "radius":80.0, "life":1.0, "max_life":1.0}],
		"boss_projectiles":[], "enemies":[],
	}, 40, "")
	assert(readability.critical_visual_active())
	assert(is_equal_approx(readability.player_effect_scale(), 1.0))
	readability.update_snapshot({"boss_telegraphs":[], "boss_projectiles":[], "enemies":[]}, 170, "c5s5_crown")
	var stressed := readability.debug_state()
	assert(int(stressed.get("load_tier", -1)) == CombatReadabilityClass.LOAD_EXTREME)
	assert(float(stressed.get("player_effect_scale", 1.0)) < 0.5)
	assert(readability.trail_steps(6) == 2)
	assert(readability.damage_popup_cap(64) < 64)
	# Retry/scene cleanup must remove the temporary boss override.
	readability.update_snapshot({"boss_telegraphs":[], "boss_projectiles":[], "enemies":[]}, 0, "")
	assert(not readability.critical_visual_active())
	assert(is_equal_approx(readability.player_effect_scale(), 1.0))
	host.queue_free()
	await process_frame
	# Exercise Match setup and one live update/draw cycle with the shared system.
	var match_script := load("res://scripts/Match.gd")
	assert(match_script != null)
	var match_node: Variant = match_script.new()
	root.add_child(match_node)
	await process_frame
	await process_frame
	assert(match_node._combat_readability != null)
	assert(not match_node._combat_readability.debug_state().is_empty())
	match_node.queue_free()
	await process_frame
	print("Combat readability tests passed: hierarchy · objective urgency · budget response · settings hooks · cleanup")
	quit(0)

func _test_objective_priority() -> void:
	var spirits: Array = []
	for index in 6:
		spirits.append({"kind":"released_soul", "pos":Vector2(float(index) * 100.0, 0.0), "hp":100.0, "max_hp":100.0})
	spirits[4]["refrozen"] = true
	var selected := CombatReadabilityClass.select_objective(spirits, Vector2.ZERO)
	assert(selected == spirits[4])
	spirits[4]["completed"] = true
	selected = CombatReadabilityClass.select_objective(spirits, Vector2.ZERO)
	assert(selected == spirits[0])

func _test_damage_number_modes() -> void:
	assert(CombatReadabilityClass.normalize_damage_number_mode(true) == "all")
	assert(CombatReadabilityClass.normalize_damage_number_mode(false) == "off")
	assert(CombatReadabilityClass.normalize_damage_number_mode("Critical Only") == "critical_only")
	assert(not CombatReadabilityClass.allows_damage_number("off", true, 5, CombatReadabilityClass.LOAD_NORMAL))
	assert(not CombatReadabilityClass.allows_damage_number("critical_only", false, 2, CombatReadabilityClass.LOAD_NORMAL))
	assert(CombatReadabilityClass.allows_damage_number("critical_only", true, 4, CombatReadabilityClass.LOAD_EXTREME))
	assert(not CombatReadabilityClass.allows_damage_number("all", false, 1, CombatReadabilityClass.LOAD_HEAVY))
