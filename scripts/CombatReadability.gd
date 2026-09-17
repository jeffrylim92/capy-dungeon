class_name CombatReadability
extends Node2D

## Presentation-only visual hierarchy and logical effect budget. Critical combat
## geometry is redrawn as an emphasis pass above player spectacle; no gameplay
## state is changed here.
const PRIORITY_SURVIVAL: int = 1
const PRIORITY_STORY: int = 2
const PRIORITY_PLAYER: int = 3
const PRIORITY_ENEMY_STATE: int = 4
const PRIORITY_PLAYER_FEEDBACK: int = 5
const PRIORITY_DECORATIVE: int = 6

const LOAD_NORMAL: int = 0
const LOAD_HEAVY: int = 1
const LOAD_EXTREME: int = 2

var _snapshot: Dictionary = {}
var _time: float = 0.0
var _player_pos: Vector2 = Vector2.ZERO
var _world_rect: Rect2 = Rect2()
var _outline_strength: float = 1.0
var _quality_scale: float = 1.0
var _base_effect_scale: float = 1.0
var _player_effect_scale: float = 1.0
var _load_tier: int = LOAD_NORMAL
var _logical_load: int = 0
var _boss_mode: String = ""
var _critical_active: bool = false
var _damage_number_mode: String = "all"
var _high_contrast: bool = false
var _enhanced_patterns: bool = false
var _show_symbols: bool = true

func _ready() -> void:
	z_index = 30
	process_mode = Node.PROCESS_MODE_PAUSABLE

func configure(settings: Dictionary) -> void:
	_base_effect_scale = clampf(float(settings.get("effect_intensity", 1.0)), 0.0, 1.0)
	_outline_strength = clampf(float(settings.get("player_outline", 1.0)), 0.0, 2.0)
	var quality := str(settings.get("player_effects", "high")).to_lower()
	_quality_scale = {"high":1.0, "medium":0.78, "low":0.58}.get(quality, 1.0)
	_damage_number_mode = normalize_damage_number_mode(settings.get("damage_numbers", true))
	_high_contrast = bool(settings.get("high_contrast_telegraphs", false))
	_enhanced_patterns = str(settings.get("hazard_patterns", "standard")) == "enhanced"
	_show_symbols = bool(settings.get("color_independent_indicators", true))
	_recalculate_scale()
	queue_redraw()

func update_motion(player_pos: Vector2, elapsed: float, world_rect: Rect2) -> void:
	_player_pos = player_pos
	_time = elapsed
	_world_rect = world_rect
	queue_redraw()

func update_snapshot(snapshot: Dictionary, logical_load: int, boss_mode: String) -> void:
	_snapshot = snapshot
	_logical_load = maxi(logical_load, 0)
	_load_tier = LOAD_EXTREME if _logical_load >= 150 else (LOAD_HEAVY if _logical_load >= 78 else LOAD_NORMAL)
	_boss_mode = boss_mode
	_critical_active = not _boss_mode.is_empty() \
		or not (_snapshot.get("boss_telegraphs", []) as Array).is_empty() \
		or not (_snapshot.get("boss_projectiles", []) as Array).is_empty() \
		or _has_lethal_role_action(_snapshot.get("enemies", []) as Array)
	_recalculate_scale()

func _recalculate_scale() -> void:
	var load_scale := 1.0
	if _load_tier == LOAD_HEAVY:
		load_scale = 0.76
	elif _load_tier == LOAD_EXTREME:
		load_scale = 0.54
	var boss_scale := 1.0
	if not _boss_mode.is_empty():
		boss_scale = 0.78
	if _boss_mode.contains("lanes") or _boss_mode.contains("crown") or _boss_mode.contains("desperation"):
		boss_scale = 0.62
	_player_effect_scale = clampf(_base_effect_scale * _quality_scale * load_scale * boss_scale, 0.32, 1.0)

func player_effect_scale() -> float:
	return _player_effect_scale

func trail_steps(full_steps: int) -> int:
	if _load_tier == LOAD_EXTREME or _quality_scale < 0.65:
		return mini(full_steps, 2)
	if _load_tier == LOAD_HEAVY or _quality_scale < 0.9:
		return mini(full_steps, 4)
	return full_steps

