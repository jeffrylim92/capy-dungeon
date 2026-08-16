class_name StorySelect
extends Node2D

const STORY_ATMOSPHERE := preload("res://scripts/StoryAtmosphere.gd")

signal stage_selected(stage: Dictionary)
signal test_stage_selected(stage: Dictionary)
signal back_requested
signal cloud_sync_requested

var account_username := ""
var initial_stage_index := -1
var open_dev_test_selector_on_ready: bool = false
var _stage_index := 0
var _page_root: CanvasLayer
var _reward_layer: CanvasLayer
var _dev_test_layer: CanvasLayer

func _ready() -> void:
	_stage_index = clampi(initial_stage_index, 0, StoryStore.stage_count() - 1) if initial_stage_index >= 0 else StoryStore.unlocked_stage(StoryStore.load_profile(account_username))
	_build_page()
	if open_dev_test_selector_on_ready and OS.is_debug_build():
		call_deferred("_show_dev_story_test_selector")

func _build_page() -> void:
	if _page_root != null and is_instance_valid(_page_root): _page_root.queue_free()
	_page_root = CanvasLayer.new(); add_child(_page_root)
	var view := get_viewport_rect().size
	var stage := StoryStore.stage(_stage_index)
	var chapter_number := int(stage.chapter)
	var chapter := StoryStore.chapter(chapter_number - 1)
	var profile := StoryStore.load_profile(account_username)
	var cleared := String(stage.id) in (profile.get("cleared", []) as Array)
	var unlocked := _stage_index == 0 or String(StoryStore.stage(_stage_index - 1).id) in (profile.get("cleared", []) as Array)
	var chapter_claimed := StoryStore.is_chapter_claimed(profile, chapter_number)
	_add_scene_layer("res://assets/story/chapters/ch%d_base.png" % chapter_number, view)
	_add_parallax_layer("res://assets/story/chapters/ch%d_mid.png" % chapter_number, view, Vector2(-12, 4), Vector2(12, -4), 6.5)
	var atmosphere := STORY_ATMOSPHERE.new() as StoryAtmosphere; atmosphere.setup(chapter_number - 1, view); _page_root.add_child(atmosphere)
	_add_parallax_layer("res://assets/story/chapters/ch%d_fg.png" % chapter_number, view, Vector2(9, 2), Vector2(-9, -2), 4.8)
	var shade := ColorRect.new(); shade.color = Color(0.01, 0.02, 0.03, 0.48 if unlocked else 0.72); shade.size = view; _page_root.add_child(shade)
	var top := Label.new(); top.text = "CHAPTER %d\n%s" % [chapter_number, String(chapter.name)]; top.position = Vector2(265, 30); top.size = Vector2(view.x - 530, 135); top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; top.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; top.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; top.add_theme_font_size_override("font_size", 35); top.add_theme_color_override("font_color", Color("ffd66b")); _page_root.add_child(top)
	if _stage_index > 0:
		_add_nav_button("Previous Stage", Vector2(25, 48), Vector2(225, 78), true, -1)
	if int(stage.chapter_stage) == 5:
		if chapter_claimed:
			_add_claimed_indicator(view)
			if chapter_number < StoryStore.CHAPTERS.size():
				_add_nav_button("Next Chapter", Vector2(view.x - 250, 140), Vector2(225, 78), true, 1)
			else:
				_add_nav_button("Story Complete", Vector2(view.x - 250, 140), Vector2(225, 78), false, 0)
		else:
			_add_claim_button(view, chapter_number, cleared)
	else:
		var next_unlocked := cleared
		_add_nav_button("Next Stage", Vector2(view.x - 250, 48), Vector2(225, 78), next_unlocked, 1)
	var panel := PanelContainer.new(); panel.position = Vector2(82, view.y * 0.53); panel.size = Vector2(view.x - 164, 620); panel.add_theme_stylebox_override("panel", _panel_style()); _page_root.add_child(panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 16); panel.add_child(box)
	var name := Label.new(); name.text = String(stage.name); name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; name.add_theme_font_size_override("font_size", 50); name.add_theme_color_override("font_color", Color.WHITE); box.add_child(name)
	var story := Label.new(); story.text = String(stage.story); story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; story.add_theme_font_size_override("font_size", 32); box.add_child(story)
	var challenge := Label.new(); challenge.text = "Challenge  ·  %s" % String(stage.challenge); challenge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; challenge.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; challenge.add_theme_font_size_override("font_size", 28); challenge.add_theme_color_override("font_color", Color("ffca68")); box.add_child(challenge)
	var displayed_reward: Dictionary = StoryStore.stage_reward(str(stage.get("id", "")), cleared)
	var reward := Label.new(); reward.text = "%s  ·  %d camp coins  ·  %d upgrade materials" % ["Replay reward (30%)" if cleared else "First-clear reward (100%)", int(displayed_reward.get("coins", 0)), int(displayed_reward.get("materials", 0))]; reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; reward.add_theme_font_size_override("font_size", 30); reward.add_theme_color_override("font_color", Color("a7ed9a")); box.add_child(reward)
	var play := Button.new(); play.text = "REPLAY STAGE" if cleared else ("PLAY STAGE" if unlocked else "LOCKED  ·  COMPLETE PREVIOUS STAGE"); play.disabled = not unlocked; play.custom_minimum_size = Vector2(0, 108); play.add_theme_font_size_override("font_size", 40); play.pressed.connect(func() -> void: stage_selected.emit(stage.duplicate(true))); _style_button(play); box.add_child(play)
	var wallet := Label.new(); wallet.text = "Upgrade materials: %d  ·  Camp coins: %d" % [int(profile.get("materials", 0)), int(ProgressionStore.load_profile(account_username).get("coins", 0))]; wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; wallet.add_theme_font_size_override("font_size", 28); box.add_child(wallet)
	var back := Button.new(); back.text = "Play Modes"; back.position = Vector2(30, view.y - 112); back.size = Vector2(270, 78); back.add_theme_font_size_override("font_size", 32); back.pressed.connect(func(): back_requested.emit()); _style_button(back); _page_root.add_child(back)
	var count := Label.new(); count.text = "Stage %d / 5" % int(stage.chapter_stage); count.position = Vector2(view.x - 245, view.y - 106); count.size = Vector2(205, 62); count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; count.add_theme_font_size_override("font_size", 33); _page_root.add_child(count)
	if OS.is_debug_build():
		_add_dev_story_test_button(view)

