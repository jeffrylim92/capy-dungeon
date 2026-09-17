class_name StoryBuildCapabilities
extends RefCounted

const CAPABILITIES: Array[String] = [
	"fire", "ice", "lightning", "poison", "projectile", "aoe",
	"mobility", "defence", "sustain", "crit", "companion",
]

# Gameplay metadata is centralized here because the current skill definitions do
# not expose tags. Story mechanics only query capabilities and never skill IDs.
const SKILL_TAGS: Dictionary = {
	"orb":["projectile"], "bolt":["lightning", "projectile"],
	"ice_orb":["ice", "projectile", "aoe"], "aura":["aoe"], "wave":["aoe"],
	"regen":["sustain"], "fireball":["fire", "projectile"],
	"elec_wave":["lightning", "aoe"], "hurricane":["aoe"],
	"blizzard":["ice", "aoe"], "arrow":["projectile"],
	"split_arrow":["projectile"], "pierce_arrow":["projectile"],
	"sky_fall":["projectile", "aoe"], "star_knife":["projectile"],
	"knife_storm":["aoe"], "boomerang":["projectile"], "seven_slash":["aoe"],
	"swirl_tangerine":["aoe"], "arcane_missile":["projectile"],
	"mana_nova":["aoe", "defence"], "time_warp":["aoe", "defence"],
	"crystal_prism":["aoe"], "arc_lightning":["lightning"],
	"ricochet_arrow":["projectile"], "hawk_companion":["projectile", "companion"],
	"trap_arrow":["projectile"], "poison_arrow":["poison", "projectile"],
	"phantom_hunt":["projectile"], "venom_plague":["poison", "projectile", "aoe"],
	"shadow_dagger":["projectile"], "blink_strike":["mobility"],
	"smoke_bomb":["aoe", "defence"], "shadow_clone":["aoe", "companion"],
	"bleed_mark":["projectile", "crit"], "thousand_blades":["projectile", "aoe"],
	"toxic_mushroom":["poison", "aoe"], "bog_trap":["poison", "aoe"],
	"leech_vine":["poison", "projectile", "sustain"],
	"plague_beetles":["poison", "companion"], "corruption_field":["poison", "aoe"],
	"flying_pan":["projectile"], "soup_splash":["aoe"],
	"chili_explosion":["fire", "projectile", "aoe"],
	"healing_feast":["sustain"], "meatball_barrage":["defence"],
	"master_kitchen":["fire", "aoe", "sustain"], "belly_bounce":["aoe"],
	"friendly_aura":["aoe"], "lucky_clover":["sustain"],
	"capy_charge":["mobility"], "stampede":["mobility", "aoe"],
	"inferno_thunder":["fire", "lightning", "aoe"],
	"frozen_lance":["ice", "projectile", "aoe"],
	"divine_volley":["projectile"], "thunder_god_pulse":["lightning", "aoe"],
	"toxic_lightning":["poison", "lightning", "aoe"],
}

