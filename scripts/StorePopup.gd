class_name StorePopup
extends CanvasLayer

signal purchase_completed(product_id: String)
signal closed

const JOB_SKILLS: Dictionary = {
	"capy_wizard":   "Fireball · Electric Wave · Hurricane · Blizzard",
	"capy_archer":   "Power Arrow · Split Arrow · Pierce Arrow · Sky Fall",
	"capy_assassin": "Star Knife · Knife Storm · Boomerang · 7 Slash",
}
const PORTRAIT_DIR := "res://assets/characters/"
const PORTRAIT_EXTS: Array[String] = [".png", ".webp", ".jpg", ".svg"]

var account_username: String = ""
var initial_tab: String = "character"

var _view: Vector2 = Vector2.ZERO
var _active_tab: String = "character"
var _content: VBoxContainer = null
var _character_tab: Button = null
var _ring_tab: Button = null
var _key_tab: Button = null
var _status_lbl: Label = null

func _ready() -> void:
	_view = get_viewport().get_visible_rect().size
	_active_tab = initial_tab
	PurchaseStore.set_username(account_username)
	_build_ui()
	_show_tab(_active_tab)

func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.74)
	overlay.size = _view
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.11, 0.08, 0.16, 1.0)
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.corner_radius_bottom_right = 24
	panel_style.corner_radius_bottom_left = 24
	panel_style.border_color = Color(0.76, 0.56, 0.24, 0.86)
	panel_style.set_border_width_all(3)
	panel_style.content_margin_left = 34
	panel_style.content_margin_right = 34
	panel_style.content_margin_top = 30
	panel_style.content_margin_bottom = 30
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	panel_style.shadow_size = 18
	panel.add_theme_stylebox_override("panel", panel_style)
	var pw: float = min(_view.x - 44.0, 620.0)
	var ph: float = min(_view.y - 80.0, 850.0)
	panel.position = Vector2((_view.x - pw) * 0.5, (_view.y - ph) * 0.5)
	panel.custom_minimum_size = Vector2(pw, ph)
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(root)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(top_row)

	var title := Label.new()
	title.text = "Store"
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.36))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.custom_minimum_size = Vector2(132, 50)
	close_btn.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	top_row.add_child(close_btn)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(tabs)

	_character_tab = _make_tab_button("Character")
	_character_tab.pressed.connect(func() -> void: _show_tab("character"))
	tabs.add_child(_character_tab)

	_ring_tab = _make_tab_button("Ring")
	_ring_tab.pressed.connect(func() -> void: _show_tab("ring"))
	tabs.add_child(_ring_tab)

	_key_tab = _make_tab_button("Key")
	_key_tab.pressed.connect(func() -> void: _show_tab("key"))
	tabs.add_child(_key_tab)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.scroll_started.connect(func() -> void: pass)  # Enable momentum scrolling
	root.add_child(scroll)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 16)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)

	_status_lbl = Label.new()
	_status_lbl.text = ""
	_status_lbl.add_theme_font_size_override("font_size", 24)
	_status_lbl.add_theme_color_override("font_color", Color(0.88, 0.78, 0.62))
	_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(_status_lbl)

	var diag := Label.new()
	diag.add_theme_font_size_override("font_size", 20)
	diag.add_theme_color_override("font_color", Color(0.50, 0.50, 0.50))
	diag.autowrap_mode = TextServer.AUTOWRAP_WORD
	var has_plugin: bool = Engine.has_singleton("GodotGooglePlayBilling")
	var billing_state: String = "n/a"
	if has_plugin:
		billing_state = str(PurchaseStore._billing_ready)
	diag.text = "[diag] OS:%s plugin:%s billing_ready:%s" % [OS.get_name(), str(has_plugin), billing_state]
	root.add_child(diag)

func _make_tab_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 30)
	btn.custom_minimum_size = Vector2(0, 58)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return btn

