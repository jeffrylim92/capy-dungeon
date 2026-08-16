class_name StoryCompletionValidator
extends RefCounted

static func validate(stage: Dictionary, state: Dictionary) -> Dictionary:
	if bool(state.get("victory_committed", false)):
		return _rejected("victory_already_committed")

	var objective: String = str(stage.get("objective", ""))
	var chapter: int = int(stage.get("chapter", 1))
	if chapter == 1:
		var chapter_one_result: Dictionary = _validate_chapter_one(objective, state)
		if not bool(chapter_one_result.get("accepted", false)):
			return chapter_one_result
	elif chapter == 2:
		var chapter_two_result: Dictionary = _validate_chapter_two(objective, state)
		if not bool(chapter_two_result.get("accepted", false)):
			return chapter_two_result
	elif chapter == 3:
		var chapter_three_result: Dictionary = _validate_chapter_three(objective, state)
		if not bool(chapter_three_result.get("accepted", false)):
			return chapter_three_result
	elif chapter == 4:
		var chapter_four_result: Dictionary = _validate_chapter_four(objective, state)
		if not bool(chapter_four_result.get("accepted", false)):
			return chapter_four_result
	elif chapter == 5:
		var chapter_five_result: Dictionary = _validate_chapter_five(objective, state)
		if not bool(chapter_five_result.get("accepted", false)):
			return chapter_five_result
	else:
		if bool(state.get("staged_required", false)):
			if int(state.get("required_generated", 0)) < int(state.get("required_total", 0)):
				return _rejected("required_objectives_not_generated")
			if int(state.get("required_completed", 0)) < int(state.get("required_total", 0)):
				return _rejected("required_objectives_incomplete")
			if int(state.get("required_active", 0)) > 0:
				return _rejected("required_objective_still_active")
			if bool(state.get("pending_spawn", false)):
				return _rejected("required_objective_spawn_pending")
		if objective == "abyss_king":
			var phase: int = int(state.get("stage_phase", 0))
			if phase < 2:
				return _rejected("ritual_anchors_incomplete")
			if phase < 3:
				return _rejected("crown_progression_incomplete")
		if objective in ["frost_mimic", "plaguebeast", "frost_colossus", "abyss_king"] and not bool(state.get("boss_defeated", false)):
			return _rejected("boss_not_defeated")
		if not bool(state.get("primary_complete", false)):
			return _rejected("primary_objective_incomplete")
	if bool(state.get("finale_required", false)):
		if not bool(state.get("finale_triggered", false)):
			return _rejected("final_assault_not_started", true)
		if not bool(state.get("finale_complete", false)):
			return _rejected("final_assault_incomplete")
	if bool(state.get("boss_required", false)) and not bool(state.get("boss_defeated", false)):
		return _rejected("boss_not_defeated")
	return {"accepted": true, "reason": "all_required_conditions_complete", "start_finale": false}

