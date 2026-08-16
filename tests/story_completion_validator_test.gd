extends SceneTree

const Validator = preload("res://scripts/story/StoryCompletionValidator.gd")

func _init() -> void:
	_test_broken_trail()
	_test_mushroom_crossing()
	_test_supply_thieves()
	_test_old_watchpath()
	_test_crestkeepers_gate()
	_test_rekindle_the_way()
	_test_frozen_captives()
	_test_runes_of_thaw()
	_test_mimic_treasury()
	_test_frostbound_colossus()
	_test_cleanse_the_mire()
	_test_hunt_the_plaguebeast()
	_test_venom_harvest()
	_test_fragile_cure()
	_test_grand_antidote()
	_test_ore_rush()
	_test_molten_circuit()
	_test_golem_taming()
	_test_lost_relic()
	_test_meltdown()
	_test_chapter_four_authored_puzzle()
	_test_chapter_four_shutdown_sequences()
	_test_chapter_four_phase_gates()
	_test_silent_descent_route_gate()
	_test_throne_of_the_deep()
	print("StoryCompletionValidator tests passed.")
	quit()

func _base_state() -> Dictionary:
	return {
		"victory_committed": false, "primary_complete": true, "objective_started": true,
		"required_total": 0, "required_generated": 0, "required_completed": 0,
		"required_active": 0, "required_gate_remaining": 0, "pending_spawn": false,
		"staged_required": false, "timer_expired": true, "route_complete": true,
		"target_alive": true, "finale_required": false, "finale_triggered": false,
		"finale_complete": false, "boss_required": false, "boss_defeated": true,
		"stage_phase": 3,
		"mission_started": true, "interaction_complete": true,
		"extraction_reached": true, "extraction_complete": true,
		"timer_complete": true, "growth_resolved": true,
		"transition_pending": false, "gate_unlocked": true, "gate_crossed": true,
		"key_enemy_held": false, "feeding_sacs_resolved": true,
		"foreman_resolved": true, "supplies_secured": true,
		"barrage_phases_completed": 3, "boss_spawned": true,
	}

func _test_broken_trail() -> void:
	var stage := {"chapter": 1, "chapter_stage": 1, "objective": "escort"}
	var state := _base_state()
	state["mission_started"] = false
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["mission_started"] = true
	state["interaction_complete"] = false
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["interaction_complete"] = true
	state["route_complete"] = false
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["route_complete"] = true
	state["target_alive"] = false
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["target_alive"] = true
	assert(bool(Validator.validate(stage, state).get("accepted", false)))

func _test_mushroom_crossing() -> void:
	var stage := {"chapter": 1, "chapter_stage": 2, "objective": "defend"}
	var state := _base_state()
	state["timer_complete"] = false
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["timer_complete"] = true
	state["target_alive"] = false
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["target_alive"] = true
	state["finale_complete"] = true
	assert(bool(Validator.validate(stage, state).get("accepted", false)))

func _test_supply_thieves() -> void:
	var stage := {"chapter": 1, "chapter_stage": 3, "objective": "nests"}
	var state := _base_state()
	state.merge({"required_total":3, "required_generated":3, "required_completed":2}, true)
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["required_completed"] = 3
	assert(bool(Validator.validate(stage, state).get("accepted", false)))

func _test_old_watchpath() -> void:
	var stage := {"chapter": 1, "chapter_stage": 4, "objective": "keys"}
	var state := _base_state()
	state.merge({"required_total":3, "required_generated":3, "required_completed":3, "gate_crossed":false}, true)
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["gate_crossed"] = true
	assert(bool(Validator.validate(stage, state).get("accepted", false)))

func _test_crestkeepers_gate() -> void:
	var stage := {"chapter": 1, "chapter_stage": 5, "objective": "hazards"}
	var state := _base_state()
	state["boss_required"] = true
	state["boss_defeated"] = false
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["boss_defeated"] = true
	state["finale_complete"] = true
	assert(bool(Validator.validate(stage, state).get("accepted", false)))

func _test_runes_of_thaw() -> void:
	var stage := {"chapter": 2, "chapter_stage": 3, "objective": "thaw_runes"}
	var state := _base_state()
	state.merge({"sequence_generated":true, "sequence_reveal_complete":true, "runes_correct":3, "final_rune_activated":false, "spreading_freeze_resolved":false}, true)
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state.merge({"runes_correct":4, "final_rune_activated":true, "spreading_freeze_resolved":true}, true)
	assert(bool(Validator.validate(stage, state).get("accepted", false)))

func _test_mimic_treasury() -> void:
	var stage := {"chapter": 2, "chapter_stage": 4, "objective": "frost_mimic"}
	var state := _base_state()
	state.merge({"real_mimic_opened":true, "mimic_spawned":true, "mimic_defeated":false}, true)
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["mimic_defeated"] = true
	assert(bool(Validator.validate(stage, state).get("accepted", false)))

