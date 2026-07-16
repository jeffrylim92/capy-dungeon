extends Node2D

## Main lobby: shown right after login. Player can start a match, view per
## character stats, change settings, or sign out / switch account.

signal start_game_requested
signal story_requested
signal history_requested
signal cloud_sync_requested
signal collectibles_requested
signal logout_requested

const SETTINGS_SCENE := preload("res://scenes/Settings.tscn")
const CAMP_VISTA_SCRIPT := preload("res://scripts/CampVista.gd")

var account: Dictionary = {}
var open_play_hub_on_ready := false

var _settings_overlay: Node = null
var _welcome_lbl: Label = null
var _lobby_avatar_rect: TextureRect = null
var _camp_overlay: CanvasLayer = null
var _modifier_info_layer: CanvasLayer = null
var _play_hub_layer: CanvasLayer = null
var _camp_resident_state: Dictionary = {}

func _ready() -> void:
	SettingsStore.apply(get_tree())
	add_to_group("active_account")
	set_meta("username", String(account.get("username", "")))
	set_meta("social_email", String(account.get("social_email", "")).strip_edges().to_lower())
	_build_ui()
	if open_play_hub_on_ready:
		_show_play_hub.call_deferred()

func _build_ui() -> void:
	var view := get_viewport_rect().size

	var bg := TextureRect.new()
	var bg_tex := load("res://assets/backgrounds/bg_lobby.png") as Texture2D
	if bg_tex:
		bg.texture = bg_tex
	else:
		bg.set_script(null)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = view
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var layout := Control.new()
	layout.position = Vector2.ZERO
	layout.size = view
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layout)

	var center := CenterContainer.new()
	center.position = Vector2.ZERO
	center.size = view
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(view.x - 80.0, 0.0)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.98, 0.95, 0.88, 0.55)
	card_style.border_color = Color(0.75, 0.55, 0.20, 0.88)
	card_style.set_border_width_all(2)
	card_style.corner_radius_top_left = 28
	card_style.corner_radius_top_right = 28
	card_style.corner_radius_bottom_right = 28
	card_style.corner_radius_bottom_left = 28
	card_style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	card_style.shadow_size = 18
	card_style.shadow_offset = Vector2(0, 6)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 48)
	inner.add_theme_constant_override("margin_right", 48)
	inner.add_theme_constant_override("margin_top", 48)
	inner.add_theme_constant_override("margin_bottom", 48)
	card.add_child(inner)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 22)
	inner.add_child(root)

	var title := Label.new()
	title.text = "Capy Dungeon"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.22, 0.10, 0.02))
	title.add_theme_color_override("font_outline_color", Color(1.0, 0.90, 0.60, 0.55))
	title.add_theme_constant_override("outline_size", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var _prof := _load_profile()
	var _av_id: String = _prof.get("avatar", "capy_zoomer") as String
	var _av_tex := load("res://assets/characters/" + _av_id + ".png") as Texture2D
	if _av_tex:
		var av_center := CenterContainer.new()
		_lobby_avatar_rect = TextureRect.new()
		_lobby_avatar_rect.texture = _av_tex
		_lobby_avatar_rect.custom_minimum_size = Vector2(96, 96)
		_lobby_avatar_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		_lobby_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		av_center.add_child(_lobby_avatar_rect)
		root.add_child(av_center)

	var welcome := Label.new()
	var _base_name: String = String(account.get("display_name", account.get("username", "trainer")))
	var display_name: String = _prof.get("display_name", _base_name) as String
	welcome.text = "Welcome back, %s" % display_name
	welcome.add_theme_font_size_override("font_size", 36)
	welcome.add_theme_color_override("font_color", Color(0.28, 0.14, 0.04))
	welcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(welcome)
	_welcome_lbl = welcome
	var username := String(account.get("username", ""))
	var progression := ProgressionStore.load_profile(username)
	var camp_summary := Label.new()
	camp_summary.text = "Camp Lv.%d  ·  %d coins  ·  %s" % [ProgressionStore.account_level(progression), int(progression.get("coins", 0)), String(ProgressionStore.difficulty(progression).get("name", "Cozy"))]
	camp_summary.add_theme_font_size_override("font_size", 24)
	camp_summary.add_theme_color_override("font_color", Color(0.34, 0.20, 0.06))
	camp_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(camp_summary)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	root.add_child(spacer)

	var play_btn := _make_button("PLAY", 44, Vector2(0, 140), true)
	play_btn.pressed.connect(_show_play_hub)
	root.add_child(play_btn)

	var history_btn := _make_button("History", 32, Vector2(0, 90))
	history_btn.pressed.connect(func() -> void: history_requested.emit())
	root.add_child(history_btn)

	var collectibles_btn := _make_button("Collectibles", 32, Vector2(0, 90))
	collectibles_btn.pressed.connect(func() -> void: collectibles_requested.emit())
	root.add_child(collectibles_btn)

	var settings_btn := _make_button("Settings", 32, Vector2(0, 90))
	settings_btn.pressed.connect(_on_settings_pressed)
	root.add_child(settings_btn)

func _show_play_hub() -> void:
	if _play_hub_layer != null and is_instance_valid(_play_hub_layer): return
	_play_hub_layer = CanvasLayer.new()
	_play_hub_layer.layer = 70
	add_child(_play_hub_layer)
	var view := get_viewport_rect().size
	var bg := TextureRect.new()
	bg.texture = load("res://assets/backgrounds/bg_preparation_stage.png") as Texture2D
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = view
	_play_hub_layer.add_child(bg)
	var shade := ColorRect.new(); shade.color = Color(0.02, 0.04, 0.06, 0.55); shade.size = view; _play_hub_layer.add_child(shade)
	var root := VBoxContainer.new(); root.position = Vector2(55, 70); root.size = Vector2(view.x - 110, view.y - 125); root.add_theme_constant_override("separation", 24); _play_hub_layer.add_child(root)
	var title := Label.new(); title.text = "CHOOSE YOUR ADVENTURE"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 54); title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.28)); root.add_child(title)
	_add_mode_card(root, "story", "STORY", "Clear chapters · Claim equipment · Upgrade your loadout", Color(0.25, 0.66, 0.48), func() -> void: story_requested.emit())
	_add_mode_card(root, "survival", "SURVIVAL", "Endless waves · Rings and artifacts · High-score runs", Color(0.72, 0.34, 0.20), func() -> void: start_game_requested.emit())
	_add_mode_card(root, "camp", "CAMP & CHALLENGES", "Permanent upgrades · Missions · Dungeon difficulty", Color(0.32, 0.48, 0.72), func() -> void:
		_close_play_hub()
		_show_camp()
	)
	var back := _make_button("Main Menu", 30, Vector2(0, 90)); back.pressed.connect(_close_play_hub); root.add_child(back)

