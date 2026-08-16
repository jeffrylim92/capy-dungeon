extends SceneTree

const Validator = preload("res://scripts/story/StoryCompletionValidator.gd")

func _init() -> void:
	var cases: Array[Dictionary] = [
		{"objective":"silent_descent", "state":{"infiltration_started":true, "selected_route":"shadow", "checkpoints_reached":3, "gate_opened":true, "silent_finale_selected":true, "final_route_complete":true, "final_threshold_crossed":true, "primary_complete":true}},
		{"objective":"soul_liberation", "state":{"spirits_saved":6, "chains_generated":6, "active_soul_chains":0, "active_spirits":0, "portal_sealing_started":true, "seals_stable":3, "portal_keeper_resolved":true, "spirits_captured":0, "portal_sealed":true, "primary_complete":true}},
		{"objective":"mirror_labyrinth", "state":{"clue_state_valid":true, "rooms_completed":4, "labyrinth_exit_reached":true, "guardian_spawned":true, "guardian_defeated":true, "primary_complete":true}},
		{"objective":"twin_eclipse", "state":{"obelisk_a_stabilized":true, "obelisk_b_stabilized":true, "route_prepared":true, "sync_attempt_started":true, "sync_succeeded":true, "sync_hold_complete":true, "eclipse_elite_resolved":true, "elite_disruption_active":false, "primary_complete":true}},
		{"objective":"abyss_king", "state":{"anchors_destroyed":3, "anchor_transitions_complete":true, "crown_spawned":true, "crown_sections_broken":4, "crown_destroyed":true, "crown_transition_complete":true, "final_phase_entered":true, "desperation_entered":true, "boss_defeated":true, "boss_transition_pending":false, "primary_complete":true}},
	]
	for case_index in cases.size():
		var case: Dictionary = cases[case_index]
		var stage: Dictionary = {"chapter":5, "chapter_stage":case_index + 1, "objective":case.objective}
		var state: Dictionary = (case.state as Dictionary).duplicate(true)
		var accepted: Dictionary = Validator.validate(stage, state)
		if not bool(accepted.get("accepted", false)):
			printerr("Valid C5S%d rejected: %s" % [case_index + 1, str(accepted.get("reason", ""))])
			quit(1)
			return
		for required_key in state.keys():
			if required_key in ["boss_transition_pending", "spirits_captured", "active_soul_chains", "active_spirits", "elite_disruption_active"]:
				continue
			var incomplete: Dictionary = state.duplicate(true)
			var value: Variant = incomplete[required_key]
			incomplete[required_key] = "" if value is String else (0 if value is int else false)
			var rejected: Dictionary = Validator.validate(stage, incomplete)
			if bool(rejected.get("accepted", false)):
				printerr("Incomplete C5S%d accepted without %s" % [case_index + 1, str(required_key)])
				quit(1)
				return
	print("ChapterFive completion validation passed")
	quit(0)