func decorative_count(full_count: int, minimum: int = 0) -> int:
	return maxi(minimum, int(round(float(full_count) * _player_effect_scale)))

func damage_number_mode() -> String:
	return _damage_number_mode

func damage_popup_cap(base_cap: int) -> int:
	if _load_tier == LOAD_EXTREME:
		return maxi(16, int(round(float(base_cap) * 0.55)))
	if _load_tier == LOAD_HEAVY:
		return maxi(20, int(round(float(base_cap) * 0.78)))
	return base_cap

func critical_visual_active() -> bool:
	return _critical_active

func debug_state() -> Dictionary:
	return {
		"logical_load":_logical_load,
		"load_tier":_load_tier,
		"boss_mode":_boss_mode,
		"critical_active":_critical_active,
		"player_effect_scale":_player_effect_scale,
		"damage_number_mode":_damage_number_mode,
		"high_contrast":_high_contrast,
		"enhanced_patterns":_enhanced_patterns,
		"show_symbols":_show_symbols,
	}

static func normalize_damage_number_mode(value: Variant) -> String:
	if value is bool:
		return "all" if bool(value) else "off"
	var mode := str(value).to_lower().replace(" ", "_")
	return mode if mode in ["all", "critical_only", "off"] else "all"

static func allows_damage_number(mode: String, critical: bool, priority: int, load_tier: int) -> bool:
	if mode == "off":
		return false
	if mode == "critical_only" and not critical and priority < 4:
		return false
	if load_tier >= LOAD_EXTREME and not critical and priority <= 2:
		return false
	if load_tier >= LOAD_HEAVY and not critical and priority <= 1:
		return false
	return true

static func objective_urgency(prop: Dictionary, player_pos: Vector2) -> float:
	if bool(prop.get("completed", false)) or bool(prop.get("disabled", false)) or bool(prop.get("purified", false)):
		return -INF
	var kind := str(prop.get("kind", ""))
	var urgency := 10.0
	if bool(prop.get("refrozen", false)) or bool(prop.get("bound", false)) or bool(prop.get("suppressed", false)) or bool(prop.get("disrupted", false)):
		urgency += 120.0
	var max_hp := float(prop.get("max_hp", 0.0))
	if max_hp > 1.0:
		var hp_ratio := clampf(float(prop.get("hp", max_hp)) / max_hp, 0.0, 1.0)
		if hp_ratio <= 0.5:
			urgency += (1.0 - hp_ratio) * 90.0
	if kind in ["c3_vial", "antidote_vial", "released_soul", "soul_chain", "regulator", "ritual_anchor", "abyss_crown", "crown_seal"]:
		urgency += 34.0
	if bool(prop.get("active", false)) or bool(prop.get("exposed", false)) or bool(prop.get("actionable", false)):
		urgency += 22.0
	urgency -= minf(player_pos.distance_to(prop.get("pos", player_pos) as Vector2) / 180.0, 18.0)
	return urgency

