class_name ArtifactStore

## Persistent artifact inventory per account.
## Artifacts are dictionaries with optional `effects` dictionary.

const ARTIFACT_POOL: Array[Dictionary] = [
	{"id": "artifact_infernal_heart", "name": "Infernal Heart", "rarity": "epic", "desc": "Damage +12%\nBurn duration +15%", "image_desc": "A molten red heart floating above cracked lava stone, glowing orange veins, small embers drifting upward.", "effects": {"skill_dmg": 0.12, "burn_duration": 0.15}},
	{"id": "artifact_frozen_crown", "name": "Frozen Crown", "rarity": "rare", "desc": "Freeze duration +15%\nIce damage +8%", "image_desc": "A silver crown encased in ice crystals with snowflakes orbiting around it.", "effects": {"freeze_duration": 0.15, "ice_dmg": 0.08}},
	{"id": "artifact_storm_core", "name": "Storm Core", "rarity": "rare", "desc": "Lightning chain +1\nLightning damage +8%", "image_desc": "A crystal sphere trapping a miniature thunderstorm with blue lightning inside.", "effects": {"lightning_chain": 1.0, "lightning_dmg": 0.08}},
	{"id": "artifact_rangers_quiver", "name": "Ranger's Quiver", "rarity": "common", "desc": "Projectile speed +8%\nProjectile damage +6%", "image_desc": "Leather quiver filled with glowing green arrows.", "effects": {"projectile_spd": 0.08, "projectile_dmg": 0.06}},
	{"id": "artifact_guardian_halo", "name": "Guardian Halo", "rarity": "rare", "desc": "Max HP +8%\nRecover 0.4% HP every 18 sec", "image_desc": "Golden angelic halo with tiny white feathers floating around it.", "effects": {"max_hp_pct": 0.08, "regen_pulse_pct": 0.004, "regen_pulse_interval": 18.0}},
	{"id": "artifact_arcane_prism", "name": "Arcane Prism", "rarity": "epic", "desc": "6% chance to duplicate projectile", "image_desc": "Floating rainbow prism refracting magical light in multiple directions.", "effects": {"proj_dup_chance": 0.06}},
	{"id": "artifact_emerald_clover", "name": "Emerald Clover", "rarity": "common", "desc": "Luck +12%\nRare drop chance +8%", "image_desc": "Four-leaf clover made of glowing emerald crystal.", "effects": {"luck": 0.12, "ring_drop_rate": 0.08}},
	{"id": "artifact_phoenix_feather", "name": "Phoenix Feather", "rarity": "legendary", "desc": "Revive once\nReturn with 25% HP", "image_desc": "A fiery orange feather burning endlessly without being consumed.", "effects": {"revive_once": 1.0, "revive_hp_pct": 0.25}},
	{"id": "artifact_berserker_mask", "name": "Berserker Mask", "rarity": "epic", "desc": "Damage +18%\nMax HP -12%", "image_desc": "Ancient red demon mask with glowing eyes and battle scars.", "effects": {"skill_dmg": 0.18, "max_hp_pct": -0.12}},
	{"id": "artifact_blood_chalice", "name": "Blood Chalice", "rarity": "epic", "desc": "Lifesteal +4%\nHealing effectiveness -10%", "image_desc": "Silver goblet filled with glowing crimson liquid.", "effects": {"lifesteal": 0.04, "healing_efficiency": -0.10}},
	{"id": "artifact_glass_cannon", "name": "Glass Cannon", "rarity": "legendary", "desc": "Damage +24%\nDamage taken +20%", "image_desc": "Crystal cannon covered with cracks and glowing pressure lines.", "effects": {"skill_dmg": 0.24, "damage_taken_mul": 0.20}},
	{"id": "artifact_broken_stopwatch", "name": "Broken Stopwatch", "rarity": "rare", "desc": "Cooldown -12%\nDamage -8%", "image_desc": "Cracked golden stopwatch frozen in time.", "effects": {"skill_cd": 0.12, "skill_dmg": -0.08}},
	{"id": "artifact_dual_potion", "name": "Dual Potion", "rarity": "rare", "desc": "Healing effectiveness +24%\nEnemies gain +12% HP", "image_desc": "Two connected potion bottles with green and red glow, chained together.", "effects": {"healing_efficiency": 0.24, "enemy_hp_mul": 0.12}},
	{"id": "artifact_soul_lantern", "name": "Soul Lantern", "rarity": "rare", "desc": "XP gain +16%\nMovement speed -8%", "image_desc": "Ghostly blue lantern containing floating spirit flames.", "effects": {"xp_bonus": 0.16, "move_speed_mul": -0.08}},
	{"id": "artifact_titan_belt", "name": "Titan Belt", "rarity": "rare", "desc": "Max HP +16%\nMove speed -6%", "image_desc": "Massive stone belt engraved with ancient runes.", "effects": {"max_hp_pct": 0.16, "move_speed_mul": -0.06}},
	{"id": "artifact_assassins_contract", "name": "Assassin's Contract", "rarity": "epic", "desc": "Crit damage +20%\nDefense -12%", "image_desc": "Blood-stained parchment pierced by a black dagger.", "effects": {"crit_dmg": 0.20, "damage_taken_mul": 0.12}},
	{"id": "artifact_gravity_engine", "name": "Gravity Engine", "rarity": "epic", "desc": "XP pickup radius +30%\nProjectile homing +8%", "image_desc": "Mechanical core with rotating rings and teal energy.", "effects": {"pickup_radius": 0.30, "projectile_homing": 0.08}},
	{"id": "artifact_dimensional_compass", "name": "Dimensional Compass", "rarity": "legendary", "desc": "Every 18 sec: Blink short distance + 0.4s invulnerability", "image_desc": "Floating purple compass suspended inside a miniature portal.", "effects": {"blink_interval": 18.0, "blink_dist": 150.0, "blink_iframes": 0.4}},
	{"id": "artifact_capy_mystery_box", "name": "Capy's Mystery Box", "rarity": "legendary", "desc": "Chaos: random stat tradeoff each run", "image_desc": "Golden capybara-shaped treasure chest with question marks around it.", "effects": {"chaos_mystery_box": 1.0}},
	{"id": "artifact_wheel_of_fate", "name": "Wheel of Fate", "rarity": "legendary", "desc": "Every 50 sec random buff/debuff for 12 sec", "image_desc": "Ancient spinning wheel split into gold and dark-purple halves.", "effects": {"chaos_wheel": 1.0, "wheel_interval": 50.0, "wheel_duration": 12.0}},
]

