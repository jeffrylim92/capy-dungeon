extends Node2D

## Inventory screen — shown after CharacterSelect, before Match.
## Shows 2 ring slots per character and the shared ring stash.
## Player can assign a shared stash ring into a slot, or unequip by tapping a slot.

signal inventory_confirmed(char_data: CharacterData)
signal back_to_select

var selected_character: CharacterData = null
var account_username:   String        = ""

var _char_id:    String = ""
var _equipped:   Dictionary = {}   # {slot_0: ring_or_null, slot_1: ring_or_null}
var _stash:      Array      = []
var _view:       Vector2    = Vector2.ZERO
var _selected_stash_idx: int = -1  # which stash ring is highlighted

# UI refs
var _slot_btns:    Array[Button] = []
var _stash_btns:   Array[Button] = []
var _stash_scroll: ScrollContainer
var _stash_vbox:   VBoxContainer
var _info_lbl:     Label
var _merge_btn:    Button
var _confirm_btn:  Button
var _back_btn:     Button
var _store_btn:    Button
var _rules_btn:    Button

const STASH_RING_ICON_SIZE: float = 54.0

func _ready() -> void:
	_view = get_viewport_rect().size
	if selected_character != null:
		_char_id = String(selected_character.id)
	RingStore.sync_equipped_to_shared_stash(account_username)
	_equipped = RingStore.get_equipped_rings(account_username, _char_id)
	_stash    = RingStore.load_stash(account_username)
	_build_ui()

func _build_ui() -> void:
	var mx := 32.0
	var cw := _view.x - mx * 2.0

	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.07, 0.14)
	bg.size  = _view
	add_child(bg)

	var title := Label.new()
	title.text = "Inventory — %s" % (selected_character.display_name if selected_character else "")
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.40))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(mx, 24)
	title.size     = Vector2(cw, 54)
	add_child(title)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(mx, 90)
	vbox.size     = Vector2(cw, _view.y - 90 - 96)
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)

	var slots_lbl := Label.new()
	slots_lbl.text = "Equipped Rings"
	slots_lbl.add_theme_font_size_override("font_size", 36)
	slots_lbl.add_theme_color_override("font_color", Color(0.78, 0.72, 0.60))
	vbox.add_child(slots_lbl)

	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 16)
	vbox.add_child(slots_row)

	for s in 2:
		var btn := Button.new()
		var sty := StyleBoxFlat.new()
		sty.bg_color = Color(0.14, 0.10, 0.22)
		sty.corner_radius_top_left = 12; sty.corner_radius_top_right = 12
		sty.corner_radius_bottom_right = 12; sty.corner_radius_bottom_left = 12
		sty.set_border_width_all(2)
		sty.border_color = Color(0.60, 0.45, 0.85)
		btn.add_theme_stylebox_override("normal",  sty)
		btn.add_theme_stylebox_override("hover",   sty)
		btn.add_theme_stylebox_override("pressed", sty)
		btn.custom_minimum_size = Vector2(0, 96)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.flat = false
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		_refresh_slot_btn(btn, s)
		var sidx := s
		btn.pressed.connect(func(): _on_slot_pressed(sidx))
		slots_row.add_child(btn)
		_slot_btns.append(btn)

	_info_lbl = Label.new()
	_info_lbl.text = "Tap a ring in your shared stash to select it, then tap a slot to equip.\nRings stay shared across all characters. Tap an equipped slot to unequip."
	_info_lbl.add_theme_font_size_override("font_size", 32)
	_info_lbl.add_theme_color_override("font_color", Color(0.72, 0.66, 0.58))
	_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_info_lbl)

	_rules_btn = Button.new()
	_rules_btn.text = "Ring Rules"
	_rules_btn.add_theme_font_size_override("font_size", 30)
	_rules_btn.custom_minimum_size = Vector2(0, 56)
	_rules_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rules_btn.pressed.connect(_show_rules)
	vbox.add_child(_rules_btn)

	var stash_lbl := Label.new()
	stash_lbl.text = "Ring Stash  (%d rings)" % _stash.size()
	stash_lbl.add_theme_font_size_override("font_size", 36)
	stash_lbl.add_theme_color_override("font_color", Color(0.78, 0.72, 0.60))
	vbox.add_child(stash_lbl)

	_stash_scroll = ScrollContainer.new()
	_stash_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stash_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(_stash_scroll)

	_stash_vbox = VBoxContainer.new()
	_stash_vbox.add_theme_constant_override("separation", 8)
	_stash_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stash_scroll.add_child(_stash_vbox)

	_rebuild_stash()

	var btn_row := HBoxContainer.new()
	btn_row.position = Vector2(mx, _view.y - 84)
	btn_row.size     = Vector2(cw, 72)
	btn_row.add_theme_constant_override("separation", 16)
	add_child(btn_row)

	_back_btn = Button.new()
	_back_btn.text = "Back"
	_back_btn.add_theme_font_size_override("font_size", 38)
	_back_btn.custom_minimum_size = Vector2(200, 72)
	_back_btn.pressed.connect(_on_back)
	btn_row.add_child(_back_btn)

	_store_btn = Button.new()
	_store_btn.text = "Store"
	_store_btn.add_theme_font_size_override("font_size", 34)
	_store_btn.custom_minimum_size = Vector2(170, 72)
	_store_btn.pressed.connect(_open_store)
	btn_row.add_child(_store_btn)

	_merge_btn = Button.new()
	_merge_btn.text = "Merge"
	_merge_btn.add_theme_font_size_override("font_size", 34)
	_merge_btn.custom_minimum_size = Vector2(190, 72)
	_merge_btn.pressed.connect(_on_merge_pressed)
	btn_row.add_child(_merge_btn)

	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(fill)

	_confirm_btn = Button.new()
	_confirm_btn.text = "Play"
	_confirm_btn.add_theme_font_size_override("font_size", 40)
	var cst := StyleBoxFlat.new()
	cst.bg_color = Color(0.18, 0.55, 0.22)
	cst.corner_radius_top_left = 14; cst.corner_radius_top_right = 14
	cst.corner_radius_bottom_right = 14; cst.corner_radius_bottom_left = 14
	_confirm_btn.add_theme_stylebox_override("normal", cst)
	_confirm_btn.custom_minimum_size = Vector2(220, 72)
	_confirm_btn.pressed.connect(_on_confirm)
	btn_row.add_child(_confirm_btn)
	_refresh_merge_btn()

