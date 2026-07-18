class_name StoryInventory
extends Node2D

signal confirmed(character: CharacterData)
signal back_requested
signal cloud_sync_requested
signal accessories_requested
signal edit_applied
signal edit_cancelled

const CAMP_COIN_ICON := preload("res://assets/camp/resources/camp_coin.png")
const FORGECORE_MATERIAL_ICON := preload("res://assets/camp/resources/forgecore_material.png")

var selected_character: CharacterData
var account_username := ""
var equipment_edit_mode := false
var _layer: CanvasLayer
var _popup: CanvasLayer

func _ready() -> void:
	_build()

func _build() -> void:
	if _layer != null and is_instance_valid(_layer): _layer.queue_free()
	_layer = CanvasLayer.new(); add_child(_layer)
	var view := get_viewport_rect().size
	var bg := TextureRect.new(); bg.texture = load("res://assets/backgrounds/bg_preparation_stage.png") as Texture2D; bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.stretch_mode = TextureRect.STRETCH_SCALE; bg.size = view; _layer.add_child(bg)
	var shade := ColorRect.new(); shade.color = Color(0.01, 0.03, 0.04, 0.48); shade.size = view; _layer.add_child(shade)
	var title := Label.new(); title.text = "STORY LOADOUT"; title.position = Vector2(0, 30); title.size = Vector2(view.x, 70); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 52); title.add_theme_color_override("font_color", Color("ffd66b")); _layer.add_child(title)
	var portrait_frame := Control.new(); portrait_frame.position = Vector2(300, 205); portrait_frame.size = Vector2(view.x - 600, 585); portrait_frame.clip_contents = true; portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE; _layer.add_child(portrait_frame)
	var portrait := TextureRect.new(); portrait.texture = load("res://assets/characters/%s.png" % String(selected_character.id)) as Texture2D; portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE; portrait_frame.add_child(portrait)
	var char_name := Label.new(); char_name.text = selected_character.display_name; char_name.position = Vector2((view.x - 360) * 0.5, 738); char_name.size = Vector2(360, 48); char_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; char_name.add_theme_font_size_override("font_size", 30); _layer.add_child(char_name)
	var positions := {"headwear":Vector2(55, 205), "weapon":Vector2(view.x - 285, 205), "armor":Vector2(55, 410), "offhand":Vector2(view.x - 285, 410), "pants":Vector2(55, 615), "boots":Vector2(view.x - 285, 615)}
	var profile := StoryStore.load_profile(account_username)
	var equipped: Dictionary = profile.get("equipped", {}) as Dictionary
	for slot in StoryStore.SLOTS:
		_add_slot(String(slot), positions[slot] as Vector2, String(equipped.get(slot, "")), profile)
	var info := Button.new(); info.text = "Equipment Stats"; info.position = Vector2(55, 805); info.size = Vector2(230, 62); info.add_theme_font_size_override("font_size", 23); info.pressed.connect(_show_stats); _style_button(info); _layer.add_child(info)
	var wallet := HBoxContainer.new(); wallet.position = Vector2(300, 790); wallet.size = Vector2(view.x - 600, 70); wallet.alignment = BoxContainer.ALIGNMENT_CENTER; wallet.add_theme_constant_override("separation", 22); _layer.add_child(wallet)
	_add_resource_counter(wallet, FORGECORE_MATERIAL_ICON, int(profile.get("materials", 0)), "Upgrade Materials")
	_add_resource_counter(wallet, CAMP_COIN_ICON, int(ProgressionStore.load_profile(account_username).get("coins", 0)), "Camp Coins")
	if not equipment_edit_mode:
		var accessories := Button.new(); accessories.text = "Accessories"; accessories.position = Vector2(view.x - 285, 805); accessories.size = Vector2(230, 62); accessories.add_theme_font_size_override("font_size", 23); accessories.pressed.connect(func() -> void: accessories_requested.emit()); _style_button(accessories); _layer.add_child(accessories)
	var stash_title := Label.new(); stash_title.text = "EQUIPMENT STASH"; stash_title.position = Vector2(40, 880); stash_title.size = Vector2(view.x - 80, 55); stash_title.add_theme_font_size_override("font_size", 40); _layer.add_child(stash_title)
	var scroll := ScrollContainer.new(); scroll.position = Vector2(35, 940); scroll.size = Vector2(view.x - 70, view.y - 1080); _layer.add_child(scroll)
	var grid := GridContainer.new(); grid.columns = 3; grid.custom_minimum_size = Vector2(view.x - 95, 0); grid.add_theme_constant_override("h_separation", 12); grid.add_theme_constant_override("v_separation", 12); scroll.add_child(grid)
	for gear_id in profile.get("owned", []) as Array:
		_add_stash_card(grid, String(gear_id), profile)
	if (profile.get("owned", []) as Array).is_empty():
		var empty := Label.new(); empty.text = "Claim treasure chests on the chapter map to collect equipment."; empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; empty.custom_minimum_size = Vector2(view.x - 100, 100); empty.add_theme_font_size_override("font_size", 30); grid.add_child(empty)
	var back := Button.new(); back.text = "Cancel" if equipment_edit_mode else "Character"; back.position = Vector2(35, view.y - 105); back.size = Vector2(260, 74); back.add_theme_font_size_override("font_size", 28); back.pressed.connect(func():
		if equipment_edit_mode: edit_cancelled.emit()
		else: back_requested.emit()
	); _style_button(back); _layer.add_child(back)
	var play := Button.new(); play.text = "Apply" if equipment_edit_mode else "ENTER STORY"; play.position = Vector2(view.x - 365, view.y - 105); play.size = Vector2(330, 74); play.add_theme_font_size_override("font_size", 30); play.pressed.connect(_on_enter_pressed); _style_button(play, true); _layer.add_child(play)

