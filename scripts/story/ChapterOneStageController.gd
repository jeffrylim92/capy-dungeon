class_name ChapterOneStageController
extends RefCounted

var stage_number: int = 0
var phase: String = "setup"
var flags: Dictionary = {}

func reset(next_stage_number: int) -> void:
	stage_number = next_stage_number
	phase = "setup"
	flags = {
		"mission_started": false,
		"route_complete": false,
		"interaction_complete": false,
		"extraction_reached": false,
		"extraction_complete": false,
		"target_alive": true,
		"timer_complete": false,
		"growth_resolved": false,
		"finale_complete": false,
		"boss_spawned": false,
		"boss_defeated": false,
		"gate_unlocked": false,
		"gate_crossed": false,
		"key_enemy_held": false,
		"transition_pending": false,
		"primary_complete": false,
	}

func enter(next_phase: String) -> String:
	var previous: String = phase
	phase = next_phase
	return previous

func set_flag(key: String, value: bool = true) -> void:
	flags[key] = value

func flag(key: String) -> bool:
	return bool(flags.get(key, false))

func completion_state() -> Dictionary:
	var result: Dictionary = flags.duplicate(true)
	result["chapter_one_phase"] = phase
	return result
