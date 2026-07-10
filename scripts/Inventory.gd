extends Node2D

signal inventory_confirmed(char_data: CharacterData)
signal back_to_select

var selected_character: CharacterData = null
var account_username: String = ""

var _char_id: String = ""
var _rings_equipped: Dictionary = {}
var _artifacts_equipped: Dictionary = {}
var _rings: Array = []
var _artifacts: Array = []
var _filter: String = "all"  # all | rings | artifacts
var _sort_mode: String = "rarity"  # rarity | name | tier

var _view: Vector2 = Vector2.ZERO
var _info_lbl: Label
var _key_info_lbl: Label
var _bonus_grid: GridContainer
var _stash_grid: GridContainer
var _key_timer_tick: float = 0.0
var _filter_btns: Dictionary = {}
var _item_popup_layer: CanvasLayer = null
var _rings_count_lbl: Label
var _artifacts_count_lbl: Label
var _prep_bg: Texture2D = preload("res://assets/backgrounds/bg_preparation_stage.png")
var _all_filter_icon: Texture2D = preload("res://assets/icons/icon_all_filter.png")
var _ring_filter_icon: Texture2D = preload("res://assets/icons/icon_ring_filter.png")
var _artifact_filter_icon: Texture2D = preload("res://assets/icons/icon_artifact_filter.png")

var _ring_slot_btns: Array[Button] = []
var _artifact_slot_btns: Array[Button] = []

func _ready() -> void:
	_view = get_viewport_rect().size
	if selected_character != null:
		_char_id = String(selected_character.id)
	_rings_equipped = RingStore.get_equipped_rings(account_username, _char_id)
	_artifacts_equipped = ArtifactStore.get_equipped_artifacts(account_username, _char_id)
	_rings = RingStore.load_stash(account_username)
	_artifacts = ArtifactStore.load_stash(account_username)
	_build_ui()