func _rebuild_stash() -> void:
	for c in _stash_vbox.get_children():
		c.queue_free()
	_stash_btns.clear()
	_refresh_merge_btn()
	if _stash.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No rings yet. Defeat bosses or visit the store to earn rings!"
		empty_lbl.add_theme_font_size_override("font_size", 32)
		empty_lbl.add_theme_color_override("font_color", Color(0.55, 0.52, 0.45))
		_stash_vbox.add_child(empty_lbl)
		return
	for i in _stash.size():
		var ring: Dictionary = _stash[i] as Dictionary
		var row := Button.new()
		var rs := StyleBoxFlat.new()
		var rarity: String = ring.get("rarity", "common") as String
		var rc: Color = _rarity_color(rarity)
		var equipped_slot: int = _equipped_slot_for_ring_id(ring.get("id", "") as String)
		var is_equipped: bool = equipped_slot >= 0
		rs.bg_color = Color(0.13, 0.13, 0.15, 0.92) if is_equipped else _rarity_bg_color(rarity)
		rs.corner_radius_top_left = 10; rs.corner_radius_top_right = 10
		rs.corner_radius_bottom_right = 10; rs.corner_radius_bottom_left = 10
		rs.set_border_width_all(2)
		rs.border_color = Color(0.36, 0.36, 0.40, 0.80) if is_equipped else rc if _selected_stash_idx != i else Color(1.0, 0.95, 0.30)
		row.add_theme_stylebox_override("normal",  rs)
		row.add_theme_stylebox_override("hover",   rs)
		row.add_theme_stylebox_override("pressed", rs)
		row.add_theme_stylebox_override("disabled", rs)
		row.custom_minimum_size = Vector2(0, 82)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.clip_contents = true
		row.text = ""
		var ring_text: String = "[%s]  %s  T%d" % [
			(ring.get("rarity", "common") as String).to_upper(),
			ring.get("name", "Ring") as String,
			int(ring.get("tier", 1)),
		]
		var bonus_text: String = _format_ring_bonus(ring)
		if is_equipped:
			bonus_text += " - equipped in Slot %d" % (equipped_slot + 1)
		row.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.0))
		row.add_theme_color_override("font_disabled_color", Color(0.54, 0.54, 0.58))
		row.add_child(_make_stash_row_content(ring, ring_text, bonus_text, Color(0.54, 0.54, 0.58) if is_equipped else rc))
		row.disabled = is_equipped
		row.modulate = Color(0.66, 0.66, 0.68, 0.78) if is_equipped else Color.WHITE
		var ridx := i
		if not is_equipped:
			row.pressed.connect(func(): _on_stash_pressed(ridx))
		_stash_vbox.add_child(row)
		_stash_btns.append(row)

