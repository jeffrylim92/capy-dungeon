class_name ProgressionStore
extends RefCounted

## Persistent meta-progression. Stored separately so existing accounts/stats remain compatible.
const SAVE_PATH := "user://capy_progression.json"
const MAX_UPGRADE_LEVEL := 10

const UPGRADES := {
	"vitality": {"name": "Cozy Bed", "desc": "Rest between expeditions and begin every dungeon with 3% more maximum health per level.", "base_cost": 60, "icon": "res://assets/upgrades/camp_vitality.png", "color": Color(0.30, 0.92, 0.50), "effect": "Max HP", "effect_per_level": 3.0},
	"power": {"name": "Training Dummy", "desc": "Sharpen every combat technique, increasing all skill damage by 2% per level.", "base_cost": 75, "icon": "res://assets/upgrades/camp_power.png", "color": Color(1.0, 0.38, 0.24), "effect": "Skill damage", "effect_per_level": 2.0},
	"haste": {"name": "Clockwork Gym", "desc": "Practice perfect timing so every skill recharges 1.5% faster per level.", "base_cost": 85, "icon": "res://assets/upgrades/camp_haste.png", "color": Color(0.48, 0.70, 1.0), "effect": "Faster recharge", "effect_per_level": 1.5},
	"fortune": {"name": "Lucky Pond", "desc": "Make an offering before each run to earn 3% more camp coins per level.", "base_cost": 65, "icon": "res://assets/upgrades/camp_fortune.png", "color": Color(0.45, 0.92, 0.28), "effect": "Camp coins", "effect_per_level": 3.0},
	"wisdom": {"name": "Ancient Library", "desc": "Study old dungeon maps and gain 3% more experience from enemies per level.", "base_cost": 70, "icon": "res://assets/upgrades/camp_wisdom.png", "color": Color(0.76, 0.56, 1.0), "effect": "Experience", "effect_per_level": 3.0},
}

const DIFFICULTIES := [
	{"name": "Cozy", "enemy_hp": 1.0, "enemy_damage": 1.0, "reward": 1.0, "unlock_level": 1},
	{"name": "Wild", "enemy_hp": 1.25, "enemy_damage": 1.15, "reward": 1.35, "unlock_level": 3},
	{"name": "Nightmare", "enemy_hp": 1.60, "enemy_damage": 1.35, "reward": 1.80, "unlock_level": 7},
]

const MODIFIERS := [
	{"id": "bounty", "name": "Bounty Hunt", "desc": "Enemies are tougher; camp rewards +25%", "enemy_hp": 1.15, "reward": 1.25},
	{"id": "glass", "name": "Glass Cannon", "desc": "Deal +20% damage, but take +20% damage", "skill_dmg": 0.20, "damage_taken": 1.20},
	{"id": "rush", "name": "Capy Rush", "desc": "Move +12% faster; enemies deal +10% damage", "move_speed": 0.12, "damage_taken": 1.10},
	{"id": "scholar", "name": "Scholar's Trial", "desc": "Experience +20%; enemy health +20%", "xp_bonus": 0.20, "enemy_hp": 1.20},
]

const DAILY_MISSIONS := [
	{"id":"enemy_kills", "name":"Kill Enemies", "description":"Defeat 75 enemies in any combat mode.", "target":75, "reward":30},
	{"id":"survival_time", "name":"Survive for 10 Minutes", "description":"Spend a total of 10 minutes alive in Survival.", "target":600, "reward":40},
	{"id":"boss_kills", "name":"Defeat a Boss", "description":"Defeat 1 boss in any combat mode.", "target":1, "reward":45},
	{"id":"characters", "name":"Play 3 Different Characters", "description":"Start runs with 3 different capybara characters.", "target":3, "reward":45},
	{"id":"story_clears", "name":"Clear a Story Stage", "description":"Complete any Story stage once.", "target":1, "reward":35},
	{"id":"dungeon_clears", "name":"Clear a Dungeon Depth", "description":"Complete any depth in either resource dungeon.", "target":1, "reward":35},
	{"id":"survival_runs", "name":"Play Survival Once", "description":"Complete 1 Survival run.", "target":1, "reward":25},
]

