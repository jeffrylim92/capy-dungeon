class_name StoryBossPractice
extends RefCounted

const RUN_CONTEXT: String = "boss_practice"
const BOSS_STAGE_IDS: Array[String] = ["ch1_5", "ch2_5", "ch3_5", "ch4_5", "ch5_5"]
const BREW_PRESETS: Array[Dictionary] = [
	{"id":"volatile", "name":"Volatile", "purity":45.0},
	{"id":"stable", "name":"Stable", "purity":65.0},
	{"id":"pure", "name":"Pure", "purity":85.0},
]

const BOSSES: Dictionary = {
	"ch1_5": {
		"chapter":1, "name":"Crestkeeper", "hint":"Follow the rotating safe lanes and disable the emitter banks.",
		"phases":[
			{"id":"full", "name":"Full Fight"},
			{"id":"emitter_barrage", "name":"Emitter Barrage"},
			{"id":"final_barrage", "name":"Final Barrage"},
		],
	},
	"ch2_5": {
		"chapter":2, "name":"Frostbound Colossus", "hint":"Break exposed crystals to disable armour systems.",
		"phases":[
			{"id":"full", "name":"Full Fight"},
			{"id":"armour_systems", "name":"Armour Systems"},
			{"id":"exposed_core", "name":"Exposed Core"},
		],
	},
	"ch3_5": {
		"chapter":3, "name":"Blight Vine Tyrant", "hint":"Your simulated Antidote quality changes the Tyrant's hazards.",
		"phases":[
			{"id":"full", "name":"Full Fight"},
			{"id":"final_growth", "name":"Final Growth"},
		],
	},
	"ch4_5": {
		"chapter":4, "name":"Thunderforge Behemoth", "hint":"Shut down regulators in sequence while surviving the Behemoth.",
		"phases":[
			{"id":"full", "name":"Full Encounter"},
			{"id":"shutdown_pressure", "name":"2 Regulators Remaining"},
			{"id":"final_combat", "name":"Final Combat"},
		],
	},
	"ch5_5": {
		"chapter":5, "name":"Abyss King", "hint":"Destroy protected Ritual Anchors before attacking the Crown.",
		"phases":[
			{"id":"full", "name":"Full Fight"},
			{"id":"ritual_anchors", "name":"Ritual Anchors"},
			{"id":"abyss_crown", "name":"Abyss Crown"},
			{"id":"the_king", "name":"The King"},
			{"id":"desperation", "name":"Desperation"},
		],
	},
}

static func boss(stage_id: String) -> Dictionary:
	return (BOSSES.get(stage_id, {}) as Dictionary).duplicate(true)

static func is_boss_stage(stage_id: String) -> bool:
	return stage_id in BOSS_STAGE_IDS

static func progression_allowed(run_context: String) -> bool:
	return run_context == "story"

static func unlocked(profile: Dictionary, stage_id: String, debug_override: bool = false) -> bool:
	return debug_override or stage_id in (profile.get("cleared", []) as Array)

static func difficulty_available(profile: Dictionary, stage_id: String, difficulty_id: String, debug_override: bool = false) -> bool:
	if debug_override:
		return true
	return StoryStore.highest_cleared_difficulty(profile, stage_id) >= StoryStore.difficulty_rank(difficulty_id)

static func phases(stage_id: String) -> Array:
	return (boss(stage_id).get("phases", []) as Array).duplicate(true)

static func phase_valid(stage_id: String, phase_id: String) -> bool:
	for phase_variant in phases(stage_id):
		if str((phase_variant as Dictionary).get("id", "")) == phase_id:
			return true
	return false

static func phase_name(stage_id: String, phase_id: String) -> String:
	for phase_variant in phases(stage_id):
		var phase: Dictionary = phase_variant as Dictionary
		if str(phase.get("id", "")) == phase_id:
			return str(phase.get("name", phase_id))
	return "Full Fight"

static func brew_purity(preset_id: String) -> float:
	for preset in BREW_PRESETS:
		if str(preset.get("id", "")) == preset_id:
			return float(preset.get("purity", 65.0))
	return 65.0

static func configure(stage_data: Dictionary, difficulty_id: String, mutator_ids: Array, profile: Dictionary, phase_id: String = "full", brew_id: String = "stable", debug_override: bool = false) -> Dictionary:
	var stage_id := str(stage_data.get("id", ""))
	if not is_boss_stage(stage_id) or not unlocked(profile, stage_id, debug_override) or not difficulty_available(profile, stage_id, difficulty_id, debug_override):
		return {}
	var safe_phase := phase_id if phase_valid(stage_id, phase_id) else "full"
	var configured := StoryStore.configure_run(stage_data, difficulty_id, mutator_ids, profile, debug_override)
	configured["run_context"] = RUN_CONTEXT
	configured["practice_phase"] = safe_phase
	configured["practice_phase_name"] = phase_name(stage_id, safe_phase)
	configured["practice_brew"] = brew_id if brew_id in ["volatile", "stable", "pure"] else "stable"
	configured["practice_brew_purity"] = brew_purity(str(configured["practice_brew"]))
	configured["practice_boss_name"] = str(boss(stage_id).get("name", "Chapter Boss"))
	configured["practice_hint"] = str(boss(stage_id).get("hint", ""))
	configured["practice_rewards_disabled"] = true
	return configured

static func phase_complete(stage_id: String, phase_id: String, state: Dictionary) -> bool:
	if phase_id == "full":
		return bool(state.get("full_encounter_complete", false))
	match stage_id:
		"ch1_5":
			return bool(state.get("boss_defeated", false)) if phase_id == "final_barrage" else int(state.get("barrage_phases_completed", 0)) >= 3
		"ch2_5":
			return bool(state.get("boss_defeated", false)) if phase_id == "exposed_core" else int(state.get("crystals_broken", 0)) >= 3
		"ch3_5":
			return bool(state.get("boss_defeated", false))
		"ch4_5":
			return bool(state.get("boss_defeated", false)) if phase_id == "final_combat" else bool(state.get("shutdown_complete", false)) and bool(state.get("boss_defeated", false))
		"ch5_5":
			if phase_id == "ritual_anchors": return int(state.get("anchors_destroyed", 0)) >= 3
			if phase_id == "abyss_crown": return bool(state.get("crown_destroyed", false))
			return bool(state.get("boss_defeated", false))
	return false
