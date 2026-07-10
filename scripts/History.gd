extends Node2D

## Match history and global leaderboard.

signal back_requested

const HISTORY_BG := "res://assets/backgrounds/bg_history.png"
const UI_ICON_DIR := "res://assets/icons/"

const PORTRAIT_DIR  := "res://assets/characters/"
const PORTRAIT_EXTS: Array[String] = [".png", ".webp", ".jpg", ".svg"]

const CHAR_ORDER: Array[String] = [
	"capy_zoomer", "capy_chef", "capy_swamp",
	"capy_brown",
	"capy_wizard", "capy_archer", "capy_assassin",
]

var account: Dictionary = {}

var _tab_panels:   Array[Control] = []
var _tab_buttons:  Array[Button]  = []
var _global_panel: Control        = null
var _global_loaded: bool          = false
var _global_mode: String          = "kills"
var _global_kills_done: bool      = false
var _global_survive_done: bool    = false
var _global_wave_done: bool       = false
var _global_kill_user_entry: Variant = null
var _global_survive_user_entry: Variant = null
var _global_wave_user_entry: Variant = null
var _global_kills_failed: bool    = false
var _global_survive_failed: bool  = false
var _global_wave_failed: bool     = false
var _global_kills_entries: Array = []
var _global_survive_entries: Array = []
var _global_wave_entries: Array = []
var _history_scroll: ScrollContainer = null
var _global_list_scroll: ScrollContainer = null
var _active_swipe_scroll: ScrollContainer = null

const TAB_DEFS: Array[Dictionary] = [
	{"title": "History", "icon": "icon_run.png"},
	{"title": "Global", "icon": "icon_time.png"},
]

func _cloud_username_for_history() -> String:
	var social_email: String = String(account.get("social_email", "")).strip_edges().to_lower()
	if not social_email.is_empty():
		return social_email
	return String(account.get("username", "")).strip_edges().to_lower()

func _ready() -> void:
	SettingsStore.apply(get_tree())
	_build_ui()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_active_swipe_scroll = _scroll_for_point(touch.position)
		else:
			_active_swipe_scroll = null
		return
	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _active_swipe_scroll != null and is_instance_valid(_active_swipe_scroll):
			_active_swipe_scroll.scroll_vertical = maxi(0, _active_swipe_scroll.scroll_vertical - int(round(drag.relative.y)))
			get_viewport().set_input_as_handled()

func _scroll_for_point(point: Vector2) -> ScrollContainer:
	if _history_scroll != null and is_instance_valid(_history_scroll) and _history_scroll.visible and _history_scroll.get_global_rect().has_point(point):
		return _history_scroll
	if _global_list_scroll != null and is_instance_valid(_global_list_scroll) and _global_list_scroll.visible and _global_list_scroll.get_global_rect().has_point(point):
		return _global_list_scroll
	return null

func _build_ui() -> void:
	var view := get_viewport_rect().size

	# ── Background ─────────────────────────────────────────────────────────────
	var bg_tex := _load_ui_texture(HISTORY_BG)
	var bg := TextureRect.new()
	bg.texture      = bg_tex
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size         = view
	bg.position     = Vector2.ZERO
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var veil := ColorRect.new()
	veil.color = Color(0.05, 0.04, 0.03, 0.24)
	veil.size = view
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	# ── Title ──────────────────────────────────────────────────────────────────
	var title := Label.new()
	title.text = "History"
	title.add_theme_font_size_override("font_size", 66)
	title.add_theme_color_override("font_color", Color(1.0, 0.96, 0.86))
	title.add_theme_color_override("font_outline_color", Color(0.20, 0.11, 0.04, 0.95))
	title.add_theme_constant_override("outline_size", 8)
	title.position = Vector2(0, 76)
	title.size     = Vector2(view.x, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var display_name: String = String(account.get("display_name", account.get("username", "trainer")))
	var subtitle := Label.new()
	subtitle.text = "%s · all matches" % display_name
	subtitle.add_theme_font_size_override("font_size", 34)
	subtitle.add_theme_color_override("font_color", Color(0.92, 0.80, 0.56))
	subtitle.add_theme_color_override("font_outline_color", Color(0.16, 0.08, 0.03, 0.85))
	subtitle.add_theme_constant_override("outline_size", 6)
	subtitle.position = Vector2(0, 154)
	subtitle.size     = Vector2(view.x, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

	# ── Tab bar ────────────────────────────────────────────────────────────────
	var tab_bar := HBoxContainer.new()
	tab_bar.position = Vector2(44, 212)
	tab_bar.size     = Vector2(view.x - 88.0, 78)
	tab_bar.add_theme_constant_override("separation", 12)
	tab_bar.z_index = 20
	add_child(tab_bar)

	for i in TAB_DEFS.size():
		var tab_def: Dictionary = TAB_DEFS[i]
		var btn := Button.new()
		btn.text = String(tab_def.get("title", "Tab"))
		btn.add_theme_font_size_override("font_size", 28)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size   = Vector2(0, 78)
		btn.focus_mode            = Control.FOCUS_NONE
		_tab_buttons.append(btn)
		tab_bar.add_child(btn)
		btn.pressed.connect(_switch_tab.bind(i))

	# ── Content panels ─────────────────────────────────────────────────────────
	var content_y: float = 282.0
	var content_h: float = view.y - content_y - 130.0
	var content_w: float = view.x - 80.0

	var content_frame := PanelContainer.new()
	content_frame.position = Vector2(34, 318)
	content_frame.size = Vector2(view.x - 68.0, view.y - 476.0)
	content_frame.z_index = 8
	content_frame.clip_contents = true
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.13, 0.09, 0.05, 0.94)
	frame_style.corner_radius_top_left = 28
	frame_style.corner_radius_top_right = 28
	frame_style.corner_radius_bottom_right = 28
	frame_style.corner_radius_bottom_left = 28
	frame_style.border_color = Color(0.92, 0.72, 0.38, 0.72)
	frame_style.set_border_width_all(2)
	frame_style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	frame_style.shadow_size = 22
	frame_style.shadow_offset = Vector2(0, 8)
	frame_style.content_margin_left = 12
	frame_style.content_margin_right = 12
	frame_style.content_margin_top = 12
	frame_style.content_margin_bottom = 12
	content_frame.add_theme_stylebox_override("panel", frame_style)
	add_child(content_frame)

	var history_panel  := _build_history_panel(content_y, content_h, content_w)
	_global_panel       = _build_global_panel(content_y, content_h, content_w)

	_tab_panels = [history_panel, _global_panel]
	for p in _tab_panels:
		p.visible = false
		content_frame.add_child(p)

	_switch_tab(0)

	# ── Back button ────────────────────────────────────────────────────────────
	var back := Button.new()
	back.text = "Back"
	back.add_theme_font_size_override("font_size", 40)
	back.custom_minimum_size = Vector2(260, 88)
	back.size     = Vector2(260, 88)
	back.position = Vector2(60, view.y - 116.0)
	back.focus_mode = Control.FOCUS_NONE
	_style_secondary(back)
	back.pressed.connect(func() -> void: back_requested.emit())
	add_child(back)

# ── Tab switching ──────────────────────────────────────────────────────────────

func _switch_tab(idx: int) -> void:
	for i in _tab_panels.size():
		_tab_panels[i].visible = (i == idx)
	for i in _tab_buttons.size():
		_style_tab_btn(_tab_buttons[i], i == idx)
	if idx == 1 and not _global_loaded:
		_global_loaded = true
		_fetch_global_rankings()

func _style_tab_btn(btn: Button, active: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.98, 0.89, 0.72, 0.96) if active else Color(0.16, 0.10, 0.06, 0.76)
	s.corner_radius_top_left     = 18
	s.corner_radius_top_right    = 18
	s.corner_radius_bottom_right = 18
	s.corner_radius_bottom_left  = 18
	s.border_color = Color(0.88, 0.60, 0.24, 0.95) if active else Color(0.84, 0.65, 0.28, 0.38)
	s.set_border_width_all(3 if active else 2)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 3)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal",  s)
	btn.add_theme_stylebox_override("hover",   s)
	btn.add_theme_stylebox_override("pressed", s)
	var fg := Color(0.18, 0.09, 0.03) if active else Color(0.93, 0.85, 0.70)
	btn.add_theme_color_override("font_color",         fg)
	btn.add_theme_color_override("font_hover_color",   fg)
	btn.add_theme_color_override("font_pressed_color", fg)
	btn.add_theme_color_override("font_focus_color",   fg)

func _load_ui_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

# ── History panel (existing per-character cards) ───────────────────────────────

func _build_history_panel(y: float, h: float, w: float) -> Control:
	var panel := Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	vbox.add_child(_build_summary_label())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_history_scroll = scroll
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)

	var username := String(account.get("username", ""))
	var characters := CharacterLoader.load_all()
	if characters.is_empty():
		var msg := Label.new()
		msg.text = "No characters available."
		msg.add_theme_font_size_override("font_size", 32)
		msg.add_theme_color_override("font_color", Color(0.78, 0.70, 0.58))
		list.add_child(msg)
	else:
		characters.sort_custom(func(a: CharacterData, b: CharacterData) -> bool:
			var ia: int = CHAR_ORDER.find(String(a.id))
			var ib: int = CHAR_ORDER.find(String(b.id))
			if ia < 0: ia = 999
			if ib < 0: ib = 999
			return ia < ib)
		for c in characters:
			list.add_child(_make_char_card(c, StatsStore.get_for(username, String(c.id)), w))
	return panel

