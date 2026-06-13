extends Node2D

## Match history & per-character stats for the active account.

signal back_requested

const PORTRAIT_DIR := "res://assets/characters/"
const PORTRAIT_EXTS: Array[String] = [".png", ".webp", ".jpg", ".svg"]

var account: Dictionary = {}

func _ready() -> void:
	SettingsStore.apply(get_tree())
	_build_ui()

func _build_ui() -> void:
	var view := get_viewport_rect().size

	var g := Gradient.new()
	g.set_color(0, Color(0.38, 0.30, 0.22))
	g.set_color(1, Color(0.96, 0.92, 0.80))
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = g
	grad_tex.fill = GradientTexture2D.FILL_LINEAR
	grad_tex.fill_from = Vector2(0.5, 0.0)
	grad_tex.fill_to = Vector2(0.5, 1.0)
	var bg := TextureRect.new()
	bg.texture = grad_tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = view
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := Label.new()
	title.text = "History"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.97, 0.93, 0.82))
	title.position = Vector2(0, 80)
	title.size = Vector2(view.x, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var display_name: String = String(account.get("display_name", account.get("username", "trainer")))
	var subtitle := Label.new()
	subtitle.text = "%s · all matches" % display_name
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.70, 0.58))
	subtitle.position = Vector2(0, 162)
	subtitle.size = Vector2(view.x, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle)

	# Lifetime stat summary card.
	var summary := _build_summary_label()
	var sum_w: float = view.x - 120.0
	summary.position = Vector2((view.x - sum_w) * 0.5, 214)
	add_child(summary)

	# Character cards — vertical list: portrait left, full stats right.
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 318)
	scroll.size = Vector2(view.x - 80.0, view.y - 318.0 - 140.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)

	var username := String(account.get("username", ""))
	var characters := CharacterLoader.load_all()
	if characters.is_empty():
		var msg := Label.new()
		msg.text = "No characters available."
		msg.add_theme_font_size_override("font_size", 22)
		msg.add_theme_color_override("font_color", Color(0.78, 0.70, 0.58))
		list.add_child(msg)
	else:
		for c in characters:
			list.add_child(_make_char_card(c, StatsStore.get_for(username, String(c.id)), view.x - 80.0))

	var back := Button.new()
	back.text = "← Back"
	back.add_theme_font_size_override("font_size", 28)
	back.custom_minimum_size = Vector2(260, 80)
	back.size = Vector2(260, 80)
	back.position = Vector2(60, view.y - 116.0)
	back.focus_mode = Control.FOCUS_NONE
	_style_secondary(back)
	back.pressed.connect(func() -> void: back_requested.emit())
	add_child(back)

func _build_summary_label() -> Control:
	var username := String(account.get("username", ""))
	var all := StatsStore.get_all_for_user(username)
	var matches: int = 0
	var total_kills: int = 0
	var best_survive: float = 0.0
	var total_seconds: float = 0.0
	for cid in all:
		var e: Dictionary = all[cid]
		matches += int(e.get("matches", 0))
		total_kills += int(e.get("total_kills", 0))
		best_survive = max(best_survive, float(e.get("best_survive_seconds", 0.0)))
		total_seconds += float(e.get("total_play_time_seconds", 0.0))

	var card := PanelContainer.new()
	var view_w: float = get_viewport_rect().size.x
	card.custom_minimum_size = Vector2(view_w - 120.0, 0)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.14, 0.14, 0.22, 0.90)
	cs.corner_radius_top_left = 16
	cs.corner_radius_top_right = 16
	cs.corner_radius_bottom_right = 16
	cs.corner_radius_bottom_left = 16
	cs.border_color = Color(0.55, 0.55, 0.75, 0.65)
	cs.set_border_width_all(2)
	cs.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	cs.shadow_size = 8
	cs.shadow_offset = Vector2(0, 3)
	cs.content_margin_left = 20
	cs.content_margin_right = 20
	cs.content_margin_top = 16
	cs.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", cs)

	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 0)
	stat_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(stat_row)

	stat_row.add_child(_make_stat_col(str(matches), "Runs"))
	stat_row.add_child(_make_stat_col(StatsStore.format_seconds(best_survive), "Best Survive"))
	stat_row.add_child(_make_stat_col(str(total_kills), "Kills"))
	stat_row.add_child(_make_stat_col(StatsStore.format_seconds(total_seconds), "Time"))

	return card