const RARITY_WEIGHTS: Dictionary = {"common": 90, "rare": 60, "epic": 30, "legendary": 10}
const RARITY_COLORS: Dictionary = {
	"common": Color(0.72, 0.72, 0.72),
	"rare": Color(0.30, 0.55, 1.0),
	"epic": Color(0.75, 0.25, 1.0),
	"legendary": Color(1.0, 0.62, 0.12),
}

const ARTIFACT_ICON_DIRS: Array[String] = [
	"res://assets/artifacts/",
	"res://assets/artifatcs/",
]

static var _stash_cache: Dictionary = {}  # username -> Array[Dictionary]
const _SHARED_EQUIPPED_KEY: String = "__shared__"

static func artifact_icon_path(artifact: Dictionary) -> String:
	var explicit_path: String = String(artifact.get("icon", ""))
	if not explicit_path.is_empty() and ResourceLoader.exists(explicit_path):
		return explicit_path

	var raw_id: String = String(artifact.get("id", ""))
	if raw_id.is_empty():
		return ""
	var base_id: String = raw_id
	var last_underscore: int = raw_id.rfind("_")
	if last_underscore > 0:
		var suffix: String = raw_id.substr(last_underscore + 1)
		if suffix.is_valid_int():
			base_id = raw_id.substr(0, last_underscore)

	var candidate_ids: Array[String] = []
	candidate_ids.append(raw_id)
	if base_id != raw_id:
		candidate_ids.append(base_id)
	if last_underscore > 0:
		var trimmed_tail: String = raw_id.substr(0, last_underscore)
		if not trimmed_tail.is_empty() and not candidate_ids.has(trimmed_tail):
			candidate_ids.append(trimmed_tail)

	for dir_path in ARTIFACT_ICON_DIRS:
		for candidate in candidate_ids:
			for ext in ["png", "webp"]:
				var path: String = "%s%s.%s" % [dir_path, candidate, ext]
				if ResourceLoader.exists(path):
					return path
	return ""

static func artifact_icon(artifact: Dictionary) -> Texture2D:
	var path: String = artifact_icon_path(artifact)
	if path.is_empty():
		return null
	return load(path) as Texture2D

static func _stash_path(username: String) -> String:
	return "user://artifacts_%s.json" % username.strip_edges().to_lower()

static func _equip_path(username: String) -> String:
	return "user://artifacts_equipped_%s.json" % username.strip_edges().to_lower()

