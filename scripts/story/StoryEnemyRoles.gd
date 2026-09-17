class_name StoryEnemyRoles
extends RefCounted

const ROLES: Array[String] = [
	"chaser", "tank", "zoner", "sniper", "charger",
	"support", "disruptor", "thief", "controller", "summoner",
]

const ROLE_COSTS := {
	"chaser":1, "tank":1, "zoner":2, "sniper":2, "charger":2,
	"support":2, "disruptor":2, "thief":2, "controller":2, "summoner":3,
}

const ROLE_KINDS := {
	"chaser":"normal", "tank":"normal_tank", "charger":"normal_fast",
	"zoner":"role_zoner", "sniper":"role_sniper", "support":"role_support",
	"controller":"role_controller", "summoner":"role_summoner",
}

# Bosses are deliberately absent. They remain owned by the authored boss system.
const KIND_ROLES := {
	"normal":["chaser"],
	"normal_tank":["tank"],
	"normal_fast":["charger"],
	"role_zoner":["zoner"],
	"role_sniper":["sniper"],
	"role_support":["support"],
	"role_controller":["controller"],
	"role_summoner":["summoner"],
}

# Named Story identities retain their authored logic. This table only describes
# battlefield purpose and enables the relevant reusable behaviour where useful.
const STORY_TAG_ROLES := {
	"shrine_attacker":["disruptor"], "c2_brazier_suppressor":["disruptor", "tank"],
	"c2_flamekeeper":["support"], "c2_jailer_elite":["disruptor", "controller"],
	"c2_lesser_mimic":["charger"], "c3_contaminator":["disruptor"],
	"c3_energy_carrier":["support"], "c3_marked_spider":["controller", "zoner"],
	"c3_spider_pack":["controller"], "c3_marked_toad":["charger", "zoner"],
	"c3_toad_pack":["charger"], "c3_marked_wasp":["sniper"],
	"c3_wasp_pack":["chaser"], "c4_ore_thief":["thief"],
	"c4_cart_blocker":["tank"], "c4_forge_jammer":["disruptor"],
	"c4_repair_drone":["support"], "c5_soul_binder":["disruptor", "controller"],
	"c5_anchor_dominion":["support", "tank"], "c5_crown_channeler":["support"],
	"supply_foreman":["support", "tank"], "carrier_guard":["tank"],
	"fleeing_key_carrier":["thief"], "protected_key_carrier":["thief", "tank"],
	"watchpath_captain":["tank"],
}

const STORY_TAG_PREFIX_ROLES := {
	"c2_jailer_":["disruptor", "controller"],
	"c4_golem_":["charger"],
	"c4_chamber_guardian_":["tank"],
}