func _add_dev_story_test_button(view: Vector2) -> void:
	var button := Button.new()
	button.text = "DEV STORY TEST"
	button.position = Vector2((view.x - 330.0) * 0.5, view.y - 112.0)
	button.size = Vector2(330.0, 78.0)
	button.add_theme_font_size_override("font_size", 30)
	button.pressed.connect(_show_dev_story_test_selector)
	_style_button(button)
	_page_root.add_child(button)

func _show_dev_story_test_selector() -> void:
	if not OS.is_debug_build():
		push_warning("Story test selector requested in a release build.")
		return
	if _dev_test_layer != null and is_instance_valid(_dev_test_layer):
		_dev_test_layer.queue_free()
	_dev_test_layer = CanvasLayer.new()
	_dev_test_layer.layer = 210
	add_child(_dev_test_layer)
	var view := get_viewport_rect().size
	var shade := ColorRect.new(); shade.color = Color(0.01, 0.01, 0.02, 0.92); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; _dev_test_layer.add_child(shade)
	var panel := PanelContainer.new(); panel.position = Vector2(65.0, view.y * 0.20); panel.size = Vector2(view.x - 130.0, 680.0); panel.add_theme_stylebox_override("panel", _panel_style()); _dev_test_layer.add_child(panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 22); panel.add_child(box)
	var title := Label.new(); title.text = "DEV STORY TEST"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 50); title.add_theme_color_override("font_color", Color("ffd66b")); box.add_child(title)
	var note := Label.new(); note.text = "Progress, rewards, records, and unlocks are not saved."; note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; note.add_theme_font_size_override("font_size", 34); box.add_child(note)
	var stages := OptionButton.new(); stages.custom_minimum_size = Vector2(0.0, 108.0); stages.add_theme_font_size_override("font_size", 38); stages.add_theme_icon_override("arrow", load("res://assets/icons/dev_dropdown_arrow.svg") as Texture2D); stages.add_theme_constant_override("arrow_margin", 26); stages.alignment = HORIZONTAL_ALIGNMENT_CENTER; _style_button(stages)
	var stage_popup: PopupMenu = stages.get_popup(); stage_popup.add_theme_font_size_override("font_size", 35); stage_popup.add_theme_constant_override("item_start_padding", 32); stage_popup.add_theme_constant_override("item_end_padding", 32); stage_popup.add_theme_constant_override("v_separation", 10)
	for index in StoryStore.stage_count():
		var stage: Dictionary = StoryStore.stage(index)
		stages.add_item("C%dS%d — %s" % [int(stage.chapter), int(stage.chapter_stage), str(stage.name).get_slice("  ", 1)], index)
	stages.select(clampi(_stage_index, 0, StoryStore.stage_count() - 1)); box.add_child(stages)
	var start := Button.new(); start.text = "START TEST"; start.custom_minimum_size = Vector2(0.0, 102.0); start.add_theme_font_size_override("font_size", 40); _style_button(start); box.add_child(start)
	start.pressed.connect(func() -> void:
		if not OS.is_debug_build():
			push_warning("Story test launch rejected in a release build.")
			return
		var selected_index: int = stages.get_selected_id()
		var selected_stage: Dictionary = StoryStore.stage(selected_index).duplicate(true)
		print("[Story][TEST][C%dS%d][0.00s] Test stage selected" % [int(selected_stage.chapter), int(selected_stage.chapter_stage)])
		test_stage_selected.emit(selected_stage)
	)
	var cancel := Button.new(); cancel.text = "Cancel"; cancel.custom_minimum_size = Vector2(0.0, 88.0); cancel.add_theme_font_size_override("font_size", 36); cancel.pressed.connect(func() -> void: _dev_test_layer.queue_free()); _style_button(cancel); box.add_child(cancel)

