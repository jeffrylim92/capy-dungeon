extends Node2D

## Inventory screen — shown after CharacterSelect, before Match.
## Shows 2 ring slots per character and the full ring stash.
## Player can drag a ring from stash into a slot, or unequip by tapping a slot.

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
var _confirm_btn:  Button
var _back_btn:     Button

func _ready() -> void:
	_view = get_viewport_rect().size
	if selected_character != null:
		_char_id = String(selected_character.id)
	_equipped = RingStore.get_equipped_rings(account_username, _char_id)
	_stash    = RingStore.load_stash(account_username)
	_build_ui()

func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.07, 0.14)
	bg.size  = _view
	add_child(bg)

	# Title
	var title := Label.new()
	title.text = "Inventory — %s" % (selected_character.display_name if selected_character else "")
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.40))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 28)
	title.size     = Vector2(_view.x, 44)
	add_child(title)

	# ── Ring slots ──────────────────────────────────────────────────────────
	var slots_lbl := Label.new()
	slots_lbl.text = "Equipped Rings"
	slots_lbl.add_theme_font_size_override("font_size", 20)
	slots_lbl.add_theme_color_override("font_color", Color(0.78, 0.72, 0.60))
	slots_lbl.position = Vector2(32, 88)
	add_child(slots_lbl)

	var slot_y: float = 120.0
	var slot_w: float = (_view.x * 0.5 - 56.0)
	for s in 2:
		var slot_x: float = 32.0 + float(s) * (slot_w + 16.0)
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
		btn.position = Vector2(slot_x, slot_y)
		btn.size     = Vector2(slot_w, 90)
		btn.flat     = false
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		_refresh_slot_btn(btn, s)
		var sidx := s
		btn.pressed.connect(func(): _on_slot_pressed(sidx))
		add_child(btn)
		_slot_btns.append(btn)

	# ── Info label ──────────────────────────────────────────────────────────
	_info_lbl = Label.new()
	_info_lbl.text = "Tap a ring in your stash to select it, then tap a slot to equip.\nTap an equipped slot to unequip."
	_info_lbl.add_theme_font_size_override("font_size", 16)
	_info_lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.52))
	_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_info_lbl.position = Vector2(32, 226)
	_info_lbl.size     = Vector2(_view.x - 64, 52)
	add_child(_info_lbl)

	# ── Stash label ─────────────────────────────────────────────────────────
	var stash_lbl := Label.new()
	stash_lbl.text = "Ring Stash  (%d rings)" % _stash.size()
	stash_lbl.add_theme_font_size_override("font_size", 20)
	stash_lbl.add_theme_color_override("font_color", Color(0.78, 0.72, 0.60))
	stash_lbl.position = Vector2(32, 288)
	add_child(stash_lbl)

	# ── Scroll area for stash ────────────────────────────────────────────────
	_stash_scroll = ScrollContainer.new()
	_stash_scroll.position = Vector2(16, 318)
	_stash_scroll.size     = Vector2(_view.x - 32, _view.y - 420)
	add_child(_stash_scroll)

	_stash_vbox = VBoxContainer.new()
	_stash_vbox.add_theme_constant_override("separation", 8)
	_stash_vbox.size = Vector2(_view.x - 48, 0)
	_stash_scroll.add_child(_stash_vbox)

	_rebuild_stash()

	# ── Bottom buttons ───────────────────────────────────────────────────────
	_back_btn = Button.new()
	_back_btn.text = "← Back"
	_back_btn.add_theme_font_size_override("font_size", 22)
	_back_btn.position = Vector2(24, _view.y - 82)
	_back_btn.size     = Vector2(160, 58)
	_back_btn.pressed.connect(_on_back)
	add_child(_back_btn)

	_confirm_btn = Button.new()
	_confirm_btn.text = "Play ▶"
	_confirm_btn.add_theme_font_size_override("font_size", 26)
	var cst := StyleBoxFlat.new()
	cst.bg_color = Color(0.18, 0.55, 0.22)
	cst.corner_radius_top_left = 14; cst.corner_radius_top_right = 14
	cst.corner_radius_bottom_right = 14; cst.corner_radius_bottom_left = 14
	_confirm_btn.add_theme_stylebox_override("normal", cst)
	_confirm_btn.position = Vector2(_view.x - 220, _view.y - 82)
	_confirm_btn.size     = Vector2(196, 58)
	_confirm_btn.pressed.connect(_on_confirm)
	add_child(_confirm_btn)

