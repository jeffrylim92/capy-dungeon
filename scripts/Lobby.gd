extends Node2D

## Main lobby: shown right after login. Player can start a match, view per
## character stats, change settings, or sign out / switch account.

signal start_game_requested
signal history_requested
signal logout_requested

const SETTINGS_SCENE := preload("res://scenes/Settings.tscn")

var account: Dictionary = {}

var _settings_overlay: Node = null
var _welcome_lbl: Label = null
var _lobby_avatar_rect: TextureRect = null

func _ready() -> void:
	SettingsStore.apply(get_tree())
	add_to_group("active_account")
	set_meta("username", String(account.get("username", "")))
	_build_ui()

func _build_ui() -> void:
	var view := get_viewport_rect().size

	var bg := TextureRect.new()
	var bg_tex := load("res://assets/backgrounds/bg_lobby.png") as Texture2D
	if bg_tex:
		bg.texture = bg_tex
	else:
		bg.set_script(null)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = view
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var layout := Control.new()
	layout.position = Vector2.ZERO
	layout.size = view
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layout)

	var center := CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = view
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(view.x - 80.0, 0.0)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.98, 0.95, 0.88, 0.55)
	card_style.border_color = Color(0.75, 0.55, 0.20, 0.88)
	card_style.set_border_width_all(2)
	card_style.corner_radius_top_left = 28
	card_style.corner_radius_top_right = 28
	card_style.corner_radius_bottom_right = 28
	card_style.corner_radius_bottom_left = 28
	card_style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	card_style.shadow_size = 18
	card_style.shadow_offset = Vector2(0, 6)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 48)
	inner.add_theme_constant_override("margin_right", 48)
	inner.add_theme_constant_override("margin_top", 48)
	inner.add_theme_constant_override("margin_bottom", 48)
	card.add_child(inner)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 22)
	inner.add_child(root)

	var title := Label.new()
	title.text = "Capy Dungeon"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.22, 0.10, 0.02))
	title.add_theme_color_override("font_outline_color", Color(1.0, 0.90, 0.60, 0.55))
	title.add_theme_constant_override("outline_size", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var _prof := _load_profile()
	var _av_id: String = _prof.get("avatar", "capy_zoomer") as String
	var _av_tex := load("res://assets/characters/" + _av_id + ".png") as Texture2D
	if _av_tex:
		var av_center := CenterContainer.new()
		_lobby_avatar_rect = TextureRect.new()
		_lobby_avatar_rect.texture = _av_tex
		_lobby_avatar_rect.custom_minimum_size = Vector2(96, 96)
		_lobby_avatar_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		_lobby_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		av_center.add_child(_lobby_avatar_rect)
		root.add_child(av_center)

	var welcome := Label.new()
	var _base_name: String = String(account.get("display_name", account.get("username", "trainer")))
	var display_name: String = _prof.get("display_name", _base_name) as String
	welcome.text = "Welcome back, %s" % display_name
	welcome.add_theme_font_size_override("font_size", 36)
	welcome.add_theme_color_override("font_color", Color(0.28, 0.14, 0.04))
	welcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(welcome)
	_welcome_lbl = welcome

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	root.add_child(spacer)

	var play_btn := _make_button("PLAY", 44, Vector2(0, 140), true)
	play_btn.pressed.connect(func() -> void: start_game_requested.emit())
	root.add_child(play_btn)

	var history_btn := _make_button("History", 32, Vector2(0, 90))
	history_btn.pressed.connect(func() -> void: history_requested.emit())
	root.add_child(history_btn)

	var settings_btn := _make_button("Settings", 32, Vector2(0, 90))
	settings_btn.pressed.connect(_on_settings_pressed)
	root.add_child(settings_btn)

func _make_button(text: String, font_size: int, min_size: Vector2, is_primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.custom_minimum_size = min_size
	if is_primary:
		_style_primary(b)
	else:
		_style_secondary(b)
	return b

func _load_profile() -> Dictionary:
	if not FileAccess.file_exists("user://profile.json"):
		return {}
	var f := FileAccess.open("user://profile.json", FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}

func _refresh_lobby_header() -> void:
	var prof := _load_profile()
	var base_name: String = String(account.get("display_name", account.get("username", "trainer")))
	var new_name: String = prof.get("display_name", base_name) as String
	if is_instance_valid(_welcome_lbl):
		_welcome_lbl.text = "Welcome back, %s" % new_name
	var new_av: String = prof.get("avatar", "capy_zoomer") as String
	var ntex := load("res://assets/characters/" + new_av + ".png") as Texture2D
	if ntex and is_instance_valid(_lobby_avatar_rect):
		_lobby_avatar_rect.texture = ntex

func _on_settings_pressed() -> void:
	if _settings_overlay != null and is_instance_valid(_settings_overlay):
		return
	_settings_overlay = SETTINGS_SCENE.instantiate()
	_settings_overlay.logout_requested.connect(func() -> void:
		_close_settings()
		logout_requested.emit())
	_settings_overlay.display_name_changed.connect(func(new_name: String) -> void:
		if is_instance_valid(_welcome_lbl):
			_welcome_lbl.text = "Welcome back, %s" % new_name)
	_settings_overlay.closed.connect(func() -> void:
		_refresh_lobby_header()
		_close_settings())
	add_child(_settings_overlay)

func _close_settings() -> void:
	if _settings_overlay != null and is_instance_valid(_settings_overlay):
		_settings_overlay.queue_free()
	_settings_overlay = null

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
