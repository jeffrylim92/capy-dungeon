extends Node2D

## Character pick screen. Shows every CharacterData found under
## resources/characters/ as a tappable card. Tapping selects the card;
## the "Start Match" button then launches the match.

signal character_chosen(data: CharacterData)
signal back_to_menu

const PORTRAIT_DIR := "res://assets/characters/"
const PORTRAIT_EXTS: Array[String] = [".png", ".webp", ".jpg", ".svg"]
const SKILL_NAMES: Dictionary = {
	"orb": "Capy Orb", "bolt": "Capy Bolt", "aura": "Mud Aura",
	"wave": "Squeal Wave", "regen": "Capy Calm", "magnet": "XP Magnet",
	"ice_orb": "Ice Orb",
	"fireball": "Fireball Orbit", "elec_wave": "Electric Wave",
	"hurricane": "Hurricane", "blizzard": "Blizzard",
	"arrow": "Power Arrow", "split_arrow": "Split Arrow",
	"pierce_arrow": "Pierce Arrow", "sky_fall": "Sky Fall",
	"star_knife": "Star Knife", "knife_storm": "Knife Storm",
	"boomerang": "Boomerang", "seven_slash": "7 Slash",
	"swirl_tangerine": "Swirl Tangerine",
}

const JOB_SKILLS: Dictionary = {
	"capy_zoomer":   "Capy Orb · Mud Aura · Ice Orb · Capy Calm · XP Magnet",
	"capy_chef":     "Capy Orb · Capy Bolt · Capy Calm · XP Magnet",
	"capy_swamp":    "Mud Aura · Squeal Wave · Ice Orb · Capy Calm · XP Magnet",
	"capy_wizard":   "Fireball · Electric Wave · Hurricane · ✦ Blizzard (Ulti)",
	"capy_archer":   "Power Arrow · Split Arrow · Pierce Arrow · ✦ Sky Fall (Ulti)",
	"capy_assassin": "Star Knife · Knife Storm · Boomerang · ✦ 7 Slash (Ulti)",
}

# Display order: free basics → earn-to-unlock → IAP premium
const CHAR_ORDER: Array[String] = [
	"capy_zoomer", "capy_chef", "capy_swamp",
	"capy_brown",
	"capy_wizard", "capy_archer", "capy_assassin",
]

const CHAR_ULTI: Dictionary = {
	"capy_brown":    "swirl_tangerine",
	"capy_wizard":   "blizzard",
	"capy_archer":   "sky_fall",
	"capy_assassin": "seven_slash",
}

const ULTI_DESC: Dictionary = {
	"swirl_tangerine": "A massive tangerine energy cyclone sweeps the entire screen, obliterating all enemies in a single devastating vortex.\n\nUnlock: Master any 2 skills (reach Level 5 on 2 skills). Exclusive to Brown Capy.",
	"blizzard":        "An absolute-zero ice storm blankets the entire screen, dealing massive damage and near-freezing all enemies.\n\nUnlock: Master any 2 Wizard skills (reach Level 5). Exclusive to Wizard Capy.",
	"sky_fall":        "A relentless storm of arrows rains down across the entire screen, piercing through every enemy.\n\nUnlock: Master any 2 Archer skills (reach Level 5). Exclusive to Archer Capy.",
	"seven_slash":     "Seven simultaneous screen-wide blade slashes tear through every enemy at once with lethal force.\n\nUnlock: Master any 2 Assassin skills (reach Level 5). Exclusive to Assassin Capy.",
}

## Set by Main before the scene is added to the tree so the favourite is
## pre-selected when the screen opens.
var favourite_character_id: String = ""
var account_username: String = ""

var _selected_idx: int = -1
var _selected_data: CharacterData = null
var _card_list: Array[Button] = []
var _card_locked: Array[bool] = []
var _card_iap: Array[bool] = []
var _char_list: Array[CharacterData] = []
var _start_btn: Button
var _back_btn: Button
var _store_btn: Button
var _card_w: float = 0.0
var _cards_vbox: VBoxContainer = null

func _ready() -> void:
	_build_background()
	_build_title()
	_build_store_button()
	_build_cards()
	_build_start_button()

