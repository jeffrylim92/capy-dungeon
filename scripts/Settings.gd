extends CanvasLayer

## Modal settings panel. Persists changes via SettingsStore and applies them
## immediately so the player sees the effect.

signal closed
signal logout_requested
signal display_name_changed(new_name: String)

const _PROFILE_PATH := "user://profile.json"

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
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.35, 0.18, 0.08))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	_sfx_slider = _add_slider(col, "Sound effects", "sfx_volume", 0.0, 100.0, 1.0)
	_music_slider = _add_slider(col, "Music", "music_volume", 0.0, 100.0, 1.0)
	_bright_slider = _add_slider(col, "Brightness", "brightness", 0.4, 1.0, 0.01, true)

	_mute_check = _add_toggle(col, "Mute all audio", "muted")
	_fps_check   = _add_toggle(col, "Show FPS counter", "show_fps")

	var sep := HSeparator.new()
	col.add_child(sep)

	var reset_btn := Button.new()
	reset_btn.text = "Reset my stats"
	reset_btn.add_theme_font_size_override("font_size", 36)
	reset_btn.custom_minimum_size = Vector2(0, 80)
	_style_secondary(reset_btn)
	reset_btn.pressed.connect(_on_reset_stats)
	col.add_child(reset_btn)

	var profile_btn := Button.new()
	profile_btn.text = "My Profile"
	profile_btn.add_theme_font_size_override("font_size", 36)
	profile_btn.custom_minimum_size = Vector2(0, 80)
	_style_secondary(profile_btn)
	profile_btn.pressed.connect(_show_profile_panel)
	col.add_child(profile_btn)

	var close_btn := Button.new()
	close_btn.text = "Done"
	close_btn.add_theme_font_size_override("font_size", 40)
	close_btn.custom_minimum_size = Vector2(0, 88)
	_style_primary(close_btn)
	close_btn.pressed.connect(func() -> void: closed.emit())
	col.add_child(close_btn)

	var version := Label.new()
	version.text = "Capy Dungeon v1.0"
	version.add_theme_font_size_override("font_size", 26)
	version.add_theme_color_override("font_color", Color(0.55, 0.40, 0.25))
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(version)

func _add_slider(parent: Node, label_text: String, key: String, min_v: float, max_v: float, step: float, is_percent_one: bool = false) -> HSlider:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var header := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_color", Color(0.35, 0.22, 0.1))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl)
	var value_lbl := Label.new()
	value_lbl.add_theme_font_size_override("font_size", 34)
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

## Full-width toggle row — large hit area, easy to press on phone.
## Returns a CheckBox (for API compat) but the actual tappable area is the row button.
func _add_toggle(parent: Node, label_text: String, key: String) -> CheckBox:
	var is_on: bool = bool(_data.get(key, false))

	# Invisible CheckBox kept off-screen so the rest of the code can read .button_pressed
	var cb := CheckBox.new()
	cb.button_pressed = is_on
	cb.visible = false
	parent.add_child(cb)

	# The tappable row
	var row := Button.new()
	row.toggle_mode = true
	row.button_pressed = is_on
	row.focus_mode = Control.FOCUS_NONE
	row.custom_minimum_size = Vector2(0, 80)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Style the row itself
	var ink := Color(0.15, 0.08, 0.02)
	var s_off := StyleBoxFlat.new()
	s_off.bg_color = Color(0.90, 0.86, 0.76, 0.60)
	s_off.corner_radius_top_left = 14; s_off.corner_radius_top_right = 14
	s_off.corner_radius_bottom_right = 14; s_off.corner_radius_bottom_left = 14
	s_off.border_color = Color(0.65, 0.52, 0.35, 0.60); s_off.set_border_width_all(2)
	var s_on := StyleBoxFlat.new()
	s_on.bg_color = Color(0.88, 0.70, 0.12, 0.30)
	s_on.corner_radius_top_left = 14; s_on.corner_radius_top_right = 14
	s_on.corner_radius_bottom_right = 14; s_on.corner_radius_bottom_left = 14
	s_on.border_color = Color(0.80, 0.60, 0.10, 0.80); s_on.set_border_width_all(2)
	row.add_theme_stylebox_override("normal",         s_off)
	row.add_theme_stylebox_override("hover",          s_off)
	row.add_theme_stylebox_override("pressed",        s_on)
	row.add_theme_stylebox_override("normal_mirrored", s_on)  # toggled-on state
	row.add_theme_color_override("font_color",         ink)
	row.add_theme_color_override("font_hover_color",   ink)
	row.add_theme_color_override("font_pressed_color", ink)

	# Build the inside manually so we can put text left and the pill right
	var inner := HBoxContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("separation", 12)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(inner)

	# Pad left
	var lpad := Control.new(); lpad.custom_minimum_size = Vector2(16, 0)
	lpad.mouse_filter = Control.MOUSE_FILTER_IGNORE; inner.add_child(lpad)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_color", ink)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(lbl)

	# Pill indicator
	var pill := Label.new()
	pill.add_theme_font_size_override("font_size", 28)
	pill.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(pill)

	# Pad right
	var rpad := Control.new(); rpad.custom_minimum_size = Vector2(16, 0)
	rpad.mouse_filter = Control.MOUSE_FILTER_IGNORE; inner.add_child(rpad)

	var update_pill := func(on: bool) -> void:
		pill.text = "ON" if on else "OFF"
		pill.add_theme_color_override("font_color",
			Color(0.65, 0.45, 0.05) if on else Color(0.45, 0.35, 0.22))
		row.add_theme_stylebox_override("normal",
			s_on if on else s_off)
		row.add_theme_stylebox_override("hover",
			s_on if on else s_off)

	update_pill.call(is_on)

	row.toggled.connect(func(pressed: bool) -> void:
		cb.button_pressed = pressed
		update_pill.call(pressed)
		_data = SettingsStore.set_value(key, pressed)
		SettingsStore.apply(get_tree()))

	parent.add_child(row)
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
	warn.add_theme_font_size_override("font_size", 36)
	warn.add_theme_color_override("font_color", Color(0.6, 0.08, 0.06))
	warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(warn)

	var msg := Label.new()
	msg.text = "This will permanently erase all your wins, losses, and combos. Cannot be undone."
	msg.add_theme_font_size_override("font_size", 28)
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
	cancel_btn.add_theme_font_size_override("font_size", 32)
	_style_secondary(cancel_btn)
	cancel_btn.pressed.connect(func() -> void:
		scrim2.queue_free()
		box.queue_free())
	btns.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = "Yes, reset"
	confirm_btn.custom_minimum_size = Vector2(180, 56)
	confirm_btn.add_theme_font_size_override("font_size", 32)
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