const SYNERGIES: Array[Dictionary] = [
	{"stage":"ch1_1", "mechanic":"scout_protection", "capability":"defence", "cap":0.08, "label":"Scout protection", "description":"reduces nearby Scout damage"},
	{"stage":"ch1_1", "mechanic":"hurry_safety", "capability":"mobility", "cap":0.08, "label":"Hurry safety", "description":"slightly increases the safe Scout follow distance"},
	{"stage":"ch1_2", "mechanic":"shrine_protection", "capability":"defence", "cap":0.08, "label":"Shrine protection", "description":"reduces nearby Shrine damage"},
	{"stage":"ch1_2", "mechanic":"shrine_energy_decay", "capability":"fire", "cap":0.10, "label":"Shrine warmth", "description":"slows Shrine energy loss"},
	{"stage":"ch2_1", "mechanic":"brazier_decay", "capability":"fire", "cap":0.10, "label":"Brazier warmth", "description":"slows Brazier heat loss"},
	{"stage":"ch2_1", "mechanic":"cold_exposure", "capability":"ice", "cap":0.05, "label":"Cold control", "description":"slows Cold Exposure buildup"},
	{"stage":"ch2_2", "mechanic":"prison_thaw", "capability":"fire", "cap":0.10, "label":"Prison thaw", "description":"speeds valid prison thawing"},
	{"stage":"ch2_2", "mechanic":"captive_protection", "capability":"defence", "cap":0.08, "label":"Captive protection", "description":"reduces nearby Jailer refreeze pressure"},
	{"stage":"ch2_3", "mechanic":"wrong_rune_recovery", "capability":"ice", "cap":0.10, "label":"Freeze recovery", "description":"shortens wrong-rune recovery pressure"},
	{"stage":"ch2_5", "mechanic":"exposed_crystal", "capability":"fire", "cap":0.10, "label":"Exposed crystal", "description":"improves valid exposed-crystal damage"},
	{"stage":"ch3_1", "mechanic":"pool_stability", "capability":"sustain", "cap":0.10, "label":"Pool stability", "description":"improves active reclamation stability"},
	{"stage":"ch3_1", "mechanic":"mire_resistance", "capability":"poison", "cap":0.08, "label":"Mire resistance", "description":"reduces reclamation corruption pressure"},
	{"stage":"ch3_3", "mechanic":"web_lure", "capability":"fire", "cap":0.10, "label":"Web clearing", "description":"speeds the valid Spider lure channel"},
	{"stage":"ch3_3", "mechanic":"wasp_lure_range", "capability":"projectile", "cap":0.10, "label":"Ranged lure", "description":"slightly increases Wasp lure reach"},
	{"stage":"ch3_5", "mechanic":"brew_cooling", "capability":"ice", "cap":0.10, "label":"Brew cooling", "description":"improves cauldron cooling"},
	{"stage":"ch3_5", "mechanic":"brew_purity", "capability":"sustain", "cap":0.10, "label":"Cleanse efficiency", "description":"improves active purity recovery"},
	{"stage":"ch4_1", "mechanic":"mining_heat", "capability":"ice", "cap":0.10, "label":"Mining cooling", "description":"reduces mining Heat buildup"},
	{"stage":"ch4_2", "mechanic":"forge_stabilization", "capability":"lightning", "cap":0.10, "label":"Forge stabilization", "description":"shortens stabilization after the route is solved"},
	{"stage":"ch4_3", "mechanic":"capture_channel", "capability":"ice", "cap":0.10, "label":"Capture cooling", "description":"slightly shortens a valid Golem capture channel"},
	{"stage":"ch4_5", "mechanic":"regulator_channel", "capability":"lightning", "cap":0.10, "label":"Regulator stabilization", "description":"shortens correct-or-wrong regulator channels without choosing one"},
	{"stage":"ch4_5", "mechanic":"meltdown_heat", "capability":"ice", "cap":0.10, "label":"Meltdown cooling", "description":"slows ambient Heat buildup"},
	{"stage":"ch5_2", "mechanic":"spirit_protection", "capability":"defence", "cap":0.08, "label":"Spirit protection", "description":"slightly reduces nearby Soul Binder reach"},
]

const CAPABILITY_LABELS: Dictionary = {
	"fire":"🔥 Fire", "ice":"❄ Ice", "lightning":"⚡ Lightning", "poison":"☠ Poison",
	"projectile":"➶ Projectile", "aoe":"◎ AOE", "mobility":"➤ Mobility",
	"defence":"🛡 Defence", "sustain":"✚ Sustain", "crit":"✦ Critical", "companion":"◆ Companion",
}