func _build_background() -> void:
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

func _build_title() -> void:
	var view := get_viewport_rect().size
	var title := Label.new()
	title.text = "Pick Your Capy"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(0.97, 0.93, 0.82))
	title.position = Vector2(0, 80)
	title.size = Vector2(view.x, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

func _build_store_button() -> void:
	var view := get_viewport_rect().size
	_store_btn = Button.new()
	_store_btn.text = "Store"
	_store_btn.add_theme_font_size_override("font_size", 32)
	_store_btn.add_theme_color_override("font_color", Color(0.12, 0.06, 0.0))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.78, 0.20, 0.96)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.border_color = Color(0.72, 0.42, 0.0, 0.86)
	style.set_border_width_all(2)
	_store_btn.add_theme_stylebox_override("normal", style)
	_store_btn.add_theme_stylebox_override("hover", style)
	_store_btn.add_theme_stylebox_override("pressed", style)
	_store_btn.size = Vector2(150, 58)
	_store_btn.position = Vector2(view.x - 174.0, 92.0)
	_store_btn.focus_mode = Control.FOCUS_NONE
	_store_btn.pressed.connect(func() -> void: _open_store("character"))
	add_child(_store_btn)

func _build_cards() -> void:
	var view := get_viewport_rect().size
	var characters := CharacterLoader.load_all()
	if characters.is_empty():
		_show_empty_state()
		return
	_char_list = characters
	# Sort by CHAR_ORDER: free basics → earn-to-unlock → IAP premium
	_char_list.sort_custom(func(a: CharacterData, b: CharacterData) -> bool:
		var ia: int = CHAR_ORDER.find(String(a.id))
		var ib: int = CHAR_ORDER.find(String(b.id))
		if ia < 0: ia = 999
		if ib < 0: ib = 999
		return ia < ib)

	var card_w: float = view.x - 80.0
	var card_h: float = 180.0

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 178)
	scroll.size = Vector2(card_w, view.y - 178.0 - 126.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)

	for i in range(_char_list.size()):
		var data: CharacterData = _char_list[i]
		var locked: bool = _is_brown_locked(data)
		var iap: bool    = _is_iap_locked(data)
		var has_ulti: bool = CHAR_ULTI.has(String(data.id)) and not locked and not iap
		_card_locked.append(locked)
		_card_iap.append(iap)
		var h: float = 190.0 if locked else (240.0 if iap else (202.0 if has_ulti else card_h))
		var btn := _make_char_button(data, card_w, h, i, locked, iap)
		list.add_child(btn)
		_card_list.append(btn)

	_card_w = card_w
	_cards_vbox = list

	# Pre-select the favourite character if one is set.
	if favourite_character_id != "":
		for i in range(_char_list.size()):
			if String(_char_list[i].id) == favourite_character_id and not (_card_locked.size() > i and _card_locked[i]):
				_select_card(i)
				break