func _add_claim_button(view: Vector2, chapter_number: int, enabled: bool) -> void:
	var button := Button.new(); button.text = "Claim Chapter Reward"; button.position = Vector2(view.x - 280, 48); button.size = Vector2(255, 78); button.disabled = not enabled; button.add_theme_font_size_override("font_size", 19); button.pressed.connect(_show_chapter_reward.bind(chapter_number, false)); _style_button(button); _page_root.add_child(button)

func _add_claimed_indicator(view: Vector2) -> void:
	var claimed := Button.new(); claimed.text = "REWARD CLAIMED"; claimed.position = Vector2(view.x - 280, 48); claimed.size = Vector2(255, 78); claimed.disabled = true; claimed.add_theme_font_size_override("font_size", 20); _style_button(claimed); _page_root.add_child(claimed)

func _show_chapter_reward(chapter_number: int, revealed: bool) -> void:
	if _reward_layer != null and is_instance_valid(_reward_layer): _reward_layer.queue_free()
	_reward_layer = CanvasLayer.new(); _reward_layer.layer = 180; add_child(_reward_layer)
	var view := get_viewport_rect().size
	var shade := ColorRect.new(); shade.color = Color(0, 0, 0, 0.90); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; _reward_layer.add_child(shade)
	var title := Label.new(); title.text = "CHAPTER %d COMPLETE" % chapter_number; title.position = Vector2(60, 120); title.size = Vector2(view.x - 120, 80); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 48); title.add_theme_color_override("font_color", Color("ffd66b")); _reward_layer.add_child(title)
	if not revealed:
		var chest_size := Vector2(500, 500)
		var chest := Button.new(); chest.position = (view - chest_size) * 0.5; chest.size = chest_size; chest.icon = load("res://assets/story/chapters/chapter_chest.png") as Texture2D; chest.expand_icon = true; chest.add_theme_constant_override("icon_max_width", 470); chest.text = ""; chest.focus_mode = Control.FOCUS_NONE
		var empty_style := StyleBoxEmpty.new(); chest.add_theme_stylebox_override("normal", empty_style); chest.add_theme_stylebox_override("hover", empty_style); chest.add_theme_stylebox_override("pressed", empty_style); chest.add_theme_stylebox_override("focus", empty_style); chest.pressed.connect(_open_chapter_chest.bind(chapter_number)); _reward_layer.add_child(chest)
		var instruction := Label.new(); instruction.text = "Tap the chest to claim"; instruction.position = Vector2(90, chest.position.y + chest.size.y + 24); instruction.size = Vector2(view.x - 180, 60); instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; instruction.add_theme_font_size_override("font_size", 30); instruction.add_theme_color_override("font_color", Color("ffe2a1")); _reward_layer.add_child(instruction)
		return
	var chapter := StoryStore.chapter(chapter_number - 1)
	var rewards: Array = chapter.get("reward", []) as Array
	var row := HBoxContainer.new(); row.position = Vector2(70, 300); row.size = Vector2(view.x - 140, 570); row.add_theme_constant_override("separation", 24); _reward_layer.add_child(row)
	for gear_id_variant in rewards:
		var gear_id := String(gear_id_variant); var gear: Dictionary = StoryStore.GEAR[gear_id] as Dictionary
		var card := VBoxContainer.new(); card.custom_minimum_size = Vector2((view.x - 164) * 0.5, 550); row.add_child(card)
		var icon := TextureRect.new(); icon.texture = load("res://assets/story/equipment/%s.png" % gear_id) as Texture2D; icon.custom_minimum_size = Vector2(0, 380); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; card.add_child(icon)
		var label := Label.new(); label.text = "%s\n%s" % [String(gear.name), StoryStore.effect_text(gear_id)]; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.add_theme_font_size_override("font_size", 26); label.add_theme_color_override("font_color", Color("ffe2a1")); card.add_child(label)
	var next := Button.new(); next.text = "Next Chapter" if chapter_number < StoryStore.CHAPTERS.size() else "Story Complete"; next.position = Vector2((view.x - 430) * 0.5, view.y - 250); next.size = Vector2(430, 90); next.add_theme_font_size_override("font_size", 32); next.pressed.connect(_finish_chapter_reward.bind(chapter_number)); _style_button(next); _reward_layer.add_child(next)