func _add_mode_card(parent: VBoxContainer, asset_id: String, title: String, description: String, color: Color, action: Callable) -> void:
	var button := _make_button("", 28, Vector2(0, 350), true)
	button.clip_contents = true
	var style := _camp_card_style(color.lightened(0.25), color.darkened(0.55), 24, 4)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style.duplicate())
	var art := TextureRect.new(); art.texture = load("res://assets/story/modes/%s.png" % asset_id) as Texture2D; art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); art.offset_left = 5; art.offset_top = 5; art.offset_right = -5; art.offset_bottom = -5; art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; art.mouse_filter = Control.MOUSE_FILTER_IGNORE; button.add_child(art)
	var veil := ColorRect.new(); veil.color = Color(0.01, 0.02, 0.03, 0.48); veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); veil.offset_left = 5; veil.offset_top = 5; veil.offset_right = -5; veil.offset_bottom = -5; veil.mouse_filter = Control.MOUSE_FILTER_IGNORE; button.add_child(veil)
	var text := Label.new(); text.text = "%s\n%s" % [title, description]; text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); text.offset_left = 38; text.offset_right = -38; text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT; text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; text.add_theme_font_size_override("font_size", 34); text.add_theme_color_override("font_color", Color.WHITE); text.add_theme_color_override("font_outline_color", Color.BLACK); text.add_theme_constant_override("outline_size", 8); text.mouse_filter = Control.MOUSE_FILTER_IGNORE; button.add_child(text)
	button.pressed.connect(action)
	parent.add_child(button)

func _close_play_hub() -> void:
	if _play_hub_layer != null and is_instance_valid(_play_hub_layer): _play_hub_layer.queue_free()
	_play_hub_layer = null