static func _blank() -> Dictionary:
	return {"coins": 0, "account_xp": 0, "upgrades": {}, "mastery": {}, "difficulty": 0, "missions": {}, "claimed_unlocks": [], "dungeon_depths":{"coin_burrow":0, "forgecore":0}}

static func _load_all() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed as Dictionary if parsed is Dictionary else {}

static func _save_all(data: Dictionary) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

static func load_profile(username: String) -> Dictionary:
	var key := username.strip_edges().to_lower()
	var all := _load_all()
	var profile: Dictionary = (all.get(key, _blank()) as Dictionary).duplicate(true)
	for field in _blank().keys():
		if not profile.has(field):
			profile[field] = _blank()[field]
	_refresh_missions(profile)
	all[key] = profile
	_save_all(all)
	return profile

static func save_profile(username: String, profile: Dictionary) -> void:
	if username.strip_edges().is_empty():
		return
	profile["updated_at"] = int(Time.get_unix_time_from_system())
	var all := _load_all()
	all[username.strip_edges().to_lower()] = profile
	_save_all(all)

static func cloud_snapshot(username: String) -> Dictionary:
	return load_profile(username).duplicate(true)

static func replace_profile(username: String, profile: Dictionary) -> void:
	save_profile(username, profile.duplicate(true))

static func restore_from_server(username: String, server_profile: Dictionary) -> void:
	if username.strip_edges().is_empty() or server_profile.is_empty():
		return
	var local := load_profile(username)
	var server_is_newer := int(server_profile.get("updated_at", 0)) > int(local.get("updated_at", 0))
	if server_is_newer:
		local["coins"] = int(server_profile.get("coins", 0))
		local["difficulty"] = int(server_profile.get("difficulty", 0))
		local["missions"] = (server_profile.get("missions", {}) as Dictionary).duplicate(true)
	local["account_xp"] = maxi(int(local.get("account_xp", 0)), int(server_profile.get("account_xp", 0)))
	for field in ["upgrades", "mastery"]:
		var merged: Dictionary = local.get(field, {}) as Dictionary
		for key in (server_profile.get(field, {}) as Dictionary):
			merged[key] = maxi(int(merged.get(key, 0)), int((server_profile.get(field, {}) as Dictionary)[key]))
		local[field] = merged
	var depths: Dictionary = local.get("dungeon_depths", {}) as Dictionary
	for dungeon_id in (server_profile.get("dungeon_depths", {}) as Dictionary):
		depths[dungeon_id] = maxi(int(depths.get(dungeon_id, 0)), int((server_profile.get("dungeon_depths", {}) as Dictionary)[dungeon_id]))
	local["dungeon_depths"] = depths
	var unlocks: Array = local.get("claimed_unlocks", []) as Array
	for value in server_profile.get("claimed_unlocks", []) as Array:
		if value not in unlocks:
			unlocks.append(value)
	local["claimed_unlocks"] = unlocks
	if not server_is_newer and int(local.get("difficulty", 0)) == 0:
		local["difficulty"] = int(server_profile.get("difficulty", 0))
	local["updated_at"] = maxi(int(local.get("updated_at", 0)), int(server_profile.get("updated_at", 0)))
	save_profile(username, local)

static func purge_user(username: String) -> void:
	var key := username.strip_edges().to_lower()
	if key.is_empty():
		return
	var all := _load_all()
	all.erase(key)
	_save_all(all)

static func account_level(profile: Dictionary) -> int:
	return 1 + int(floor(sqrt(float(maxi(int(profile.get("account_xp", 0)), 0)) / 120.0)))

static func xp_for_next_level(profile: Dictionary) -> int:
	var level := account_level(profile)
	return level * level * 120

static func xp_level_start(profile: Dictionary) -> int:
	var level := account_level(profile)
	return (level - 1) * (level - 1) * 120

static func xp_progress(profile: Dictionary) -> Dictionary:
	var total := maxi(int(profile.get("account_xp", 0)), 0)
	var start := xp_level_start(profile)
	var target := xp_for_next_level(profile)
	return {"current": total - start, "needed": target - start, "total": total}

