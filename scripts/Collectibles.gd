extends Node2D

signal back_requested

var account_username: String = ""

var _view: Vector2 = Vector2.ZERO
var _current_tab: String = "rings"
var _tab_buttons: Dictionary = {}
var _rings_scroll: ScrollContainer
var _artifacts_scroll: ScrollContainer
var _active_swipe_scroll: ScrollContainer = null

var _bg_tex: Texture2D = preload("res://assets/backgrounds/bg_preparation_stage.png")
var _label_chip_tex: Texture2D = preload("res://assets/icons/icon_label.png")

func _ready() -> void:
	_view = get_viewport_rect().size
	if not account_username.is_empty():
		PurchaseStore.set_username(account_username)
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
	if _rings_scroll != null and is_instance_valid(_rings_scroll) and _rings_scroll.visible and _rings_scroll.get_global_rect().has_point(point):
		return _rings_scroll
	if _artifacts_scroll != null and is_instance_valid(_artifacts_scroll) and _artifacts_scroll.visible and _artifacts_scroll.get_global_rect().has_point(point):
		return _artifacts_scroll
	return null

func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.texture = _bg_tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = _view
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.05, 0.11, 0.84)
	shade.size = _view
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var top_glow := ColorRect.new()
	top_glow.color = Color(0.84, 0.58, 0.16, 0.08)
	top_glow.position = Vector2(0, 0)
	top_glow.size = Vector2(_view.x, 180)
	top_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_glow)

	var title := Label.new()
	title.text = "COLLECTIBLES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(40, 10)
	title.size = Vector2(_view.x - 80, 84)
	title.z_index = 2
	title.add_theme_font_size_override("font_size", 68)
	title.add_theme_color_override("font_color", Color(0.98, 0.83, 0.46))
	add_child(title)

	var tab_y: float = 108.0
	var tab_w: float = clamp(_view.x * 0.19, 170.0, 220.0)
	var tab_gap: float = 14.0
	var total_tabs_w: float = tab_w * 2.0 + tab_gap
	var tab_x: float = (_view.x - total_tabs_w) * 0.5
	var rings_btn := _make_tab_button("RINGS", "rings")
	rings_btn.position = Vector2(tab_x, tab_y)
	rings_btn.size = Vector2(tab_w, 78)
	rings_btn.z_index = 3
	add_child(rings_btn)
	_tab_buttons["rings"] = rings_btn

	var artifacts_btn := _make_tab_button("ARTIFACTS", "artifacts")
	artifacts_btn.position = Vector2(tab_x + tab_w + tab_gap, tab_y)
	artifacts_btn.size = Vector2(tab_w, 78)
	artifacts_btn.z_index = 3
	add_child(artifacts_btn)
	_tab_buttons["artifacts"] = artifacts_btn

	var frame_margin: float = 32.0
	var frame_top: float = 204.0
	var frame_bottom: float = 132.0
	var frame_size := Vector2(_view.x - frame_margin * 2.0, _view.y - frame_top - frame_bottom)
	var frame := PanelContainer.new()
	frame.position = Vector2(frame_margin, frame_top)
	frame.size = frame_size
	frame.add_theme_stylebox_override("panel", _ornate_panel_style(Color(0.62, 0.46, 0.18, 0.95), Color(0.02, 0.05, 0.10, 0.96), 22, 3))
	add_child(frame)

	var frame_inner := MarginContainer.new()
	frame_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame_inner.offset_left = 26
	frame_inner.offset_top = 22
	frame_inner.offset_right = -16
	frame_inner.offset_bottom = -18
	frame.add_child(frame_inner)

	var content_host := Control.new()
	content_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame_inner.add_child(content_host)

	_rings_scroll = _build_collectible_scroll(frame_size.x - 42.0, frame_size.y - 40.0)
	content_host.add_child(_rings_scroll)
	var rings_box := _scroll_content_box(_rings_scroll, frame_size.x - 84.0)
	_fill_ring_cards(rings_box)

	_artifacts_scroll = _build_collectible_scroll(frame_size.x - 42.0, frame_size.y - 40.0)
	content_host.add_child(_artifacts_scroll)
	var artifacts_box := _scroll_content_box(_artifacts_scroll, frame_size.x - 84.0)
	_fill_artifact_cards(artifacts_box)

	var back_btn := Button.new()
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(320, 74)
	back_btn.position = Vector2((_view.x - 320.0) * 0.5, _view.y - 102)
	back_btn.add_theme_font_size_override("font_size", 34)
	back_btn.focus_mode = Control.FOCUS_NONE
	_apply_button_style(back_btn, Color(0.84, 0.66, 0.24, 0.96), Color(0.16, 0.12, 0.08, 0.94), Color(1.0, 1.0, 1.0), 18)
	back_btn.pressed.connect(func() -> void: back_requested.emit())
	add_child(back_btn)

	# Keep tabs in front for mouse hit-testing as well as drawing.
	move_child(rings_btn, get_child_count() - 1)
	move_child(artifacts_btn, get_child_count() - 1)

	_set_current_tab("rings")

