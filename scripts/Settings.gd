extends CanvasLayer

## Modal settings panel. Persists changes via SettingsStore and applies them
## immediately so the player sees the effect.

signal closed
signal logout_requested

var _data: Dictionary = {}

var _sfx_slider: HSlider
var _music_slider: HSlider
var _bright_slider: HSlider
var _mute_check: CheckBox
var _fps_check: CheckBox

func _ready() -> void:
	layer = 50
	_data = SettingsStore.load_all()
	_build_ui()

func _build_ui() -> void:
	var view := get_viewport().get_visible_rect().size

	# Dim backdrop that absorbs taps outside the panel.
	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.55)
	scrim.size = view
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(scrim)

	var panel := PanelContainer.new()
	var panel_w: float = min(view.x - 80.0, 720.0)
	var panel_h: float = min(view.y - 200.0, 1100.0)
	panel.custom_minimum_size = Vector2(panel_w, panel_h)
	panel.position = Vector2((view.x - panel_w) * 0.5, (view.y - panel_h) * 0.5)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.99, 0.96, 0.88)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.border_color = Color(0.35, 0.18, 0.08)
	style.set_border_width_all(3)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	panel.add_child(col)

	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.35, 0.18, 0.08))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	_sfx_slider = _add_slider(col, "Sound effects", "sfx_volume", 0.0, 100.0, 1.0)
	_music_slider = _add_slider(col, "Music", "music_volume", 0.0, 100.0, 1.0)
	_bright_slider = _add_slider(col, "Brightness", "brightness", 0.4, 1.0, 0.01, true)

	_mute_check = _add_check(col, "Mute all audio", "muted")
	_fps_check = _add_check(col, "Show FPS counter", "show_fps")

	var sep := HSeparator.new()
	col.add_child(sep)

	var reset_btn := Button.new()
	reset_btn.text = "Reset my stats"
	reset_btn.add_theme_font_size_override("font_size", 24)
	reset_btn.custom_minimum_size = Vector2(0, 60)
	_style_secondary(reset_btn)
	reset_btn.pressed.connect(_on_reset_stats)
	col.add_child(reset_btn)

	var logout_btn := Button.new()
	logout_btn.text = "Log out / switch account"
	logout_btn.add_theme_font_size_override("font_size", 24)
	logout_btn.custom_minimum_size = Vector2(0, 60)
	_style_danger(logout_btn)
	logout_btn.pressed.connect(func() -> void: logout_requested.emit())
	col.add_child(logout_btn)

	var version := Label.new()
	version.text = "Capy Dungeon · prototype build"
	version.add_theme_font_size_override("font_size", 16)
	version.add_theme_color_override("font_color", Color(0.5, 0.4, 0.3))
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(version)

	var close_btn := Button.new()
	close_btn.text = "Done"
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.custom_minimum_size = Vector2(0, 72)
	_style_primary(close_btn)
	close_btn.pressed.connect(func() -> void: closed.emit())
	col.add_child(close_btn)

func _add_slider(parent: Node, label_text: String, key: String, min_v: float, max_v: float, step: float, is_percent_one: bool = false) -> HSlider:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var header := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.35, 0.22, 0.1))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl)
	var value_lbl := Label.new()
	value_lbl.add_theme_font_size_override("font_size", 22)
	value_lbl.add_theme_color_override("font_color", Color(0.35, 0.22, 0.1))
	header.add_child(value_lbl)
	row.add_child(header)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.value = float(_data.get(key, min_v))
	slider.custom_minimum_size = Vector2(0, 40)
	row.add_child(slider)
	var update_label := func(v: float) -> void:
		if is_percent_one:
			value_lbl.text = "%d%%" % int(round(v * 100.0))
		else:
			value_lbl.text = "%d" % int(round(v))
	update_label.call(slider.value)
	slider.value_changed.connect(func(v: float) -> void:
		update_label.call(v)
		_data = SettingsStore.set_value(key, v)
		SettingsStore.apply(get_tree()))
	return slider