func _show_camp(selected_upgrade: String = "") -> void:
	if _camp_overlay != null and is_instance_valid(_camp_overlay):
		return
	var username := String(account.get("username", ""))
	var profile := ProgressionStore.load_profile(username)
	_camp_overlay = CanvasLayer.new()
	_camp_overlay.layer = 80
	add_child(_camp_overlay)
	var view := get_viewport_rect().size
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.05, 0.94)
	shade.size = view
	_camp_overlay.add_child(shade)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 70)
	scroll.size = Vector2(view.x - 80, view.y - 140)
	_camp_overlay.add_child(scroll)
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(view.x - 110, 0)
	root.add_theme_constant_override("separation", 16)
	scroll.add_child(root)
	var title := Label.new()
	title.text = "Capy Camp  ·  Level %d" % ProgressionStore.account_level(profile)
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.20))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	var wallet := Label.new()
	var xp_info := ProgressionStore.xp_progress(profile)
	wallet.text = "%d camp coins  ·  Camp XP %d / %d  ·  Total %d\nNext unlock: %s" % [int(profile.get("coins", 0)), int(xp_info.current), int(xp_info.needed), int(xp_info.total), ProgressionStore.next_unlock(profile)]
	wallet.add_theme_font_size_override("font_size", 24)
	wallet.autowrap_mode = TextServer.AUTOWRAP_WORD
	wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(wallet)
	var xp_bar := ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(0, 38)
	xp_bar.max_value = maxi(int(xp_info.needed), 1)
	xp_bar.value = int(xp_info.current)
	xp_bar.show_percentage = true
	xp_bar.tooltip_text = "%d XP remaining until Camp Level %d" % [maxi(int(xp_info.needed) - int(xp_info.current), 0), ProgressionStore.account_level(profile) + 1]
	root.add_child(xp_bar)
	var vista := CAMP_VISTA_SCRIPT.new() as CampVista
	vista.name = "CampVista"
	vista.setup(profile, username, _camp_resident_state)
	vista.upgrade_selected.connect(func(upgrade_id: String) -> void:
		_close_camp()
		_show_camp(upgrade_id)
	)
	vista.section_selected.connect(func(section_id: String) -> void:
		_close_camp()
		_show_camp(section_id)
	)
	root.add_child(vista)
	var vista_note := Label.new()
	vista_note.text = "TIP  ·  Tap a labeled camp building to inspect or upgrade it.  ✦ appears at Lv.4 and ✦✦ at Lv.8 as the building gains new details."
	vista_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vista_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vista_note.add_theme_font_size_override("font_size", 21)
	vista_note.add_theme_color_override("font_color", Color(0.76, 0.80, 0.88))
	root.add_child(vista_note)
	if not selected_upgrade.is_empty() and ProgressionStore.UPGRADES.has(selected_upgrade):
		var def: Dictionary = ProgressionStore.UPGRADES[selected_upgrade] as Dictionary
		var level := ProgressionStore.upgrade_level(profile, selected_upgrade)
		var upgrade_title := Label.new()
		upgrade_title.text = "Selected Building  ·  %s" % String(def.get("name", selected_upgrade.capitalize()))
		upgrade_title.add_theme_font_size_override("font_size", 34)
		root.add_child(upgrade_title)
		var btn := _build_upgrade_card(selected_upgrade, def, level, profile)
		btn.disabled = level >= ProgressionStore.MAX_UPGRADE_LEVEL
		btn.pressed.connect(func() -> void:
			var error := ProgressionStore.buy_upgrade(username, selected_upgrade)
			if error.is_empty(): cloud_sync_requested.emit()
			if error.is_empty():
				_close_camp()
				_show_camp(selected_upgrade)
			else:
				btn.text = error
		)
		root.add_child(btn)
		var overview_btn := _make_button("Back to Camp Buildings", 25, Vector2(0, 68))
		overview_btn.pressed.connect(func() -> void:
			_close_camp()
			_show_camp()
		)
		root.add_child(overview_btn)
	elif selected_upgrade == "difficulty":
		var difficulty_title := Label.new()
		difficulty_title.text = "Expedition Gate  ·  Dungeon Difficulty"
		difficulty_title.add_theme_font_size_override("font_size", 34)
		root.add_child(difficulty_title)
		var mod := ProgressionStore.daily_modifier()
		var challenge_row := HBoxContainer.new()
		challenge_row.add_theme_constant_override("separation", 10)
		root.add_child(challenge_row)
		var challenge := Label.new()
		challenge.text = "TODAY'S CHALLENGE: %s\n%s" % [String(mod.get("name", "")), String(mod.get("desc", ""))]
		challenge.add_theme_font_size_override("font_size", 24)
		challenge.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
		challenge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		challenge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		challenge_row.add_child(challenge)
		var info_btn := _make_button("ⓘ", 32, Vector2(66, 66))
		info_btn.pressed.connect(_show_modifier_info)
		challenge_row.add_child(info_btn)
		for i in ProgressionStore.DIFFICULTIES.size():
			var difficulty_index := i
			var d: Dictionary = ProgressionStore.DIFFICULTIES[i] as Dictionary
			var is_selected := i == int(profile.get("difficulty", 0))
			var difficulty_label := "✓ ACTIVE  ·  %s" % String(d.name) if is_selected else String(d.name)
			var details := "Enemy health ×%.2f  ·  Enemy damage ×%.2f  ·  Rewards ×%.2f" % [float(d.enemy_hp), float(d.enemy_damage), float(d.reward)]
			var db := _make_button("%s\n%s" % [difficulty_label, details], 22, Vector2(0, 90))
			db.disabled = ProgressionStore.account_level(profile) < int(d.unlock_level)
			if db.disabled:
				db.text += "\nUnlocks at Camp Level %d" % int(d.unlock_level)
			if is_selected:
				_style_selected_difficulty(db)
			db.pressed.connect(func() -> void:
				ProgressionStore.set_difficulty(username, difficulty_index)
				cloud_sync_requested.emit()
				_close_camp(); _show_camp("difficulty")
			)
			root.add_child(db)
		_add_camp_overview_button(root)
	elif selected_upgrade == "missions":
		var mission_title := Label.new()
		mission_title.text = "Mission Board  ·  Claim Rewards"
		mission_title.add_theme_font_size_override("font_size", 34)
		root.add_child(mission_title)
		var has_claimable := false
		for mission in ProgressionStore.missions(profile):
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			root.add_child(row)
			var ml := Label.new()
			var complete := int(mission.progress) >= int(mission.target)
			var claimed := bool(mission.claimed)
			ml.text = "%s  ·  %d/%d  ·  %d coins" % [String(mission.name), mini(int(mission.progress), int(mission.target)), int(mission.target), int(mission.reward)]
			ml.add_theme_font_size_override("font_size", 24)
			ml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(ml)
			var claim_text := "Collected" if claimed else ("Collect" if complete else "Incomplete")
			var claim_btn := _make_button(claim_text, 21, Vector2(150, 62), complete and not claimed)
			claim_btn.disabled = not complete or claimed
			var mission_id := String(mission.id)
			var captured_mission_id := mission_id
			claim_btn.pressed.connect(func() -> void:
				ProgressionStore.claim_mission(username, captured_mission_id)
				cloud_sync_requested.emit()
				_close_camp(); _show_camp("missions")
			)
			row.add_child(claim_btn)
			has_claimable = has_claimable or (complete and not claimed)
		var collect_all := _make_button("Collect All", 25, Vector2(0, 70), true)
		collect_all.disabled = not has_claimable
		collect_all.pressed.connect(func() -> void:
			ProgressionStore.claim_all_missions(username)
			cloud_sync_requested.emit()
			_close_camp(); _show_camp("missions")
		)
		root.add_child(collect_all)
		_add_camp_overview_button(root)
	var close := _make_button("Back to Play Modes", 30, Vector2(0, 82), true)
	close.pressed.connect(func() -> void:
		_close_camp()
		_show_play_hub()
	)
	root.add_child(close)