func _rebuild_stash() -> void:
	for c in _stash_vbox.get_children():
		c.queue_free()
	_stash_btns.clear()
	if _stash.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No rings yet. Defeat Normal Bosses to earn rings!"
		empty_lbl.add_theme_font_size_override("font_size", 16)
		empty_lbl.add_theme_color_override("font_color", Color(0.55, 0.52, 0.45))
		_stash_vbox.add_child(empty_lbl)
		return
	for i in _stash.size():
		var ring: Dictionary = _stash[i] as Dictionary
		var row := Button.new()
		var rs := StyleBoxFlat.new()
		var rc: Color = _rarity_color(ring.get("rarity", "common") as String)
		rs.bg_color = Color(0.12, 0.09, 0.18)
		rs.corner_radius_top_left = 10; rs.corner_radius_top_right = 10
		rs.corner_radius_bottom_right = 10; rs.corner_radius_bottom_left = 10
		rs.set_border_width_all(2)
		rs.border_color = rc if _selected_stash_idx != i else Color(1.0, 0.95, 0.30)
		row.add_theme_stylebox_override("normal",  rs)
		row.add_theme_stylebox_override("hover",   rs)
		row.add_theme_stylebox_override("pressed", rs)
		row.custom_minimum_size = Vector2(_view.x - 64, 64)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var rtext: String = "[%s]  %s  (+%.2f %s)" % [
			(ring.get("rarity", "common") as String).to_upper(),
			ring.get("name", "Ring") as String,
			float(ring.get("value", 0.0)),
			ring.get("attr", "") as String,
		]
		row.text = rtext
		row.add_theme_font_size_override("font_size", 16)
		row.add_theme_color_override("font_color", rc)
		var ridx := i
		row.pressed.connect(func(): _on_stash_pressed(ridx))
		_stash_vbox.add_child(row)
		_stash_btns.append(row)

func _refresh_slot_btn(btn: Button, slot: int) -> void:
	var key: String  = "slot_%d" % slot
	var ring         = _equipped.get(key, null)
	if ring == null:
		btn.text = "Ring Slot %d\n(empty)" % (slot + 1)
		btn.add_theme_color_override("font_color", Color(0.55, 0.50, 0.45))
	else:
		var rd: Dictionary = ring as Dictionary
		var rc: Color      = _rarity_color(rd.get("rarity", "common") as String)
		btn.text = "Slot %d: %s\n+%.2f %s" % [slot + 1, rd.get("name", ""), float(rd.get("value", 0.0)), rd.get("attr", "")]
		btn.add_theme_color_override("font_color", rc)

func _on_slot_pressed(slot: int) -> void:
	var key: String = "slot_%d" % slot
	if _selected_stash_idx >= 0 and _selected_stash_idx < _stash.size():
		# Equip selected stash ring into this slot
		var ring: Dictionary = _stash[_selected_stash_idx] as Dictionary
		# If something already in slot, return it to stash
		var old = _equipped.get(key, null)
		if old != null:
			_stash.append(old as Dictionary)
		_equipped[key] = ring
		_stash.remove_at(_selected_stash_idx)
		_selected_stash_idx = -1
		RingStore.equip_ring(account_username, _char_id, slot, ring)
		RingStore._stash_cache[account_username] = _stash
		RingStore.save_stash(account_username)
		_refresh_slot_btn(_slot_btns[slot], slot)
		_rebuild_stash()
		_info_lbl.text = "Equipped: %s" % (ring.get("name", "") as String)
	else:
		# Unequip: return to stash
		var ring = _equipped.get(key, null)
		if ring != null:
			_stash.append(ring as Dictionary)
			_equipped[key] = null
			RingStore.unequip_ring(account_username, _char_id, slot)
			RingStore._stash_cache[account_username] = _stash
			RingStore.save_stash(account_username)
			_refresh_slot_btn(_slot_btns[slot], slot)
			_rebuild_stash()
			_info_lbl.text = "Ring returned to stash."

func _on_stash_pressed(idx: int) -> void:
	_selected_stash_idx = idx if _selected_stash_idx != idx else -1
	_rebuild_stash()
	if _selected_stash_idx >= 0:
		var ring: Dictionary = _stash[idx] as Dictionary
		_info_lbl.text = "%s — %s" % [ring.get("name", ""), ring.get("desc", "")]
	else:
		_info_lbl.text = "Tap a ring to select, then tap a slot to equip."

func _on_confirm() -> void:
	inventory_confirmed.emit(selected_character)

func _on_back() -> void:
	back_to_select.emit()

func _rarity_color(rarity: String) -> Color:
	return RingStore.RARITY_COLORS.get(rarity, Color(0.80, 0.80, 0.80)) as Color
