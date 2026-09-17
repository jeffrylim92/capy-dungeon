class_name StoryRunPresentation
extends RefCounted

const SOURCE_NAMES := {
	"other":"Other Damage", "poison":"Poison", "orb":"Orbiting Capy", "capy_charge":"Capy Charge",
	"stampede":"Stampede", "meatball_barrage":"Meatball Barrage", "phantom_hunt":"Phantom Hunt",
	"blink_strike":"Blink Strike", "boomerang":"Boomerang", "companion_beetle":"Beetle Companion",
	"companion_hawk":"Hawk Companion", "smoke_bomb":"Smoke Bomb", "crystal_prism":"Crystal Prism",
	"trap_arrow":"Trap Arrow", "master_kitchen":"Master Kitchen", "fireball":"Fireball",
	"inferno_thunder":"Inferno Thunder", "frozen_lance":"Frozen Lance",
}

static func source_name(source_id: String) -> String:
	var normalized := StoryRunStats.normalize_source_id(source_id)
	return str(SOURCE_NAMES.get(normalized, normalized.replace("_", " ").capitalize()))

static func format_duration(seconds: float) -> String:
	var safe_seconds := maxi(0, floori(seconds))
	return "%02d:%02d" % [safe_seconds / 60, safe_seconds % 60]

static func format_time_improvement(seconds: float) -> String:
	return "%.1fs" % seconds if seconds < 10.0 else "%ds" % roundi(seconds)

static func format_number(value: float) -> String:
	var digits := str(maxi(0, roundi(value)))
	var output := ""
	for index in digits.length():
		if index > 0 and (digits.length() - index) % 3 == 0:
			output += ","
		output += digits.substr(index, 1)
	return output

static func record_result_text(evaluation: Dictionary) -> String:
	var changes: Array = evaluation.get("changes", []) as Array
	if changes.is_empty():
		return ""
	var lines: Array[String] = ["FIRST RECORD" if bool(evaluation.get("first_record", false)) else "NEW RECORDS"]
	for change_variant in changes:
		var change: Dictionary = change_variant as Dictionary
		var kind := str(change.get("record", ""))
		var first := bool(change.get("first", false))
		match kind:
			"best_time":
				var line := "Best Time  %s" % format_duration(float(change.get("value", 0.0)))
				if not first: line += "  ↓ %s" % format_time_improvement(float(change.get("delta", 0.0)))
				lines.append(line)
			"lowest_damage":
				var line := "Lowest Damage  %s" % format_number(float(change.get("value", 0.0)))
				if not first: line += "  ↓ %s" % format_number(float(change.get("delta", 0.0)))
				if is_zero_approx(float(change.get("value", 0.0))): line += " · PERFECT CLEAR"
				lines.append(line)
			"highest_challenge":
				lines.append("Challenge Record  +%d%%" % roundi(float(change.get("value", 0.0)) * 100.0))
	return "\n".join(lines)

static func personal_record_comparison(evaluation: Dictionary) -> String:
	var current: Dictionary = evaluation.get("current", {}) as Dictionary
	if current.is_empty():
		return ""
	var lines: Array[String] = []
	var changed: Dictionary = {}
	for change_variant in evaluation.get("changes", []) as Array:
		var change: Dictionary = change_variant as Dictionary
		if not bool(change.get("first", false)):
			changed[str(change.get("record", ""))] = true
	if current.has("best_time"):
		lines.append("Clear Time Best: %s%s" % [format_duration(float((current.best_time as Dictionary).get("value", 0.0))), " · NEW BEST" if changed.has("best_time") else ""])
	if current.has("lowest_damage"):
		lines.append("Damage Taken Best: %s%s" % [format_number(float((current.lowest_damage as Dictionary).get("value", 0.0))), " · NEW BEST" if changed.has("lowest_damage") else ""])
	if current.has("highest_challenge"):
		lines.append("Challenge Best: +%d%%%s" % [roundi(float((current.highest_challenge as Dictionary).get("value", 0.0)) * 100.0), " · NEW BEST" if changed.has("highest_challenge") else ""])
	return "\n".join(lines)

static func format_timestamp(timestamp: int) -> String:
	if timestamp <= 0:
		return "Date unavailable"
	var parts := Time.get_datetime_dict_from_unix_time(timestamp)
	return "%04d-%02d-%02d  %02d:%02d" % [int(parts.get("year", 0)), int(parts.get("month", 0)), int(parts.get("day", 0)), int(parts.get("hour", 0)), int(parts.get("minute", 0))]

static func top_damage_text(record: Dictionary, limit: int = 3) -> String:
	var rows: Array[String] = []
	var summary: Array = record.get("damage_summary", []) as Array
	for index in mini(limit, summary.size()):
		var row: Dictionary = summary[index] as Dictionary
		rows.append("%d. %s  ·  %d" % [index + 1, source_name(str(row.get("source_id", "other"))), roundi(float(row.get("damage", 0.0)))])
	return "No combat damage recorded" if rows.is_empty() else "\n".join(rows)

static func effect_text(effects: Dictionary) -> String:
	var parts: Array[String] = []
	for key_variant in effects:
		var key := str(key_variant)
		var value: Variant = effects[key_variant]
		if value is int or value is float:
			parts.append("%s %s" % [StoryStore.stat_name(key), StoryStore.stat_value_text(key, float(value))])
		elif value is bool or value is String:
			parts.append("%s %s" % [StoryStore.stat_name(key), str(value)])
	return ", ".join(parts)