# Deliberate chapter progression. Empty lists are intentional quiet/boss stages.
const STAGE_PROFILES := {
	"ch1_1":{"normal":["chaser", "charger"], "hard":["tank"], "nightmare":[], "story":"Scout escort"},
	"ch1_2":{"normal":["chaser", "zoner"], "hard":["charger"], "nightmare":[], "story":"Shrine Disruptor"},
	"ch1_3":{"normal":["chaser"], "hard":["support"], "nightmare":[], "story":"Supply Foreman"},
	"ch1_4":{"normal":["chaser", "tank"], "hard":["charger"], "nightmare":[], "story":"Key carriers"},
	"ch1_5":{"normal":[], "hard":[], "nightmare":[], "story":"Crestkeeper boss"},
	"ch2_1":{"normal":["chaser", "zoner"], "hard":["controller"], "nightmare":["support"], "story":"Brazier Suppressor"},
	"ch2_2":{"normal":["chaser", "controller"], "hard":["tank"], "nightmare":[], "story":"Frost Jailer"},
	"ch2_3":{"normal":["chaser"], "hard":["zoner"], "nightmare":[], "story":"Rune puzzle"},
	"ch2_4":{"normal":["chaser"], "hard":["charger"], "nightmare":[], "story":"Frost Mimics"},
	"ch2_5":{"normal":["chaser"], "hard":[], "nightmare":[], "story":"Frost Colossus boss"},
	"ch3_1":{"normal":["chaser", "zoner"], "hard":["controller"], "nightmare":["support"], "story":"Pool Reclaimers"},
	"ch3_2":{"normal":["chaser", "controller"], "hard":["support"], "nightmare":["charger"], "story":"Plaguebeast hunt"},
	"ch3_3":{"normal":["controller", "charger", "sniper"], "hard":["zoner"], "nightmare":["support"], "story":"Venom ecosystems"},
	"ch3_4":{"normal":["chaser", "charger"], "hard":["controller"], "nightmare":[], "story":"Antidote vial"},
	"ch3_5":{"normal":["chaser", "support"], "hard":["zoner"], "nightmare":[], "story":"Cauldron pressure"},
	"ch4_1":{"normal":["chaser", "charger", "zoner"], "hard":["tank"], "nightmare":["support"], "story":"Ore Thief"},
	"ch4_2":{"normal":["chaser", "tank"], "hard":["controller"], "nightmare":["zoner"], "story":"Forge Jammer"},
	"ch4_3":{"normal":["chaser"], "hard":["controller"], "nightmare":[], "story":"Repair Support"},
	"ch4_4":{"normal":["tank", "zoner"], "hard":["charger"], "nightmare":["summoner"], "story":"Chamber Guardians"},
	"ch4_5":{"normal":["chaser"], "hard":["zoner"], "nightmare":[], "story":"Regulators and Behemoth"},
	"ch5_1":{"normal":["chaser"], "hard":["controller"], "nightmare":[], "story":"Stealth Sentries"},
	"ch5_2":{"normal":["chaser", "controller"], "hard":["support"], "nightmare":[], "story":"Soul Binder"},
	"ch5_3":{"normal":[], "hard":[], "nightmare":[], "story":"Mirror Guardian"},
	"ch5_4":{"normal":["chaser", "charger"], "hard":["zoner"], "nightmare":["support"], "story":"Obelisk disruption"},
	"ch5_5":{"normal":["chaser"], "hard":["support"], "nightmare":[], "story":"Abyss King summons"},
}

const STORY_TARGETS := {
	"ch1_2":{"disruptor":["shrine"]},
	"ch2_1":{"disruptor":["brazier"]},
	"ch2_2":{"disruptor":["ice_prison"]},
	"ch3_1":{"disruptor":["corrupted_pool"]},
	"ch3_5":{"disruptor":["cauldron"]},
	"ch4_1":{"thief":["c4_ore_bag"]},
	"ch4_2":{"disruptor":["c4_forge_mechanism"]},
	"ch5_2":{"disruptor":["released_soul"]},
	"ch5_4":{"disruptor":["eclipse_obelisk"]},
}

static func roles_for(kind: String, story_tag: String = "") -> Array[String]:
	if not story_tag.is_empty():
		if STORY_TAG_ROLES.has(story_tag):
			return _typed_roles(STORY_TAG_ROLES[story_tag] as Array)
		for prefix_variant in STORY_TAG_PREFIX_ROLES:
			var prefix := str(prefix_variant)
			if story_tag.begins_with(prefix):
				return _typed_roles(STORY_TAG_PREFIX_ROLES[prefix] as Array)
	return _typed_roles(KIND_ROLES.get(kind, []) as Array)

static func primary_role(kind: String, story_tag: String = "") -> String:
	var roles := roles_for(kind, story_tag)
	return roles[0] if not roles.is_empty() else ""

static func is_role_kind(kind: String) -> bool:
	return kind in ROLE_KINDS.values()

static func kind_for_role(role: String) -> String:
	return str(ROLE_KINDS.get(role, "normal"))

static func stage_profile(stage_id: String) -> Dictionary:
	return (STAGE_PROFILES.get(stage_id, {}) as Dictionary).duplicate(true)

static func stage_roles(stage_id: String, difficulty_rank: int) -> Array[String]:
	var profile := stage_profile(stage_id)
	var out := _typed_roles(profile.get("normal", []) as Array)
	if difficulty_rank >= 1:
		_append_unique(out, profile.get("hard", []) as Array)
	if difficulty_rank >= 2:
		_append_unique(out, profile.get("nightmare", []) as Array)
	return out