# ── Global ranking panel ───────────────────────────────────────────────────────

func _build_global_panel(y: float, h: float, w: float) -> Control:
	var panel := Control.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)

	var mode_row := HBoxContainer.new()
	mode_row.name = "GlobalModeRow"
	mode_row.add_theme_constant_override("separation", 12)
	mode_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(mode_row)

	var kill_btn := Button.new()
	kill_btn.name = "ModeKillBtn"
	kill_btn.text = "Top Kill"
	kill_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kill_btn.custom_minimum_size = Vector2(0, 72)
	kill_btn.add_theme_font_size_override("font_size", 30)
	kill_btn.focus_mode = Control.FOCUS_NONE
	kill_btn.pressed.connect(func() -> void: _set_global_mode("kills"))
	mode_row.add_child(kill_btn)

	var survive_btn := Button.new()
	survive_btn.name = "ModeSurviveBtn"
	survive_btn.text = "Top Survival"
	survive_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	survive_btn.custom_minimum_size = Vector2(0, 72)
	survive_btn.add_theme_font_size_override("font_size", 30)
	survive_btn.focus_mode = Control.FOCUS_NONE
	survive_btn.pressed.connect(func() -> void: _set_global_mode("survive"))
	mode_row.add_child(survive_btn)

	var wave_btn := Button.new()
	wave_btn.name = "ModeWaveBtn"
	wave_btn.text = "Top Wave"
	wave_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wave_btn.custom_minimum_size = Vector2(0, 72)
	wave_btn.add_theme_font_size_override("font_size", 30)
	wave_btn.focus_mode = Control.FOCUS_NONE
	wave_btn.pressed.connect(func() -> void: _set_global_mode("wave"))
	mode_row.add_child(wave_btn)

	var header := Label.new()
	header.name = "GlobalHeader"
	header.text = "TOP KILL LEADERBOARD"
	header.add_theme_font_size_override("font_size", 36)
	header.add_theme_color_override("font_color", Color(0.97, 0.86, 0.52))
	header.add_theme_color_override("font_outline_color", Color(0.18, 0.10, 0.04, 0.92))
	header.add_theme_constant_override("outline_size", 4)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(header)

	var leaderboard_frame := PanelContainer.new()
	leaderboard_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leaderboard_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.15, 0.10, 0.06, 0.92)
	frame_style.corner_radius_top_left = 18
	frame_style.corner_radius_top_right = 18
	frame_style.corner_radius_bottom_right = 18
	frame_style.corner_radius_bottom_left = 18
	frame_style.border_color = Color(0.88, 0.64, 0.30, 0.56)
	frame_style.set_border_width_all(2)
	frame_style.content_margin_left = 10
	frame_style.content_margin_right = 10
	frame_style.content_margin_top = 10
	frame_style.content_margin_bottom = 10
	leaderboard_frame.add_theme_stylebox_override("panel", frame_style)
	root.add_child(leaderboard_frame)

	var list_scroll := ScrollContainer.new()
	list_scroll.name = "GlobalListScroll"
	list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_global_list_scroll = list_scroll
	leaderboard_frame.add_child(list_scroll)

	var list := VBoxContainer.new()
	list.name = "GlobalList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	list_scroll.add_child(list)

	var pinned := PanelContainer.new()
	pinned.name = "GlobalPinned"
	pinned.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pinned.custom_minimum_size = Vector2(0, 230)
	var pinned_style := StyleBoxFlat.new()
	pinned_style.bg_color = Color(0.22, 0.14, 0.32, 0.94)
	pinned_style.corner_radius_top_left = 18
	pinned_style.corner_radius_top_right = 18
	pinned_style.corner_radius_bottom_right = 18
	pinned_style.corner_radius_bottom_left = 18
	pinned_style.border_color = Color(0.86, 0.66, 0.96, 0.80)
	pinned_style.set_border_width_all(2)
	pinned_style.content_margin_left = 14
	pinned_style.content_margin_right = 14
	pinned_style.content_margin_top = 12
	pinned_style.content_margin_bottom = 12
	pinned.add_theme_stylebox_override("panel", pinned_style)
	root.add_child(pinned)

	_refresh_global_mode_buttons()
	_refresh_global_view()

	return panel

func _fetch_global_rankings() -> void:
	_global_kills_done = false
	_global_survive_done = false
	_global_wave_done = false
	_global_kill_user_entry = null
	_global_survive_user_entry = null
	_global_wave_user_entry = null
	_global_kills_failed = false
	_global_survive_failed = false
	_global_wave_failed = false
	_global_kills_entries = []
	_global_survive_entries = []
	_global_wave_entries = []
	_refresh_global_view()

	var cloud_username: String = _cloud_username_for_history()
	LeaderboardClient.fetch_kills_with_user(self, cloud_username, func(payload: Dictionary) -> void:
		var entries_for_match: Array = payload.get("entries", []) as Array
		var ok: bool = payload.get("ok", false) as bool
		_global_kills_failed = not ok
		_global_kills_entries = entries_for_match
		var resolved_entry: Variant = _best_rank_entry(payload.get("user_entry", null), entries_for_match, false, _global_kills_entries)
		var resolved_rank: int = int((resolved_entry as Dictionary).get("rank", 0)) if typeof(resolved_entry) == TYPE_DICTIONARY else 0
		var local_username: String = String(account.get("username", "")).strip_edges().to_lower()
		if resolved_rank <= 0 and not local_username.is_empty() and local_username != cloud_username:
			LeaderboardClient.fetch_kills_with_user(self, local_username, func(payload2: Dictionary) -> void:
				_global_kills_done = true
				_global_kill_user_entry = _best_rank_entry(payload2.get("user_entry", null), entries_for_match, false, _global_kills_entries)
				_refresh_global_view()
			, LeaderboardClient.GLOBAL_LIMIT_ALL, "")
			return
		_global_kills_done = true
		_global_kill_user_entry = resolved_entry
		_refresh_global_view()
	, LeaderboardClient.GLOBAL_LIMIT_ALL, "")
	LeaderboardClient.fetch_survive_with_user(self, cloud_username, func(payload: Dictionary) -> void:
		var entries_for_match: Array = payload.get("entries", []) as Array
		var ok: bool = payload.get("ok", false) as bool
		_global_survive_failed = not ok
		_global_survive_entries = entries_for_match
		var resolved_entry: Variant = _best_rank_entry(payload.get("user_entry", null), entries_for_match, true, _global_survive_entries)
		var resolved_rank: int = int((resolved_entry as Dictionary).get("rank", 0)) if typeof(resolved_entry) == TYPE_DICTIONARY else 0
		var local_username: String = String(account.get("username", "")).strip_edges().to_lower()
		if resolved_rank <= 0 and not local_username.is_empty() and local_username != cloud_username:
			LeaderboardClient.fetch_survive_with_user(self, local_username, func(payload2: Dictionary) -> void:
				_global_survive_done = true
				_global_survive_user_entry = _best_rank_entry(payload2.get("user_entry", null), entries_for_match, true, _global_survive_entries)
				_refresh_global_view()
			, LeaderboardClient.GLOBAL_LIMIT_ALL, "")
			return
		_global_survive_done = true
		_global_survive_user_entry = resolved_entry
		_refresh_global_view()
	, LeaderboardClient.GLOBAL_LIMIT_ALL, "")
	LeaderboardClient.fetch_wave_with_user(self, cloud_username, func(payload: Dictionary) -> void:
		var entries_for_match: Array = payload.get("entries", []) as Array
		var ok: bool = payload.get("ok", false) as bool
		_global_wave_failed = not ok
		_global_wave_entries = entries_for_match
		var resolved_entry: Variant = _best_rank_entry(payload.get("user_entry", null), entries_for_match, false, _global_wave_entries)
		var resolved_rank: int = int((resolved_entry as Dictionary).get("rank", 0)) if typeof(resolved_entry) == TYPE_DICTIONARY else 0
		var local_username: String = String(account.get("username", "")).strip_edges().to_lower()
		if resolved_rank <= 0 and not local_username.is_empty() and local_username != cloud_username:
			LeaderboardClient.fetch_wave_with_user(self, local_username, func(payload2: Dictionary) -> void:
				_global_wave_done = true
				_global_wave_user_entry = _best_rank_entry(payload2.get("user_entry", null), entries_for_match, false, _global_wave_entries)
				_refresh_global_view()
			, LeaderboardClient.GLOBAL_LIMIT_ALL, "")
			return
		_global_wave_done = true
		_global_wave_user_entry = resolved_entry
		_refresh_global_view()
	, LeaderboardClient.GLOBAL_LIMIT_ALL, "")

func _set_global_mode(mode: String) -> void:
	if mode != "kills" and mode != "survive" and mode != "wave":
		return
	if _global_mode == mode:
		return
	_global_mode = mode
	_refresh_global_mode_buttons()
	_refresh_global_view()