const DEV_PROFILE_IDS: Array[String] = ["current", "none", "fire", "ice", "lightning", "mobility", "defence", "projectile_aoe"]
const DEV_PROFILE_LABELS: Dictionary = {
	"current":"Current run build", "none":"No relevant synergy", "fire":"Fire-heavy",
	"ice":"Ice-heavy", "lightning":"Lightning-heavy", "mobility":"Mobility-heavy",
	"defence":"Defensive-heavy", "projectile_aoe":"Projectile + AOE-heavy",
}

static func calculate(skills: Array, stats: Dictionary = {}, character_defence: int = 0, mutator_config: Dictionary = {}) -> Dictionary:
	var scores: Dictionary = {}
	for capability in CAPABILITIES:
		scores[capability] = 0.0
	for skill_variant in skills:
		if typeof(skill_variant) != TYPE_DICTIONARY:
			continue
		var skill: Dictionary = skill_variant as Dictionary
		var skill_id := str(skill.get("id", ""))
		var level := maxi(1, int(skill.get("level", 1)))
		var investment := minf(0.90, 0.42 + float(level - 1) * 0.11 + (0.08 if not str(skill.get("evolution", "")).is_empty() else 0.0))
		for tag_variant in SKILL_TAGS.get(skill_id, []) as Array:
			var tag := str(tag_variant)
			scores[tag] = minf(1.0, float(scores.get(tag, 0.0)) + investment)

	_add_score(scores, "fire", _positive_stat_score(stats, ["fire_dmg", "burn_duration"], 0.15))
	_add_score(scores, "ice", _positive_stat_score(stats, ["ice_dmg", "freeze_duration"], 0.15))
	_add_score(scores, "lightning", _positive_stat_score(stats, ["lightning_dmg", "lightning_chain"], 0.15))
	_add_score(scores, "projectile", _positive_stat_score(stats, ["projectile_spd", "projectile_dmg", "projectile_homing", "proj_dup_chance"], 0.18))
	_add_score(scores, "aoe", _positive_stat_score(stats, ["aoe_radius"], 0.15))
	_add_score(scores, "mobility", _positive_stat_score(stats, ["move_speed_mul", "blink_iframes"], 0.15))
	_add_score(scores, "mobility", minf(0.55, maxf(0.0, float(stats.get("move_speed", 0.0))) / 55.0))
	_add_score(scores, "sustain", _positive_stat_score(stats, ["regen", "regen_pulse_pct", "lifesteal", "healing_efficiency"], 0.16))
	_add_score(scores, "crit", _positive_stat_score(stats, ["crit_chance", "crit_dmg"], 0.18))
	_add_score(scores, "defence", _positive_stat_score(stats, ["max_hp_pct", "timed_shield"], 0.18))
	_add_score(scores, "defence", minf(0.45, maxf(0.0, float(stats.get("max_hp", 0.0))) / 60.0))
	_add_score(scores, "defence", minf(0.30, maxf(0.0, float(character_defence - 10)) * 0.06))
	if float(stats.get("damage_taken_mul", 0.0)) < 0.0:
		_add_score(scores, "defence", minf(0.60, -float(stats.get("damage_taken_mul", 0.0)) / 0.20))
	if float(mutator_config.get("damage_taken", 1.0)) < 1.0:
		_add_score(scores, "defence", minf(0.60, (1.0 - float(mutator_config.get("damage_taken", 1.0))) / 0.25))
	if not bool(mutator_config.get("healing_enabled", true)):
		scores["sustain"] = 0.0
	return {"scores":scores, "tiers":_tiers(scores)}

static func score(profile: Dictionary, capability: String) -> float:
	return clampf(float((profile.get("scores", {}) as Dictionary).get(capability, 0.0)), 0.0, 1.0)

static func dev_profile(profile_id: String) -> Dictionary:
	var scores: Dictionary = {}
	for capability in CAPABILITIES:
		scores[capability] = 0.0
	match profile_id:
		"fire", "ice", "lightning", "mobility", "defence": scores[profile_id] = 1.0
		"projectile_aoe": scores.merge({"projectile":1.0, "aoe":1.0}, true)
	return {"scores":scores, "tiers":_tiers(scores), "dev_override":profile_id}