static func composition(stage_id: String, difficulty_rank: int, count: int, rotation: int = 0) -> Array[String]:
	var result: Array[String] = []
	if count <= 0:
		return result
	var available := stage_roles(stage_id, difficulty_rank)
	if available.is_empty():
		for _index in count:
			result.append("normal")
		return result
	var attention_budget: int = int([2, 4, 6][clampi(difficulty_rank, 0, 2)])
	var attention_used := 0
	for index in count:
		var role := available[(index + rotation) % available.size()]
		var cost := int(ROLE_COSTS.get(role, 1))
		if role != "chaser" and attention_used + cost <= attention_budget:
			result.append(kind_for_role(role))
			attention_used += cost
		else:
			result.append("normal")
	return result

static func composition_roles(kinds: Array, story_tag: String = "") -> Array[String]:
	var roles: Array[String] = []
	for kind_variant in kinds:
		var role := primary_role(str(kind_variant), story_tag)
		if not role.is_empty():
			roles.append(role)
	return roles

static func complexity(roles: Array) -> int:
	var total := 0
	for role_variant in roles:
		total += int(ROLE_COSTS.get(str(role_variant), 0))
	return total

static func can_target_story_prop(stage_id: String, role: String, prop_kind: String) -> bool:
	var stage_targets := STORY_TARGETS.get(stage_id, {}) as Dictionary
	return prop_kind in (stage_targets.get(role, []) as Array)

static func max_active_normal(difficulty_rank: int, boss_active: bool = false) -> int:
	if boss_active:
		return [14, 16, 18][clampi(difficulty_rank, 0, 2)]
	return [34, 40, 46][clampi(difficulty_rank, 0, 2)]

static func max_hazards(difficulty_rank: int) -> int:
	return [4, 6, 8][clampi(difficulty_rank, 0, 2)]

static func max_summons(difficulty_rank: int) -> int:
	return [4, 6, 8][clampi(difficulty_rank, 0, 2)]

static func support_healed_hp(current_hp: float, max_hp: float, requested_ratio: float) -> float:
	var safe_max := maxf(max_hp, 1.0)
	var heal_ratio := clampf(requested_ratio, 0.0, 0.16)
	return minf(safe_max * 0.85, maxf(0.0, current_hp) + safe_max * heal_ratio)

static func can_add_summon(owner_count: int, global_count: int, difficulty_rank: int, active_normal: int, boss_active: bool = false) -> bool:
	return owner_count < 2 and global_count < max_summons(difficulty_rank) and active_normal < max_active_normal(difficulty_rank, boss_active)

static func controller_slow_duration(requested: float) -> float:
	return clampf(requested, 0.0, 0.85)

static func charger_speed(base_speed: float) -> float:
	return minf(maxf(base_speed, 0.0) * 3.8, 560.0)

static func validate() -> Array[String]:
	var issues: Array[String] = []
	for role in ROLES:
		if not ROLE_COSTS.has(role):
			issues.append("Missing role cost: %s" % role)
	for stage_id_variant in STAGE_PROFILES:
		var stage_id := str(stage_id_variant)
		var profile := STAGE_PROFILES[stage_id] as Dictionary
		for key in ["normal", "hard", "nightmare"]:
			for role_variant in profile.get(key, []) as Array:
				if str(role_variant) not in ROLES:
					issues.append("Unknown role: %s/%s" % [stage_id, str(role_variant)])
				elif not ROLE_KINDS.has(str(role_variant)):
					issues.append("Non-combat role in composition: %s/%s" % [stage_id, str(role_variant)])
	for stage_id_variant in STORY_TARGETS:
		var stage_id := str(stage_id_variant)
		if not STAGE_PROFILES.has(stage_id):
			issues.append("Unknown target stage: %s" % stage_id)
		for role_variant in (STORY_TARGETS[stage_id] as Dictionary):
			if str(role_variant) not in ["disruptor", "thief"]:
				issues.append("Unsafe Story target role: %s/%s" % [stage_id, str(role_variant)])
	return issues

static func _typed_roles(values: Array) -> Array[String]:
	var out: Array[String] = []
	for value_variant in values:
		out.append(str(value_variant))
	return out

static func _append_unique(target: Array[String], values: Array) -> void:
	for value_variant in values:
		var value := str(value_variant)
		if value not in target:
			target.append(value)
