class_name RingStore

## Persistent ring inventory per account.
## Saved to user://rings_<username>.json
## Rings are dictionaries: { id, name, attr, value, rarity, tier }

# ─── Ring attribute pool ─────────────────────────────────────────────────────
# rarity weights: "common"=60, "rare"=30, "epic"=10
const RING_POOL: Array[Dictionary] = [
	# Common
	{ "attr": "potion_drop_rate",  "name": "Mender's Band",      "rarity": "common", "value_range": [0.04, 0.10],  "desc": "+potion drop chance from bosses" },
	{ "attr": "xp_bonus",         "name": "Scholar's Loop",      "rarity": "common", "value_range": [0.05, 0.05],  "desc": "+5% XP from orbs" },
	{ "attr": "ring_drop_rate",    "name": "Collector's Signet",  "rarity": "common", "value_range": [0.04, 0.08],  "desc": "+ring drop chance from bosses" },
	{ "attr": "move_speed",        "name": "Swift Ring",          "rarity": "common", "value_range": [15.0, 30.0],  "desc": "+move speed" },
	{ "attr": "max_hp",            "name": "Vitality Band",       "rarity": "common", "value_range": [15.0, 30.0],  "desc": "+max HP" },
	# Rare
	{ "attr": "boss_dmg",          "name": "Boss Breaker Band",   "rarity": "rare",   "value_range": [0.05, 0.08],  "desc": "+damage against bosses" },
	{ "attr": "projectile_spd",    "name": "Velocity Loop",       "rarity": "rare",   "value_range": [0.10, 0.20],  "desc": "+projectile speed" },
	# Epic
	{ "attr": "aoe_radius",        "name": "Amplifier Ring",      "rarity": "epic",   "value_range": [0.08, 0.15],  "desc": "+AOE/wave/freeze radius" },
	{ "attr": "crit_chance",       "name": "Fortune's Edge",      "rarity": "epic",   "value_range": [0.05, 0.10],  "desc": "+crit chance (1.8× dmg on crit)" },
	{ "attr": "regen",             "name": "Lifetap Band",        "rarity": "epic",   "value_range": [2.0, 5.0],    "desc": "+HP regen per second" },
]

const RARITY_WEIGHTS: Dictionary = { "common": 60, "rare": 30, "epic": 10 }
const MERGE_VALUE_MULT: float = 1.20
const RARITY_COLORS: Dictionary  = {
	"common": Color(0.80, 0.80, 0.80),
	"rare":   Color(0.30, 0.55, 1.0),
	"epic":   Color(0.75, 0.25, 1.0),
	"legendary": Color(1.0, 0.62, 0.12),
}
const RING_ICON_DIR := "res://assets/rings/"
const RING_ICON_FILES: Dictionary = {
	"Mender's Band": "menders_band.png",
	"Scholar's Loop": "scholars_loop.png",
	"Collector's Signet": "collectors_signet.png",
	"Swift Ring": "swift_ring.png",
	"Vitality Band": "vitality_band.png",
	"Boss Breaker Band": "boss_breaker_band.png",
	"Velocity Loop": "velocity_loop.png",
	"Amplifier Ring": "amplifier_ring.png",
	"Fortune's Edge": "fortunes_edge.png",
	"Lifetap Band": "lifetap_band.png",
	"Warlord's Crest": "warlords_crest.png",
	"Haste Coil": "haste_coil.png",
	"Second Chance Ring": "second_chance_ring.png",
	"Guardian Pulse Ring": "guardian_pulse_ring.png",
}
const RING_ICON_FALLBACK_FILES: Dictionary = {
	"ring_warlords_crest": "warlords_crest.png",
	"ring_haste_coil": "haste_coil.png",
	"ring_second_chance": "second_chance_ring.png",
	"ring_guardian_pulse": "guardian_pulse_ring.png",
	"skill_dmg": "warlords_crest.png",
	"skill_cd": "haste_coil.png",
	"revive_once": "second_chance_ring.png",
	"timed_shield": "guardian_pulse_ring.png",
}

static var _stash_cache: Dictionary = {}  # username -> Array[Dictionary]

static func ring_icon_path(ring: Dictionary) -> String:
	var ring_name: String = ring.get("name", "") as String
	var file_name: String = RING_ICON_FILES.get(ring_name, "") as String
	if file_name == "":
		var ring_id: String = ring.get("id", "") as String
		file_name = RING_ICON_FALLBACK_FILES.get(ring_id, "") as String
	if file_name == "":
		var attr: String = ring.get("attr", "") as String
		file_name = RING_ICON_FALLBACK_FILES.get(attr, "") as String
	if file_name == "":
		return ""
	var path: String = RING_ICON_DIR + file_name
	return path if ResourceLoader.exists(path) else ""

static func ring_icon(ring: Dictionary) -> Texture2D:
	var path: String = ring_icon_path(ring)
	if path == "":
		return null
	return load(path) as Texture2D