static func _validate_chapter_five(objective: String, state: Dictionary) -> Dictionary:
	if bool(state.get("failure_active", false)):
		return _rejected("chapter_five_failure_active")
	if bool(state.get("transition_pending", false)):
		return _rejected("chapter_five_transition_pending")
	match objective:
		"silent_descent":
			if not bool(state.get("infiltration_started", false)): return _rejected("infiltration_not_started")
			if str(state.get("selected_route", "")).is_empty(): return _rejected("infiltration_route_not_selected")
			if int(state.get("checkpoints_reached", 0)) < 3: return _rejected("infiltration_checkpoints_incomplete")
			if not bool(state.get("gate_opened", false)): return _rejected("inner_gate_not_opened")
			if not bool(state.get("silent_finale_selected", false)) and not bool(state.get("detected_finale_selected", false)): return _rejected("infiltration_finale_not_selected")
			if not bool(state.get("final_route_complete", false)): return _rejected("infiltration_finale_incomplete")
			if not bool(state.get("final_threshold_crossed", false)): return _rejected("final_threshold_not_crossed")
		"soul_liberation":
			if int(state.get("spirits_saved", 0)) < 6: return _rejected("spirits_not_saved")
			if int(state.get("chains_generated", 0)) < 6: return _rejected("soul_chain_progression_incomplete")
			if not bool(state.get("portal_sealing_started", false)): return _rejected("portal_sealing_not_started")
			if int(state.get("seals_stable", 0)) < 3: return _rejected("portal_stabilizers_incomplete")
			if not bool(state.get("portal_keeper_resolved", false)): return _rejected("portal_keeper_unresolved")
			if int(state.get("spirits_captured", 0)) > 0: return _rejected("spirit_still_captured")
			if int(state.get("active_soul_chains", 0)) > 0 or int(state.get("active_spirits", 0)) > 0: return _rejected("spirit_recovery_transition_pending")
			if not bool(state.get("portal_sealed", false)): return _rejected("abyss_portal_not_sealed")
		"mirror_labyrinth":
			if not bool(state.get("clue_state_valid", false)): return _rejected("mirror_clue_state_invalid")
			if int(state.get("rooms_completed", 0)) < 4: return _rejected("mirror_rooms_incomplete")
			if not bool(state.get("labyrinth_exit_reached", false)): return _rejected("labyrinth_exit_not_reached")
			if not bool(state.get("guardian_spawned", false)): return _rejected("mirror_guardian_not_spawned")
			if not bool(state.get("guardian_defeated", false)): return _rejected("mirror_guardian_not_defeated")
		"twin_eclipse":
			if not bool(state.get("obelisk_a_stabilized", false)): return _rejected("obelisk_a_unstable")
			if not bool(state.get("obelisk_b_stabilized", false)): return _rejected("obelisk_b_unstable")
			if not bool(state.get("route_prepared", false)): return _rejected("eclipse_route_unprepared")
			if not bool(state.get("sync_attempt_started", false)): return _rejected("eclipse_sync_not_started")
			if not bool(state.get("sync_succeeded", false)): return _rejected("eclipse_sync_failed")
			if not bool(state.get("sync_hold_complete", false)): return _rejected("eclipse_hold_incomplete")
			if not bool(state.get("eclipse_elite_resolved", false)): return _rejected("eclipse_elite_unresolved")
			if bool(state.get("elite_disruption_active", false)): return _rejected("eclipse_disruption_pending")
		"abyss_king":
			if int(state.get("anchors_destroyed", 0)) < 3: return _rejected("ritual_anchors_incomplete")
			if not bool(state.get("anchor_transitions_complete", false)): return _rejected("anchor_transition_incomplete")
			if not bool(state.get("crown_spawned", false)): return _rejected("abyss_crown_not_spawned")
			if int(state.get("crown_sections_broken", 0)) < 4: return _rejected("abyss_crown_sections_incomplete")
			if not bool(state.get("crown_destroyed", false)): return _rejected("abyss_crown_not_destroyed")
			if not bool(state.get("crown_transition_complete", false)): return _rejected("crown_transition_incomplete")
			if not bool(state.get("final_phase_entered", false)): return _rejected("abyss_king_final_phase_missing")
			if not bool(state.get("desperation_entered", false)): return _rejected("abyss_king_phase_progression_incomplete")
			if not bool(state.get("boss_defeated", false)): return _rejected("abyss_king_not_defeated")
			if bool(state.get("boss_transition_pending", false)): return _rejected("abyss_king_transition_pending")
	if not bool(state.get("primary_complete", false)):
		return _rejected("primary_objective_incomplete")
	return {"accepted":true, "reason":"chapter_five_requirements_complete", "start_finale":false}