func _refresh_global_mode_buttons() -> void:
	if _global_panel == null:
		return
	var kill_btn: Button = _global_panel.get_node_or_null("GlobalModeRow/ModeKillBtn") as Button
	var survive_btn: Button = _global_panel.get_node_or_null("GlobalModeRow/ModeSurviveBtn") as Button
	var wave_btn: Button = _global_panel.get_node_or_null("GlobalModeRow/ModeWaveBtn") as Button
	if kill_btn != null:
		_style_global_mode_btn(kill_btn, _global_mode == "kills")
	if survive_btn != null:
		_style_global_mode_btn(survive_btn, _global_mode == "survive")
	if wave_btn != null:
		_style_global_mode_btn(wave_btn, _global_mode == "wave")

func _style_global_mode_btn(btn: Button, active: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.70, 0.44, 0.12, 0.95) if active else Color(0.14, 0.10, 0.08, 0.90)
	s.corner_radius_top_left = 14
	s.corner_radius_top_right = 14
	s.corner_radius_bottom_right = 14
	s.corner_radius_bottom_left = 14
	s.border_color = Color(0.98, 0.76, 0.28, 0.95) if active else Color(0.72, 0.52, 0.24, 0.60)
	s.set_border_width_all(3 if active else 2)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover", s)
	btn.add_theme_stylebox_override("pressed", s)
	var fg := Color(1.0, 0.95, 0.82) if active else Color(0.86, 0.76, 0.62)
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_color_override("font_pressed_color", fg)

func _refresh_global_view() -> void:
	if _global_panel == null:
		return

	var header: Label = _global_panel.find_child("GlobalHeader", true, false) as Label
	var list: VBoxContainer = _global_panel.find_child("GlobalList", true, false) as VBoxContainer
	var pinned: PanelContainer = _global_panel.find_child("GlobalPinned", true, false) as PanelContainer
	if header == null or list == null or pinned == null:
		return

	for child in list.get_children():
		child.queue_free()
	for child in pinned.get_children():
		child.queue_free()

	var mode: String = _global_mode
	var is_survive: bool = mode == "survive"
	var is_wave: bool = mode == "wave"
	header.text = "TOP SURVIVAL LEADERBOARD" if is_survive else ("TOP WAVE LEADERBOARD" if is_wave else "TOP KILL LEADERBOARD")

	var loaded: bool = _global_survive_done if is_survive else (_global_wave_done if is_wave else _global_kills_done)
	var failed: bool = _global_survive_failed if is_survive else (_global_wave_failed if is_wave else _global_kills_failed)
	var entries: Array = _global_survive_entries if is_survive else (_global_wave_entries if is_wave else _global_kills_entries)
	var user_entry: Variant = _global_survive_user_entry if is_survive else (_global_wave_user_entry if is_wave else _global_kill_user_entry)

	if not loaded:
		list.add_child(_empty_hint("Loading global leaderboard..."))
	else:
		if failed and entries.is_empty():
			list.add_child(_empty_hint("Could not load global ranking. Please retry."))
			var retry := Button.new()
			retry.text = "↺  Retry"
			retry.add_theme_font_size_override("font_size", 30)
			retry.custom_minimum_size = Vector2(180, 60)
			retry.focus_mode = Control.FOCUS_NONE
			_style_retry(retry)
			retry.pressed.connect(func() -> void:
				_global_loaded = false
				_switch_tab(1)
			)
			list.add_child(retry)
		elif entries.is_empty():
			list.add_child(_empty_hint("No global records yet."))
		else:
			var cap: int = mini(20, entries.size())
			for i in cap:
				var entry: Dictionary = entries[i] as Dictionary
				list.add_child(_global_rank_row(entry, mode))

	var pinned_root := VBoxContainer.new()
	pinned_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pinned_root.add_theme_constant_override("separation", 10)
	pinned.add_child(pinned_root)

	var pinned_title := Label.new()
	pinned_title.text = "YOUR POSITION"
	pinned_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pinned_title.add_theme_font_size_override("font_size", 36)
	pinned_title.add_theme_color_override("font_color", Color(0.98, 0.84, 0.42))
	pinned_root.add_child(pinned_title)

	if typeof(user_entry) != TYPE_DICTIONARY:
		pinned_root.add_child(_empty_hint("Play more runs to place on the global rank."))
		return

	var user: Dictionary = user_entry as Dictionary
	var user_rank: int = int(user.get("rank", 0))
	var user_char: String = String(user.get("character", ""))
	var user_name: String = String(user.get("display_name", account.get("display_name", account.get("username", "You"))))
	var user_value: float = float(user.get("value", 0.0))

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	pinned_root.add_child(row)

	var rank_badge := Label.new()
	rank_badge.text = "%d" % user_rank if user_rank > 0 else "—"
	rank_badge.custom_minimum_size = Vector2(120, 96)
	rank_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank_badge.add_theme_font_size_override("font_size", 54)
	rank_badge.add_theme_color_override("font_color", Color(0.99, 0.88, 0.54))
	row.add_child(rank_badge)

	if not user_char.is_empty():
		row.add_child(_make_portrait_panel(user_char, 92, Color(0.42, 0.28, 0.56)))

	var info_col := VBoxContainer.new()
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.add_theme_constant_override("separation", 2)
	row.add_child(info_col)

	var name_lbl := Label.new()
	name_lbl.text = user_name
	name_lbl.add_theme_font_size_override("font_size", 44)
	name_lbl.add_theme_color_override("font_color", Color(0.97, 0.92, 0.84))
	info_col.add_child(name_lbl)

	var value_lbl := Label.new()
	if is_survive:
		value_lbl.text = StatsStore.format_seconds(user_value)
	elif is_wave:
		value_lbl.text = "Wave %d" % int(round(user_value))
	else:
		value_lbl.text = "%d Kills" % int(user_value)
	value_lbl.add_theme_font_size_override("font_size", 50)
	value_lbl.add_theme_color_override("font_color", Color(0.98, 0.84, 0.42))
	info_col.add_child(value_lbl)

	var detail_btn := Button.new()
	detail_btn.text = "View Run Details"
	detail_btn.custom_minimum_size = Vector2(260, 56)
	detail_btn.add_theme_font_size_override("font_size", 28)
	_style_match_detail_btn(detail_btn)
	var detail_entry: Dictionary = _detail_entry_from_global_entry(user, mode)
	if detail_entry.is_empty():
		detail_btn.disabled = true
	else:
		detail_btn.pressed.connect(func() -> void: _show_match_detail_modal(detail_entry))
	row.add_child(detail_btn)

	var progress_row := HBoxContainer.new()
	progress_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_row.add_theme_constant_override("separation", 10)
	pinned_root.add_child(progress_row)

	progress_row.add_child(_global_progress_card(
		"To pass rank",
		_global_nearest_higher_text(user_rank, user_value, entries, mode)
	))
	progress_row.add_child(_global_progress_card(
		"To enter top 20",
		_global_top20_target_text(user_rank, user_value, entries, mode)
	))

func _global_progress_card(title: String, text: String) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.08, 0.15, 0.92)
	ps.corner_radius_top_left = 12
	ps.corner_radius_top_right = 12
	ps.corner_radius_bottom_right = 12
	ps.corner_radius_bottom_left = 12
	ps.border_color = Color(0.86, 0.64, 0.30, 0.50)
	ps.set_border_width_all(2)
	ps.content_margin_left = 10
	ps.content_margin_right = 10
	ps.content_margin_top = 8
	ps.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", ps)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	panel.add_child(col)

	var title_lbl := Label.new()
	title_lbl.text = title.to_upper()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color(0.98, 0.84, 0.42))
	col.add_child(title_lbl)

	var body_lbl := Label.new()
	body_lbl.text = text
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	body_lbl.add_theme_font_size_override("font_size", 34)
	body_lbl.add_theme_color_override("font_color", Color(0.96, 0.94, 0.88))
	col.add_child(body_lbl)

	return panel

func _global_nearest_higher_text(user_rank: int, user_value: float, entries: Array, mode: String) -> String:
	if user_rank <= 1:
		return "You are Rank 1"
	var higher: Dictionary = {}
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = entry as Dictionary
		if int(data.get("rank", 0)) == user_rank - 1:
			higher = data
			break
	if higher.is_empty():
		return "Need more runs to estimate"
	var higher_rank: int = int(higher.get("rank", 0))
	var higher_value: float = float(higher.get("value", 0.0))
	if mode == "survive":
		var diff_secs: float = max(0.1, higher_value - user_value + 1.0)
		return "Need +%s to pass Rank %d" % [StatsStore.format_seconds(diff_secs), higher_rank]
	if mode == "wave":
		var diff_wave: int = maxi(1, int(round(higher_value)) - int(round(user_value)) + 1)
		return "Need +%d wave%s to pass Rank %d" % [diff_wave, "s" if diff_wave != 1 else "", higher_rank]
	var diff_kills: int = maxi(1, int(higher_value) - int(user_value) + 1)
	return "Need +%d kills to pass Rank %d" % [diff_kills, higher_rank]