func _add_camp_overview_button(root: VBoxContainer) -> void:
	var overview_btn := _make_button("Back to Camp Buildings", 25, Vector2(0, 68))
	overview_btn.pressed.connect(func() -> void:
		_close_camp()
		_show_camp()
	)
	root.add_child(overview_btn)

func _close_camp() -> void:
	_close_modifier_info()
	if _camp_overlay != null and is_instance_valid(_camp_overlay):
		var vista := _camp_overlay.find_child("CampVista", true, false) as CampVista
		if vista != null:
			_camp_resident_state = vista.resident_state()
		_camp_overlay.queue_free()
	_camp_overlay = null

func _build_upgrade_card(id: String, definition: Dictionary, level: int, profile: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 250)
	btn.focus_mode = Control.FOCUS_NONE
	btn.text = ""
	var accent: Color = definition.get("color", Color(0.90, 0.68, 0.20)) as Color
	var normal := _camp_card_style(accent, Color(0.04, 0.05, 0.09, 0.98))
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.09)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.08)
	var disabled_style := normal.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color(0.12, 0.12, 0.14, 0.92)
	disabled_style.border_color = Color(0.38, 0.38, 0.42, 0.75)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled_style)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	btn.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 20)
	margin.add_child(row)
	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(142, 142)
	icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_panel.add_theme_stylebox_override("panel", _camp_card_style(accent, Color(0.08, 0.05, 0.11, 0.98), 14, 2))
	row.add_child(icon_panel)
	var icon := TextureRect.new()
	var icon_path := String(definition.get("icon", ""))
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path) as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_panel.add_child(icon)
	var details := VBoxContainer.new()
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 7)
	row.add_child(details)
	var header := Label.new()
	header.text = "%s  ·  Lv.%d/%d" % [String(definition.get("name", id.capitalize())), level, ProgressionStore.MAX_UPGRADE_LEVEL]
	header.add_theme_font_size_override("font_size", 34)
	header.add_theme_color_override("font_color", accent.lightened(0.18))
	details.add_child(header)
	var desc := Label.new()
	desc.text = "%s\nCurrent effect: %s" % [String(definition.get("desc", "")), ProgressionStore.upgrade_effect_text(profile, id)]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.add_theme_font_size_override("font_size", 24)
	desc.add_theme_color_override("font_color", Color(0.90, 0.85, 0.74))
	details.add_child(desc)
	var cost := Label.new()
	cost.text = "MAXIMUM LEVEL" if level >= ProgressionStore.MAX_UPGRADE_LEVEL else "Upgrade for %d camp coins" % ProgressionStore.upgrade_cost(profile, id)
	cost.add_theme_font_size_override("font_size", 24)
	cost.add_theme_color_override("font_color", Color(1.0, 0.79, 0.24))
	details.add_child(cost)
	return btn

