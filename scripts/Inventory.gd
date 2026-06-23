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

var _view: Vector2 = Vector2.ZERO
var _info_lbl: Label
var _key_info_lbl: Label
var _stash_grid: GridContainer
var _key_timer_tick: float = 0.0

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

	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.07, 0.14)
	bg.size = _view
	add_child(bg)

	var title := Label.new()
	title.text = "Inventory — %s" % (selected_character.display_name if selected_character else "")
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.40))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(mx, 20)
	title.size = Vector2(cw, 54)
	add_child(title)

	var root := VBoxContainer.new()
	root.position = Vector2(mx, 86)
	root.size = Vector2(cw, _view.y - 178)
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var r_lbl := Label.new()
	r_lbl.text = "Equipped Rings"
	r_lbl.add_theme_font_size_override("font_size", 32)
	r_lbl.add_theme_color_override("font_color", Color(0.80, 0.74, 0.62))
	root.add_child(r_lbl)

	var ring_row := HBoxContainer.new()
	ring_row.add_theme_constant_override("separation", 12)
	root.add_child(ring_row)
	for i in 2:
		var b := _make_slot_button()
		var idx: int = i
		b.pressed.connect(func() -> void: _on_ring_slot_pressed(idx))
		ring_row.add_child(b)
		_ring_slot_btns.append(b)

	var a_lbl := Label.new()
	a_lbl.text = "Equipped Artifacts"
	a_lbl.add_theme_font_size_override("font_size", 32)
	a_lbl.add_theme_color_override("font_color", Color(0.80, 0.74, 0.62))
	root.add_child(a_lbl)

	var artifact_row := HBoxContainer.new()
	artifact_row.add_theme_constant_override("separation", 12)
	root.add_child(artifact_row)
	for i in 2:
		var b := _make_slot_button()
		var idx: int = i
		b.pressed.connect(func() -> void: _on_artifact_slot_pressed(idx))
		artifact_row.add_child(b)
		_artifact_slot_btns.append(b)

	_info_lbl = Label.new()
	_info_lbl.text = "Tap a stash item to auto-equip. If slots are full, unequip a slot first."
	_info_lbl.add_theme_font_size_override("font_size", 26)
	_info_lbl.add_theme_color_override("font_color", Color(0.72, 0.66, 0.58))
	_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(_info_lbl)

	_key_info_lbl = Label.new()
	_key_info_lbl.add_theme_font_size_override("font_size", 24)
	_key_info_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.34))
	root.add_child(_key_info_lbl)

	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 8)
	root.add_child(filter_row)
	for f in ["all", "rings", "artifacts"]:
		var btn := Button.new()
		btn.text = f.capitalize()
		btn.custom_minimum_size = Vector2(130, 48)
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(func() -> void:
			_filter = f
			_rebuild_stash()
		)
		filter_row.add_child(btn)

	var stash_lbl := Label.new()
	stash_lbl.text = "Inventory Stash"
	stash_lbl.add_theme_font_size_override("font_size", 34)
	stash_lbl.add_theme_color_override("font_color", Color(0.78, 0.72, 0.60))
	root.add_child(stash_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_stash_grid = GridContainer.new()
	_stash_grid.columns = 2
	_stash_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stash_grid.add_theme_constant_override("h_separation", 10)
	_stash_grid.add_theme_constant_override("v_separation", 10)
	_stash_grid.custom_minimum_size = Vector2(cw - 6.0, 0.0)
	scroll.add_child(_stash_grid)

	var bottom := HBoxContainer.new()
	bottom.position = Vector2(mx, _view.y - 80)
	bottom.size = Vector2(cw, 64)
	bottom.add_theme_constant_override("separation", 12)
	add_child(bottom)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(180, 64)
	back_btn.add_theme_font_size_override("font_size", 34)
	back_btn.pressed.connect(func() -> void: back_to_select.emit())
	bottom.add_child(back_btn)

	var store_btn := Button.new()
	store_btn.text = "Store"
	store_btn.custom_minimum_size = Vector2(180, 64)
	store_btn.add_theme_font_size_override("font_size", 30)
	store_btn.pressed.connect(_open_store)
	bottom.add_child(store_btn)

	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(fill)

	var play_btn := Button.new()
	play_btn.text = "Play"
	play_btn.custom_minimum_size = Vector2(220, 64)
	play_btn.add_theme_font_size_override("font_size", 36)
	play_btn.pressed.connect(func() -> void: inventory_confirmed.emit(selected_character))
	bottom.add_child(play_btn)

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
	btn.custom_minimum_size = Vector2(0, 92)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.14, 0.10, 0.22)
	sty.corner_radius_top_left = 10
	sty.corner_radius_top_right = 10
	sty.corner_radius_bottom_right = 10
	sty.corner_radius_bottom_left = 10
	sty.set_border_width_all(2)
	sty.border_color = Color(0.60, 0.45, 0.85)
	btn.add_theme_stylebox_override("normal", sty)
	btn.add_theme_stylebox_override("hover", sty)
	btn.add_theme_stylebox_override("pressed", sty)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_constant_override("icon_max_width", 56)
	btn.add_theme_constant_override("icon_max_height", 56)
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.clip_text = true
	return btn

