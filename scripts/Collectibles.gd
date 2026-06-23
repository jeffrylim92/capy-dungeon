extends Node2D

signal back_requested

var account_username: String = ""

var _view: Vector2 = Vector2.ZERO

func _ready() -> void:
	_view = get_viewport_rect().size
	if not account_username.is_empty():
		PurchaseStore.set_username(account_username)
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.06, 0.11)
	bg.size = _view
	add_child(bg)

	var title := Label.new()
	title.text = "Collectibles"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(24, 18)
	title.size = Vector2(_view.x - 48, 48)
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.40))
	add_child(title)

	var tabs := TabContainer.new()
	tabs.position = Vector2(24, 78)
	tabs.size = Vector2(_view.x - 48, _view.y - 150)
	add_child(tabs)

	var rings_tab := ScrollContainer.new()
	rings_tab.name = "Rings"
	rings_tab.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(rings_tab)
	var rings_box := VBoxContainer.new()
	rings_box.add_theme_constant_override("separation", 8)
	rings_tab.add_child(rings_box)

	var artifacts_tab := ScrollContainer.new()
	artifacts_tab.name = "Artifacts"
	artifacts_tab.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(artifacts_tab)
	var artifacts_box := VBoxContainer.new()
	artifacts_box.add_theme_constant_override("separation", 8)
	artifacts_tab.add_child(artifacts_box)

	_fill_ring_cards(rings_box)
	_fill_artifact_cards(artifacts_box)
	tabs.current_tab = 0

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(180, 60)
	back_btn.position = Vector2(24, _view.y - 66)
	back_btn.add_theme_font_size_override("font_size", 30)
	back_btn.pressed.connect(func() -> void: back_requested.emit())
	add_child(back_btn)

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
		var head := Label.new()
		head.text = rarity.capitalize()
		head.add_theme_font_size_override("font_size", 30)
		head.add_theme_color_override("font_color", RingStore.RARITY_COLORS.get(rarity, Color(0.8, 0.8, 0.8)) as Color)
		parent.add_child(head)
		for item in items:
			var d2: Dictionary = item as Dictionary
			var card := PanelContainer.new()
			var st := StyleBoxFlat.new()
			st.bg_color = Color(0.14, 0.12, 0.18)
			st.corner_radius_top_left = 8
			st.corner_radius_top_right = 8
			st.corner_radius_bottom_right = 8
			st.corner_radius_bottom_left = 8
			st.set_border_width_all(1)
			st.border_color = Color(0.36, 0.34, 0.44)
			card.add_theme_stylebox_override("panel", st)
			parent.add_child(card)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			card.add_child(row)
			row.add_child(_ring_thumb(d2, obtained.has(d2.get("name", "") as String)))
			var box := VBoxContainer.new()
			box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.add_theme_constant_override("separation", 2)
			row.add_child(box)
			var name: String = d2.get("name", "Ring") as String
			var got: bool = obtained.has(name)
			var l1 := Label.new()
			l1.text = name
			l1.add_theme_font_size_override("font_size", 24)
			box.add_child(l1)
			var l2 := Label.new()
			l2.text = d2.get("desc", "") as String if got else "???"
			l2.add_theme_font_size_override("font_size", 20)
			l2.add_theme_color_override("font_color", Color(0.80, 0.78, 0.86))
			box.add_child(l2)

func _collectible_ring_entries() -> Array:
	var out: Array = []
	for e in RingStore.RING_POOL:
		out.append((e as Dictionary).duplicate(true))
	for product_id in PurchaseStore.RING_PRODUCTS.keys():
		out.append(PurchaseStore.ring_product_to_ring(product_id as String))
	return out

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
		var head := Label.new()
		head.text = rarity.capitalize()
		head.add_theme_font_size_override("font_size", 30)
		head.add_theme_color_override("font_color", ArtifactStore.RARITY_COLORS.get(rarity, Color(0.8, 0.8, 0.8)) as Color)
		parent.add_child(head)
		for item in items:
			var d2: Dictionary = item as Dictionary
			var card := PanelContainer.new()
			var st := StyleBoxFlat.new()
			st.bg_color = Color(0.14, 0.12, 0.18)
			st.corner_radius_top_left = 8
			st.corner_radius_top_right = 8
			st.corner_radius_bottom_right = 8
			st.corner_radius_bottom_left = 8
			st.set_border_width_all(1)
			st.border_color = Color(0.36, 0.34, 0.44)
			card.add_theme_stylebox_override("panel", st)
			parent.add_child(card)
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			card.add_child(row)
			row.add_child(_artifact_thumb(d2, obtained.has(d2.get("name", "") as String)))
			var box := VBoxContainer.new()
			box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.add_theme_constant_override("separation", 2)
			row.add_child(box)
			var name: String = d2.get("name", "Artifact") as String
			var got: bool = obtained.has(name)
			var l1 := Label.new()
			l1.text = name
			l1.add_theme_font_size_override("font_size", 24)
			box.add_child(l1)
			var l2 := Label.new()
			l2.text = d2.get("desc", "") as String if got else "???"
			l2.add_theme_font_size_override("font_size", 20)
			l2.add_theme_color_override("font_color", Color(0.80, 0.78, 0.86))
			box.add_child(l2)

func _ring_thumb(data: Dictionary, obtained: bool) -> Control:
	var tex := TextureRect.new()
	tex.custom_minimum_size = Vector2(60, 60)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if obtained:
		tex.texture = RingStore.ring_icon(data)
	if tex.texture == null:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(60, 60)
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.22, 0.20, 0.28)
		st.corner_radius_top_left = 8
		st.corner_radius_top_right = 8
		st.corner_radius_bottom_right = 8
		st.corner_radius_bottom_left = 8
		panel.add_theme_stylebox_override("panel", st)
		var lbl := Label.new()
		lbl.text = "?" if not obtained else "R"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.add_child(lbl)
		return panel
	return tex

func _artifact_thumb(data: Dictionary, obtained: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(60, 60)
	var st := StyleBoxFlat.new()
	st.bg_color = ArtifactStore.RARITY_COLORS.get(data.get("rarity", "rare"), Color(0.55, 0.55, 0.55)) as Color
	st.bg_color = st.bg_color.darkened(0.45)
	st.corner_radius_top_left = 8
	st.corner_radius_top_right = 8
	st.corner_radius_bottom_right = 8
	st.corner_radius_bottom_left = 8
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
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.88))
	panel.add_child(lbl)
	return panel
