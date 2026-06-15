extends Node2D

## Match history, personal ranking, and global leaderboard.

signal back_requested

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
var _global_kills_done: bool      = false
var _global_survive_done: bool    = false
var _global_kill_user_entry: Variant = null
var _global_survive_user_entry: Variant = null

func _ready() -> void:
	SettingsStore.apply(get_tree())
	_build_ui()

func _build_ui() -> void:
	var view := get_viewport_rect().size

	# ── Background ─────────────────────────────────────────────────────────────
	var g := Gradient.new()
	g.set_color(0, Color(0.38, 0.30, 0.22))
	g.set_color(1, Color(0.96, 0.92, 0.80))
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient  = g
	grad_tex.fill      = GradientTexture2D.FILL_LINEAR
	grad_tex.fill_from = Vector2(0.5, 0.0)
	grad_tex.fill_to   = Vector2(0.5, 1.0)
	var bg := TextureRect.new()
	bg.texture      = grad_tex
	bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size         = view
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# ── Title ──────────────────────────────────────────────────────────────────
	var title := Label.new()
	title.text = "History"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.97, 0.93, 0.82))
	title.position = Vector2(0, 80)
	title.size     = Vector2(view.x, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var display_name: String = String(account.get("display_name", account.get("username", "trainer")))
	var subtitle := Label.new()
	subtitle.text = "%s · all matches" % display_name
	subtitle.add_theme_font_size_override("font_size", 36)
	subtitle.add_theme_color_override("font_color", Color(0.88, 0.80, 0.66))
	subtitle.position = Vector2(0, 162)
	subtitle.size     = Vector2(view.x, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

	# ── Tab bar ────────────────────────────────────────────────────────────────
	var tab_bar := HBoxContainer.new()
	tab_bar.position = Vector2(40, 210)
	tab_bar.size     = Vector2(view.x - 80.0, 64)
	tab_bar.add_theme_constant_override("separation", 8)
	add_child(tab_bar)

	var tab_labels: Array[String] = ["History", "Personal", "Global"]
	for i in tab_labels.size():
		var btn := Button.new()
		btn.text = tab_labels[i]
		btn.add_theme_font_size_override("font_size", 32)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size   = Vector2(0, 64)
		btn.focus_mode            = Control.FOCUS_NONE
		_tab_buttons.append(btn)
		tab_bar.add_child(btn)
		btn.pressed.connect(_switch_tab.bind(i))

	# ── Content panels ─────────────────────────────────────────────────────────
	var content_y: float = 282.0
	var content_h: float = view.y - content_y - 130.0
	var content_w: float = view.x - 80.0

	var history_panel  := _build_history_panel(content_y, content_h, content_w)
	var personal_panel := _build_personal_panel(content_y, content_h, content_w)
	_global_panel       = _build_global_panel(content_y, content_h, content_w)

	_tab_panels = [history_panel, personal_panel, _global_panel]
	for p in _tab_panels:
		p.visible = false
		add_child(p)

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
	if idx == 2 and not _global_loaded:
		_global_loaded = true
		_fetch_global_rankings()

func _style_tab_btn(btn: Button, active: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.97, 0.93, 0.82) if active else Color(0.18, 0.14, 0.10, 0.72)
	s.corner_radius_top_left     = 16
	s.corner_radius_top_right    = 16
	s.corner_radius_bottom_right = 6
	s.corner_radius_bottom_left  = 6
	s.border_color = Color(0.82, 0.72, 0.55, 0.65)
	s.set_border_width_all(2)
	btn.add_theme_stylebox_override("normal",  s)
	btn.add_theme_stylebox_override("hover",   s)
	btn.add_theme_stylebox_override("pressed", s)
	var fg := Color(0.20, 0.10, 0.02) if active else Color(0.82, 0.75, 0.62)
	btn.add_theme_color_override("font_color",         fg)
	btn.add_theme_color_override("font_hover_color",   fg)
	btn.add_theme_color_override("font_pressed_color", fg)
	btn.add_theme_color_override("font_focus_color",   fg)

# ── History panel (existing per-character cards) ───────────────────────────────

func _build_history_panel(y: float, h: float, w: float) -> Control:
	var panel := Control.new()
	panel.position = Vector2(40, y)
	panel.size     = Vector2(w, h)

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

# ── Personal ranking panel ─────────────────────────────────────────────────────

func _build_personal_panel(y: float, h: float, w: float) -> Control:
	var panel := Control.new()
	panel.position = Vector2(40, y)
	panel.size     = Vector2(w, h)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(vbox)

	var username   := String(account.get("username", ""))
	var characters := CharacterLoader.load_all()
	if characters.is_empty():
		vbox.add_child(_empty_hint("No characters available."))
		return panel

	var entries: Array = []
	for c in characters:
		entries.append({"data": c, "stats": StatsStore.get_for(username, String(c.id))})

	# ── Best Kill ───────────────────────────────────────────────────────────
	vbox.add_child(_section_header("🗡️ Best Kill", Color(0.95, 0.78, 0.25)))
	var by_kills := entries.duplicate()
	by_kills.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["stats"].get("total_kills", 0)) > int(b["stats"].get("total_kills", 0)))
	var kill_rank: int = 0
	for e in by_kills:
		var kills: int = int(e["stats"].get("total_kills", 0))
		if kills <= 0:
			continue
		kill_rank += 1
		vbox.add_child(_personal_rank_row(kill_rank, e["data"],
			str(kills) + " kills", Color(0.95, 0.72, 0.20)))
	if kill_rank == 0:
		vbox.add_child(_empty_hint("Play a match to see your kill ranking"))

	# ── Best Survive ────────────────────────────────────────────────────────
	vbox.add_child(_section_header("⏱️ Best Survive", Color(0.55, 0.85, 0.65)))
	var by_survive := entries.duplicate()
	by_survive.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["stats"].get("best_survive_seconds", 0.0)) > float(b["stats"].get("best_survive_seconds", 0.0)))
	var surv_rank: int = 0
	for e in by_survive:
		var secs: float = float(e["stats"].get("best_survive_seconds", 0.0))
		if secs <= 0.0:
			continue
		surv_rank += 1
		vbox.add_child(_personal_rank_row(surv_rank, e["data"],
			StatsStore.format_seconds(secs), Color(0.50, 0.88, 0.62)))
	if surv_rank == 0:
		vbox.add_child(_empty_hint("Play a match to see your survive ranking"))

	return panel

