class_name SkillUIPresentation
extends RefCounted

const TAG_LABELS: Dictionary = {
	"fire":"🔥 FIRE",
	"ice":"❄ ICE",
	"lightning":"⚡ SHOCK",
	"poison":"☠ POISON",
	"projectile":"➶ SHOT",
	"aoe":"◎ AOE",
	"mobility":"➤ MOVE",
	"defence":"🛡 GUARD",
	"sustain":"✚ RECOVER",
	"crit":"✦ CRIT",
	"companion":"◆ ALLY",
}

const DETAIL_KEYS: Array[String] = [
	"n", "orbs", "shots", "spawn_n", "chains", "chain", "pierce", "bounces", "max_targets",
	"dmg", "dps", "hps", "cd", "r", "freeze_r", "explode_r", "pulse_r", "rng", "spd",
	"life", "dur", "slow",
]

const COUNT_LABELS: Dictionary = {
	"n":"PROJECTILE", "orbs":"ORB", "shots":"SHOT", "spawn_n":"SUMMON",
	"chains":"CHAIN", "chain":"CHAIN", "pierce":"PIERCE", "bounces":"BOUNCE",
	"max_targets":"TARGET",
}

static func choice_state(choice: Dictionary) -> String:
	if bool(choice.get("is_ulti", false)):
		return "ultimate"
	if not str(choice.get("evolution", "")).is_empty():
		return "evolved"
	if bool(choice.get("is_combo", false)):
		return "combo"
	return "upgrade" if str(choice.get("type", "new")) == "upgrade" else "new"

static func level_text(state: String, new_level: int, is_upgrade: bool = false) -> String:
	if state in ["evolved", "combo"]:
		return "◆ EVOLVED ◆"
	if state == "new" or state == "ultimate" and not is_upgrade:
		return "NEW · Lv.1"
	return "Lv.%d → Lv.%d" % [maxi(1, new_level - 1), maxi(1, new_level)]

static func primary_change(levels: Array, new_level: int, state: String, fallback: String = "") -> String:
	if state in ["evolved", "combo"]:
		return _compact_fallback(fallback, "NEW FORM")
	if levels.is_empty():
		return _compact_fallback(fallback, "NEW POWER")
	var current_index := clampi(new_level - 1, 0, levels.size() - 1)
	var current: Dictionary = levels[current_index] as Dictionary
	if state in ["new", "ultimate"] or current_index == 0:
		for key in ["n", "orbs", "shots", "spawn_n", "chains", "chain", "pierce", "bounces", "max_targets"]:
			if current.has(key) and int(current[key]) > 1:
				return "%d %s%s" % [int(current[key]), str(COUNT_LABELS.get(key, key)).to_upper(), "S" if int(current[key]) != 1 else ""]
		for key in ["dmg", "dps", "hps", "r", "freeze_r", "rng", "cd"]:
			if current.has(key) and _is_number(current[key]):
				return _new_value_text(key, float(current[key]))
		return _compact_fallback(fallback, "NEW POWER")

	var previous: Dictionary = levels[current_index - 1] as Dictionary
	for key in ["n", "orbs", "shots", "spawn_n", "chains", "chain", "pierce", "bounces", "max_targets"]:
		if current.has(key) and previous.has(key):
			var delta := int(current[key]) - int(previous[key])
			if delta > 0:
				return "+%d %s%s" % [delta, str(COUNT_LABELS.get(key, key)).to_upper(), "S" if delta != 1 else ""]
	for key in ["dmg", "dps", "chain_dmg", "explode_dmg", "pulse_dmg", "pool_dps", "poison_dps", "ember_dps", "emp_dmg", "hps"]:
		if current.has(key) and previous.has(key):
			var old_value := float(previous[key])
			var new_value := float(current[key])
			if old_value > 0.0 and new_value > old_value:
				var percent := roundi((new_value / old_value - 1.0) * 100.0)
				return "+%d%% %s" % [percent, "HEAL" if key == "hps" else "DAMAGE"]
	if current.has("cd") and previous.has("cd") and float(current.cd) < float(previous.cd):
		return "-%ss COOLDOWN" % _compact_number(float(previous.cd) - float(current.cd))
	for key in ["r", "freeze_r", "explode_r", "pulse_r", "pool_r", "fog_r", "chain_r", "spread_r", "rng", "len"]:
		if current.has(key) and previous.has(key) and float(current[key]) > float(previous[key]):
			var old_radius := maxf(float(previous[key]), 0.001)
			return "+%d%% AREA" % roundi((float(current[key]) / old_radius - 1.0) * 100.0)
	if current.has("spd") and previous.has("spd") and float(current.spd) > float(previous.spd):
		return "+%d%% SPEED" % roundi((float(current.spd) / maxf(float(previous.spd), 0.001) - 1.0) * 100.0)
	return _compact_fallback(fallback, "POWER UP")

static func detail_lines(levels: Array, new_level: int) -> Array[String]:
	var output: Array[String] = []
	if levels.is_empty():
		return output
	var data: Dictionary = levels[clampi(new_level - 1, 0, levels.size() - 1)] as Dictionary
	for key in DETAIL_KEYS:
		if not data.has(key) or not _is_number(data[key]):
			continue
		var value := float(data[key])
		match key:
			"n", "orbs", "shots", "spawn_n", "chains", "chain", "pierce", "bounces", "max_targets":
				output.append("%s  %d" % [str(COUNT_LABELS.get(key, key)).capitalize(), roundi(value)])
			"dmg": output.append("Damage  %s" % _compact_number(value))
			"dps": output.append("Damage / sec  %s" % _compact_number(value))
			"hps": output.append("Healing / sec  %s" % _compact_number(value))
			"cd": output.append("Cooldown  %ss" % _compact_number(value))
			"r", "freeze_r", "explode_r", "pulse_r", "rng": output.append("Area  %s" % _compact_number(value))
			"spd": output.append("Speed  %s" % _compact_number(value))
			"life", "dur": output.append("Duration  %ss" % _compact_number(value))
			"slow": output.append("Slow  %d%%" % roundi(value * 100.0))
		if output.size() >= 6:
			break
	return output

static func tag_labels(tags: Array, limit: int = 3) -> Array[String]:
	var output: Array[String] = []
	for tag_variant in tags:
		var tag := str(tag_variant)
		if not TAG_LABELS.has(tag):
			continue
		output.append(str(TAG_LABELS[tag]))
		if output.size() >= limit:
			break
	return output

static func _new_value_text(key: String, value: float) -> String:
	match key:
		"dmg": return "%s DAMAGE" % _compact_number(value)
		"dps": return "%s DPS" % _compact_number(value)
		"hps": return "%s HEAL / SEC" % _compact_number(value)
		"r", "freeze_r", "rng": return "%s AREA" % _compact_number(value)
		"cd": return "%ss COOLDOWN" % _compact_number(value)
	return _compact_number(value)

static func _compact_fallback(value: String, default_value: String) -> String:
	var compact := value.strip_edges().replace(" — ", " ").replace("—", " ")
	if compact.is_empty():
		return default_value
	if compact.length() > 30:
		compact = compact.substr(0, 29).strip_edges() + "…"
	return compact.to_upper()

static func _compact_number(value: float) -> String:
	return str(roundi(value)) if is_equal_approx(value, roundf(value)) else String.num(value, 1)

static func _is_number(value: Variant) -> bool:
	return value is int or value is float