func _build_start_button() -> void:
	var view := get_viewport_rect().size
	var total_w: float = view.x - 120.0
	var back_w: float = 260.0
	var gap: float = 16.0
	var start_w: float = total_w - back_w - gap
	var btn_y: float = view.y - 116.0
	var btn_h: float = 88.0

	# ── Back / secondary button ─────────────────────────────────────────
	var back_n := StyleBoxFlat.new()
	back_n.bg_color = Color(0.14, 0.14, 0.22, 0.92)
	back_n.corner_radius_top_left = 28
	back_n.corner_radius_top_right = 28
	back_n.corner_radius_bottom_right = 28
	back_n.corner_radius_bottom_left = 28
	back_n.border_color = Color(0.55, 0.55, 0.75, 0.75)
	back_n.set_border_width_all(2)
	back_n.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	back_n.shadow_size = 7
	back_n.shadow_offset = Vector2(0, 3)

	var back_h := StyleBoxFlat.new()
	back_h.bg_color = Color(0.22, 0.22, 0.35, 0.95)
	back_h.corner_radius_top_left = 28
	back_h.corner_radius_top_right = 28
	back_h.corner_radius_bottom_right = 28
	back_h.corner_radius_bottom_left = 28
	back_h.border_color = Color(0.65, 0.65, 0.88, 0.85)
	back_h.set_border_width_all(2)
	back_h.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	back_h.shadow_size = 7
	back_h.shadow_offset = Vector2(0, 3)

	var back_p := StyleBoxFlat.new()
	back_p.bg_color = Color(0.08, 0.08, 0.16, 0.95)
	back_p.corner_radius_top_left = 28
	back_p.corner_radius_top_right = 28
	back_p.corner_radius_bottom_right = 28
	back_p.corner_radius_bottom_left = 28
	back_p.border_color = Color(0.45, 0.45, 0.65, 0.7)
	back_p.set_border_width_all(2)
	back_p.shadow_color = Color(0.0, 0.0, 0.0, 0.2)
	back_p.shadow_size = 3
	back_p.shadow_offset = Vector2(0, 1)

	_back_btn = Button.new()
	_back_btn.text = "Menu"
	_back_btn.add_theme_font_size_override("font_size", 40)
	_back_btn.add_theme_color_override("font_color", Color(0.90, 0.90, 1.0))
	_back_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	_back_btn.add_theme_color_override("font_pressed_color", Color(0.72, 0.72, 0.88))
	_back_btn.add_theme_stylebox_override("normal", back_n)
	_back_btn.add_theme_stylebox_override("hover", back_h)
	_back_btn.add_theme_stylebox_override("pressed", back_p)
	_back_btn.size = Vector2(back_w, btn_h)
	_back_btn.position = Vector2(60.0, btn_y)
	_back_btn.focus_mode = Control.FOCUS_NONE
	_back_btn.pressed.connect(_on_back_pressed)
	add_child(_back_btn)

	# ── Start Match / primary CTA ───────────────────────────────────────
	var start_n := StyleBoxFlat.new()
	start_n.bg_color = Color(0.98, 0.72, 0.08)
	start_n.corner_radius_top_left = 28
	start_n.corner_radius_top_right = 28
	start_n.corner_radius_bottom_right = 28
	start_n.corner_radius_bottom_left = 28
	start_n.border_color = Color(0.72, 0.42, 0.0)
	start_n.set_border_width_all(3)
	start_n.shadow_color = Color(0.72, 0.42, 0.0, 0.58)
	start_n.shadow_size = 12
	start_n.shadow_offset = Vector2(0, 5)

	var start_h := StyleBoxFlat.new()
	start_h.bg_color = Color(1.0, 0.82, 0.25)
	start_h.corner_radius_top_left = 28
	start_h.corner_radius_top_right = 28
	start_h.corner_radius_bottom_right = 28
	start_h.corner_radius_bottom_left = 28
	start_h.border_color = Color(0.72, 0.42, 0.0)
	start_h.set_border_width_all(3)
	start_h.shadow_color = Color(0.72, 0.42, 0.0, 0.58)
	start_h.shadow_size = 12
	start_h.shadow_offset = Vector2(0, 5)

	var start_p := StyleBoxFlat.new()
	start_p.bg_color = Color(0.80, 0.56, 0.03)
	start_p.corner_radius_top_left = 28
	start_p.corner_radius_top_right = 28
	start_p.corner_radius_bottom_right = 28
	start_p.corner_radius_bottom_left = 28
	start_p.border_color = Color(0.58, 0.32, 0.0)
	start_p.set_border_width_all(3)
	start_p.shadow_color = Color(0.58, 0.32, 0.0, 0.4)
	start_p.shadow_size = 5
	start_p.shadow_offset = Vector2(0, 2)

	var start_d := StyleBoxFlat.new()
	start_d.bg_color = Color(0.50, 0.48, 0.40, 0.72)
	start_d.corner_radius_top_left = 28
	start_d.corner_radius_top_right = 28
	start_d.corner_radius_bottom_right = 28
	start_d.corner_radius_bottom_left = 28
	start_d.border_color = Color(0.42, 0.40, 0.34, 0.5)
	start_d.set_border_width_all(2)
	start_d.shadow_color = Color(0.0, 0.0, 0.0, 0.15)
	start_d.shadow_size = 4
	start_d.shadow_offset = Vector2(0, 2)

	_start_btn = Button.new()
	_start_btn.text = "Start Match"
	_start_btn.disabled = _selected_data == null
	_start_btn.add_theme_font_size_override("font_size", 42)
	_start_btn.add_theme_color_override("font_color", Color(0.10, 0.05, 0.0))
	_start_btn.add_theme_color_override("font_hover_color", Color(0.08, 0.04, 0.0))
	_start_btn.add_theme_color_override("font_pressed_color", Color(0.08, 0.04, 0.0))
	_start_btn.add_theme_color_override("font_disabled_color", Color(0.60, 0.58, 0.50))
	_start_btn.add_theme_stylebox_override("normal", start_n)
	_start_btn.add_theme_stylebox_override("hover", start_h)
	_start_btn.add_theme_stylebox_override("pressed", start_p)
	_start_btn.add_theme_stylebox_override("disabled", start_d)
	_start_btn.size = Vector2(start_w, btn_h)
	_start_btn.position = Vector2(60.0 + back_w + gap, btn_y)
	_start_btn.focus_mode = Control.FOCUS_NONE
	_start_btn.pressed.connect(_on_start_pressed)
	add_child(_start_btn)