## Vertical history card: portrait on left, full match stats on right.
func _make_char_card(data: CharacterData, stats: Dictionary, card_w: float) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.99, 0.96, 1.0)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_right = 20
	style.corner_radius_bottom_left = 20
	style.border_color = Color(0.82, 0.72, 0.55, 0.65)
	style.set_border_width_all(2)
	style.shadow_color = Color(0.25, 0.15, 0.05, 0.28)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(card_w, 0)

	var matches: int = int(stats.get("matches", 0))
	if matches == 0:
		panel.modulate = Color(1.0, 1.0, 1.0, 0.55)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	panel.add_child(hbox)

	# ── Portrait ────────────────────────────────────────────────────────
	var portrait_panel := Panel.new()
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.86, 0.82, 0.74)
	p_style.corner_radius_top_left = 14
	p_style.corner_radius_top_right = 14
	p_style.corner_radius_bottom_right = 14
	p_style.corner_radius_bottom_left = 14
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
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_panel.add_child(tr)
	else:
		var swatch := ColorRect.new()
		swatch.color = data.tint
		swatch.set_anchors_preset(Control.PRESET_FULL_RECT)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_panel.add_child(swatch)

	# ── Stats column ─────────────────────────────────────────────────────
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	hbox.add_child(col)

	var name_lbl := Label.new()
	name_lbl.text = data.display_name
	name_lbl.add_theme_font_size_override("font_size", 30)
	name_lbl.add_theme_color_override("font_color", Color(0.18, 0.10, 0.04))
	col.add_child(name_lbl)

	if matches <= 0:
		var hint := Label.new()
		hint.text = "Not played yet"
		hint.add_theme_font_size_override("font_size", 19)
		hint.add_theme_color_override("font_color", Color(0.55, 0.48, 0.38))
		col.add_child(hint)
		return panel

	var best_survive: float = float(stats.get("best_survive_seconds", 0.0))
	var total_kills: int = int(stats.get("total_kills", 0))
	var total_time: float = float(stats.get("total_play_time_seconds", 0.0))
	var last_played: String = String(stats.get("last_played_at", ""))

	var runs_lbl := Label.new()
	runs_lbl.text = "%d run%s" % [matches, "s" if matches != 1 else ""]
	runs_lbl.add_theme_font_size_override("font_size", 20)
	runs_lbl.add_theme_color_override("font_color", Color(0.38, 0.26, 0.12))
	col.add_child(runs_lbl)

	var line2 := Label.new()
	line2.text = "Best survive: %s  ·  %d kills" % [StatsStore.format_seconds(best_survive), total_kills]
	line2.add_theme_font_size_override("font_size", 18)
	line2.add_theme_color_override("font_color", Color(0.45, 0.32, 0.18))
	col.add_child(line2)

	var line3 := Label.new()
	line3.text = "%s played  ·  Last: %s" % [StatsStore.format_seconds(total_time), _short_date(last_played)]
	line3.add_theme_font_size_override("font_size", 18)
	line3.add_theme_color_override("font_color", Color(0.55, 0.42, 0.28))
	col.add_child(line3)

	return panel

func _short_date(iso: String) -> String:
	if iso.is_empty():
		return "—"
	var t_idx: int = iso.find("T")
	if t_idx <= 0:
		return iso
	var date_part := iso.substr(0, t_idx)
	var time_part := iso.substr(t_idx + 1, 5)
	return "%s %s" % [date_part, time_part]

func _load_portrait(char_id: String) -> Texture2D:
	if char_id.is_empty():
		return null
	for ext in PORTRAIT_EXTS:
		var path: String = PORTRAIT_DIR + char_id + ext
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null

# ---- UI helpers -------------------------------------------------------------

func _make_stat_col(value: String, key: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.add_theme_font_size_override("font_size", 26)
	val_lbl.add_theme_color_override("font_color", Color(0.97, 0.93, 0.82))
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(val_lbl)
	var key_lbl := Label.new()
	key_lbl.text = key
	key_lbl.add_theme_font_size_override("font_size", 14)
	key_lbl.add_theme_color_override("font_color", Color(0.60, 0.55, 0.45))
	key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(key_lbl)
	return col

func _make_badge(badge_text: String, bg: Color, fg: Color) -> Label:
	var lbl := Label.new()
	lbl.text = badge_text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", fg)
	var bs := StyleBoxFlat.new()
	bs.bg_color = bg
	bs.corner_radius_top_left = 10
	bs.corner_radius_top_right = 10
	bs.corner_radius_bottom_right = 10
	bs.corner_radius_bottom_left = 10
	bs.content_margin_left = 10
	bs.content_margin_right = 10
	bs.content_margin_top = 4
	bs.content_margin_bottom = 4
	lbl.add_theme_stylebox_override("normal", bs)
	return lbl

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
