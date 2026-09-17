class_name CombatVFX
extends Node2D

## Shared procedural polish for every skill family. This sits above Match's bespoke
## effects and supplies consistent cast anticipation, sparks, trails and impacts.
const MAX_PARTICLES := 260
const MAX_PULSES := 48
const IOS_MAX_PARTICLES := 140
const IOS_MAX_PULSES := 28
const MAX_HIT_EMISSIONS_PER_FRAME := 12
const IOS_MAX_HIT_EMISSIONS_PER_FRAME := 8
const MAX_STREAKS := 40
const MEDIUM_PARTICLES := 190
const MEDIUM_PULSES := 36
const MEDIUM_STREAKS := 30
const MEDIUM_HIT_EMISSIONS_PER_FRAME := 10
const LOW_PARTICLES := 120
const LOW_PULSES := 24
const LOW_STREAKS := 20
const LOW_HIT_EMISSIONS_PER_FRAME := 8

var _particles: Array[Dictionary] = []
var _pulses: Array[Dictionary] = []
var _streaks: Array[Dictionary] = []
var _time: float = 0.0
var _particle_limit: int = MAX_PARTICLES
var _pulse_limit: int = MAX_PULSES
var _streak_limit: int = MAX_STREAKS
var _hit_emission_limit: int = MAX_HIT_EMISSIONS_PER_FRAME
var _hit_emissions_this_frame: int = 0
var _effect_intensity: float = 1.0

func _ready() -> void:
	z_index = 24
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if OS.get_name() == "iOS":
		_particle_limit = IOS_MAX_PARTICLES
		_pulse_limit = IOS_MAX_PULSES
		_hit_emission_limit = IOS_MAX_HIT_EMISSIONS_PER_FRAME
	set_process(false)

func configure_quality(settings: Dictionary) -> void:
	var quality := str(settings.get("player_effects", "high")).to_lower()
	match quality:
		"low":
			_particle_limit = LOW_PARTICLES
			_pulse_limit = LOW_PULSES
			_streak_limit = LOW_STREAKS
			_hit_emission_limit = LOW_HIT_EMISSIONS_PER_FRAME
		"medium":
			_particle_limit = MEDIUM_PARTICLES
			_pulse_limit = MEDIUM_PULSES
			_streak_limit = MEDIUM_STREAKS
			_hit_emission_limit = MEDIUM_HIT_EMISSIONS_PER_FRAME
		_:
			_particle_limit = MAX_PARTICLES
			_pulse_limit = MAX_PULSES
			_streak_limit = MAX_STREAKS
			_hit_emission_limit = MAX_HIT_EMISSIONS_PER_FRAME
	if OS.get_name() == "iOS":
		_particle_limit = mini(_particle_limit, IOS_MAX_PARTICLES)
		_pulse_limit = mini(_pulse_limit, IOS_MAX_PULSES)
		_hit_emission_limit = mini(_hit_emission_limit, IOS_MAX_HIT_EMISSIONS_PER_FRAME)
	_trim()

func debug_budget() -> Dictionary:
	return {
		"particles":_particle_limit,
		"pulses":_pulse_limit,
		"streaks":_streak_limit,
		"hit_emissions":_hit_emission_limit,
		"active":active_effect_count(),
		"processing":is_processing(),
	}

func set_effect_intensity(value: float) -> void:
	_effect_intensity = clampf(value, 0.0, 1.0)
	if active_effect_count() > 0:
		queue_redraw()

func emit_hit(event: Dictionary) -> void:
	if _effect_intensity <= 0.0 or _hit_emissions_this_frame >= _hit_emission_limit:
		return
	_hit_emissions_this_frame += 1
	var position: Vector2 = event.get("position", Vector2.ZERO) as Vector2
	var critical := bool(event.get("critical", false))
	var killing_blow := bool(event.get("killing_blow", false))
	var is_dot := bool(event.get("dot", false))
	var is_piercing := bool(event.get("piercing", false))
	var is_aoe := bool(event.get("aoe", false))
	var is_elite := bool(event.get("elite", false))
	var is_volatile := bool(event.get("volatile", false))
	var element := String(event.get("element", ""))
	var family := _family(element)
	var color := _color_for(family)
	if element.is_empty():
		color = Color(1.0, 0.90, 0.38) if critical else Color(1.0, 0.52, 0.25)
	if killing_blow:
		color = Color(1.0, 0.78, 0.42) if is_elite else Color(0.95, 0.72, 1.0)
	var count := 1 if is_dot else (3 if is_piercing or is_aoe else (8 if critical else 4))
	if killing_blow and not is_volatile:
		count = 12 if is_elite else 7
	count = maxi(1, int(round(float(count) * _effect_intensity)))
	if not is_dot and not is_piercing and not (killing_blow and is_volatile):
		var end_radius := 54.0 if killing_blow else (42.0 if critical else 30.0)
		_add_pulse(position, color, 7.0, end_radius, 0.26, family)
	for i in count:
		var angle := randf() * TAU
		var speed := randf_range(55.0, 230.0 if critical or killing_blow else 145.0)
		_add_particle(position, Vector2.from_angle(angle) * speed, color, randf_range(0.16, 0.38), randf_range(1.6, 4.6), family)
	_trim()

