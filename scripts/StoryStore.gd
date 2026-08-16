class_name StoryStore
extends RefCounted

const SAVE_PREFIX := "user://capy_story_"
const MAX_GEAR_LEVEL := 10
const REPLAY_REWARD_MULTIPLIER: float = 0.30
const SLOTS := ["weapon", "armor", "pants", "offhand", "headwear", "boots"]

const CHAPTERS := [
	{"name":"THE STOLEN CAMP CREST", "theme":"mushroom woodland", "reward":["twig_blade", "scout_cap"], "stages":["The Broken Trail", "Mushroom Crossing", "Supply Thieves", "The Old Watchpath", "Crestkeeper's Gate"]},
	{"name":"FROSTBOUND HOLLOW", "theme":"frozen hollow", "reward":["moss_vest", "trail_boots"], "stages":["Rekindle the Way", "Frozen Captives", "Runes of Thaw", "The Mimic Treasury", "Frostbound Colossus"]},
	{"name":"BLIGHTROOT MARSH", "theme":"blighted marsh", "reward":["pan_lid", "forager_pants"], "stages":["Cleanse the Mire", "Hunt the Plaguebeast", "Venom Harvest", "The Fragile Cure", "Brew the Grand Antidote"]},
	{"name":"EMBERFORGE RUINS", "theme":"emberforge ruins", "reward":["thorn_spear", "bark_mail"], "stages":["Ore Rush", "Molten Circuit", "Golem Taming", "Forge the Lost Relic", "Stop the Meltdown"]},
	{"name":"ABYSSAL CITADEL", "theme":"abyssal citadel", "reward":["warden_helm", "root_guard"], "stages":["Silent Descent", "Soul Liberation", "Mirror Labyrinth", "Twin Eclipse", "Throne of the Deep"]},
]

