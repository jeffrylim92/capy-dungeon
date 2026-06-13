class_name RingStore

## Persistent ring inventory per account.
## Saved to user://rings_<username>.json
## Rings are dictionaries: { id, name, attr, value, rarity }

# ─── Ring attribute pool ─────────────────────────────────────────────────────
# rarity weights: "common"=60, "rare"=30, "epic"=10
const RING_POOL: Array[Dictionary] = [
	# Common
	{ "attr": "potion_drop_rate",  "name": "Mender's Band",      "rarity": "common", "value_range": [0.04, 0.10],  "desc": "+potion drop chance from mini/normal bosses" },
	{ "attr": "xp_bonus",         "name": "Scholar's Loop",      "rarity": "common", "value_range": [0.05, 0.05],  "desc": "+5% XP from orbs" },
	{ "attr": "ring_drop_rate",    "name": "Collector's Signet",  "rarity": "common", "value_range": [0.04, 0.08],  "desc": "+ring drop chance from normal bosses" },
	{ "attr": "move_speed",        "name": "Swift Ring",          "rarity": "common", "value_range": [15.0, 30.0],  "desc": "+move speed" },
	{ "attr": "max_hp",            "name": "Vitality Band",       "rarity": "common", "value_range": [15.0, 30.0],  "desc": "+max HP" },
	# Rare
	{ "attr": "skill_dmg",         "name": "Warlord's Crest",     "rarity": "rare",   "value_range": [0.08, 0.15],  "desc": "+skill damage (all skills)" },
	{ "attr": "skill_cd",          "name": "Haste Coil",          "rarity": "rare",   "value_range": [0.06, 0.12],  "desc": "-skill cooldown" },
	{ "attr": "aoe_radius",        "name": "Amplifier Ring",      "rarity": "rare",   "value_range": [0.08, 0.15],  "desc": "+AOE/wave radius" },
	{ "attr": "projectile_spd",    "name": "Velocity Loop",       "rarity": "rare",   "value_range": [0.10, 0.20],  "desc": "+projectile speed" },
	# Epic
	{ "attr": "crit_chance",       "name": "Fortune's Edge",      "rarity": "epic",   "value_range": [0.05, 0.10],  "desc": "+crit chance (1.8× dmg on crit)" },
	{ "attr": "regen",             "name": "Lifetap Band",        "rarity": "epic",   "value_range": [2.0, 5.0],    "desc": "+HP regen per second" },
]

const RARITY_WEIGHTS: Dictionary = { "common": 60, "rare": 30, "epic": 10 }
const RARITY_COLORS: Dictionary  = {
	"common": Color(0.80, 0.80, 0.80),
	"rare":   Color(0.30, 0.55, 1.0),
	"epic":   Color(0.75, 0.25, 1.0),
}

static var _stash_cache: Dictionary = {}  # username -> Array[Dictionary]

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
		_stash_cache[username] = data as Array
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
	(_stash_cache[username] as Array).append(ring)
	save_stash(username)

static func remove_ring_from_stash(username: String, ring_id: String) -> void:
	load_stash(username)
	var arr: Array = _stash_cache[username] as Array
	for i in range(arr.size() - 1, -1, -1):
		if (arr[i] as Dictionary).get("id", "") == ring_id:
			arr.remove_at(i)
			break
	save_stash(username)

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

# Returns dict: { "slot_0": ring_dict_or_null, "slot_1": ring_dict_or_null }
static func get_equipped_rings(username: String, char_id: String) -> Dictionary:
	var all: Dictionary = load_equipped(username)
	var key: String     = char_id
	if all.has(key):
		return all[key] as Dictionary
	return {"slot_0": null, "slot_1": null}

static func equip_ring(username: String, char_id: String, slot: int, ring: Dictionary) -> void:
	var all: Dictionary = load_equipped(username)
	if not all.has(char_id):
		all[char_id] = {"slot_0": null, "slot_1": null}
	(all[char_id] as Dictionary)["slot_%d" % slot] = ring
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
	for key in slots:
		var r = slots[key]
		if r == null: continue
		var ring: Dictionary = r as Dictionary
		var attr: String = ring.get("attr", "") as String
		var val: float   = float(ring.get("value", 0.0))
		if attr.is_empty(): continue
		out[attr] = float(out.get(attr, 0.0)) + val
	return out
