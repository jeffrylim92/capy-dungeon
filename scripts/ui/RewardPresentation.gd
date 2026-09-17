class_name RewardPresentation
extends RefCounted

const RARITY_ORDER := {"common": 0, "rare": 1, "epic": 2, "legendary": 3, "milestone": 4}
const RARITY_COLORS := {
	"common": Color(0.72, 0.70, 0.64),
	"rare": Color(0.30, 0.66, 1.0),
	"epic": Color(0.76, 0.43, 1.0),
	"legendary": Color(1.0, 0.68, 0.18),
	"milestone": Color(1.0, 0.84, 0.30),
}
const RARITY_MARKERS := {
	"common": "◇",
	"rare": "◆",
	"epic": "✦",
	"legendary": "✹",
	"milestone": "★",
}

const PERCENT_STATS := [
	"skill_dmg", "projectile_spd", "projectile_dmg", "projectile_damage",
	"max_hp_pct", "xp_bonus", "crit_chance", "crit_dmg", "luck",
	"ring_drop_rate", "potion_drop_rate", "damage_taken_mul", "enemy_hp_mul",
	"move_speed_mul", "healing_efficiency", "freeze_duration", "ice_dmg",
	"lightning_dmg", "burn_duration", "pickup_radius", "projectile_homing",
	"proj_dup_chance", "regen_pulse_pct", "aoe_radius", "boss_dmg",
]
const HARMFUL_WHEN_POSITIVE := ["damage_taken_mul", "enemy_hp_mul"]
const AUXILIARY_EFFECTS := [
	"regen_pulse_interval", "blink_interval", "blink_dist", "blink_iframes",
	"wheel_interval", "wheel_duration",
]

static var _icon_cache: Dictionary = {}

static func normalize_rarity(value: Variant) -> String:
	var rarity := str(value).to_lower().strip_edges()
	return rarity if RARITY_ORDER.has(rarity) else "common"

static func rarity_color(value: Variant) -> Color:
	return RARITY_COLORS[normalize_rarity(value)] as Color

static func rarity_label(value: Variant) -> String:
	var rarity := normalize_rarity(value)
	return "%s  %s" % [str(RARITY_MARKERS[rarity]), rarity.to_upper()]

static func rarity_rank(value: Variant) -> int:
	return int(RARITY_ORDER.get(normalize_rarity(value), 0))

static func frame_border_width(value: Variant) -> int:
	return [2, 3, 4, 5, 4][rarity_rank(value)]

static func frame_corner_radius(value: Variant, item_type: String) -> int:
	var rarity := normalize_rarity(value)
	if item_type == "artifact":
		return {"common": 7, "rare": 5, "epic": 3, "legendary": 1, "milestone": 3}.get(rarity, 7)
	return {"common": 18, "rare": 16, "epic": 13, "legendary": 10, "milestone": 14}.get(rarity, 18)