func _personal_rank_row(rank: int, data: CharacterData, value_text: String, value_color: Color) -> Control:
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(1.0, 0.99, 0.96)
	cs.corner_radius_top_left     = 16
	cs.corner_radius_top_right    = 16
	cs.corner_radius_bottom_right = 16
	cs.corner_radius_bottom_left  = 16
	cs.border_color  = Color(0.82, 0.72, 0.55, 0.55)
	cs.set_border_width_all(2)
	cs.shadow_color  = Color(0.25, 0.15, 0.05, 0.22)
	cs.shadow_size   = 8
	cs.shadow_offset = Vector2(0, 3)
	cs.content_margin_left   = 16
	cs.content_margin_right  = 16
	cs.content_margin_top    = 12
	cs.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", cs)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	card.add_child(hbox)

	var rank_lbl := Label.new()
	rank_lbl.text = "#%d" % rank
	rank_lbl.add_theme_font_size_override("font_size", 36)
	rank_lbl.add_theme_color_override("font_color",
		Color(0.95, 0.78, 0.25) if rank == 1 else
		(Color(0.75, 0.75, 0.78) if rank == 2 else
		(Color(0.82, 0.52, 0.22) if rank == 3 else Color(0.55, 0.45, 0.32))))
	rank_lbl.custom_minimum_size = Vector2(70, 0)
	rank_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(rank_lbl)

	var portrait_panel := _make_portrait_panel(String(data.id), 72, Color(0.86, 0.82, 0.74))
	hbox.add_child(portrait_panel)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 4)
	hbox.add_child(col)

	var name_lbl := Label.new()
	name_lbl.text = data.display_name
	name_lbl.add_theme_font_size_override("font_size", 34)
	name_lbl.add_theme_color_override("font_color", Color(0.18, 0.10, 0.04))
	col.add_child(name_lbl)

	var val_lbl := Label.new()
	val_lbl.text = value_text
	val_lbl.add_theme_font_size_override("font_size", 32)
	val_lbl.add_theme_color_override("font_color", value_color)
	col.add_child(val_lbl)

	var ring_lbl := Label.new()
	ring_lbl.text = _equipped_ring_text(String(data.id))
	ring_lbl.add_theme_font_size_override("font_size", 26)
	ring_lbl.add_theme_color_override("font_color", Color(0.36, 0.26, 0.14))
	ring_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	col.add_child(ring_lbl)

	return card

# ── Global ranking panel ───────────────────────────────────────────────────────