func _make_stash_row_content(ring: Dictionary, ring_text: String, bonus_text: String, text_color: Color) -> Control:
	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 12
	content.offset_top = 8
	content.offset_right = -12
	content.offset_bottom = -8
	content.add_theme_constant_override("separation", 12)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var icon_rect := TextureRect.new()
	icon_rect.texture = RingStore.ring_icon(ring)
	icon_rect.custom_minimum_size = Vector2(STASH_RING_ICON_SIZE, STASH_RING_ICON_SIZE)
	icon_rect.size = Vector2(STASH_RING_ICON_SIZE, STASH_RING_ICON_SIZE)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon_rect)

	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.add_theme_constant_override("separation", 0)
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(labels)

	var name_lbl := Label.new()
	name_lbl.text = ring_text
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_lbl.add_theme_color_override("font_color", text_color)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(name_lbl)

	var bonus_lbl := Label.new()
	bonus_lbl.text = bonus_text
	bonus_lbl.add_theme_font_size_override("font_size", 24)
	bonus_lbl.add_theme_color_override("font_color", text_color)
	bonus_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bonus_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.add_child(bonus_lbl)

	return content

func _refresh_slot_btn(btn: Button, slot: int) -> void:
	var key: String  = "slot_%d" % slot
	var ring         = _equipped.get(key, null)
	if ring == null:
		var sty := StyleBoxFlat.new()
		sty.bg_color = Color(0.14, 0.10, 0.22)
		sty.corner_radius_top_left = 12; sty.corner_radius_top_right = 12
		sty.corner_radius_bottom_right = 12; sty.corner_radius_bottom_left = 12
		sty.set_border_width_all(2)
		sty.border_color = Color(0.60, 0.45, 0.85)
		btn.add_theme_stylebox_override("normal", sty)
		btn.add_theme_stylebox_override("hover", sty)
		btn.add_theme_stylebox_override("pressed", sty)
		btn.icon = null
		btn.text = "Ring Slot %d\n(empty)" % (slot + 1)
		btn.add_theme_font_size_override("font_size", 32)
		btn.add_theme_color_override("font_color", Color(0.55, 0.50, 0.45))
	else:
		var rd: Dictionary = ring as Dictionary
		var rarity: String = rd.get("rarity", "common") as String
		var rc: Color      = _rarity_color(rarity)
		var rs := StyleBoxFlat.new()
		rs.bg_color = _rarity_bg_color(rarity)
		rs.corner_radius_top_left = 12; rs.corner_radius_top_right = 12
		rs.corner_radius_bottom_right = 12; rs.corner_radius_bottom_left = 12
		rs.set_border_width_all(2)
		rs.border_color = rc
		btn.add_theme_stylebox_override("normal", rs)
		btn.add_theme_stylebox_override("hover", rs)
		btn.add_theme_stylebox_override("pressed", rs)
		btn.icon = RingStore.ring_icon(rd)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.text = "Slot %d: %s T%d\n%s" % [slot + 1, rd.get("name", ""), int(rd.get("tier", 1)), _format_ring_bonus(rd)]
		btn.add_theme_font_size_override("font_size", 32)
		btn.add_theme_color_override("font_color", rc)

func _on_slot_pressed(slot: int) -> void:
	var key: String = "slot_%d" % slot
	if _selected_stash_idx >= 0 and _selected_stash_idx < _stash.size():
		# Assign selected shared stash ring into this slot.
		var ring: Dictionary = _stash[_selected_stash_idx] as Dictionary
		var ring_id: String = ring.get("id", "") as String
		var equipped_slot: int = _equipped_slot_for_ring_id(ring_id)
		if equipped_slot >= 0 and equipped_slot != slot:
			_info_lbl.text = "%s is already equipped in Slot %d." % [ring.get("name", "Ring") as String, equipped_slot + 1]
			return
		_equipped[key] = ring
		_selected_stash_idx = -1
		RingStore.equip_ring(account_username, _char_id, slot, ring)
		_refresh_slot_btn(_slot_btns[slot], slot)
		_rebuild_stash()
		_info_lbl.text = "Equipped: %s" % (ring.get("name", "") as String)
	else:
		# Unequip: clear this character slot. The ring remains in the shared stash.
		var ring = _equipped.get(key, null)
		if ring != null:
			_equipped[key] = null
			RingStore.unequip_ring(account_username, _char_id, slot)
			_refresh_slot_btn(_slot_btns[slot], slot)
			_rebuild_stash()
			_info_lbl.text = "Ring unequipped. It remains in the shared stash."