func _show_tab(tab: String) -> void:
	_active_tab = tab
	_update_tab_style(_character_tab, tab == "character")
	_update_tab_style(_ring_tab, tab == "ring")
	_update_tab_style(_key_tab, tab == "key")
	for child in _content.get_children():
		child.queue_free()
	if tab == "ring":
		_build_ring_tab()
	elif tab == "key":
		_build_key_tab()
	else:
		_build_character_tab()

func _update_tab_style(btn: Button, active: bool) -> void:
	if btn == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.78, 0.48, 0.12, 1.0) if active else Color(0.20, 0.16, 0.24, 1.0)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.border_color = Color(1.0, 0.78, 0.26, 0.9) if active else Color(0.48, 0.40, 0.55, 0.8)
	style.set_border_width_all(2)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", Color(0.10, 0.05, 0.0) if active else Color(0.86, 0.82, 0.92))

func _build_character_tab() -> void:
	var chars: Array[CharacterData] = CharacterLoader.load_all()
	for product_id in PurchaseStore.CHARACTER_PRODUCTS:
		var data: CharacterData = _find_character(chars, product_id)
		var display_name: String = data.display_name if data != null else product_id
		var desc: String = JOB_SKILLS.get(product_id, "Premium character") as String
		_content.add_child(_make_product_card(product_id, display_name, "Premium Job", desc, false, false))

func _build_ring_tab() -> void:
	for product_id in PurchaseStore.RING_PRODUCTS.keys():
		var ring: Dictionary = PurchaseStore.ring_product_to_ring(product_id as String)
		var desc: String = ring.get("desc", "") as String
		desc += "\nShared from your ring stash across all available characters."
		_content.add_child(_make_product_card(product_id as String, ring.get("name", "Ring") as String, "Store Ring", desc, true, false))

func _build_key_tab() -> void:
	var ordered_ids: Array[String] = ["key_pack_1", "key_pack_3", "key_pack_5", "key_pack_10"]
	for product_id in ordered_ids:
		if not PurchaseStore.KEY_PRODUCTS.has(product_id):
			continue
		var data: Dictionary = PurchaseStore.KEY_PRODUCTS[product_id] as Dictionary
		var keys: int = int(data.get("keys", 0))
		var bonus: int = int(data.get("bonus_keys", 0))
		var desc: String = "Spend door keys to enter boss-room challenge doors after boss waves.\nEach key pack can be purchased once per week."
		if bonus > 0:
			desc += "\nIncludes %d free key%s." % [bonus, "s" if bonus != 1 else ""]
		var title: String = "Door Key x%d" % keys
		if bonus > 0:
			title += " (+%d free)" % bonus
		_content.add_child(_make_product_card(product_id, title, "Key Pack", desc, false, true))

func _make_product_card(product_id: String, title: String, badge: String, desc: String, is_ring: bool, is_key: bool) -> Control:
	var ring: Dictionary = PurchaseStore.ring_product_to_ring(product_id) if is_ring else {}
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = _rarity_bg_color(ring.get("rarity", "") as String) if is_ring else Color(0.17, 0.13, 0.22, 1.0)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.border_color = _rarity_color(ring.get("rarity", "") as String) if is_ring else Color(0.58, 0.44, 0.70, 0.75)
	style.set_border_width_all(2)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	card.add_theme_stylebox_override("panel", style)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_PASS  # Allow scrolling input to pass through

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_PASS  # Allow scrolling through row
	card.add_child(row)

	if is_ring:
		row.add_child(_make_ring_icon(ring, 118.0))
	elif is_key:
		row.add_child(_make_key_icon())
	else:
		row.add_child(_make_character_portrait(product_id))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.mouse_filter = Control.MOUSE_FILTER_PASS  # Allow scrolling through box
	row.add_child(box)

	var badge_lbl := Label.new()
	badge_lbl.text = badge
	badge_lbl.add_theme_font_size_override("font_size", 24)
	badge_lbl.add_theme_color_override("font_color", Color(1.0, 0.76, 0.28))
	box.add_child(badge_lbl)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 34)
	title_lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 1.0))
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.add_theme_font_size_override("font_size", 25)
	desc_lbl.add_theme_color_override("font_color", Color(0.78, 0.74, 0.86))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(desc_lbl)

	if is_ring:
		var bonus_lbl := Label.new()
		bonus_lbl.text = "Effect: " + _format_ring_bonus(ring)
		bonus_lbl.add_theme_font_size_override("font_size", 25)
		bonus_lbl.add_theme_color_override("font_color", Color(0.55, 0.95, 0.70))
		bonus_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		box.add_child(bonus_lbl)

	var buy_btn := Button.new()
	var owned: bool = PurchaseStore.is_purchased(product_id) if not is_key else not PurchaseStore.can_buy_key_product_this_week(product_id)
	var price: String = PurchaseStore.PRICES.get(product_id, "") as String
	if is_key:
		buy_btn.text = "Bought this week" if owned else "Buy " + price
	else:
		buy_btn.text = "Owned" if owned else "Buy " + price
	buy_btn.disabled = owned
	buy_btn.add_theme_font_size_override("font_size", 30)
	buy_btn.custom_minimum_size = Vector2(0, 56)
	buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_btn.pressed.connect(func() -> void: _purchase(product_id, buy_btn))
	box.add_child(buy_btn)

	return card

