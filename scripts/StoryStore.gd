class_name StoryStore
extends RefCounted

const SAVE_PREFIX := "user://capy_story_"
const MAX_GEAR_LEVEL := 10
const SLOTS := ["weapon", "armor", "pants", "offhand", "headwear", "boots"]

const CHAPTERS := [
	{"name":"THE STOLEN CAMP CREST", "theme":"mushroom woodland", "reward":["twig_blade", "scout_cap"], "stages":["The Broken Trail", "Mushroom Crossing", "Supply Thieves", "The Old Watchpath", "Crestkeeper's Gate"]},
	{"name":"LANTERNS OF THE DROWNED MARSH", "theme":"drowned marsh", "reward":["moss_vest", "trail_boots"], "stages":["Fogbound Causeway", "Lantern Fen", "Roots Below", "The Sunken Bell", "Marshlight Guardian"]},
	{"name":"THE EMBER PANTRY", "theme":"ember kitchen", "reward":["pan_lid", "forager_pants"], "stages":["Scorched Larder", "Boiling Galleries", "Spice-Mine Tunnels", "Furnace Feast", "The Cinder Chef"]},
	{"name":"THORNWATCH SIEGE", "theme":"thorn ruins", "reward":["thorn_spear", "bark_mail"], "stages":["Briar Approach", "Vinebound Ruins", "The Green Rampart", "Heart of Thorns", "Thornwatch Tyrant"]},
	{"name":"WARDEN OF THE HOLLOW", "theme":"root cathedral", "reward":["warden_helm", "root_guard"], "stages":["Rootbound Nave", "Antlered Hall", "Runestone Choir", "The Deep Sanctuary", "Hollow Warden"]},
	{"name":"THE ECLIPSE CITADEL", "theme":"eclipse citadel", "reward":["warden_greaves", "hollow_treads"], "stages":["Starfall Ascent", "The Black-Gold Bridge", "Astral Courtyard", "Eclipse Throne", "Lord of the Last Night"]},
]

const GEAR := {
	"twig_blade":{"name":"Trailblazer Twig", "slot":"weapon", "effects":{"skill_dmg":0.06, "crit_chance":0.02}},
	"scout_cap":{"name":"Scout's Leaf Cap", "slot":"headwear", "effects":{"xp_bonus":0.08, "max_hp_pct":0.03}},
	"moss_vest":{"name":"Moss-Stitched Vest", "slot":"armor", "effects":{"max_hp_pct":0.08, "damage_taken_mul":-0.03}},
	"trail_boots":{"name":"Quickstep Sandals", "slot":"boots", "effects":{"move_speed_mul":0.06, "xp_bonus":0.03}},
	"pan_lid":{"name":"Chef's Pan Lid", "slot":"offhand", "effects":{"max_hp_pct":0.05, "damage_taken_mul":-0.04}},
	"forager_pants":{"name":"Forager Trousers", "slot":"pants", "effects":{"xp_bonus":0.07, "move_speed_mul":0.03}},
	"thorn_spear":{"name":"Thornwatch Spear", "slot":"weapon", "effects":{"skill_dmg":0.11, "boss_dmg":0.05}},
	"bark_mail":{"name":"Ironbark Mail", "slot":"armor", "effects":{"max_hp_pct":0.14, "damage_taken_mul":-0.06}},
	"warden_helm":{"name":"Hollow Warden Helm", "slot":"headwear", "effects":{"crit_chance":0.07, "skill_dmg":0.04}},
	"root_guard":{"name":"Rootbound Guard", "slot":"offhand", "effects":{"boss_dmg":0.12, "damage_taken_mul":-0.05}},
	"warden_greaves":{"name":"Warden Greaves", "slot":"pants", "effects":{"skill_dmg":0.07, "max_hp_pct":0.06}},
	"hollow_treads":{"name":"Hollow Treads", "slot":"boots", "effects":{"move_speed_mul":0.10, "damage_taken_mul":-0.03}},
}

static func _path(username: String) -> String:
	return SAVE_PREFIX + username.sha256_text().left(20) + ".json"