func _on_start_pressed() -> void:
	if _selected_data != null:
		character_chosen.emit(_selected_data)

func _on_back_pressed() -> void:
	back_to_menu.emit()

func _on_card_pressed(idx: int) -> void:
	if _card_locked.size() > idx and _card_locked[idx]:
		return
	if _card_iap.size() > idx and _card_iap[idx]:
		_open_store("character")
		return
	_select_card(idx)

func _select_card(idx: int) -> void:
	_selected_idx = idx
	_selected_data = _char_list[idx]
	if is_instance_valid(_start_btn):
		_start_btn.disabled = false

	for i in _card_list.size():
		var btn: Button = _card_list[i]
		if i == idx:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			var sel := StyleBoxFlat.new()
			sel.bg_color = Color(1.0, 0.97, 0.82, 1.0)
			sel.corner_radius_top_left = 20
			sel.corner_radius_top_right = 20
			sel.corner_radius_bottom_right = 20
			sel.corner_radius_bottom_left = 20
			sel.set_border_width_all(6)
			sel.border_color = Color(0.98, 0.72, 0.08, 1.0)
			sel.shadow_color = Color(0.98, 0.72, 0.08, 0.60)
			sel.shadow_size = 16
			sel.shadow_offset = Vector2(0, 5)
			btn.add_theme_stylebox_override("normal", sel)
			btn.add_theme_stylebox_override("hover", sel)
			btn.add_theme_stylebox_override("pressed", sel)
		else:
			btn.modulate = Color(1.0, 1.0, 1.0, 0.55)
			# Restore cream card styles so text remains readable.
			var n := StyleBoxFlat.new()
			n.bg_color = Color(1.0, 0.99, 0.96, 1.0)
			n.corner_radius_top_left = 20
			n.corner_radius_top_right = 20
			n.corner_radius_bottom_right = 20
			n.corner_radius_bottom_left = 20
			n.border_color = Color(0.82, 0.72, 0.55, 0.65)
			n.set_border_width_all(2)
			n.shadow_color = Color(0.25, 0.15, 0.05, 0.28)
			n.shadow_size = 10
			n.shadow_offset = Vector2(0, 4)
			var h := StyleBoxFlat.new()
			h.bg_color = Color(0.96, 0.94, 0.86, 1.0)
			h.corner_radius_top_left = 20
			h.corner_radius_top_right = 20
			h.corner_radius_bottom_right = 20
			h.corner_radius_bottom_left = 20
			h.border_color = Color(0.88, 0.68, 0.35, 0.9)
			h.set_border_width_all(3)
			h.shadow_color = Color(0.25, 0.15, 0.05, 0.35)
			h.shadow_size = 12
			h.shadow_offset = Vector2(0, 4)
			btn.add_theme_stylebox_override("normal", n)
			btn.add_theme_stylebox_override("hover", h)
			btn.add_theme_stylebox_override("pressed", n)