static func select_objective(candidates: Array, player_pos: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -INF
	for value in candidates:
		if not value is Dictionary:
			continue
		var prop := value as Dictionary
		var score := objective_urgency(prop, player_pos)
		if score > best_score:
			best_score = score
			best = prop
	return best

func _has_lethal_role_action(enemies: Array) -> bool:
	for value in enemies:
		if not value is Dictionary:
			continue
		var enemy := value as Dictionary
		var role := str(enemy.get("primary_role", ""))
		var state := str(enemy.get("role_state", "idle"))
		if (role == "sniper" and state == "aiming") or (role == "charger" and state == "windup") or (role == "zoner" and state == "casting"):
			return true
	return false

func _draw() -> void:
	if _snapshot.is_empty():
		return
	_draw_role_actions(_snapshot.get("enemies", []) as Array)
	_draw_player_marker()
	_draw_story_objective_highlights(_snapshot.get("critical_objectives", []) as Array)
	_draw_objective(_snapshot.get("objective", {}) as Dictionary, PRIORITY_STORY)
	_draw_objective(_snapshot.get("threat", {}) as Dictionary, PRIORITY_SURVIVAL)
	_draw_role_hazards(_snapshot.get("role_hazards", []) as Array)
	_draw_boss_hazard_geometry()
	_draw_mutator_boundaries()
	_draw_enemy_projectiles()
	_draw_boss_telegraphs(_snapshot.get("boss_telegraphs", []) as Array)

func _draw_player_marker() -> void:
	if _outline_strength <= 0.01:
		return
	var radius := 48.0
	var pulse := 0.88 + sin(_time * 4.0) * 0.08
	var dark_alpha := 0.44 * minf(_outline_strength, 1.0)
	draw_arc(_player_pos, radius, 0.0, TAU, 36, Color(0.02, 0.025, 0.03, dark_alpha), 6.0 * _outline_strength)
	for quadrant in 4:
		var start := float(quadrant) * PI * 0.5 + 0.18
		draw_arc(_player_pos, radius * pulse, start, start + 0.62, 9, Color(1.0, 0.94, 0.68, 0.72 * minf(_outline_strength, 1.25)), 2.4 * _outline_strength)

func _draw_objective(item: Dictionary, priority: int) -> void:
	if item.is_empty():
		return
	var target := item.get("pos", Vector2.INF) as Vector2
	if target == Vector2.INF:
		return
	var color := item.get("color", Color(1.0, 0.82, 0.22)) as Color
	var urgent := bool(item.get("urgent", false))
	if _world_rect.grow(-36.0).has_point(target):
		var radius := float(item.get("radius", 58.0)) + sin(_time * (7.0 if urgent else 3.5)) * (5.0 if urgent else 2.5)
		var width := 5.0 if urgent else 3.0
		for segment in 4:
			var start := float(segment) * PI * 0.5 + _time * (0.7 if urgent else 0.25)
			draw_arc(target, radius, start, start + 0.82, 10, Color(color.r, color.g, color.b, 0.94), width)
		if _show_symbols:
			var symbol := "!" if urgent or priority == PRIORITY_SURVIVAL else "◆"
			draw_string(ThemeDB.fallback_font, target + Vector2(-28.0, 9.0), symbol, HORIZONTAL_ALIGNMENT_CENTER, 56.0, 28, Color.WHITE)
		return
	var direction := _player_pos.direction_to(target)
	if direction.is_zero_approx():
		return
	var arrow_pos := _player_pos + direction * 132.0
	var side := Vector2(-direction.y, direction.x)
	var size := 24.0 * (1.0 + sin(_time * (8.0 if urgent else 4.0)) * 0.08)
	draw_colored_polygon(PackedVector2Array([
		arrow_pos + direction * size,
		arrow_pos - direction * size * 0.72 + side * size * 0.58,
		arrow_pos - direction * size * 0.72 - side * size * 0.58,
	]), Color(0.02, 0.02, 0.025, 0.88))
	draw_colored_polygon(PackedVector2Array([
		arrow_pos + direction * size * 0.78,
		arrow_pos - direction * size * 0.48 + side * size * 0.36,
		arrow_pos - direction * size * 0.48 - side * size * 0.36,
	]), color)
	var label := str(item.get("label", "DANGER" if priority == PRIORITY_SURVIVAL else "OBJECTIVE"))
	draw_string(ThemeDB.fallback_font, arrow_pos + Vector2(-115.0, 54.0), label, HORIZONTAL_ALIGNMENT_CENTER, 230.0, 23, Color.WHITE)

func _draw_story_objective_highlights(items: Array) -> void:
	for value in items:
		if not value is Dictionary:
			continue
		var item := value as Dictionary
		var pos := item.get("pos", Vector2.INF) as Vector2
		if pos == Vector2.INF or not _world_rect.grow(-24.0).has_point(pos):
			continue
		var color := item.get("color", Color(1.0, 0.82, 0.22)) as Color
		var radius := float(item.get("radius", 58.0))
		var urgent := bool(item.get("urgent", false))
		var alpha := 0.90 if urgent else 0.58
		for segment in 4:
			var start := float(segment) * PI * 0.5 + 0.12
			draw_arc(pos, radius, start, start + 0.66, 8, Color(color.r, color.g, color.b, alpha), 4.0 if urgent else 2.0)
		if _show_symbols:
			draw_string(ThemeDB.fallback_font, pos + Vector2(-24.0, -radius - 8.0), "!" if urgent else "◆", HORIZONTAL_ALIGNMENT_CENTER, 48.0, 21, Color.WHITE)

func _draw_role_actions(enemies: Array) -> void:
	for value in enemies:
		if not value is Dictionary:
			continue
		var enemy := value as Dictionary
		if not bool(enemy.get("role_enabled", false)):
			continue
		var pos := enemy.get("pos", Vector2.ZERO) as Vector2
		var role := str(enemy.get("primary_role", ""))
		var state := str(enemy.get("role_state", "idle"))
		var radius := float(enemy.get("r", 24.0)) * 1.6
		if role == "sniper" and state == "aiming":
			var target := enemy.get("role_target", _player_pos) as Vector2
			draw_line(pos, target, Color(0.03, 0.01, 0.01, 0.94), 10.0)
			draw_line(pos, target, Color(1.0, 0.28, 0.12, 0.96), 3.0)
			draw_arc(target, 20.0, 0.0, TAU, 24, Color(1.0, 0.86, 0.62, 0.96), 3.0)
		elif role == "charger" and state == "windup":
			var direction := enemy.get("role_charge_dir", Vector2.RIGHT) as Vector2
			var side := Vector2(-direction.y, direction.x)
			var end := pos + direction * 330.0
			draw_line(pos + side * 16.0, end + side * 16.0, Color(0.05, 0.03, 0.01, 0.92), 7.0)
			draw_line(pos - side * 16.0, end - side * 16.0, Color(1.0, 0.70, 0.12, 0.94), 4.0)
		elif role == "zoner" and state == "casting":
			var target := enemy.get("role_target", _player_pos) as Vector2
			_draw_segmented_circle(target, 108.0, Color(0.72, 1.0, 0.38, 0.98), 4.0)
		elif role == "support" and state == "casting" and enemy.has("role_target"):
			var target := enemy.get("role_target", pos) as Vector2
			draw_line(pos, target, Color(0.38, 1.0, 0.58, 0.82), 3.0)
			draw_circle(target, 7.0, Color(0.82, 1.0, 0.86, 0.94))
		elif role == "controller" and state == "casting":
			var target := enemy.get("role_target", _player_pos) as Vector2
			draw_dashed_line(pos, target, Color(0.48, 0.78, 1.0, 0.94), 7.0, 12.0)
			draw_arc(target, 34.0, 0.0, TAU, 22, Color(0.72, 0.90, 1.0, 0.96), 3.0)
		elif role == "summoner" and state == "casting":
			var cast_radius := radius + 28.0 + sin(_time * 12.0) * 6.0
			_draw_segmented_circle(pos, cast_radius, Color(0.84, 0.48, 1.0, 0.96), 4.0)
			for spoke in 6:
				var direction := Vector2.from_angle(float(spoke) * TAU / 6.0 + _time)
				draw_line(pos + direction * 10.0, pos + direction * (cast_radius - 6.0), Color(0.78, 0.42, 1.0, 0.48), 2.0)
		elif role == "disruptor" and enemy.has("role_target"):
			var target := enemy.get("role_target", pos) as Vector2
			draw_dashed_line(pos, target, Color(1.0, 0.40, 0.76, 0.96), 6.0, 11.0)
			draw_arc(target, 42.0, 0.0, TAU, 24, Color(1.0, 0.70, 0.88, 0.94), 3.0)
		elif role == "thief":
			var resource := _thief_resource(enemy)
			if not resource.is_empty():
				var icon_pos := pos + Vector2(0.0, -radius - 24.0)
				draw_circle(icon_pos, 20.0, Color(0.04, 0.03, 0.01, 0.90))
				draw_string(ThemeDB.fallback_font, icon_pos + Vector2(-34.0, 7.0), resource, HORIZONTAL_ALIGNMENT_CENTER, 68.0, 18, Color(1.0, 0.88, 0.24))

func _thief_resource(enemy: Dictionary) -> String:
	var tag := str(enemy.get("story_tag", ""))
	if int(enemy.get("stolen_ore", 0)) > 0:
		return "ORE"
	if int(enemy.get("stolen_keys", enemy.get("stolen_key", 0))) > 0:
		return "KEY"
	if int(enemy.get("stolen_supply", enemy.get("stolen_supplies", 0))) > 0:
		return "SUP"
	if tag in ["fleeing_key_carrier", "protected_key_carrier", "watchpath_captain"]:
		return "KEY"
	if tag == "supply_thief":
		return "SUP"
	return ""

func _draw_role_hazards(hazards: Array) -> void:
	for value in hazards:
		if not value is Dictionary:
			continue
		var hazard := value as Dictionary
		var pos := hazard.get("pos", Vector2.ZERO) as Vector2
		var radius := float(hazard.get("r", 100.0))
		var ratio := clampf(float(hazard.get("life", 0.0)) / maxf(float(hazard.get("max_life", 1.0)), 0.01), 0.0, 1.0)
		_draw_segmented_circle(pos, radius, Color(0.70, 1.0, 0.42, 0.92 * ratio), 4.0)
		if _enhanced_patterns:
			_draw_hazard_pattern(pos, radius, Color(0.88, 1.0, 0.72, 0.52 * ratio))

func _draw_boss_hazard_geometry() -> void:
	for key in ["mortar_strikes", "lava_pools", "thorn_patches", "lightning_markers", "venom_pods"]:
		for value in _snapshot.get(key, []) as Array:
			if not value is Dictionary:
				continue
			var hazard := value as Dictionary
			var pos := hazard.get("pos", hazard.get("target", Vector2.INF)) as Vector2
			if pos == Vector2.INF:
				continue
			var radius := float(hazard.get("r", hazard.get("radius", 58.0)))
			var preview: bool = float(hazard.get("arming", 0.0)) > 0.0 or key in ["mortar_strikes", "lightning_markers"]
			var danger_color := Color(1.0, 0.78, 0.22, 0.96) if preview else Color(1.0, 0.24, 0.10, 0.98)
			draw_arc(pos, radius, 0.0, TAU, 36, Color(0.025, 0.01, 0.01, 0.96 if _high_contrast else 0.88), 11.0 if _high_contrast else 8.0)
			if preview:
				_draw_segmented_circle(pos, radius, danger_color, 4.0)
			else:
				draw_arc(pos, radius, 0.0, TAU, 36, danger_color, 4.0)
			if _enhanced_patterns:
				_draw_hazard_pattern(pos, radius, Color(danger_color.r, danger_color.g, danger_color.b, 0.56))
			if _show_symbols:
				draw_string(ThemeDB.fallback_font, pos + Vector2(-30.0, 10.0), "!", HORIZONTAL_ALIGNMENT_CENTER, 60.0, 30, Color.WHITE)
	for value in _snapshot.get("lava_lines", []) as Array:
		if not value is Dictionary:
			continue
		var line := value as Dictionary
		var start := line.get("start", line.get("pos", Vector2.ZERO)) as Vector2
		var direction := line.get("dir", Vector2.RIGHT) as Vector2
		var length := float(line.get("len", line.get("length", 760.0)))
		var width := float(line.get("width", 42.0))
		var side := Vector2(-direction.y, direction.x) * width * 0.5
		draw_line(start + side, start + direction * length + side, Color(0.02, 0.01, 0.01, 0.90), 8.0)
		draw_line(start - side, start + direction * length - side, Color(0.02, 0.01, 0.01, 0.90), 8.0)
		draw_dashed_line(start + side, start + direction * length + side, Color(1.0, 0.36, 0.10, 0.96), 4.0, 18.0)
		draw_dashed_line(start - side, start + direction * length - side, Color(1.0, 0.36, 0.10, 0.96), 4.0, 18.0)
	for value in _snapshot.get("boss_chains", []) as Array:
		if not value is Dictionary:
			continue
		var chain := value as Dictionary
		var start := chain.get("boss_pos", Vector2.ZERO) as Vector2
		var direction := chain.get("direction", Vector2.RIGHT) as Vector2
		var length := float(chain.get("length", 120.0))
		draw_dashed_line(start, start + direction * length, Color(0.68, 0.92, 1.0, 0.94), 4.0, 12.0)
	for value in _snapshot.get("prism_zones", []) as Array:
		if not value is Dictionary:
			continue
		var zone := value as Dictionary
		var nodes := zone.get("nodes", []) as Array
		if nodes.size() < 3:
			continue
		var polygon := PackedVector2Array()
		for node in nodes:
			polygon.append(node as Vector2)
		polygon.append(nodes[0] as Vector2)
		draw_polyline(polygon, Color(0.94, 0.68, 1.0, 0.96), 4.0)

func _draw_mutator_boundaries() -> void:
	var ground_zones := _snapshot.get("ground_zones", []) as Array
	for value in ground_zones:
		if not value is Dictionary:
			continue
		var zone := value as Dictionary
		var pos := zone.get("pos", Vector2.ZERO) as Vector2
		var radius := float(zone.get("r", 82.0))
		var ratio := clampf(float(zone.get("life", 0.0)) / maxf(float(zone.get("max_life", 1.0)), 0.01), 0.0, 1.0)
		_draw_segmented_circle(pos, radius, Color(0.94, 0.50, 1.0, 0.86 * ratio), 3.0)
	var volatile_bursts := _snapshot.get("volatile_bursts", []) as Array
	for value in volatile_bursts:
		if not value is Dictionary:
			continue
		var burst := value as Dictionary
		var pos := burst.get("pos", Vector2.ZERO) as Vector2
		var radius := float(burst.get("r", 112.0))
		var progress := 1.0 - clampf(float(burst.get("life", 0.0)) / maxf(float(burst.get("max_life", 1.0)), 0.01), 0.0, 1.0)
		draw_arc(pos, radius, 0.0, TAU, 32, Color(0.10, 0.02, 0.01, 0.90), 8.0)
		draw_arc(pos, radius, 0.0, TAU, 32, Color(1.0, 0.64, 0.18, 0.96), 4.0)
		draw_arc(pos, radius * progress, 0.0, TAU, 28, Color(1.0, 0.92, 0.62, 0.92), 2.0)
	var pressure := _snapshot.get("pressure_wave", {}) as Dictionary
	if not pressure.is_empty():
		var center := pressure.get("center", Vector2.ZERO) as Vector2
		var direction := pressure.get("direction", Vector2.RIGHT) as Vector2
		var perpendicular := Vector2(-direction.y, direction.x)
		var preview := float(pressure.get("telegraph", 0.0)) > 0.0
		var color := Color(1.0, 0.88, 0.42, 0.74 if preview else 0.96)
		draw_line(center - perpendicular * 1200.0, center + perpendicular * 1200.0, Color(0.05, 0.03, 0.01, 0.88), 12.0 if preview else 22.0)
		draw_dashed_line(center - perpendicular * 1200.0, center + perpendicular * 1200.0, color, 5.0 if preview else 9.0, 24.0)

func _draw_enemy_projectiles() -> void:
	for value in _snapshot.get("role_projectiles", []) as Array:
		if not value is Dictionary:
			continue
		var projectile := value as Dictionary
		_draw_warning_projectile(projectile.get("pos", Vector2.ZERO) as Vector2, 11.0, str(projectile.get("kind", "role")))
	for value in _snapshot.get("boss_projectiles", []) as Array:
		if not value is Dictionary:
			continue
		var projectile := value as Dictionary
		if float(projectile.get("delay", 0.0)) > 0.0:
			continue
		_draw_warning_projectile(projectile.get("pos", Vector2.ZERO) as Vector2, 15.0, str(projectile.get("kind", "boss")))

func _draw_warning_projectile(pos: Vector2, radius: float, kind: String) -> void:
	if not _world_rect.grow(60.0).has_point(pos):
		return
	var spin := _time * (4.0 if kind.contains("boss") else 6.0)
	var points := PackedVector2Array()
	for corner in 4:
		points.append(pos + Vector2.from_angle(spin + PI * 0.25 + float(corner) * PI * 0.5) * radius)
	points.append(points[0])
	draw_polyline(points, Color(0.015, 0.01, 0.02, 0.96), 7.0)
	draw_polyline(points, Color(1.0, 0.96, 0.76, 0.98), 2.6)
	draw_circle(pos, radius * 0.28, Color(1.0, 0.36, 0.16, 0.98))

func _draw_boss_telegraphs(telegraphs: Array) -> void:
	for value in telegraphs:
		if not value is Dictionary:
			continue
		var telegraph := value as Dictionary
		var pos := telegraph.get("pos", Vector2.ZERO) as Vector2
		var ratio := clampf(float(telegraph.get("life", 0.0)) / maxf(float(telegraph.get("max_life", 1.0)), 0.01), 0.0, 1.0)
		var color := telegraph.get("color", Color(1.0, 0.22, 0.12)) as Color
		var safe := color.g > color.r * 1.35 and color.b > color.r
		if str(telegraph.get("kind", "circle")) == "line":
			var direction := telegraph.get("dir", Vector2.RIGHT) as Vector2
			var length := float(telegraph.get("length", 600.0))
			var side := Vector2(-direction.y, direction.x)
			var half_width := float(telegraph.get("width", 32.0)) * 0.5
			var end := pos + direction * length
			var edge := Color(0.68, 1.0, 0.94, 0.96 * ratio) if safe else Color(1.0, 0.34, 0.16, 0.98 * ratio)
			draw_line(pos + side * half_width, end + side * half_width, Color(0.02, 0.02, 0.02, 0.88 * ratio), 8.0)
			draw_line(pos - side * half_width, end - side * half_width, Color(0.02, 0.02, 0.02, 0.88 * ratio), 8.0)
			if safe:
				draw_dashed_line(pos + side * half_width, end + side * half_width, edge, 3.5, 20.0)
				draw_dashed_line(pos - side * half_width, end - side * half_width, edge, 3.5, 20.0)
			else:
				draw_line(pos + side * half_width, end + side * half_width, edge, 4.0)
				draw_line(pos - side * half_width, end - side * half_width, edge, 4.0)
			if _enhanced_patterns:
				var marker_step := 54.0
				var marker_count := maxi(1, int(length / marker_step))
				for marker_index in marker_count:
					var marker_pos := pos + direction * minf(length, (float(marker_index) + 0.5) * marker_step)
					draw_line(marker_pos - side * half_width, marker_pos + side * half_width, Color(edge.r, edge.g, edge.b, 0.52 * ratio), 2.0)
			if _show_symbols:
				draw_string(ThemeDB.fallback_font, pos + direction * minf(length * 0.5, 180.0) + Vector2(-45.0, 8.0), "SAFE" if safe else "!", HORIZONTAL_ALIGNMENT_CENTER, 90.0, 22, Color.WHITE)
		else:
			var radius := float(telegraph.get("radius", 80.0))
			draw_arc(pos, radius, 0.0, TAU, 40, Color(0.02, 0.01, 0.01, (0.98 if _high_contrast else 0.90) * ratio), 12.0 if _high_contrast else 9.0)
			_draw_segmented_circle(pos, radius, Color(color.r, color.g, color.b, 0.98 * ratio), 4.0)
			if _enhanced_patterns:
				_draw_hazard_pattern(pos, radius, Color(color.r, color.g, color.b, 0.52 * ratio))
			if _show_symbols:
				draw_string(ThemeDB.fallback_font, pos + Vector2(-32.0, 10.0), "SAFE" if safe else "!", HORIZONTAL_ALIGNMENT_CENTER, 64.0, 26, Color.WHITE)

func _draw_segmented_circle(pos: Vector2, radius: float, color: Color, width: float) -> void:
	for segment in 8:
		var start := float(segment) * TAU / 8.0 + 0.06
		draw_arc(pos, radius, start, start + TAU / 11.0, 8, color, width)

func _draw_hazard_pattern(pos: Vector2, radius: float, color: Color) -> void:
	# Sparse clipped stripes remain cheap on mobile and distinguish danger areas
	# without relying on red/green perception.
	var spacing := maxf(18.0, radius * 0.28)
	var offset := -radius + spacing
	while offset < radius:
		var half_chord := sqrt(maxf(radius * radius - offset * offset, 0.0))
		var left := Vector2(-half_chord, offset).rotated(PI * 0.25)
		var right := Vector2(half_chord, offset).rotated(PI * 0.25)
		draw_line(pos + left, pos + right, color, 2.0)
		offset += spacing