static func load_profile(username: String) -> Dictionary:
	var base := {"cleared":[], "claimed":[], "claimed_chapters":[], "owned":[], "equipped":{}, "materials":0, "levels":{}}
	if username.is_empty() or not FileAccess.file_exists(_path(username)):
		return base
	var file := FileAccess.open(_path(username), FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	if typeof(parsed) == TYPE_DICTIONARY:
		base.merge(parsed as Dictionary, true)
	return base

static func _save(username: String, profile: Dictionary) -> void:
	if username.is_empty(): return
	profile["updated_at"] = int(Time.get_unix_time_from_system())
	var file := FileAccess.open(_path(username), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(profile))

static func cloud_snapshot(username: String) -> Dictionary:
	return load_profile(username).duplicate(true)

static func restore_from_server(username: String, server_profile: Dictionary) -> void:
	if username.is_empty() or server_profile.is_empty():
		return
	var local := load_profile(username)
	var server_is_newer := int(server_profile.get("updated_at", 0)) > int(local.get("updated_at", 0))
	for field in ["cleared", "claimed", "claimed_chapters", "owned"]:
		var merged: Array = local.get(field, []) as Array
		for value in server_profile.get(field, []) as Array:
			if value not in merged:
				merged.append(value)
		local[field] = merged
	var levels: Dictionary = local.get("levels", {}) as Dictionary
	for gear_id in (server_profile.get("levels", {}) as Dictionary):
		levels[gear_id] = maxi(int(levels.get(gear_id, 1)), int((server_profile.get("levels", {}) as Dictionary)[gear_id]))
	local["levels"] = levels
	if server_is_newer:
		local["materials"] = int(server_profile.get("materials", 0))
	var server_equipped: Dictionary = server_profile.get("equipped", {}) as Dictionary
	if server_is_newer or ((local.get("equipped", {}) as Dictionary).is_empty() and not server_equipped.is_empty()):
		local["equipped"] = server_equipped.duplicate(true)
	local["updated_at"] = maxi(int(local.get("updated_at", 0)), int(server_profile.get("updated_at", 0)))
	_save(username, local)

static func purge_user(username: String) -> void:
	if not username.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path(username)))

static func stage(index: int) -> Dictionary:
	var safe := clampi(index, 0, stage_count() - 1)
	var chapter_index := floori(float(safe) / 5.0)
	var chapter_stage := safe % 5
	var chapter: Dictionary = CHAPTERS[chapter_index] as Dictionary
	var hp := 1.08 + float(safe) * 0.055
	var damage := 1.0 + float(safe) * 0.04
	return {"id":"ch%d_%d" % [chapter_index + 1, chapter_stage + 1], "chapter":chapter_index + 1, "chapter_stage":chapter_stage + 1, "name":"%d-%d  %s" % [chapter_index + 1, chapter_stage + 1, String((chapter.stages as Array)[chapter_stage])], "story":"Advance through the %s and uncover the path ahead." % String(chapter.theme), "challenge":"Enemy health +%d%% · damage +%d%%%s" % [roundi((hp - 1.0) * 100.0), roundi((damage - 1.0) * 100.0), " · Chapter boss" if chapter_stage == 4 else ""], "enemy_hp":hp, "enemy_damage":damage, "boss":"abyss_gate_warden" if chapter_stage == 4 else "", "coins":25 + safe * 4, "materials":1 + chapter_index}

static func stage_count() -> int:
	return CHAPTERS.size() * 5

static func chapter(index: int) -> Dictionary:
	return CHAPTERS[clampi(index, 0, CHAPTERS.size() - 1)] as Dictionary

static func unlocked_stage(profile: Dictionary) -> int:
	for chapter_number in range(1, CHAPTERS.size() + 1):
		if is_chapter_complete(profile, chapter_number) and chapter_number not in (profile.get("claimed_chapters", []) as Array):
			return chapter_number * 5 - 1
	return mini((profile.get("cleared", []) as Array).size(), stage_count() - 1)