func _global_top20_target_text(user_rank: int, user_value: float, entries: Array, mode: String) -> String:
	if user_rank > 0 and user_rank <= 20:
		return "Already in Top 20"
	if entries.size() < 20:
		return "Top 20 has open slots"
	var threshold: Dictionary = entries[19] as Dictionary
	var threshold_value: float = float(threshold.get("value", 0.0))
	if mode == "survive":
		var diff_secs: float = max(0.1, threshold_value - user_value + 1.0)
		return "Need +%s to enter Top 20" % StatsStore.format_seconds(diff_secs)
	if mode == "wave":
		var diff_wave: int = maxi(1, int(round(threshold_value)) - int(round(user_value)) + 1)
		return "Need +%d wave%s to enter Top 20" % [diff_wave, "s" if diff_wave != 1 else ""]
	var diff_kills: int = maxi(1, int(threshold_value) - int(user_value) + 1)
	return "Need +%d kills to enter Top 20" % diff_kills

func _best_rank_entry(server_entry: Variant, entries: Array, is_survive: bool, fallback_entries: Array = []) -> Variant:
	var candidate: Variant = null
	if typeof(server_entry) == TYPE_DICTIONARY:
		candidate = server_entry
	else:
		var visible_entry: Variant = _matching_visible_rank_entry(entries)
		if typeof(visible_entry) == TYPE_DICTIONARY:
			candidate = visible_entry
		else:
			candidate = _local_best_rank_entry(is_survive)

	if typeof(candidate) != TYPE_DICTIONARY:
		return null

	var normalized: Dictionary = (candidate as Dictionary).duplicate(true)
	var rank: int = int(normalized.get("rank", 0))
	if rank <= 0:
		var inferred_rank: int = _infer_rank_for_entry(normalized, entries, is_survive)
		if inferred_rank <= 0 and not fallback_entries.is_empty():
			inferred_rank = _infer_rank_for_entry(normalized, fallback_entries, is_survive)
		if inferred_rank > 0:
			normalized["rank"] = inferred_rank
	return normalized

func _matching_visible_rank_entry(entries: Array) -> Variant:
	var username := String(account.get("username", "")).strip_edges().to_lower()
	var social_email := String(account.get("social_email", "")).strip_edges().to_lower()
	var cloud_username := _cloud_username_for_history()
	var display_name := String(account.get("display_name", username)).strip_edges().to_lower()
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = entry as Dictionary
		var entry_user := String(data.get("username", "")).strip_edges().to_lower()
		var entry_name := String(data.get("display_name", "")).strip_edges().to_lower()
		if not entry_user.is_empty() and (entry_user == cloud_username or entry_user == social_email or entry_user == username):
			return entry
		if not entry_name.is_empty() and (entry_name == display_name or entry_name == username or entry_name == cloud_username):
			return entry
	return null

func _infer_rank_for_entry(entry: Dictionary, entries: Array, is_survive: bool) -> int:
	if entries.is_empty():
		return 0

	var username := String(account.get("username", "")).strip_edges().to_lower()
	var social_email := String(account.get("social_email", "")).strip_edges().to_lower()
	var cloud_username := _cloud_username_for_history()
	var display_name := String(account.get("display_name", username)).strip_edges().to_lower()
	var target_char := String(entry.get("character", "")).strip_edges().to_lower()
	var target_value: float = float(entry.get("value", 0.0))

	for i in entries.size():
		var item: Variant = entries[i]
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = item as Dictionary
		var entry_user := String(data.get("username", "")).strip_edges().to_lower()
		var entry_name := String(data.get("display_name", "")).strip_edges().to_lower()
		var rank: int = int(data.get("rank", i + 1))
		if not entry_user.is_empty() and (entry_user == cloud_username or entry_user == social_email or entry_user == username):
			return rank
		if not entry_name.is_empty() and (entry_name == display_name or entry_name == username):
			return rank
		var value: float = float(data.get("value", 0.0))
		var char_id := String(data.get("character", "")).strip_edges().to_lower()
		if not target_char.is_empty() and char_id == target_char:
			if is_survive:
				if abs(value - target_value) < 0.001:
					return rank
			else:
				if int(value) == int(target_value):
					return rank
	return 0

func _local_best_rank_entry(is_survive: bool) -> Variant:
	var username := String(account.get("username", ""))
	if username.is_empty():
		return null
	var all: Dictionary = StatsStore.get_all_for_user(username)
	var best_value: float = 0.0
	var best_char: String = ""
	for char_id in all:
		var stats: Dictionary = all[char_id] as Dictionary
		var value: float = float(stats.get("best_survive_seconds", 0.0)) if is_survive else float(int(stats.get("total_kills", 0)))
		if value > best_value:
			best_value = value
			best_char = String(char_id)
	if best_value <= 0.0:
		return null
	return {
		"rank": 0,
		"display_name": String(account.get("display_name", account.get("username", ""))),
		"value": best_value,
		"character": best_char,
	}

func _style_retry(btn: Button) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.18, 0.12, 0.06, 0.92)
	s.corner_radius_top_left     = 16
	s.corner_radius_top_right    = 16
	s.corner_radius_bottom_right = 16
	s.corner_radius_bottom_left  = 16
	s.border_color = Color(0.92, 0.70, 0.32, 0.55)
	s.set_border_width_all(2)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.28, 0.18, 0.08, 0.95)
	btn.add_theme_stylebox_override("normal",  s)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", s)
	btn.add_theme_color_override("font_color",         Color(1.0, 0.94, 0.82))
	btn.add_theme_color_override("font_hover_color",   Color(1.0, 0.98, 0.90))
	btn.add_theme_color_override("font_pressed_color", Color(0.92, 0.84, 0.70))

func _style_match_detail_btn(btn: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.25, 0.14, 0.40, 0.96)
	n.corner_radius_top_left = 14
	n.corner_radius_top_right = 14
	n.corner_radius_bottom_right = 14
	n.corner_radius_bottom_left = 14
	n.border_color = Color(0.96, 0.70, 0.38, 0.92)
	n.set_border_width_all(3)
	n.shadow_color = Color(0.10, 0.04, 0.16, 0.36)
	n.shadow_size = 6
	n.shadow_offset = Vector2(0, 3)
	n.content_margin_left = 14
	n.content_margin_right = 14
	n.content_margin_top = 8
	n.content_margin_bottom = 8

	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.34, 0.18, 0.52, 0.98)
	h.border_color = Color(1.0, 0.80, 0.46, 0.98)

	var p := n.duplicate() as StyleBoxFlat
	p.bg_color = Color(0.18, 0.10, 0.30, 1.0)

	var d := n.duplicate() as StyleBoxFlat
	d.bg_color = Color(0.20, 0.18, 0.24, 0.74)
	d.border_color = Color(0.56, 0.50, 0.62, 0.62)

	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("disabled", d)
	btn.add_theme_color_override("font_color", Color(1.0, 0.93, 0.82))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.90))
	btn.add_theme_color_override("font_pressed_color", Color(0.94, 0.86, 0.72))
	btn.add_theme_color_override("font_disabled_color", Color(0.72, 0.68, 0.64))
	btn.focus_mode = Control.FOCUS_NONE

func _global_rank_row(entry: Dictionary, mode: String) -> Control:
	var is_survive: bool = mode == "survive"
	var is_wave: bool = mode == "wave"
	var rank: int       = int(entry.get("rank", 0))
	var player: String  = str(entry.get("display_name", "—"))
	var char_id: String = str(entry.get("character", ""))
	var value_text: String
	if is_survive:
		value_text = StatsStore.format_seconds(float(entry.get("value", 0.0)))
	elif is_wave:
		value_text = "Wave %d" % int(round(float(entry.get("value", 0.0))))
	else:
		value_text = str(int(entry.get("value", 0))) + " Kills"
	var value_color := Color(0.50, 0.88, 0.62) if is_survive else (Color(0.58, 0.82, 0.98) if is_wave else Color(0.95, 0.72, 0.20))

	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.20, 0.12, 0.06, 0.90)
	cs.corner_radius_top_left     = 18
	cs.corner_radius_top_right    = 18
	cs.corner_radius_bottom_right = 18
	cs.corner_radius_bottom_left  = 18
	cs.border_color  = Color(0.90, 0.66, 0.28, 0.48)
	cs.set_border_width_all(2)
	cs.shadow_color  = Color(0.0, 0.0, 0.0, 0.34)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(hbox)

	var rank_lbl := Label.new()
	rank_lbl.text = str(rank)
	rank_lbl.add_theme_font_size_override("font_size", 40)
	rank_lbl.add_theme_color_override("font_color",
		Color(0.95, 0.78, 0.25) if rank == 1 else
		(Color(0.75, 0.75, 0.78) if rank == 2 else
		(Color(0.82, 0.52, 0.22) if rank == 3 else Color(0.62, 0.60, 0.75))))
	rank_lbl.custom_minimum_size = Vector2(56, 0)
	rank_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(rank_lbl)

	hbox.add_child(_make_portrait_panel(char_id, 72, Color(0.28, 0.26, 0.38)))

	var name_lbl := Label.new()
	name_lbl.text = player
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 36)
	name_lbl.add_theme_color_override("font_color", Color(0.97, 0.94, 0.86))
	name_lbl.add_theme_color_override("font_outline_color", Color(0.10, 0.05, 0.02, 0.80))
	name_lbl.add_theme_constant_override("outline_size", 3)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(name_lbl)

	var val_lbl := Label.new()
	val_lbl.text = value_text
	val_lbl.custom_minimum_size = Vector2(180, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val_lbl.add_theme_font_size_override("font_size", 34)
	val_lbl.add_theme_color_override("font_color", value_color)
	hbox.add_child(val_lbl)

	var detail_btn := Button.new()
	detail_btn.text = "View Run Details"
	detail_btn.custom_minimum_size = Vector2(210, 54)
	detail_btn.add_theme_font_size_override("font_size", 26)
	_style_match_detail_btn(detail_btn)
	var detail_entry: Dictionary = _detail_entry_from_global_entry(entry, mode)
	if detail_entry.is_empty():
		detail_btn.disabled = true
	else:
		detail_btn.pressed.connect(func() -> void: _show_match_detail_modal(detail_entry))
	hbox.add_child(detail_btn)

	return card

# ── Shared helpers ─────────────────────────────────────────────────────────────

func _make_portrait_panel(char_id: String, size: int, bg: Color) -> Panel:
	var p := Panel.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = bg
	ps.corner_radius_top_left     = 10
	ps.corner_radius_top_right    = 10
	ps.corner_radius_bottom_right = 10
	ps.corner_radius_bottom_left  = 10
	p.add_theme_stylebox_override("panel", ps)
	p.custom_minimum_size = Vector2(size, size)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.clip_contents = true
	var tex := _load_portrait(char_id)
	if tex != null:
		var portrait_rect := TextureRect.new()
		portrait_rect.texture      = tex
		portrait_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		portrait_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(portrait_rect)
	return p

func _section_header(text: String, accent: Color, icon: Texture2D = null) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.texture = icon
		icon_rect.custom_minimum_size = Vector2(30, 30)
		icon_rect.size = Vector2(30, 30)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_rect)

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_color", accent)
	lbl.add_theme_color_override("font_outline_color", Color(0.10, 0.06, 0.03, 0.85))
	lbl.add_theme_constant_override("outline_size", 4)
	row.add_child(lbl)
	return row