func _build_global_panel(y: float, h: float, w: float) -> Control:
	var panel := Control.new()
	panel.position = Vector2(40, y)
	panel.size     = Vector2(w, h)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.name = "GlobalScroll"
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 20)
	vbox.name = "GlobalVBox"
	scroll.add_child(vbox)

	vbox.add_child(_section_header("🗡️ Best Kill", Color(0.95, 0.78, 0.25)))
	vbox.add_child(_loading_label("kills"))
	vbox.add_child(_section_header("⏱️ Best Survive", Color(0.55, 0.85, 0.65)))
	vbox.add_child(_loading_label("survive"))
	vbox.add_child(_section_header("Your Best Rank", Color(0.78, 0.72, 1.0)))
	vbox.add_child(_loading_label("self"))

	return panel

func _fetch_global_rankings() -> void:
	# Rebuild the vbox contents to fresh loading state before every fetch attempt.
	# This ensures placeholders always exist when _populate_global_section() runs,
	# so retry works any number of times.
	var vbox: VBoxContainer = _global_panel.get_node_or_null("GlobalScroll/GlobalVBox") as VBoxContainer
	if vbox == null:
		return
	for child in vbox.get_children():
		vbox.remove_child(child)  # detach immediately so queue_free won't sweep new children
		child.queue_free()
	vbox.add_child(_section_header("🗡️ Best Kill", Color(0.95, 0.78, 0.25)))
	vbox.add_child(_loading_label("kills"))
	vbox.add_child(_section_header("⏱️ Best Survive", Color(0.55, 0.85, 0.65)))
	vbox.add_child(_loading_label("survive"))
	vbox.add_child(_section_header("Your Best Rank", Color(0.78, 0.72, 1.0)))
	vbox.add_child(_loading_label("self"))

	_global_kills_done = false
	_global_survive_done = false
	_global_kill_user_entry = null
	_global_survive_user_entry = null

	var username := String(account.get("username", ""))
	LeaderboardClient.fetch_kills_with_user(self, username, func(payload: Dictionary) -> void:
		_global_kills_done = true
		var entries: Array = payload.get("entries", []) as Array
		_global_kill_user_entry = _best_rank_entry(payload.get("user_entry", null), entries, false)
		_populate_global_section("kills", entries, false)
		_populate_global_best_detail()
	)
	LeaderboardClient.fetch_survive_with_user(self, username, func(payload: Dictionary) -> void:
		_global_survive_done = true
		var entries: Array = payload.get("entries", []) as Array
		_global_survive_user_entry = _best_rank_entry(payload.get("user_entry", null), entries, true)
		_populate_global_section("survive", entries, true)
		_populate_global_best_detail()
	)

func _best_rank_entry(server_entry: Variant, entries: Array, is_survive: bool) -> Variant:
	if typeof(server_entry) == TYPE_DICTIONARY:
		return server_entry
	var visible_entry: Variant = _matching_visible_rank_entry(entries)
	if typeof(visible_entry) == TYPE_DICTIONARY:
		return visible_entry
	return _local_best_rank_entry(is_survive)

func _matching_visible_rank_entry(entries: Array) -> Variant:
	var username := String(account.get("username", "")).strip_edges().to_lower()
	var display_name := String(account.get("display_name", username)).strip_edges().to_lower()
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = entry as Dictionary
		var entry_user := String(data.get("username", "")).strip_edges().to_lower()
		var entry_name := String(data.get("display_name", "")).strip_edges().to_lower()
		if not entry_user.is_empty() and entry_user == username:
			return entry
		if not entry_name.is_empty() and (entry_name == display_name or entry_name == username):
			return entry
	return null

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

func _populate_global_section(section: String, entries: Array, is_survive: bool) -> void:
	var vbox: VBoxContainer = _global_panel.get_node_or_null("GlobalScroll/GlobalVBox") as VBoxContainer
	if vbox == null:
		return
	var placeholder: Node = vbox.get_node_or_null("Loading_" + section)
	if placeholder == null:
		return
	var insert_idx: int = placeholder.get_index()
	placeholder.queue_free()

	if entries.is_empty():
		var hint := _empty_hint("No data yet — play a match to appear here!")
		vbox.add_child(hint)
		vbox.move_child(hint, insert_idx)
		insert_idx += 1
		var retry := Button.new()
		retry.text = "↺  Retry"
		retry.add_theme_font_size_override("font_size", 30)
		retry.custom_minimum_size = Vector2(160, 56)
		retry.focus_mode = Control.FOCUS_NONE
		_style_retry(retry)
		vbox.add_child(retry)
		vbox.move_child(retry, insert_idx)
		retry.pressed.connect(func() -> void:
			_global_loaded = false
			_switch_tab(2)
		)
		return

	for entry in entries:
		var row := _global_rank_row(entry, is_survive)
		vbox.add_child(row)
		vbox.move_child(row, insert_idx)
		insert_idx += 1