func _on_enter_pressed() -> void:
	if equipment_edit_mode:
		edit_applied.emit()
		return
	var warnings := _loadout_warning_lines()
	if warnings.is_empty():
		confirmed.emit(selected_character)
	else:
		_show_loadout_warning(warnings, func() -> void: confirmed.emit(selected_character))

func _loadout_warning_lines() -> Array[String]:
	var warnings: Array[String] = []
	var profile := StoryStore.load_profile(account_username)
	var equipped: Dictionary = profile.get("equipped", {}) as Dictionary
	for gear_id_variant in profile.get("owned", []) as Array:
		var gear_id := String(gear_id_variant)
		if not StoryStore.GEAR.has(gear_id): continue
		var slot := String((StoryStore.GEAR[gear_id] as Dictionary).get("slot", ""))
		if String(equipped.get(slot, "")).is_empty():
			warnings.append("Equipment is available for an empty %s slot." % _slot_name(slot))
			break
	var character_id := String(selected_character.id)
	if _has_open_accessory_slot(RingStore.load_stash(account_username), RingStore.get_equipped_rings(account_username, character_id)):
		warnings.append("A ring is available for an empty accessory slot.")
	if _has_open_accessory_slot(ArtifactStore.load_stash(account_username), ArtifactStore.get_equipped_artifacts(account_username, character_id)):
		warnings.append("An artifact is available for an empty accessory slot.")
	return warnings

func _has_open_accessory_slot(stash: Array, equipped: Dictionary) -> bool:
	if equipped.get("slot_0", null) != null and equipped.get("slot_1", null) != null:
		return false
	for item_variant in stash:
		if typeof(item_variant) != TYPE_DICTIONARY: continue
		var item := item_variant as Dictionary
		var item_id := String(item.get("id", ""))
		var already_equipped := false
		for slot_index in 2:
			var equipped_item = equipped.get("slot_%d" % slot_index, null)
			if equipped_item != null and typeof(equipped_item) == TYPE_DICTIONARY and String((equipped_item as Dictionary).get("id", "")) == item_id:
				already_equipped = true
				break
		if not already_equipped: return true
	return false