func emit_blocked(position: Vector2, color: Color) -> void:
	if _effect_intensity <= 0.0 or _hit_emissions_this_frame >= _hit_emission_limit:
		return
	_hit_emissions_this_frame += 1
	_add_pulse(position, color, 12.0, 48.0, 0.24, "shield")
	for i in maxi(2, int(round(4.0 * _effect_intensity))):
		var angle := -PI * 0.85 + float(i) * PI * 0.55
		_add_particle(position, Vector2.from_angle(angle) * 95.0, color, 0.22, 3.0, "shield")
	_trim()

func emit_player_damage(position: Vector2, heavy: bool) -> void:
	if _effect_intensity <= 0.0:
		return
	var color := Color(1.0, 0.22, 0.18)
	_add_pulse(position, color, 10.0, 50.0 if heavy else 34.0, 0.24, "impact")
	for i in maxi(2, int(round((7.0 if heavy else 4.0) * _effect_intensity))):
		var angle := randf() * TAU
		_add_particle(position, Vector2.from_angle(angle) * randf_range(70.0, 155.0), color, 0.25, 3.2, "impact")
	_trim()

func emit_heal(position: Vector2, major: bool) -> void:
	if _effect_intensity <= 0.0:
		return
	var color := _color_for("healing")
	_add_pulse(position, color, 8.0, 52.0 if major else 34.0, 0.32, "healing")
	for i in maxi(3, int(round((10.0 if major else 5.0) * _effect_intensity))):
		var offset := Vector2(randf_range(-24.0, 24.0), randf_range(-8.0, 24.0))
		_add_particle(position + offset, Vector2(randf_range(-12.0, 12.0), randf_range(-105.0, -55.0)), color, 0.42, 3.5, "healing")
	_trim()

func emit_ultimate(position: Vector2) -> void:
	if _effect_intensity <= 0.0:
		return
	var color := Color(1.0, 0.78, 0.25)
	_add_pulse(position, color, 18.0, 118.0, 0.38, "arcane")
	for i in maxi(8, int(round(18.0 * _effect_intensity))):
		var angle := TAU * float(i) / 18.0
		_add_particle(position, Vector2.from_angle(angle) * 175.0, color, 0.42, 4.5, "arcane")
	_trim()

func clear_transients() -> void:
	_particles.clear()
	_pulses.clear()
	_streaks.clear()
	_hit_emissions_this_frame = 0
	set_process(false)
	queue_redraw()

func active_effect_count() -> int:
	return _particles.size() + _pulses.size() + _streaks.size()

func emit_cast(cue: String, position: Vector2) -> void:
	if _effect_intensity <= 0.0:
		return
	var family := _family(cue)
	var color := _color_for(family)
	var major := _is_major(cue)
	_add_pulse(position, color, 28.0 if major else 18.0, 190.0 if major else 105.0, 0.55 if major else 0.34, family)
	var count := maxi(6 if major else 3, int(round(float(24 if major else 10) * _effect_intensity)))
	for i in count:
		var angle := TAU * float(i) / float(count) + randf_range(-0.18, 0.18)
		var speed := randf_range(110.0, 330.0 if major else 220.0)
		_add_particle(position + Vector2.from_angle(angle) * randf_range(4.0, 24.0), Vector2.from_angle(angle) * speed, color, randf_range(0.28, 0.62), randf_range(2.5, 7.0), family)
	if family in ["projectile", "blade", "lightning"]:
		for i in (5 if major else 3):
			var direction := Vector2.from_angle(randf() * TAU)
			_streaks.append({"a": position - direction * randf_range(12.0, 35.0), "b": position + direction * randf_range(35.0, 90.0), "color": color, "life": 0.22, "max_life": 0.22})
	_trim()
	queue_redraw()