func _build_ui() -> void:
	var mx: float = 28.0
	var cw: float = _view.x - mx * 2.0

	var bg := TextureRect.new()
	bg.texture = _prep_bg
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = _view
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var vignette := PanelContainer.new()
	vignette.position = Vector2(6, 6)
	vignette.size = _view - Vector2(12, 12)
	vignette.add_theme_stylebox_override("panel", _make_panel_style(Color(0.34, 0.24, 0.08, 0.75), Color(0.0, 0.0, 0.0, 0.0), 24, 4))
	add_child(vignette)

	var top_glow := ColorRect.new()
	top_glow.color = Color(0.18, 0.12, 0.04, 0.20)
	top_glow.position = Vector2(0, 0)
	top_glow.size = Vector2(_view.x, _view.y * 0.33)
	add_child(top_glow)

	var mid_tint := ColorRect.new()
	mid_tint.color = Color(0.02, 0.10, 0.12, 0.18)
	mid_tint.position = Vector2(0, _view.y * 0.20)
	mid_tint.size = Vector2(_view.x, _view.y * 0.58)
	add_child(mid_tint)

	var torch_glow_l := ColorRect.new()
	torch_glow_l.color = Color(0.96, 0.52, 0.14, 0.13)
	torch_glow_l.position = Vector2(8, 92)
	torch_glow_l.size = Vector2(46, 140)
	add_child(torch_glow_l)

	var torch_glow_r := ColorRect.new()
	torch_glow_r.color = Color(0.96, 0.52, 0.14, 0.13)
	torch_glow_r.position = Vector2(_view.x - 54, 92)
	torch_glow_r.size = Vector2(46, 140)
	add_child(torch_glow_r)

	var title_panel := PanelContainer.new()
	title_panel.position = Vector2(mx + 70.0, 14)
	title_panel.size = Vector2(cw - 140.0, 96)
	title_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.72, 0.53, 0.16, 0.98), Color(0.08, 0.07, 0.05, 0.95), 16, 3))
	add_child(title_panel)

	var title := Label.new()
	title.text = "INVENTORY"
	title.add_theme_font_size_override("font_size", 70)
	title.add_theme_color_override("font_color", Color(0.98, 0.80, 0.24))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_panel.add_child(title)

	var char_lbl := Label.new()
	char_lbl.text = selected_character.display_name if selected_character else "Adventurer"
	char_lbl.add_theme_font_size_override("font_size", 26)
	char_lbl.add_theme_color_override("font_color", Color(0.84, 0.70, 0.46))
	char_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	char_lbl.position = Vector2(mx, 126)
	char_lbl.size = Vector2(cw, 34)
	add_child(char_lbl)

	var root := VBoxContainer.new()
	root.position = Vector2(mx, 180)
	root.size = Vector2(cw, _view.y - 286)
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	var equipped_panel := PanelContainer.new()
	equipped_panel.custom_minimum_size = Vector2(0, clampf(_view.y * 0.28, 300.0, 430.0))
	equipped_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.70, 0.52, 0.16, 0.95), Color(0.03, 0.08, 0.10, 0.97), 20, 3))
	root.add_child(equipped_panel)

	var equipped_box := VBoxContainer.new()
	equipped_box.add_theme_constant_override("separation", 8)
	equipped_panel.add_child(equipped_box)

	var eq_lbl := Label.new()
	eq_lbl.text = "EQUIPPED"
	eq_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eq_lbl.add_theme_font_size_override("font_size", 58)
	eq_lbl.add_theme_color_override("font_color", Color(0.98, 0.82, 0.34))
	equipped_box.add_child(eq_lbl)

	var type_row := HBoxContainer.new()
	type_row.add_theme_constant_override("separation", 12)
	equipped_box.add_child(type_row)

	var ring_counter_wrap := HBoxContainer.new()
	ring_counter_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ring_counter_wrap.add_theme_constant_override("separation", 8)
	ring_counter_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	type_row.add_child(ring_counter_wrap)

	var ring_counter_icon := TextureRect.new()
	ring_counter_icon.texture = _ring_filter_icon
	ring_counter_icon.custom_minimum_size = Vector2(34, 34)
	ring_counter_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ring_counter_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ring_counter_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring_counter_wrap.add_child(ring_counter_icon)

	_rings_count_lbl = Label.new()
	_rings_count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_rings_count_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_rings_count_lbl.add_theme_font_size_override("font_size", 40)
	_rings_count_lbl.add_theme_color_override("font_color", Color(0.90, 0.76, 0.36))
	ring_counter_wrap.add_child(_rings_count_lbl)

	var artifact_counter_wrap := HBoxContainer.new()
	artifact_counter_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	artifact_counter_wrap.add_theme_constant_override("separation", 8)
	artifact_counter_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	type_row.add_child(artifact_counter_wrap)

	var artifact_counter_icon := TextureRect.new()
	artifact_counter_icon.texture = _artifact_filter_icon
	artifact_counter_icon.custom_minimum_size = Vector2(34, 34)
	artifact_counter_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artifact_counter_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artifact_counter_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artifact_counter_wrap.add_child(artifact_counter_icon)

	_artifacts_count_lbl = Label.new()
	_artifacts_count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_artifacts_count_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_artifacts_count_lbl.add_theme_font_size_override("font_size", 40)
	_artifacts_count_lbl.add_theme_color_override("font_color", Color(0.90, 0.76, 0.36))
	artifact_counter_wrap.add_child(_artifacts_count_lbl)

	var equipped_row := HBoxContainer.new()
	equipped_row.add_theme_constant_override("separation", 12)
	equipped_box.add_child(equipped_row)
	for i in 2:
		var rb := _make_slot_button()
		var ridx: int = i
		rb.pressed.connect(func() -> void: _on_ring_slot_pressed(ridx))
		equipped_row.add_child(rb)
		_ring_slot_btns.append(rb)
	for i in 2:
		var ab := _make_slot_button()
		var aidx: int = i
		ab.pressed.connect(func() -> void: _on_artifact_slot_pressed(aidx))
		equipped_row.add_child(ab)
		_artifact_slot_btns.append(ab)

	_info_lbl = Label.new()
	_info_lbl.text = "Tap an item in stash to equip. Tap equipped cards to unequip."
	_info_lbl.add_theme_font_size_override("font_size", 22)
	_info_lbl.add_theme_color_override("font_color", Color(0.80, 0.70, 0.52))
	_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD

	_key_info_lbl = Label.new()
	_key_info_lbl.add_theme_font_size_override("font_size", 24)
	_key_info_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.34))

	var status_panel := PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.70, 0.52, 0.18, 0.92), Color(0.04, 0.06, 0.09, 0.97), 14, 2))
	root.add_child(status_panel)

	var status_box := VBoxContainer.new()
	status_box.add_theme_constant_override("separation", 4)
	status_panel.add_child(status_box)
	status_box.add_child(_info_lbl)
	status_box.add_child(_key_info_lbl)

	var stash_panel := PanelContainer.new()
	stash_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stash_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.70, 0.52, 0.16, 0.95), Color(0.03, 0.08, 0.10, 0.97), 20, 3))
	root.add_child(stash_panel)

	var stash_box := VBoxContainer.new()
	stash_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stash_box.add_theme_constant_override("separation", 8)
	stash_panel.add_child(stash_box)

	var stash_lbl := Label.new()
	stash_lbl.text = "INVENTORY STASH"
	stash_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stash_lbl.add_theme_font_size_override("font_size", 52)
	stash_lbl.add_theme_color_override("font_color", Color(0.94, 0.74, 0.32))
	stash_box.add_child(stash_lbl)

	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 10)
	stash_box.add_child(filter_row)
	for f in ["all", "rings", "artifacts"]:
		var btn := Button.new()
		if f == "all":
			btn.text = "All"
			btn.icon = _all_filter_icon
			btn.expand_icon = true
			btn.add_theme_constant_override("icon_max_width", 34)
			btn.add_theme_constant_override("h_separation", 1)
		elif f == "rings":
			btn.text = "Rings"
			btn.icon = _ring_filter_icon
			btn.expand_icon = true
			btn.add_theme_constant_override("icon_max_width", 34)
			btn.add_theme_constant_override("h_separation", 1)
		else:
			btn.text = "Artifacts"
			btn.icon = _artifact_filter_icon
			btn.expand_icon = true
			btn.add_theme_constant_override("icon_max_width", 34)
			btn.add_theme_constant_override("h_separation", 1)
		btn.custom_minimum_size = Vector2(210, 56)
		btn.add_theme_font_size_override("font_size", 30)
		btn.pressed.connect(func() -> void:
			_filter = f
			_update_filter_buttons()
			_rebuild_stash()
		)
		filter_row.add_child(btn)
		_filter_btns[f] = btn

	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_row.add_child(fill)

	var sort_btn := OptionButton.new()
	sort_btn.custom_minimum_size = Vector2(220, 56)
	sort_btn.add_theme_font_size_override("font_size", 30)
	sort_btn.add_item("Rarity")
	sort_btn.add_item("Name")
	sort_btn.add_item("Tier")
	sort_btn.item_selected.connect(func(idx: int) -> void:
		match idx:
			0:
				_sort_mode = "rarity"
			1:
				_sort_mode = "name"
			2:
				_sort_mode = "tier"
			_:
				_sort_mode = "rarity"
		_rebuild_stash()
	)
	var sort_normal := _make_panel_style(Color(0.68, 0.52, 0.18, 0.9), Color(0.06, 0.05, 0.08, 0.96), 10, 2)
	sort_normal.content_margin_right = 28
	var sort_hover := sort_normal.duplicate() as StyleBoxFlat
	sort_hover.bg_color = sort_normal.bg_color.lightened(0.10)
	var sort_pressed := sort_normal.duplicate() as StyleBoxFlat
	sort_pressed.bg_color = sort_normal.bg_color.darkened(0.08)
	var sort_focus := sort_normal.duplicate() as StyleBoxFlat
	sort_focus.border_color = Color(0.92, 0.74, 0.28, 0.98)
	sort_focus.set_border_width_all(3)
	sort_btn.add_theme_stylebox_override("normal", sort_normal)
	sort_btn.add_theme_stylebox_override("hover", sort_hover)
	sort_btn.add_theme_stylebox_override("pressed", sort_pressed)
	sort_btn.add_theme_stylebox_override("focus", sort_focus)
	var sort_arrow: Texture2D = sort_btn.get_theme_icon("arrow", "OptionButton")
	if sort_arrow != null:
		var arrow_img: Image = sort_arrow.get_image()
		if arrow_img != null and not arrow_img.is_empty():
			arrow_img.resize(30, 30, Image.INTERPOLATE_LANCZOS)
			var big_arrow := ImageTexture.create_from_image(arrow_img)
			sort_btn.add_theme_icon_override("arrow", big_arrow)
	sort_btn.add_theme_constant_override("arrow_margin", 14)
	sort_btn.add_theme_color_override("font_color", Color(0.95, 0.82, 0.58))
	var sort_popup: PopupMenu = sort_btn.get_popup()
	sort_popup.add_theme_font_size_override("font_size", 30)
	sort_popup.add_theme_stylebox_override("panel", _make_panel_style(Color(0.68, 0.52, 0.18, 0.92), Color(0.05, 0.05, 0.08, 0.98), 10, 2))
	filter_row.add_child(sort_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stash_box.add_child(scroll)

	_stash_grid = GridContainer.new()
	_stash_grid.columns = clampi(int(floor(cw / 208.0)), 3, 6)
	_stash_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stash_grid.add_theme_constant_override("h_separation", 12)
	_stash_grid.add_theme_constant_override("v_separation", 12)
	_stash_grid.custom_minimum_size = Vector2(cw - 6.0, 0.0)
	scroll.add_child(_stash_grid)

	var bottom := HBoxContainer.new()
	bottom.position = Vector2(mx, _view.y - 90)
	bottom.size = Vector2(cw, 74)
	bottom.add_theme_constant_override("separation", 12)
	add_child(bottom)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(260, 74)
	back_btn.add_theme_font_size_override("font_size", 34)
	_apply_button_skin(back_btn, Color(0.56, 0.40, 0.14, 0.9), Color(0.10, 0.08, 0.06), Color(0.95, 0.86, 0.70))
	back_btn.pressed.connect(func() -> void: back_to_select.emit())
	bottom.add_child(back_btn)

	var store_btn := Button.new()
	store_btn.text = "Store"
	store_btn.custom_minimum_size = Vector2(260, 74)
	store_btn.add_theme_font_size_override("font_size", 30)
	_apply_button_skin(store_btn, Color(0.56, 0.40, 0.14, 0.9), Color(0.10, 0.08, 0.06), Color(0.95, 0.86, 0.70))
	store_btn.pressed.connect(_open_store)
	bottom.add_child(store_btn)

	var bottom_fill := Control.new()
	bottom_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(bottom_fill)

	var play_btn := Button.new()
	play_btn.text = "Play"
	play_btn.custom_minimum_size = Vector2(320, 74)
	play_btn.add_theme_font_size_override("font_size", 36)
	_apply_button_skin(play_btn, Color(0.98, 0.82, 0.14, 0.98), Color(0.42, 0.26, 0.08), Color(0.02, 0.02, 0.02), 3)
	play_btn.pressed.connect(func() -> void: inventory_confirmed.emit(selected_character))
	bottom.add_child(play_btn)

	_update_filter_buttons()
	_refresh_slots()
	_update_key_info()
	_rebuild_stash()

func _process(delta: float) -> void:
	_key_timer_tick += delta
	if _key_timer_tick >= 1.0:
		_key_timer_tick = 0.0
		_update_key_info()

func _make_slot_button() -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 232)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 1)
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.clip_text = true
	return btn