static func upgrade_level(profile: Dictionary, id: String) -> int:
	return int((profile.get("upgrades", {}) as Dictionary).get(id, 0))

static func upgrade_cost(profile: Dictionary, id: String) -> int:
	var definition: Dictionary = UPGRADES.get(id, {}) as Dictionary
	var level := upgrade_level(profile, id)
	return int(definition.get("base_cost", 75)) * (level + 1)

static func upgrade_effect_text(profile: Dictionary, id: String) -> String:
	var definition: Dictionary = UPGRADES.get(id, {}) as Dictionary
	var total := float(definition.get("effect_per_level", 0.0)) * float(upgrade_level(profile, id))
	var amount := "%.1f" % total if not is_equal_approx(total, round(total)) else str(int(round(total)))
	return "+%s%% %s" % [amount, String(definition.get("effect", "bonus"))]

static func buy_upgrade(username: String, id: String) -> String:
	if not UPGRADES.has(id):
		return "Unknown upgrade."
	var profile := load_profile(username)
	var level := upgrade_level(profile, id)
	if level >= MAX_UPGRADE_LEVEL:
		return "Already at maximum level."
	var cost := upgrade_cost(profile, id)
	if int(profile.get("coins", 0)) < cost:
		return "Not enough camp coins."
	profile["coins"] = int(profile.get("coins", 0)) - cost
	var levels: Dictionary = profile.get("upgrades", {}) as Dictionary
	levels[id] = level + 1
	profile["upgrades"] = levels
	save_profile(username, profile)
	return ""

static func set_difficulty(username: String, index: int) -> void:
	var profile := load_profile(username)
	var allowed := 0
	for i in DIFFICULTIES.size():
		if account_level(profile) >= int((DIFFICULTIES[i] as Dictionary).get("unlock_level", 1)):
			allowed = i
	profile["difficulty"] = clampi(index, 0, allowed)
	save_profile(username, profile)

static func difficulty(profile: Dictionary) -> Dictionary:
	return (DIFFICULTIES[clampi(int(profile.get("difficulty", 0)), 0, DIFFICULTIES.size() - 1)] as Dictionary).duplicate(true)

static func daily_modifier() -> Dictionary:
	var date: Dictionary = Time.get_date_dict_from_system()
	var day_key := int(date.get("year", 0)) * 400 + int(date.get("month", 0)) * 31 + int(date.get("day", 0))
	return (MODIFIERS[posmod(day_key, MODIFIERS.size())] as Dictionary).duplicate(true)

static func gameplay_bonuses(profile: Dictionary, character_id: String = "") -> Dictionary:
	var mastery_damage := minf(float(mastery_level(profile, character_id) - 1) * 0.01, 0.10) if not character_id.is_empty() else 0.0
	return {
		"max_hp_pct": float(upgrade_level(profile, "vitality")) * 0.03,
		"skill_dmg": float(upgrade_level(profile, "power")) * 0.02 + mastery_damage,
		"skill_cd": float(upgrade_level(profile, "haste")) * 0.015,
		"xp_bonus": float(upgrade_level(profile, "wisdom")) * 0.03,
	}

static func record_run(username: String, character_id: String, kills: int, seconds: float, wave: int) -> Dictionary:
	var profile := load_profile(username)
	var diff := difficulty(profile)
	var modifier := daily_modifier()
	var reward_mult := float(diff.get("reward", 1.0)) * float(modifier.get("reward", 1.0))
	reward_mult *= 1.0 + float(upgrade_level(profile, "fortune")) * 0.03
	var coins := maxi(10, int(round((10.0 + float(kills) * 0.45 + seconds / 18.0 + float(wave) * 3.0) * reward_mult)))
	var xp := maxi(8, int(round((8.0 + float(kills) * 0.30 + seconds / 25.0 + float(wave) * 2.0) * reward_mult)))
	profile["coins"] = int(profile.get("coins", 0)) + coins
	profile["account_xp"] = int(profile.get("account_xp", 0)) + xp
	var mastery: Dictionary = profile.get("mastery", {}) as Dictionary
	mastery[character_id] = int(mastery.get(character_id, 0)) + xp
	profile["mastery"] = mastery
	_add_mission_progress(profile, "enemy_kills", kills)
	_add_mission_progress(profile, "survival_time", int(seconds))
	_add_mission_progress(profile, "survival_runs", 1)
	save_profile(username, profile)
	return {"coins": coins, "xp": xp, "level": account_level(profile), "mastery_level": mastery_level(profile, character_id), "next_unlock": next_unlock(profile)}