const STAGE_OBJECTIVES := [
	[
		{"id":"escort", "desc":"Command the Scout, open the barricade, and secure extraction", "target_seconds":210.0},
		{"id":"defend", "desc":"Gather energy spores and power the Mushroom Shrine", "target_seconds":210.0},
		{"id":"nests", "desc":"Destroy three different Supply Thief Nests", "count":3},
		{"id":"keys", "desc":"Track three key carriers and cross the Watchpath Gate", "count":3},
		{"id":"hazards", "desc":"Master the Crestkeeper barrage and defeat the Crestkeeper", "target_seconds":270.0},
	],
	[
		{"id":"frozen_braziers", "desc":"Carry flame charges and stabilize four connected warmth zones", "count":4},
		{"id":"ice_captives", "desc":"Release, protect and extract five frozen captives", "count":5},
		{"id":"thaw_runes", "desc":"Memorize four runes and finish the sequence under spreading frost", "count":4, "simultaneous_objectives":true},
		{"id":"frost_mimic", "desc":"Investigate clues, identify the real chest and defeat the Frost Mimic", "count":6, "simultaneous_objectives":true},
		{"id":"frost_colossus", "desc":"Expose three integrated armour crystals and defeat the Frostbound Colossus", "count":3, "simultaneous_objectives":true},
	],
	[
		{"id":"cleanse_mire", "desc":"Carry cleansing energy through three different purification mechanics", "count":3, "energy":6, "target_seconds":270.0},
		{"id":"plaguebeast", "desc":"Read tracking clues, prepare traps, and hunt the Plaguebeast", "count":3, "target_seconds":300.0},
		{"id":"venom_harvest", "desc":"Choose three ecosystems and extract guaranteed venom ingredients", "count":3, "target_seconds":270.0},
		{"id":"fragile_cure", "desc":"Choose a route and deliver a fragile antidote vial", "count":3, "target_seconds":300.0},
		{"id":"grand_antidote", "desc":"Manage recipe, heat, purity, and defeat the Blight Vine Tyrant", "count":3, "target_seconds":360.0},
	],
	[
		{"id":"ore_rush", "desc":"Mine, carry and deliver Ember Ore, then escort the loaded mining cart", "count":12, "target_seconds":300.0},
		{"id":"molten_circuit", "desc":"Route lava, traverse the powered circuit and defend its stabilization", "count":3, "target_seconds":300.0, "simultaneous_objectives":true},
		{"id":"golem_taming", "desc":"Learn and complete four different nonlethal rogue golem captures", "count":4, "target_seconds":330.0},
		{"id":"lost_relic", "desc":"Clear three forge chambers, assemble a relic and defeat its guardian", "count":3, "target_seconds":330.0},
		{"id":"meltdown", "desc":"Complete the shutdown sequence while fighting the Thunderforge Behemoth", "count":4, "target_seconds":390.0, "simultaneous_objectives":true, "final_boss":"thunderforge_behemoth"},
	],
	[
		{"id":"silent_descent", "desc":"Cross three stealth safe points and reach the inner citadel without filling the alert meter", "count":3},
		{"id":"soul_liberation", "desc":"Rescue six moving spirits and seal the Abyss Portal", "count":6},
		{"id":"mirror_labyrinth", "desc":"Solve four clue-driven mirror rooms and defeat the Mirror Guardian", "count":4},
		{"id":"twin_eclipse", "desc":"Prepare both obelisks, synchronize them, and defeat the Eclipse Elite", "simultaneous_objectives":true},
		{"id":"abyss_king", "desc":"Interrupt the ritual, break the crown, and defeat the Abyss King", "simultaneous_objectives":true},
	],
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
	var base := {"cleared":[], "claimed":[], "claimed_chapters":[], "owned":[], "equipped":{}, "materials":0, "levels":{}, "results":{}, "highest_unlocked_chapter":1, "highest_unlocked_stage":1, "story_complete":false}
	if username.is_empty() or not FileAccess.file_exists(_path(username)):
		return base
	var file := FileAccess.open(_path(username), FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	if typeof(parsed) == TYPE_DICTIONARY:
		base.merge(parsed as Dictionary, true)
	var highest_cleared := -1
	for stage_id in base.get("cleared", []) as Array:
		highest_cleared = maxi(highest_cleared, stage_index(str(stage_id)))
	var unlocked_index := clampi(highest_cleared + 1, 0, stage_count() - 1)
	var derived_chapter := floori(float(unlocked_index) / 5.0) + 1
	var derived_stage := unlocked_index % 5 + 1
	if derived_chapter > int(base.get("highest_unlocked_chapter", 1)):
		base["highest_unlocked_chapter"] = derived_chapter
		base["highest_unlocked_stage"] = derived_stage
	elif derived_chapter == int(base.get("highest_unlocked_chapter", 1)):
		base["highest_unlocked_stage"] = maxi(int(base.get("highest_unlocked_stage", 1)), derived_stage)
	base["story_complete"] = bool(base.get("story_complete", false)) or "ch5_5" in (base.get("cleared", []) as Array)
	return base

static func _save(username: String, profile: Dictionary) -> void:
	if username.is_empty(): return
	profile["updated_at"] = int(Time.get_unix_time_from_system())
	var file := FileAccess.open(_path(username), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(profile))

static func cloud_snapshot(username: String) -> Dictionary:
	return load_profile(username).duplicate(true)

static func replace_profile(username: String, profile: Dictionary) -> void:
	_save(username, profile.duplicate(true))

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
	var results: Dictionary = local.get("results", {}) as Dictionary
	for stage_id in (server_profile.get("results", {}) as Dictionary):
		var server_result: Dictionary = (server_profile.get("results", {}) as Dictionary).get(stage_id, {}) as Dictionary
		var local_result: Dictionary = results.get(stage_id, {}) as Dictionary
		if local_result.is_empty() or int(server_result.get("updated_at", 0)) > int(local_result.get("updated_at", 0)):
			results[stage_id] = server_result.duplicate(true)
	local["results"] = results
	var local_chapter := int(local.get("highest_unlocked_chapter", 1))
	var server_chapter := int(server_profile.get("highest_unlocked_chapter", 1))
	if server_chapter > local_chapter:
		local["highest_unlocked_chapter"] = server_chapter
		local["highest_unlocked_stage"] = int(server_profile.get("highest_unlocked_stage", 1))
	elif server_chapter == local_chapter:
		local["highest_unlocked_stage"] = maxi(int(local.get("highest_unlocked_stage", 1)), int(server_profile.get("highest_unlocked_stage", 1)))
	local["story_complete"] = bool(local.get("story_complete", false)) or bool(server_profile.get("story_complete", false))
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
	var hp := 1.08 + float(safe) * 0.055 + float(chapter_index) * 0.08
	var damage := 1.0 + float(safe) * 0.04 + float(chapter_index) * 0.05
	var speed := 1.0 + float(safe) * 0.006 + float(chapter_index) * 0.02
	var objective_config: Dictionary = (STAGE_OBJECTIVES[chapter_index][chapter_stage] as Dictionary).duplicate(true)
	var objective := str(objective_config.get("id", "escort"))
	return {"id":"ch%d_%d" % [chapter_index + 1, chapter_stage + 1], "chapter":chapter_index + 1, "chapter_stage":chapter_stage + 1, "name":"%d-%d  %s" % [chapter_index + 1, chapter_stage + 1, str((chapter.stages as Array)[chapter_stage])], "story":"Advance through the %s and uncover the path ahead." % str(chapter.theme), "challenge":"%s\nEnemy health +%d%% · damage +%d%% · speed +%d%%" % [str(objective_config.get("desc", "Complete the objective")), roundi((hp - 1.0) * 100.0), roundi((damage - 1.0) * 100.0), roundi((speed - 1.0) * 100.0)], "objective":objective, "objective_config":objective_config, "enemy_hp":hp, "enemy_damage":damage, "enemy_speed":speed, "boss":"" , "coins":25 + safe * 4, "materials":1 + chapter_index}

static func stage_count() -> int:
	return CHAPTERS.size() * 5

static func chapter(index: int) -> Dictionary:
	return CHAPTERS[clampi(index, 0, CHAPTERS.size() - 1)] as Dictionary

static func unlocked_stage(profile: Dictionary) -> int:
	for chapter_number in range(1, CHAPTERS.size() + 1):
		if is_chapter_complete(profile, chapter_number) and not is_chapter_claimed(profile, chapter_number):
			return chapter_number * 5 - 1
	var highest_cleared := -1
	for stage_id_variant in profile.get("cleared", []) as Array:
		highest_cleared = maxi(highest_cleared, stage_index(String(stage_id_variant)))
	return clampi(highest_cleared + 1, 0, stage_count() - 1)

static func record_clear(username: String, stage_id: String, result: Dictionary = {}) -> Dictionary:
	var profile := load_profile(username)
	var results: Dictionary = profile.get("results", {}) as Dictionary
	var previous: Dictionary = results.get(stage_id, {}) as Dictionary
	var elapsed := float(result.get("elapsed", 0.0))
	results[stage_id] = {"latest_seconds":elapsed, "best_seconds":elapsed if previous.is_empty() or elapsed < float(previous.get("best_seconds", elapsed)) else float(previous.get("best_seconds", elapsed)), "kills":int(result.get("kills", 0)), "level":int(result.get("level", 1)), "updated_at":int(Time.get_unix_time_from_system())}
	profile["results"] = results
	var cleared: Array = profile.get("cleared", []) as Array
	var first_clear := stage_id not in cleared
	if stage_id in cleared:
		var replay_reward: Dictionary = stage_reward(stage_id, true)
		var replay_materials: int = int(replay_reward.get("materials", 0))
		var replay_coins: int = int(replay_reward.get("coins", 0))
		profile["materials"] = int(profile.get("materials", 0)) + replay_materials
		_add_camp_coins(username, replay_coins)
		_save(username, profile)
		return {"first_clear":false, "materials":replay_materials, "coins":replay_coins, "reward_multiplier":REPLAY_REWARD_MULTIPLIER}
	if first_clear:
		cleared.append(stage_id)
		profile["cleared"] = cleared
		var next_index := mini(stage_index(stage_id) + 1, stage_count() - 1)
		profile["highest_unlocked_chapter"] = floori(float(next_index) / 5.0) + 1
		profile["highest_unlocked_stage"] = next_index % 5 + 1
		if stage_id == "ch5_5": profile["story_complete"] = true
	var stage_data := stage(stage_index(stage_id))
	profile["materials"] = int(profile.get("materials", 0)) + int(stage_data.materials)
	_add_camp_coins(username, int(stage_data.coins))
	_save(username, profile)
	return {"first_clear":true, "materials":int(stage_data.materials), "coins":int(stage_data.coins), "reward_multiplier":1.0}

static func stage_reward(stage_id: String, replay: bool = false) -> Dictionary:
	var stage_data: Dictionary = stage(stage_index(stage_id))
	var multiplier: float = REPLAY_REWARD_MULTIPLIER if replay else 1.0
	return {
		"coins": floori(float(stage_data.get("coins", 0)) * multiplier),
		"materials": floori(float(stage_data.get("materials", 0)) * multiplier),
		"multiplier": multiplier,
	}

static func claim_chapter(username: String, chapter_number: int) -> Array[String]:
	var profile := load_profile(username)
	var final_stage_id := "ch%d_5" % chapter_number
	if final_stage_id not in (profile.get("cleared", []) as Array) or is_chapter_claimed(profile, chapter_number):
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

static func is_chapter_claimed(profile: Dictionary, chapter_number: int) -> bool:
	for claimed_variant in profile.get("claimed_chapters", []) as Array:
		if int(claimed_variant) == chapter_number:
			return true
	return false

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

static func add_materials(username: String, amount: int) -> void:
	if amount <= 0: return
	var profile := load_profile(username)
	profile["materials"] = int(profile.get("materials", 0)) + amount
	_save(username, profile)

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
		"skill_dmg": return "Skill Damage"
		"skill_cd": return "Skill Cooldown"
		"max_hp_pct": return "Maximum Health"
		"max_hp": return "Maximum Health"
		"regen": return "Health Regeneration"
		"damage_taken_mul": return "Damage Taken"
		"move_speed_mul": return "Movement Speed"
		"crit_chance": return "Critical Chance"
		"crit_dmg": return "Critical Damage"
		"boss_dmg": return "Boss Damage"
		"xp_bonus": return "Experience Bonus"
		"aoe_radius": return "Area of Effect Radius"
		"projectile_spd": return "Projectile Speed"
		"projectile_dmg", "projectile_damage": return "Projectile Damage"
		"revive_once": return "Revive Once"
		"revive_hp_pct": return "Restore Health"
		"timed_shield": return "Timed Shield"
		"luck": return "Luck"
		"ring_drop_rate": return "Ring Drop Rate"
		"potion_drop_rate": return "Potion Drop Rate"
		"freeze_duration": return "Freeze Duration"
		"ice_dmg": return "Ice Damage"
		"lightning_chain": return "Lightning Chain"
		"lightning_dmg": return "Lightning Damage"
		"burn_duration": return "Burn Duration"
		"lifesteal": return "Lifesteal"
		"healing_efficiency": return "Healing Effectiveness"
		"enemy_hp_mul": return "Enemy Health"
		"pickup_radius": return "Pickup Radius"
		"projectile_homing": return "Projectile Homing"
		"proj_dup_chance": return "Projectile Duplication Chance"
		"regen_pulse_pct": return "Regeneration Pulse"
		"regen_pulse_interval": return "Regeneration Pulse Interval"
		"blink_interval": return "Blink Interval"
		"blink_dist": return "Blink Distance"
		"blink_iframes": return "Invulnerability Frames"
		"chaos_mystery_box": return "Chaos Mystery Effect"
		"chaos_wheel": return "Chaos Wheel Effect"
		"wheel_duration": return "Wheel Duration"
		"wheel_interval": return "Wheel Interval"
		_: return key.replace("_", " ").capitalize()

static func stat_value_text(key: String, value: float) -> String:
	if key in ["skill_dmg", "projectile_spd", "projectile_dmg", "projectile_damage", "max_hp_pct", "xp_bonus", "crit_chance", "crit_dmg", "luck", "ring_drop_rate", "damage_taken_mul", "enemy_hp_mul", "move_speed_mul", "healing_efficiency", "freeze_duration", "ice_dmg", "lightning_dmg", "burn_duration", "pickup_radius", "projectile_homing", "proj_dup_chance", "regen_pulse_pct", "potion_drop_rate", "aoe_radius", "boss_dmg", "skill_cd"]:
		var percentage := value * 100.0
		return "%+.1f%%" % percentage if absf(percentage) < 1.0 and not is_zero_approx(percentage) else "%+d%%" % roundi(percentage)
	if key in ["wheel_duration", "wheel_interval", "blink_interval", "regen_pulse_interval"]:
		return "%s seconds" % String.num(value, 0)
	if key == "blink_dist": return "%s meters" % String.num(value / 37.5, 0)
	if key == "blink_iframes": return "%s seconds" % String.num(value, 1)
	if key == "regen": return "%+.1f health per second" % value
	if key in ["revive_once", "lightning_chain", "chaos_mystery_box", "chaos_wheel"]: return "+%d" % roundi(value)
	return ("+" if value >= 0.0 else "") + String.num(value, 2)

static func display_percent(key: String, value: float) -> int:
	return roundi(absf(value) * 100.0) if key == "damage_taken_mul" else roundi(value * 100.0)