func _show_loadout_warning(warnings: Array[String], proceed: Callable) -> void:
	_close_popup(); _popup = CanvasLayer.new(); _popup.layer = 170; add_child(_popup)
	var view := get_viewport_rect().size
	var shade := ColorRect.new(); shade.color = Color(0, 0, 0, 0.84); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; _popup.add_child(shade)
	var panel := PanelContainer.new(); panel.position = Vector2(70, view.y * 0.28); panel.size = Vector2(view.x - 140, 460); panel.add_theme_stylebox_override("panel", _panel_style()); _popup.add_child(panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 22); panel.add_child(box)
	var title := Label.new(); title.text = "UNEQUIPPED ITEMS"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 44); title.add_theme_color_override("font_color", Color("ffd66b")); box.add_child(title)
	var message := Label.new(); message.text = "You have items that can fill empty slots:\n\n• %s\n\nEquip them before entering, or proceed with the current loadout." % "\n• ".join(warnings); message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; message.add_theme_font_size_override("font_size", 29); box.add_child(message)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 16); box.add_child(row)
	var cancel := Button.new(); cancel.text = "Cancel"; cancel.custom_minimum_size = Vector2(0, 82); cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; cancel.add_theme_font_size_override("font_size", 31); cancel.pressed.connect(_close_popup); _style_button(cancel); row.add_child(cancel)
	var continue_btn := Button.new(); continue_btn.text = "Proceed"; continue_btn.custom_minimum_size = Vector2(0, 82); continue_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL; continue_btn.add_theme_font_size_override("font_size", 31); continue_btn.pressed.connect(func() -> void: _close_popup(); proceed.call()); _style_button(continue_btn, true); row.add_child(continue_btn)

func _add_resource_counter(parent: Container, texture: Texture2D, amount: int, tooltip: String, icon_size: int = 42, font_size: int = 29) -> void:
	var counter := HBoxContainer.new()
	counter.add_theme_constant_override("separation", 6)
	counter.tooltip_text = tooltip
	parent.add_child(counter)
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter.add_child(icon)
	var value := Label.new()
	value.text = str(amount)
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", font_size)
	value.add_theme_color_override("font_color", Color("ffcf69"))
	counter.add_child(value)

func _add_slot(slot: String, pos: Vector2, gear_id: String, profile: Dictionary) -> void:
	var button := Button.new(); button.position = pos; button.size = Vector2(230, 175); button.add_theme_font_size_override("font_size", 28); button.clip_contents = true; _style_card(button)
	if gear_id.is_empty(): button.text = _slot_name(slot)
	else:
		button.text = ""
		var icon := TextureRect.new(); icon.texture = load("res://assets/story/equipment/%s.png" % gear_id) as Texture2D; icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); icon.offset_left = 4; icon.offset_top = 4; icon.offset_right = -4; icon.offset_bottom = -4; icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.pivot_offset = Vector2(111, 83); icon.scale = Vector2(1.28, 1.28); icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; button.add_child(icon)
		button.tooltip_text = "%s  ·  Lv.%d\n%s" % [String((StoryStore.GEAR[gear_id] as Dictionary).name), StoryStore.gear_level(profile, gear_id), StoryStore.scaled_effect_text(profile, gear_id)]
		button.pressed.connect(_show_item.bind(gear_id))
	_layer.add_child(button)

func _slot_name(slot: String) -> String:
	match slot:
		"headwear": return "Headgear"
		"pants": return "Pant"
		"boots": return "Boot"
		_: return slot.capitalize()