static func load_stash(username: String) -> Array:
	if _stash_cache.has(username):
		return _stash_cache[username] as Array
	var path: String = _stash_path(username)
	if not FileAccess.file_exists(path):
		var seeded: Array = []
		if _is_devadmin(username):
			seeded = _ensure_devadmin_artifact_stash([])
		_stash_cache[username] = seeded
		if not seeded.is_empty():
			save_stash(username)
		return _stash_cache[username] as Array
	var f := FileAccess.open(path, FileAccess.READ)
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Array:
		var arr: Array = data as Array
		if _is_devadmin(username):
			arr = _ensure_devadmin_artifact_stash(arr)
		_stash_cache[username] = arr
	else:
		var fallback: Array = []
		if _is_devadmin(username):
			fallback = _ensure_devadmin_artifact_stash([])
		_stash_cache[username] = fallback
	if _is_devadmin(username):
		save_stash(username)
	return _stash_cache[username] as Array

static func _is_devadmin(username: String) -> bool:
	return username.strip_edges().to_lower() == "devadmin"

static func _ensure_devadmin_artifact_stash(stash: Array) -> Array:
	var out: Array = []
	var seen_base_ids: Dictionary = {}
	var pool_base_ids: Array[String] = []
	for i in ARTIFACT_POOL.size():
		var pool_item: Dictionary = ARTIFACT_POOL[i] as Dictionary
		pool_base_ids.append(String(pool_item.get("id", "")))
	for item in stash:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var art: Dictionary = (item as Dictionary).duplicate(true)
		out.append(art)
		var aid: String = String(art.get("id", ""))
		if not aid.is_empty():
			var base: String = aid
			for known_base in pool_base_ids:
				if aid == known_base or aid.begins_with("%s_" % known_base):
					base = known_base
					break
			seen_base_ids[base] = true

	for i in ARTIFACT_POOL.size():
		var tpl: Dictionary = (ARTIFACT_POOL[i] as Dictionary).duplicate(true)
		var base_id: String = String(tpl.get("id", "artifact"))
		if seen_base_ids.has(base_id):
			continue
		tpl["id"] = "%s_devadmin" % base_id
		out.append(tpl)
		seen_base_ids[base_id] = true

	return out

static func save_stash(username: String) -> void:
	var path: String = _stash_path(username)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(_stash_cache.get(username, []) as Array))
	f.close()

static func add_artifact_to_stash(username: String, artifact: Dictionary) -> void:
	load_stash(username)
	(_stash_cache[username] as Array).append(artifact.duplicate(true))
	save_stash(username)

static func ensure_artifact_in_stash(username: String, artifact: Dictionary) -> void:
	if username.strip_edges().is_empty() or artifact.is_empty():
		return
	load_stash(username)
	var artifact_id: String = artifact.get("id", "") as String
	if artifact_id.is_empty():
		return
	var stash: Array = _stash_cache[username] as Array
	for item in stash:
		var candidate: Dictionary = item as Dictionary
		if candidate.get("id", "") == artifact_id:
			return
	stash.append(artifact.duplicate(true))
	save_stash(username)

static func remove_artifact_from_stash(username: String, artifact_id: String) -> void:
	if username.strip_edges().is_empty() or artifact_id.is_empty():
		return
	load_stash(username)
	var stash: Array = _stash_cache[username] as Array
	for i in range(stash.size() - 1, -1, -1):
		if (stash[i] as Dictionary).get("id", "") == artifact_id:
			stash.remove_at(i)
			break
	save_stash(username)

static func load_equipped(username: String) -> Dictionary:
	var path: String = _equip_path(username)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (data is Dictionary):
		return {}
	var equipped_data: Dictionary = data as Dictionary
	if equipped_data.has("slot_0") or equipped_data.has("slot_1"):
		# Legacy format: preserve old shared slots under a dedicated key.
		var migrated := {
			_SHARED_EQUIPPED_KEY: {
				"slot_0": equipped_data.get("slot_0", null),
				"slot_1": equipped_data.get("slot_1", null),
			}
		}
		save_equipped(username, migrated)
		_ensure_equipped_artifacts_in_stash(username, migrated)
		return migrated
	_ensure_equipped_artifacts_in_stash(username, equipped_data)
	return equipped_data

static func _ensure_equipped_artifacts_in_stash(username: String, equipped: Dictionary) -> void:
	# Artifacts are account unlocks with independent per-character loadouts.
	# Recover items removed by the previous consumptive equip behavior.
	var stash := load_stash(username)
	var known_ids: Dictionary = {}
	for item in stash:
		if item is Dictionary:
			known_ids[String((item as Dictionary).get("id", ""))] = true
	var changed := false
	for slots_any in equipped.values():
		if not (slots_any is Dictionary):
			continue
		for artifact_any in (slots_any as Dictionary).values():
			if not (artifact_any is Dictionary):
				continue
			var artifact := artifact_any as Dictionary
			var artifact_id := String(artifact.get("id", ""))
			if not artifact_id.is_empty() and not known_ids.has(artifact_id):
				stash.append(artifact.duplicate(true))
				known_ids[artifact_id] = true
				changed = true
	if changed:
		save_stash(username)

