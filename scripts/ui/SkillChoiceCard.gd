class_name SkillChoiceCard
extends Button

signal detail_requested

var _accent: Color = Color.WHITE
var _state: String = "new"
var _motion_scale: float = 1.0
var _active_tween: Tween = null
var _selection_locked: bool = false

func configure(model: Dictionary) -> void:
	for child in get_children():
		child.queue_free()
	_state = str(model.get("state", "new"))
	_accent = model.get("accent", Color.WHITE) as Color
	_motion_scale = clampf(float(model.get("motion_scale", 1.0)), 0.0, 1.0)
	_selection_locked = false
	text = ""
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clip_contents = false
	pivot_offset = size * 0.5
	_apply_styles(false)

	var badge := Label.new()
	badge.text = _badge_text()
	badge.position = Vector2(196.0, 13.0)
	badge.size = Vector2(size.x - 264.0, 25.0)
	badge.add_theme_font_size_override("font_size", 16)
	badge.add_theme_color_override("font_color", _badge_color())
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(badge)

	var icon_frame := Panel.new()
	icon_frame.position = Vector2(22.0, 40.0)
	icon_frame.size = Vector2(148.0, 148.0)
	icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_frame.clip_contents = true
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = Color(0.035, 0.03, 0.025, 0.98)
	icon_style.border_color = _accent.lightened(0.12)
	icon_style.set_border_width_all(5 if _state in ["evolved", "ultimate", "combo"] else 3)
	icon_style.set_corner_radius_all(28 if _state == "ultimate" else 16)
	icon_frame.add_theme_stylebox_override("panel", icon_style)
	add_child(icon_frame)

	var icon_texture: Texture2D = model.get("icon", null) as Texture2D
	if icon_texture != null:
		var icon := TextureRect.new()
		icon.texture = icon_texture
		icon.position = Vector2(8.0, 8.0)
		icon.size = Vector2(132.0, 132.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_frame.add_child(icon)
	else:
		var fallback := Label.new()
		fallback.text = str(model.get("abbreviation", "?"))
		fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 38)
		fallback.add_theme_color_override("font_color", _accent)
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_frame.add_child(fallback)

	if _state in ["evolved", "ultimate", "combo"]:
		var marker := Label.new()
		marker.text = "◆"
		marker.position = Vector2(5.0, 2.0)
		marker.size = Vector2(35.0, 35.0)
		marker.add_theme_font_size_override("font_size", 24)
		marker.add_theme_color_override("font_color", _accent.lightened(0.25))
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(marker)

	var name_label := Label.new()
	name_label.name = "SkillTitle"
	name_label.text = str(model.get("title", "SKILL"))
	name_label.position = Vector2(196.0, 40.0)
	name_label.size = Vector2(size.x - 275.0, 58.0)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.add_theme_font_size_override("font_size", 33)
	name_label.add_theme_color_override("font_color", _accent.lightened(0.12))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_label)

	var level_label := Label.new()
	level_label.text = str(model.get("level", "NEW"))
	level_label.position = Vector2(196.0, 94.0)
	level_label.size = Vector2(size.x - 218.0, 28.0)
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.add_theme_color_override("font_color", Color(0.92, 0.87, 0.72))
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(level_label)

	var primary := Label.new()
	primary.name = "PrimaryChange"
	primary.text = str(model.get("primary", "NEW POWER"))
	primary.position = Vector2(196.0, 124.0)
	primary.size = Vector2(size.x - 218.0, 42.0)
	primary.add_theme_font_size_override("font_size", 29)
	primary.add_theme_color_override("font_color", Color(1.0, 0.91, 0.48) if _state != "new" else Color(0.55, 1.0, 0.68))
	primary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(primary)

	var tags := HBoxContainer.new()
	tags.name = "SkillTags"
	tags.position = Vector2(196.0, 174.0)
	tags.size = Vector2(size.x - 275.0, 34.0)
	tags.add_theme_constant_override("separation", 8)
	tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tags)
	for tag_variant in model.get("tags", []) as Array:
		var tag := Label.new()
		tag.text = str(tag_variant)
		tag.add_theme_font_size_override("font_size", 14)
		tag.add_theme_color_override("font_color", Color(0.78, 0.88, 0.91))
		tag.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
		tag.add_theme_constant_override("outline_size", 3)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tags.add_child(tag)

	var info := Button.new()
	info.name = "DetailsButton"
	info.text = "ⓘ"
	info.position = Vector2(size.x - 64.0, 12.0)
	info.size = Vector2(48.0, 48.0)
	info.focus_mode = Control.FOCUS_NONE
	info.tooltip_text = "Details"
	info.add_theme_font_size_override("font_size", 22)
	var info_style := StyleBoxFlat.new()
	info_style.bg_color = Color(0.06, 0.08, 0.10, 0.88)
	info_style.border_color = Color(0.72, 0.78, 0.82, 0.72)
	info_style.set_border_width_all(2)
	info_style.set_corner_radius_all(18)
	info.add_theme_stylebox_override("normal", info_style)
	info.add_theme_stylebox_override("hover", info_style)
	info.add_theme_stylebox_override("pressed", info_style)
	info.pressed.connect(func() -> void: detail_requested.emit())
	add_child(info)