func emit_impact(position: Vector2, critical: bool = false, defeated: bool = false) -> void:
	if _effect_intensity <= 0.0:
		return
	var color := Color(1.0, 0.90, 0.38) if critical else Color(1.0, 0.52, 0.25)
	if defeated:
		color = Color(0.95, 0.72, 1.0)
	_add_pulse(position, color, 8.0, 62.0 if defeated else 38.0, 0.30, "impact")
	var count := maxi(3 if defeated or critical else 1, int(round(float(16 if defeated else 9 if critical else 5) * _effect_intensity)))
	for i in count:
		var angle := randf() * TAU
		_add_particle(position, Vector2.from_angle(angle) * randf_range(80.0, 260.0), color, randf_range(0.20, 0.46), randf_range(2.0, 5.5), "impact")
	_trim()

func emit_dash(from: Vector2, to: Vector2, cue: String = "skill_blink") -> void:
	if _effect_intensity <= 0.0:
		return
	var color := _color_for(_family(cue))
	var distance := from.distance_to(to)
	var steps := clampi(int(float(clampi(int(distance / 22.0), 3, 18)) * _effect_intensity), 2, 18)
	for i in steps:
		var t := float(i) / float(maxi(steps - 1, 1))
		var pos := from.lerp(to, t)
		_add_particle(pos, Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0)), color, 0.34 + t * 0.16, 7.0 * (1.0 - t * 0.45), "shadow")
	_add_pulse(to, color, 10.0, 72.0, 0.34, "shadow")
	_trim()

func _process(delta: float) -> void:
	_hit_emissions_this_frame = 0
	_time += delta
	for i in range(_particles.size() - 1, -1, -1):
		var p: Dictionary = _particles[i]
		p["life"] = float(p["life"]) - delta
		if float(p["life"]) <= 0.0:
			_particles.remove_at(i)
			continue
		p["pos"] = (p["pos"] as Vector2) + (p["vel"] as Vector2) * delta
		p["vel"] = (p["vel"] as Vector2) * exp(-3.2 * delta) + Vector2(0.0, 28.0) * delta
	for i in range(_pulses.size() - 1, -1, -1):
		_pulses[i]["life"] = float(_pulses[i]["life"]) - delta
		if float(_pulses[i]["life"]) <= 0.0:
			_pulses.remove_at(i)
	for i in range(_streaks.size() - 1, -1, -1):
		_streaks[i]["life"] = float(_streaks[i]["life"]) - delta
		if float(_streaks[i]["life"]) <= 0.0:
			_streaks.remove_at(i)
	if not _particles.is_empty() or not _pulses.is_empty() or not _streaks.is_empty():
		queue_redraw()
	else:
		queue_redraw()
		set_process(false)

func _draw() -> void:
	var visual_scale := _effect_intensity
	for pulse in _pulses:
		var ratio := clampf(float(pulse["life"]) / float(pulse["max_life"]), 0.0, 1.0)
		var progress := 1.0 - ratio
		var radius := lerpf(float(pulse["start_r"]), float(pulse["end_r"]), ease(progress, -1.8))
		var color: Color = pulse["color"] as Color
		var pos: Vector2 = pulse["pos"] as Vector2
		draw_circle(pos, radius * 0.72, Color(color.r, color.g, color.b, 0.10 * ratio * visual_scale))
		draw_arc(pos, radius, 0.0, TAU, 36, Color(color.r, color.g, color.b, 0.88 * ratio * visual_scale), maxf(1.0, 5.0 * ratio))
		draw_arc(pos, radius * 0.72, _time * 2.4, _time * 2.4 + PI * 1.35, 24, Color(1.0, 1.0, 1.0, 0.48 * ratio * visual_scale), maxf(1.0, 2.0 * ratio))
		_draw_family_marks(pos, radius, ratio * visual_scale, String(pulse["family"]), color)
	for streak in _streaks:
		var ratio := float(streak["life"]) / float(streak["max_life"])
		var color: Color = streak["color"] as Color
		draw_line(streak["a"] as Vector2, streak["b"] as Vector2, Color(color.r, color.g, color.b, 0.72 * ratio * visual_scale), 5.0 * ratio)
		draw_line(streak["a"] as Vector2, streak["b"] as Vector2, Color(1, 1, 1, 0.58 * ratio * visual_scale), 1.4)
	for particle in _particles:
		var ratio := clampf(float(particle["life"]) / float(particle["max_life"]), 0.0, 1.0)
		var color: Color = particle["color"] as Color
		var pos: Vector2 = particle["pos"] as Vector2
		var size := float(particle["size"]) * (0.35 + ratio * 0.65)
		draw_circle(pos, size * 1.8, Color(color.r, color.g, color.b, 0.12 * ratio * visual_scale))
		draw_circle(pos, size, Color(color.r, color.g, color.b, 0.90 * ratio * visual_scale))
		draw_circle(pos, size * 0.38, Color(1, 1, 1, 0.82 * ratio * visual_scale))