static func save_equipped(username: String, equipped: Dictionary) -> void:
	var path: String = _equip_path(username)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(equipped))
	f.close()

static func replace_loadout(username: String, stash: Array, equipped: Dictionary) -> void:
	_stash_cache[username] = stash.duplicate(true)
	save_stash(username)
	save_equipped(username, equipped.duplicate(true))

static func restore_from_server(username: String, artifact_stash: Array, artifact_equipped: Dictionary) -> void:
	if username.strip_edges().is_empty():
		return
	if artifact_stash.is_empty() and artifact_equipped.is_empty():
		return
	if not artifact_stash.is_empty():
		var stash_copy: Array = load_stash(username).duplicate(true)
		var known_ids: Dictionary = {}
		for local_item in stash_copy:
			if typeof(local_item) == TYPE_DICTIONARY:
				known_ids[String((local_item as Dictionary).get("id", ""))] = true
		for item in artifact_stash:
			if typeof(item) == TYPE_DICTIONARY:
				var artifact_id := String((item as Dictionary).get("id", ""))
				if not artifact_id.is_empty() and not known_ids.has(artifact_id):
					stash_copy.append((item as Dictionary).duplicate(true))
					known_ids[artifact_id] = true
		_stash_cache[username] = stash_copy
		save_stash(username)
	if not artifact_equipped.is_empty():
		save_equipped(username, artifact_equipped)
	reconcile_loadout(username)

static func reconcile_loadout(username: String) -> void:
	if username.strip_edges().is_empty():
		return
	_ensure_equipped_artifacts_in_stash(username, load_equipped(username))

static func purge_user(username: String) -> void:
	var key := username.strip_edges().to_lower()
	if key.is_empty():
		return
	_stash_cache.erase(key)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_stash_path(key)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_equip_path(key)))

static func get_equipped_artifacts(username: String, char_id: String) -> Dictionary:
	var all: Dictionary = load_equipped(username)
	if all.has(char_id):
		var slots: Dictionary = all[char_id] as Dictionary
		return {
			"slot_0": slots.get("slot_0", null),
			"slot_1": slots.get("slot_1", null),
		}
	return {"slot_0": null, "slot_1": null}

static func equip_artifact(username: String, char_id: String, slot: int, artifact: Dictionary) -> void:
	var all: Dictionary = load_equipped(username)
	if not all.has(char_id):
		all[char_id] = {"slot_0": null, "slot_1": null}
	var slots: Dictionary = all[char_id] as Dictionary
	slots["slot_%d" % slot] = artifact.duplicate(true)
	save_equipped(username, all)

static func unequip_artifact(username: String, char_id: String, slot: int) -> void:
	var all: Dictionary = load_equipped(username)
	if all.has(char_id):
		(all[char_id] as Dictionary)["slot_%d" % slot] = null
		save_equipped(username, all)

static func get_bonuses(username: String, char_id: String) -> Dictionary:
	var slots: Dictionary = get_equipped_artifacts(username, char_id)
	var out: Dictionary = {}
	for key in slots:
		var a = slots[key]
		if a == null:
			continue
		var ad: Dictionary = a as Dictionary
		if ad.has("effects"):
			var effects: Dictionary = ad.get("effects", {}) as Dictionary
			for ek in effects.keys():
				out[ek] = float(out.get(ek, 0.0)) + float(effects[ek])
			continue
		var eff: String = ad.get("effect_key", "") as String
		var val: float = float(ad.get("value", 0.0))
		if eff == "hybrid_hp_dmg":
			out["max_hp"] = float(out.get("max_hp", 0.0)) + 18.0
			out["skill_dmg"] = float(out.get("skill_dmg", 0.0)) + 0.04
		elif not eff.is_empty():
			out[eff] = float(out.get(eff, 0.0)) + val
	return out

static func roll_artifact() -> Dictionary:
	var total_w: int = 0
	for e in ARTIFACT_POOL:
		total_w += int(RARITY_WEIGHTS.get(e.get("rarity", "rare"), 1))
	var roll: int = randi() % max(total_w, 1)
	var cum: int = 0
	for e in ARTIFACT_POOL:
		cum += int(RARITY_WEIGHTS.get(e.get("rarity", "rare"), 1))
		if roll < cum:
			var out: Dictionary = (e as Dictionary).duplicate(true)
			out["id"] = "%s_%d" % [out.get("id", "artifact"), randi()]
			return out
	var fallback: Dictionary = (ARTIFACT_POOL[0] as Dictionary).duplicate(true)
	fallback["id"] = "%s_%d" % [fallback.get("id", "artifact"), randi()]
	return fallback