func _test_rekindle_the_way() -> void:
	var stage := {"chapter":2, "chapter_stage":1, "objective":"frozen_braziers"}
	var state := _base_state()
	state.merge({"braziers_generated":4, "braziers_lit":4, "active_braziers":3, "warmth_stabilized":false}, true)
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state.merge({"active_braziers":4, "warmth_stabilized":true}, true)
	assert(bool(Validator.validate(stage, state).get("accepted", false)))

func _test_frozen_captives() -> void:
	var stage := {"chapter":2, "chapter_stage":2, "objective":"ice_captives"}
	var state := _base_state()
	state.merge({"prisons_generated":5, "prisons_destroyed":5, "captives_released":5, "captives_extracted":4, "captives_refrozen":0, "jailer_elite_resolved":true, "finale_complete":true}, true)
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["captives_extracted"] = 5
	assert(bool(Validator.validate(stage, state).get("accepted", false)))

func _test_frostbound_colossus() -> void:
	var stage := {"chapter":2, "chapter_stage":5, "objective":"frost_colossus"}
	var state := _base_state()
	state.merge({"boss_spawned":true, "crystals_broken":2, "armour_transitions":2, "all_armour_transitions_complete":false, "final_vulnerable_phase":false}, true)
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state.merge({"crystals_broken":3, "armour_transitions":3, "all_armour_transitions_complete":true, "final_vulnerable_phase":true}, true)
	assert(bool(Validator.validate(stage, state).get("accepted", false)))

func _test_cleanse_the_mire() -> void:
	var stage := {"chapter":3, "chapter_stage":1, "objective":"cleanse_mire"}
	var state := _base_state()
	state.merge({"pools_generated":3, "pools_purified":3, "nodes_resolved":3, "reclamation_complete":true, "all_pools_stable":true, "pool_reclaiming":false}, true)
	assert(bool(Validator.validate(stage, state).get("accepted", false)))
	state["pool_reclaiming"] = true
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))

func _test_hunt_the_plaguebeast() -> void:
	var stage := {"chapter":3, "chapter_stage":2, "objective":"plaguebeast"}
	var state := _base_state()
	state.merge({"tracking_phases_complete":3, "final_arena_reached":true, "final_phase_started":true, "boss_defeated":true, "escape_pending":false}, true)
	assert(bool(Validator.validate(stage, state).get("accepted", false)))
	state["tracking_phases_complete"] = 2
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))

func _test_venom_harvest() -> void:
	var stage := {"chapter":3, "chapter_stage":3, "objective":"venom_harvest"}
	var state := _base_state()
	state.merge({"spider_complete":true, "toad_complete":true, "wasp_complete":true, "ingredient_case_assembled":true, "ingredients_contaminated":false, "ingredient_case_extracted":true}, true)
	assert(bool(Validator.validate(stage, state).get("accepted", false)))
	state["ingredients_contaminated"] = true
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))

func _test_fragile_cure() -> void:
	var stage := {"chapter":3, "chapter_stage":4, "objective":"fragile_cure"}
	var state := _base_state()
	state.merge({"vial_collected":true, "route_checkpoints":2, "route_checkpoints_required":2, "vial_at_altar":true, "vial_integrity":65.0, "transfer_complete":true, "altar_cured":true}, true)
	assert(bool(Validator.validate(stage, state).get("accepted", false)))
	state["vial_integrity"] = 0.0
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))

func _test_grand_antidote() -> void:
	var stage := {"chapter":3, "chapter_stage":5, "objective":"grand_antidote"}
	var state := _base_state()
	state.merge({"recipe_size":3, "ingredients_acquired":3, "ingredients_submitted":3, "brew_complete":true, "purity":70.0, "boss_spawned":true, "boss_defeated":true}, true)
	assert(bool(Validator.validate(stage, state).get("accepted", false)))
	state["brew_complete"] = false
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))

func _test_ore_rush() -> void:
	var stage := {"chapter": 4, "chapter_stage": 1, "objective": "ore_rush"}
	var state := _base_state()
	state.merge({"ore_required":12, "ore_generated":12, "ore_mined":12, "ore_delivered":11, "cart_loaded":false, "extraction_started":false, "cart_reached_extraction":false, "ore_stolen":0, "cargo_transition_clear":false}, true)
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state.merge({"ore_delivered":12, "cart_loaded":true, "extraction_started":true, "cart_reached_extraction":true, "cargo_transition_clear":true}, true)
	assert(bool(Validator.validate(stage, state).get("accepted", false)))

func _test_molten_circuit() -> void:
	var stage := {"chapter":4, "chapter_stage":2, "objective":"molten_circuit"}
	var state := _base_state()
	state.merge({"puzzle_initialized":true, "mechanisms_powered":3, "route_nodes":3, "route_traversal_complete":true, "stabilization_complete":false, "mandatory_jam_active":false}, true)
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["stabilization_complete"] = true
	assert(bool(Validator.validate(stage, state).get("accepted", false)))

func _test_golem_taming() -> void:
	var stage := {"chapter":4, "chapter_stage":3, "objective":"golem_taming"}
	var state := _base_state()
	state.merge({"golems_captured":4, "golem_1_captured":true, "golem_2_captured":true, "golem_3_captured":true, "golem_4_captured":true, "assistance_resolved":true, "capture_pending":true}, true)
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["capture_pending"] = false
	assert(bool(Validator.validate(stage, state).get("accepted", false)))