func _refresh_slots() -> void:
	for i in 2:
		var rr = _rings_equipped.get("slot_%d" % i, null)
		_refresh_slot_card(_ring_slot_btns[i], "ring", i, rr)
	for i in 2:
		var aa = _artifacts_equipped.get("slot_%d" % i, null)
		_refresh_slot_card(_artifact_slot_btns[i], "artifact", i, aa)
	_refresh_equipped_counts()

func _refresh_slot_card(btn: Button, item_type: String, slot: int, item: Variant) -> void:
	for child in btn.get_children():
		child.queue_free()

	var wrap := MarginContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.offset_left = 10
	wrap.offset_top = 10
	wrap.offset_right = -10
	wrap.offset_bottom = -10
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(wrap)

	var body := HBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("separation", 10)
	wrap.add_child(body)

	var has_item: bool = item != null and typeof(item) == TYPE_DICTIONARY
	if not has_item:
		var empty_labels := VBoxContainer.new()
		empty_labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
		empty_labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_child(empty_labels)

		var empty_title := Label.new()
		empty_title.text = "Empty Slot"
		empty_title.add_theme_font_size_override("font_size", 34)
		empty_title.add_theme_color_override("font_color", Color(0.70, 0.66, 0.58))
		empty_labels.add_child(empty_title)

		var empty_desc := Label.new()
		empty_desc.text = "Equip a %s to activate this slot." % item_type
		empty_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty_desc.add_theme_font_size_override("font_size", 24)
		empty_desc.add_theme_color_override("font_color", Color(0.58, 0.54, 0.48))
		empty_labels.add_child(empty_desc)

		var empty_style := _make_panel_style(Color(0.44, 0.34, 0.16, 0.85), Color(0.04, 0.05, 0.08, 0.95), 14, 2)
		btn.add_theme_stylebox_override("normal", empty_style)
		btn.add_theme_stylebox_override("hover", empty_style)
		btn.add_theme_stylebox_override("pressed", empty_style)
		return

	var data: Dictionary = item as Dictionary
	var rarity: String = String(data.get("rarity", "common")).to_lower()
	var rarity_col: Color = _rarity_color(rarity)
	var card_style := _make_panel_style(Color(rarity_col.r, rarity_col.g, rarity_col.b, 0.92), Color(0.04, 0.05, 0.09, 0.97), 14, 2)
	var hover_style := card_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = card_style.bg_color.lightened(0.08)
	btn.add_theme_stylebox_override("normal", card_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", card_style)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 6)
	body.add_child(content)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(top)

	var tier_lbl := Label.new()
	tier_lbl.text = "T%d" % int(data.get("tier", 1))
	tier_lbl.add_theme_font_size_override("font_size", 24)
	tier_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.74))
	top.add_child(tier_lbl)

	var item_name := Label.new()
	item_name.text = String(data.get("name", item_type.capitalize()))
	item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	item_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_name.add_theme_font_size_override("font_size", 20)
	item_name.add_theme_color_override("font_color", Color(0.90, 0.82, 0.68))
	top.add_child(item_name)

	var icon_rect := TextureRect.new()
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(0, 164)
	icon_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_rect.texture = RingStore.ring_icon(data) if item_type == "ring" else _artifact_icon(data)
	content.add_child(icon_rect)

func _equipped_count(equipped: Dictionary) -> int:
	var count: int = 0
	for i in 2:
		if equipped.get("slot_%d" % i, null) != null:
			count += 1
	return count

func _refresh_equipped_counts() -> void:
	if _rings_count_lbl != null:
		_rings_count_lbl.text = "RINGS (%d/2)" % _equipped_count(_rings_equipped)
	if _artifacts_count_lbl != null:
		_artifacts_count_lbl.text = "ARTIFACTS (%d/2)" % _equipped_count(_artifacts_equipped)

func _refresh_bonus_panel() -> void:
	if _bonus_grid == null:
		return
	for c in _bonus_grid.get_children():
		c.queue_free()

	var bonuses: Array = _collect_current_bonuses()
	while bonuses.size() < 4:
		bonuses.append({"label": "-", "value": "0", "color": Color(0.42, 0.38, 0.30)})

	for i in 4:
		var b: Dictionary = bonuses[i] as Dictionary
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 96)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.34, 0.27, 0.12, 0.9), Color(0.05, 0.05, 0.04, 0.95), 10, 2))
		_bonus_grid.add_child(card)

		var vb := VBoxContainer.new()
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(vb)

		var l1 := Label.new()
		l1.text = b.get("label", "") as String
		l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l1.add_theme_font_size_override("font_size", 24)
		l1.add_theme_color_override("font_color", Color(0.88, 0.80, 0.66))
		vb.add_child(l1)

		var l2 := Label.new()
		l2.text = b.get("value", "") as String
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l2.add_theme_font_size_override("font_size", 34)
		l2.add_theme_color_override("font_color", b.get("color", Color(0.88, 0.72, 0.32)) as Color)
		vb.add_child(l2)

func _collect_current_bonuses() -> Array:
	var totals: Dictionary = {}
	for i in 2:
		var ring_item = _rings_equipped.get("slot_%d" % i, null)
		if ring_item != null and typeof(ring_item) == TYPE_DICTIONARY:
			var ring: Dictionary = ring_item as Dictionary
			var attr: String = String(ring.get("attr", ""))
			if attr.is_empty():
				continue
			var value: float = float(ring.get("value", 0.0))
			totals[attr] = float(totals.get(attr, 0.0)) + value
	for i in 2:
		var art_item = _artifacts_equipped.get("slot_%d" % i, null)
		if art_item != null and typeof(art_item) == TYPE_DICTIONARY:
			var art: Dictionary = art_item as Dictionary
			var effects: Dictionary = art.get("effects", {}) as Dictionary
			for key in effects.keys():
				totals[key] = float(totals.get(key, 0.0)) + float(effects[key])

	var ordered_keys: Array = ["skill_dmg", "projectile_spd", "projectile_damage", "revive_once", "xp_bonus", "crit_chance", "max_hp_pct"]
	var out: Array = []
	for key in ordered_keys:
		if not totals.has(key):
			continue
		out.append(_bonus_chip_data(key, float(totals[key])))
		if out.size() >= 4:
			break
	return out