static func mastery_level(profile: Dictionary, character_id: String) -> int:
	return 1 + int((profile.get("mastery", {}) as Dictionary).get(character_id, 0)) / 250

static func next_unlock(profile: Dictionary) -> String:
	var level := account_level(profile)
	if level < 3: return "Wild difficulty at Camp Level 3"
	if level < 5: return "Treasure Hunter title at Camp Level 5"
	if level < 7: return "Nightmare difficulty at Camp Level 7"
	if level < 10: return "Golden Camp badge at Camp Level 10"
	return "All camp milestones unlocked — raise character mastery!"

static func missions(profile: Dictionary, period: String = "daily") -> Array[Dictionary]:
	_refresh_missions(profile)
	var data: Dictionary = profile.get("missions", {}) as Dictionary
	var counters: Dictionary = data.get("%s_progress" % period, {}) as Dictionary
	var claimed: Array = data.get("%s_claimed" % period, []) as Array
	var out: Array[Dictionary] = []
	for definition_variant in DAILY_MISSIONS:
		var definition: Dictionary = (definition_variant as Dictionary).duplicate(true)
		var multiplier := 7 if period == "weekly" else 1
		definition["period"] = period
		definition["progress"] = int(counters.get(definition.id, 0))
		definition["target"] = int(definition.target) * multiplier
		definition["reward"] = int(definition.reward) * (5 if period == "weekly" else 1)
		if period == "weekly" and String(definition.id) == "characters":
			definition["name"] = "Play 21 Character Runs"
			definition["description"] = "Start 21 runs using any capybara characters during the week."
		if period == "weekly" and String(definition.id) == "survival_time":
			definition["name"] = "Survive for 70 Minutes"
			definition["description"] = "Spend a total of 70 minutes alive in Survival during the week."
		definition["claimed"] = String(definition.id) in claimed
		out.append(definition)
	return out

static func claim_mission(username: String, mission_id: String, period: String = "daily") -> int:
	var profile := load_profile(username)
	var reward := _claim_mission_in_profile(profile, mission_id, period)
	if reward > 0:
		profile["coins"] = int(profile.get("coins", 0)) + reward
		save_profile(username, profile)
	return reward

static func claim_all_missions(username: String, period: String = "daily") -> int:
	var profile := load_profile(username)
	var total := 0
	for definition in DAILY_MISSIONS:
		total += _claim_mission_in_profile(profile, String((definition as Dictionary).id), period)
	if total > 0:
		profile["coins"] = int(profile.get("coins", 0)) + total
		save_profile(username, profile)
	return total

static func _claim_mission_in_profile(profile: Dictionary, mission_id: String, period: String) -> int:
	_refresh_missions(profile)
	var data: Dictionary = profile.get("missions", {}) as Dictionary
	var claimed: Array = data.get("%s_claimed" % period, []) as Array
	var reward := 0
	for mission in missions(profile, period):
		if String(mission.id) == mission_id and int(mission.progress) >= int(mission.target) and mission_id not in claimed:
			claimed.append(mission_id)
			reward = int(mission.reward)
			break
	data["%s_claimed" % period] = claimed
	profile["missions"] = data
	return reward