# ─── Roll a random ring ───────────────────────────────────────────────────────
static func roll_ring() -> Dictionary:
	var total_w: int = 0
	for entry in RING_POOL:
		total_w += RARITY_WEIGHTS[entry["rarity"] as String] as int
	var roll: int = randi() % total_w
	var cum: int  = 0
	for entry in RING_POOL:
		cum += RARITY_WEIGHTS[entry["rarity"] as String] as int
		if roll < cum:
			var vr: Array = entry["value_range"] as Array
			var val: float = randf_range(float(vr[0]), float(vr[1]))
			return {
				"attr":    entry["attr"],
				"name":    entry["name"],
				"rarity":  entry["rarity"],
				"tier":    1,
				"value":   val,
				"desc":    entry["desc"],
				"id":      "%s_%d" % [entry["attr"], randi()],
			}
	# Fallback
	return roll_ring()

# ─── Stash management ────────────────────────────────────────────────────────
static func _stash_path(username: String) -> String:
	return "user://rings_%s.json" % username.strip_edges().to_lower()

static func load_stash(username: String) -> Array:
	if _stash_cache.has(username):
		return _stash_cache[username] as Array
	var path: String = _stash_path(username)
	if not FileAccess.file_exists(path):
		_stash_cache[username] = []
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data is Array:
		var arr: Array = data as Array
		for i in arr.size():
			arr[i] = normalize_ring(arr[i] as Dictionary)
		_stash_cache[username] = arr
	else:
		_stash_cache[username] = []
	return _stash_cache[username] as Array

static func save_stash(username: String) -> void:
	var path: String = _stash_path(username)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(_stash_cache.get(username, []) as Array))
	f.close()

static func add_ring_to_stash(username: String, ring: Dictionary) -> void:
	load_stash(username)
	(_stash_cache[username] as Array).append(normalize_ring(ring))
	save_stash(username)

static func ensure_ring_in_stash(username: String, ring: Dictionary) -> void:
	if username.strip_edges().is_empty() or ring.is_empty():
		return
	load_stash(username)
	var normalized: Dictionary = normalize_ring(ring)
	var ring_id: String = normalized.get("id", "") as String
	if ring_id.is_empty():
		return
	var stash: Array = _stash_cache[username] as Array
	for item in stash:
		var candidate: Dictionary = item as Dictionary
		if candidate.get("id", "") == ring_id:
			return
	stash.append(normalized)
	save_stash(username)

static func sync_equipped_to_shared_stash(username: String) -> void:
	if username.strip_edges().is_empty():
		return
	var equipped_all: Dictionary = load_equipped(username)
	for char_id in equipped_all.keys():
		var slots: Dictionary = equipped_all[char_id] as Dictionary
		for slot in 2:
			var ring = slots.get("slot_%d" % slot, null)
			if ring != null:
				ensure_ring_in_stash(username, ring as Dictionary)

static func remove_ring_from_stash(username: String, ring_id: String) -> void:
	load_stash(username)
	var arr: Array = _stash_cache[username] as Array
	for i in range(arr.size() - 1, -1, -1):
		if (arr[i] as Dictionary).get("id", "") == ring_id:
			arr.remove_at(i)
			break
	save_stash(username)

static func normalize_ring(ring: Dictionary) -> Dictionary:
	var out: Dictionary = ring.duplicate(true)
	if not out.has("tier"):
		out["tier"] = 1
	return out

static func resolve_equipped_ring(username: String, ring: Dictionary) -> Dictionary:
	var ring_id: String = ring.get("id", "") as String
	if ring_id.is_empty():
		return normalize_ring(ring)
	var stash: Array = load_stash(username)
	for item in stash:
		var candidate: Dictionary = item as Dictionary
		if candidate.get("id", "") == ring_id:
			return normalize_ring(candidate)
	return normalize_ring(ring)

static func ring_merge_key(ring: Dictionary) -> String:
	var normalized: Dictionary = normalize_ring(ring)
	return "%s|%s|%d" % [
		normalized.get("attr", "") as String,
		normalized.get("rarity", "common") as String,
		int(normalized.get("tier", 1)),
	]

static func count_merge_matches(stash: Array, ring: Dictionary) -> int:
	var target_key: String = ring_merge_key(ring)
	var count: int = 0
	for item in stash:
		var candidate: Dictionary = item as Dictionary
		if ring_merge_key(candidate) == target_key:
			count += 1
	return count

static func can_merge_from_stash(stash: Array, ring: Dictionary) -> bool:
	return count_merge_matches(stash, ring) >= 3