func _fill_ring_cards(parent: VBoxContainer) -> void:
	var obtained: Dictionary = {}
	for r in RingStore.load_stash(account_username):
		obtained[(r as Dictionary).get("name", "") as String] = true
	for product_id in PurchaseStore.RING_PRODUCTS.keys():
		if PurchaseStore.is_purchased(product_id as String):
			var purchased_ring: Dictionary = PurchaseStore.ring_product_to_ring(product_id as String)
			obtained[purchased_ring.get("name", "") as String] = true

	var groups: Dictionary = {"common": [], "rare": [], "epic": [], "legendary": []}
	for e in _collectible_ring_entries():
		var d: Dictionary = e as Dictionary
		var rr: String = d.get("rarity", "common") as String
		(groups[rr] as Array).append(d)

	for rarity in ["common", "rare", "epic", "legendary"]:
		var items: Array = groups.get(rarity, []) as Array
		if items.is_empty():
			continue
		parent.add_child(_make_rarity_header(rarity, RingStore.RARITY_COLORS.get(rarity, Color(0.8, 0.8, 0.8)) as Color))
		for item in items:
			var d2: Dictionary = item as Dictionary
			var ring_name: String = d2.get("name", "Ring") as String
			parent.add_child(_make_collectible_card("ring", d2, obtained.has(ring_name)))

func _collectible_ring_entries() -> Array:
	var out: Array = []
	for e in RingStore.RING_POOL:
		out.append(_normalize_collectible_ring_entry((e as Dictionary).duplicate(true)))
	for product_id in PurchaseStore.RING_PRODUCTS.keys():
		out.append(_normalize_collectible_ring_entry(PurchaseStore.ring_product_to_ring(product_id as String)))
	return out

func _normalize_collectible_ring_entry(ring: Dictionary) -> Dictionary:
	var normalized: Dictionary = ring.duplicate(true)
	if not normalized.has("value"):
		var vr: Array = normalized.get("value_range", []) as Array
		if vr.size() >= 2:
			normalized["value"] = (float(vr[0]) + float(vr[1])) * 0.5
		elif vr.size() == 1:
			normalized["value"] = float(vr[0])
		else:
			normalized["value"] = 0.0
	if not normalized.has("tier"):
		normalized["tier"] = 1
	return normalized