func _populate_global_best_detail() -> void:
	if not _global_kills_done or not _global_survive_done:
		return
	var vbox: VBoxContainer = _global_panel.get_node_or_null("GlobalScroll/GlobalVBox") as VBoxContainer
	if vbox == null:
		return
	var placeholder: Node = vbox.get_node_or_null("Loading_self")
	if placeholder == null:
		return
	var insert_idx: int = placeholder.get_index()
	vbox.remove_child(placeholder)
	placeholder.queue_free()

	var has_kills := typeof(_global_kill_user_entry) == TYPE_DICTIONARY
	var has_survive := typeof(_global_survive_user_entry) == TYPE_DICTIONARY
	if not has_kills and not has_survive:
		var hint := _empty_hint("Play a match to see your global rank here.")
		vbox.add_child(hint)
		vbox.move_child(hint, insert_idx)
		return

	if has_kills:
		var kill_card: Control = _global_user_rank_card("Best Kill Rank", _global_kill_user_entry as Dictionary, false)
		vbox.add_child(kill_card)
		vbox.move_child(kill_card, insert_idx)
		insert_idx += 1
	if has_survive:
		var survive_card: Control = _global_user_rank_card("Best Survive Rank", _global_survive_user_entry as Dictionary, true)
		vbox.add_child(survive_card)
		vbox.move_child(survive_card, insert_idx)

func _global_user_rank_card(title: String, entry: Dictionary, is_survive: bool) -> Control:
	var rank: int = int(entry.get("rank", 0))
	var char_id: String = str(entry.get("character", ""))
	var value_text: String
	if is_survive:
		value_text = StatsStore.format_seconds(float(entry.get("value", 0.0)))
	else:
		value_text = str(int(entry.get("value", 0))) + " kills"
	if rank <= 0:
		value_text += " · rank syncing"
	var value_color := Color(0.50, 0.88, 0.62) if is_survive else Color(0.95, 0.72, 0.20)

	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.20, 0.18, 0.30, 0.94)
	cs.corner_radius_top_left     = 16
	cs.corner_radius_top_right    = 16
	cs.corner_radius_bottom_right = 16
	cs.corner_radius_bottom_left  = 16
	cs.border_color  = Color(0.78, 0.72, 1.0, 0.72)
	cs.set_border_width_all(2)
	cs.shadow_color  = Color(0.0, 0.0, 0.0, 0.30)
	cs.shadow_size   = 8
	cs.shadow_offset = Vector2(0, 3)
	cs.content_margin_left   = 16
	cs.content_margin_right  = 16
	cs.content_margin_top    = 12
	cs.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", cs)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	card.add_child(hbox)

	var rank_lbl := Label.new()
	rank_lbl.text = "#%d" % rank if rank > 0 else "#—"
	rank_lbl.add_theme_font_size_override("font_size", 40 if rank > 0 else 34)
	rank_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.25))
	rank_lbl.custom_minimum_size = Vector2(82, 0)
	rank_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(rank_lbl)

	if not char_id.is_empty():
		hbox.add_child(_make_portrait_panel(char_id, 72, Color(0.32, 0.28, 0.45)))

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 4)
	hbox.add_child(col)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", Color(0.93, 0.90, 1.0))
	col.add_child(title_lbl)

	var val_lbl := Label.new()
	val_lbl.text = value_text
	val_lbl.add_theme_font_size_override("font_size", 32)
	val_lbl.add_theme_color_override("font_color", value_color)
	col.add_child(val_lbl)

	var ring_lbl := Label.new()
	ring_lbl.text = _global_entry_ring_text(entry, char_id)
	ring_lbl.add_theme_font_size_override("font_size", 26)
	ring_lbl.add_theme_color_override("font_color", Color(0.82, 0.78, 0.96))
	ring_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	col.add_child(ring_lbl)

	return card