func _bonus_chip_data(key: String, value: float) -> Dictionary:
	match key:
		"skill_dmg":
			return {"label": "Skill Damage", "value": "%+d%%" % int(round(value * 100.0)), "color": Color(1.0, 0.34, 0.30)}
		"projectile_spd":
			return {"label": "Projectile Speed", "value": "%+d%%" % int(round(value * 100.0)), "color": Color(0.28, 0.72, 1.0)}
		"projectile_damage":
			return {"label": "Projectile Damage", "value": "%+d%%" % int(round(value * 100.0)), "color": Color(1.0, 0.58, 0.18)}
		"revive_once":
			return {"label": "Revive", "value": "+%d" % int(round(value)), "color": Color(0.42, 0.90, 0.36)}
		"xp_bonus":
			return {"label": "XP Bonus", "value": "%+d%%" % int(round(value * 100.0)), "color": Color(0.76, 0.58, 1.0)}
		"crit_chance":
			return {"label": "Crit Chance", "value": "%+d%%" % int(round(value * 100.0)), "color": Color(1.0, 0.40, 0.42)}
		"max_hp_pct":
			return {"label": "Max HP", "value": "%+d%%" % int(round(value * 100.0)), "color": Color(0.30, 0.92, 0.50)}
		_:
			return {"label": key.capitalize(), "value": "%+d" % int(round(value)), "color": Color(0.92, 0.78, 0.34)}

func _artifact_bonus_text(artifact: Dictionary) -> String:
	var effects: Dictionary = artifact.get("effects", {}) as Dictionary
	if effects.is_empty():
		return "No bonus"
	var pieces: Array[String] = []
	for k in effects.keys():
		var key: String = String(k)
		var value: float = float(effects[k])
		pieces.append("%s %s" % [_format_stat_value(key, value), _pretty_stat_label(key)])
	return " | ".join(pieces)

func _item_stat_lines(item_type: String, data: Dictionary, max_lines: int = 3) -> Array[String]:
	var lines: Array[String] = []
	if item_type == "ring":
		var attr: String = String(data.get("attr", ""))
		lines.append("%s %s" % [_stat_icon(attr), _ring_bonus_text(data)])
		if attr == "skill_dmg":
			var ring_name_l: String = String(data.get("name", "")).to_lower()
			var ring_id_l: String = String(data.get("id", "")).to_lower()
			var is_warlock_crest: bool = ring_name_l.find("warlord") != -1 or ring_name_l.find("warlock") != -1 or ring_id_l.find("warlords_crest") != -1 or ring_id_l.find("warlock_crest") != -1
			if not is_warlock_crest:
				lines.append("%s -8%% %s" % [_stat_icon("skill_cd"), _pretty_stat_label("skill_cd")])
				lines.append("%s +5%% %s" % [_stat_icon("crit_chance"), _pretty_stat_label("crit_chance")])
		elif attr == "revive_once":
			lines.append("%s Restore 25%% Health" % _stat_icon("revive_hp_pct"))
			lines.append("%s 3 seconds Timed Shield" % _stat_icon("timed_shield"))
	else:
		var special_lines: Array[String] = _artifact_special_description_lines(data)
		if not special_lines.is_empty():
			for s in special_lines:
				lines.append(s)
		var desc_text: String = String(data.get("desc", "")).strip_edges()
		if not desc_text.is_empty():
			var raw_lines: PackedStringArray = desc_text.split("\n", false)
			for raw in raw_lines:
				var line_text: String = String(raw).strip_edges()
				if not line_text.is_empty():
					lines.append("✦ %s" % line_text)
		else:
			var effects: Dictionary = data.get("effects", {}) as Dictionary
			for key in effects.keys():
				var stat_key: String = String(key)
				var stat_value: float = float(effects[key])
				var text_value: String = _format_stat_value(stat_key, stat_value)
				lines.append("%s %s %s" % [_stat_icon(stat_key), text_value, _pretty_stat_label(stat_key)])

	if lines.is_empty():
		lines.append("✦ %s" % (data.get("desc", "No bonus") as String))

	if lines.size() > max_lines:
		lines = lines.slice(0, max_lines)
	return lines

func _artifact_special_description_lines(artifact: Dictionary) -> Array[String]:
	var aid: String = String(artifact.get("id", "")).to_lower()
	var aname: String = String(artifact.get("name", "")).to_lower()
	if aid.find("capy_mystery_box") != -1 or aname.find("mystery box") != -1:
		return [
			"%s Each run rolls 2 random tradeoff effects" % _stat_icon("chaos_mystery_box"),
			"%s Skill Damage +12%% or -10%%, Maximum Health +12%% or -10%%" % _stat_icon("skill_dmg"),
			"%s Movement Speed +10%% or -10%%, Experience Bonus +15%% or -10%%" % _stat_icon("move_speed_mul"),
		]
	if aid.find("wheel_of_fate") != -1 or aname.find("wheel of fate") != -1:
		return [
			"%s Every 50 seconds: 1 random effect for 12 seconds" % _stat_icon("chaos_wheel"),
			"%s Skill Damage +12%% or -8%%, Movement Speed +15%% or -12%%" % _stat_icon("skill_dmg"),
			"%s Skill Cooldown -10%% or +10%%" % _stat_icon("skill_cd"),
		]
	return []

func _pretty_stat_label(stat_key: String) -> String:
	match stat_key:
		"skill_dmg": return "Skill Damage"
		"skill_cd": return "Skill Cooldown"
		"crit_chance": return "Critical Chance"
		"crit_dmg": return "Critical Damage"
		"revive_once": return "Revive Once"
		"revive_hp_pct": return "Restore Health"
		"projectile_spd": return "Projectile Speed"
		"projectile_dmg", "projectile_damage": return "Projectile Damage"
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
		"freeze_duration": return "Freeze Duration"
		"ice_dmg": return "Ice Damage"
		"lightning_chain": return "Lightning Chain"
		"lightning_dmg": return "Lightning Damage"
		"burn_duration": return "Burn Duration"
		"lifesteal": return "Lifesteal"
		"healing_efficiency": return "Healing Effectiveness"
		"damage_taken_mul": return "Damage Taken"
		"enemy_hp_mul": return "Enemy Health"
		"move_speed_mul": return "Movement Speed"
		"pickup_radius": return "Pickup Radius"
		"projectile_homing": return "Projectile Homing"
		"proj_dup_chance": return "Projectile Duplication Chance"
		"regen_pulse_pct": return "Regeneration Pulse"
		"regen_pulse_interval": return "Regeneration Pulse Interval"
		"blink_interval": return "Blink Interval"
		"blink_dist": return "Blink Distance"
		"blink_iframes": return "Invulnerability Frames"
		"chaos_mystery_box": return "Chaos Mystery Effect"
		"chaos_wheel": return "Chaos Wheel Effect"
		"wheel_interval": return "Wheel Interval"
		"wheel_duration": return "Wheel Duration"
		_:
			return stat_key.replace("_", " ").capitalize()