static func _validate_chapter_four(objective: String, state: Dictionary) -> Dictionary:
	if bool(state.get("transition_pending", false)):
		return _rejected("chapter_four_transition_pending")
	if bool(state.get("heat_failure_active", false)):
		return _rejected("chapter_four_heat_failure_active")
	match objective:
		"ore_rush":
			var ore_required: int = int(state.get("ore_required", 12))
			if int(state.get("ore_generated", 0)) < ore_required: return _rejected("ember_ore_not_generated")
			if int(state.get("ore_mined", 0)) < ore_required: return _rejected("ember_ore_not_mined")
			if int(state.get("ore_delivered", 0)) < ore_required: return _rejected("ember_ore_not_delivered")
			if not bool(state.get("cart_loaded", false)): return _rejected("mining_cart_not_loaded")
			if not bool(state.get("extraction_started", false)): return _rejected("cart_extraction_not_started")
			if not bool(state.get("cart_reached_extraction", false)): return _rejected("cart_not_extracted")
			if int(state.get("ore_stolen", 0)) > 0: return _rejected("stolen_ore_unrecovered")
			if not bool(state.get("cargo_transition_clear", false)): return _rejected("cargo_transition_pending")
		"molten_circuit":
			if bool(state.get("valve_transition_pending", false)): return _rejected("lava_valve_transition_pending")
			if not bool(state.get("puzzle_initialized", false)): return _rejected("molten_circuit_not_initialized")
			if int(state.get("mechanisms_powered", 0)) < 3: return _rejected("forge_mechanisms_unpowered")
			if int(state.get("route_nodes", 0)) < 3: return _rejected("powered_lava_route_incomplete")
			if not bool(state.get("route_traversal_complete", false)): return _rejected("molten_route_not_traversed")
			if not bool(state.get("stabilization_complete", false)): return _rejected("molten_circuit_not_stabilized")
			if bool(state.get("mandatory_jam_active", false)): return _rejected("forge_jammer_unresolved")
		"golem_taming":
			if int(state.get("golems_captured", 0)) < 4: return _rejected("rogue_golems_not_captured")
			for golem_index in 4:
				if not bool(state.get("golem_%d_captured" % (golem_index + 1), false)):
					return _rejected("golem_%d_capture_incomplete" % (golem_index + 1))
			if not bool(state.get("assistance_resolved", false)): return _rejected("captured_golem_assistance_unresolved")
			if bool(state.get("capture_channel_active", false)): return _rejected("golem_capture_channel_active")
			if bool(state.get("capture_pending", false)): return _rejected("golem_capture_pending")
		"lost_relic":
			for chamber_index in 3:
				if not bool(state.get("chamber_%d_complete" % (chamber_index + 1), false)):
					return _rejected("relic_chamber_%d_incomplete" % (chamber_index + 1))
			if int(state.get("components_collected", 0)) < 3: return _rejected("relic_components_missing")
			if not bool(state.get("relic_assembled", false)): return _rejected("lost_relic_not_assembled")
			if not bool(state.get("relic_choice_committed", false)): return _rejected("relic_choice_not_committed")
			if not bool(state.get("boss_spawned", false)): return _rejected("relic_guardian_not_spawned")
			if not bool(state.get("boss_defeated", false)): return _rejected("relic_guardian_not_defeated")
		"meltdown":
			if bool(state.get("regulator_transition_pending", false)): return _rejected("regulator_transition_pending")
			if bool(state.get("boss_transition_pending", false)): return _rejected("behemoth_transition_pending")
			if int(state.get("regulators_disabled", 0)) < 4: return _rejected("shutdown_regulators_remaining")
			if not bool(state.get("shutdown_complete", false)): return _rejected("shutdown_sequence_incomplete")
			if not bool(state.get("shutdown_committed", false)): return _rejected("shutdown_not_committed")
			if not bool(state.get("final_phase_entered", false)): return _rejected("final_shutdown_phase_missing")
			if int(state.get("boss_regulator_phases_completed", state.get("regulators_disabled", 0))) < 4: return _rejected("boss_regulator_phases_incomplete")
			if not bool(state.get("boss_spawned", false)): return _rejected("thunderforge_behemoth_not_spawned")
			if not bool(state.get("boss_defeated", false)): return _rejected("thunderforge_behemoth_not_defeated")
	if not bool(state.get("primary_complete", false)):
		return _rejected("primary_objective_incomplete")
	return {"accepted": true, "reason":"chapter_four_requirements_complete", "start_finale":false}

