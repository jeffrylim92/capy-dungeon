class_name StoryMutators
extends RefCounted

const MAX_ACTIVE := 3
const REWARD_MULTIPLIER_CAP := 2.0

const DEFINITIONS := [
	{"id":"glass_capy", "name":"Glass Capy", "category":"Player", "description":"Deal +35% damage, but lose 35% Max HP.", "reward_weight":0.20, "unlock_chapter":1, "incompatible":[], "restricted_stages":{}},
	{"id":"heavy_armour", "name":"Heavy Armour", "category":"Player", "description":"Take 20% less damage, but move 15% slower.", "reward_weight":0.10, "unlock_chapter":1, "incompatible":[], "restricted_stages":{}},
	{"id":"no_healing", "name":"No Healing", "category":"Resource", "description":"Normal healing and potions are disabled.", "reward_weight":0.30, "unlock_chapter":1, "incompatible":["scarce_recovery"], "restricted_stages":{}},
	{"id":"scarce_recovery", "name":"Scarce Recovery", "category":"Resource", "description":"Recovery drop chance is reduced by 50%.", "reward_weight":0.15, "unlock_chapter":1, "incompatible":["no_healing"], "restricted_stages":{}},
	{"id":"elite_hunt", "name":"Elite Hunt", "category":"Enemy", "description":"Some normal hostiles become tougher elite enemies.", "reward_weight":0.20, "unlock_chapter":1, "incompatible":[], "restricted_stages":{}},
	{"id":"aggressive_enemies", "name":"Aggressive Enemies", "category":"Enemy", "description":"Normal hostiles pursue and recover attacks faster.", "reward_weight":0.15, "unlock_chapter":3, "incompatible":[], "restricted_stages":{}},
	{"id":"empowered_enemies", "name":"Empowered Enemies", "category":"Enemy", "description":"Eligible hostiles gain 10% health and 15% damage.", "reward_weight":0.15, "unlock_chapter":3, "incompatible":[], "restricted_stages":{}},
	{"id":"volatile_enemies", "name":"Volatile Enemies", "category":"Enemy", "description":"Some hostiles explode after a clear death warning.", "reward_weight":0.15, "unlock_chapter":3, "incompatible":[], "restricted_stages":{}},
	{"id":"corrupted_ground", "name":"Corrupted Ground", "category":"Environment", "description":"Some hostile deaths leave temporary hazard patches.", "reward_weight":0.20, "unlock_chapter":3, "incompatible":[], "restricted_stages":{}},
	{"id":"frostbite", "name":"Frostbite", "category":"Player", "description":"Standing still builds a chill that briefly slows movement.", "reward_weight":0.15, "unlock_chapter":3, "incompatible":[], "restricted_stages":{}},
	{"id":"hunters_mark", "name":"Hunter's Mark", "category":"Special", "description":"A stronger marked hostile periodically grants bonus XP.", "reward_weight":0.10, "unlock_chapter":3, "incompatible":[], "restricted_stages":{}},
	{"id":"pressure_wave", "name":"Pressure Wave", "category":"Environment", "description":"Telegraphed pressure walls periodically sweep the arena.", "reward_weight":0.20, "unlock_chapter":3, "incompatible":[], "restricted_stages":{"ch5_3":"Disabled during Mirror Labyrinth deduction."}},
	{"id":"berserk_elites", "name":"Berserk Elites", "category":"Enemy", "description":"Elite Hunt enemies enrage below 30% health.", "reward_weight":0.15, "unlock_chapter":5, "requires":["elite_hunt"], "incompatible":[], "restricted_stages":{}},
	{"id":"chaos_supply", "name":"Chaos Supply", "category":"Resource", "description":"Optional enemy rewards rotate through fair supply effects.", "reward_weight":0.10, "unlock_chapter":5, "incompatible":[], "restricted_stages":{}},
	{"id":"relentless", "name":"Relentless", "category":"Special", "description":"Eligible quiet gaps and ambient spawn delays are shorter.", "reward_weight":0.25, "unlock_chapter":5, "incompatible":[], "restricted_stages":{"ch5_1":"Disabled to preserve stealth routing.", "ch5_3":"Disabled to preserve Mirror Labyrinth deduction."}},
]

static func definition(mutator_id: String) -> Dictionary:
	for definition_variant in DEFINITIONS:
		var item: Dictionary = definition_variant as Dictionary
		if str(item.get("id", "")) == mutator_id:
			return item.duplicate(true)
	return {}

static func display_name(mutator_id: String) -> String:
	return str(definition(mutator_id).get("name", mutator_id))

static func names(mutator_ids: Array) -> Array[String]:
	var out: Array[String] = []
	for mutator_id_variant in mutator_ids:
		var mutator_id := str(mutator_id_variant)
		if not definition(mutator_id).is_empty():
			out.append(display_name(mutator_id))
	return out

static func is_unlocked(profile: Dictionary, mutator_id: String) -> bool:
	var item := definition(mutator_id)
	if item.is_empty():
		return false
	var required_chapter := int(item.get("unlock_chapter", 1))
	return "ch%d_5" % required_chapter in (profile.get("cleared", []) as Array)

static func stage_restriction(mutator_id: String, stage_id: String) -> String:
	var item := definition(mutator_id)
	if item.is_empty():
		return "Unknown Mutator."
	return str((item.get("restricted_stages", {}) as Dictionary).get(stage_id, ""))