static func merge_matching_from_stash(username: String, ring: Dictionary) -> Dictionary:
	load_stash(username)
	var arr: Array = _stash_cache[username] as Array
	var target_key: String = ring_merge_key(ring)
	var matched_indices: Array[int] = []
	var best_value: float = 0.0
	var base_ring: Dictionary = normalize_ring(ring)
	for i in arr.size():
		var candidate: Dictionary = normalize_ring(arr[i] as Dictionary)
		if ring_merge_key(candidate) != target_key:
			continue
		matched_indices.append(i)
		best_value = max(best_value, float(candidate.get("value", 0.0)))
		if matched_indices.size() >= 3:
			break
	if matched_indices.size() < 3:
		return {}
	for i in range(matched_indices.size() - 1, -1, -1):
		arr.remove_at(matched_indices[i])
	var next_tier: int = int(base_ring.get("tier", 1)) + 1
	base_ring["tier"] = next_tier
	base_ring["value"] = best_value * MERGE_VALUE_MULT
	base_ring["id"] = "%s_t%d_%d" % [base_ring.get("attr", "ring") as String, next_tier, randi()]
	arr.append(base_ring)
	_stash_cache[username] = arr
	save_stash(username)
	return base_ring

# ─── Equipped rings per character ────────────────────────────────────────────
static func _equip_path(username: String) -> String:
	return "user://rings_equipped_%s.json" % username.strip_edges().to_lower()

static func load_equipped(username: String) -> Dictionary:
	var path: String = _equip_path(username)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	return data if data is Dictionary else {}

static func save_equipped(username: String, equipped: Dictionary) -> void:
	var path: String = _equip_path(username)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(equipped))
	f.close()

static func restore_from_server(username: String, ring_stash: Array, rings_equipped: Dictionary) -> void:
	if username.strip_edges().is_empty():
		return
	if ring_stash.is_empty() and rings_equipped.is_empty():
		return
	if not ring_stash.is_empty():
		var normalized_stash: Array = []
		for item in ring_stash:
			if typeof(item) == TYPE_DICTIONARY:
				normalized_stash.append(normalize_ring(item as Dictionary))
		_stash_cache[username] = normalized_stash
		save_stash(username)
	if not rings_equipped.is_empty():
		save_equipped(username, rings_equipped)

# Returns dict: { "slot_0": ring_dict_or_null, "slot_1": ring_dict_or_null }
static func get_equipped_rings(username: String, char_id: String) -> Dictionary:
	var all: Dictionary = load_equipped(username)
	var key: String     = char_id
	if all.has(key):
		var equipped: Dictionary = all[key] as Dictionary
		var seen_ids: Dictionary = {}
		var changed: bool = false
		for slot in 2:
			var slot_key: String = "slot_%d" % slot
			var ring = equipped.get(slot_key, null)
			if ring != null:
				var resolved: Dictionary = resolve_equipped_ring(username, ring as Dictionary)
				var ring_id: String = resolved.get("id", "") as String
				if not ring_id.is_empty() and seen_ids.has(ring_id):
					equipped[slot_key] = null
					changed = true
				else:
					equipped[slot_key] = resolved
					if not ring_id.is_empty():
						seen_ids[ring_id] = true
		if changed:
			save_equipped(username, all)
		return equipped
	return {"slot_0": null, "slot_1": null}

static func equip_ring(username: String, char_id: String, slot: int, ring: Dictionary) -> void:
	var all: Dictionary = load_equipped(username)
	if not all.has(char_id):
		all[char_id] = {"slot_0": null, "slot_1": null}
	var slots: Dictionary = all[char_id] as Dictionary
	var ring_id: String = ring.get("id", "") as String
	if not ring_id.is_empty():
		for other_slot in 2:
			if other_slot == slot:
				continue
			var other_key: String = "slot_%d" % other_slot
			var other_ring = slots.get(other_key, null)
			if other_ring != null and (other_ring as Dictionary).get("id", "") == ring_id:
				slots[other_key] = null
	slots["slot_%d" % slot] = ring
	save_equipped(username, all)

static func unequip_ring(username: String, char_id: String, slot: int) -> void:
	var all: Dictionary = load_equipped(username)
	if all.has(char_id):
		(all[char_id] as Dictionary)["slot_%d" % slot] = null
		save_equipped(username, all)

# ─── Stat bonuses from equipped rings ────────────────────────────────────────
# Returns summed bonuses: { attr_name: total_value, ... }
static func get_bonuses(username: String, char_id: String) -> Dictionary:
	var slots: Dictionary = get_equipped_rings(username, char_id)
	var out: Dictionary   = {}
	var seen_ids: Dictionary = {}
	for key in slots:
		var r = slots[key]
		if r == null: continue
		var ring: Dictionary = r as Dictionary
		var ring_id: String = ring.get("id", "") as String
		if not ring_id.is_empty():
			if seen_ids.has(ring_id):
				continue
			seen_ids[ring_id] = true
		var attr: String = ring.get("attr", "") as String
		var val: float   = float(ring.get("value", 0.0))
		if attr.is_empty(): continue
		out[attr] = float(out.get(attr, 0.0)) + val
	return out