static func _validate_chapter_three(objective: String, state: Dictionary) -> Dictionary:
	if bool(state.get("transition_pending", false)):
		return _rejected("chapter_three_transition_pending")
	match objective:
		"cleanse_mire":
			if int(state.get("pools_generated", 0)) < 3: return _rejected("mire_pools_not_generated")
			if int(state.get("pools_purified", 0)) < 3: return _rejected("mire_pools_not_purified")
			if int(state.get("nodes_resolved", 0)) < 3: return _rejected("corruption_nodes_unresolved")
			if not bool(state.get("reclamation_complete", false)): return _rejected("reclamation_surge_incomplete")
			if not bool(state.get("all_pools_stable", false)): return _rejected("mire_pool_unstable")
			if bool(state.get("pool_reclaiming", false)): return _rejected("mire_pool_reclaiming")
		"plaguebeast":
			if int(state.get("tracking_phases_complete", 0)) < 3: return _rejected("tracking_phases_incomplete")
			if not bool(state.get("final_arena_reached", false)): return _rejected("plaguebeast_arena_not_reached")
			if not bool(state.get("final_phase_started", false)): return _rejected("plaguebeast_final_phase_missing")
			if not bool(state.get("boss_defeated", false)): return _rejected("plaguebeast_not_defeated")
			if bool(state.get("escape_pending", false)): return _rejected("plaguebeast_escape_pending")
		"venom_harvest":
			if not bool(state.get("spider_complete", false)): return _rejected("spider_venom_incomplete")
			if not bool(state.get("toad_complete", false)): return _rejected("toad_bile_incomplete")
			if not bool(state.get("wasp_complete", false)): return _rejected("wasp_stingers_incomplete")
			if not bool(state.get("ingredient_case_assembled", false)): return _rejected("ingredient_case_missing")
			if bool(state.get("ingredients_contaminated", false)): return _rejected("ingredients_contaminated")
			if not bool(state.get("ingredient_case_extracted", false)): return _rejected("ingredient_case_not_extracted")
		"fragile_cure":
			if not bool(state.get("vial_collected", false)): return _rejected("antidote_vial_not_collected")
			if int(state.get("route_checkpoints", 0)) < int(state.get("route_checkpoints_required", 2)): return _rejected("cure_route_incomplete")
			if not bool(state.get("vial_at_altar", false)): return _rejected("antidote_not_at_altar")
			if float(state.get("vial_integrity", 0.0)) <= 0.0: return _rejected("antidote_vial_shattered")
			if not bool(state.get("transfer_complete", false)): return _rejected("antidote_transfer_incomplete")
			if not bool(state.get("altar_cured", false)): return _rejected("infected_altar_uncured")
		"grand_antidote":
			if int(state.get("recipe_size", 0)) < 3: return _rejected("antidote_recipe_missing")
			if int(state.get("ingredients_acquired", 0)) < 3: return _rejected("brew_ingredients_missing")
			if int(state.get("ingredients_submitted", 0)) < 3: return _rejected("brew_ingredients_unsubmitted")
			if not bool(state.get("brew_complete", false)): return _rejected("grand_antidote_incomplete")
			if float(state.get("purity", 0.0)) < 35.0: return _rejected("grand_antidote_purity_too_low")
			if not bool(state.get("boss_spawned", false)): return _rejected("blight_tyrant_not_spawned")
			if not bool(state.get("boss_defeated", false)): return _rejected("blight_tyrant_not_defeated")
	if not bool(state.get("primary_complete", false)):
		return _rejected("primary_objective_incomplete")
	return {"accepted":true, "reason":"chapter_three_requirements_complete", "start_finale":false}

static func _validate_chapter_two(objective: String, state: Dictionary) -> Dictionary:
	if bool(state.get("transition_pending", state.get("pending_transition", false))):
		return _rejected("chapter_two_transition_pending")
	match objective:
		"frozen_braziers":
			if int(state.get("braziers_generated", 0)) < 4: return _rejected("braziers_not_generated")
			if int(state.get("braziers_lit", 0)) < 4: return _rejected("braziers_not_lit")
			if int(state.get("active_braziers", 0)) < 4: return _rejected("warmth_chain_inactive")
			if not bool(state.get("warmth_stabilized", false)): return _rejected("warmth_chain_not_stabilized")
		"ice_captives":
			if int(state.get("prisons_generated", 0)) < 5: return _rejected("prisons_not_generated")
			if int(state.get("prisons_destroyed", 0)) < 5: return _rejected("prisons_not_destroyed")
			if int(state.get("captives_released", 0)) < 5: return _rejected("captives_not_released")
			if int(state.get("captives_extracted", 0)) < 5: return _rejected("captives_not_extracted")
			if int(state.get("captives_refrozen", 0)) > 0: return _rejected("captive_still_refrozen")
			if not bool(state.get("jailer_elite_resolved", false)): return _rejected("jailer_elite_unresolved")
			if not bool(state.get("finale_complete", false)): return _rejected("blizzard_extraction_incomplete")
		"thaw_runes":
			if not bool(state.get("sequence_generated", false)): return _rejected("rune_sequence_missing")
			if not bool(state.get("sequence_reveal_complete", false)): return _rejected("rune_reveal_incomplete")
			if int(state.get("runes_correct", 0)) < 4: return _rejected("rune_sequence_incomplete")
			if not bool(state.get("final_rune_activated", false)): return _rejected("final_rune_inactive")
			if not bool(state.get("spreading_freeze_resolved", false)): return _rejected("spreading_freeze_unresolved")
		"frost_mimic":
			if not bool(state.get("real_mimic_opened", false)): return _rejected("real_mimic_not_opened")
			if not bool(state.get("mimic_spawned", false)): return _rejected("frost_mimic_not_spawned")
			if not bool(state.get("mimic_defeated", false)): return _rejected("frost_mimic_not_defeated")
		"frost_colossus":
			if not bool(state.get("boss_spawned", false)): return _rejected("colossus_not_spawned")
			if int(state.get("crystals_broken", 0)) < 3: return _rejected("armour_crystals_remaining")
			if int(state.get("armour_transitions", 0)) < 3: return _rejected("armour_transitions_incomplete")
			if not bool(state.get("all_armour_transitions_complete", false)): return _rejected("armour_transition_pending")
			if not bool(state.get("final_vulnerable_phase", false)): return _rejected("final_vulnerable_phase_missing")
			if not bool(state.get("boss_defeated", false)): return _rejected("colossus_not_defeated")
	if not bool(state.get("primary_complete", false)):
		return _rejected("primary_objective_incomplete")
	return {"accepted": true, "reason": "chapter_two_requirements_complete", "start_finale": false}