func _format_stat_value(stat_key: String, stat_value: float) -> String:
	if stat_key in ["skill_dmg", "projectile_spd", "projectile_dmg", "projectile_damage", "max_hp_pct", "xp_bonus", "crit_chance", "crit_dmg", "luck", "ring_drop_rate", "damage_taken_mul", "enemy_hp_mul", "move_speed_mul", "healing_efficiency", "freeze_duration", "ice_dmg", "lightning_dmg", "burn_duration", "pickup_radius", "projectile_homing", "proj_dup_chance", "regen_pulse_pct", "potion_drop_rate", "aoe_radius", "boss_dmg"]:
		return _format_percent_value(stat_value)
	if stat_key in ["blink_interval", "wheel_interval", "wheel_duration", "regen_pulse_interval"]:
		return "%s seconds" % String.num(stat_value, 0)
	if stat_key == "blink_dist":
		return "%s meters" % String.num(stat_value / 37.5, 0)
	if stat_key in ["revive_once", "lightning_chain", "chaos_mystery_box", "chaos_wheel"]:
		return "+%d" % int(round(stat_value))
	if stat_key == "blink_iframes":
		return "%s seconds" % String.num(stat_value, 1)
	if stat_key == "regen":
		return "%s health per second" % String.num(stat_value, 1)
	return "%+s" % String.num(stat_value, 2)

func _format_percent_value(value: float) -> String:
	var pct: float = value * 100.0
	if abs(pct) < 1.0 and abs(pct) > 0.0:
		return "%+.1f%%" % pct
	return "%+d%%" % int(round(pct))

func _stat_icon(stat_key: String) -> String:
	match stat_key:
		"skill_dmg", "burn_duration": return "⚔"
		"skill_cd", "blink_interval", "wheel_interval", "wheel_duration": return "◴"
		"crit_chance", "crit_dmg": return "✶"
		"revive_once", "revive_hp_pct": return "❤"
		"timed_shield", "blink_iframes": return "🛡"
		"projectile_spd", "projectile_homing": return "➤"
		"projectile_dmg", "projectile_damage": return "✹"
		"xp_bonus": return "✦"
		"max_hp", "max_hp_pct", "regen", "regen_pulse_pct": return "❦"
		"luck", "ring_drop_rate": return "☘"
		"freeze_duration", "ice_dmg": return "❄"
		"lightning_chain", "lightning_dmg": return "⚡"
		"lifesteal": return "🩸"
		"pickup_radius": return "◎"
		"blink_dist": return "⇢"
		_:
			return "✦"

func _make_panel_style(border_col: Color, bg_col: Color, radius: int = 12, border_size: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(border_size)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.content_margin_left = 12
	sb.content_margin_top = 10
	sb.content_margin_right = 12
	sb.content_margin_bottom = 10
	return sb

func _apply_button_skin(btn: Button, border_col: Color, bg_col: Color, font_col: Color, border_size: int = 2) -> void:
	var normal := _make_panel_style(border_col, bg_col, 12, border_size)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg_col.lightened(0.12)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg_col.darkened(0.10)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", font_col)

func _apply_button_style_states(btn: Button, normal: StyleBoxFlat) -> void:
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.10)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.08)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"legendary":
			return Color(0.95, 0.72, 0.22)
		"epic":
			return Color(0.72, 0.42, 0.96)
		"rare":
			return Color(0.28, 0.66, 1.0)
		_:
			return Color(0.70, 0.66, 0.56)

func _update_filter_buttons() -> void:
	for key in _filter_btns.keys():
		var btn: Button = _filter_btns[key] as Button
		if btn == null:
			continue
		if key == _filter:
			var active_style := _make_panel_style(Color(0.90, 0.70, 0.24, 0.98), Color(0.24, 0.17, 0.05), 12, 2)
			_apply_button_style_states(btn, active_style)
			btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72))
		else:
			var idle_style := _make_panel_style(Color(0.54, 0.42, 0.18, 0.90), Color(0.05, 0.05, 0.08), 12, 2)
			_apply_button_style_states(btn, idle_style)
			btn.add_theme_color_override("font_color", Color(0.86, 0.74, 0.52))

func _update_key_info() -> void:
	if _key_info_lbl == null:
		return
	_key_info_lbl.text = "Door Keys: %d  |  Next key drop available in: %s" % [
		PurchaseStore.get_key_count(account_username),
		PurchaseStore.get_key_drop_remaining_text(account_username)
	]

func _ring_slots_full() -> bool:
	return _rings_equipped.get("slot_0", null) != null and _rings_equipped.get("slot_1", null) != null

func _artifact_slots_full() -> bool:
	return _artifacts_equipped.get("slot_0", null) != null and _artifacts_equipped.get("slot_1", null) != null

func _first_empty_slot(equipped: Dictionary) -> int:
	for i in 2:
		if equipped.get("slot_%d" % i, null) == null:
			return i
	return -1

func _is_item_equipped(equipped: Dictionary, item_id: String) -> bool:
	if item_id.is_empty():
		return false
	for i in 2:
		var item = equipped.get("slot_%d" % i, null)
		if item != null and typeof(item) == TYPE_DICTIONARY:
			var item_dict: Dictionary = item as Dictionary
			if String(item_dict.get("id", "")) == item_id:
				return true
	return false

func _on_ring_slot_pressed(slot: int) -> void:
	var ring = _rings_equipped.get("slot_%d" % slot, null)
	if ring == null:
		return
	if typeof(ring) == TYPE_DICTIONARY:
		_show_item_action_popup("ring", ring as Dictionary, true, slot, _ring_merge_count_in_stash(ring as Dictionary))

func _on_artifact_slot_pressed(slot: int) -> void:
	var art = _artifacts_equipped.get("slot_%d" % slot, null)
	if art == null:
		return
	if typeof(art) == TYPE_DICTIONARY:
		_show_item_action_popup("artifact", art as Dictionary, true, slot, 0)

func _rebuild_stash() -> void:
	for c in _stash_grid.get_children():
		c.queue_free()

	var rows: Array = []
	var grouped: Dictionary = {}

	if _filter == "all" or _filter == "rings":
		for r in _rings:
			var r_dict: Dictionary = r as Dictionary
			var r_id: String = String(r_dict.get("id", ""))
			if r_id.is_empty() or _is_item_equipped(_rings_equipped, r_id):
				continue
			_append_grouped_stash_item(grouped, "ring", r_dict)
	if _filter == "all" or _filter == "artifacts":
		for a in _artifacts:
			var a_dict: Dictionary = a as Dictionary
			var a_id: String = String(a_dict.get("id", ""))
			if a_id.is_empty() or _is_item_equipped(_artifacts_equipped, a_id):
				continue
			_append_grouped_stash_item(grouped, "artifact", a_dict)

	rows = grouped.values()

	if rows.is_empty():
		var empty := Label.new()
		empty.text = "No items in this filter."
		empty.add_theme_font_size_override("font_size", 30)
		empty.add_theme_color_override("font_color", Color(0.58, 0.54, 0.50))
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_stash_grid.add_child(empty)
		return

	rows.sort_custom(Callable(self, "_stash_row_sort"))

	for row_data in rows:
		var item_type: String = row_data["type"] as String
		var data: Dictionary = row_data["data"] as Dictionary
		var count: int = int(row_data.get("count", 1))
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 286)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 1)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.clip_text = true
		btn.text = ""
		# Allow drag gestures to bubble to ScrollContainer while keeping tap-to-open.
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		btn.add_child(_build_stash_card_content(item_type, data, count))

		var disabled: bool = false
		btn.disabled = disabled
		_style_stash_card(btn, item_type, data, disabled)
		if not disabled:
			btn.pressed.connect(func() -> void: _show_item_action_popup(item_type, data, false, -1, count))
		_stash_grid.add_child(btn)