func _add_check(parent: Node, label_text: String, key: String) -> CheckBox:
	var cb := CheckBox.new()
	cb.text = label_text
	cb.add_theme_font_size_override("font_size", 22)
	cb.button_pressed = bool(_data.get(key, false))
	# AA-compliant: all interactive states pinned to a dark ink colour (~11:1
	# contrast on the panel's warm-cream background). Godot's default theme
	# uses near-white for hover/pressed which would be unreadable here.
	var ink := Color(0.15, 0.08, 0.02)
	cb.add_theme_color_override("font_color", ink)
	cb.add_theme_color_override("font_hover_color", ink)
	cb.add_theme_color_override("font_pressed_color", ink)
	cb.add_theme_color_override("font_hover_pressed_color", ink)
	cb.add_theme_color_override("font_focus_color", ink)
	cb.toggled.connect(func(pressed: bool) -> void:
		_data = SettingsStore.set_value(key, pressed)
		SettingsStore.apply(get_tree()))
	parent.add_child(cb)
	return cb

func _on_reset_stats() -> void:
	# Show a confirmation overlay before destroying the player's stats.
	var view := get_viewport().get_visible_rect().size

	var scrim2 := ColorRect.new()
	scrim2.color = Color(0, 0, 0, 0.45)
	scrim2.size = view
	scrim2.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(scrim2)

	var box := PanelContainer.new()
	var box_w: float = min(view.x - 120.0, 600.0)
	box.custom_minimum_size = Vector2(box_w, 0)
	var bstyle := StyleBoxFlat.new()
	bstyle.bg_color = Color(0.99, 0.96, 0.88)
	bstyle.corner_radius_top_left = 14
	bstyle.corner_radius_top_right = 14
	bstyle.corner_radius_bottom_left = 14
	bstyle.corner_radius_bottom_right = 14
	bstyle.border_color = Color(0.75, 0.15, 0.1)
	bstyle.set_border_width_all(3)
	bstyle.content_margin_left = 20
	bstyle.content_margin_right = 20
	bstyle.content_margin_top = 16
	bstyle.content_margin_bottom = 16
	box.add_theme_stylebox_override("panel", bstyle)
	add_child(box)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	box.add_child(inner)

	var warn := Label.new()
	warn.text = "Reset stats?"
	warn.add_theme_font_size_override("font_size", 30)
	warn.add_theme_color_override("font_color", Color(0.6, 0.08, 0.06))
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(warn)

	var msg := Label.new()
	msg.text = "This will permanently erase all your wins, losses, and combos. Cannot be undone."
	msg.add_theme_font_size_override("font_size", 20)
	msg.add_theme_color_override("font_color", Color(0.15, 0.08, 0.02))
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(msg)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 16)
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_child(btns)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(180, 56)
	cancel_btn.add_theme_font_size_override("font_size", 24)
	_style_secondary(cancel_btn)
	cancel_btn.pressed.connect(func() -> void:
		scrim2.queue_free()
		box.queue_free())
	btns.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = "Yes, reset"
	confirm_btn.custom_minimum_size = Vector2(180, 56)
	confirm_btn.add_theme_font_size_override("font_size", 24)
	_style_danger(confirm_btn)
	confirm_btn.pressed.connect(func() -> void:
		scrim2.queue_free()
		box.queue_free()
		var username := ""
		for n in get_tree().get_nodes_in_group("active_account"):
			if n.has_meta("username"):
				username = String(n.get_meta("username"))
				break
		if username != "":
			StatsStore.reset_user(username))
	btns.add_child(confirm_btn)

	# Position the dialog centred on screen after layout settles.
	box.set_deferred("position", Vector2(
		(view.x - box_w) * 0.5,
		view.y * 0.3))

# ---- Button style helpers ---------------------------------------------------