func _is_brown_locked(data: CharacterData) -> bool:
	if String(data.id) != "capy_brown":
		return false
	return not StatsStore.is_brown_unlocked(account_username)

func _is_iap_locked(data: CharacterData) -> bool:
	return PurchaseStore.PURCHASABLE.has(String(data.id)) and not PurchaseStore.is_purchased(String(data.id))

func _open_store(tab: String = "character") -> void:
	var store := StorePopup.new()
	store.account_username = account_username
	store.initial_tab = tab
	store.purchase_completed.connect(func(_product_id: String) -> void:
		_rebuild_cards()
	)
	add_child(store)

func _rebuild_cards() -> void:
	if not is_instance_valid(_cards_vbox):
		return
	for btn in _card_list:
		if is_instance_valid(btn):
			btn.queue_free()
	_card_list.clear()
	_card_locked.clear()
	_card_iap.clear()
	_selected_idx = -1
	_selected_data = null
	if is_instance_valid(_start_btn):
		_start_btn.disabled = true
	var card_h: float = 180.0
	for i in range(_char_list.size()):
		var data: CharacterData = _char_list[i]
		var locked: bool = _is_brown_locked(data)
		var iap: bool    = _is_iap_locked(data)
		var has_ulti: bool = CHAR_ULTI.has(String(data.id)) and not locked and not iap
		_card_locked.append(locked)
		_card_iap.append(iap)
		var h: float = 190.0 if locked else (240.0 if iap else (202.0 if has_ulti else card_h))
		var btn := _make_char_button(data, _card_w, h, i, locked, iap)
		_cards_vbox.add_child(btn)
		_card_list.append(btn)