static func _refresh_missions(profile: Dictionary) -> void:
	var now := Time.get_date_dict_from_system()
	var daily_key := "%04d-%02d-%02d" % [int(now.year), int(now.month), int(now.day)]
	var weekly_key := str(int(Time.get_unix_time_from_system() / 604800.0))
	var m: Dictionary = profile.get("missions", {}) as Dictionary
	if String(m.get("daily_key", "")) != daily_key:
		m["daily_key"] = daily_key; m["daily_progress"] = {}; m["daily_claimed"] = []; m["daily_characters"] = []
	if String(m.get("weekly_key", "")) != weekly_key:
		m["weekly_key"] = weekly_key; m["weekly_progress"] = {}; m["weekly_claimed"] = []; m["weekly_characters"] = []
	# Migrate mission fields created by the previous three-mission format.
	for period in ["daily", "weekly"]:
		var progress_key := "%s_progress" % period
		var claimed_key := "%s_claimed" % period
		var characters_key := "%s_characters" % period
		if typeof(m.get(progress_key, null)) != TYPE_DICTIONARY:
			m[progress_key] = {}
		if typeof(m.get(claimed_key, null)) != TYPE_ARRAY:
			m[claimed_key] = []
		if typeof(m.get(characters_key, null)) != TYPE_ARRAY:
			m[characters_key] = []
	profile["missions"] = m

static func record_mission_event(username: String, mission_id: String, amount: int = 1, character_id: String = "") -> void:
	var profile := load_profile(username)
	if mission_id == "characters": _add_mission_character(profile, character_id)
	else: _add_mission_progress(profile, mission_id, amount)
	save_profile(username, profile)

static func _add_mission_progress(profile: Dictionary, mission_id: String, amount: int) -> void:
	_refresh_missions(profile)
	var m: Dictionary = profile.get("missions", {}) as Dictionary
	for period in ["daily", "weekly"]:
		var counters: Dictionary = m.get("%s_progress" % period, {}) as Dictionary
		counters[mission_id] = int(counters.get(mission_id, 0)) + amount
		m["%s_progress" % period] = counters
	profile["missions"] = m

static func _add_mission_character(profile: Dictionary, character_id: String) -> void:
	if character_id.is_empty(): return
	_refresh_missions(profile)
	var m: Dictionary = profile.get("missions", {}) as Dictionary
	for period in ["daily", "weekly"]:
		var characters: Array = m.get("%s_characters" % period, []) as Array
		if character_id not in characters: characters.append(character_id)
		m["%s_characters" % period] = characters
		var counters: Dictionary = m.get("%s_progress" % period, {}) as Dictionary
		counters["characters"] = int(counters.get("characters", 0)) + 1 if period == "weekly" else characters.size()
		m["%s_progress" % period] = counters
	profile["missions"] = m

static func record_dungeon_run(username: String, dungeon_id: String, depth: int, extracted_amount: int = -1) -> Dictionary:
	var profile := load_profile(username)
	var depths: Dictionary = profile.get("dungeon_depths", {}) as Dictionary
	depths[dungeon_id] = maxi(int(depths.get(dungeon_id, 0)), depth)
	profile["dungeon_depths"] = depths
	if depth > 0: _add_mission_progress(profile, "dungeon_clears", depth)
	# Resource dungeons are repeatable, so rewards scale steadily without
	# eclipsing one-time Story clears or the broader Survival reward bundle.
	var reward := extracted_amount if dungeon_id == "coin_burrow" and extracted_amount >= 0 else (35 + depth * 12 if depth > 0 else 0)
	if dungeon_id == "coin_burrow": profile["coins"] = int(profile.get("coins", 0)) + reward
	save_profile(username, profile)
	var material_reward := maxi(1, ceili(float(depth) * 0.75)) if depth > 0 else 0
	return {"coins":reward if dungeon_id == "coin_burrow" else 0, "materials":material_reward if dungeon_id == "forgecore" else 0, "depth":depth}

static func record_dungeon_depth_completed(username: String, dungeon_id: String, depth: int) -> void:
	if username.is_empty() or dungeon_id.is_empty() or depth < 1:
		return
	var profile := load_profile(username)
	var depths: Dictionary = profile.get("dungeon_depths", {}) as Dictionary
	if depth <= int(depths.get(dungeon_id, 0)):
		return
	depths[dungeon_id] = depth
	profile["dungeon_depths"] = depths
	save_profile(username, profile)
