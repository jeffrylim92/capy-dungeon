class_name StoryDamageProtection
extends RefCounted

static func minimum_hp(story_tag: String, max_hp: float, state: Dictionary = {}) -> float:
	var safe_max_hp := maxf(1.0, max_hp)
	if story_tag == "frost_colossus" and int(state.get("crystals_broken", 0)) < 3:
		return 1.0
	if story_tag == "c3_blight_tyrant" and not bool(state.get("arena_rooted", false)):
		return safe_max_hp * 0.55
	if story_tag.begins_with("c4_golem_"):
		return safe_max_hp * 0.20
	if story_tag == "c4_thunderforge_behemoth" and not bool(state.get("shutdown_complete", false)):
		return safe_max_hp * 0.25
	if story_tag == "abyss_king":
		if not bool(state.get("final_phase_entered", false)):
			return safe_max_hp * 0.72
		return safe_max_hp * float({"final_boss_a":0.65, "final_boss_b":0.35, "final_boss_c":0.22}.get(str(state.get("phase", "")), 0.0))
	return 0.0

static func clamp_hp(story_tag: String, hp: float, max_hp: float, state: Dictionary = {}) -> float:
	return maxf(hp, minimum_hp(story_tag, max_hp, state))