func _add_stash_card(parent: GridContainer, gear_id: String, profile: Dictionary) -> void:
	var gear: Dictionary = StoryStore.GEAR[gear_id] as Dictionary
	var button := Button.new(); button.custom_minimum_size = Vector2(315, 310); button.text = ""; button.clip_contents = true; _style_card(button)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); margin.add_theme_constant_override("margin_left", 10); margin.add_theme_constant_override("margin_right", 10); margin.add_theme_constant_override("margin_top", 8); margin.add_theme_constant_override("margin_bottom", 8); margin.mouse_filter = Control.MOUSE_FILTER_IGNORE; button.add_child(margin)
	var box := VBoxContainer.new(); box.mouse_filter = Control.MOUSE_FILTER_IGNORE; margin.add_child(box)
	var level := Label.new(); level.text = "Lv.%d  ·  %s" % [StoryStore.gear_level(profile, gear_id), String(gear.name)]; level.add_theme_font_size_override("font_size", 24); level.add_theme_color_override("font_color", Color(1.0, 0.87, 0.58)); level.clip_text = true; box.add_child(level)
	var icon := TextureRect.new(); icon.texture = load("res://assets/story/equipment/%s.png" % gear_id) as Texture2D; icon.custom_minimum_size = Vector2(0, 205); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; box.add_child(icon)
	var type := Label.new(); type.text = _slot_name(String(gear.slot)); type.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; type.add_theme_font_size_override("font_size", 26); type.add_theme_color_override("font_color", Color(0.94, 0.85, 0.68)); box.add_child(type)
	if StoryStore.is_equipped(profile, gear_id):
		var badge := Label.new(); badge.text = "E"; badge.position = Vector2(270, 248); badge.size = Vector2(34, 34); badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; badge.add_theme_font_size_override("font_size", 25); badge.add_theme_color_override("font_color", Color(0.05, 0.03, 0.0)); badge.add_theme_stylebox_override("normal", _badge_style()); badge.mouse_filter = Control.MOUSE_FILTER_IGNORE; button.add_child(badge)
	button.pressed.connect(_show_item.bind(gear_id)); parent.add_child(button)

func _show_item(gear_id: String) -> void:
	_close_popup(); _popup = CanvasLayer.new(); _popup.layer = 150; add_child(_popup)
	var view := get_viewport_rect().size
	var shade := ColorRect.new(); shade.color = Color(0, 0, 0, 0.78); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; _popup.add_child(shade)
	var panel := PanelContainer.new(); panel.position = Vector2(90, view.y * 0.18); panel.size = Vector2(view.x - 180, 850); panel.add_theme_stylebox_override("panel", _panel_style()); _popup.add_child(panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 10); panel.add_child(box)
	var profile := StoryStore.load_profile(account_username); var gear: Dictionary = StoryStore.GEAR[gear_id] as Dictionary; var level := StoryStore.gear_level(profile, gear_id)
	var icon := TextureRect.new(); icon.texture = load("res://assets/story/equipment/%s.png" % gear_id) as Texture2D; icon.custom_minimum_size = Vector2(0, 175); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; box.add_child(icon)
	var name := Label.new(); name.text = "%s  ·  Lv.%d" % [String(gear.name), level]; name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; name.add_theme_font_size_override("font_size", 38); box.add_child(name)
	var stats := Label.new(); stats.text = StoryStore.scaled_effect_text(profile, gear_id); stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; stats.add_theme_font_size_override("font_size", 30); box.add_child(stats)
	var equipped_now := StoryStore.is_equipped(profile, gear_id)
	var equip := Button.new(); equip.text = "UNEQUIP" if equipped_now else "EQUIP"; equip.custom_minimum_size = Vector2(0, 78); equip.add_theme_font_size_override("font_size", 30); equip.pressed.connect(func():
		if equipped_now: StoryStore.unequip(account_username, gear_id)
		else: StoryStore.equip(account_username, gear_id)
		cloud_sync_requested.emit()
		_close_popup(); _build()
	); _style_button(equip, true); box.add_child(equip)
	var cost := StoryStore.upgrade_cost(profile, gear_id)
	if level < StoryStore.MAX_GEAR_LEVEL:
		var cost_row := HBoxContainer.new(); cost_row.alignment = BoxContainer.ALIGNMENT_CENTER; cost_row.add_theme_constant_override("separation", 18); box.add_child(cost_row)
		var cost_label := Label.new(); cost_label.text = "Upgrade Cost"; cost_label.add_theme_font_size_override("font_size", 27); cost_row.add_child(cost_label)
		_add_resource_counter(cost_row, FORGECORE_MATERIAL_ICON, int(cost.materials), "Upgrade Materials", 38, 27)
		_add_resource_counter(cost_row, CAMP_COIN_ICON, int(cost.coins), "Camp Coins", 38, 27)
	var upgrade := Button.new(); upgrade.text = "UPGRADE" if level < StoryStore.MAX_GEAR_LEVEL else "MAXIMUM LEVEL"; upgrade.disabled = level >= StoryStore.MAX_GEAR_LEVEL; upgrade.custom_minimum_size = Vector2(0, 72); upgrade.add_theme_font_size_override("font_size", 30); upgrade.pressed.connect(_upgrade.bind(gear_id, upgrade)); _style_button(upgrade); box.add_child(upgrade)
	var refund := StoryStore.reset_material_refund(profile, gear_id)
	var coin_refund := StoryStore.reset_coin_refund(profile, gear_id)
	if refund > 0:
		var refund_row := HBoxContainer.new(); refund_row.alignment = BoxContainer.ALIGNMENT_CENTER; refund_row.add_theme_constant_override("separation", 18); box.add_child(refund_row)
		var refund_label := Label.new(); refund_label.text = "Full Refund"; refund_label.add_theme_font_size_override("font_size", 27); refund_row.add_child(refund_label)
		_add_resource_counter(refund_row, FORGECORE_MATERIAL_ICON, refund, "Upgrade Materials", 38, 27)
		_add_resource_counter(refund_row, CAMP_COIN_ICON, coin_refund, "Camp Coins", 38, 27)
	var reset := Button.new(); reset.text = "RESET TO LEVEL 1"; reset.disabled = refund <= 0; reset.custom_minimum_size = Vector2(0, 72); reset.add_theme_font_size_override("font_size", 28); reset.pressed.connect(_reset_upgrade.bind(gear_id, reset)); _style_button(reset); box.add_child(reset)
	var close := Button.new(); close.text = "Close"; close.custom_minimum_size = Vector2(0, 68); close.add_theme_font_size_override("font_size", 32); close.pressed.connect(_close_popup); _style_button(close); box.add_child(close)