func _on_stash_pressed(idx: int) -> void:
	if idx < 0 or idx >= _stash.size():
		return
	var ring: Dictionary = _stash[idx] as Dictionary
	var equipped_slot: int = _equipped_slot_for_ring_id(ring.get("id", "") as String)
	if equipped_slot >= 0:
		_selected_stash_idx = -1
		_rebuild_stash()
		_info_lbl.text = "%s is already equipped in Slot %d. Unequip it from the slot first." % [ring.get("name", "Ring") as String, equipped_slot + 1]
		_refresh_merge_btn()
		return
	_selected_stash_idx = idx if _selected_stash_idx != idx else -1
	_rebuild_stash()
	if _selected_stash_idx >= 0:
		var merge_count: int = RingStore.count_merge_matches(_stash, ring)
		_info_lbl.text = "%s T%d — %s\nMerge: %d/3 matching rings" % [ring.get("name", ""), int(ring.get("tier", 1)), ring.get("desc", ""), merge_count]
	else:
		_info_lbl.text = "Tap a ring to select, then tap a slot to equip."
	_refresh_merge_btn()

func _on_merge_pressed() -> void:
	if _selected_stash_idx < 0 or _selected_stash_idx >= _stash.size():
		return
	var ring: Dictionary = _stash[_selected_stash_idx] as Dictionary
	var merged: Dictionary = RingStore.merge_matching_from_stash(account_username, ring)
	if merged.is_empty():
		_info_lbl.text = "Need 3 matching rings with the same type and tier to merge."
		_refresh_merge_btn()
		return
	_stash = RingStore.load_stash(account_username)
	_selected_stash_idx = _find_stash_ring_index(merged.get("id", "") as String)
	_rebuild_stash()
	_info_lbl.text = "Merged into %s T%d: %s" % [merged.get("name", "Ring"), int(merged.get("tier", 1)), _format_ring_bonus(merged)]

func _on_confirm() -> void:
	inventory_confirmed.emit(selected_character)

func _on_back() -> void:
	back_to_select.emit()

func _open_store() -> void:
	var store := StorePopup.new()
	store.account_username = account_username
	store.initial_tab = "ring"
	store.purchase_completed.connect(func(_product_id: String) -> void:
		_stash = RingStore.load_stash(account_username)
		_rebuild_stash()
	)
	add_child(store)

func _show_rules() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.76)
	overlay.size = _view
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(overlay)

	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.07, 0.14, 1.0)
	ps.corner_radius_top_left = 18
	ps.corner_radius_top_right = 18
	ps.corner_radius_bottom_right = 18
	ps.corner_radius_bottom_left = 18
	ps.border_color = Color(0.82, 0.64, 0.28, 0.90)
	ps.set_border_width_all(3)
	ps.content_margin_left = 18
	ps.content_margin_right = 18
	ps.content_margin_top = 16
	ps.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", ps)
	var pw: float = min(_view.x - 48.0, 640.0)
	var ph: float = min(_view.y - 96.0, 880.0)
	panel.position = Vector2((_view.x - pw) * 0.5, (_view.y - ph) * 0.5)
	panel.custom_minimum_size = Vector2(pw, ph)
	layer.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)

	var title := Label.new()
	title.text = "Ring Rules"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.38))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.add_theme_font_size_override("font_size", 26)
	close_btn.custom_minimum_size = Vector2(120, 48)
	close_btn.pressed.connect(layer.queue_free)
	top.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, ph - 92.0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)

	_add_rule_section(body, "Shared Stash", "Rings in your stash are shared across all available characters. Equipping a ring assigns it to this character's slot, but the ring stays in the shared stash for other characters too. The same ring cannot fill both slots on one character.")
	_add_rule_section(body, "Rarity Colors", "Common cards are grey, Rare cards are blue, Epic cards are purple, and Legendary cards are gold/orange.")
	_add_rule_section(body, "Merge Rule", "Select a stash ring. If you have 3 rings with the same attribute, rarity, and tier, the Merge button turns on. Merging consumes those 3 rings and creates 1 ring at the next tier.")
	_add_rule_section(body, "Merge Formula", "New value = best value from the 3 matched rings x 1.20. T2, T3, and higher tiers keep repeating this same rule.")
	_add_rule_section(body, "Store Rings", "Purchased rings are store-only and unique in the stash, so they are not normally mergeable. They can still be equipped by any character through the shared stash.")
	_add_rule_section(body, "Special Gameplay Rules", "Second Chance Ring revives once per gameplay. Guardian Pulse Ring creates a 1 second shield every 10 seconds. Boss Breaker Band increases damage only against bosses.")
	_add_rule_section(body, "Mergeable Boss-Drop Rings", _mergeable_ring_rules_text())
	_add_rule_section(body, "Store Purchase Rings", _store_ring_rules_text())

	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			layer.queue_free()
	)