func _style_retry(btn: Button) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.22, 0.22, 0.35, 0.92)
	s.corner_radius_top_left     = 16
	s.corner_radius_top_right    = 16
	s.corner_radius_bottom_right = 16
	s.corner_radius_bottom_left  = 16
	s.border_color = Color(0.55, 0.55, 0.75, 0.75)
	s.set_border_width_all(2)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.30, 0.30, 0.46, 0.95)
	btn.add_theme_stylebox_override("normal",  s)
	btn.add_theme_stylebox_override("hover",   h)
	btn.add_theme_stylebox_override("pressed", s)
	btn.add_theme_color_override("font_color",         Color(0.90, 0.90, 1.0))
	btn.add_theme_color_override("font_hover_color",   Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.72, 0.72, 0.88))

func _global_rank_row(entry: Dictionary, is_survive: bool) -> Control:
	var rank: int       = int(entry.get("rank", 0))
	var player: String  = str(entry.get("display_name", "—"))
	var char_id: String = str(entry.get("character", ""))
	var value_text: String
	if is_survive:
		value_text = StatsStore.format_seconds(float(entry.get("value", 0.0)))
	else:
		value_text = str(int(entry.get("value", 0))) + " kills"
	var value_color := Color(0.50, 0.88, 0.62) if is_survive else Color(0.95, 0.72, 0.20)

	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.14, 0.14, 0.22, 0.90)
	cs.corner_radius_top_left     = 16
	cs.corner_radius_top_right    = 16
	cs.corner_radius_bottom_right = 16
	cs.corner_radius_bottom_left  = 16
	cs.border_color  = Color(0.55, 0.55, 0.75, 0.55)
	cs.set_border_width_all(2)
	cs.shadow_color  = Color(0.0, 0.0, 0.0, 0.28)
	cs.shadow_size   = 8
	cs.shadow_offset = Vector2(0, 3)
	cs.content_margin_left   = 16
	cs.content_margin_right  = 16
	cs.content_margin_top    = 12
	cs.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", cs)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	card.add_child(hbox)

	var rank_lbl := Label.new()
	rank_lbl.text = "#%d" % rank
	rank_lbl.add_theme_font_size_override("font_size", 36)
	rank_lbl.add_theme_color_override("font_color",
		Color(0.95, 0.78, 0.25) if rank == 1 else
		(Color(0.75, 0.75, 0.78) if rank == 2 else
		(Color(0.82, 0.52, 0.22) if rank == 3 else Color(0.62, 0.60, 0.75))))
	rank_lbl.custom_minimum_size = Vector2(70, 0)
	rank_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(rank_lbl)

	if not char_id.is_empty():
		hbox.add_child(_make_portrait_panel(char_id, 72, Color(0.28, 0.26, 0.38)))

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 4)
	hbox.add_child(col)

	var name_lbl := Label.new()
	name_lbl.text = player
	name_lbl.add_theme_font_size_override("font_size", 34)
	name_lbl.add_theme_color_override("font_color", Color(0.93, 0.90, 1.0))
	col.add_child(name_lbl)

	var val_lbl := Label.new()
	val_lbl.text = value_text
	val_lbl.add_theme_font_size_override("font_size", 32)
	val_lbl.add_theme_color_override("font_color", value_color)
	col.add_child(val_lbl)

	var ring_lbl := Label.new()
	ring_lbl.text = _global_entry_ring_text(entry, char_id)
	ring_lbl.add_theme_font_size_override("font_size", 26)
	ring_lbl.add_theme_color_override("font_color", Color(0.82, 0.78, 0.96))
	ring_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	col.add_child(ring_lbl)

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
		var tr := TextureRect.new()
		tr.texture      = tex
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(tr)
	return p

func _section_header(text: String, accent: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.add_theme_color_override("font_color", accent)
	return lbl

func _loading_label(section: String) -> Label:
	var lbl := Label.new()
	lbl.name = "Loading_" + section
	lbl.text = "Loading…"
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.50))
	return lbl

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
	cs.bg_color = Color(0.14, 0.14, 0.22, 0.90)
	cs.corner_radius_top_left     = 16
	cs.corner_radius_top_right    = 16
	cs.corner_radius_bottom_right = 16
	cs.corner_radius_bottom_left  = 16
	cs.border_color  = Color(0.55, 0.55, 0.75, 0.65)
	cs.set_border_width_all(2)
	cs.shadow_color  = Color(0.0, 0.0, 0.0, 0.32)
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

	stat_row.add_child(_make_stat_col(str(matches),                        "Runs"))
	stat_row.add_child(_make_stat_col(StatsStore.format_seconds(best_survive), "Best Survive"))
	stat_row.add_child(_make_stat_col(str(total_kills),                    "Kills"))
	stat_row.add_child(_make_stat_col(StatsStore.format_seconds(total_seconds), "Time"))
	return card