func _fill_artifact_cards(parent: VBoxContainer) -> void:
	var obtained: Dictionary = {}
	for a in ArtifactStore.load_stash(account_username):
		obtained[(a as Dictionary).get("name", "") as String] = true

	var groups: Dictionary = {"common": [], "rare": [], "epic": [], "legendary": []}
	for e in ArtifactStore.ARTIFACT_POOL:
		var d: Dictionary = e as Dictionary
		var rr: String = d.get("rarity", "rare") as String
		(groups[rr] as Array).append(d)

	for rarity in ["common", "rare", "epic", "legendary"]:
		var items: Array = groups.get(rarity, []) as Array
		if items.is_empty():
			continue
		parent.add_child(_make_rarity_header(rarity, ArtifactStore.RARITY_COLORS.get(rarity, Color(0.8, 0.8, 0.8)) as Color))
		for item in items:
			var d2: Dictionary = item as Dictionary
			var name: String = d2.get("name", "Artifact") as String
			parent.add_child(_make_collectible_card("artifact", d2, obtained.has(name)))

func _set_current_tab(tab_id: String) -> void:
	_current_tab = tab_id
	if _rings_scroll != null:
		_rings_scroll.visible = tab_id == "rings"
	if _artifacts_scroll != null:
		_artifacts_scroll.visible = tab_id == "artifacts"
	for key in _tab_buttons.keys():
		var btn: Button = _tab_buttons[key] as Button
		if btn == null:
			continue
		var active: bool = key == tab_id
		_apply_tab_button_style(btn, active)

func _build_collectible_scroll(width: float, height: float) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.custom_minimum_size = Vector2(width, height)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	return scroll

func _scroll_content_box(scroll: ScrollContainer, width: float) -> VBoxContainer:
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	content.custom_minimum_size = Vector2(width, 0)
	scroll.add_child(content)
	return content

func _make_tab_button(title: String, tab_id: String) -> Button:
	var btn := Button.new()
	btn.text = title
	btn.icon = null
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.clip_text = false
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 78)
	btn.add_theme_font_size_override("font_size", 28)
	btn.pressed.connect(func() -> void: _set_current_tab(tab_id))
	return btn

func _apply_tab_button_style(btn: Button, active: bool) -> void:
	var border_col: Color = Color(0.88, 0.68, 0.22, 0.98) if active else Color(0.42, 0.36, 0.24, 0.88)
	var bg_col: Color = Color(0.20, 0.14, 0.06, 0.96) if active else Color(0.04, 0.08, 0.14, 0.92)
	var font_col: Color = Color(0.98, 0.83, 0.40) if active else Color(0.80, 0.82, 0.90)
	var style := _ornate_panel_style(border_col, bg_col, 18, 2)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = bg_col.lightened(0.08)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", font_col)

func _make_rarity_header(rarity: String, accent: Color) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var left_diamond := Label.new()
	left_diamond.text = "<>"
	left_diamond.add_theme_font_size_override("font_size", 18)
	left_diamond.add_theme_color_override("font_color", accent)
	row.add_child(left_diamond)

	var head := Label.new()
	head.text = rarity.to_upper()
	head.add_theme_font_size_override("font_size", 28)
	head.add_theme_color_override("font_color", accent)
	row.add_child(head)

	var line := ColorRect.new()
	line.color = Color(accent.r, accent.g, accent.b, 0.55)
	line.custom_minimum_size = Vector2(0, 2)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(line)

	return row