func _loading_label(section: String) -> Label:
	var lbl := Label.new()
	lbl.name = "Loading_" + section
	lbl.text = "Loading…"
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.50))
	return lbl

func _section_icon_row(icon: Texture2D, text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	if icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.texture = icon
		icon_rect.custom_minimum_size = Vector2(28, 28)
		icon_rect.size = Vector2(28, 28)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_rect)

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.94, 0.83, 0.66))
	row.add_child(lbl)
	return row

func _empty_hint(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.50))
	return lbl

func _build_summary_label() -> Control:
	var username := String(account.get("username", ""))
	var all: Dictionary = StatsStore.get_all_for_user(username)
	var matches: int = 0; var total_kills: int = 0
	var best_survive: float = 0.0; var total_seconds: float = 0.0
	for cid in all:
		var e: Dictionary = all[cid] as Dictionary
		matches       += int(e.get("matches", 0))
		total_kills   += int(e.get("total_kills", 0))
		best_survive   = max(best_survive, float(e.get("best_survive_seconds", 0.0)))
		total_seconds += float(e.get("total_play_time_seconds", 0.0))

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.10, 0.12, 0.20, 0.96)
	cs.corner_radius_top_left     = 20
	cs.corner_radius_top_right    = 20
	cs.corner_radius_bottom_right = 20
	cs.corner_radius_bottom_left  = 20
	cs.border_color  = Color(0.56, 0.64, 0.84, 0.74)
	cs.set_border_width_all(2)
	cs.shadow_color  = Color(0.0, 0.0, 0.0, 0.45)
	cs.shadow_size   = 8
	cs.shadow_offset = Vector2(0, 3)
	cs.content_margin_left   = 20
	cs.content_margin_right  = 20
	cs.content_margin_top    = 16
	cs.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", cs)

	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 0)
	stat_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(stat_row)

	var summary_cols: Array[Control] = [
		_make_stat_col(str(matches),                          "Runs", _load_ui_texture(UI_ICON_DIR + "icon_run.png"), 38, 23, 120, true),
		_make_stat_col(StatsStore.format_seconds(best_survive), "Best Survive", _load_ui_texture(UI_ICON_DIR + "icon_best_survive.png"), 38, 23, 120, true),
		_make_stat_col(str(total_kills),                      "Kills", _load_ui_texture(UI_ICON_DIR + "icon_kill.png"), 38, 23, 120, true),
		_make_stat_col(StatsStore.format_seconds(total_seconds), "Time", _load_ui_texture(UI_ICON_DIR + "icon_time.png"), 38, 23, 120, true),
	]
	for i in summary_cols.size():
		stat_row.add_child(summary_cols[i])
		if i < summary_cols.size() - 1:
			var divider := ColorRect.new()
			divider.color = Color(0.70, 0.70, 0.70, 0.55)
			divider.custom_minimum_size = Vector2(4, 138)
			divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			stat_row.add_child(divider)
	return card

func _make_char_card(data: CharacterData, stats: Dictionary, card_w: float) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.97, 0.94, 0.88, 0.98)
	style.corner_radius_top_left     = 20
	style.corner_radius_top_right    = 20
	style.corner_radius_bottom_right = 20
	style.corner_radius_bottom_left  = 20
	style.border_color  = Color(0.86, 0.74, 0.58, 0.84)
	style.set_border_width_all(2)
	style.shadow_color  = Color(0.20, 0.12, 0.05, 0.24)
	style.shadow_size   = 12
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left   = 16
	style.content_margin_right  = 16
	style.content_margin_top    = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(0, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var matches: int = int(stats.get("matches", 0))
	if matches == 0:
		panel.modulate = Color(1.0, 1.0, 1.0, 0.68)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	panel.add_child(hbox)

	var portrait_panel := Panel.new()
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.93, 0.89, 0.80)
	p_style.corner_radius_top_left     = 14
	p_style.corner_radius_top_right    = 14
	p_style.corner_radius_bottom_right = 14
	p_style.corner_radius_bottom_left  = 14
	portrait_panel.add_theme_stylebox_override("panel", p_style)
	portrait_panel.custom_minimum_size = Vector2(140, 140)
	portrait_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_panel.clip_contents = true
	hbox.add_child(portrait_panel)

	var portrait_tex: Texture2D = _load_portrait(String(data.id))
	if portrait_tex != null:
		var tr := TextureRect.new()
		tr.texture = portrait_tex
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_panel.add_child(tr)
	else:
		var swatch := ColorRect.new()
		swatch.color = data.tint
		swatch.set_anchors_preset(Control.PRESET_FULL_RECT)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_panel.add_child(swatch)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	hbox.add_child(col)

	var name_lbl := Label.new()
	name_lbl.text = data.display_name
	name_lbl.add_theme_font_size_override("font_size", 40)
	name_lbl.add_theme_color_override("font_color", Color(0.28, 0.18, 0.08))

	if matches <= 0:
		col.add_child(name_lbl)
		var hint := Label.new()
		hint.text = "Not played yet"
		hint.add_theme_font_size_override("font_size", 36)
		hint.add_theme_color_override("font_color", Color(0.52, 0.42, 0.28))
		col.add_child(hint)
		return panel

	var best_survive: float = float(stats.get("best_survive_seconds", 0.0))
	var total_kills: int    = int(stats.get("total_kills", 0))
	var total_time: float   = float(stats.get("total_play_time_seconds", 0.0))
	var last_played: String = String(stats.get("last_played_at", ""))

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 14)
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(top_row)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_stretch_ratio = 0.8
	text_col.add_theme_constant_override("separation", 4)
	top_row.add_child(text_col)
	text_col.add_child(name_lbl)

	var runs_lbl := Label.new()
	runs_lbl.text = "%d run%s" % [matches, "s" if matches != 1 else ""]
	runs_lbl.add_theme_font_size_override("font_size", 32)
	runs_lbl.add_theme_color_override("font_color", Color(0.36, 0.26, 0.14))
	text_col.add_child(runs_lbl)

	var line_time := Label.new()
	line_time.text = "%s played" % [StatsStore.format_seconds(total_time)]
	line_time.add_theme_font_size_override("font_size", 27)
	line_time.add_theme_color_override("font_color", Color(0.40, 0.30, 0.18))
	line_time.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_child(line_time)

	var line_last := Label.new()
	line_last.text = "Last: %s" % _short_date(last_played)
	line_last.add_theme_font_size_override("font_size", 26)
	line_last.add_theme_color_override("font_color", Color(0.40, 0.30, 0.18))
	line_last.autowrap_mode = TextServer.AUTOWRAP_WORD
	line_last.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_child(line_last)

	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_stretch_ratio = 1.2
	right_col.custom_minimum_size = Vector2(360, 0)
	right_col.add_theme_constant_override("separation", 8)
	top_row.add_child(right_col)

	var right_stats := HBoxContainer.new()
	right_stats.add_theme_constant_override("separation", 20)
	right_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_stats.alignment = BoxContainer.ALIGNMENT_CENTER
	right_col.add_child(right_stats)

	right_stats.add_child(_make_record_right_stat("Best survive", StatsStore.format_seconds(best_survive), _load_ui_texture(UI_ICON_DIR + "icon_best_survive.png")))
	var right_divider := ColorRect.new()
	right_divider.color = Color(0.70, 0.70, 0.70, 0.62)
	right_divider.custom_minimum_size = Vector2(4, 92)
	right_divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_stats.add_child(right_divider)
	right_stats.add_child(_make_record_right_stat("Kills", str(total_kills), _load_ui_texture(UI_ICON_DIR + "icon_kill.png")))

	var detail_record: Dictionary = _best_local_record_for_character(String(data.id))
	var detail_btn := Button.new()
	detail_btn.text = "View Run Details"
	detail_btn.custom_minimum_size = Vector2(300, 42)
	detail_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_btn.add_theme_font_size_override("font_size", 20)
	_style_match_detail_btn(detail_btn)
	var history_detail: Dictionary = _equipment_detail_for_character(String(data.id), detail_record)
	detail_btn.pressed.connect(func() -> void: _show_match_detail_modal(history_detail))
	right_col.add_child(detail_btn)

	return panel