func _add_rule_section(parent: VBoxContainer, heading: String, text: String) -> void:
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.16, 0.12, 0.20, 1.0)
	cs.corner_radius_top_left = 10
	cs.corner_radius_top_right = 10
	cs.corner_radius_bottom_right = 10
	cs.corner_radius_bottom_left = 10
	cs.border_color = Color(0.48, 0.38, 0.58, 0.70)
	cs.set_border_width_all(1)
	cs.content_margin_left = 12
	cs.content_margin_right = 12
	cs.content_margin_top = 10
	cs.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", cs)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)

	var h := Label.new()
	h.text = heading
	h.add_theme_font_size_override("font_size", 28)
	h.add_theme_color_override("font_color", Color(1.0, 0.82, 0.34))
	h.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(h)

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.84, 0.80, 0.90))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(lbl)

func _mergeable_ring_rules_text() -> String:
	var lines: Array[String] = []
	for entry in RingStore.RING_POOL:
		var ring: Dictionary = entry as Dictionary
		var value_range: Array = ring.get("value_range", []) as Array
		var value_text: String = _format_value_range(ring.get("attr", "") as String, value_range)
		lines.append("%s - %s: %s" % [
			ring.get("rarity", "common") as String,
			ring.get("name", "Ring") as String,
			value_text,
		])
	return "\n".join(lines)

func _store_ring_rules_text() -> String:
	var lines: Array[String] = []
	for product_id in PurchaseStore.RING_PRODUCTS.keys():
		var ring: Dictionary = PurchaseStore.ring_product_to_ring(product_id as String)
		var price: String = PurchaseStore.PRICES.get(product_id, "") as String
		lines.append("%s - %s: %s (%s)" % [
			ring.get("rarity", "rare") as String,
			ring.get("name", "Ring") as String,
			_format_ring_bonus(ring),
			price,
		])
	return "\n".join(lines)

func _format_value_range(attr: String, value_range: Array) -> String:
	if value_range.size() < 2:
		return attr
	var min_value: float = float(value_range[0])
	var max_value: float = float(value_range[1])
	if attr in ["potion_drop_rate", "xp_bonus", "ring_drop_rate", "aoe_radius", "projectile_spd", "crit_chance", "boss_dmg"]:
		return "+%d%%-%d%% %s" % [int(round(min_value * 100.0)), int(round(max_value * 100.0)), attr]
	if attr == "regen":
		return "+%.1f-%.1f HP/s" % [min_value, max_value]
	return "+%.0f-%.0f %s" % [min_value, max_value, attr]

func _refresh_merge_btn() -> void:
	if _merge_btn == null:
		return
	var can_merge: bool = false
	if _selected_stash_idx >= 0 and _selected_stash_idx < _stash.size():
		can_merge = RingStore.can_merge_from_stash(_stash, _stash[_selected_stash_idx] as Dictionary)
	_merge_btn.disabled = not can_merge
	_merge_btn.modulate = Color(1, 1, 1, 1) if can_merge else Color(0.65, 0.65, 0.65, 0.75)

func _find_stash_ring_index(ring_id: String) -> int:
	for i in _stash.size():
		var ring: Dictionary = _stash[i] as Dictionary
		if ring.get("id", "") == ring_id:
			return i
	return -1

func _equipped_slot_for_ring_id(ring_id: String) -> int:
	if ring_id.is_empty():
		return -1
	for slot in 2:
		var ring = _equipped.get("slot_%d" % slot, null)
		if ring == null:
			continue
		var rd: Dictionary = ring as Dictionary
		if rd.get("id", "") == ring_id:
			return slot
	return -1

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

func _rarity_color(rarity: String) -> Color:
	return RingStore.RARITY_COLORS.get(rarity, Color(0.80, 0.80, 0.80)) as Color

func _rarity_bg_color(rarity: String) -> Color:
	var color: Color = _rarity_color(rarity)
	return Color(0.08, 0.07, 0.10).lerp(color, 0.24)