func _make_key_icon() -> Control:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.24, 0.18, 0.10, 1.0)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.border_color = Color(1.0, 0.78, 0.26, 0.9)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(118, 118)
	panel.size = Vector2(118, 118)

	var lbl := Label.new()
	lbl.text = "KEY"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.38))
	panel.add_child(lbl)
	return panel

func _make_character_portrait(char_id: String) -> Control:
	const PORTRAIT_SIZE: float = 126.0
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.24, 0.18, 0.30, 1.0)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.border_color = Color(0.72, 0.54, 0.88, 0.75)
	style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	panel.size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	panel.clip_contents = true
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var portrait: Texture2D = _load_portrait(char_id)
	if portrait != null:
		var texture_rect := TextureRect.new()
		texture_rect.texture = portrait
		texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(texture_rect)
	else:
		var swatch := ColorRect.new()
		swatch.color = Color(0.46, 0.34, 0.58, 1.0)
		swatch.set_anchors_preset(Control.PRESET_FULL_RECT)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(swatch)
	return panel

func _make_ring_icon(ring: Dictionary, icon_size: float) -> Control:
	var icon: Texture2D = RingStore.ring_icon(ring)
	if icon != null:
		var texture_rect := TextureRect.new()
		texture_rect.texture = icon
		texture_rect.custom_minimum_size = Vector2(icon_size, icon_size)
		texture_rect.size = Vector2(icon_size, icon_size)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return texture_rect
	else:
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(icon_size, icon_size)
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return spacer

func _load_portrait(char_id: String) -> Texture2D:
	if char_id == "":
		return null
	for ext in PORTRAIT_EXTS:
		var path: String = PORTRAIT_DIR + char_id + ext
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null

func _purchase(product_id: String, buy_btn: Button) -> void:
	buy_btn.disabled = true
	buy_btn.text = "Processing..."
	_status_lbl.text = ""
	PurchaseStore.purchase_success.connect(func(done_id: String) -> void:
		if done_id != product_id:
			return
		_status_lbl.text = "Purchase complete."
		purchase_completed.emit(product_id)
		_show_tab(_active_tab)
	, CONNECT_ONE_SHOT)
	PurchaseStore.purchase_failed.connect(func(done_id: String, message: String) -> void:
		if done_id != product_id:
			return
		_status_lbl.text = message
		_show_tab(_active_tab)
	, CONNECT_ONE_SHOT)
	PurchaseStore.purchase(product_id)

func _find_character(chars: Array[CharacterData], product_id: String) -> CharacterData:
	for data in chars:
		if String(data.id) == product_id:
			return data
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

func _rarity_color(rarity: String) -> Color:
	return RingStore.RARITY_COLORS.get(rarity, Color(0.58, 0.44, 0.70)) as Color

func _rarity_bg_color(rarity: String) -> Color:
	var color: Color = _rarity_color(rarity)
	return Color(0.10, 0.08, 0.14).lerp(color, 0.26)