func _equipped_ring_text(char_id: String) -> String:
	var username: String = String(account.get("username", ""))
	if username.is_empty() or char_id.is_empty():
		return "Rings: No rings equipped"
	var equipped: Dictionary = RingStore.get_equipped_rings(username, char_id)
	return _ring_text_from_slots(equipped, "Rings: No rings equipped")

func _equipped_artifact_text(char_id: String) -> String:
	var username: String = String(account.get("username", ""))
	if username.is_empty() or char_id.is_empty():
		return "Artifacts: None equipped"
	var equipped: Dictionary = ArtifactStore.get_equipped_artifacts(username, char_id)
	return _artifact_text_from_slots(equipped)

func _global_entry_ring_text(entry: Dictionary, char_id: String) -> String:
	var rings_value: Variant = entry.get("rings", null)
	if typeof(rings_value) == TYPE_DICTIONARY:
		var rings: Dictionary = rings_value as Dictionary
		if not rings.is_empty():
			return _ring_text_from_slots(rings, "Rings: No rings equipped")
	var current_username: String = String(account.get("username", "")).strip_edges().to_lower()
	var entry_username: String = String(entry.get("username", "")).strip_edges().to_lower()
	if not current_username.is_empty() and current_username == entry_username:
		return _equipped_ring_text(char_id)
	return "Rings: No rings equipped"

func _ring_text_from_slots(equipped: Dictionary, empty_text: String) -> String:
	var parts: Array[String] = []
	for slot in 2:
		var ring = equipped.get("slot_%d" % slot, null)
		if ring == null:
			continue
		var ring_data: Dictionary = RingStore.normalize_ring(ring as Dictionary)
		parts.append("%s T%d (%s)" % [
			ring_data.get("name", "Ring") as String,
			int(ring_data.get("tier", 1)),
			_format_ring_bonus(ring_data),
		])
	if parts.is_empty():
		return empty_text
	return "Rings: " + "  ·  ".join(parts)

func _artifact_text_from_slots(equipped: Dictionary) -> String:
	var parts: Array[String] = []
	for slot in 2:
		var art = equipped.get("slot_%d" % slot, null)
		if art == null:
			continue
		var a: Dictionary = art as Dictionary
		parts.append(a.get("name", "Artifact") as String)
	if parts.is_empty():
		return "Artifacts: None equipped"
	return "Artifacts: " + "  ·  ".join(parts)

func _best_local_record_for_character(char_id: String) -> Dictionary:
	var username: String = String(account.get("username", ""))
	if username.is_empty() or char_id.is_empty():
		return {}
	var recs: Array = StatsStore.get_recent_match_records(username, 80)
	for rec in recs:
		if typeof(rec) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = rec as Dictionary
		if String(d.get("character", "")) == char_id:
			return d
	return {}

func _equipment_detail_for_character(char_id: String, _seed: Dictionary = {}) -> Dictionary:
	if char_id.is_empty():
		return {}
	var out: Dictionary = _seed.duplicate(true)
	out["character"] = char_id

	var username: String = String(account.get("username", ""))
	var all_stats: Dictionary = StatsStore.get_all_for_user(username)
	var stats: Dictionary = all_stats.get(char_id, {}) as Dictionary

	if not out.has("kills"):
		out["kills"] = int(stats.get("total_kills", 0))
	if not out.has("survive_seconds"):
		out["survive_seconds"] = float(stats.get("best_survive_seconds", 0.0))

	var rings_value: Variant = out.get("rings", null)
	if typeof(rings_value) != TYPE_DICTIONARY or (rings_value as Dictionary).is_empty():
		out["rings"] = RingStore.get_equipped_rings(username, char_id)

	var arts_value: Variant = out.get("artifacts", null)
	if typeof(arts_value) != TYPE_DICTIONARY or (arts_value as Dictionary).is_empty():
		out["artifacts"] = ArtifactStore.get_equipped_artifacts(username, char_id)

	if not out.has("ts"):
		out["ts"] = 0
	return out

func _detail_entry_from_global_entry(entry: Dictionary, mode: String) -> Dictionary:
	var char_id: String = String(entry.get("character", ""))
	if char_id.is_empty():
		return {}
	var local: Dictionary = _best_local_record_for_character(char_id)
	var is_survive: bool = mode == "survive"
	var out: Dictionary = {
		"character": char_id,
		"rank": int(entry.get("rank", 0)),
		"kills": int(entry.get("value", 0)) if not is_survive else int(local.get("kills", 0)),
		"survive_seconds": float(entry.get("value", 0.0)) if is_survive else float(local.get("survive_seconds", 0.0)),
		"rings": entry.get("rings", local.get("rings", {})),
		"artifacts": local.get("artifacts", {}),
		"ts": local.get("ts", 0),
	}
	return out

