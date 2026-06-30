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

	for dir_path in ARTIFACT_ICON_DIRS:
		for ext in ["png", "webp"]:
			var path: String = "%s%s.%s" % [dir_path, base_id, ext]
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
		_stash_cache[username] = []
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Array:
		_stash_cache[username] = (data as Array)
	else:
		_stash_cache[username] = []
	return _stash_cache[username] as Array

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
		return {"slot_0": null, "slot_1": null}
	var f := FileAccess.open(path, FileAccess.READ)
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (data is Dictionary):
		return {"slot_0": null, "slot_1": null}
	var equipped_data: Dictionary = data as Dictionary
	if equipped_data.has("slot_0") or equipped_data.has("slot_1"):
		return {
			"slot_0": equipped_data.get("slot_0", null),
			"slot_1": equipped_data.get("slot_1", null),
		}
	var shared: Dictionary = {"slot_0": null, "slot_1": null}
	for char_id in equipped_data.keys():
		var slots: Dictionary = equipped_data.get(char_id, {}) as Dictionary
		if slots.is_empty():
			continue
		for slot in 2:
			var slot_key: String = "slot_%d" % slot
			if shared.get(slot_key, null) == null and slots.get(slot_key, null) != null:
				shared[slot_key] = (slots.get(slot_key, null) as Dictionary).duplicate(true)
	save_equipped(username, shared)
	return shared

static func save_equipped(username: String, equipped: Dictionary) -> void:
	var path: String = _equip_path(username)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"slot_0": equipped.get("slot_0", null),
		"slot_1": equipped.get("slot_1", null),
	}))
	f.close()

static func get_equipped_artifacts(username: String, char_id: String) -> Dictionary:
	return load_equipped(username)

static func equip_artifact(username: String, char_id: String, slot: int, artifact: Dictionary) -> void:
	var all: Dictionary = load_equipped(username)
	all["slot_%d" % slot] = artifact.duplicate(true)
	save_equipped(username, all)

static func unequip_artifact(username: String, char_id: String, slot: int) -> void:
	var all: Dictionary = load_equipped(username)
	all["slot_%d" % slot] = null
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