func _test_lost_relic() -> void:
	var stage := {"chapter":4, "chapter_stage":4, "objective":"lost_relic"}
	var state := _base_state()
	state.merge({"chamber_1_complete":true, "chamber_2_complete":true, "chamber_3_complete":true, "components_collected":3, "relic_assembled":true, "relic_choice_committed":true, "boss_spawned":true, "boss_defeated":false}, true)
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["boss_defeated"] = true
	assert(bool(Validator.validate(stage, state).get("accepted", false)))

func _test_meltdown() -> void:
	var stage := {"chapter":4, "chapter_stage":5, "objective":"meltdown"}
	var state := _base_state()
	state.merge({"regulators_disabled":4, "shutdown_complete":true, "shutdown_committed":true, "final_phase_entered":true, "boss_spawned":true, "boss_defeated":false}, true)
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["boss_defeated"] = true
	assert(bool(Validator.validate(stage, state).get("accepted", false)))

func _test_chapter_four_authored_puzzle() -> void:
	var valve_masks: Array[int] = [1, 2, 4]
	for initial_mask in 8:
		var solution_found: bool = false
		for input_mask in 8:
			var state: int = initial_mask
			for valve_index in 3:
				if (input_mask & (1 << valve_index)) != 0: state ^= valve_masks[valve_index]
			if state == 7:
				solution_found = true
				break
		assert(solution_found)

func _test_chapter_four_shutdown_sequences() -> void:
	for iteration in 250:
		var sequence: Array[int] = [0, 1, 2, 3]
		sequence.shuffle()
		var seen: Dictionary = {}
		for regulator_id in sequence: seen[regulator_id] = true
		assert(sequence.size() == 4)
		assert(seen.size() == 4)
		assert(sequence.min() == 0 and sequence.max() == 3)

func _test_chapter_four_phase_gates() -> void:
	var ore_stage := {"chapter":4, "chapter_stage":1, "objective":"ore_rush"}
	var ore_state := _base_state()
	ore_state.merge({"ore_required":12, "ore_generated":12, "ore_mined":12, "ore_delivered":12, "cart_loaded":true, "extraction_started":true, "cart_reached_extraction":true, "ore_stolen":0, "cargo_transition_clear":true, "heat_failure_active":true}, true)
	assert(not bool(Validator.validate(ore_stage, ore_state).get("accepted", false)))
	var capture_stage := {"chapter":4, "chapter_stage":3, "objective":"golem_taming"}
	var capture_state := _base_state()
	capture_state.merge({"golems_captured":4, "golem_1_captured":true, "golem_2_captured":true, "golem_3_captured":true, "golem_4_captured":true, "assistance_resolved":true, "capture_pending":false, "capture_channel_active":true}, true)
	assert(not bool(Validator.validate(capture_stage, capture_state).get("accepted", false)))
	var boss_stage := {"chapter":4, "chapter_stage":5, "objective":"meltdown"}
	var boss_state := _base_state()
	boss_state.merge({"regulators_disabled":3, "boss_regulator_phases_completed":3, "shutdown_complete":false, "shutdown_committed":false, "final_phase_entered":false, "boss_spawned":true, "boss_defeated":true}, true)
	assert(not bool(Validator.validate(boss_stage, boss_state).get("accepted", false)))

func _test_silent_descent_route_gate() -> void:
	var stage := {"chapter":5, "chapter_stage":1, "objective":"silent_descent"}
	var state := _base_state()
	state.merge({"infiltration_started":true, "selected_route":"shadow", "checkpoints_reached":0, "gate_opened":false, "silent_finale_selected":false, "final_route_complete":false, "final_threshold_crossed":false}, true)
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["checkpoints_reached"] = 3
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["gate_opened"] = true
	state["silent_finale_selected"] = true
	state["final_route_complete"] = true
	state["final_threshold_crossed"] = true
	assert(bool(Validator.validate(stage, state).get("accepted", false)))

func _test_throne_of_the_deep() -> void:
	var stage := {"chapter": 5, "chapter_stage": 5, "objective": "abyss_king"}
	var state := _base_state()
	state.merge({"anchors_destroyed":2, "anchor_transitions_complete":false, "crown_spawned":false, "crown_sections_broken":0, "crown_destroyed":false, "crown_transition_complete":false, "final_phase_entered":false, "desperation_entered":false, "boss_defeated":false, "boss_transition_pending":false}, true)
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state.merge({"anchors_destroyed":3, "anchor_transitions_complete":true, "crown_spawned":true, "crown_sections_broken":4, "crown_destroyed":true, "crown_transition_complete":true, "final_phase_entered":true, "desperation_entered":true, "boss_defeated":true}, true)
	state["primary_complete"] = false
	assert(not bool(Validator.validate(stage, state).get("accepted", false)))
	state["primary_complete"] = true
	assert(bool(Validator.validate(stage, state).get("accepted", false)))