func _camp_card_style(border: Color, background: Color, radius: int = 16, width: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	return style

func _style_selected_difficulty(button: Button) -> void:
	var selected := _camp_card_style(Color(1.0, 0.82, 0.24), Color(0.20, 0.36, 0.16, 1.0), 18, 4)
	var hover := selected.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.25, 0.44, 0.19, 1.0)
	button.add_theme_stylebox_override("normal", selected)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", selected)
	button.add_theme_color_override("font_color", Color(1.0, 0.92, 0.46))
	button.add_theme_color_override("font_hover_color", Color.WHITE)

func _show_modifier_info() -> void:
	if _modifier_info_layer != null and is_instance_valid(_modifier_info_layer):
		return
	_modifier_info_layer = CanvasLayer.new()
	_modifier_info_layer.layer = 95
	add_child(_modifier_info_layer)
	var view := get_viewport_rect().size
	var blocker := ColorRect.new()
	blocker.color = Color(0, 0, 0, 0.76)
	blocker.size = view
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_modifier_info_layer.add_child(blocker)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(view.x - 100, 0)
	panel.position = Vector2(50, view.y * 0.17)
	panel.add_theme_stylebox_override("panel", _camp_card_style(Color(0.35, 0.78, 1.0), Color(0.03, 0.05, 0.10, 0.99), 22, 3))
	_modifier_info_layer.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)
	var title := Label.new()
	title.text = "Daily Run Modifiers"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	var note := Label.new()
	note.text = "One modifier is active for every player each day. The rotation changes automatically at your next local calendar day."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 23)
	note.add_theme_color_override("font_color", Color(0.78, 0.82, 0.90))
	root.add_child(note)
	var active_id := String(ProgressionStore.daily_modifier().get("id", ""))
	for modifier_variant in ProgressionStore.MODIFIERS:
		var modifier: Dictionary = modifier_variant as Dictionary
		var card := PanelContainer.new()
		var is_active := String(modifier.get("id", "")) == active_id
		card.add_theme_stylebox_override("panel", _camp_card_style(Color(1.0, 0.76, 0.20) if is_active else Color(0.30, 0.48, 0.68), Color(0.06, 0.08, 0.14, 0.98), 14, 2))
		root.add_child(card)
		var text := Label.new()
		text.text = "%s%s\n%s" % ["ACTIVE TODAY  ·  " if is_active else "", String(modifier.get("name", "Unknown")), String(modifier.get("desc", ""))]
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_theme_font_size_override("font_size", 27)
		text.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42) if is_active else Color(0.88, 0.90, 0.96))
		card.add_child(text)
	var close := _make_button("Close", 30, Vector2(0, 78), true)
	close.pressed.connect(_close_modifier_info)
	root.add_child(close)
	blocker.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
			_close_modifier_info()
		elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
			_close_modifier_info()
	)