func _make_char_button(data: CharacterData, card_w: float, card_h: float, idx: int, locked: bool = false, iap: bool = false) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(card_w, card_h)
	btn.size = Vector2(card_w, card_h)
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.clip_contents = true
	btn.pivot_offset = Vector2(card_w, card_h) * 0.5

	# Card background: dark purple for IAP, grey for locked, cream for normal.
	var bg_style := StyleBoxFlat.new()
	if iap:
		bg_style.bg_color = Color(0.14, 0.09, 0.22, 1.0)
		bg_style.border_color = Color(0.62, 0.35, 0.88, 0.70)
	elif locked:
		bg_style.bg_color = Color(0.80, 0.79, 0.78, 1.0)
		bg_style.border_color = Color(0.58, 0.55, 0.52, 0.65)
	else:
		bg_style.bg_color = Color(1.0, 0.99, 0.96, 1.0)
		bg_style.border_color = Color(0.82, 0.72, 0.55, 0.65)
	bg_style.corner_radius_top_left = 20
	bg_style.corner_radius_top_right = 20
	bg_style.corner_radius_bottom_right = 20
	bg_style.corner_radius_bottom_left = 20
	bg_style.set_border_width_all(2)
	bg_style.shadow_color = Color(0.25, 0.15, 0.05, 0.28)
	bg_style.shadow_size = 10
	bg_style.shadow_offset = Vector2(0, 4)
	btn.add_theme_stylebox_override("normal", bg_style)

	var hover_style := StyleBoxFlat.new()
	if iap:
		hover_style.bg_color = Color(0.20, 0.13, 0.32, 1.0)
		hover_style.border_color = Color(0.78, 0.50, 1.0, 0.90)
	elif locked:
		hover_style.bg_color = Color(0.80, 0.79, 0.78, 1.0)
		hover_style.border_color = Color(0.58, 0.55, 0.52, 0.65)
	else:
		hover_style.bg_color = Color(0.96, 0.94, 0.86, 1.0)
		hover_style.border_color = Color(0.88, 0.68, 0.35, 0.9)
	hover_style.corner_radius_top_left = 20
	hover_style.corner_radius_top_right = 20
	hover_style.corner_radius_bottom_right = 20
	hover_style.corner_radius_bottom_left = 20
	hover_style.set_border_width_all(3)
	hover_style.shadow_color = Color(0.25, 0.15, 0.05, 0.35)
	hover_style.shadow_size = 12
	hover_style.shadow_offset = Vector2(0, 4)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pad: float = 16.0
	const PORTRAIT_SIZE: float = 140.0
	var portrait_y: float = (card_h - PORTRAIT_SIZE) * 0.5
	var stats_x: float = pad + PORTRAIT_SIZE + pad
	var stats_w: float = card_w - stats_x - pad

	# Portrait panel — 140×140 rounded+clipped, identical to History cards.
	var portrait_panel := Panel.new()
	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.86, 0.82, 0.74)
	p_style.corner_radius_top_left = 14
	p_style.corner_radius_top_right = 14
	p_style.corner_radius_bottom_right = 14
	p_style.corner_radius_bottom_left = 14
	portrait_panel.add_theme_stylebox_override("panel", p_style)
	portrait_panel.position = Vector2(pad, portrait_y)
	portrait_panel.size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait_panel.clip_contents = true
	portrait_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(portrait_panel)

	var portrait: Texture2D = _load_portrait(String(data.id))
	if portrait != null:
		var portrait_rect := TextureRect.new()
		portrait_rect.texture = portrait
		portrait_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_panel.add_child(portrait_rect)
	else:
		var swatch := ColorRect.new()
		swatch.color = data.tint
		swatch.set_anchors_preset(Control.PRESET_FULL_RECT)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_panel.add_child(swatch)

	# Portrait panel — dim tint when locked.
	if locked:
		var dim := ColorRect.new()
		dim.color = Color(0.0, 0.0, 0.0, 0.38)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_panel.add_child(dim)

	# Character name.
	var name_lbl := Label.new()
	name_lbl.text = data.display_name
	name_lbl.add_theme_font_size_override("font_size", 38)
	name_lbl.add_theme_color_override("font_color",
		Color(0.12, 0.07, 0.02) if (not locked and not iap) else (Color(0.88, 0.82, 0.96) if iap else Color(0.52, 0.48, 0.44)))
	name_lbl.position = Vector2(stats_x, pad)
	name_lbl.size = Vector2(stats_w, 44)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_lbl)

	if locked:
		# ── Locked state: left column = name + 🔒 Locked,
		#                  right column = criteria + 3 progress rows ───────
		var left_w: float  = stats_w * 0.42
		var right_x: float = stats_x + left_w + 12.0
		var right_w: float = stats_w - left_w - 12.0

		# Restrict name label to left column only
		name_lbl.size = Vector2(left_w, name_lbl.size.y)

		var lock_lbl := Label.new()
		lock_lbl.text = "🔒 Locked"
		lock_lbl.add_theme_font_size_override("font_size", 32)
		lock_lbl.add_theme_color_override("font_color", Color(0.72, 0.15, 0.10))
		lock_lbl.position = Vector2(stats_x, pad + 46)
		lock_lbl.size = Vector2(left_w, 38)
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lock_lbl)

		# Right column: subtitle at top, then 3 progress rows
		var sub_lbl := Label.new()
		sub_lbl.text = "Win 3 games (5+ min) with each:"
		sub_lbl.add_theme_font_size_override("font_size", 28)
		sub_lbl.add_theme_color_override("font_color", Color(0.25, 0.18, 0.10))
		sub_lbl.position = Vector2(right_x, pad)
		sub_lbl.size = Vector2(right_w, 34)
		sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(sub_lbl)

		var prog := StatsStore.get_brown_unlock_progress(account_username)
		var rows := [
			["capy_zoomer", "Zoomer"],
			["capy_chef",   "Chef"],
			["capy_swamp",  "Swamp"],
		]
		var right_top: float = pad + 34.0
		var row_h: float     = 36.0
		for ri in rows.size():
			var row: Array = rows[ri]
			var cid: String = row[0] as String
			var cname: String = row[1] as String
			var count: int = prog.get(cid, 0) as int
			var dots: String = ""
			for d in 3:
				dots += ("●" if d < count else "○")
			var row_lbl := Label.new()
			row_lbl.text = cname + "  " + dots + "  " + str(count) + "/3"
			row_lbl.add_theme_font_size_override("font_size", 30)
			row_lbl.add_theme_color_override("font_color",
				Color(0.20, 0.62, 0.25) if count >= 3 else Color(0.30, 0.25, 0.18))
			row_lbl.position = Vector2(right_x, right_top + float(ri) * row_h)
			row_lbl.size = Vector2(right_w, row_h)
			row_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(row_lbl)
	elif iap:
		# ── IAP state: show premium badge + skills + Store direction ──────
		var badge_lbl := Label.new()
		badge_lbl.text = "✨ Premium Job"
		badge_lbl.add_theme_font_size_override("font_size", 30)
		badge_lbl.add_theme_color_override("font_color", Color(0.78, 0.52, 1.0))
		badge_lbl.position = Vector2(stats_x, pad + 44)
		badge_lbl.size = Vector2(stats_w, 34)
		badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(badge_lbl)

		var char_id: String = String(data.id)
		var skills_text: String = JOB_SKILLS.get(char_id, "") as String
		var sjobs_lbl := Label.new()
		sjobs_lbl.text = skills_text
		sjobs_lbl.add_theme_font_size_override("font_size", 28)
		sjobs_lbl.add_theme_color_override("font_color", Color(0.76, 0.72, 0.88))
		sjobs_lbl.position = Vector2(stats_x, pad + 86)
		sjobs_lbl.size = Vector2(stats_w, 58)
		sjobs_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sjobs_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(sjobs_lbl)

		var store_lbl := Label.new()
		store_lbl.text = "Available in Store"
		store_lbl.add_theme_font_size_override("font_size", 28)
		store_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.22))
		store_lbl.position = Vector2(stats_x, pad + 154)
		store_lbl.size = Vector2(stats_w, 32)
		store_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(store_lbl)
	else:
		# ── Unlocked state: show starting skill ──────────────────────────
		if not data.base_skill.is_empty():
			var skill_lbl := Label.new()
			var sname: String = SKILL_NAMES.get(data.base_skill, data.base_skill) as String
			skill_lbl.text = "Starts with: " + sname
			skill_lbl.add_theme_font_size_override("font_size", 30)
			skill_lbl.add_theme_color_override("font_color", Color(0.62, 0.38, 0.04))
			skill_lbl.position = Vector2(stats_x, pad + 52)
			skill_lbl.size = Vector2(stats_w, 28)
			skill_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(skill_lbl)

		# Ulti indicator with ⓘ info button — inline so icon is right next to label
		var char_id_str: String = String(data.id)
		if CHAR_ULTI.has(char_id_str):
			var ulti_sid_c: String  = CHAR_ULTI[char_id_str] as String
			var ulti_name_c: String = SKILL_NAMES.get(ulti_sid_c, ulti_sid_c) as String

			var ulti_row := HBoxContainer.new()
			ulti_row.position = Vector2(stats_x, pad + 82)
			ulti_row.custom_minimum_size = Vector2(stats_w, 32)
			ulti_row.size = Vector2(stats_w, 32)
			ulti_row.add_theme_constant_override("separation", 4)
			ulti_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(ulti_row)

			var ulti_lbl := Label.new()
			ulti_lbl.text = "✦ Ulti: " + ulti_name_c
			ulti_lbl.add_theme_font_size_override("font_size", 30)
			ulti_lbl.add_theme_color_override("font_color", Color(0.65, 0.20, 0.01))
			ulti_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			ulti_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			ulti_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ulti_row.add_child(ulti_lbl)

			var info_btn := Button.new()
			info_btn.text = "ⓘ"
			info_btn.custom_minimum_size = Vector2(32, 32)
			var info_ns := StyleBoxFlat.new()
			info_ns.bg_color = Color(0.0, 0.0, 0.0, 0.0)
			var info_hs := StyleBoxFlat.new()
			info_hs.bg_color = Color(0.65, 0.20, 0.01, 0.12)
			info_hs.corner_radius_top_left    = 6
			info_hs.corner_radius_top_right   = 6
			info_hs.corner_radius_bottom_right = 6
			info_hs.corner_radius_bottom_left  = 6
			info_btn.add_theme_stylebox_override("normal", info_ns)
			info_btn.add_theme_stylebox_override("hover", info_hs)
			info_btn.add_theme_stylebox_override("pressed", info_hs)
			info_btn.add_theme_color_override("font_color", Color(0.65, 0.20, 0.01))
			info_btn.add_theme_color_override("font_hover_color", Color(0.65, 0.20, 0.01))
			info_btn.add_theme_color_override("font_pressed_color", Color(0.45, 0.12, 0.00))
			info_btn.add_theme_font_size_override("font_size", 30)
			info_btn.focus_mode = Control.FOCUS_NONE
			var cap_char: String = char_id_str
			var cap_ulti: String = ulti_sid_c
			info_btn.pressed.connect(func() -> void: _show_ulti_info(cap_char, cap_ulti))
			ulti_row.add_child(info_btn)

	btn.pressed.connect(func() -> void: _on_card_pressed(idx))
	return btn