func _show_match_detail_modal(record: Dictionary) -> void:
	if record.is_empty():
		return
	var view: Vector2 = get_viewport_rect().size
	var layer := CanvasLayer.new()
	add_child(layer)

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.78)
	overlay.size = view
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(overlay)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(min(view.x - 44.0, 920.0), min(view.y - 56.0, 1380.0))
	panel.position = Vector2((view.x - panel.custom_minimum_size.x) * 0.5, (view.y - panel.custom_minimum_size.y) * 0.5)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.06, 0.08, 0.98)
	st.corner_radius_top_left = 24
	st.corner_radius_top_right = 24
	st.corner_radius_bottom_right = 24
	st.corner_radius_bottom_left = 24
	st.border_color = Color(0.93, 0.67, 0.24, 0.95)
	st.set_border_width_all(4)
	st.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	st.shadow_size = 18
	st.shadow_offset = Vector2(0, 8)
	st.content_margin_left = 24
	st.content_margin_right = 24
	st.content_margin_top = 22
	st.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", st)
	layer.add_child(panel)

	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and not panel.get_global_rect().has_point(mb.global_position):
				layer.queue_free()
		elif event is InputEventScreenTouch:
			var touch_event := event as InputEventScreenTouch
			if touch_event.pressed and not panel.get_global_rect().has_point(touch_event.global_position):
				layer.queue_free()
	)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 14)
	panel.add_child(root)

	var char_id: String = String(record.get("character", ""))
	var player_name: String = String(record.get("display_name", account.get("display_name", account.get("username", char_id))))
	var rank_num: int = int(record.get("rank", 0))
	var kills: int = int(record.get("kills", 0))
	var survive_text: String = StatsStore.format_seconds(float(record.get("survive_seconds", 0.0)))
	var date_raw: String = String(record.get("played_at", record.get("last_played_at", "")))
	if date_raw.is_empty():
		var ts: int = int(record.get("ts", 0))
		if ts > 0:
			date_raw = Time.get_datetime_string_from_unix_time(ts)
	var date_text: String = _short_date(date_raw)

	var top_row := HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(top_row)

	var close_x := Button.new()
	close_x.text = "X"
	close_x.custom_minimum_size = Vector2(58, 58)
	close_x.add_theme_font_size_override("font_size", 34)
	close_x.focus_mode = Control.FOCUS_NONE
	var x_style := StyleBoxFlat.new()
	x_style.bg_color = Color(0.35, 0.12, 0.10, 0.96)
	x_style.corner_radius_top_left = 28
	x_style.corner_radius_top_right = 28
	x_style.corner_radius_bottom_right = 28
	x_style.corner_radius_bottom_left = 28
	x_style.border_color = Color(0.96, 0.67, 0.22, 0.96)
	x_style.set_border_width_all(3)
	close_x.add_theme_stylebox_override("normal", x_style)
	close_x.add_theme_stylebox_override("hover", x_style)
	close_x.add_theme_stylebox_override("pressed", x_style)
	close_x.add_theme_color_override("font_color", Color(1.0, 0.92, 0.78))
	close_x.pressed.connect(func() -> void: layer.queue_free())
	top_row.add_child(close_x)

	var title := Label.new()
	title.text = "RUN DETAILS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 66)
	title.add_theme_color_override("font_color", Color(0.99, 0.79, 0.30))
	title.add_theme_color_override("font_outline_color", Color(0.20, 0.10, 0.03, 0.96))
	title.add_theme_constant_override("outline_size", 5)
	root.add_child(title)

	var title_divider := ColorRect.new()
	title_divider.color = Color(0.90, 0.62, 0.20, 0.80)
	title_divider.custom_minimum_size = Vector2(0, 2)
	title_divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(title_divider)

	var name_lbl := Label.new()
	name_lbl.text = player_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 52)
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.88, 0.74))
	root.add_child(name_lbl)

	var hero := HBoxContainer.new()
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero.add_theme_constant_override("separation", 18)
	root.add_child(hero)

	var left_col := VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(246, 0)
	left_col.add_theme_constant_override("separation", 10)
	hero.add_child(left_col)

	var badge := Label.new()
	badge.text = str(rank_num) if rank_num > 0 else "—"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 44)
	badge.add_theme_color_override("font_color", Color(0.99, 0.82, 0.28))
	badge.add_theme_color_override("font_outline_color", Color(0.18, 0.10, 0.03, 0.96))
	badge.add_theme_constant_override("outline_size", 4)
	left_col.add_child(badge)

	var portrait := _make_portrait_panel(char_id, 230, Color(0.28, 0.16, 0.05))
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color(0.20, 0.12, 0.05, 0.96)
	portrait_style.corner_radius_top_left = 14
	portrait_style.corner_radius_top_right = 14
	portrait_style.corner_radius_bottom_right = 14
	portrait_style.corner_radius_bottom_left = 14
	portrait_style.border_color = Color(0.95, 0.67, 0.23, 0.94)
	portrait_style.set_border_width_all(3)
	portrait.add_theme_stylebox_override("panel", portrait_style)
	left_col.add_child(portrait)

	var stat_card := PanelContainer.new()
	stat_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stat_style := StyleBoxFlat.new()
	stat_style.bg_color = Color(0.07, 0.06, 0.08, 0.94)
	stat_style.corner_radius_top_left = 14
	stat_style.corner_radius_top_right = 14
	stat_style.corner_radius_bottom_right = 14
	stat_style.corner_radius_bottom_left = 14
	stat_style.border_color = Color(0.82, 0.58, 0.24, 0.56)
	stat_style.set_border_width_all(2)
	stat_style.content_margin_left = 14
	stat_style.content_margin_right = 14
	stat_style.content_margin_top = 14
	stat_style.content_margin_bottom = 14
	stat_card.add_theme_stylebox_override("panel", stat_style)
	hero.add_child(stat_card)

	var stat_col := VBoxContainer.new()
	stat_col.add_theme_constant_override("separation", 10)
	stat_card.add_child(stat_col)

	var row_kill := HBoxContainer.new()
	row_kill.add_theme_constant_override("separation", 10)
	stat_col.add_child(row_kill)
	var kill_icon := TextureRect.new()
	kill_icon.texture = _load_ui_texture(UI_ICON_DIR + "icon_kill.png")
	kill_icon.custom_minimum_size = Vector2(120, 120)
	kill_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	kill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row_kill.add_child(kill_icon)
	var kill_lbl := Label.new()
	kill_lbl.text = "Kills"
	kill_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kill_lbl.add_theme_font_size_override("font_size", 40)
	kill_lbl.add_theme_color_override("font_color", Color(0.95, 0.89, 0.78))
	row_kill.add_child(kill_lbl)
	var kill_val := Label.new()
	kill_val.text = str(kills)
	kill_val.add_theme_font_size_override("font_size", 52)
	kill_val.add_theme_color_override("font_color", Color(0.99, 0.78, 0.30))
	row_kill.add_child(kill_val)

	var sep1 := ColorRect.new()
	sep1.color = Color(0.45, 0.33, 0.20, 0.60)
	sep1.custom_minimum_size = Vector2(0, 2)
	sep1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_col.add_child(sep1)

	var row_survive := HBoxContainer.new()
	row_survive.add_theme_constant_override("separation", 10)
	stat_col.add_child(row_survive)
	var survive_icon := TextureRect.new()
	survive_icon.texture = _load_ui_texture(UI_ICON_DIR + "icon_best_survive.png")
	survive_icon.custom_minimum_size = Vector2(120, 120)
	survive_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	survive_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row_survive.add_child(survive_icon)
	var survive_lbl := Label.new()
	survive_lbl.text = "Survive Time"
	survive_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	survive_lbl.add_theme_font_size_override("font_size", 40)
	survive_lbl.add_theme_color_override("font_color", Color(0.95, 0.89, 0.78))
	row_survive.add_child(survive_lbl)
	var survive_val := Label.new()
	survive_val.text = survive_text
	survive_val.add_theme_font_size_override("font_size", 52)
	survive_val.add_theme_color_override("font_color", Color(0.99, 0.78, 0.30))
	row_survive.add_child(survive_val)

	var sep2 := ColorRect.new()
	sep2.color = Color(0.45, 0.33, 0.20, 0.60)
	sep2.custom_minimum_size = Vector2(0, 2)
	sep2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_col.add_child(sep2)

	var row_date := HBoxContainer.new()
	row_date.add_theme_constant_override("separation", 10)
	stat_col.add_child(row_date)
	var date_icon := TextureRect.new()
	date_icon.texture = _load_ui_texture(UI_ICON_DIR + "icon_time.png")
	date_icon.custom_minimum_size = Vector2(120, 120)
	date_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	date_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row_date.add_child(date_icon)
	var date_lbl := Label.new()
	date_lbl.text = "Date"
	date_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	date_lbl.add_theme_font_size_override("font_size", 40)
	date_lbl.add_theme_color_override("font_color", Color(0.95, 0.89, 0.78))
	row_date.add_child(date_lbl)
	var date_val := Label.new()
	date_val.text = date_text
	date_val.add_theme_font_size_override("font_size", 36)
	date_val.add_theme_color_override("font_color", Color(0.90, 0.82, 0.72))
	row_date.add_child(date_val)

	var rings_header := Label.new()
	rings_header.text = "RINGS"
	rings_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rings_header.add_theme_font_size_override("font_size", 46)
	rings_header.add_theme_color_override("font_color", Color(0.98, 0.76, 0.28))
	root.add_child(rings_header)
	_add_equipment_lines(root, "ring", record.get("rings", {}) as Dictionary)

	var arts_header := Label.new()
	arts_header.text = "ARTIFACTS"
	arts_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arts_header.add_theme_font_size_override("font_size", 46)
	arts_header.add_theme_color_override("font_color", Color(0.98, 0.76, 0.28))
	root.add_child(arts_header)
	_add_equipment_lines(root, "artifact", record.get("artifacts", {}) as Dictionary)

	var quote := Label.new()
	quote.text = '"Power comes from strategy, not luck."'
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD
	quote.add_theme_font_size_override("font_size", 34)
	quote.add_theme_color_override("font_color", Color(0.93, 0.73, 0.36))
	root.add_child(quote)

	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(0, 92)
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_btn.add_theme_font_size_override("font_size", 58)
	close_btn.focus_mode = Control.FOCUS_NONE
	var close_n := StyleBoxFlat.new()
	close_n.bg_color = Color(0.27, 0.12, 0.45, 0.98)
	close_n.corner_radius_top_left = 18
	close_n.corner_radius_top_right = 18
	close_n.corner_radius_bottom_right = 18
	close_n.corner_radius_bottom_left = 18
	close_n.border_color = Color(0.96, 0.70, 0.38, 0.96)
	close_n.set_border_width_all(3)
	close_btn.add_theme_stylebox_override("normal", close_n)
	close_btn.add_theme_stylebox_override("hover", close_n)
	close_btn.add_theme_stylebox_override("pressed", close_n)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.84))
	close_btn.pressed.connect(func() -> void: layer.queue_free())
	root.add_child(close_btn)

