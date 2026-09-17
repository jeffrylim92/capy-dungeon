extends SceneTree

const Telemetry := preload("res://scripts/story/StoryTelemetry.gd")

func _init() -> void:
	_test_story_sequence_and_schema()
	_test_stage_coverage_and_boss_metrics()
	_test_context_isolation_and_abandon()
	_test_retry_ids_and_bounded_buffer()
	print("Story Telemetry tests passed: schema, sequences, coverage, contexts, retries, bounds")
	quit(0)

func _stage(stage_id: String = "ch1_1", difficulty: String = "hard", mutators: Array = ["pressure_wave", "glass_capy", "pressure_wave"]) -> Dictionary:
	var chapter := stage_id.get_slice("_", 0).trim_prefix("ch").to_int()
	var stage_number := stage_id.get_slice("_", 1).to_int()
	return {"id":stage_id, "chapter":chapter, "chapter_stage":stage_number, "difficulty":difficulty, "mutators":mutators, "mutator_reward_bonus":0.4}

func _new_telemetry(stage: Dictionary, test_mode: bool = false, context: String = "story"):
	var telemetry = Telemetry.new()
	telemetry.set_debug_enabled(false)
	telemetry.start(stage, test_mode, {"tiers":{"fire":"strong"}, "scores":{"fire":0.9}}, context)
	return telemetry

func _test_story_sequence_and_schema() -> void:
	var telemetry = _new_telemetry(_stage())
	telemetry.sync_active_time(4.0)
	telemetry.phase_changed("setup", "escort")
	telemetry.objective_spawned("scout")
	telemetry.mistake("unsafe_scout_command", {"command":"hurry"})
	telemetry.recovery("scout_recovered")
	telemetry.role_event("support", "heal_cast")
	telemetry.protected_damage_rejected("crestkeeper", "armour_active")
	telemetry.protected_damage_rejected("crestkeeper", "armour_active")
	telemetry.mastery_failed("ch1_1_safe_scout", "scout_low_health")
	telemetry.mastery_final(["ch1_1_fast_route"], {"ch1_1_safe_scout":"scout_low_health"})
	telemetry.mastery_persisted(["ch1_1_fast_route"], false)
	telemetry.stage_completed(42.5, {"route_complete":true, "target_alive":true, "escort_command":"hurry", "route_choice":"short"}, {"top_damage":[{"source_id":"fireball", "damage":120.0}], "damage_coverage":0.92}, "history-1")
	assert(telemetry.event_count("story_stage_started") == 1)
	assert(telemetry.event_count("story_stage_completed") == 1)
	assert(telemetry.event_count("story_protected_damage_rejected") == 1)
	assert(telemetry.is_terminal())
	var events: Array = telemetry.events()
	for event_variant in events:
		var event := event_variant as Dictionary
		for field in ["event_name", "timestamp", "run_id", "run_context", "stage_id", "chapter_id", "difficulty", "mutator_ids", "event_data"]:
			assert(event.has(field))
		assert(str(event.run_context) == "story")
		assert(str(event.stage_id) == "ch1_1")
		assert((event.mutator_ids as Array) == ["glass_capy", "pressure_wave"])
	var terminal := events[-1] as Dictionary
	assert(str(terminal.event_name) == "story_stage_completed")
	assert(is_equal_approx(float(terminal.event_data.active_seconds), 42.5))
	assert(str(terminal.event_data.history_run_id) == "history-1")

func _test_stage_coverage_and_boss_metrics() -> void:
	var coverage := Telemetry.stage_coverage()
	assert(coverage.size() == 25)
	for chapter in range(1, 6):
		for stage_number in range(1, 6):
			var stage_id := "ch%d_%d" % [chapter, stage_number]
			assert(coverage.has(stage_id))
			assert((Telemetry.STAGE_METRIC_FIELDS.get(stage_id, []) as Array).size() >= 3)
	var c4 = _new_telemetry(_stage("ch4_5"))
	c4.boss_spawned("c4_thunderforge_behemoth")
	c4.mistake("wrong_shutdown_regulator", {"selected":2, "expected":1})
	c4.protected_damage_rejected("c4_thunderforge_behemoth", "forge_protected")
	c4.stage_failed("meltdown", 95.0, {"regulators_disabled":2, "boss_regulator_phases_completed":2, "heat":100.0, "shutdown_complete":false, "boss_defeated":false})
	assert(c4.event_count("story_boss_spawned") == 1)
	assert(c4.event_count("story_stage_failed") == 1)
	var c4_terminal := c4.events()[-1] as Dictionary
	assert(int(c4_terminal.event_data.stage_metrics.regulators_disabled) == 2)
	var c5 = _new_telemetry(_stage("ch5_5", "nightmare", ["elite_hunt", "berserk_elites"]))
	c5.phase_changed("setup", "ritual_anchors")
	for anchor_type in ["dominion", "ruin", "reflection"]:
		c5.boss_mechanic("abyss_king", "ritual_anchor_destroyed", {"anchor_type":anchor_type})
	c5.phase_changed("ritual_anchors", "abyss_crown")
	c5.boss_mechanic("abyss_king", "crown_section_broken", {"sections_broken":4})
	c5.phase_changed("abyss_crown", "desperation")
	c5.stage_completed(180.0, {"anchors_destroyed":3, "crown_sections_broken":4, "crown_cycles":2, "desperation_entered":true, "boss_defeated":true})
	assert(c5.event_count("story_boss_mechanic") == 4)
	var c5_terminal := c5.events()[-1] as Dictionary
	assert(int(c5_terminal.event_data.stage_metrics.anchors_destroyed) == 3)
	assert(bool(c5_terminal.event_data.stage_metrics.desperation_entered))

func _test_context_isolation_and_abandon() -> void:
	var dev = _new_telemetry(_stage("ch2_4"), true, "story")
	assert(dev.context() == "story_dev_test")
	dev.stage_abandoned("story_test_exit", 13.0, {"clues_found":2, "wrong_chests":1})
	assert(dev.event_count("story_stage_abandoned") == 1)
	for event in dev.events():
		assert(str((event as Dictionary).run_context) == "story_dev_test")
	var practice = _new_telemetry(_stage("ch5_5"), false, "boss_practice")
	assert(practice.context() == "boss_practice")
	practice.mastery_failed("should_not_persist", "practice_probe")
	practice.stage_failed("player_defeated", 18.0)
	assert(practice.event_count("story_stage_failed") == 1)
	for event in practice.events():
		assert(str((event as Dictionary).run_context) == "boss_practice")

func _test_retry_ids_and_bounded_buffer() -> void:
	var ids: Dictionary = {}
	for retry_index in 20:
		var telemetry = _new_telemetry(_stage("ch3_4"))
		assert(not ids.has(telemetry.run_id()))
		ids[telemetry.run_id()] = true
		telemetry.objective_failed("fragile_cure", "antidote_vial_shattered", true)
		telemetry.recovery("replacement_antidote_vial_spawned")
		telemetry.stage_failed("player_defeated", float(retry_index + 1))
		telemetry.stage_retried("test_loop")
		assert(telemetry.event_count() <= Telemetry.MAX_EVENTS)
	assert(ids.size() == 20)
	var bounded = _new_telemetry(_stage("ch5_3"))
	for index in 200:
		bounded.mistake("wrong_mirror", {"index":index})
	bounded.stage_failed("abyss_pressure", 60.0, {"rooms_completed":1, "wrong_choices":200, "abyss_pressure":100.0})
	assert(bounded.event_count() == Telemetry.MAX_EVENTS)
	assert(str((bounded.events()[-1] as Dictionary).event_name) == "story_stage_failed")