static func record_clear(username: String, stage_id: String) -> Dictionary:
	var profile := load_profile(username)
	var cleared: Array = profile.get("cleared", []) as Array
	var first_clear := stage_id not in cleared
	if stage_id in cleared:
		var replay_materials := 1 + floori(float(stage_index(stage_id)) / 5.0)
		profile["materials"] = int(profile.get("materials", 0)) + replay_materials
		_add_camp_coins(username, 8 + stage_index(stage_id) * 2)
		_save(username, profile)
		return {"first_clear":false, "materials":replay_materials, "coins":8 + stage_index(stage_id) * 2}
	if first_clear:
		cleared.append(stage_id)
		profile["cleared"] = cleared
	var stage_data := stage(stage_index(stage_id))
	profile["materials"] = int(profile.get("materials", 0)) + int(stage_data.materials)
	_add_camp_coins(username, int(stage_data.coins))
	_save(username, profile)
	return {"first_clear":true, "materials":int(stage_data.materials), "coins":int(stage_data.coins)}

static func claim_chapter(username: String, chapter_number: int) -> Array[String]:
	var profile := load_profile(username)
	var final_stage_id := "ch%d_5" % chapter_number
	if final_stage_id not in (profile.get("cleared", []) as Array) or chapter_number in (profile.get("claimed_chapters", []) as Array):
		return []
	var claimed: Array = profile.get("claimed_chapters", []) as Array
	claimed.append(chapter_number)
	profile["claimed_chapters"] = claimed
	var owned: Array = profile.get("owned", []) as Array
	var newly_owned: Array[String] = []
	for gear_id in (chapter(chapter_number - 1).get("reward", []) as Array):
		if gear_id not in owned:
			owned.append(gear_id)
			newly_owned.append(String(gear_id))
	profile["owned"] = owned
	_save(username, profile)
	return newly_owned

static func stage_index(stage_id: String) -> int:
	var parts := stage_id.trim_prefix("ch").split("_")
	if parts.size() != 2: return 0
	return maxi(0, (int(parts[0]) - 1) * 5 + int(parts[1]) - 1)

static func is_chapter_complete(profile: Dictionary, chapter_number: int) -> bool:
	return "ch%d_5" % chapter_number in (profile.get("cleared", []) as Array)

static func _add_camp_coins(username: String, amount: int) -> void:
	var camp := ProgressionStore.load_profile(username)
	camp["coins"] = int(camp.get("coins", 0)) + amount
	ProgressionStore.save_profile(username, camp)

static func equip(username: String, gear_id: String) -> void:
	var profile := load_profile(username)
	if gear_id not in (profile.get("owned", []) as Array) or not GEAR.has(gear_id): return
	var equipped: Dictionary = profile.get("equipped", {}) as Dictionary
	equipped[String((GEAR[gear_id] as Dictionary).get("slot", ""))] = gear_id
	profile["equipped"] = equipped
	_save(username, profile)

static func unequip(username: String, gear_id: String) -> void:
	var profile := load_profile(username)
	var equipped: Dictionary = profile.get("equipped", {}) as Dictionary
	for slot in equipped.keys():
		if String(equipped[slot]) == gear_id: equipped.erase(slot)
	profile["equipped"] = equipped
	_save(username, profile)

static func is_equipped(profile: Dictionary, gear_id: String) -> bool:
	return gear_id in (profile.get("equipped", {}) as Dictionary).values()

static func bonuses(username: String) -> Dictionary:
	var out := {}
	var profile := load_profile(username)
	var equipped: Dictionary = profile.get("equipped", {}) as Dictionary
	for gear_id in equipped.values():
		if not GEAR.has(gear_id): continue
		for key in ((GEAR[gear_id] as Dictionary).get("effects", {}) as Dictionary):
			out[key] = float(out.get(key, 0.0)) + scaled_effect(profile, String(gear_id), String(key))
	return out

static func gear_level(profile: Dictionary, gear_id: String) -> int:
	return maxi(1, int((profile.get("levels", {}) as Dictionary).get(gear_id, 1)))