func _append_grouped_stash_item(grouped: Dictionary, item_type: String, data: Dictionary) -> void:
	var item_id: String = String(data.get("id", ""))
	if item_id.is_empty():
		return
	var key: String = _stash_group_key(item_type, data)
	if not grouped.has(key):
		grouped[key] = {"type": item_type, "data": data, "count": 0}
	var current: Dictionary = grouped[key] as Dictionary
	current["count"] = int(current.get("count", 0)) + 1
	grouped[key] = current

func _stash_group_key(item_type: String, data: Dictionary) -> String:
	if item_type == "ring":
		var attr: String = String(data.get("attr", ""))
		var tier: int = int(data.get("tier", 1))
		var rarity: String = String(data.get("rarity", "common"))
		return "ring::%s::%d::%s" % [attr, tier, rarity]
	var id_raw: String = String(data.get("id", ""))
	var base_id: String = id_raw
	var idx: int = id_raw.rfind("_")
	if idx > 0:
		var suffix: String = id_raw.substr(idx + 1)
		if suffix.is_valid_int():
			base_id = id_raw.substr(0, idx)
	return "artifact::%s" % base_id

func _stash_row_sort(a: Dictionary, b: Dictionary) -> bool:
	var da: Dictionary = a.get("data", {}) as Dictionary
	var db: Dictionary = b.get("data", {}) as Dictionary
	var ta: String = String(a.get("type", ""))
	var tb: String = String(b.get("type", ""))
	var ra: String = String(da.get("rarity", "common")).to_lower()
	var rb: String = String(db.get("rarity", "common")).to_lower()
	var r_weight := {"legendary": 0, "epic": 1, "rare": 2, "common": 3}
	var wa: int = int(r_weight.get(ra, 4))
	var wb: int = int(r_weight.get(rb, 4))
	var na: String = String(da.get("name", ""))
	var nb: String = String(db.get("name", ""))
	var taier: int = int(da.get("tier", 1))
	var tbier: int = int(db.get("tier", 1))

	match _sort_mode:
		"name":
			if na != nb:
				return na < nb
			if wa != wb:
				return wa < wb
			if taier != tbier:
				return taier > tbier
			return ta < tb
		"tier":
			if taier != tbier:
				return taier > tbier
			if wa != wb:
				return wa < wb
			if na != nb:
				return na < nb
			return ta < tb
		_:
			if wa != wb:
				return wa < wb
			if taier != tbier:
				return taier > tbier
			if na != nb:
				return na < nb
			return ta < tb

func _build_stash_card_content(item_type: String, data: Dictionary, count: int) -> Control:
	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10
	content.offset_top = 10
	content.offset_right = -10
	content.offset_bottom = -10
	content.add_theme_constant_override("separation", 6)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var rarity: String = String(data.get("rarity", "common")).to_lower()
	var rarity_col: Color = _rarity_color(rarity)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(top)

	var tier_lbl := Label.new()
	tier_lbl.text = "T%d" % int(data.get("tier", 1))
	tier_lbl.add_theme_font_size_override("font_size", 24)
	tier_lbl.add_theme_color_override("font_color", rarity_col)
	top.add_child(tier_lbl)

	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(fill)

	if count > 1:
		var count_lbl := Label.new()
		count_lbl.text = "%d" % count
		count_lbl.add_theme_font_size_override("font_size", 30)
		count_lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.70))
		top.add_child(count_lbl)

	var icon_rect := TextureRect.new()
	icon_rect.texture = RingStore.ring_icon(data) if item_type == "ring" else _artifact_icon(data)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(0, 162)
	icon_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon_rect)

	var type_lbl := Label.new()
	type_lbl.text = "Ring" if item_type == "ring" else "Artifact"
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 24)
	type_lbl.add_theme_color_override("font_color", Color(0.92, 0.84, 0.66))
	type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(type_lbl)

	return content

func _style_stash_card(btn: Button, item_type: String, data: Dictionary, disabled: bool) -> void:
	var normal := StyleBoxFlat.new()
	var rarity_col: Color = _rarity_color(String(data.get("rarity", "common")).to_lower())
	if item_type == "ring":
		normal.bg_color = Color(0.09, 0.07, 0.12, 0.98)
		normal.border_color = Color(rarity_col.r, rarity_col.g, rarity_col.b, 0.94)
	else:
		normal.bg_color = Color(0.08, 0.08, 0.11, 0.98)
		normal.border_color = Color(rarity_col.r, rarity_col.g, rarity_col.b, 0.92)
	normal.set_border_width_all(3)
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_right = 12
	normal.corner_radius_bottom_left = 12
	normal.content_margin_left = 0
	normal.content_margin_right = 0
	normal.content_margin_top = 0
	normal.content_margin_bottom = 0

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.10)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.10)

	var disabled_style := normal.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color(0.18, 0.18, 0.18, 0.70)
	disabled_style.border_color = Color(0.42, 0.42, 0.42, 0.70)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled_style)
	btn.modulate = Color(0.68, 0.68, 0.68, 0.76) if disabled else Color.WHITE

func _artifact_icon(artifact: Dictionary) -> Texture2D:
	return ArtifactStore.artifact_icon(artifact)