# ---- Profile helpers --------------------------------------------------------

func _get_username() -> String:
	for n in get_tree().get_nodes_in_group("active_account"):
		if n.has_meta("username"):
			return String(n.get_meta("username"))
	return ""

func _load_profile() -> Dictionary:
	if not FileAccess.file_exists(_PROFILE_PATH):
		return {}
	var f := FileAccess.open(_PROFILE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}

func _save_profile(data: Dictionary) -> void:
	var f := FileAccess.open(_PROFILE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()

func _is_avatar_unlocked(char_id: String, username: String) -> bool:
	if PurchaseStore.PURCHASABLE.has(char_id):
		return PurchaseStore.is_purchased(char_id)
	if char_id == "capy_brown":
		return StatsStore.is_brown_unlocked(username)
	return true

func _avatar_char_defs() -> Array:
	return [
		{"id": "capy_zoomer",   "label": "Zoomer",   "tint": Color(0.70, 0.55, 0.40)},
		{"id": "capy_chef",     "label": "Chef",     "tint": Color(0.95, 0.85, 0.70)},
		{"id": "capy_swamp",    "label": "Swamp",    "tint": Color(0.52, 0.44, 0.30)},
		{"id": "capy_brown",    "label": "Brown",    "tint": Color(0.85, 0.70, 0.50)},
		{"id": "capy_wizard",   "label": "Wizard",   "tint": Color(0.58, 0.35, 0.82)},
		{"id": "capy_archer",   "label": "Archer",   "tint": Color(0.38, 0.62, 0.30)},
		{"id": "capy_assassin", "label": "Assassin", "tint": Color(0.22, 0.22, 0.30)},
	]

func _mk_av_style(tint: Color, selected: bool, locked: bool, radius: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = tint.darkened(0.40) if locked else tint
	s.corner_radius_top_left    = int(radius)
	s.corner_radius_top_right   = int(radius)
	s.corner_radius_bottom_left = int(radius)
	s.corner_radius_bottom_right = int(radius)
	if selected:
		s.border_color = Color(1.0, 0.84, 0.12)
		s.set_border_width_all(6)
	elif locked:
		s.border_color = Color(0.35, 0.35, 0.35, 0.40)
		s.set_border_width_all(2)
	return s

func _show_profile_panel() -> void:
	var view := get_viewport().get_visible_rect().size
	var username := _get_username()
	var profile := _load_profile()
	var cur_avatar: String = profile.get("avatar", "capy_zoomer") as String

	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.55)
	scrim.size = view
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(scrim)

	var pw: float = min(view.x - 60.0, 720.0)
	var ph: float = min(view.y - 100.0, 1400.0)
	var panel := Panel.new()
	panel.size = Vector2(pw, ph)
	panel.position = Vector2((view.x - pw) * 0.5, (view.y - ph) * 0.5)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.99, 0.96, 0.88)
	ps.corner_radius_top_left    = 18; ps.corner_radius_top_right   = 18
	ps.corner_radius_bottom_left = 18; ps.corner_radius_bottom_right = 18
	ps.border_color = Color(0.35, 0.18, 0.08); ps.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24, 24)
	scroll.size = Vector2(pw - 48.0, ph - 48.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 20)
	scroll.add_child(col)

	# Title
	var title := Label.new()
	title.text = "My Profile"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.35, 0.18, 0.08))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	if not username.is_empty():
		var acc_lbl := Label.new()
		acc_lbl.text = "Account: " + username
		acc_lbl.add_theme_font_size_override("font_size", 28)
		acc_lbl.add_theme_color_override("font_color", Color(0.50, 0.36, 0.20))
		acc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(acc_lbl)

	# Large avatar preview (tap to change via the grid below)
	var av_def_list := _avatar_char_defs()
	var cur_av_tint := Color(0.70, 0.55, 0.40)
	for _pd in av_def_list:
		if (_pd["id"] as String) == cur_avatar:
			cur_av_tint = _pd["tint"] as Color
			break
	var preview_center := CenterContainer.new()
	col.add_child(preview_center)
	var preview_panel := Panel.new()
	preview_panel.custom_minimum_size = Vector2(130, 130)
	preview_panel.add_theme_stylebox_override("panel", _mk_av_style(cur_av_tint, false, false, 65.0))
	preview_center.add_child(preview_panel)
	var preview_tr := TextureRect.new()
	preview_tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_tr.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var _init_ptex := load("res://assets/characters/" + cur_avatar + ".png") as Texture2D
	if _init_ptex:
		preview_tr.texture = _init_ptex
	preview_panel.add_child(preview_tr)

	# Display name
	var dn_lbl := Label.new()
	dn_lbl.text = "Display Name"
	dn_lbl.add_theme_font_size_override("font_size", 32)
	dn_lbl.add_theme_color_override("font_color", Color(0.35, 0.22, 0.10))
	col.add_child(dn_lbl)

	var dn_row := HBoxContainer.new()
	dn_row.add_theme_constant_override("separation", 12)
	col.add_child(dn_row)

	var dn_edit := LineEdit.new()
	dn_edit.text = profile.get("display_name", username) as String
	dn_edit.placeholder_text = "Enter display name..."
	dn_edit.add_theme_font_size_override("font_size", 32)
	dn_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dn_edit.custom_minimum_size = Vector2(0, 72)
	var dn_bg := StyleBoxFlat.new()
	dn_bg.bg_color = Color(1.0, 1.0, 0.96)
	dn_bg.corner_radius_top_left = 14; dn_bg.corner_radius_top_right = 14
	dn_bg.corner_radius_bottom_left = 14; dn_bg.corner_radius_bottom_right = 14
	dn_bg.border_color = Color(0.65, 0.48, 0.28); dn_bg.set_border_width_all(2)
	dn_bg.content_margin_left = 16; dn_bg.content_margin_right = 16
	dn_bg.content_margin_top = 8; dn_bg.content_margin_bottom = 8
	dn_edit.add_theme_stylebox_override("normal", dn_bg)
	dn_edit.add_theme_stylebox_override("focus", dn_bg)
	dn_edit.add_theme_color_override("font_color", Color(0.15, 0.08, 0.02))
	dn_edit.add_theme_color_override("font_selected_color", Color(1.0, 0.96, 0.86))
	dn_edit.add_theme_color_override("font_placeholder_color", Color(0.36, 0.24, 0.12))
	dn_edit.add_theme_color_override("caret_color", Color(0.15, 0.08, 0.02))
	dn_edit.add_theme_color_override("selection_color", Color(0.55, 0.36, 0.12, 0.75))
	dn_row.add_child(dn_edit)

	var save_name_btn := Button.new()
	save_name_btn.text = "Save"
	save_name_btn.add_theme_font_size_override("font_size", 30)
	save_name_btn.custom_minimum_size = Vector2(120, 72)
	_style_primary(save_name_btn)
	dn_row.add_child(save_name_btn)

	var saved_lbl := Label.new()
	saved_lbl.add_theme_font_size_override("font_size", 26)
	saved_lbl.add_theme_color_override("font_color", Color(0.20, 0.55, 0.20))
	saved_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(saved_lbl)

	save_name_btn.pressed.connect(func() -> void:
		var new_name := dn_edit.text.strip_edges()
		if new_name.is_empty():
			return
		profile["display_name"] = new_name
		_save_profile(profile)
		display_name_changed.emit(new_name)
		LeaderboardClient.submit_stats(self, username, new_name)
		saved_lbl.text = "Name saved!"
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			if is_instance_valid(saved_lbl):
				saved_lbl.text = ""))

	# Avatar picker
	var av_lbl := Label.new()
	av_lbl.text = "Choose Avatar"
	av_lbl.add_theme_font_size_override("font_size", 34)
	av_lbl.add_theme_color_override("font_color", Color(0.35, 0.22, 0.10))
	col.add_child(av_lbl)

	var avail_w: float = pw - 48.0
	var col_count: int = 4 if avail_w >= 400.0 else 3
	var gap: float = 10.0
	var circ_size: float = clamp(
		(avail_w - gap * (col_count - 1)) / float(col_count), 90.0, 170.0)
	var circ_r: float = circ_size * 0.5

	var grid := GridContainer.new()
	grid.columns = col_count
	grid.add_theme_constant_override("h_separation", int(gap))
	grid.add_theme_constant_override("v_separation", int(gap))
	col.add_child(grid)

	var defs := _avatar_char_defs()
	var av_btns: Array = []

	var avatar_box := [cur_avatar]  # Array wrapper so lambda can mutate the selection

	var update_selection := func(new_id: String) -> void:
		avatar_box[0] = new_id
		profile["avatar"] = new_id
		_save_profile(profile)
		for _upd in defs:
			if (_upd["id"] as String) == new_id:
				preview_panel.add_theme_stylebox_override("panel", _mk_av_style(_upd["tint"] as Color, false, false, 65.0))
				break
		var _ptex := load("res://assets/characters/" + new_id + ".png") as Texture2D
		if _ptex and is_instance_valid(preview_tr):
			preview_tr.texture = _ptex
		for i in av_btns.size():
			var inf: Dictionary = defs[i]
			var cid2: String  = inf["id"]   as String
			var tint2: Color  = inf["tint"] as Color
			var lock2: bool   = not _is_avatar_unlocked(cid2, username)
			var s2 := _mk_av_style(tint2, cid2 == avatar_box[0], lock2, circ_r)
			var b2 := av_btns[i] as Button
			b2.add_theme_stylebox_override("normal",  s2)
			b2.add_theme_stylebox_override("hover",   s2)
			b2.add_theme_stylebox_override("pressed", s2)

	for inf in defs:
		var cid:      String = inf["id"]    as String
		var clabel:   String = inf["label"] as String
		var ctint:    Color  = inf["tint"]  as Color
		var unlocked: bool   = _is_avatar_unlocked(cid, username)
		var is_sel:   bool   = cid == cur_avatar

		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 6)
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var avbtn := Button.new()
		avbtn.custom_minimum_size = Vector2(circ_size, circ_size)
		avbtn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		avbtn.focus_mode = Control.FOCUS_NONE
		var av_s := _mk_av_style(ctint, is_sel, not unlocked, circ_r)
		avbtn.add_theme_stylebox_override("normal",  av_s)
		avbtn.add_theme_stylebox_override("hover",   av_s)
		avbtn.add_theme_stylebox_override("pressed", av_s)

		var portrait_tex := load("res://assets/characters/" + cid + ".png") as Texture2D
		if portrait_tex:
			var portrait_rect := TextureRect.new()
			portrait_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			portrait_rect.texture = portrait_tex
			portrait_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if not unlocked:
				portrait_rect.modulate = Color(0.45, 0.40, 0.42, 0.85)
			avbtn.add_child(portrait_rect)
		if not unlocked:
			var lock_lbl := Label.new()
			lock_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			lock_lbl.text = "?"
			lock_lbl.add_theme_font_size_override("font_size", 40)
			lock_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.90))
			lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			avbtn.add_child(lock_lbl)

		var name_lbl := Label.new()
		name_lbl.text = clabel
		name_lbl.add_theme_font_size_override("font_size", 26)
		name_lbl.add_theme_color_override("font_color",
			Color(0.15, 0.08, 0.02) if unlocked else Color(0.50, 0.40, 0.30))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		cell.add_child(avbtn)
		cell.add_child(name_lbl)
		grid.add_child(cell)
		av_btns.append(avbtn)

		if unlocked:
			var cid_cap := cid
			avbtn.pressed.connect(func() -> void: update_selection.call(cid_cap))

	var sep_p := HSeparator.new()
	col.add_child(sep_p)

	var logout_btn := Button.new()
	logout_btn.text = "Log out / switch account"
	logout_btn.add_theme_font_size_override("font_size", 36)
	logout_btn.custom_minimum_size = Vector2(0, 80)
	_style_danger(logout_btn)
	logout_btn.pressed.connect(func() -> void: logout_requested.emit())
	col.add_child(logout_btn)

	var close_p := Button.new()
	close_p.text = "Done"
	close_p.add_theme_font_size_override("font_size", 40)
	close_p.custom_minimum_size = Vector2(0, 88)
	_style_primary(close_p)
	close_p.pressed.connect(func() -> void:
		scrim.queue_free()
		panel.queue_free())
	col.add_child(close_p)

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