func _upgrade(gear_id: String, button: Button) -> void:
	var error := StoryStore.upgrade(account_username, gear_id)
	if error.is_empty(): cloud_sync_requested.emit(); _close_popup(); _build()
	else: button.text = error

func _reset_upgrade(gear_id: String, button: Button) -> void:
	if not bool(button.get_meta("confirm_reset", false)):
		button.set_meta("confirm_reset", true)
		button.text = "TAP AGAIN TO CONFIRM FULL REFUND"
		return
	var refunded := StoryStore.reset_upgrade(account_username, gear_id)
	if refunded > 0:
		cloud_sync_requested.emit()
	_close_popup()
	_build()

func _show_stats() -> void:
	_close_popup(); _popup = CanvasLayer.new(); _popup.layer = 150; add_child(_popup)
	var view := get_viewport_rect().size; var shade := ColorRect.new(); shade.color = Color(0,0,0,0.82); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; _popup.add_child(shade)
	var bonuses := StoryStore.bonuses(account_username)
	var character_id := str(selected_character.id)
	for source in [RingStore.get_bonuses(account_username, character_id), ArtifactStore.get_bonuses(account_username, character_id)]:
		for key in source: bonuses[key] = float(bonuses.get(key, 0.0)) + float(source[key])
	var lines: Array[String] = []
	for key in bonuses: lines.append("%s: %s" % [StoryStore.stat_name(String(key)), StoryStore.stat_value_text(String(key), float(bonuses[key]))])
	var panel_height := minf(820.0, view.y - 180.0)
	var panel := PanelContainer.new(); panel.position = Vector2(70, (view.y - panel_height) * 0.5); panel.size = Vector2(view.x - 140, panel_height); panel.add_theme_stylebox_override("panel", _panel_style()); _popup.add_child(panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 20); panel.add_child(box)
	var title := Label.new(); title.text = "ALL EQUIPPED STATS"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 42); title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.34)); box.add_child(title)
	var subtitle := Label.new(); subtitle.text = "Equipment, Rings, and Artifacts"; subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; subtitle.add_theme_font_size_override("font_size", 28); box.add_child(subtitle)
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; box.add_child(scroll)
	var label := Label.new(); label.text = "No bonuses equipped." if lines.is_empty() else "\n".join(lines); label.custom_minimum_size = Vector2(view.x - 210, 0); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size", 34); scroll.add_child(label)
	var close := Button.new(); close.text = "Close"; close.custom_minimum_size = Vector2(0, 86); close.add_theme_font_size_override("font_size", 34); close.pressed.connect(_close_popup); _style_button(close); box.add_child(close)