static func selection_issue(profile: Dictionary, stage_id: String, selected_ids: Array, candidate_id: String, bypass_unlocks: bool = false) -> String:
	var item := definition(candidate_id)
	if item.is_empty():
		return "Unknown Mutator."
	if candidate_id in selected_ids:
		return ""
	var restriction := stage_restriction(candidate_id, stage_id)
	if not restriction.is_empty():
		return restriction
	if not bypass_unlocks and not is_unlocked(profile, candidate_id):
		return "Locked · Clear Chapter %d." % int(item.get("unlock_chapter", 1))
	if selected_ids.size() >= MAX_ACTIVE:
		return "Maximum %d Mutators selected." % MAX_ACTIVE
	for required_variant in item.get("requires", []) as Array:
		var required_id := str(required_variant)
		if required_id not in selected_ids:
			return "Requires %s." % display_name(required_id)
	var incompatible: Array = item.get("incompatible", []) as Array
	for selected_variant in selected_ids:
		var selected_id := str(selected_variant)
		var selected_item := definition(selected_id)
		if selected_id in incompatible or candidate_id in (selected_item.get("incompatible", []) as Array):
			return "Incompatible with %s." % display_name(selected_id)
	return ""

static func sanitize_selection(profile: Dictionary, stage_id: String, requested_ids: Array, bypass_unlocks: bool = false) -> Array[String]:
	var out: Array[String] = []
	for mutator_id_variant in requested_ids:
		var mutator_id := str(mutator_id_variant)
		if mutator_id in out:
			continue
		if selection_issue(profile, stage_id, out, mutator_id, bypass_unlocks).is_empty():
			out.append(mutator_id)
	return out

static func reward_bonus(mutator_ids: Array) -> float:
	var total := 0.0
	var seen: Array[String] = []
	for mutator_id_variant in mutator_ids:
		var mutator_id := str(mutator_id_variant)
		if mutator_id in seen:
			continue
		var item := definition(mutator_id)
		if not item.is_empty():
			total += maxf(0.0, float(item.get("reward_weight", 0.0)))
			seen.append(mutator_id)
	return minf(total, REWARD_MULTIPLIER_CAP - 1.0)

static func reward_multiplier(mutator_ids: Array) -> float:
	return 1.0 + reward_bonus(mutator_ids)

static func runtime_config(stage_id: String, mutator_ids: Array) -> Dictionary:
	var ids := sanitize_selection({}, stage_id, mutator_ids, true)
	var speed_multiplier := 1.0
	if "heavy_armour" in ids:
		# Twin Eclipse keeps enough movement headroom for the synchronization route.
		speed_multiplier *= 0.92 if stage_id == "ch5_4" else 0.85
	return {
		"player_damage":1.35 if "glass_capy" in ids else 1.0,
		"player_max_hp":0.65 if "glass_capy" in ids else 1.0,
		"player_speed":speed_multiplier,
		"damage_taken":0.80 if "heavy_armour" in ids else 1.0,
		"healing_enabled":"no_healing" not in ids,
		"recovery_drop_multiplier":0.50 if "scarce_recovery" in ids else 1.0,
	}

static func apply_to_stage(stage_data: Dictionary, mutator_ids: Array, profile: Dictionary = {}, bypass_unlocks: bool = false) -> Dictionary:
	var configured := stage_data.duplicate(true)
	var stage_id := str(configured.get("id", ""))
	var ids := sanitize_selection(profile, stage_id, mutator_ids, bypass_unlocks)
	configured["mutators"] = ids
	configured["mutator_names"] = names(ids)
	configured["mutator_config"] = runtime_config(stage_id, ids)
	configured["mutator_reward_bonus"] = reward_bonus(ids)
	configured["mutator_reward_multiplier"] = reward_multiplier(ids)
	return configured

static func validate_definitions() -> Array[String]:
	var issues: Array[String] = []
	var ids: Array[String] = []
	for definition_variant in DEFINITIONS:
		var item: Dictionary = definition_variant as Dictionary
		var mutator_id := str(item.get("id", ""))
		if mutator_id.is_empty() or mutator_id in ids:
			issues.append("Duplicate or empty Mutator ID: %s" % mutator_id)
		else:
			ids.append(mutator_id)
		var weight := float(item.get("reward_weight", -1.0))
		if weight < 0.0 or weight > 1.0:
			issues.append("Invalid reward weight: %s" % mutator_id)
	for definition_variant in DEFINITIONS:
		var item: Dictionary = definition_variant as Dictionary
		for incompatible_variant in item.get("incompatible", []) as Array:
			var incompatible_id := str(incompatible_variant)
			if incompatible_id not in ids:
				issues.append("Invalid incompatibility: %s -> %s" % [str(item.get("id", "")), incompatible_id])
			elif str(item.get("id", "")) not in (definition(incompatible_id).get("incompatible", []) as Array):
				issues.append("Asymmetric incompatibility: %s -> %s" % [str(item.get("id", "")), incompatible_id])
		for required_variant in item.get("requires", []) as Array:
			if str(required_variant) not in ids:
				issues.append("Invalid requirement: %s -> %s" % [str(item.get("id", "")), str(required_variant)])
		for stage_id_variant in (item.get("restricted_stages", {}) as Dictionary).keys():
			var stage_id := str(stage_id_variant)
			var chapter_number := stage_id.get_slice("_", 0).trim_prefix("ch").to_int()
			var stage_number := stage_id.get_slice("_", 1).to_int()
			if not stage_id.begins_with("ch") or chapter_number < 1 or chapter_number > 5 or stage_number < 1 or stage_number > 5:
				issues.append("Invalid stage restriction: %s -> %s" % [str(item.get("id", "")), stage_id])
	return issues