func _show_ulti_info(_char_id: String, ulti_sid: String) -> void:
	var view := get_viewport_rect().size
	var ulti_name: String = SKILL_NAMES.get(ulti_sid, ulti_sid) as String
	var desc: String      = ULTI_DESC.get(ulti_sid, "An unstoppable ultimate skill exclusive to this character.") as String

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	overlay.size  = view
	overlay.z_index = 110
	add_child(overlay)

	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.07, 0.02, 1.0)
	ps.corner_radius_top_left    = 24
	ps.corner_radius_top_right   = 24
	ps.corner_radius_bottom_right = 24
	ps.corner_radius_bottom_left  = 24
	ps.border_color = Color(1.0, 0.78, 0.10, 0.90)
	ps.set_border_width_all(3)
	ps.shadow_color = Color(1.0, 0.65, 0.05, 0.38)
	ps.shadow_size  = 18
	panel.add_theme_stylebox_override("panel", ps)
	var pw: float = 560.0
	var ph: float = 360.0
	panel.position = Vector2((view.x - pw) * 0.5, (view.y - ph) * 0.5)
	panel.custom_minimum_size = Vector2(pw, ph)
	panel.z_index = 111
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "✦ Ultimate Skill"
	title_lbl.add_theme_font_size_override("font_size", 32)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.10))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var name_lbl := Label.new()
	name_lbl.text = ulti_name
	name_lbl.add_theme_font_size_override("font_size", 42)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.55))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var sep := HSeparator.new()
	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(1.0, 0.72, 0.10, 0.40)
	sep_s.content_margin_top = 2; sep_s.content_margin_bottom = 2
	sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 30)
	desc_lbl.add_theme_color_override("font_color", Color(0.88, 0.82, 0.68))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	var close_btn := Button.new()
	close_btn.text = "Got it!"
	close_btn.custom_minimum_size = Vector2(160, 50)
	var cb_s := StyleBoxFlat.new()
	cb_s.bg_color = Color(0.70, 0.45, 0.05)
	cb_s.corner_radius_top_left    = 14
	cb_s.corner_radius_top_right   = 14
	cb_s.corner_radius_bottom_right = 14
	cb_s.corner_radius_bottom_left  = 14
	close_btn.add_theme_stylebox_override("normal", cb_s)
	close_btn.add_theme_color_override("font_color", Color(1, 1, 1))
	close_btn.add_theme_font_size_override("font_size", 34)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(close_btn)

	close_btn.pressed.connect(func() -> void:
		overlay.queue_free()
		panel.queue_free()
	)
	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			overlay.queue_free()
			panel.queue_free()
	)

func _load_portrait(char_id: String) -> Texture2D:
	if char_id == "":
		return null
	for ext in PORTRAIT_EXTS:
		var path: String = PORTRAIT_DIR + char_id + ext
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null

func _show_empty_state() -> void:
	var view := get_viewport_rect().size
	var msg := Label.new()
	msg.text = "No characters found in\nres://resources/characters/"
	msg.add_theme_font_size_override("font_size", 36)
	msg.add_theme_color_override("font_color", Color(0.6, 0.1, 0.1))
	msg.position = Vector2(0, view.y * 0.5 - 40)
	msg.size = Vector2(view.x, 100)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(msg)