static func _validate_chapter_one(objective: String, state: Dictionary) -> Dictionary:
	if bool(state.get("transition_pending", false)):
		return _rejected("mandatory_transition_pending")
	match objective:
		"escort":
			if not bool(state.get("mission_started", state.get("objective_started", false))):
				return _rejected("escort_not_started")
			if not bool(state.get("route_complete", false)):
				return _rejected("escort_route_incomplete")
			if not bool(state.get("target_alive", false)):
				return _rejected("scout_not_alive")
			if not bool(state.get("interaction_complete", false)):
				return _rejected("barricade_incomplete")
			if not bool(state.get("extraction_reached", false)):
				return _rejected("extraction_not_reached")
			if not bool(state.get("extraction_complete", false)):
				return _rejected("extraction_channel_incomplete")
		"defend":
			if not bool(state.get("mission_started", state.get("objective_started", false))):
				return _rejected("shrine_not_summoned")
			if not bool(state.get("target_alive", false)):
				return _rejected("shrine_not_alive")
			if not bool(state.get("timer_complete", false)):
				return _rejected("shrine_energy_incomplete")
			if not bool(state.get("growth_resolved", false)):
				return _rejected("corrupted_growth_unresolved")
			if not bool(state.get("finale_complete", false)):
				return _rejected("cleansing_channel_incomplete")
		"nests":
			if int(state.get("required_generated", 0)) < int(state.get("required_total", 3)):
				return _rejected("required_nests_not_generated")
			if int(state.get("required_completed", 0)) < int(state.get("required_total", 3)):
				return _rejected("required_nests_incomplete")
			if int(state.get("required_active", 0)) > 0:
				return _rejected("required_nest_still_active")
			if not bool(state.get("feeding_sacs_resolved", false)):
				return _rejected("feeding_sacs_unresolved")
			if not bool(state.get("foreman_resolved", false)):
				return _rejected("supply_foreman_unresolved")
			if not bool(state.get("supplies_secured", false)):
				return _rejected("recovered_supplies_unsecured")
		"keys":
			if int(state.get("required_generated", 0)) < int(state.get("required_total", 3)):
				return _rejected("required_keys_not_generated")
			if int(state.get("required_completed", 0)) < int(state.get("required_total", 3)):
				return _rejected("required_keys_incomplete")
			if int(state.get("required_active", 0)) > 0:
				return _rejected("required_key_uncollected")
			if bool(state.get("key_enemy_held", false)):
				return _rejected("required_key_held_by_enemy")
			if not bool(state.get("gate_unlocked", false)):
				return _rejected("watchpath_gate_locked")
			if not bool(state.get("gate_crossed", false)):
				return _rejected("watchpath_gate_not_crossed")
		"hazards":
			if int(state.get("barrage_phases_completed", 0)) < 3:
				return _rejected("required_barrage_phases_incomplete")
			if not bool(state.get("boss_spawned", false)):
				return _rejected("crestkeeper_not_spawned")
			if not bool(state.get("boss_defeated", false)):
				return _rejected("crestkeeper_not_defeated")
			if not bool(state.get("finale_complete", false)):
				return _rejected("chapter_finale_incomplete")
	if int(state.get("required_gate_remaining", 0)) > 0:
		return _rejected("required_cleanup_incomplete")
	if not bool(state.get("primary_complete", false)):
		return _rejected("primary_objective_incomplete")
	return {"accepted": true}

static func _rejected(reason: String, start_finale: bool = false) -> Dictionary:
	return {"accepted": false, "reason": reason, "start_finale": start_finale}