func _show_item_action_popup(item_type: String, data: Dictionary, from_equipped: bool, slot: int, stash_count: int) -> void:
	_close_item_action_popup()
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	_item_popup_layer = layer

	var view: Vector2 = get_viewport_rect().size
	var blocker := ColorRect.new()
	blocker.color = Color(0.0, 0.0, 0.0, 0.62)
	blocker.size = view
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(blocker)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(min(980.0, view.x - 70.0), 0.0)
	panel.position = Vector2((view.x - panel.custom_minimum_size.x) * 0.5, view.y * 0.16)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.90, 0.68, 0.20, 0.98), Color(0.03, 0.04, 0.08, 0.99), 18, 3))
	layer.add_child(panel)

	blocker.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and not panel.get_global_rect().has_point(mb.global_position):
				_close_item_action_popup()
		elif event is InputEventScreenTouch:
			var st := event as InputEventScreenTouch
			if st.pressed and not panel.get_global_rect().has_point(st.global_position):
				_close_item_action_popup()
	)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	root.add_child(head)

	var tier_chip := Label.new()
	tier_chip.text = "T%d" % int(data.get("tier", 1))
	tier_chip.custom_minimum_size = Vector2(68, 56)
	tier_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tier_chip.add_theme_font_size_override("font_size", 34)
	tier_chip.add_theme_color_override("font_color", Color(0.95, 0.86, 1.0))
	tier_chip.add_theme_stylebox_override("normal", _make_panel_style(Color(0.66, 0.40, 0.86, 0.95), Color(0.10, 0.06, 0.18, 0.98), 10, 2))
	head.add_child(tier_chip)

	var head_fill := Control.new()
	head_fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(head_fill)

	var close_x := Button.new()
	close_x.text = "✕"
	close_x.custom_minimum_size = Vector2(58, 58)
	close_x.add_theme_font_size_override("font_size", 30)
	_apply_button_style_states(close_x, _make_panel_style(Color(0.86, 0.58, 0.18, 0.95), Color(0.24, 0.12, 0.02, 0.98), 30, 2))
	head.add_child(close_x)
	close_x.pressed.connect(_close_item_action_popup)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	root.add_child(body)

	var icon_wrap := PanelContainer.new()
	icon_wrap.custom_minimum_size = Vector2(300, 300)
	icon_wrap.add_theme_stylebox_override("panel", _make_panel_style(Color(0.86, 0.60, 0.18, 0.92), Color(0.08, 0.04, 0.10, 0.98), 14, 2))
	body.add_child(icon_wrap)

	var icon_rect := TextureRect.new()
	icon_rect.texture = RingStore.ring_icon(data) if item_type == "ring" else _artifact_icon(data)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = 10
	icon_rect.offset_top = 10
	icon_rect.offset_right = -10
	icon_rect.offset_bottom = -10
	icon_wrap.add_child(icon_rect)

	var info_col := VBoxContainer.new()
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.add_theme_constant_override("separation", 8)
	body.add_child(info_col)

	var name_lbl := Label.new()
	name_lbl.text = data.get("name", item_type.capitalize()) as String
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 56)
	name_lbl.add_theme_color_override("font_color", Color(0.80, 0.40, 0.96))
	info_col.add_child(name_lbl)

	var type_lbl := Label.new()
	type_lbl.text = "%s %s" % [String(data.get("rarity", "common")).capitalize(), item_type.capitalize()]
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	type_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	type_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	type_lbl.add_theme_font_size_override("font_size", 34)
	type_lbl.add_theme_color_override("font_color", Color(0.88, 0.70, 0.98))
	type_lbl.add_theme_stylebox_override("normal", _make_panel_style(Color(0.50, 0.26, 0.66, 0.95), Color(0.10, 0.06, 0.18, 0.98), 8, 2))
	info_col.add_child(type_lbl)

	var stat_lines: Array[String] = _item_stat_lines(item_type, data, 3)
	for line_text in stat_lines:
		var stat_lbl := Label.new()
		stat_lbl.text = line_text
		stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		stat_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		stat_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_lbl.add_theme_font_size_override("font_size", 42)
		stat_lbl.add_theme_color_override("font_color", Color(0.97, 0.90, 0.72))
		info_col.add_child(stat_lbl)

	var sep := ColorRect.new()
	sep.color = Color(0.66, 0.50, 0.18, 0.8)
	sep.custom_minimum_size = Vector2(0, 3)
	root.add_child(sep)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	root.add_child(button_row)

	var equipped_now: bool = _is_item_currently_equipped(item_type, data)
	var equip_btn := Button.new()
	equip_btn.text = "Unequip" if equipped_now else "Equip"
	equip_btn.custom_minimum_size = Vector2(0, 84)
	equip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_btn.add_theme_font_size_override("font_size", 46)
	_apply_button_style_states(equip_btn, _make_panel_style(Color(0.52, 0.86, 0.22, 0.96), Color(0.12, 0.26, 0.06, 0.98), 12, 2))
	button_row.add_child(equip_btn)

	if item_type == "ring":
		var is_legendary_ring: bool = String(data.get("rarity", "common")).to_lower() == "legendary"
		var can_merge: bool = stash_count >= 3 and not is_legendary_ring
		if from_equipped:
			can_merge = _ring_merge_count_in_stash(data) >= 3 and not is_legendary_ring
		var merge_btn := Button.new()
		merge_btn.text = "Merge"
		merge_btn.custom_minimum_size = Vector2(0, 84)
		merge_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		merge_btn.add_theme_font_size_override("font_size", 46)
		_apply_button_style_states(merge_btn, _make_panel_style(Color(0.22, 0.56, 0.94, 0.96), Color(0.06, 0.14, 0.30, 0.98), 12, 2))
		merge_btn.disabled = not can_merge
		button_row.add_child(merge_btn)

		var merge_note := Label.new()
		merge_note.text = "Legendary rings cannot be merged." if is_legendary_ring else "Need 3 ring of same tier and same type to merge."
		merge_note.add_theme_font_size_override("font_size", 21)
		merge_note.add_theme_color_override("font_color", Color(0.86, 0.74, 0.54))
		merge_note.autowrap_mode = TextServer.AUTOWRAP_WORD
		root.add_child(merge_note)

		merge_btn.pressed.connect(func() -> void:
			if is_legendary_ring:
				_info_lbl.text = "Legendary rings cannot be merged."
				return
			if _ring_merge_count_in_stash(data) < 3:
				_info_lbl.text = "Need 3 ring of same tier and same type to merge."
				return
			var merged: Dictionary = RingStore.merge_matching_from_stash(account_username, data)
			if merged.is_empty():
				_info_lbl.text = "Merge failed. Need 3 matching rings in stash."
			else:
				_info_lbl.text = "Merged into Tier %d %s." % [int(merged.get("tier", 1)), String(merged.get("name", "Ring"))]
			_rings = RingStore.load_stash(account_username)
			_refresh_slots()
			_rebuild_stash()
			_close_item_action_popup()
		)

	equip_btn.pressed.connect(func() -> void:
		if _is_item_currently_equipped(item_type, data):
			var eq_slot: int = _find_equipped_slot(item_type, data)
			if eq_slot >= 0:
				_unequip_item(item_type, eq_slot)
		else:
			if (item_type == "ring" and _ring_slots_full()) or (item_type == "artifact" and _artifact_slots_full()):
				_close_item_action_popup()
				_show_replace_slot_popup(item_type, data)
				return
			_equip_item_from_stash(item_type, data)
		_close_item_action_popup()
	)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(0, 58)
	close_btn.add_theme_font_size_override("font_size", 28)
	_apply_button_style_states(close_btn, _make_panel_style(Color(0.52, 0.42, 0.20, 0.90), Color(0.08, 0.08, 0.08, 0.98), 10, 2))
	root.add_child(close_btn)
	close_btn.pressed.connect(_close_item_action_popup)

func _show_replace_slot_popup(item_type: String, data: Dictionary) -> void:
	_close_item_action_popup()
	var layer := CanvasLayer.new()
	layer.layer = 91
	add_child(layer)
	_item_popup_layer = layer

	var view: Vector2 = get_viewport_rect().size
	var blocker := ColorRect.new()
	blocker.color = Color(0.0, 0.0, 0.0, 0.70)
	blocker.size = view
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(blocker)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(min(760.0, view.x - 90.0), 0.0)
	panel.position = Vector2((view.x - panel.custom_minimum_size.x) * 0.5, view.y * 0.28)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.88, 0.66, 0.20, 0.96), Color(0.05, 0.06, 0.09, 0.98), 16, 2))
	layer.add_child(panel)

	blocker.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and not panel.get_global_rect().has_point(mb.global_position):
				_close_item_action_popup()
		elif event is InputEventScreenTouch:
			var st := event as InputEventScreenTouch
			if st.pressed and not panel.get_global_rect().has_point(st.global_position):
				_close_item_action_popup()
	)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	var title := Label.new()
	title.text = "Choose Slot To Replace"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.96, 0.82, 0.30))
	root.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)

	for i in 2:
		var slot_btn := Button.new()
		slot_btn.text = "Slot %d" % (i + 1)
		slot_btn.custom_minimum_size = Vector2(0, 74)
		slot_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_btn.add_theme_font_size_override("font_size", 34)
		_apply_button_style_states(slot_btn, _make_panel_style(Color(0.72, 0.54, 0.18, 0.95), Color(0.14, 0.12, 0.08, 0.98), 12, 2))
		var idx: int = i
		slot_btn.pressed.connect(func() -> void:
			_replace_equipped_slot(item_type, idx, data)
			_close_item_action_popup()
		)
		row.add_child(slot_btn)

	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.custom_minimum_size = Vector2(0, 62)
	cancel.add_theme_font_size_override("font_size", 30)
	_apply_button_style_states(cancel, _make_panel_style(Color(0.52, 0.42, 0.20, 0.90), Color(0.08, 0.08, 0.08, 0.98), 10, 2))
	root.add_child(cancel)
	cancel.pressed.connect(_close_item_action_popup)