func _open_chapter_chest(chapter_number: int) -> void:
	StoryStore.claim_chapter(account_username, chapter_number)
	cloud_sync_requested.emit()
	_show_chapter_reward(chapter_number, true)

func _finish_chapter_reward(chapter_number: int) -> void:
	if _reward_layer != null: _reward_layer.queue_free()
	_reward_layer = null
	if chapter_number < StoryStore.CHAPTERS.size(): _stage_index = chapter_number * 5
	_build_page()

func _add_scene_layer(path: String, view: Vector2) -> void:
	var bg := TextureRect.new(); bg.texture = load(path) as Texture2D; bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; bg.size = view; _page_root.add_child(bg)

func _add_nav_button(text: String, pos: Vector2, button_size: Vector2, enabled: bool, direction: int) -> void:
	var button := Button.new(); button.text = text; button.position = pos; button.size = button_size; button.disabled = not enabled; button.add_theme_font_size_override("font_size", 28); button.pressed.connect(func() -> void: _stage_index += direction; _build_page()); _style_button(button); _page_root.add_child(button)

func _add_parallax_layer(path: String, view: Vector2, start_pos: Vector2, end_pos: Vector2, duration: float) -> void:
	if not ResourceLoader.exists(path): return
	var layer := TextureRect.new(); layer.texture = load(path) as Texture2D; layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; layer.stretch_mode = TextureRect.STRETCH_SCALE; layer.position = start_pos; layer.size = view + Vector2(24, 12); layer.mouse_filter = Control.MOUSE_FILTER_IGNORE; _page_root.add_child(layer)
	var tween := layer.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT); tween.tween_property(layer, "position", end_pos, duration); tween.tween_property(layer, "position", start_pos, duration)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.03, 0.06, 0.08, 0.92); style.border_color = Color(0.86, 0.66, 0.22, 0.92); style.set_border_width_all(3); style.corner_radius_top_left = 24; style.corner_radius_top_right = 24; style.corner_radius_bottom_left = 24; style.corner_radius_bottom_right = 24; style.content_margin_left = 28; style.content_margin_right = 28; style.content_margin_top = 24; style.content_margin_bottom = 24; return style

func _style_button(button: Button) -> void:
	var normal := _lobby_button_box(Color(0.14, 0.14, 0.22, 0.92), Color(0.55, 0.55, 0.75, 0.75), 2, 7)
	var hover := _lobby_button_box(Color(0.22, 0.22, 0.35, 0.95), Color(0.65, 0.65, 0.88, 0.85), 2, 7)
	var pressed := _lobby_button_box(Color(0.08, 0.08, 0.16, 0.95), Color(0.45, 0.45, 0.65, 0.70), 2, 3)
	var disabled := _lobby_button_box(Color(0.10, 0.10, 0.16, 0.88), Color(0.38, 0.38, 0.54, 0.68), 2, 3)
	button.add_theme_stylebox_override("normal", normal); button.add_theme_stylebox_override("hover", hover); button.add_theme_stylebox_override("pressed", pressed); button.add_theme_stylebox_override("disabled", disabled); button.add_theme_color_override("font_color", Color(0.90, 0.90, 1.0)); button.add_theme_color_override("font_disabled_color", Color(0.52, 0.52, 0.64)); button.focus_mode = Control.FOCUS_NONE

func _lobby_button_box(background: Color, border: Color, width: int, shadow: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = background; style.border_color = border; style.set_border_width_all(width); style.corner_radius_top_left = 28; style.corner_radius_top_right = 28; style.corner_radius_bottom_left = 28; style.corner_radius_bottom_right = 28; style.shadow_color = Color(0, 0, 0, 0.38); style.shadow_size = shadow; style.shadow_offset = Vector2(0, 3); return style