static func cached_icon(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	if _icon_cache.has(path):
		return _icon_cache[path] as Texture2D
	var texture := ResourceLoader.load(path) as Texture2D
	_icon_cache[path] = texture
	return texture

static func clear_icon_cache() -> void:
	_icon_cache.clear()

static func icon_cache_size() -> int:
	return _icon_cache.size()

static func item_name(data: Dictionary, item_type: String) -> String:
	var fallback := "Unknown %s" % item_type.capitalize()
	return str(data.get("name", fallback)).strip_edges() if not data.is_empty() else fallback

static func stat_name(stat_key: String) -> String:
	match stat_key:
		"skill_dmg": return "Skill Damage"
		"skill_cd": return "Skill Cooldown"
		"crit_chance": return "Critical Chance"
		"crit_dmg": return "Critical Damage"
		"revive_once": return "Revive Once"
		"projectile_spd": return "Projectile Speed"
		"projectile_dmg", "projectile_damage": return "Projectile Damage"
		"xp_bonus": return "Experience Bonus"
		"max_hp", "max_hp_pct": return "Maximum Health"
		"regen": return "Health Regeneration"
		"timed_shield": return "Timed Shield"
		"luck": return "Luck"
		"ring_drop_rate": return "Ring Drop Rate"
		"potion_drop_rate": return "Potion Drop Rate"
		"aoe_radius": return "Area"
		"boss_dmg": return "Boss Damage"
		"freeze_duration": return "Freeze Duration"
		"ice_dmg": return "Ice Damage"
		"lightning_chain": return "Lightning Chain"
		"lightning_dmg": return "Lightning Damage"
		"burn_duration": return "Burn Duration"
		"lifesteal": return "Lifesteal"
		"healing_efficiency": return "Healing Effectiveness"
		"damage_taken_mul": return "Damage Taken"
		"enemy_hp_mul": return "Enemy Health"
		"move_speed", "move_speed_mul": return "Movement Speed"
		"pickup_radius": return "Pickup Radius"
		"projectile_homing": return "Projectile Homing"
		"proj_dup_chance": return "Projectile Duplication"
		"regen_pulse_pct": return "Regeneration Pulse"
		_:
			return stat_key.replace("_", " ").capitalize()

static func is_detrimental(stat_key: String, value: float) -> bool:
	if stat_key in HARMFUL_WHEN_POSITIVE:
		return value > 0.0
	return value < 0.0

static func stat_value_text(stat_key: String, value: float) -> String:
	if stat_key == "skill_cd" and value > 0.0:
		return "-%d%%" % roundi(value * 100.0)
	if stat_key in PERCENT_STATS:
		var percent := value * 100.0
		return "%+.1f%%" % percent if absf(percent) < 1.0 and not is_zero_approx(percent) else "%+d%%" % roundi(percent)
	if stat_key == "regen":
		return "%+.1f HP/s" % value
	if stat_key in ["revive_once", "lightning_chain", "timed_shield"]:
		return "+%d" % roundi(value)
	return "%+.1f" % value if not is_equal_approx(value, roundf(value)) else "%+d" % roundi(value)

static func effect_line(stat_key: String, value: float) -> String:
	var direction := "↓" if is_detrimental(stat_key, value) else "↑"
	return "%s %s %s" % [direction, stat_value_text(stat_key, value), stat_name(stat_key)]

static func item_effect_lines(item_type: String, data: Dictionary, max_lines: int = 2) -> Array[String]:
	var lines: Array[String] = []
	if data.is_empty():
		return ["Effect data unavailable"]
	if item_type == "ring":
		var attr := str(data.get("attr", ""))
		if attr.is_empty():
			return [str(data.get("desc", "Effect data unavailable"))]
		return [effect_line(attr, float(data.get("value", 0.0)))]
	if item_type in ["equipment", "currency", "material"]:
		var primary := str(data.get("primary_effect", data.get("effect", data.get("desc", "")))).strip_edges()
		return [primary] if not primary.is_empty() else ["Equipment reward"]
	var effects: Dictionary = data.get("effects", {}) as Dictionary
	var helpful: Array[String] = []
	var harmful: Array[String] = []
	for key_variant in effects.keys():
		var key := str(key_variant)
		if key in AUXILIARY_EFFECTS:
			continue
		var value := float(effects[key_variant])
		var line := effect_line(key, value)
		if is_detrimental(key, value):
			harmful.append(line)
		else:
			helpful.append(line)
	if not helpful.is_empty() and not harmful.is_empty():
		lines.append(helpful[0])
		lines.append(harmful[0])
	else:
		lines.append_array(helpful)
		lines.append_array(harmful)
	if lines.is_empty():
		var desc := str(data.get("desc", "Effect data unavailable")).strip_edges()
		for raw_line in desc.split("\n", false):
			if not str(raw_line).strip_edges().is_empty():
				lines.append(str(raw_line).strip_edges())
	if max_lines > 0 and lines.size() > max_lines:
		lines.resize(max_lines)
	return lines

static func primary_effect(item_type: String, data: Dictionary) -> String:
	var lines := item_effect_lines(item_type, data, 2)
	return lines[0] if not lines.is_empty() else "Effect data unavailable"

static func merge_progress(count: int, required: int = 3) -> String:
	var safe_required := maxi(required, 1)
	var filled := mini(maxi(count, 0), safe_required)
	return "%s%s  %d / %d" % ["●".repeat(filled), "○".repeat(safe_required - filled), filled, safe_required]

static func state_priority(flags: Dictionary, rarity: String) -> int:
	if bool(flags.get("new", false)):
		return 500 + rarity_rank(rarity)
	if bool(flags.get("merge_ready", false)):
		return 400
	if bool(flags.get("milestone", false)):
		return 300
	return 100 + rarity_rank(rarity)