func _add_equipment_lines(root: VBoxContainer, item_type: String, slots: Dictionary) -> void:
	var found := false
	for slot in 2:
		var item = slots.get("slot_%d" % slot, null)
		if item == null:
			continue
		if typeof(item) != TYPE_DICTIONARY:
			continue
		found = true
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color(0.10, 0.08, 0.12, 0.96)
		cs.corner_radius_top_left = 14
		cs.corner_radius_top_right = 14
		cs.corner_radius_bottom_right = 14
		cs.corner_radius_bottom_left = 14
		cs.border_color = Color(0.76, 0.46, 0.86, 0.75)
		cs.set_border_width_all(2)
		cs.content_margin_left = 12
		cs.content_margin_right = 12
		cs.content_margin_top = 10
		cs.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", cs)
		root.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)

		var item_dict: Dictionary = item as Dictionary
		var icon: Texture2D = _equipment_icon(item_type, item_dict)
		if icon != null:
			var panel_size: int = 110 if item_type == "artifact" else 96
			var icon_size: int = 102 if item_type == "artifact" else 86
			var icon_panel := PanelContainer.new()
			var ips := StyleBoxFlat.new()
			ips.bg_color = Color(0.18, 0.08, 0.24, 0.96)
			ips.corner_radius_top_left = 10
			ips.corner_radius_top_right = 10
			ips.corner_radius_bottom_right = 10
			ips.corner_radius_bottom_left = 10
			ips.border_color = Color(0.76, 0.46, 0.92, 0.94)
			ips.set_border_width_all(2)
			icon_panel.add_theme_stylebox_override("panel", ips)
			icon_panel.custom_minimum_size = Vector2(panel_size, panel_size)
			row.add_child(icon_panel)

			var icon_rect := TextureRect.new()
			icon_rect.texture = icon
			icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if item_type == "artifact" else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_panel.add_child(icon_rect)

		var text_col := VBoxContainer.new()
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_col.add_theme_constant_override("separation", 4)
		row.add_child(text_col)

		var title_lbl := Label.new()
		if item_type == "ring":
			var ring_data: Dictionary = RingStore.normalize_ring(item_dict)
			title_lbl.text = "%s T%d" % [
				ring_data.get("name", "Ring") as String,
				int(ring_data.get("tier", 1)),
			]
			title_lbl.add_theme_font_size_override("font_size", 32)
			title_lbl.add_theme_color_override("font_color", Color(0.98, 0.92, 0.84))
			title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text_col.add_child(title_lbl)
			var sub_lbl := Label.new()
			sub_lbl.text = _format_ring_bonus(ring_data)
			sub_lbl.add_theme_font_size_override("font_size", 24)
			sub_lbl.add_theme_color_override("font_color", Color(0.83, 0.78, 0.88))
			sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			sub_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text_col.add_child(sub_lbl)
		else:
			title_lbl.text = item_dict.get("name", "Artifact") as String
			title_lbl.add_theme_font_size_override("font_size", 32)
			title_lbl.add_theme_color_override("font_color", Color(0.98, 0.92, 0.84))
			title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			text_col.add_child(title_lbl)
			var desc_text: String = _artifact_desc_for_history(item_dict)
			if not desc_text.is_empty():
				var desc_lbl := Label.new()
				desc_lbl.text = desc_text
				desc_lbl.add_theme_font_size_override("font_size", 22)
				desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.88))
				desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				text_col.add_child(desc_lbl)
			var sub_art := _format_artifact_bonus(item_dict)
			if not sub_art.is_empty() and sub_art.to_lower() != desc_text.to_lower():
				var sub_lbl2 := Label.new()
				sub_lbl2.text = sub_art
				sub_lbl2.add_theme_font_size_override("font_size", 21)
				sub_lbl2.add_theme_color_override("font_color", Color(0.83, 0.78, 0.88))
				sub_lbl2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				sub_lbl2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				text_col.add_child(sub_lbl2)

	if found:
		return

	var empty_lbl := Label.new()
	empty_lbl.text = "None equipped"
	empty_lbl.add_theme_font_size_override("font_size", 28)
	empty_lbl.add_theme_color_override("font_color", Color(0.78, 0.72, 0.80))
	empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(empty_lbl)

func _equipment_icon(item_type: String, item: Dictionary) -> Texture2D:
	if item_type == "ring":
		return RingStore.ring_icon(item)

	# Reuse ArtifactStore's icon resolver so History detail matches game inventory rendering.
	var store_icon: Texture2D = ArtifactStore.artifact_icon(item)
	if store_icon != null:
		return store_icon

	# Fallback by artifact name when historical payloads miss id/icon fields.
	var item_name: String = String(item.get("name", "")).strip_edges().to_lower()
	if not item_name.is_empty():
		for tpl_any in ArtifactStore.ARTIFACT_POOL:
			if typeof(tpl_any) != TYPE_DICTIONARY:
				continue
			var tpl: Dictionary = tpl_any as Dictionary
			if String(tpl.get("name", "")).strip_edges().to_lower() == item_name:
				var mapped_icon: Texture2D = ArtifactStore.artifact_icon(tpl)
				if mapped_icon != null:
					return mapped_icon

	var explicit: String = String(item.get("icon", ""))
	if not explicit.is_empty() and ResourceLoader.exists(explicit):
		return load(explicit) as Texture2D

	var raw_id: String = String(item.get("id", ""))
	if raw_id.is_empty():
		return null
	var base_id: String = raw_id
	var cut: int = raw_id.rfind("_")
	if cut > 0:
		var suffix: String = raw_id.substr(cut + 1)
		if suffix.is_valid_int():
			base_id = raw_id.substr(0, cut)

	var candidates: Array[String] = [
		"res://assets/artifacts/%s.png" % base_id,
		"res://assets/artifacts/%s.webp" % base_id,
		"res://assets/sprites/artifacts/%s.png" % base_id,
		"res://assets/sprites/artifacts/%s.webp" % base_id,
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null

func _format_ring_bonus(ring: Dictionary) -> String:
	var attr: String = ring.get("attr", "") as String
	var value: float = float(ring.get("value", 0.0))
	if attr == "revive_once":
		return "revive once per gameplay"
	if attr == "timed_shield":
		return "1s shield every 10s"
	if attr in ["potion_drop_rate", "xp_bonus", "ring_drop_rate", "skill_dmg", "skill_cd", "aoe_radius", "projectile_spd", "crit_chance", "boss_dmg"]:
		return "+%d%% %s" % [int(round(value * 100.0)), attr]
	if attr == "regen":
		return "+%.1f HP/s" % value
	return "+%.0f %s" % [value, attr]

func _format_artifact_bonus(artifact: Dictionary) -> String:
	if artifact.has("bonus_text"):
		return String(artifact.get("bonus_text", "")).strip_edges()
	var attr: String = String(artifact.get("attr", "")).strip_edges()
	if attr.is_empty():
		return ""
	var value: float = float(artifact.get("value", 0.0))
	if abs(value) < 0.001:
		return attr
	if abs(value) <= 1.0:
		return "+%d%% %s" % [int(round(value * 100.0)), attr]
	return "+%.0f %s" % [value, attr]

func _artifact_desc_for_history(artifact: Dictionary) -> String:
	var direct_desc: String = String(artifact.get("desc", "")).strip_edges()
	if not direct_desc.is_empty():
		return direct_desc

	var artifact_id: String = String(artifact.get("id", "")).strip_edges()
	var artifact_name: String = String(artifact.get("name", "")).strip_edges().to_lower()
	for tpl_any in ArtifactStore.ARTIFACT_POOL:
		if typeof(tpl_any) != TYPE_DICTIONARY:
			continue
		var tpl: Dictionary = tpl_any as Dictionary
		var tpl_id: String = String(tpl.get("id", "")).strip_edges()
		var tpl_name: String = String(tpl.get("name", "")).strip_edges().to_lower()
		if (not artifact_id.is_empty() and (artifact_id == tpl_id or artifact_id.begins_with("%s_" % tpl_id))) or (not artifact_name.is_empty() and artifact_name == tpl_name):
			return String(tpl.get("desc", "")).strip_edges()
	return ""

func _short_date(iso: String) -> String:
	if iso.is_empty(): return "—"
	var t_idx: int = iso.find("T")
	if t_idx <= 0: return iso
	return "%s %s" % [iso.substr(0, t_idx), iso.substr(t_idx + 1, 5)]

func _load_portrait(char_id: String) -> Texture2D:
	if char_id.is_empty(): return null
	for ext in PORTRAIT_EXTS:
		var path: String = PORTRAIT_DIR + char_id + ext
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null

func _make_stat_col(value: String, key: String, icon: Texture2D = null, value_size: int = 40, key_size: int = 30, icon_size: int = 48, expand_horizontal: bool = true, value_color: Color = Color(0.97, 0.93, 0.82), key_color: Color = Color(0.75, 0.68, 0.55)) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL if expand_horizontal else Control.SIZE_SHRINK_CENTER
	if icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.texture = icon
		icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
		icon_rect.size = Vector2(icon_size, icon_size)
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(icon_rect)
	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.add_theme_font_size_override("font_size", value_size)
	val_lbl.add_theme_color_override("font_color", value_color)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(val_lbl)
	var key_lbl := Label.new()
	key_lbl.text = key
	key_lbl.add_theme_font_size_override("font_size", key_size)
	key_lbl.add_theme_color_override("font_color", key_color)
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(key_lbl)
	return col

func _make_record_right_stat(label_text: String, value_text: String, icon: Texture2D) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	head.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(head)

	if icon != null:
		var icon_rect := TextureRect.new()
		icon_rect.texture = icon
		icon_rect.custom_minimum_size = Vector2(64, 64)
		icon_rect.size = Vector2(64, 64)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head.add_child(icon_rect)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.45, 0.35, 0.22))
	head.add_child(lbl)

	var val := Label.new()
	val.text = value_text
	val.add_theme_font_size_override("font_size", 42)
	val.add_theme_color_override("font_color", Color(0.20, 0.14, 0.08))
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(val)

	return col

func _style_secondary(btn: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.18, 0.12, 0.06, 0.92)
	n.corner_radius_top_left     = 28
	n.corner_radius_top_right    = 28
	n.corner_radius_bottom_right = 28
	n.corner_radius_bottom_left  = 28
	n.border_color  = Color(0.92, 0.70, 0.32, 0.55)
	n.set_border_width_all(2)
	n.shadow_color  = Color(0.0, 0.0, 0.0, 0.38)
	n.shadow_size   = 7
	n.shadow_offset = Vector2(0, 3)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.22, 0.22, 0.35, 0.95)
	var p := n.duplicate() as StyleBoxFlat
	p.bg_color = Color(0.08, 0.08, 0.16, 0.95)
	btn.add_theme_stylebox_override("normal",  n)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color",         Color(0.90, 0.90, 1.0))
	btn.add_theme_color_override("font_hover_color",   Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.72, 0.72, 0.88))
	btn.focus_mode = Control.FOCUS_NONE