func _replace_equipped_slot(item_type: String, slot: int, data: Dictionary) -> void:
	if slot < 0 or slot > 1:
		return
	var item_id: String = String(data.get("id", ""))
	if item_type == "ring":
		var old_ring = _rings_equipped.get("slot_%d" % slot, null)
		if old_ring != null and typeof(old_ring) == TYPE_DICTIONARY:
			RingStore.ensure_ring_in_stash(account_username, old_ring as Dictionary)
		_rings_equipped["slot_%d" % slot] = data
		RingStore.equip_ring(account_username, _char_id, slot, data)
		RingStore.remove_ring_from_stash(account_username, item_id)
		_rings = RingStore.load_stash(account_username)
		_info_lbl.text = "Ring equipped to slot %d." % (slot + 1)
	else:
		var old_art = _artifacts_equipped.get("slot_%d" % slot, null)
		if old_art != null and typeof(old_art) == TYPE_DICTIONARY:
			ArtifactStore.ensure_artifact_in_stash(account_username, old_art as Dictionary)
		_artifacts_equipped["slot_%d" % slot] = data
		ArtifactStore.equip_artifact(account_username, _char_id, slot, data)
		ArtifactStore.remove_artifact_from_stash(account_username, item_id)
		_artifacts = ArtifactStore.load_stash(account_username)
		_info_lbl.text = "Artifact equipped to slot %d." % (slot + 1)
	_refresh_slots()
	_update_key_info()
	_rebuild_stash()

func _close_item_action_popup() -> void:
	if _item_popup_layer != null and is_instance_valid(_item_popup_layer):
		_item_popup_layer.queue_free()
	_item_popup_layer = null

func _is_item_currently_equipped(item_type: String, data: Dictionary) -> bool:
	var item_id: String = String(data.get("id", ""))
	if item_id.is_empty():
		return false
	if item_type == "ring":
		return _is_item_equipped(_rings_equipped, item_id)
	return _is_item_equipped(_artifacts_equipped, item_id)

func _find_equipped_slot(item_type: String, data: Dictionary) -> int:
	var item_id: String = String(data.get("id", ""))
	if item_id.is_empty():
		return -1
	var equipped: Dictionary = _rings_equipped if item_type == "ring" else _artifacts_equipped
	for i in 2:
		var entry = equipped.get("slot_%d" % i, null)
		if entry != null and typeof(entry) == TYPE_DICTIONARY and String((entry as Dictionary).get("id", "")) == item_id:
			return i
	return -1

func _ring_merge_count_in_stash(ring: Dictionary) -> int:
	var target_key: String = RingStore.ring_merge_key(ring)
	var count: int = 0
	for item in _rings:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if RingStore.ring_merge_key(item as Dictionary) == target_key:
			count += 1
	return count

func _unequip_item(item_type: String, slot: int) -> void:
	if slot < 0:
		return
	if item_type == "ring":
		var ring = _rings_equipped.get("slot_%d" % slot, null)
		if ring != null and typeof(ring) == TYPE_DICTIONARY:
			RingStore.ensure_ring_in_stash(account_username, ring as Dictionary)
		_rings_equipped["slot_%d" % slot] = null
		RingStore.unequip_ring(account_username, _char_id, slot)
		_rings = RingStore.load_stash(account_username)
		_info_lbl.text = "Ring unequipped."
	else:
		var art = _artifacts_equipped.get("slot_%d" % slot, null)
		if art != null and typeof(art) == TYPE_DICTIONARY:
			ArtifactStore.ensure_artifact_in_stash(account_username, art as Dictionary)
		_artifacts_equipped["slot_%d" % slot] = null
		ArtifactStore.unequip_artifact(account_username, _char_id, slot)
		_artifacts = ArtifactStore.load_stash(account_username)
		_info_lbl.text = "Artifact unequipped."
	_refresh_slots()
	_rebuild_stash()

func _equip_item_from_stash(item_type: String, data: Dictionary) -> void:
	var item_id: String = String(data.get("id", ""))
	if item_type == "ring":
		var slot: int = _first_empty_slot(_rings_equipped)
		if slot < 0:
			_info_lbl.text = "Ring slots are full. Unequip one first."
			return
		_rings_equipped["slot_%d" % slot] = data
		RingStore.equip_ring(account_username, _char_id, slot, data)
		RingStore.remove_ring_from_stash(account_username, item_id)
		_rings = RingStore.load_stash(account_username)
		_info_lbl.text = "Ring equipped to slot %d." % (slot + 1)
	else:
		var slot_a: int = _first_empty_slot(_artifacts_equipped)
		if slot_a < 0:
			_info_lbl.text = "Artifact slots are full. Unequip one first."
			return
		_artifacts_equipped["slot_%d" % slot_a] = data
		ArtifactStore.equip_artifact(account_username, _char_id, slot_a, data)
		ArtifactStore.remove_artifact_from_stash(account_username, item_id)
		_artifacts = ArtifactStore.load_stash(account_username)
		_info_lbl.text = "Artifact equipped to slot %d." % (slot_a + 1)
	_refresh_slots()
	_update_key_info()
	_rebuild_stash()

func _ring_bonus_text(ring: Dictionary) -> String:
	var attr: String = ring.get("attr", "") as String
	var value: float = _ring_base_t1_value(attr, float(ring.get("value", 0.0)))
	if attr in ["potion_drop_rate", "xp_bonus", "ring_drop_rate", "skill_dmg", "skill_cd", "aoe_radius", "projectile_spd", "crit_chance", "boss_dmg"]:
		return "%s %s" % [_format_percent_value(value), _pretty_stat_label(attr)]
	if attr == "regen":
		return "+%.1f Health per second" % value
	if attr == "revive_once":
		return "Revive once"
	if attr == "timed_shield":
		return "Timed Shield"
	return "+%.0f %s" % [value, _pretty_stat_label(attr)]

func _ring_base_t1_value(attr: String, fallback: float) -> float:
	for entry_any in RingStore.RING_POOL:
		if typeof(entry_any) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_any as Dictionary
		if String(entry.get("attr", "")) != attr:
			continue
		var vr: Array = entry.get("value_range", []) as Array
		if vr.size() >= 2:
			return (float(vr[0]) + float(vr[1])) * 0.5
		if vr.size() == 1:
			return float(vr[0])
		if entry.has("value"):
			return float(entry.get("value", fallback))
		return fallback
	match attr:
		"skill_dmg":
			return 0.15
		"skill_cd":
			return 0.12
		"revive_once":
			return 1.0
		"timed_shield":
			return 1.0
		_:
			return fallback

func _item_effect_text(item_type: String, data: Dictionary) -> String:
	if item_type == "ring":
		return _ring_bonus_text(data)
	return _artifact_bonus_text(data)

func _open_store() -> void:
	var store := StorePopup.new()
	store.account_username = account_username
	store.initial_tab = "ring"
	store.purchase_completed.connect(func(_product_id: String) -> void:
		_rings = RingStore.load_stash(account_username)
		_update_key_info()
		_rebuild_stash()
	)
	add_child(store)