static func scaled_effect(profile: Dictionary, gear_id: String, key: String) -> float:
	if not GEAR.has(gear_id): return 0.0
	var base := float(((GEAR[gear_id] as Dictionary).get("effects", {}) as Dictionary).get(key, 0.0))
	return base * (1.0 + float(gear_level(profile, gear_id) - 1) * 0.18)

static func upgrade_cost(profile: Dictionary, gear_id: String) -> Dictionary:
	var level := gear_level(profile, gear_id)
	return {"materials":level + 1, "coins":40 + level * 35}

static func upgrade(username: String, gear_id: String) -> String:
	var profile := load_profile(username)
	if gear_id not in (profile.get("owned", []) as Array): return "Equipment not owned."
	var level := gear_level(profile, gear_id)
	if level >= MAX_GEAR_LEVEL: return "Maximum level reached."
	var cost := upgrade_cost(profile, gear_id)
	if int(profile.get("materials", 0)) < int(cost.materials): return "Not enough upgrade materials."
	var camp := ProgressionStore.load_profile(username)
	if int(camp.get("coins", 0)) < int(cost.coins): return "Not enough camp coins."
	profile["materials"] = int(profile.get("materials", 0)) - int(cost.materials)
	var levels: Dictionary = profile.get("levels", {}) as Dictionary
	levels[gear_id] = level + 1
	profile["levels"] = levels
	camp["coins"] = int(camp.get("coins", 0)) - int(cost.coins)
	_save(username, profile)
	ProgressionStore.save_profile(username, camp)
	return ""

static func reset_material_refund(profile: Dictionary, gear_id: String) -> int:
	var refund := 0
	for level in range(1, gear_level(profile, gear_id)):
		refund += level + 1
	return refund

static func reset_coin_refund(profile: Dictionary, gear_id: String) -> int:
	var refund := 0
	for level in range(1, gear_level(profile, gear_id)):
		refund += 40 + level * 35
	return refund

static func reset_upgrade(username: String, gear_id: String) -> int:
	var profile := load_profile(username)
	if gear_id not in (profile.get("owned", []) as Array):
		return 0
	var refund := reset_material_refund(profile, gear_id)
	if refund <= 0:
		return 0
	var coin_refund := reset_coin_refund(profile, gear_id)
	var levels: Dictionary = profile.get("levels", {}) as Dictionary
	levels[gear_id] = 1
	profile["levels"] = levels
	profile["materials"] = int(profile.get("materials", 0)) + refund
	var camp := ProgressionStore.load_profile(username)
	camp["coins"] = int(camp.get("coins", 0)) + coin_refund
	_save(username, profile)
	ProgressionStore.save_profile(username, camp)
	return refund

static func effect_text(gear_id: String) -> String:
	if not GEAR.has(gear_id): return ""
	var effects: Dictionary = (GEAR[gear_id] as Dictionary).get("effects", {}) as Dictionary
	var parts: Array[String] = []
	for key in effects:
		parts.append("%s +%d%%" % [stat_name(String(key)), display_percent(String(key), float(effects[key]))])
	return ", ".join(parts)

static func scaled_effect_text(profile: Dictionary, gear_id: String) -> String:
	if not GEAR.has(gear_id): return ""
	var parts: Array[String] = []
	for key in ((GEAR[gear_id] as Dictionary).get("effects", {}) as Dictionary):
		parts.append("%s +%d%%" % [stat_name(String(key)), display_percent(String(key), scaled_effect(profile, gear_id, String(key)))])
	return ", ".join(parts)

static func stat_name(key: String) -> String:
	match key:
		"skill_dmg": return "Attack"
		"max_hp_pct": return "HP"
		"damage_taken_mul": return "Defense"
		"move_speed_mul": return "Move Speed"
		"crit_chance": return "Critical Chance"
		"boss_dmg": return "Boss Attack"
		"xp_bonus": return "XP Gain"
		_: return key.replace("_", " ").capitalize()

static func display_percent(key: String, value: float) -> int:
	return roundi(absf(value) * 100.0) if key == "damage_taken_mul" else roundi(value * 100.0)