func _refresh_slots() -> void:
	for i in 2:
		var rr = _rings_equipped.get("slot_%d" % i, null)
		if rr == null:
			_ring_slot_btns[i].text = "Ring Slot %d\n(empty)" % (i + 1)
			_ring_slot_btns[i].icon = null
		else:
			var rd: Dictionary = rr as Dictionary
			_ring_slot_btns[i].text = "Ring %d\n%s" % [i + 1, rd.get("name", "Ring") as String]
			_ring_slot_btns[i].icon = RingStore.ring_icon(rd)
	for i in 2:
		var aa = _artifacts_equipped.get("slot_%d" % i, null)
		if aa == null:
			_artifact_slot_btns[i].text = "Artifact Slot %d\n(empty)" % (i + 1)
		else:
			var ad: Dictionary = aa as Dictionary
			_artifact_slot_btns[i].text = "Artifact %d\n%s" % [i + 1, ad.get("name", "Artifact") as String]

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
		RingStore.ensure_ring_in_stash(account_username, ring as Dictionary)
	_rings_equipped["slot_%d" % slot] = null
	RingStore.unequip_ring(account_username, _char_id, slot)
	_rings = RingStore.load_stash(account_username)
	_info_lbl.text = "Ring unequipped."
	_refresh_slots()
	_rebuild_stash()

func _on_artifact_slot_pressed(slot: int) -> void:
	var art = _artifacts_equipped.get("slot_%d" % slot, null)
	if art == null:
		return
	if typeof(art) == TYPE_DICTIONARY:
		ArtifactStore.ensure_artifact_in_stash(account_username, art as Dictionary)
	_artifacts_equipped["slot_%d" % slot] = null
	ArtifactStore.unequip_artifact(account_username, _char_id, slot)
	_artifacts = ArtifactStore.load_stash(account_username)
	_info_lbl.text = "Artifact unequipped."
	_refresh_slots()
	_rebuild_stash()

func _rebuild_stash() -> void:
	for c in _stash_grid.get_children():
		c.queue_free()

	var rows: Array = []
	if _filter == "all" or _filter == "rings":
		for r in _rings:
			var r_dict: Dictionary = r as Dictionary
			var r_id: String = String(r_dict.get("id", ""))
			if r_id.is_empty() or _is_item_equipped(_rings_equipped, r_id):
				continue
			rows.append({"type": "ring", "data": r})
	if _filter == "all" or _filter == "artifacts":
		for a in _artifacts:
			var a_dict: Dictionary = a as Dictionary
			var a_id: String = String(a_dict.get("id", ""))
			if a_id.is_empty() or _is_item_equipped(_artifacts_equipped, a_id):
				continue
			rows.append({"type": "artifact", "data": a})

	if rows.is_empty():
		var empty := Label.new()
		empty.text = "No items in this filter."
		empty.add_theme_font_size_override("font_size", 26)
		empty.add_theme_color_override("font_color", Color(0.58, 0.54, 0.50))
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_stash_grid.add_child(empty)
		return

	for row_data in rows:
		var item_type: String = row_data["type"] as String
		var data: Dictionary = row_data["data"] as Dictionary
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 146 if item_type == "ring" else 130)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 1)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.clip_text = true
		var title: String = data.get("name", item_type.capitalize()) as String
		var desc: String = ""
		if item_type == "ring":
			desc = data.get("desc", "") as String
		else:
			desc = data.get("desc", "") as String
		btn.text = ""
		btn.add_child(_build_stash_row_content(item_type, data, title, desc))

		var disabled: bool = false
		if item_type == "ring" and _ring_slots_full():
			disabled = true
		if item_type == "artifact" and _artifact_slots_full():
			disabled = true
		btn.disabled = disabled
		_style_stash_card(btn, item_type, disabled)
		if not disabled:
			btn.pressed.connect(func() -> void: _on_stash_item_pressed(item_type, data))
		_stash_grid.add_child(btn)

