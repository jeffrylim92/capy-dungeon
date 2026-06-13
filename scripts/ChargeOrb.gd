class_name ChargeOrb
extends Control

## Glass-sphere charge meter. Liquid fills from the bottom as the orb's
## `ratio` (0..1) climbs. Emits `tapped` when the player presses the orb so
## the Match scene can decide whether to unleash the finisher.

signal tapped
signal became_ready

const RADIUS: float = 64.0
const PADDING: float = 12.0

var ratio: float = 0.0:
	set(value):
		ratio = clamp(value, 0.0, 1.0)
		queue_redraw()

var liquid_color: Color = Color(0.55, 0.35, 0.95):
	set(value):
		liquid_color = value
		queue_redraw()

var ready_flag: bool = false
var _pulse: Tween
var _shimmer: float = 0.0
var _ready_phase: float = 0.0
var _tap_label: Label
var _tap_tween: Tween

func _ready() -> void:
	custom_minimum_size = Vector2(RADIUS * 2.0 + PADDING * 2.0, RADIUS * 2.0 + PADDING * 2.0)
	size = custom_minimum_size
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tap_label = Label.new()
	_tap_label.text = "TAP!"
	_tap_label.add_theme_font_size_override("font_size", 26)
	_tap_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.3))
	_tap_label.add_theme_color_override("font_outline_color", Color(0.55, 0.08, 0.0))
	_tap_label.add_theme_constant_override("outline_size", 5)
	_tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tap_label.size = Vector2(size.x, 32)
	_tap_label.position = Vector2(0, -38)
	_tap_label.pivot_offset = _tap_label.size * 0.5
	_tap_label.visible = false
	_tap_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tap_label)
	set_process(true)

func _process(delta: float) -> void:
	_shimmer += delta * 3.0
	if ready_flag:
		_ready_phase += delta
	queue_redraw()

func set_ready(is_ready: bool) -> void:
	if ready_flag == is_ready:
		return
	ready_flag = is_ready
	if _pulse and _pulse.is_valid():
		_pulse.kill()
	if _tap_tween and _tap_tween.is_valid():
		_tap_tween.kill()
	if is_ready:
		_ready_phase = 0.0
		_pulse = create_tween().set_loops()
		_pulse.tween_property(self, "scale", Vector2(1.14, 1.14), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_pulse.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tap_label.visible = true
		_tap_label.modulate = Color(1, 1, 1, 1)
		_tap_label.position = Vector2(0, -38)
		_tap_label.scale = Vector2.ONE
		_tap_tween = create_tween().set_loops()
		_tap_tween.tween_property(_tap_label, "position:y", -52.0, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tap_tween.parallel().tween_property(_tap_label, "scale", Vector2(1.15, 1.15), 0.32)
		_tap_tween.tween_property(_tap_label, "position:y", -34.0, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_tap_tween.parallel().tween_property(_tap_label, "scale", Vector2.ONE, 0.32)
		became_ready.emit()
	else:
		scale = Vector2.ONE
		_tap_label.visible = false

func _gui_input(event: InputEvent) -> void:
	var pressed_pos: Vector2 = Vector2.ZERO
	var is_press: bool = false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed_pos = event.position
		is_press = true
	elif event is InputEventScreenTouch and event.pressed:
		pressed_pos = event.position
		is_press = true
	if not is_press:
		return
	var c: Vector2 = size * 0.5
	if pressed_pos.distance_to(c) <= RADIUS + 6.0:
		accept_event()
		tapped.emit()

func drain() -> void:
	# Release flash, then empty the sphere ready for the next charge cycle.
	set_ready(false)
	var orig: Color = Color(0.55, 0.35, 0.95)
	var t := create_tween()
	t.tween_property(self, "liquid_color", Color(1.0, 0.95, 0.7), 0.08)
	t.parallel().tween_property(self, "ratio", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(self, "liquid_color", orig, 0.25)

func _draw() -> void:
	var c: Vector2 = size * 0.5
	# Ready glow + expanding shockwave rings.
	if ready_flag:
		var halo: float = (sin(_shimmer * 2.2) * 0.5 + 0.5)
		draw_circle(c, RADIUS + 14.0, Color(1.0, 0.95, 0.4, 0.22 + 0.16 * halo))
		draw_circle(c, RADIUS + 7.0, Color(1.0, 0.85, 0.3, 0.36 + 0.18 * halo))
		# Three staggered shockwave rings that grow from the rim and fade out.
		var ring_period: float = 1.2
		for i in 3:
			var phase: float = fposmod(_ready_phase + float(i) * (ring_period / 3.0), ring_period) / ring_period
			var ring_r: float = RADIUS + 6.0 + phase * 64.0
			var ring_a: float = (1.0 - phase) * 0.55
			draw_arc(c, ring_r, 0.0, TAU, 48, Color(1.0, 0.9, 0.4, ring_a), 3.0, true)
	# Glass back.
	draw_circle(c, RADIUS, Color(0.08, 0.05, 0.14, 0.85))
	# Liquid body.
	if ratio >= 0.999:
		draw_circle(c, RADIUS - 2.0, liquid_color)
	elif ratio > 0.0:
		var inner_r: float = RADIUS - 2.0
		var y_rel: float = inner_r - 2.0 * inner_r * ratio
		var sin_t: float = clamp(y_rel / inner_r, -1.0, 1.0)
		var theta_r: float = asin(sin_t)
		var theta_l: float = PI - theta_r
		# Lower arc: right-surface → bottom → left-surface.
		var n: int = 40
		var arc := PackedVector2Array()
		for i in n + 1:
			var ft: float = float(i) / float(n)
			var theta: float = lerp(theta_r, theta_l, ft)
			arc.append(c + Vector2(cos(theta), sin(theta)) * inner_r)
		# Wavy surface from left back to right.
		var seg: int = 18
		var x_right: float = c.x + cos(theta_r) * inner_r
		var x_left: float = c.x + cos(theta_l) * inner_r
		var surface_y: float = c.y + y_rel
		var wave := PackedVector2Array()
		for i in seg + 1:
			var ft: float = float(i) / float(seg)
			var x: float = lerp(x_right, x_left, ft)
			# Fade wave to zero at the endpoints so the polygon corners match the
			# arc exactly — eliminates the tiny seam that can cause render flicker.
			var edge_fade: float = sin(ft * PI)
			var wy: float = surface_y + sin(_shimmer + ft * TAU) * 1.6 * edge_fade
			wave.append(Vector2(x, wy))
		var poly := PackedVector2Array()
		poly.append_array(arc)
		for i in range(wave.size() - 1, -1, -1):
			poly.append(wave[i])
		draw_colored_polygon(poly, liquid_color)
		# Bright surface line.
		draw_polyline(wave, Color(1.0, 1.0, 1.0, 0.55), 2.0, true)
	# Glass rim + highlight.
	draw_arc(c, RADIUS, 0.0, TAU, 64, Color(1.0, 1.0, 1.0, 0.75), 3.0, true)
	draw_circle(c + Vector2(-RADIUS * 0.35, -RADIUS * 0.4), RADIUS * 0.18, Color(1.0, 1.0, 1.0, 0.22))