func _style_primary(btn: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.98, 0.72, 0.08)
	n.corner_radius_top_left = 28
	n.corner_radius_top_right = 28
	n.corner_radius_bottom_right = 28
	n.corner_radius_bottom_left = 28
	n.border_color = Color(0.72, 0.42, 0.0)
	n.set_border_width_all(3)
	n.shadow_color = Color(0.72, 0.42, 0.0, 0.58)
	n.shadow_size = 12
	n.shadow_offset = Vector2(0, 5)
	var h := StyleBoxFlat.new()
	h.bg_color = Color(1.0, 0.82, 0.25)
	h.corner_radius_top_left = 28
	h.corner_radius_top_right = 28
	h.corner_radius_bottom_right = 28
	h.corner_radius_bottom_left = 28
	h.border_color = Color(0.72, 0.42, 0.0)
	h.set_border_width_all(3)
	h.shadow_color = Color(0.72, 0.42, 0.0, 0.58)
	h.shadow_size = 12
	h.shadow_offset = Vector2(0, 5)
	var p := StyleBoxFlat.new()
	p.bg_color = Color(0.80, 0.56, 0.03)
	p.corner_radius_top_left = 28
	p.corner_radius_top_right = 28
	p.corner_radius_bottom_right = 28
	p.corner_radius_bottom_left = 28
	p.border_color = Color(0.58, 0.32, 0.0)
	p.set_border_width_all(3)
	p.shadow_color = Color(0.58, 0.32, 0.0, 0.4)
	p.shadow_size = 5
	p.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color", Color(0.10, 0.05, 0.0))
	btn.add_theme_color_override("font_hover_color", Color(0.08, 0.04, 0.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.08, 0.04, 0.0))
	btn.focus_mode = Control.FOCUS_NONE

func _style_secondary(btn: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.14, 0.14, 0.22, 0.92)
	n.corner_radius_top_left = 28
	n.corner_radius_top_right = 28
	n.corner_radius_bottom_right = 28
	n.corner_radius_bottom_left = 28
	n.border_color = Color(0.55, 0.55, 0.75, 0.75)
	n.set_border_width_all(2)
	n.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	n.shadow_size = 7
	n.shadow_offset = Vector2(0, 3)
	var h := StyleBoxFlat.new()
	h.bg_color = Color(0.22, 0.22, 0.35, 0.95)
	h.corner_radius_top_left = 28
	h.corner_radius_top_right = 28
	h.corner_radius_bottom_right = 28
	h.corner_radius_bottom_left = 28
	h.border_color = Color(0.65, 0.65, 0.88, 0.85)
	h.set_border_width_all(2)
	h.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	h.shadow_size = 7
	h.shadow_offset = Vector2(0, 3)
	var p := StyleBoxFlat.new()
	p.bg_color = Color(0.08, 0.08, 0.16, 0.95)
	p.corner_radius_top_left = 28
	p.corner_radius_top_right = 28
	p.corner_radius_bottom_right = 28
	p.corner_radius_bottom_left = 28
	p.border_color = Color(0.45, 0.45, 0.65, 0.7)
	p.set_border_width_all(2)
	p.shadow_color = Color(0.0, 0.0, 0.0, 0.2)
	p.shadow_size = 3
	p.shadow_offset = Vector2(0, 1)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color", Color(0.90, 0.90, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.72, 0.72, 0.88))
	btn.focus_mode = Control.FOCUS_NONE

func _style_danger(btn: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.70, 0.12, 0.12)
	n.corner_radius_top_left = 28
	n.corner_radius_top_right = 28
	n.corner_radius_bottom_right = 28
	n.corner_radius_bottom_left = 28
	n.border_color = Color(0.50, 0.05, 0.05)
	n.set_border_width_all(3)
	n.shadow_color = Color(0.65, 0.05, 0.05, 0.50)
	n.shadow_size = 8
	n.shadow_offset = Vector2(0, 4)
	var h := StyleBoxFlat.new()
	h.bg_color = Color(0.85, 0.18, 0.18)
	h.corner_radius_top_left = 28
	h.corner_radius_top_right = 28
	h.corner_radius_bottom_right = 28
	h.corner_radius_bottom_left = 28
	h.border_color = Color(0.55, 0.08, 0.05)
	h.set_border_width_all(3)
	h.shadow_color = Color(0.65, 0.05, 0.05, 0.50)
	h.shadow_size = 8
	h.shadow_offset = Vector2(0, 4)
	var p := StyleBoxFlat.new()
	p.bg_color = Color(0.55, 0.08, 0.08)
	p.corner_radius_top_left = 28
	p.corner_radius_top_right = 28
	p.corner_radius_bottom_right = 28
	p.corner_radius_bottom_left = 28
	p.border_color = Color(0.42, 0.04, 0.04)
	p.set_border_width_all(3)
	p.shadow_color = Color(0.42, 0.02, 0.02, 0.35)
	p.shadow_size = 4
	p.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.90, 0.90, 0.90))
	btn.focus_mode = Control.FOCUS_NONE