func _make_collectible_card(item_type: String, data: Dictionary, obtained: bool) -> Control:
	var rarity: String = String(data.get("rarity", "common")).to_lower()
	var accent: Color = RingStore.RARITY_COLORS.get(rarity, Color(0.72, 0.72, 0.72)) as Color if item_type == "ring" else ArtifactStore.RARITY_COLORS.get(rarity, Color(0.72, 0.72, 0.72)) as Color
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 110)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := _ornate_panel_style(Color(accent.r, accent.g, accent.b, 0.52), Color(0.05, 0.08, 0.14, 0.94), 14, 1)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", style)
	card.modulate = Color(0.74, 0.74, 0.78, 0.86) if not obtained else Color.WHITE

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)

	var thumb: Control = _ring_thumb(data, obtained) if item_type == "ring" else _artifact_thumb(data, obtained)
	thumb.custom_minimum_size = Vector2(64, 64)
	row.add_child(thumb)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	row.add_child(box)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	box.add_child(top_row)

	var name_lbl := Label.new()
	name_lbl.text = String(data.get("name", "Collectible"))
	name_lbl.add_theme_font_size_override("font_size", 36)
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(name_lbl)

	var tag_lbl := Label.new()
	tag_lbl.text = "OWNED" if obtained else "HIDDEN"
	tag_lbl.add_theme_font_size_override("font_size", 20)
	tag_lbl.add_theme_color_override("font_color", Color(0.98, 0.88, 0.68) if obtained else Color(0.76, 0.78, 0.82))
	tag_lbl.add_theme_stylebox_override("normal", _ornate_panel_style(Color(accent.r, accent.g, accent.b, 0.60), Color(0.12, 0.12, 0.14, 0.88), 8, 1))
	top_row.add_child(tag_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = _ring_inventory_desc(data) if item_type == "ring" else (_collectible_artifact_desc(data) if obtained else "???")
	desc_lbl.add_theme_font_size_override("font_size", 26)
	desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.88))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(desc_lbl)

	return card

func _ornate_panel_style(border_col: Color, bg_col: Color, radius: int, border_size: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(border_size)
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

func _apply_button_style(btn: Button, border_col: Color, bg_col: Color, font_col: Color, radius: int) -> void:
	var normal := _ornate_panel_style(border_col, bg_col, radius, 2)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg_col.lightened(0.08)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg_col.darkened(0.08)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", font_col)

func _ring_inventory_desc(ring: Dictionary) -> String:
	var attr: String = String(ring.get("attr", ""))
	var value: float = float(ring.get("value", 0.0))
	var vr: Array = ring.get("value_range", []) as Array
	var has_range: bool = vr.size() >= 2
	var min_v: float = float(vr[0]) if has_range else value
	var max_v: float = float(vr[1]) if has_range else value
	if attr in ["potion_drop_rate", "xp_bonus", "ring_drop_rate", "skill_dmg", "skill_cd", "aoe_radius", "projectile_spd", "crit_chance", "boss_dmg"]:
		if has_range:
			return "%s to %s %s" % [_format_percent_value(min_v), _format_percent_value(max_v), _pretty_stat_label(attr)]
		return "%s %s" % [_format_percent_value(value), _pretty_stat_label(attr)]
	if attr == "regen":
		if has_range:
			return "%s to %s Health per second" % [_format_signed_value(min_v, 1), _format_signed_value(max_v, 1)]
		return "+%.1f Health per second" % value
	if attr == "revive_once":
		return "Revive once"
	if attr == "timed_shield":
		return "Timed Shield"
	if has_range:
		return "%s to %s %s" % [_format_signed_value(min_v, 0), _format_signed_value(max_v, 0), _pretty_stat_label(attr)]
	return "+%.0f %s" % [value, _pretty_stat_label(attr)]

func _format_percent_value(value: float) -> String:
	var pct: float = value * 100.0
	if abs(pct) < 1.0 and abs(pct) > 0.0:
		return "%+.1f%%" % pct
	return "%+d%%" % int(round(pct))

func _format_signed_value(value: float, decimals: int) -> String:
	var fmt_value: String = String.num(value, decimals)
	if value >= 0.0:
		return "+%s" % fmt_value
	return fmt_value

func _pretty_stat_label(stat_key: String) -> String:
	match stat_key:
		"skill_dmg": return "Skill Damage"
		"skill_cd": return "Skill Cooldown"
		"projectile_spd": return "Projectile Speed"
		"projectile_dmg", "projectile_damage": return "Projectile Damage"
		"crit_chance": return "Critical Chance"
		"crit_dmg": return "Critical Damage"
		"xp_bonus": return "XP Bonus"
		"max_hp": return "Maximum Health"
		"max_hp_pct": return "Maximum Health"
		"regen": return "Health Regeneration"
		"timed_shield": return "Timed Shield"
		"luck": return "Luck"
		"ring_drop_rate": return "Ring Drop Rate"
		"potion_drop_rate": return "Potion Drop Rate"
		"aoe_radius": return "Area of Effect Radius"
		"boss_dmg": return "Boss Damage"
		_:
			return stat_key.replace("_", " ").capitalize()

func _collectible_artifact_desc(artifact: Dictionary) -> String:
	var base_desc: String = String(artifact.get("desc", "")).strip_edges()
	var extras: Array[String] = _collectible_artifact_special_lines(artifact)
	if extras.is_empty():
		return base_desc
	if base_desc.is_empty():
		return "\n".join(extras)
	return base_desc + "\n" + "\n".join(extras)

func _collectible_artifact_special_lines(artifact: Dictionary) -> Array[String]:
	var aid: String = String(artifact.get("id", "")).to_lower()
	var aname: String = String(artifact.get("name", "")).to_lower()
	if aid.find("capy_mystery_box") != -1 or aname.find("mystery box") != -1:
		return [
			"✦ Each run rolls 2 random tradeoff effects",
			"⚔ Skill Damage +12% or -10%, Maximum Health +12% or -10%",
			"⏩ Movement Speed +10% or -10%, Experience Bonus +15% or -10%",
		]
	if aid.find("wheel_of_fate") != -1 or aname.find("wheel of fate") != -1:
		return [
			"✦ Every 50 seconds: 1 random effect for 12 seconds",
			"⚔ Skill Damage +12% or -8%, Movement Speed +15% or -12%",
			"◴ Skill Cooldown -10% or +10%",
		]
	return []

func _ring_thumb(data: Dictionary, obtained: bool) -> Control:
	var tex := TextureRect.new()
	tex.custom_minimum_size = Vector2(64, 64)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if obtained:
		tex.texture = RingStore.ring_icon(data)
	if tex.texture == null:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(64, 64)
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.10, 0.12, 0.18)
		st.border_color = Color(0.42, 0.34, 0.18, 0.88)
		st.set_border_width_all(1)
		st.corner_radius_top_left = 12
		st.corner_radius_top_right = 12
		st.corner_radius_bottom_right = 12
		st.corner_radius_bottom_left = 12
		panel.add_theme_stylebox_override("panel", st)
		var lbl := Label.new()
		lbl.text = "?" if not obtained else "R"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.add_theme_font_size_override("font_size", 38)
		lbl.add_theme_color_override("font_color", Color(0.94, 0.84, 0.52))
		panel.add_child(lbl)
		return panel
	return tex

