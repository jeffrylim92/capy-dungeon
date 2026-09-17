class_name StoryRunStats
extends RefCounted

var _context: String = "story"
var _damage_by_source: Dictionary = {}
var _total_damage: float = 0.0
var _damage_taken: float = 0.0
var _healing: float = 0.0
var _boss_damage: float = 0.0
var _kills: int = 0
var _revives: int = 0

func reset(context: String = "story") -> void:
	_context = context
	_damage_by_source.clear()
	_total_damage = 0.0
	_damage_taken = 0.0
	_healing = 0.0
	_boss_damage = 0.0
	_kills = 0
	_revives = 0

func record_damage(source_id: String, applied_damage: float, boss_damage: bool = false, combat_eligible: bool = true) -> void:
	if not combat_eligible or applied_damage <= 0.0 or is_nan(applied_damage) or is_inf(applied_damage):
		return
	var normalized := normalize_source_id(source_id)
	_damage_by_source[normalized] = float(_damage_by_source.get(normalized, 0.0)) + applied_damage
	_total_damage += applied_damage
	if boss_damage:
		_boss_damage += applied_damage

static func actual_applied_damage(hp_before: float, hp_after: float, combat_eligible: bool = true) -> float:
	if not combat_eligible or is_nan(hp_before) or is_nan(hp_after) or is_inf(hp_before) or is_inf(hp_after):
		return 0.0
	return maxf(0.0, maxf(hp_before, 0.0) - maxf(hp_after, 0.0))

func record_damage_taken(applied_damage: float) -> void:
	if applied_damage > 0.0 and not is_nan(applied_damage) and not is_inf(applied_damage):
		_damage_taken += applied_damage

func record_healing(applied_healing: float) -> void:
	if applied_healing > 0.0 and not is_nan(applied_healing) and not is_inf(applied_healing):
		_healing += applied_healing

func record_enemy_defeat(countable: bool = true) -> void:
	if countable:
		_kills += 1

func record_revive() -> void:
	_revives += 1

func snapshot() -> Dictionary:
	var attributed_damage := _total_damage - float(_damage_by_source.get("other", 0.0))
	return {
		"context": _context,
		"damage_summary": _sorted_damage_summary(),
		"total_damage": snappedf(_total_damage, 0.01),
		"damage_taken": snappedf(_damage_taken, 0.01),
		"healing": snappedf(_healing, 0.01),
		"boss_damage": snappedf(_boss_damage, 0.01),
		"kills": _kills,
		"revives": _revives,
		"damage_coverage": clampf(attributed_damage / _total_damage, 0.0, 1.0) if _total_damage > 0.0 else 0.0,
	}

func top_damage(limit: int = 3) -> Array[Dictionary]:
	var sorted := _sorted_damage_summary()
	if sorted.size() > maxi(0, limit):
		sorted.resize(maxi(0, limit))
	return sorted

static func normalize_source_id(source_id: String) -> String:
	var source := source_id.strip_edges().to_lower()
	match source:
		"", "unknown": return "other"
		"fire_trail", "fireball": return "fireball"
		"inferno_plasma", "inferno_chain", "inferno_emp", "inferno_thunder": return "inferno_thunder"
		"frozen_lance_shatter": return "frozen_lance"
		"beetle": return "companion_beetle"
		"hawk_feather": return "companion_hawk"
		_: return source

func _sorted_damage_summary() -> Array[Dictionary]:
	var summary: Array[Dictionary] = []
	for source_variant in _damage_by_source:
		var damage := float(_damage_by_source[source_variant])
		if damage > 0.0:
			summary.append({"source_id":str(source_variant), "damage":snappedf(damage, 0.01)})
	summary.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var damage_a := float(a.get("damage", 0.0))
		var damage_b := float(b.get("damage", 0.0))
		return str(a.get("source_id", "")) < str(b.get("source_id", "")) if is_equal_approx(damage_a, damage_b) else damage_a > damage_b
	)
	return summary