static func tier(profile: Dictionary, capability: String) -> String:
	return str((profile.get("tiers", {}) as Dictionary).get(capability, "none"))

static func stage_synergies(stage_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in SYNERGIES:
		if str(entry.get("stage", "")) == stage_id:
			out.append(entry.duplicate(true))
	return out

static func synergy(stage_id: String, mechanic: String, profile: Dictionary) -> Dictionary:
	for entry in SYNERGIES:
		if str(entry.get("stage", "")) != stage_id or str(entry.get("mechanic", "")) != mechanic:
			continue
		var capability := str(entry.get("capability", ""))
		var cap := clampf(float(entry.get("cap", 0.0)), 0.0, 0.20)
		var result := entry.duplicate(true)
		result["score"] = score(profile, capability)
		result["bonus"] = cap * float(result["score"])
		result["active"] = float(result["bonus"]) > 0.001
		return result
	return {}

static func stage_display_lines(stage_id: String) -> Array[String]:
	var out: Array[String] = []
	for entry in stage_synergies(stage_id):
		var capability := str(entry.get("capability", ""))
		out.append("%s — %s (up to %d%%)" % [str(CAPABILITY_LABELS.get(capability, capability.capitalize())), str(entry.get("description", "optional benefit")), roundi(float(entry.get("cap", 0.0)) * 100.0)])
	return out

static func telemetry_summary(profile: Dictionary) -> String:
	var parts: Array[String] = []
	for capability in CAPABILITIES:
		var capability_tier := tier(profile, capability)
		if capability_tier != "none":
			parts.append("%s=%s" % [capability, capability_tier])
	return "none" if parts.is_empty() else " ".join(parts)

static func validate() -> Array[String]:
	var issues: Array[String] = []
	var keys: Dictionary = {}
	for skill_id_variant in SKILL_TAGS:
		for tag_variant in SKILL_TAGS[skill_id_variant] as Array:
			if str(tag_variant) not in CAPABILITIES:
				issues.append("Unknown skill capability: %s -> %s" % [str(skill_id_variant), str(tag_variant)])
	for entry in SYNERGIES:
		var stage_id := str(entry.get("stage", ""))
		var mechanic := str(entry.get("mechanic", ""))
		var key := "%s:%s" % [stage_id, mechanic]
		if key in keys:
			issues.append("Duplicate Story synergy: %s" % key)
		keys[key] = true
		var chapter := stage_id.get_slice("_", 0).trim_prefix("ch").to_int()
		var stage := stage_id.get_slice("_", 1).to_int()
		if not stage_id.begins_with("ch") or chapter < 1 or chapter > 5 or stage < 1 or stage > 5 or mechanic.is_empty():
			issues.append("Invalid Story synergy ID: %s" % key)
		if str(entry.get("capability", "")) not in CAPABILITIES:
			issues.append("Unknown capability: %s" % key)
		if float(entry.get("cap", 0.0)) <= 0.0 or float(entry.get("cap", 0.0)) > 0.20:
			issues.append("Invalid cap: %s" % key)
	return issues

static func _positive_stat_score(stats: Dictionary, keys: Array[String], full_scale: float) -> float:
	var total := 0.0
	for key in keys:
		total += maxf(0.0, float(stats.get(key, 0.0)))
	return minf(0.60, total / maxf(full_scale, 0.01) * 0.60)

static func _add_score(scores: Dictionary, capability: String, amount: float) -> void:
	scores[capability] = minf(1.0, float(scores.get(capability, 0.0)) + maxf(0.0, amount))

static func _tiers(scores: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for capability in CAPABILITIES:
		var value := float(scores.get(capability, 0.0))
		out[capability] = "strong" if value >= 0.75 else ("medium" if value >= 0.40 else ("low" if value > 0.0 else "none"))
	return out