func animate_entry(delay: float) -> void:
	_kill_tween()
	var target_position := position
	modulate.a = 0.0
	position = target_position + Vector2(0.0, 10.0 * _motion_scale)
	scale = Vector2.ONE * (1.0 - 0.04 * _motion_scale)
	_active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(self, "modulate:a", 1.0, 0.14).set_delay(delay)
	_active_tween.tween_property(self, "position", target_position, 0.18).set_delay(delay)
	_active_tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_delay(delay)

func animate_selected(duration: float) -> void:
	_kill_tween()
	pivot_offset = size * 0.5
	_apply_styles(true)
	var peak := 1.0 + (0.07 if _state == "evolved" else 0.035) * _motion_scale
	_active_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(self, "scale", Vector2.ONE * peak, duration * 0.45)
	_active_tween.tween_property(self, "scale", Vector2.ONE, duration * 0.55)

func set_dimmed(value: bool) -> void:
	modulate = Color(0.48, 0.48, 0.48, 0.72) if value else Color.WHITE
	disabled = value

func lock_input() -> void:
	disabled = true
	var info := get_node_or_null("DetailsButton") as Button
	if info != null:
		info.disabled = true

func try_lock_selection() -> bool:
	if _selection_locked:
		return false
	_selection_locked = true
	return true

func _apply_styles(selected: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = _background_color()
	normal.border_color = Color.WHITE if selected else _accent.lightened(0.04)
	normal.set_border_width_all(6 if selected or _state in ["evolved", "ultimate"] else (4 if _state in ["new", "combo"] else 3))
	normal.corner_radius_top_left = 24
	normal.corner_radius_top_right = 10 if _state in ["evolved", "combo"] else 24
	normal.corner_radius_bottom_left = 10 if _state in ["evolved", "combo"] else 24
	normal.corner_radius_bottom_right = 24
	normal.shadow_color = Color(_accent.r, _accent.g, _accent.b, 0.34 if selected else 0.20)
	normal.shadow_size = 16 if selected else 10
	normal.shadow_offset = Vector2(0.0, 4.0)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.07)
	hover.border_color = _accent.lightened(0.22)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.08)
	pressed.shadow_size = 4
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed)
	add_theme_stylebox_override("disabled", normal)

func _background_color() -> Color:
	match _state:
		"ultimate": return Color(0.16, 0.105, 0.015, 0.98)
		"evolved": return Color(0.075, 0.105, 0.13, 0.98)
		"combo": return Color(0.045, 0.12, 0.115, 0.98)
		"new": return Color(0.055, 0.115, 0.075, 0.98)
		_: return Color(0.10, 0.08, 0.06, 0.98)

func _badge_text() -> String:
	match _state:
		"ultimate": return "◆ ULTIMATE ◆"
		"evolved": return "◆ EVOLUTION ◆"
		"combo": return "✦ COMBO ✦"
		"upgrade": return "UPGRADE"
		_: return "NEW"

func _badge_color() -> Color:
	match _state:
		"new": return Color(0.42, 1.0, 0.62)
		"combo", "evolved": return Color(0.52, 1.0, 0.94)
		_: return Color(1.0, 0.82, 0.24)

func _kill_tween() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null