func _close_modifier_info() -> void:
	if _modifier_info_layer != null and is_instance_valid(_modifier_info_layer):
		_modifier_info_layer.queue_free()
	_modifier_info_layer = null

func _make_button(text: String, font_size: int, min_size: Vector2, is_primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.custom_minimum_size = min_size
	if is_primary:
		_style_primary(b)
	else:
		_style_secondary(b)
	return b

func _load_profile() -> Dictionary:
	if not FileAccess.file_exists("user://profile.json"):
		return {}
	var f := FileAccess.open("user://profile.json", FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}

func _refresh_lobby_header() -> void:
	var prof := _load_profile()
	var base_name: String = String(account.get("display_name", account.get("username", "trainer")))
	var new_name: String = prof.get("display_name", base_name) as String
	if is_instance_valid(_welcome_lbl):
		_welcome_lbl.text = "Welcome back, %s" % new_name
	var new_av: String = prof.get("avatar", "capy_zoomer") as String
	var ntex := load("res://assets/characters/" + new_av + ".png") as Texture2D
	if ntex and is_instance_valid(_lobby_avatar_rect):
		_lobby_avatar_rect.texture = ntex

func _on_settings_pressed() -> void:
	if _settings_overlay != null and is_instance_valid(_settings_overlay):
		return
	_settings_overlay = SETTINGS_SCENE.instantiate()
	_settings_overlay.logout_requested.connect(func() -> void:
		_close_settings()
		logout_requested.emit())
	_settings_overlay.display_name_changed.connect(func(new_name: String) -> void:
		if is_instance_valid(_welcome_lbl):
			_welcome_lbl.text = "Welcome back, %s" % new_name)
	_settings_overlay.closed.connect(func() -> void:
		_refresh_lobby_header()
		_close_settings())
	add_child(_settings_overlay)

func _close_settings() -> void:
	if _settings_overlay != null and is_instance_valid(_settings_overlay):
		_settings_overlay.queue_free()
	_settings_overlay = null

# ---- Button style helpers ---------------------------------------------------

func _style_primary(btn: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.98, 0.72, 0.08)
	n.corner_radius_top_left = 28
	n.corner_radius_top_right = 28
	n.corner_radius_bottom_right = 28
	n.corner_radius_bottom_left = 28
	n.border_color = Color(0.72, 0.42, 0.0)
	n.set_border_width_all(3)
	n.shadow_color = Color(0.72, 0.42, 0.0, 0.58)
	n.shadow_size = 12
	n.shadow_offset = Vector2(0, 5)
	var h := StyleBoxFlat.new()
	h.bg_color = Color(1.0, 0.82, 0.25)
	h.corner_radius_top_left = 28
	h.corner_radius_top_right = 28
	h.corner_radius_bottom_right = 28
	h.corner_radius_bottom_left = 28
	h.border_color = Color(0.72, 0.42, 0.0)
	h.set_border_width_all(3)
	h.shadow_color = Color(0.72, 0.42, 0.0, 0.58)
	h.shadow_size = 12
	h.shadow_offset = Vector2(0, 5)
	var p := StyleBoxFlat.new()
	p.bg_color = Color(0.80, 0.56, 0.03)
	p.corner_radius_top_left = 28
	p.corner_radius_top_right = 28
	p.corner_radius_bottom_right = 28
	p.corner_radius_bottom_left = 28
	p.border_color = Color(0.58, 0.32, 0.0)
	p.set_border_width_all(3)
	p.shadow_color = Color(0.58, 0.32, 0.0, 0.4)
	p.shadow_size = 5
	p.shadow_offset = Vector2(0, 2)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color", Color(0.10, 0.05, 0.0))
	btn.add_theme_color_override("font_hover_color", Color(0.08, 0.04, 0.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.08, 0.04, 0.0))
	btn.focus_mode = Control.FOCUS_NONE

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