func _draw_family_marks(pos: Vector2, radius: float, alpha: float, family: String, color: Color) -> void:
	match family:
		"lightning":
			for i in 4:
				var a := float(i) / 4.0 * TAU + _time * 5.0
				var p1 := pos + Vector2.from_angle(a) * radius * 0.55
				var p2 := pos + Vector2.from_angle(a + 0.16) * radius * 1.12
				draw_line(p1, p2, Color(1, 1, 0.72, 0.76 * alpha), 2.2 * alpha)
		"ice":
			for i in 6:
				var a := float(i) / 6.0 * TAU
				draw_line(pos + Vector2.from_angle(a) * radius * 0.48, pos + Vector2.from_angle(a) * radius * 1.04, Color(0.78, 0.96, 1.0, 0.70 * alpha), 2.0)
		"nature", "healing":
			for i in 5:
				var a := float(i) / 5.0 * TAU + _time
				draw_circle(pos + Vector2.from_angle(a) * radius * 0.83, 4.0 * alpha, Color(color.r, color.g, color.b, 0.75 * alpha))
		"blade":
			for i in 3:
				var a := float(i) / 3.0 * TAU + _time * 3.0
				draw_arc(pos, radius * (0.75 + float(i) * 0.1), a, a + 0.65, 10, Color(1, 0.86, 0.92, 0.72 * alpha), 3.0 * alpha)
		_:
			pass

func _add_particle(pos: Vector2, velocity: Vector2, color: Color, life: float, size: float, family: String) -> void:
	set_process(true)
	_particles.append({"pos": pos, "vel": velocity, "color": color, "life": life, "max_life": life, "size": size, "family": family})

func _add_pulse(pos: Vector2, color: Color, start_r: float, end_r: float, life: float, family: String) -> void:
	set_process(true)
	_pulses.append({"pos": pos, "color": color, "start_r": start_r, "end_r": end_r, "life": life, "max_life": life, "family": family})

func _trim() -> void:
	while _particles.size() > _particle_limit:
		_particles.pop_front()
	while _pulses.size() > _pulse_limit:
		_pulses.pop_front()
	while _streaks.size() > _streak_limit:
		_streaks.pop_front()

func _is_major(cue: String) -> bool:
	return cue.contains("blizzard") or cue.contains("storm") or cue.contains("nova") or cue.contains("wave") or cue.contains("barrage") or cue.contains("feast") or cue.contains("plague") or cue.contains("charge")

func _family(cue: String) -> String:
	var key := cue.to_lower()
	if key.contains("ice") or key.contains("blizzard") or key.contains("frozen"): return "ice"
	if key.contains("bolt") or key.contains("lightning") or key.contains("elec") or key.contains("thunder"): return "lightning"
	if key.contains("fire") or key.contains("chili") or key.contains("inferno") or key.contains("lava"): return "fire"
	if key.contains("arrow") or key.contains("knife") or key.contains("blade") or key.contains("slash"): return "blade"
	if key.contains("poison") or key.contains("venom") or key.contains("vine") or key.contains("bog") or key.contains("mushroom"): return "nature"
	if key.contains("regen") or key.contains("heal") or key.contains("feast") or key.contains("aura"): return "healing"
	if key.contains("shadow") or key.contains("smoke") or key.contains("blink") or key.contains("corruption"): return "shadow"
	if key.contains("time") or key.contains("prism") or key.contains("mana") or key.contains("arcane"): return "arcane"
	if key.contains("arrow") or key.contains("bolt") or key.contains("orb"): return "projectile"
	return "impact"

func _color_for(family: String) -> Color:
	match family:
		"ice": return Color(0.42, 0.88, 1.0)
		"lightning": return Color(1.0, 0.92, 0.20)
		"fire": return Color(1.0, 0.32, 0.06)
		"blade": return Color(1.0, 0.38, 0.54)
		"nature": return Color(0.46, 0.94, 0.20)
		"healing": return Color(0.38, 1.0, 0.62)
		"shadow": return Color(0.62, 0.28, 1.0)
		"arcane": return Color(0.42, 0.58, 1.0)
		"projectile": return Color(1.0, 0.70, 0.18)
		_: return Color(1.0, 0.68, 0.22)