func _make_char_card(data: CharacterData, stats: Dictionary, card_w: float) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.99, 0.96, 1.0)
	style.corner_radius_top_left     = 20
	style.corner_radius_top_right    = 20
	style.corner_radius_bottom_right = 20
	style.corner_radius_bottom_left  = 20
	style.border_color  = Color(0.82, 0.72, 0.55, 0.65)
	style.set_border_width_all(2)
	style.shadow_color  = Color(0.25, 0.15, 0.05, 0.28)
	style.shadow_size   = 10
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left   = 16
	style.content_margin_right  = 16
	style.content_margin_top    = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(card_w, 0)

	var matches: int = int(stats.get("matches", 0))
	if matches == 0:
		panel.modulate = Color(1.0, 1.0, 1.0, 0.55)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	panel.add_child(hbox)

	var portrait_panel := Panel.new()
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.86, 0.82, 0.74)
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
	col.add_theme_constant_override("separation", 6)
	hbox.add_child(col)

	var name_lbl := Label.new()
	name_lbl.text = data.display_name
	name_lbl.add_theme_font_size_override("font_size", 40)
	name_lbl.add_theme_color_override("font_color", Color(0.18, 0.10, 0.04))
	col.add_child(name_lbl)

	if matches <= 0:
		var hint := Label.new()
		hint.text = "Not played yet"
		hint.add_theme_font_size_override("font_size", 36)
		hint.add_theme_color_override("font_color", Color(0.40, 0.30, 0.18))
		col.add_child(hint)
		return panel

	var best_survive: float = float(stats.get("best_survive_seconds", 0.0))
	var total_kills: int    = int(stats.get("total_kills", 0))
	var total_time: float   = float(stats.get("total_play_time_seconds", 0.0))
	var last_played: String = String(stats.get("last_played_at", ""))

	var runs_lbl := Label.new()
	runs_lbl.text = "%d run%s" % [matches, "s" if matches != 1 else ""]
	runs_lbl.add_theme_font_size_override("font_size", 34)
	runs_lbl.add_theme_color_override("font_color", Color(0.38, 0.26, 0.12))
	col.add_child(runs_lbl)

	var line2 := Label.new()
	line2.text = "Best survive: %s  ·  %d kills" % [StatsStore.format_seconds(best_survive), total_kills]
	line2.add_theme_font_size_override("font_size", 32)
	line2.add_theme_color_override("font_color", Color(0.45, 0.32, 0.18))
	col.add_child(line2)

	var line3 := Label.new()
	line3.text = "%s played  ·  Last: %s" % [StatsStore.format_seconds(total_time), _short_date(last_played)]
	line3.add_theme_font_size_override("font_size", 32)
	line3.add_theme_color_override("font_color", Color(0.42, 0.30, 0.16))
	col.add_child(line3)

	var ring_lbl := Label.new()
	ring_lbl.text = _equipped_ring_text(String(data.id))
	ring_lbl.add_theme_font_size_override("font_size", 28)
	ring_lbl.add_theme_color_override("font_color", Color(0.34, 0.24, 0.14))
	ring_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	col.add_child(ring_lbl)

	return panel

func _equipped_ring_text(char_id: String) -> String:
	var username: String = String(account.get("username", ""))
	if username.is_empty() or char_id.is_empty():
		return "Rings: No rings equipped"
	var equipped: Dictionary = RingStore.get_equipped_rings(username, char_id)
	return _ring_text_from_slots(equipped, "Rings: No rings equipped")

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

func _make_stat_col(value: String, key: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.add_theme_font_size_override("font_size", 40)
	val_lbl.add_theme_color_override("font_color", Color(0.97, 0.93, 0.82))
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(val_lbl)
	var key_lbl := Label.new()
	key_lbl.text = key
	key_lbl.add_theme_font_size_override("font_size", 30)
	key_lbl.add_theme_color_override("font_color", Color(0.75, 0.68, 0.55))
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(key_lbl)
	return col

func _style_secondary(btn: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.14, 0.14, 0.22, 0.92)
	n.corner_radius_top_left     = 28
	n.corner_radius_top_right    = 28
	n.corner_radius_bottom_right = 28
	n.corner_radius_bottom_left  = 28
	n.border_color  = Color(0.55, 0.55, 0.75, 0.75)
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