func _artifact_thumb(data: Dictionary, obtained: bool) -> Control:
	if obtained:
		var art_tex: Texture2D = ArtifactStore.artifact_icon(data)
		if art_tex != null:
			var tex := TextureRect.new()
			tex.texture = art_tex
			tex.custom_minimum_size = Vector2(64, 64)
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			return tex

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(64, 64)
	var st := StyleBoxFlat.new()
	st.bg_color = ArtifactStore.RARITY_COLORS.get(data.get("rarity", "rare"), Color(0.55, 0.55, 0.55)) as Color
	st.bg_color = st.bg_color.darkened(0.45)
	st.border_color = Color(0.44, 0.36, 0.18, 0.88)
	st.set_border_width_all(1)
	st.corner_radius_top_left = 12
	st.corner_radius_top_right = 12
	st.corner_radius_bottom_right = 12
	st.corner_radius_bottom_left = 12
	panel.add_theme_stylebox_override("panel", st)
	var lbl := Label.new()
	if obtained:
		var name: String = data.get("name", "Artifact") as String
		var words: PackedStringArray = name.split(" ", false)
		var initials: String = ""
		for w in words:
			if not w.is_empty():
				initials += w.substr(0, 1).to_upper()
			if initials.length() >= 2:
				break
		lbl.text = initials if not initials.is_empty() else "A"
	else:
		lbl.text = "?"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_size_override("font_size", 38)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.88))
	panel.add_child(lbl)
	return panel