func _close_popup() -> void:
	if _popup != null and is_instance_valid(_popup): _popup.queue_free()
	_popup = null

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.03, 0.06, 0.08, 0.98); style.border_color = Color(0.86, 0.66, 0.22); style.set_border_width_all(3); style.corner_radius_top_left = 22; style.corner_radius_top_right = 22; style.corner_radius_bottom_left = 22; style.corner_radius_bottom_right = 22; style.content_margin_left = 26; style.content_margin_right = 26; style.content_margin_top = 24; style.content_margin_bottom = 24; return style

func _style_card(button: Button) -> void:
	var normal := _panel_style(); normal.bg_color = Color(0.035, 0.04, 0.07, 0.98); normal.border_color = Color(0.92, 0.67, 0.18); normal.set_border_width_all(3); normal.content_margin_left = 4; normal.content_margin_right = 4; normal.content_margin_top = 4; normal.content_margin_bottom = 4
	var hover := normal.duplicate() as StyleBoxFlat; hover.bg_color = Color(0.08, 0.09, 0.14, 1.0)
	button.add_theme_stylebox_override("normal", normal); button.add_theme_stylebox_override("hover", hover); button.add_theme_stylebox_override("pressed", normal); button.add_theme_color_override("font_color", Color(0.94, 0.85, 0.68))

func _badge_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color(1.0, 0.76, 0.18); style.corner_radius_top_left = 8; style.corner_radius_top_right = 8; style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8; return style

func _style_button(button: Button, primary: bool = false) -> void:
	var normal := _lobby_button_box(Color(0.98, 0.72, 0.08) if primary else Color(0.14, 0.14, 0.22, 0.92), Color(0.72, 0.42, 0.0) if primary else Color(0.55, 0.55, 0.75, 0.75), 3 if primary else 2, 12 if primary else 7)
	var hover := _lobby_button_box(Color(1.0, 0.82, 0.25) if primary else Color(0.22, 0.22, 0.35, 0.95), Color(0.72, 0.42, 0.0) if primary else Color(0.65, 0.65, 0.88, 0.85), 3 if primary else 2, 12 if primary else 7)
	var pressed := _lobby_button_box(Color(0.80, 0.56, 0.03) if primary else Color(0.08, 0.08, 0.16, 0.95), Color(0.58, 0.32, 0.0) if primary else Color(0.45, 0.45, 0.65, 0.70), 3 if primary else 2, 5 if primary else 3)
	button.add_theme_stylebox_override("normal", normal); button.add_theme_stylebox_override("hover", hover); button.add_theme_stylebox_override("pressed", pressed); button.add_theme_color_override("font_color", Color(0.10, 0.05, 0.0) if primary else Color(0.90, 0.90, 1.0)); button.focus_mode = Control.FOCUS_NONE

func _lobby_button_box(background: Color, border: Color, width: int, shadow: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = background; style.border_color = border; style.set_border_width_all(width); style.corner_radius_top_left = 28; style.corner_radius_top_right = 28; style.corner_radius_bottom_left = 28; style.corner_radius_bottom_right = 28; style.shadow_color = Color(0, 0, 0, 0.38); style.shadow_size = shadow; style.shadow_offset = Vector2(0, 3); return style