func _build_stash_row_content(item_type: String, data: Dictionary, title: String, desc: String) -> Control:
	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10
	content.offset_top = 8
	content.offset_right = -10
	content.offset_bottom = -8
	content.add_theme_constant_override("separation", 10)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if item_type == "ring":
		var icon_rect := TextureRect.new()
		icon_rect.texture = RingStore.ring_icon(data)
		icon_rect.custom_minimum_size = Vector2(56, 56)
		icon_rect.size = Vector2(56, 56)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon_rect)
	else:
		var art_icon: Texture2D = _artifact_icon(data)
		if art_icon != null:
			var art_icon_rect := TextureRect.new()
			art_icon_rect.texture = art_icon
			art_icon_rect.custom_minimum_size = Vector2(56, 56)
			art_icon_rect.size = Vector2(56, 56)
			art_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content.add_child(art_icon_rect)

	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.add_theme_constant_override("separation", 0)
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(labels)

	var l1 := Label.new()
	if item_type == "ring":
		l1.text = "%s  [T%d]" % [title, int(data.get("tier", 1))]
	else:
		l1.text = "%s  [%s]" % [title, item_type.to_upper()]
	l1.add_theme_font_size_override("font_size", 20)
	l1.autowrap_mode = TextServer.AUTOWRAP_WORD
	l1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(l1)

	var l2 := Label.new()
	if item_type == "ring":
		l2.text = "%s  ·  %s" % [desc, _ring_bonus_text(data)]
	else:
		l2.text = desc
	l2.add_theme_font_size_override("font_size", 16)
	l2.add_theme_color_override("font_color", Color(0.80, 0.78, 0.86))
	l2.autowrap_mode = TextServer.AUTOWRAP_WORD
	l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(l2)

	return content

func _style_stash_card(btn: Button, item_type: String, disabled: bool) -> void:
	var normal := StyleBoxFlat.new()
	if item_type == "ring":
		normal.bg_color = Color(0.18, 0.13, 0.26, 0.96)
		normal.border_color = Color(0.64, 0.46, 0.90, 0.85)
	else:
		normal.bg_color = Color(0.18, 0.16, 0.24, 0.96)
		normal.border_color = Color(0.70, 0.60, 0.40, 0.85)
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_right = 12
	normal.corner_radius_bottom_left = 12

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.12)

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
	var explicit_path: String = String(artifact.get("icon", ""))
	if not explicit_path.is_empty() and ResourceLoader.exists(explicit_path):
		return load(explicit_path) as Texture2D

	var raw_id: String = String(artifact.get("id", ""))
	if raw_id.is_empty():
		return null
	var base_id: String = raw_id
	var last_underscore: int = raw_id.rfind("_")
	if last_underscore > 0:
		var suffix: String = raw_id.substr(last_underscore + 1)
		if suffix.is_valid_int():
			base_id = raw_id.substr(0, last_underscore)

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

func _on_stash_item_pressed(item_type: String, data: Dictionary) -> void:
	if item_type == "ring":
		var item_id: String = String(data.get("id", ""))
		if not item_id.is_empty() and _is_item_equipped(_rings_equipped, item_id):
			_info_lbl.text = "This ring is already equipped. Unequip it first."
			_rebuild_stash()
			return
		var slot: int = _first_empty_slot(_rings_equipped)
		if slot < 0:
			_info_lbl.text = "Ring slots are full. Unequip one first."
			_rebuild_stash()
			return
		_rings_equipped["slot_%d" % slot] = data
		RingStore.equip_ring(account_username, _char_id, slot, data)
		RingStore.remove_ring_from_stash(account_username, item_id)
		_rings = RingStore.load_stash(account_username)
		_info_lbl.text = "Ring equipped to slot %d." % (slot + 1)
	else:
		var item_id: String = String(data.get("id", ""))
		if not item_id.is_empty() and _is_item_equipped(_artifacts_equipped, item_id):
			_info_lbl.text = "This artifact is already equipped. Unequip it first."
			_rebuild_stash()
			return
		var slot_a: int = _first_empty_slot(_artifacts_equipped)
		if slot_a < 0:
			_info_lbl.text = "Artifact slots are full. Unequip one first."
			_rebuild_stash()
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
	var value: float = float(ring.get("value", 0.0))
	if attr in ["potion_drop_rate", "xp_bonus", "ring_drop_rate", "skill_dmg", "skill_cd", "aoe_radius", "projectile_spd", "crit_chance", "boss_dmg"]:
		return "+%d%% %s" % [int(round(value * 100.0)), attr]
	if attr == "regen":
		return "+%.1f HP/s" % value
	if attr == "revive_once":
		return "revive once"
	if attr == "timed_shield":
		return "timed shield"
	return "+%.0f %s" % [value, attr]

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
