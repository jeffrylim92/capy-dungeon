class_name StorySelect
extends Node2D

const StoryMutatorsClass := preload("res://scripts/story/StoryMutators.gd")
const StoryBuildCapabilitiesClass := preload("res://scripts/story/StoryBuildCapabilities.gd")
const StoryBossPracticeClass := preload("res://scripts/story/StoryBossPractice.gd")
const StoryCampaignMapClass := preload("res://scripts/story/StoryCampaignMap.gd")
const StoryNarrativeClass := preload("res://scripts/story/StoryNarrative.gd")
const StoryRunPresentationClass := preload("res://scripts/story/StoryRunPresentation.gd")
const RewardItemCardClass := preload("res://scripts/ui/RewardItemCard.gd")
const MASTERY_MATERIAL_ICON := preload("res://assets/camp/resources/forgecore_material.png")

const MAP_HEADER_HEIGHT: float = 222.0
const MAP_BOTTOM_HEIGHT: float = 126.0
const MAP_CHAPTER_HEIGHT: float = 1220.0
const MAP_CHAPTER_NODE_TOP: float = 340.0
const MAP_NODE_GAP: float = 180.0

signal stage_selected(stage: Dictionary)
signal test_stage_selected(stage: Dictionary)
signal practice_selected(stage: Dictionary)
signal back_requested
signal cloud_sync_requested

var account_username := ""
var initial_stage_index := -1
var open_stage_details_on_ready: bool = false
var initial_mastery_chapter: int = 0
var open_dev_test_selector_on_ready: bool = false
var open_boss_practice_on_ready: bool = false
var initial_practice_config: Dictionary = {}
var recent_progress_event: Dictionary = {}
var _stage_index := 0
var _selected_difficulty_id := "normal"
var _selected_mutator_ids: Array[String] = []
var _dev_selected_mutator_ids: Array[String] = []
var _mutator_draft: Array[String] = []
var _mutator_dev_mode: bool = false
var _mutator_practice_mode: bool = false
var _dev_mutator_notice: String = ""
var _dev_build_profile_id: String = "current"
var _practice_stage_id: String = "ch1_5"
var _practice_phase_id: String = "full"
var _practice_brew_id: String = "stable"
var _practice_mutator_ids: Array[String] = []
var _page_root: CanvasLayer
var _map_scroll: ScrollContainer
var _map_content: Control
var _map_stage_buttons: Dictionary = {}
var _details_layer: CanvasLayer
var _reward_layer: CanvasLayer
var _mastery_reward_layer: CanvasLayer
var _dev_test_layer: CanvasLayer
var _mutator_layer: CanvasLayer
var _practice_layer: CanvasLayer
var _history_layer: CanvasLayer
var _history_detail_layer: CanvasLayer
var _history_scroll_value: int = 0
var _transition_started: bool = false
var _remembered_map_scroll: int = 0
var _progress_event_animated: bool = false
var _mastery_claim_in_progress: bool = false
var _mastery_notice: String = ""
var _mastery_claim_result: Dictionary = {}
var _chapter_claim_in_progress: bool = false
var _chapter_reward_new_ids: Array[String] = []
var _safe_top: float = 0.0
var _safe_bottom: float = 0.0

func _ready() -> void:
	add_to_group("accessibility_settings")
	for issue in StoryStore.validate_mastery_rewards():
		push_error("Chapter Mastery reward configuration: %s" % issue)
	_stage_index = clampi(initial_stage_index, 0, StoryStore.stage_count() - 1) if initial_stage_index >= 0 else StoryCampaignMapClass.current_stage_index(StoryStore.load_profile(account_username))
	_build_map()
	apply_accessibility_settings(SettingsStore.load_all())
	if open_dev_test_selector_on_ready and OS.is_debug_build():
		call_deferred("_show_dev_story_test_selector")
	elif open_boss_practice_on_ready:
		if not initial_practice_config.is_empty():
			_practice_stage_id = str(initial_practice_config.get("id", "ch1_5"))
			_practice_phase_id = str(initial_practice_config.get("practice_phase", "full"))
			_practice_brew_id = str(initial_practice_config.get("practice_brew", "stable"))
			_practice_mutator_ids.assign(initial_practice_config.get("mutators", []) as Array)
			call_deferred("_show_boss_practice_config", _practice_stage_id)
		else:
			call_deferred("_show_boss_practice_roster")
	elif initial_mastery_chapter > 0:
		call_deferred("_show_chapter_mastery", clampi(initial_mastery_chapter, 1, StoryCampaignMapClass.CHAPTER_COUNT))
	elif open_stage_details_on_ready:
		call_deferred("_show_stage_details", _stage_index)

func _build_map(preserve_scroll: bool = false) -> void:
	if preserve_scroll and _map_scroll != null and is_instance_valid(_map_scroll):
		_remembered_map_scroll = _map_scroll.scroll_vertical
	if _page_root != null and is_instance_valid(_page_root):
		_page_root.queue_free()
	_page_root = CanvasLayer.new()
	add_child(_page_root)
	var view := get_viewport_rect().size
	var safe := SettingsStore.safe_area(view)
	_safe_top = safe.position.y
	_safe_bottom = maxf(0.0, view.y - safe.end.y)
	var profile := StoryStore.load_profile(account_username)
	var background := ColorRect.new(); background.color = Color("071016"); background.size = view; background.mouse_filter = Control.MOUSE_FILTER_IGNORE; _page_root.add_child(background)
	_build_map_header(view, profile)
	_map_scroll = ScrollContainer.new()
	_map_scroll.name = "CampaignScroll"
	_map_scroll.position = Vector2(0.0, MAP_HEADER_HEIGHT + _safe_top)
	_map_scroll.size = Vector2(view.x, view.y - MAP_HEADER_HEIGHT - MAP_BOTTOM_HEIGHT - _safe_top - _safe_bottom)
	_map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_map_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_map_scroll.scroll_deadzone = 24
	_map_scroll.follow_focus = false
	_page_root.add_child(_map_scroll)
	_map_content = Control.new()
	_map_content.name = "CampaignContent"
	_map_content.custom_minimum_size = Vector2(view.x, MAP_CHAPTER_HEIGHT * StoryCampaignMapClass.CHAPTER_COUNT)
	_map_content.set_meta("accessibility_no_scale", true)
	_map_content.mouse_filter = Control.MOUSE_FILTER_PASS
	_map_scroll.add_child(_map_content)
	_map_stage_buttons.clear()
	_build_map_chapters(view, profile)
	_build_map_paths(view, profile)
	_build_map_nodes(view, profile)
	_build_map_footer(view)
	if not recent_progress_event.is_empty():
		_progress_event_animated = true
	if preserve_scroll:
		call_deferred("_restore_map_scroll")
	else:
		call_deferred("_scroll_to_stage", _stage_index)
	print("[StoryMap] Opened at %s" % str(StoryStore.stage(_stage_index).get("id", "ch1_1")))
	apply_accessibility_settings(SettingsStore.load_all())

func apply_accessibility_settings(settings: Dictionary) -> void:
	SettingsStore.apply_ui_scale(self, float(settings.get("ui_scale", 1.0)))

func _apply_current_accessibility() -> void:
	apply_accessibility_settings(SettingsStore.load_all())

func _build_map_header(view: Vector2, profile: Dictionary) -> void:
	var shade := ColorRect.new(); shade.color = Color(0.02, 0.04, 0.06, 0.98); shade.position = Vector2.ZERO; shade.size = Vector2(view.x, MAP_HEADER_HEIGHT + _safe_top); shade.mouse_filter = Control.MOUSE_FILTER_STOP; _page_root.add_child(shade)
	var campaign_mastery := StoryStore.campaign_mastery(profile)
	var title := Label.new(); title.text = "CAMPAIGN MASTERED" if campaign_mastery >= 75 else ("STORY COMPLETE" if StoryCampaignMapClass.campaign_complete(profile) else "STORY MAP"); title.position = Vector2(34.0, 18.0 + _safe_top); title.size = Vector2(view.x - 68.0, 62.0); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 46); title.add_theme_color_override("font_color", Color("ffd66b")); _page_root.add_child(title)
	var cleared_count := (profile.get("cleared", []) as Array).size()
	var new_reward_count := int(recent_progress_event.get("mastery_rewards_available", 0))
	var summary_text := "%d / 25 Cleared  ·  CAMPAIGN MASTERY %d / 75" % [cleared_count, campaign_mastery]
	if new_reward_count > 0:
		summary_text += "\n%d CHAPTER MASTERY REWARD%s AVAILABLE" % [new_reward_count, "S" if new_reward_count != 1 else ""]
	var summary := Label.new(); summary.text = summary_text; summary.position = Vector2(35.0, 77.0 + _safe_top); summary.size = Vector2(view.x - 70.0, 50.0); summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; summary.add_theme_font_size_override("font_size", 21); summary.add_theme_color_override("font_color", Color("b9d8e2")); _page_root.add_child(summary)
	var tabs := HBoxContainer.new(); tabs.position = Vector2(42.0, 126.0 + _safe_top); tabs.size = Vector2(view.x - 84.0, 70.0); tabs.add_theme_constant_override("separation", 10); _page_root.add_child(tabs)
	for chapter_number in range(1, StoryCampaignMapClass.CHAPTER_COUNT + 1):
		var chapter_button := Button.new(); chapter_button.text = str(chapter_number); chapter_button.custom_minimum_size = Vector2(0.0, 64.0); chapter_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; chapter_button.add_theme_font_size_override("font_size", 28); chapter_button.pressed.connect(_scroll_to_chapter.bind(chapter_number)); _style_button(chapter_button); tabs.add_child(chapter_button)
	if bool(recent_progress_event.get("story_complete", false)):
		var tween := title.create_tween(); title.modulate = Color(1.25, 1.25, 1.25); tween.tween_property(title, "modulate", Color.WHITE, 1.1).set_trans(Tween.TRANS_SINE)

func _build_map_chapters(view: Vector2, profile: Dictionary) -> void:
	for chapter_number in range(1, StoryCampaignMapClass.CHAPTER_COUNT + 1):
		var chapter_index := chapter_number - 1
		var chapter_y := float(chapter_index) * MAP_CHAPTER_HEIGHT
		var background_path := "res://assets/story/chapters/ch%d_base.png" % chapter_number
		if ResourceLoader.exists(background_path):
			var chapter_background := TextureRect.new(); chapter_background.texture = load(background_path) as Texture2D; chapter_background.position = Vector2(0.0, chapter_y); chapter_background.size = Vector2(view.x, MAP_CHAPTER_HEIGHT); chapter_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; chapter_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; chapter_background.modulate = Color(1.0, 1.0, 1.0, 0.42); chapter_background.mouse_filter = Control.MOUSE_FILTER_IGNORE; chapter_background.z_index = 0; _map_content.add_child(chapter_background)
		var tint := ColorRect.new(); tint.color = StoryCampaignMapClass.chapter_color(chapter_number).darkened(0.58); tint.color.a = 0.52; tint.position = Vector2(0.0, chapter_y); tint.size = Vector2(view.x, MAP_CHAPTER_HEIGHT); tint.mouse_filter = Control.MOUSE_FILTER_IGNORE; tint.z_index = 1; _map_content.add_child(tint)
		var chapter_data := StoryStore.chapter(chapter_index)
		var chapter_state := StoryCampaignMapClass.chapter_state(profile, chapter_number)
		var header := Button.new(); header.name = "ChapterHeader_%d" % chapter_number; header.position = Vector2(54.0, chapter_y + 34.0); header.size = Vector2(view.x - 108.0, 174.0); header.text = "CHAPTER %d · %s\n%s" % [chapter_number, str(chapter_data.get("name", "STORY")).to_upper(), _chapter_progress_text(chapter_state)]; header.alignment = HORIZONTAL_ALIGNMENT_CENTER; header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; header.add_theme_font_size_override("font_size", 25); header.add_theme_color_override("font_color", Color.WHITE); header.focus_mode = Control.FOCUS_NONE; header.tooltip_text = StoryNarrativeClass.chapter_map_text(chapter_number, bool(chapter_state.get("complete", false))); header.pressed.connect(_show_chapter_mastery.bind(chapter_number)); var header_style := _map_chapter_style(StoryCampaignMapClass.chapter_color(chapter_number), bool(chapter_state.get("complete", false))); header.add_theme_stylebox_override("normal", header_style); header.add_theme_stylebox_override("hover", _map_chapter_style(StoryCampaignMapClass.chapter_color(chapter_number).lightened(0.10), bool(chapter_state.get("complete", false)))); header.add_theme_stylebox_override("pressed", _map_chapter_style(StoryCampaignMapClass.chapter_color(chapter_number).darkened(0.10), bool(chapter_state.get("complete", false)))); header.z_index = 5; _map_content.add_child(header)
		if not _progress_event_animated and bool(recent_progress_event.get("chapter_complete", false)) and int(recent_progress_event.get("chapter", 0)) == chapter_number:
			var reveal := header.create_tween().set_trans(Tween.TRANS_SINE); header.modulate = Color(1.22, 1.22, 1.22); reveal.tween_property(header, "modulate", Color.WHITE, 1.1)
		if bool(chapter_state.get("complete", false)) and not bool(chapter_state.get("claimed", false)):
			var claim := Button.new(); claim.text = "CLAIM CHAPTER REWARD"; claim.position = Vector2((view.x - 410.0) * 0.5, chapter_y + 218.0); claim.size = Vector2(410.0, 64.0); claim.add_theme_font_size_override("font_size", 24); claim.pressed.connect(_show_chapter_reward.bind(chapter_number, false)); _style_button(claim); claim.z_index = 6; _map_content.add_child(claim)
		elif bool(chapter_state.get("claimed", false)):
			var claimed := Label.new(); claimed.text = "CHAPTER REWARD CLAIMED ✓"; claimed.position = Vector2(80.0, chapter_y + 222.0); claimed.size = Vector2(view.x - 160.0, 48.0); claimed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; claimed.add_theme_font_size_override("font_size", 21); claimed.add_theme_color_override("font_color", Color("b9efb0")); claimed.z_index = 6; _map_content.add_child(claimed)

func _build_map_paths(view: Vector2, profile: Dictionary) -> void:
	for stage_index in range(StoryStore.stage_count() - 1):
		var route_active := StoryCampaignMapClass.path_active(profile, stage_index)
		var from_pos := StoryCampaignMapClass.stage_position(stage_index, view.x, MAP_CHAPTER_HEIGHT, MAP_NODE_GAP, MAP_CHAPTER_NODE_TOP)
		var to_pos := StoryCampaignMapClass.stage_position(stage_index + 1, view.x, MAP_CHAPTER_HEIGHT, MAP_NODE_GAP, MAP_CHAPTER_NODE_TOP)
		var midpoint_y := (from_pos.y + to_pos.y) * 0.5
		var line := Line2D.new(); line.name = "StagePath_%02d" % stage_index; line.points = PackedVector2Array([from_pos, Vector2(from_pos.x, midpoint_y), Vector2(to_pos.x, midpoint_y), to_pos]); line.width = 16.0 if route_active else 9.0; line.default_color = Color("ecd071") if route_active else Color(0.30, 0.34, 0.38, 0.72); line.antialiased = true; line.z_index = 2; _map_content.add_child(line)

func _build_map_nodes(view: Vector2, profile: Dictionary) -> void:
	for stage_index in StoryStore.stage_count():
		var state := StoryCampaignMapClass.stage_state(profile, stage_index)
		var center := StoryCampaignMapClass.stage_position(stage_index, view.x, MAP_CHAPTER_HEIGHT, MAP_NODE_GAP, MAP_CHAPTER_NODE_TOP)
		var node_size := Vector2(620.0, 132.0) if bool(state.get("boss", false)) else Vector2(520.0, 116.0)
		var button := Button.new(); button.name = "StageNode_%s" % str(state.get("id", "")); button.position = center - node_size * 0.5; button.size = node_size; button.text = _map_node_text(state); button.disabled = not bool(state.get("unlocked", false)); button.add_theme_font_size_override("font_size", 25 if bool(state.get("boss", false)) else 24); button.focus_mode = Control.FOCUS_NONE; button.z_index = 5; button.pressed.connect(_select_map_stage.bind(stage_index)); _style_map_node(button, state, StoryCampaignMapClass.chapter_color(int(state.get("chapter", 1))), stage_index == _stage_index); _map_content.add_child(button)
		_map_stage_buttons[stage_index] = button
		if bool(state.get("current", false)):
			var pulse := button.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT); pulse.tween_property(button, "modulate", Color(1.10, 1.10, 1.10), 0.85); pulse.tween_property(button, "modulate", Color.WHITE, 0.85)
		elif not _progress_event_animated and str(recent_progress_event.get("stage_id", "")) == str(state.get("id", "")):
			var reveal := button.create_tween().set_trans(Tween.TRANS_SINE); button.modulate = Color(1.22, 1.22, 1.22); reveal.tween_property(button, "modulate", Color.WHITE, 1.0)

func _build_map_footer(view: Vector2) -> void:
	var shade := ColorRect.new(); shade.color = Color(0.02, 0.04, 0.06, 0.98); shade.position = Vector2(0.0, view.y - MAP_BOTTOM_HEIGHT - _safe_bottom); shade.size = Vector2(view.x, MAP_BOTTOM_HEIGHT + _safe_bottom); shade.mouse_filter = Control.MOUSE_FILTER_STOP; _page_root.add_child(shade)
	var margin := 22.0
	var gap := 12.0
	var button_width := (view.x - margin * 2.0 - gap * 2.0) / 3.0
	var footer_y := view.y - 105.0 - _safe_bottom
	var back := Button.new(); back.text = "HOME"; back.position = Vector2(margin, footer_y); back.size = Vector2(button_width, 78.0); back.add_theme_font_size_override("font_size", 23); back.pressed.connect(func() -> void: back_requested.emit()); _style_button(back); _page_root.add_child(back)
	var history := Button.new(); history.name = "RecentRunsButton"; history.text = "RECENT RUNS"; history.position = Vector2(margin + button_width + gap, footer_y); history.size = Vector2(button_width, 78.0); history.add_theme_font_size_override("font_size", 23); history.pressed.connect(_show_run_history); _style_button(history); _page_root.add_child(history)
	var practice := Button.new(); practice.text = "BOSS PRACTICE"; practice.position = Vector2(margin + (button_width + gap) * 2.0, footer_y); practice.size = Vector2(button_width, 78.0); practice.add_theme_font_size_override("font_size", 21); practice.pressed.connect(_show_boss_practice_roster); _style_button(practice); _page_root.add_child(practice)

func _close_run_history() -> void:
	if _history_detail_layer != null and is_instance_valid(_history_detail_layer):
		_history_detail_layer.queue_free()
	_history_detail_layer = null
	if _history_layer != null and is_instance_valid(_history_layer):
		_history_layer.queue_free()
	_history_layer = null

func _history_icon_card(texture: Texture2D, title: String, detail: String) -> Control:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(142.0, 178.0)
	card.add_theme_constant_override("separation", 4)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(112.0, 112.0)
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(icon)
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 18)
	card.add_child(title_label)
	var detail_label := Label.new()
	detail_label.text = detail
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.add_theme_font_size_override("font_size", 16)
	detail_label.add_theme_color_override("font_color", Color("b9d8e2"))
	card.add_child(detail_label)
	return card

func _history_skill_icon(skill_id: String) -> Texture2D:
	var path := "res://assets/skills/%s.png" % skill_id
	if skill_id == "time_warp" and not ResourceLoader.exists(path):
		path = "res://assets/skills/time_wrap.png"
	return load(path) as Texture2D if ResourceLoader.exists(path) else null

func _show_run_history() -> void:
	_close_run_history()
	var view := get_viewport_rect().size
	_history_layer = CanvasLayer.new()
	_history_layer.name = "StoryRunHistory"
	_history_layer.layer = 200
	add_child(_history_layer)
	var shade := ColorRect.new(); shade.color = Color(0.01, 0.02, 0.03, 0.985); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; _history_layer.add_child(shade)
	var title := Label.new(); title.text = "RECENT STORY RUNS"; title.position = Vector2(34.0, 22.0 + _safe_top); title.size = Vector2(view.x - 68.0, 58.0); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 40); title.add_theme_color_override("font_color", Color("ffd66b")); _history_layer.add_child(title)
	var close := Button.new(); close.text = "CLOSE"; close.position = Vector2(view.x - 156.0, 84.0 + _safe_top); close.size = Vector2(124.0, 58.0); close.add_theme_font_size_override("font_size", 20); close.pressed.connect(_close_run_history); _style_button(close); _history_layer.add_child(close)
	var scroll := ScrollContainer.new(); scroll.name = "RunHistoryScroll"; scroll.position = Vector2(34.0, 154.0 + _safe_top); scroll.size = Vector2(view.x - 68.0, view.y - 184.0 - _safe_top - _safe_bottom); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; _history_layer.add_child(scroll)
	var list := VBoxContainer.new(); list.custom_minimum_size = Vector2(view.x - 92.0, 0.0); list.set_meta("accessibility_no_scale", true); list.add_theme_constant_override("separation", 16); scroll.add_child(list)
	var history := StoryStore.story_run_history(StoryStore.load_profile(account_username))
	if history.is_empty():
		var empty := Label.new(); empty.text = "No completed Story runs yet.\nFinish a Story stage to add its recap here."; empty.custom_minimum_size = Vector2(0.0, 300.0); empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; empty.add_theme_font_size_override("font_size", 28); empty.add_theme_color_override("font_color", Color("b9d8e2")); list.add_child(empty)
	else:
		for record in history:
			var mastery_count := (record.get("mastery_completed", []) as Array).size()
			var card := Button.new()
			card.name = "RunHistoryEntry_%s" % str(record.get("run_id", "unknown"))
			card.custom_minimum_size = Vector2(0.0, 146.0)
			card.text = "%s\n%s · %s · %d/3 ★\n%s" % [str(record.get("stage_name", record.get("stage_id", "Unknown Stage"))), StoryStore.difficulty_name(str(record.get("difficulty", "normal"))).to_upper(), StoryRunPresentationClass.format_duration(float(record.get("duration_seconds", 0.0))), mastery_count, StoryRunPresentationClass.format_timestamp(int(record.get("timestamp", 0)))]
			card.alignment = HORIZONTAL_ALIGNMENT_LEFT
			card.add_theme_font_size_override("font_size", 23)
			card.pressed.connect(_show_run_history_detail.bind(record))
			_style_button(card)
			list.add_child(card)
	call_deferred("_restore_history_scroll", scroll)
	_apply_current_accessibility()

func _restore_history_scroll(scroll: ScrollContainer) -> void:
	if is_instance_valid(scroll):
		scroll.scroll_vertical = _history_scroll_value

func _close_run_history_detail() -> void:
	if _history_detail_layer != null and is_instance_valid(_history_detail_layer):
		_history_detail_layer.queue_free()
	_history_detail_layer = null

func _show_run_history_detail(record: Dictionary) -> void:
	if _history_layer == null or not is_instance_valid(_history_layer):
		return
	var history_scroll := _history_layer.get_node_or_null("RunHistoryScroll") as ScrollContainer
	if history_scroll != null:
		_history_scroll_value = history_scroll.scroll_vertical
	if _history_detail_layer != null and is_instance_valid(_history_detail_layer):
		_history_detail_layer.queue_free()
	var view := get_viewport_rect().size
	_history_detail_layer = CanvasLayer.new(); _history_detail_layer.name = "StoryRunHistoryDetail"; _history_detail_layer.layer = 205; add_child(_history_detail_layer)
	var shade := ColorRect.new(); shade.color = Color(0.01, 0.02, 0.03, 0.995); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; _history_detail_layer.add_child(shade)
	var title := Label.new(); title.text = "SAVED RUN RECAP"; title.position = Vector2(34.0, 18.0 + _safe_top); title.size = Vector2(view.x - 68.0, 60.0); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 40); title.add_theme_color_override("font_color", Color("ffd66b")); _history_detail_layer.add_child(title)
	var scroll := ScrollContainer.new(); scroll.position = Vector2(34.0, 90.0 + _safe_top); scroll.size = Vector2(view.x - 68.0, view.y - 190.0 - _safe_top - _safe_bottom); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; _history_detail_layer.add_child(scroll)
	var content := VBoxContainer.new(); content.custom_minimum_size = Vector2(view.x - 92.0, 0.0); content.set_meta("accessibility_no_scale", true); content.add_theme_constant_override("separation", 15); scroll.add_child(content)
	var summary := Label.new(); summary.text = "%s\n%s · %s · Level %d\n%s" % [str(record.get("stage_name", record.get("stage_id", "Unknown Stage"))), StoryStore.difficulty_name(str(record.get("difficulty", "normal"))).to_upper(), StoryRunPresentationClass.format_duration(float(record.get("duration_seconds", 0.0))), int(record.get("final_level", 1)), StoryRunPresentationClass.format_timestamp(int(record.get("timestamp", 0)))]; summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; summary.add_theme_font_size_override("font_size", 27); summary.add_theme_color_override("font_color", Color("d7e8ec")); content.add_child(summary)
	var damage_title := Label.new(); damage_title.text = "TOP DAMAGE"; damage_title.add_theme_font_size_override("font_size", 30); damage_title.add_theme_color_override("font_color", Color("ffd66b")); content.add_child(damage_title)
	var damage := Label.new(); damage.text = StoryRunPresentationClass.top_damage_text(record, 3); damage.add_theme_font_size_override("font_size", 24); content.add_child(damage)
	var totals := Label.new(); totals.text = "Total Damage %d · Boss %d\nTaken %d · Healing %d\nEnemies Defeated %d · Revives %d" % [roundi(float(record.get("total_damage", 0.0))), roundi(float(record.get("boss_damage", 0.0))), roundi(float(record.get("damage_taken", 0.0))), roundi(float(record.get("healing", 0.0))), int(record.get("kills", 0)), int(record.get("revives", 0))]; totals.add_theme_font_size_override("font_size", 22); content.add_child(totals)
	var build_title := Label.new(); build_title.text = "FINAL BUILD"; build_title.add_theme_font_size_override("font_size", 30); build_title.add_theme_color_override("font_color", Color("ffd66b")); content.add_child(build_title)
	var grid := GridContainer.new(); grid.columns = 4; grid.add_theme_constant_override("h_separation", 12); grid.add_theme_constant_override("v_separation", 12); content.add_child(grid)
	for skill_variant in record.get("skills", []) as Array:
		var skill: Dictionary = skill_variant as Dictionary
		var sid := str(skill.get("id", "")); var skill_name := str(skill.get("evolution_name", "")); if skill_name.is_empty(): skill_name = str(skill.get("name", sid.replace("_", " ").capitalize()))
		grid.add_child(_history_icon_card(_history_skill_icon(sid), skill_name, "Lv.%d" % int(skill.get("level", 1))))
	for ring_variant in record.get("rings", []) as Array:
		var ring: Dictionary = ring_variant as Dictionary
		grid.add_child(_history_icon_card(RingStore.ring_icon(ring), str(ring.get("name", "Unknown Ring")), "%s · T%d\n%s %s" % [str(ring.get("rarity", "common")).capitalize(), int(ring.get("tier", 1)), StoryStore.stat_name(str(ring.get("attr", ""))), StoryStore.stat_value_text(str(ring.get("attr", "")), float(ring.get("value", 0.0)))]))
	for artifact_variant in record.get("artifacts", []) as Array:
		var artifact: Dictionary = artifact_variant as Dictionary
		grid.add_child(_history_icon_card(ArtifactStore.artifact_icon(artifact), str(artifact.get("name", "Unknown Artifact")), str(artifact.get("rarity", "common")).capitalize()))
	var artifact_lines: Array[String] = []
	for artifact_variant in record.get("artifacts", []) as Array:
		var artifact: Dictionary = artifact_variant as Dictionary
		var line := "%s: %s" % [str(artifact.get("name", "Unknown Artifact")), StoryRunPresentationClass.effect_text(artifact.get("effects", {}) as Dictionary)]
		var run_effect_text := StoryRunPresentationClass.effect_text(artifact.get("run_effects", {}) as Dictionary)
		if not run_effect_text.is_empty(): line += "\nRun roll: %s" % run_effect_text
		artifact_lines.append(line)
	if not artifact_lines.is_empty():
		var artifact_details := Label.new(); artifact_details.text = "\n".join(artifact_lines); artifact_details.add_theme_font_size_override("font_size", 20); artifact_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; content.add_child(artifact_details)
	var mastery_completed: Array = record.get("mastery_completed", []) as Array; var mastery_new: Array = record.get("mastery_newly_earned", []) as Array
	var mastery := Label.new(); mastery.text = "MASTERY %d/3 · Newly Earned %d\nMutators: %s" % [mastery_completed.size(), mastery_new.size(), "None" if (record.get("mutator_ids", []) as Array).is_empty() else ", ".join(StoryMutatorsClass.names(record.get("mutator_ids", []) as Array))]; mastery.add_theme_font_size_override("font_size", 23); mastery.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; content.add_child(mastery)
	var back := Button.new(); back.text = "BACK TO RECENT RUNS"; back.position = Vector2(70.0, view.y - 88.0 - _safe_bottom); back.size = Vector2(view.x - 140.0, 70.0); back.add_theme_font_size_override("font_size", 24); back.pressed.connect(_close_run_history_detail); _style_button(back); _history_detail_layer.add_child(back)
	_apply_current_accessibility()

func _chapter_progress_text(state: Dictionary) -> String:
	var completion := "✓ 5 / 5" if bool(state.get("complete", false)) else "%d / 5" % int(state.get("cleared", 0))
	var mastery_status := "◆ 15 / 15 ★" if bool(state.get("mastered", false)) else "%d / 15 ★" % int(state.get("mastery", 0))
	var available_count := int(state.get("mastery_rewards_available", 0))
	return "%s  ·  %s%s" % [completion, mastery_status, "  ·  🎁" if available_count > 0 else ""]

func _map_node_text(state: Dictionary) -> String:
	var stage_label := "C%dS%d" % [int(state.get("chapter", 1)), int(state.get("chapter_stage", 1))]
	if not bool(state.get("unlocked", false)):
		return "🔒\n%s" % stage_label
	var stars := "★".repeat(int(state.get("mastery", 0))) + "☆".repeat(3 - int(state.get("mastery", 0)))
	var prefix := "▶" if bool(state.get("current", false)) else ("✓" if bool(state.get("cleared", false)) else "○")
	if bool(state.get("boss", false)):
		prefix = "◆" if not bool(state.get("cleared", false)) else "◆ ✓"
	var recent_label := _recent_progress_label(str(state.get("id", "")))
	return "%s  %s%s\n%s" % [prefix, stage_label, "  ·  " + recent_label if not recent_label.is_empty() else "", stars]

func _recent_progress_label(stage_id: String) -> String:
	if str(recent_progress_event.get("stage_id", "")) != stage_id:
		return ""
	if bool(recent_progress_event.get("first_clear", false)):
		return "NEW CLEAR"
	if int(recent_progress_event.get("mastery_gained", 0)) > 0:
		return "+%d ★" % int(recent_progress_event.get("mastery_gained", 0))
	if bool(recent_progress_event.get("difficulty_improved", false)):
		return "%s CLEARED" % str(recent_progress_event.get("difficulty", "HARD")).to_upper()
	return "RESULT UPDATED"

func _select_map_stage(stage_index: int) -> void:
	var profile := StoryStore.load_profile(account_username)
	if not StoryCampaignMapClass.stage_unlocked(profile, stage_index):
		return
	_stage_index = clampi(stage_index, 0, StoryStore.stage_count() - 1)
	_selected_mutator_ids = StoryMutatorsClass.sanitize_selection(profile, str(StoryStore.stage(_stage_index).get("id", "")), _selected_mutator_ids)
	_refresh_map_selection(profile)
	print("[StoryMap] Selected %s" % str(StoryStore.stage(_stage_index).get("id", "")))
	_show_stage_details(_stage_index)

func _refresh_map_selection(profile: Dictionary) -> void:
	for index_variant in _map_stage_buttons:
		var index := int(index_variant)
		var button := _map_stage_buttons[index] as Button
		if button == null or not is_instance_valid(button):
			continue
		var state := StoryCampaignMapClass.stage_state(profile, index)
		_style_map_node(button, state, StoryCampaignMapClass.chapter_color(int(state.get("chapter", 1))), index == _stage_index)

func _scroll_to_chapter(chapter_number: int) -> void:
	var safe_chapter := clampi(chapter_number, 1, StoryCampaignMapClass.CHAPTER_COUNT)
	print("[StoryMap] Chapter navigation: %d" % safe_chapter)
	_scroll_to_stage((safe_chapter - 1) * StoryCampaignMapClass.STAGES_PER_CHAPTER)

func _scroll_to_stage(stage_index: int) -> void:
	if _map_scroll == null or not is_instance_valid(_map_scroll):
		return
	var center := StoryCampaignMapClass.stage_position(stage_index, _map_scroll.size.x, MAP_CHAPTER_HEIGHT, MAP_NODE_GAP, MAP_CHAPTER_NODE_TOP)
	var maximum := maxi(0, roundi(_map_content.custom_minimum_size.y - _map_scroll.size.y))
	_map_scroll.scroll_vertical = clampi(roundi(center.y - _map_scroll.size.y * 0.46), 0, maximum)

func _restore_map_scroll() -> void:
	if _map_scroll != null and is_instance_valid(_map_scroll):
		var maximum := maxi(0, roundi(_map_content.custom_minimum_size.y - _map_scroll.size.y))
		_map_scroll.scroll_vertical = clampi(_remembered_map_scroll, 0, maximum)

func _show_stage_details(stage_index: int) -> void:
	_close_stage_details()
	_transition_started = false
	_stage_index = clampi(stage_index, 0, StoryStore.stage_count() - 1)
	var view := get_viewport_rect().size
	var stage := StoryStore.stage(_stage_index)
	var stage_id := str(stage.get("id", ""))
	var chapter_number := int(stage.get("chapter", 1))
	var profile := StoryStore.load_profile(account_username)
	var state := StoryCampaignMapClass.stage_state(profile, _stage_index)
	if not bool(state.get("unlocked", false)):
		return
	_selected_mutator_ids = StoryMutatorsClass.sanitize_selection(profile, stage_id, _selected_mutator_ids)
	if not StoryStore.difficulty_unlocked(profile, stage_id, _selected_difficulty_id):
		_selected_difficulty_id = "normal"
	_details_layer = CanvasLayer.new(); _details_layer.layer = 185; add_child(_details_layer)
	var shade := ColorRect.new(); shade.color = Color(0.01, 0.02, 0.03, 0.975); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; _details_layer.add_child(shade)
	var heading := Label.new(); heading.text = "STAGE DETAILS"; heading.position = Vector2(40.0, 24.0 + _safe_top); heading.size = Vector2(view.x - 80.0, 62.0); heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; heading.add_theme_font_size_override("font_size", 42); heading.add_theme_color_override("font_color", StoryCampaignMapClass.chapter_color(chapter_number).lightened(0.24)); _details_layer.add_child(heading)
	var panel := PanelContainer.new(); panel.position = Vector2(48.0, 96.0 + _safe_top); panel.size = Vector2(view.x - 96.0, view.y - 232.0 - _safe_top - _safe_bottom); panel.add_theme_stylebox_override("panel", _panel_style()); _details_layer.add_child(panel)
	var scroll := ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO; panel.add_child(scroll)
	var box := VBoxContainer.new(); box.custom_minimum_size = Vector2(view.x - 176.0, 0.0); box.set_meta("accessibility_no_scale", true); box.add_theme_constant_override("separation", 14); scroll.add_child(box)
	var name := Label.new(); name.text = str(stage.get("name", "Story Stage")); name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; name.add_theme_font_size_override("font_size", 45); name.add_theme_color_override("font_color", Color.WHITE); box.add_child(name)
	var clear_state := Label.new(); clear_state.text = "%s  ·  Highest Clear: %s" % ["CLEARED ✓" if bool(state.get("cleared", false)) else "AVAILABLE · NOT CLEARED", str(state.get("highest_difficulty", "NONE"))]; clear_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; clear_state.add_theme_font_size_override("font_size", 24); clear_state.add_theme_color_override("font_color", Color("9fdcff")); box.add_child(clear_state)
	var personal_records := StoryStore.personal_record(profile, stage_id)
	var earned_record_mastery := StoryStore.earned_mastery(profile, stage_id)
	var personal_best_panel := PanelContainer.new()
	personal_best_panel.name = "PersonalBestPanel"
	personal_best_panel.add_theme_stylebox_override("panel", _personal_best_style())
	box.add_child(personal_best_panel)
	var personal_best_box := VBoxContainer.new()
	personal_best_box.add_theme_constant_override("separation", 5)
	personal_best_panel.add_child(personal_best_box)
	var personal_best_title := Button.new()
	personal_best_title.name = "PersonalBestToggle"
	personal_best_title.alignment = HORIZONTAL_ALIGNMENT_CENTER
	personal_best_title.custom_minimum_size = Vector2(0.0, 72.0)
	personal_best_title.add_theme_font_size_override("font_size", 23)
	personal_best_title.add_theme_color_override("font_color", Color("a9f0c4"))
	_style_button(personal_best_title)
	personal_best_box.add_child(personal_best_title)
	var personal_best_lines: Array[String] = []
	var best_time: Dictionary = personal_records.get("best_time", {}) as Dictionary
	var lowest_damage: Dictionary = personal_records.get("lowest_damage", {}) as Dictionary
	var highest_challenge: Dictionary = personal_records.get("highest_challenge", {}) as Dictionary
	personal_best_title.text = "🏆  %s  ·  %s  ·  ⚠ %s\nDETAILS  ›" % ["—" if best_time.is_empty() else StoryRunPresentationClass.format_duration(float(best_time.get("value", 0.0))), "★".repeat(earned_record_mastery.size()) + "☆".repeat(maxi(0, 3 - earned_record_mastery.size())), "—" if highest_challenge.is_empty() else "+%d%%" % roundi(float(highest_challenge.get("value", 0.0)) * 100.0)]
	personal_best_lines.append("Time: %s%s" % ["—" if best_time.is_empty() else StoryRunPresentationClass.format_duration(float(best_time.get("value", 0.0))), _personal_record_context(best_time)])
	personal_best_lines.append("Damage Taken: %s%s" % ["—" if lowest_damage.is_empty() else StoryRunPresentationClass.format_number(float(lowest_damage.get("value", 0.0))), _personal_record_context(lowest_damage)])
	personal_best_lines.append("Highest Difficulty: %s" % StoryStore.highest_cleared_difficulty_name(profile, stage_id).to_upper())
	personal_best_lines.append("Mastery: %s%s" % [("★".repeat(earned_record_mastery.size()) + "☆".repeat(maxi(0, 3 - earned_record_mastery.size()))), " · MASTERED" if earned_record_mastery.size() >= 3 else ""])
	personal_best_lines.append("Highest Challenge: %s%s" % ["—" if highest_challenge.is_empty() else "+%d%%" % roundi(float(highest_challenge.get("value", 0.0)) * 100.0), _personal_record_context(highest_challenge)])
	var personal_best_details := Label.new()
	personal_best_details.name = "PersonalBestDetails"
	personal_best_details.text = "\n".join(personal_best_lines)
	personal_best_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	personal_best_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	personal_best_details.add_theme_font_size_override("font_size", 20)
	personal_best_details.add_theme_color_override("font_color", Color("d5e9e3"))
	personal_best_details.visible = false
	personal_best_box.add_child(personal_best_details)
	personal_best_title.pressed.connect(func() -> void:
		personal_best_details.visible = not personal_best_details.visible
		personal_best_title.text = personal_best_title.text.replace("DETAILS  ›", "HIDE  ⌃") if personal_best_details.visible else personal_best_title.text.replace("HIDE  ⌃", "DETAILS  ›")
	)
	var story_text := Label.new(); story_text.text = str(stage.get("story", "")); story_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; story_text.add_theme_font_size_override("font_size", 28); box.add_child(story_text)
	var challenge := Label.new(); challenge.text = "CHALLENGE\n%s" % str(stage.get("challenge", "")); challenge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; challenge.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; challenge.add_theme_font_size_override("font_size", 23); challenge.add_theme_color_override("font_color", Color("ffca68")); box.add_child(challenge)
	var synergy_lines := StoryBuildCapabilitiesClass.stage_display_lines(stage_id)
	if not synergy_lines.is_empty():
		var synergy := Label.new(); synergy.text = "OPTIONAL BUILD SYNERGY\n%s" % "\n".join(synergy_lines); synergy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; synergy.add_theme_font_size_override("font_size", 20); synergy.add_theme_color_override("font_color", Color("b9f4dc")); box.add_child(synergy)
	var difficulty_title := Label.new(); difficulty_title.text = "DIFFICULTY"; difficulty_title.add_theme_font_size_override("font_size", 27); box.add_child(difficulty_title)
	var difficulty_row := HBoxContainer.new(); difficulty_row.add_theme_constant_override("separation", 8); box.add_child(difficulty_row)
	for difficulty_variant in StoryStore.STORY_DIFFICULTY_IDS:
		var difficulty_id := str(difficulty_variant)
		var available := StoryStore.difficulty_unlocked(profile, stage_id, difficulty_id)
		var difficulty_button := Button.new(); difficulty_button.text = StoryStore.difficulty_name(difficulty_id).to_upper(); difficulty_button.text += "\nSELECTED" if difficulty_id == _selected_difficulty_id else ("\nLOCKED" if not available else ""); difficulty_button.disabled = not available; difficulty_button.custom_minimum_size = Vector2(0.0, 82.0); difficulty_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; difficulty_button.add_theme_font_size_override("font_size", 19); difficulty_button.pressed.connect(func() -> void: _selected_difficulty_id = difficulty_id; _show_stage_details(_stage_index)); _style_button(difficulty_button); difficulty_row.add_child(difficulty_button)
	var difficulty_config := StoryStore.difficulty_config(stage_id, _selected_difficulty_id)
	var difficulty_details := Label.new(); difficulty_details.text = "%s\n%s" % [StoryStore.difficulty_name(_selected_difficulty_id).to_upper(), str(difficulty_config.get("summary", ""))]; difficulty_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; difficulty_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; difficulty_details.add_theme_font_size_override("font_size", 22); difficulty_details.add_theme_color_override("font_color", Color("9fdcff")); box.add_child(difficulty_details)
	var mutators := Button.new(); mutators.text = "⚠ ×%d  ·  +%d%%\nMUTATORS  ›" % [_selected_mutator_ids.size(), roundi(StoryMutatorsClass.reward_bonus(_selected_mutator_ids) * 100.0)]; mutators.custom_minimum_size = Vector2(0.0, 78.0); mutators.add_theme_font_size_override("font_size", 25); mutators.pressed.connect(_show_mutator_selector.bind(false)); _style_button(mutators); box.add_child(mutators)
	var earned_mastery := StoryStore.earned_mastery(profile, stage_id)
	var mastery_lines: Array[String] = []
	for objective_variant in StoryStore.mastery_objectives(stage_id):
		var objective: Dictionary = objective_variant as Dictionary
		var earned := str(objective.get("id", "")) in earned_mastery
		mastery_lines.append("%s %s — %s" % ["★" if earned else "☆", str(objective.get("title", "Mastery")), str(objective.get("description", ""))])
	var mastery_toggle := Button.new(); mastery_toggle.text = "%s  ·  CHAPTER %d / 15 ★\nMASTERY DETAILS  ›" % ["★".repeat(earned_mastery.size()) + "☆".repeat(maxi(0, 3 - earned_mastery.size())), StoryStore.chapter_mastery(profile, chapter_number)]; mastery_toggle.custom_minimum_size = Vector2(0.0, 78.0); mastery_toggle.add_theme_font_size_override("font_size", 23); _style_button(mastery_toggle); box.add_child(mastery_toggle)
	var mastery := Label.new(); mastery.text = "\n".join(mastery_lines); mastery.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; mastery.add_theme_font_size_override("font_size", 21); mastery.add_theme_color_override("font_color", Color("ffe29a")); mastery.visible = false; box.add_child(mastery)
	mastery_toggle.pressed.connect(func() -> void:
		mastery.visible = not mastery.visible
		mastery_toggle.text = mastery_toggle.text.replace("MASTERY DETAILS  ›", "HIDE MASTERY  ⌃") if mastery.visible else mastery_toggle.text.replace("HIDE MASTERY  ⌃", "MASTERY DETAILS  ›")
	)
	var cleared := bool(state.get("cleared", false))
	var eligible_multiplier := StoryMutatorsClass.reward_multiplier(_selected_mutator_ids) if cleared else 1.0
	var preview_coins := floori(float(stage.get("coins", 0)) * StoryStore.REPLAY_REWARD_MULTIPLIER * eligible_multiplier) if cleared else int(stage.get("coins", 0))
	var preview_materials := floori(float(stage.get("materials", 0)) * StoryStore.REPLAY_REWARD_MULTIPLIER * eligible_multiplier) if cleared else int(stage.get("materials", 0))
	var reward := Label.new(); reward.text = "%s\n%d camp coins  ·  %d upgrade materials" % ["Replay reward · challenge %.2fx" % eligible_multiplier if cleared else "First-clear reward", preview_coins, preview_materials]; reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; reward.add_theme_font_size_override("font_size", 23); reward.add_theme_color_override("font_color", Color("a7ed9a")); box.add_child(reward)
	var wallet_profile := ProgressionStore.load_profile(account_username)
	var wallet := Label.new(); wallet.text = "Upgrade materials: %d  ·  Camp coins: %d" % [int(profile.get("materials", 0)), int(wallet_profile.get("coins", 0))]; wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; wallet.add_theme_font_size_override("font_size", 22); box.add_child(wallet)
	var play := Button.new(); play.text = "%s · %s · MUTATORS ×%d" % ["REPLAY STAGE" if cleared else "START STAGE", StoryStore.difficulty_name(_selected_difficulty_id).to_upper(), _selected_mutator_ids.size()]; play.custom_minimum_size = Vector2(0.0, 94.0); play.add_theme_font_size_override("font_size", 30); play.pressed.connect(_launch_selected_stage.bind(play)); _style_button(play); box.add_child(play)
	var spacer := Control.new(); spacer.custom_minimum_size = Vector2(0.0, 20.0); box.add_child(spacer)
	var back := Button.new(); back.text = "BACK TO STORY MAP"; back.position = Vector2(70.0, view.y - 118.0 - _safe_bottom); back.size = Vector2(view.x - 140.0, 82.0); back.add_theme_font_size_override("font_size", 29); back.pressed.connect(_close_stage_details); _style_button(back); _details_layer.add_child(back)
	_apply_current_accessibility()

func _launch_selected_stage(button: Button) -> void:
	if _transition_started:
		return
	var profile := StoryStore.load_profile(account_username)
	if not StoryCampaignMapClass.stage_unlocked(profile, _stage_index):
		return
	var stage := StoryStore.stage(_stage_index)
	if not StoryStore.difficulty_unlocked(profile, str(stage.get("id", "")), _selected_difficulty_id):
		return
	_transition_started = true
	button.disabled = true
	print("[Story][DIFFICULTY] selected=%s stage=%s" % [_selected_difficulty_id, str(stage.get("id", ""))])
	stage_selected.emit(StoryStore.configure_run(stage, _selected_difficulty_id, _selected_mutator_ids, profile))

func _close_stage_details() -> void:
	if _details_layer != null and is_instance_valid(_details_layer):
		_details_layer.queue_free()
	_details_layer = null
	_transition_started = false

func _show_boss_practice_roster() -> void:
	_close_boss_practice()
	_practice_layer = CanvasLayer.new()
	_practice_layer.layer = 205
	add_child(_practice_layer)
	var view := get_viewport_rect().size
	var shade := ColorRect.new(); shade.color = Color(0.01, 0.02, 0.035, 0.97); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; _practice_layer.add_child(shade)
	var title := Label.new(); title.text = "BOSS PRACTICE"; title.position = Vector2(40.0, 38.0 + _safe_top); title.size = Vector2(view.x - 80.0, 72.0); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 48); title.add_theme_color_override("font_color", Color("ffd66b")); _practice_layer.add_child(title)
	var note := Label.new(); note.text = "Train with your current build · Rewards and Story progress disabled"; note.position = Vector2(55.0, 110.0 + _safe_top); note.size = Vector2(view.x - 110.0, 72.0); note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; note.add_theme_font_size_override("font_size", 23); note.add_theme_color_override("font_color", Color("a9d8e8")); _practice_layer.add_child(note)
	var scroll := ScrollContainer.new(); scroll.position = Vector2(48.0, 194.0 + _safe_top); scroll.size = Vector2(view.x - 96.0, view.y - 330.0 - _safe_top - _safe_bottom); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; _practice_layer.add_child(scroll)
	var list := VBoxContainer.new(); list.custom_minimum_size = Vector2(view.x - 120.0, 0.0); list.set_meta("accessibility_no_scale", true); list.add_theme_constant_override("separation", 14); scroll.add_child(list)
	var profile := StoryStore.load_profile(account_username)
	var debug_override := OS.is_debug_build()
	for stage_id in StoryBossPracticeClass.BOSS_STAGE_IDS:
		var data := StoryBossPracticeClass.boss(stage_id)
		var available := StoryBossPracticeClass.unlocked(profile, stage_id, debug_override)
		var button := Button.new()
		if available:
			button.text = "CHAPTER %d  ·  %s\nBest Story Clear: %s%s" % [int(data.get("chapter", 0)), str(data.get("name", "Chapter Boss")), StoryStore.highest_cleared_difficulty_name(profile, stage_id), "  ·  DEV override" if debug_override and stage_id not in (profile.get("cleared", []) as Array) else ""]
		else:
			button.text = "CHAPTER %d BOSS\n🔒 Defeat the Chapter %d Boss in Story Mode" % [int(data.get("chapter", 0)), int(data.get("chapter", 0))]
		button.disabled = not available
		button.custom_minimum_size = Vector2(0.0, 126.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 27)
		button.pressed.connect(_show_boss_practice_config.bind(stage_id))
		_style_button(button)
		list.add_child(button)
	var back := Button.new(); back.text = "Return to Story Menu"; back.position = Vector2(70.0, view.y - 112.0 - _safe_bottom); back.size = Vector2(view.x - 140.0, 76.0); back.add_theme_font_size_override("font_size", 29); back.pressed.connect(_close_boss_practice); _style_button(back); _practice_layer.add_child(back)
	_apply_current_accessibility()

func _show_boss_practice_config(stage_id: String) -> void:
	var profile := StoryStore.load_profile(account_username)
	var debug_override := OS.is_debug_build()
	if not StoryBossPracticeClass.unlocked(profile, stage_id, debug_override):
		return
	_close_boss_practice()
	_practice_stage_id = stage_id
	_stage_index = StoryStore.stage_index(stage_id)
	if not StoryBossPracticeClass.phase_valid(stage_id, _practice_phase_id):
		_practice_phase_id = "full"
	if not StoryBossPracticeClass.difficulty_available(profile, stage_id, _selected_difficulty_id, debug_override):
		_selected_difficulty_id = "normal"
	_practice_mutator_ids = StoryMutatorsClass.sanitize_selection(profile, stage_id, _practice_mutator_ids, debug_override)
	_practice_layer = CanvasLayer.new(); _practice_layer.layer = 205; add_child(_practice_layer)
	var view := get_viewport_rect().size
	var shade := ColorRect.new(); shade.color = Color(0.01, 0.02, 0.035, 0.98); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; _practice_layer.add_child(shade)
	var panel := PanelContainer.new(); panel.position = Vector2(55.0, 48.0 + _safe_top); panel.size = Vector2(view.x - 110.0, view.y - 96.0 - _safe_top - _safe_bottom); panel.add_theme_stylebox_override("panel", _panel_style()); _practice_layer.add_child(panel)
	var scroll := ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; panel.add_child(scroll)
	var box := VBoxContainer.new(); box.custom_minimum_size = Vector2(view.x - 190.0, 0.0); box.set_meta("accessibility_no_scale", true); box.add_theme_constant_override("separation", 15); scroll.add_child(box)
	var boss_data := StoryBossPracticeClass.boss(stage_id)
	var title := Label.new(); title.text = str(boss_data.get("name", "BOSS PRACTICE")).to_upper(); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 46); title.add_theme_color_override("font_color", Color("ffd66b")); box.add_child(title)
	var safety := Label.new(); safety.text = "PRACTICE · REWARDS DISABLED\nStory clears, Mastery, unlocks, and currencies are not changed."; safety.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; safety.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; safety.add_theme_font_size_override("font_size", 22); safety.add_theme_color_override("font_color", Color("9fdcff")); box.add_child(safety)
	var difficulty_title := Label.new(); difficulty_title.text = "DIFFICULTY"; difficulty_title.add_theme_font_size_override("font_size", 27); box.add_child(difficulty_title)
	var difficulty_row := HBoxContainer.new(); difficulty_row.add_theme_constant_override("separation", 8); box.add_child(difficulty_row)
	for difficulty_variant in StoryStore.STORY_DIFFICULTY_IDS:
		var difficulty_id := str(difficulty_variant)
		var available := StoryBossPracticeClass.difficulty_available(profile, stage_id, difficulty_id, debug_override)
		var difficulty_status := "\nSELECTED" if difficulty_id == _selected_difficulty_id else ("\nLOCKED · Clear in Story" if not available else "")
		var difficulty_button := Button.new(); difficulty_button.text = StoryStore.difficulty_name(difficulty_id).to_upper() + difficulty_status; difficulty_button.disabled = not available; difficulty_button.custom_minimum_size = Vector2(0.0, 82.0); difficulty_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; difficulty_button.add_theme_font_size_override("font_size", 19); difficulty_button.pressed.connect(func() -> void: _selected_difficulty_id = difficulty_id; _show_boss_practice_config(stage_id)); _style_button(difficulty_button); difficulty_row.add_child(difficulty_button)
	var phase_title := Label.new(); phase_title.text = "PRACTICE PHASE"; phase_title.add_theme_font_size_override("font_size", 27); box.add_child(phase_title)
	var phases := OptionButton.new(); phases.custom_minimum_size = Vector2(0.0, 88.0); phases.add_theme_font_size_override("font_size", 28); phases.alignment = HORIZONTAL_ALIGNMENT_CENTER; _style_button(phases)
	var phase_defs := StoryBossPracticeClass.phases(stage_id)
	for phase_index in phase_defs.size():
		var phase: Dictionary = phase_defs[phase_index] as Dictionary
		phases.add_item(str(phase.get("name", "Full Fight")), phase_index)
		if str(phase.get("id", "full")) == _practice_phase_id: phases.select(phase_index)
	phases.item_selected.connect(func(index: int) -> void: _practice_phase_id = str((phase_defs[index] as Dictionary).get("id", "full")))
	box.add_child(phases)
	if stage_id == "ch3_5":
		var brew_title := Label.new(); brew_title.text = "SIMULATED ANTIDOTE QUALITY"; brew_title.add_theme_font_size_override("font_size", 27); box.add_child(brew_title)
		var brews := OptionButton.new(); brews.custom_minimum_size = Vector2(0.0, 84.0); brews.add_theme_font_size_override("font_size", 27); brews.alignment = HORIZONTAL_ALIGNMENT_CENTER; _style_button(brews)
		for brew_index in StoryBossPracticeClass.BREW_PRESETS.size():
			var brew: Dictionary = StoryBossPracticeClass.BREW_PRESETS[brew_index]
			brews.add_item("%s · %d%% Purity" % [str(brew.get("name", "Stable")), roundi(float(brew.get("purity", 65.0)))], brew_index)
			if str(brew.get("id", "stable")) == _practice_brew_id: brews.select(brew_index)
		brews.item_selected.connect(func(index: int) -> void: _practice_brew_id = str(StoryBossPracticeClass.BREW_PRESETS[index].get("id", "stable")))
		box.add_child(brews)
	var mutators := Button.new(); mutators.text = "MUTATORS · %d / %d\nRewards remain disabled" % [_practice_mutator_ids.size(), StoryMutatorsClass.MAX_ACTIVE]; mutators.custom_minimum_size = Vector2(0.0, 88.0); mutators.add_theme_font_size_override("font_size", 25); mutators.pressed.connect(_show_mutator_selector.bind(false, true)); _style_button(mutators); box.add_child(mutators)
	var tips := Label.new(); tips.text = "BOSS TIP\n%s" % str(boss_data.get("hint", "")); tips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tips.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; tips.add_theme_font_size_override("font_size", 23); tips.add_theme_color_override("font_color", Color("b9f4dc")); box.add_child(tips)
	var start := Button.new(); start.text = "START PRACTICE"; start.custom_minimum_size = Vector2(0.0, 96.0); start.add_theme_font_size_override("font_size", 34); start.pressed.connect(_launch_boss_practice); _style_button(start); box.add_child(start)
	var choose := Button.new(); choose.text = "Choose Boss"; choose.custom_minimum_size = Vector2(0.0, 76.0); choose.add_theme_font_size_override("font_size", 27); choose.pressed.connect(_show_boss_practice_roster); _style_button(choose); box.add_child(choose)
	var close := Button.new(); close.text = "Return to Story Menu"; close.custom_minimum_size = Vector2(0.0, 76.0); close.add_theme_font_size_override("font_size", 27); close.pressed.connect(_close_boss_practice); _style_button(close); box.add_child(close)
	_apply_current_accessibility()

func _launch_boss_practice() -> void:
	var profile := StoryStore.load_profile(account_username)
	var debug_override := OS.is_debug_build()
	if not StoryBossPracticeClass.unlocked(profile, _practice_stage_id, debug_override) or not StoryBossPracticeClass.difficulty_available(profile, _practice_stage_id, _selected_difficulty_id, debug_override):
		push_warning("Boss Practice launch rejected by Story clear requirements.")
		return
	var configured := StoryBossPracticeClass.configure(StoryStore.stage(StoryStore.stage_index(_practice_stage_id)), _selected_difficulty_id, _practice_mutator_ids, profile, _practice_phase_id, _practice_brew_id, debug_override)
	if configured.is_empty():
		return
	print("[BossPractice][%s][%s] Selected: %s · Mutators: %s" % [_practice_stage_id, _selected_difficulty_id.to_upper(), _practice_phase_id, ", ".join(_practice_mutator_ids)])
	practice_selected.emit(configured)

func _close_boss_practice() -> void:
	if _practice_layer != null and is_instance_valid(_practice_layer):
		_practice_layer.queue_free()
	_practice_layer = null

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
	var panel := PanelContainer.new(); panel.position = Vector2(65.0, view.y * 0.08); panel.size = Vector2(view.x - 130.0, 1120.0); panel.add_theme_stylebox_override("panel", _panel_style()); _dev_test_layer.add_child(panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 22); panel.add_child(box)
	var title := Label.new(); title.text = "DEV STORY TEST"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 50); title.add_theme_color_override("font_color", Color("ffd66b")); box.add_child(title)
	var note := Label.new(); note.text = "Progress, rewards, records, and unlocks are not saved.%s" % ("\n" + _dev_mutator_notice if not _dev_mutator_notice.is_empty() else ""); note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; note.add_theme_font_size_override("font_size", 30); box.add_child(note)
	var stages := OptionButton.new(); stages.custom_minimum_size = Vector2(0.0, 108.0); stages.add_theme_font_size_override("font_size", 38); stages.add_theme_icon_override("arrow", load("res://assets/icons/dev_dropdown_arrow.svg") as Texture2D); stages.add_theme_constant_override("arrow_margin", 26); stages.alignment = HORIZONTAL_ALIGNMENT_CENTER; _style_button(stages)
	var stage_popup: PopupMenu = stages.get_popup(); stage_popup.add_theme_font_size_override("font_size", 35); stage_popup.add_theme_constant_override("item_start_padding", 32); stage_popup.add_theme_constant_override("item_end_padding", 32); stage_popup.add_theme_constant_override("v_separation", 10)
	for index in StoryStore.stage_count():
		var stage: Dictionary = StoryStore.stage(index)
		stages.add_item("C%dS%d — %s" % [int(stage.chapter), int(stage.chapter_stage), str(stage.name).get_slice("  ", 1)], index)
	stages.select(clampi(_stage_index, 0, StoryStore.stage_count() - 1)); stages.item_selected.connect(_on_dev_stage_changed); box.add_child(stages)
	var difficulties := OptionButton.new(); difficulties.custom_minimum_size = Vector2(0.0, 96.0); difficulties.add_theme_font_size_override("font_size", 34); difficulties.add_theme_icon_override("arrow", load("res://assets/icons/dev_dropdown_arrow.svg") as Texture2D); difficulties.add_theme_constant_override("arrow_margin", 26); difficulties.alignment = HORIZONTAL_ALIGNMENT_CENTER; _style_button(difficulties)
	for difficulty_index in StoryStore.STORY_DIFFICULTY_IDS.size():
		var difficulty_id := str(StoryStore.STORY_DIFFICULTY_IDS[difficulty_index])
		difficulties.add_item("%s · unlock bypass" % StoryStore.difficulty_name(difficulty_id), difficulty_index)
	difficulties.select(StoryStore.difficulty_rank(_selected_difficulty_id)); difficulties.item_selected.connect(func(index: int) -> void: _selected_difficulty_id = str(StoryStore.STORY_DIFFICULTY_IDS[index])); box.add_child(difficulties)
	var build_profiles := OptionButton.new(); build_profiles.custom_minimum_size = Vector2(0.0, 88.0); build_profiles.add_theme_font_size_override("font_size", 30); build_profiles.add_theme_icon_override("arrow", load("res://assets/icons/dev_dropdown_arrow.svg") as Texture2D); build_profiles.add_theme_constant_override("arrow_margin", 26); build_profiles.alignment = HORIZONTAL_ALIGNMENT_CENTER; _style_button(build_profiles)
	for profile_index in StoryBuildCapabilitiesClass.DEV_PROFILE_IDS.size():
		var profile_id := StoryBuildCapabilitiesClass.DEV_PROFILE_IDS[profile_index]
		build_profiles.add_item("BUILD · %s" % str(StoryBuildCapabilitiesClass.DEV_PROFILE_LABELS.get(profile_id, profile_id)), profile_index)
	build_profiles.select(maxi(0, StoryBuildCapabilitiesClass.DEV_PROFILE_IDS.find(_dev_build_profile_id))); build_profiles.item_selected.connect(func(index: int) -> void: _dev_build_profile_id = StoryBuildCapabilitiesClass.DEV_PROFILE_IDS[index]); box.add_child(build_profiles)
	_dev_selected_mutator_ids = StoryMutatorsClass.sanitize_selection({}, str(StoryStore.stage(_stage_index).id), _dev_selected_mutator_ids, true)
	var mutator_choice := Button.new(); mutator_choice.text = "MUTATORS · %d / %d · unlock bypass" % [_dev_selected_mutator_ids.size(), StoryMutatorsClass.MAX_ACTIVE]; mutator_choice.custom_minimum_size = Vector2(0.0, 92.0); mutator_choice.add_theme_font_size_override("font_size", 30); mutator_choice.pressed.connect(func() -> void: _stage_index = stages.get_selected_id(); _selected_difficulty_id = str(StoryStore.STORY_DIFFICULTY_IDS[difficulties.get_selected_id()]); _show_mutator_selector(true)); _style_button(mutator_choice); box.add_child(mutator_choice)
	var start := Button.new(); start.text = "START TEST"; start.custom_minimum_size = Vector2(0.0, 102.0); start.add_theme_font_size_override("font_size", 40); _style_button(start); box.add_child(start)
	start.pressed.connect(func() -> void:
		if not OS.is_debug_build():
			push_warning("Story test launch rejected in a release build.")
			return
		var selected_index: int = stages.get_selected_id()
		var difficulty_id := str(StoryStore.STORY_DIFFICULTY_IDS[difficulties.get_selected_id()])
		var selected_stage: Dictionary = StoryStore.configure_run(StoryStore.stage(selected_index), difficulty_id, _dev_selected_mutator_ids, {}, true)
		selected_stage["dev_build_profile"] = _dev_build_profile_id
		print("[Story][TEST][%s][C%dS%d][0.00s] Test stage selected · Build: %s · Mutators: %s" % [StoryStore.difficulty_name(difficulty_id).to_upper(), int(selected_stage.chapter), int(selected_stage.chapter_stage), _dev_build_profile_id, ", ".join(_dev_selected_mutator_ids)])
		test_stage_selected.emit(selected_stage)
	)
	var cancel := Button.new(); cancel.text = "Cancel"; cancel.custom_minimum_size = Vector2(0.0, 88.0); cancel.add_theme_font_size_override("font_size", 36); cancel.pressed.connect(func() -> void: _dev_test_layer.queue_free()); _style_button(cancel); box.add_child(cancel)
	_apply_current_accessibility()

func _show_mutator_selector(dev_mode: bool = false, practice_mode: bool = false) -> void:
	_mutator_dev_mode = dev_mode
	_mutator_practice_mode = practice_mode
	_mutator_draft = (_dev_selected_mutator_ids if dev_mode else (_practice_mutator_ids if practice_mode else _selected_mutator_ids)).duplicate()
	_rebuild_mutator_selector()

func _on_dev_stage_changed(index: int) -> void:
	_stage_index = clampi(index, 0, StoryStore.stage_count() - 1)
	var previous := _dev_selected_mutator_ids.duplicate()
	_dev_selected_mutator_ids = StoryMutatorsClass.sanitize_selection({}, str(StoryStore.stage(_stage_index).id), _dev_selected_mutator_ids, true)
	var removed: Array[String] = []
	for mutator_id_variant in previous:
		var mutator_id := str(mutator_id_variant)
		if mutator_id not in _dev_selected_mutator_ids: removed.append(StoryMutatorsClass.display_name(mutator_id))
	_dev_mutator_notice = "Removed for this stage: %s" % ", ".join(removed) if not removed.is_empty() else ""
	call_deferred("_show_dev_story_test_selector")

func _rebuild_mutator_selector() -> void:
	if _mutator_layer != null and is_instance_valid(_mutator_layer):
		_mutator_layer.queue_free()
	_mutator_layer = CanvasLayer.new()
	_mutator_layer.layer = 230
	add_child(_mutator_layer)
	var view := get_viewport_rect().size
	var stage := StoryStore.stage(_stage_index)
	var profile := StoryStore.load_profile(account_username)
	var shade := ColorRect.new(); shade.color = Color(0.01, 0.01, 0.02, 0.96); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; _mutator_layer.add_child(shade)
	var title := Label.new(); title.text = "MUTATORS  ·  %d / %d" % [_mutator_draft.size(), StoryMutatorsClass.MAX_ACTIVE]; title.position = Vector2(50.0, 42.0); title.size = Vector2(view.x - 100.0, 72.0); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 46); title.add_theme_color_override("font_color", Color("ffd66b")); _mutator_layer.add_child(title)
	var mode_text := "DEV unlock bypass" if _mutator_dev_mode else ("Practice · rewards disabled" if _mutator_practice_mode else "optional challenge")
	var subtitle := Label.new(); subtitle.text = "C%dS%d · %s%s" % [int(stage.chapter), int(stage.chapter_stage), mode_text, " · Challenge Bonus +%d%%" % roundi(StoryMutatorsClass.reward_bonus(_mutator_draft) * 100.0) if not _mutator_practice_mode else ""]; subtitle.position = Vector2(40.0, 112.0); subtitle.size = Vector2(view.x - 80.0, 54.0); subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; subtitle.add_theme_font_size_override("font_size", 24); subtitle.add_theme_color_override("font_color", Color("ffbf73")); _mutator_layer.add_child(subtitle)
	var scroll := ScrollContainer.new(); scroll.name = "MutatorScroll"; scroll.position = Vector2(42.0, 176.0); scroll.size = Vector2(view.x - 84.0, view.y - 390.0); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO; _mutator_layer.add_child(scroll)
	var list := VBoxContainer.new(); list.name = "MutatorList"; list.custom_minimum_size = Vector2(view.x - 108.0, 0.0); list.set_meta("accessibility_no_scale", true); list.add_theme_constant_override("separation", 10); scroll.add_child(list)
	for definition_variant in StoryMutatorsClass.DEFINITIONS:
		var item: Dictionary = definition_variant as Dictionary
		var mutator_id := str(item.get("id", ""))
		var selected := mutator_id in _mutator_draft
		var bypass_unlocks := _mutator_dev_mode or (_mutator_practice_mode and OS.is_debug_build())
		var issue := "" if selected else StoryMutatorsClass.selection_issue(profile, str(stage.id), _mutator_draft, mutator_id, bypass_unlocks)
		var button := Button.new()
		button.text = "%s  %s · %s · +%d%%\n%s%s" % ["✓" if selected else "○", str(item.get("name", mutator_id)), str(item.get("category", "Special")), roundi(float(item.get("reward_weight", 0.0)) * 100.0), str(item.get("description", "")), "\n" + issue if not issue.is_empty() else ""]
		button.custom_minimum_size = Vector2(0.0, 112.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 22)
		button.disabled = not selected and not issue.is_empty()
		button.pressed.connect(_toggle_mutator.bind(mutator_id))
		_style_button(button)
		list.add_child(button)
	var apply := Button.new(); apply.text = "APPLY  ·  %d SELECTED" % _mutator_draft.size(); apply.position = Vector2(55.0, view.y - 188.0); apply.size = Vector2(view.x - 110.0, 76.0); apply.add_theme_font_size_override("font_size", 30); apply.pressed.connect(_commit_mutator_selection); _style_button(apply); _mutator_layer.add_child(apply)
	var cancel := Button.new(); cancel.text = "Cancel"; cancel.position = Vector2(55.0, view.y - 100.0); cancel.size = Vector2(view.x - 110.0, 64.0); cancel.add_theme_font_size_override("font_size", 26); cancel.pressed.connect(_close_mutator_selector); _style_button(cancel); _mutator_layer.add_child(cancel)
	_apply_current_accessibility()

func _toggle_mutator(mutator_id: String) -> void:
	if mutator_id in _mutator_draft:
		_mutator_draft.erase(mutator_id)
	else:
		var stage_id := str(StoryStore.stage(_stage_index).id)
		var bypass_unlocks := _mutator_dev_mode or (_mutator_practice_mode and OS.is_debug_build())
		var issue := StoryMutatorsClass.selection_issue(StoryStore.load_profile(account_username), stage_id, _mutator_draft, mutator_id, bypass_unlocks)
		if not issue.is_empty():
			print("[Story][MUTATOR] rejected=%s stage=%s reason=%s" % [mutator_id, stage_id, issue])
			return
		_mutator_draft.append(mutator_id)
		print("[Story][MUTATOR] selected=%s stage=%s" % [mutator_id, stage_id])
	_rebuild_mutator_selector()

func _commit_mutator_selection() -> void:
	var practice_mode := _mutator_practice_mode
	var dev_mode := _mutator_dev_mode
	if dev_mode:
		_dev_selected_mutator_ids = _mutator_draft.duplicate()
	elif practice_mode:
		_practice_mutator_ids = _mutator_draft.duplicate()
	else:
		_selected_mutator_ids = _mutator_draft.duplicate()
	_close_mutator_selector()
	if practice_mode:
		_show_boss_practice_config(_practice_stage_id)
	elif not dev_mode:
		_show_stage_details(_stage_index)

func _close_mutator_selector() -> void:
	if _mutator_layer != null and is_instance_valid(_mutator_layer):
		_mutator_layer.queue_free()
	_mutator_layer = null
	_mutator_practice_mode = false
	_mutator_dev_mode = false

func _show_chapter_mastery(chapter_number: int) -> void:
	if _mastery_reward_layer != null and is_instance_valid(_mastery_reward_layer):
		_mastery_reward_layer.queue_free()
	_mastery_reward_layer = CanvasLayer.new()
	_mastery_reward_layer.name = "ChapterMasteryLayer"
	_mastery_reward_layer.layer = 190
	add_child(_mastery_reward_layer)
	var view := get_viewport_rect().size
	var profile := StoryStore.load_profile(account_username)
	var chapter_data := StoryStore.chapter(chapter_number - 1)
	var stars := StoryStore.chapter_mastery(profile, chapter_number)
	var chapter_unlocked := StoryCampaignMapClass.stage_unlocked(profile, (chapter_number - 1) * StoryCampaignMapClass.STAGES_PER_CHAPTER)
	var shade := ColorRect.new(); shade.color = Color(0.005, 0.012, 0.02, 0.94); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; _mastery_reward_layer.add_child(shade)
	var panel := PanelContainer.new(); panel.position = Vector2(42.0, 42.0 + _safe_top); panel.size = Vector2(view.x - 84.0, view.y - 84.0 - _safe_top - _safe_bottom); panel.add_theme_stylebox_override("panel", _panel_style()); _mastery_reward_layer.add_child(panel)
	var scroll := ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO; panel.add_child(scroll)
	var box := VBoxContainer.new(); box.name = "ChapterMasteryContent"; box.custom_minimum_size = Vector2(view.x - 164.0, 0.0); box.set_meta("accessibility_no_scale", true); box.add_theme_constant_override("separation", 14); scroll.add_child(box)
	var title := Label.new(); title.text = "CHAPTER %d MASTERY" % chapter_number; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 42); title.add_theme_color_override("font_color", Color("ffd66b")); box.add_child(title)
	var chapter_name := Label.new(); chapter_name.text = str(chapter_data.get("name", "STORY")).to_upper(); chapter_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; chapter_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; chapter_name.add_theme_font_size_override("font_size", 23); chapter_name.add_theme_color_override("font_color", Color("b9d8e2")); box.add_child(chapter_name)
	var total := Label.new(); total.text = "%d / 15 ★%s" % [stars, "  ·  CHAPTER MASTERED ◆" if stars >= 15 else ("  ·  Chapter locked" if not chapter_unlocked else "")]; total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; total.add_theme_font_size_override("font_size", 30); total.add_theme_color_override("font_color", Color("b9efb0") if stars >= 15 else Color.WHITE); box.add_child(total)
	var progress := ProgressBar.new(); progress.min_value = 0.0; progress.max_value = 15.0; progress.value = stars; progress.show_percentage = false; progress.custom_minimum_size = Vector2(0.0, 30.0); box.add_child(progress)
	if not _mastery_notice.is_empty():
		var notice := Label.new(); notice.text = _mastery_notice; notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; notice.add_theme_font_size_override("font_size", 22); notice.add_theme_color_override("font_color", Color("9ff0ac") if _mastery_notice.begins_with("CLAIMED") else Color("ffb19f")); box.add_child(notice)
	if bool(_mastery_claim_result.get("ok", false)):
		var claimed_card := RewardItemCardClass.new(); claimed_card.name = "ClaimedMasteryReward"; claimed_card.configure("material", {"name":"Reward Claimed", "rarity":"milestone", "icon":"res://assets/camp/resources/forgecore_material.png", "primary_effect":"+%d Upgrade Materials" % int(_mastery_claim_result.get("materials", 0))}, {"milestone":true}, 1, 0, true, true); claimed_card.mouse_filter = Control.MOUSE_FILTER_IGNORE; claimed_card.custom_minimum_size = Vector2(0.0, 248.0); box.add_child(claimed_card); claimed_card.call_deferred("play_reveal", SettingsStore.load_all(), "milestone")
	for reward in StoryStore.chapter_mastery_rewards(chapter_number):
		var reward_id := str(reward.get("id", ""))
		var threshold := int(reward.get("threshold", 0))
		var materials := int(reward.get("materials", 0))
		var state := StoryStore.mastery_reward_state(profile, reward_id)
		var reward_content := "%d upgrade material%s" % [materials, "s" if materials != 1 else ""]
		if bool(reward.get("emblem", false)):
			reward_content += " · Chapter Master emblem earned automatically"
		var state_text := "CLAIM"
		if state == "claimed": state_text = "CLAIMED ✓"
		elif state == "locked": state_text = "Need %d more ★" % maxi(0, threshold - stars)
		var milestone := Button.new(); milestone.name = "MasteryReward_%s" % reward_id; milestone.text = "★  %d / 15    %s\n%s  ·  %s" % [threshold, str(reward.get("name", "Mastery Reward")).to_upper(), reward_content, state_text]; milestone.icon = MASTERY_MATERIAL_ICON; milestone.expand_icon = true; milestone.add_theme_constant_override("icon_max_width", 54); milestone.custom_minimum_size = Vector2(0.0, 112.0); milestone.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; milestone.add_theme_font_size_override("font_size", 22); milestone.disabled = state != "available"; milestone.pressed.connect(_claim_mastery_reward.bind(chapter_number, reward_id, milestone)); _style_button(milestone); box.add_child(milestone)
	var explanation := Label.new(); explanation.text = "Stars come from the three permanent Mastery objectives on each Story stage. Difficulty and mutators do not multiply these rewards."; explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; explanation.add_theme_font_size_override("font_size", 20); explanation.add_theme_color_override("font_color", Color("a9bdc5")); box.add_child(explanation)
	var close := Button.new(); close.text = "BACK TO STORY MAP"; close.custom_minimum_size = Vector2(0.0, 78.0); close.add_theme_font_size_override("font_size", 27); close.pressed.connect(_close_chapter_mastery); _style_button(close); box.add_child(close)
	_apply_current_accessibility()

func _claim_mastery_reward(chapter_number: int, reward_id: String, button: Button) -> void:
	if _mastery_claim_in_progress:
		return
	_mastery_claim_in_progress = true
	button.disabled = true
	var result := StoryStore.claim_mastery_reward(account_username, chapter_number, reward_id)
	if bool(result.get("ok", false)):
		_mastery_claim_result = result.duplicate(true)
		_mastery_notice = "CLAIMED · +%d upgrade material%s" % [int(result.get("materials", 0)), "s" if int(result.get("materials", 0)) != 1 else ""]
		print("[Story][MasteryReward] claim_id=%s chapter=%d threshold=%d materials=%d balance=%d" % [reward_id, chapter_number, int(result.get("threshold", 0)), int(result.get("materials", 0)), int(result.get("balance", 0))])
		cloud_sync_requested.emit()
	else:
		_mastery_claim_result = {}
		_mastery_notice = "CLAIM FAILED · %s" % str(result.get("error", "Please try again."))
		print("[Story][MasteryReward] claim_rejected=%s chapter=%d reason=%s" % [reward_id, chapter_number, str(result.get("error", "unknown"))])
	_mastery_claim_in_progress = false
	_build_map(true)
	_show_chapter_mastery(chapter_number)

func _close_chapter_mastery() -> void:
	if _mastery_reward_layer != null and is_instance_valid(_mastery_reward_layer):
		_mastery_reward_layer.queue_free()
	_mastery_reward_layer = null
	_mastery_notice = ""
	_mastery_claim_result = {}

func _show_chapter_reward(chapter_number: int, revealed: bool) -> void:
	if _reward_layer != null and is_instance_valid(_reward_layer): _reward_layer.queue_free()
	_reward_layer = CanvasLayer.new(); _reward_layer.layer = 180; add_child(_reward_layer)
	var view := get_viewport_rect().size
	var shade := ColorRect.new(); shade.color = Color(0, 0, 0, 0.90); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; _reward_layer.add_child(shade)
	var title := Label.new(); title.text = "CHAPTER %d COMPLETE" % chapter_number; title.position = Vector2(60, 120); title.size = Vector2(view.x - 120, 80); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 48); title.add_theme_color_override("font_color", Color("ffd66b")); _reward_layer.add_child(title)
	if not revealed:
		var chest_size := Vector2(500, 500)
		var chest := Button.new(); chest.position = (view - chest_size) * 0.5; chest.size = chest_size; chest.icon = load("res://assets/story/chapters/chapter_chest.png") as Texture2D; chest.expand_icon = true; chest.add_theme_constant_override("icon_max_width", 390); chest.text = "CLAIM"; chest.add_theme_font_size_override("font_size", 36); chest.focus_mode = Control.FOCUS_NONE
		var empty_style := StyleBoxEmpty.new(); chest.add_theme_stylebox_override("normal", empty_style); chest.add_theme_stylebox_override("hover", empty_style); chest.add_theme_stylebox_override("pressed", empty_style); chest.add_theme_stylebox_override("focus", empty_style); chest.pressed.connect(_open_chapter_chest.bind(chapter_number)); _reward_layer.add_child(chest)
		var instruction := Label.new(); instruction.text = "Chapter rewards are granted immediately"; instruction.position = Vector2(90, chest.position.y + chest.size.y + 24); instruction.size = Vector2(view.x - 180, 60); instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; instruction.add_theme_font_size_override("font_size", 25); instruction.add_theme_color_override("font_color", Color("ffe2a1")); _reward_layer.add_child(instruction)
		_apply_current_accessibility()
		return
	var chapter := StoryStore.chapter(chapter_number - 1)
	var rewards: Array = chapter.get("reward", []) as Array
	var row := HBoxContainer.new(); row.position = Vector2(70, 300); row.size = Vector2(view.x - 140, 570); row.add_theme_constant_override("separation", 24); _reward_layer.add_child(row)
	for gear_id_variant in rewards:
		var gear_id := String(gear_id_variant); var gear: Dictionary = StoryStore.GEAR[gear_id] as Dictionary
		var reward_data := gear.duplicate(true); reward_data["rarity"] = "milestone"; reward_data["tier"] = StoryStore.gear_level(StoryStore.load_profile(account_username), gear_id); reward_data["icon"] = "res://assets/story/equipment/%s.png" % gear_id; reward_data["primary_effect"] = StoryStore.effect_text(gear_id)
		var card := RewardItemCardClass.new(); card.size_flags_horizontal = Control.SIZE_EXPAND_FILL; card.configure("equipment", reward_data, {"new":gear_id in _chapter_reward_new_ids, "first_clear":true}, 1, 0, false, true); row.add_child(card); card.call_deferred("play_reveal", SettingsStore.load_all(), "milestone")
	var next := Button.new(); next.text = "Next Chapter" if chapter_number < StoryStore.CHAPTERS.size() else "Story Complete"; next.position = Vector2((view.x - 430) * 0.5, view.y - 250); next.size = Vector2(430, 90); next.add_theme_font_size_override("font_size", 32); next.pressed.connect(_finish_chapter_reward.bind(chapter_number)); _style_button(next); _reward_layer.add_child(next)
	_apply_current_accessibility()

func _open_chapter_chest(chapter_number: int) -> void:
	if _chapter_claim_in_progress:
		return
	_chapter_claim_in_progress = true
	_chapter_reward_new_ids = StoryStore.claim_chapter(account_username, chapter_number)
	var claimed := StoryStore.is_chapter_claimed(StoryStore.load_profile(account_username), chapter_number)
	_chapter_claim_in_progress = false
	if not claimed:
		push_warning("Chapter reward claim could not be saved.")
		return
	cloud_sync_requested.emit()
	_show_chapter_reward(chapter_number, true)

func _finish_chapter_reward(chapter_number: int) -> void:
	if _reward_layer != null: _reward_layer.queue_free()
	_reward_layer = null
	_chapter_reward_new_ids.clear()
	if chapter_number < StoryStore.CHAPTERS.size():
		_stage_index = chapter_number * 5
		_selected_difficulty_id = "normal"
		_selected_mutator_ids.clear()
	_build_map()

func _personal_record_context(metric: Dictionary) -> String:
	if metric.is_empty():
		return ""
	var parts: Array[String] = []
	var difficulty_id := str(metric.get("difficulty", ""))
	if difficulty_id in StoryStore.STORY_DIFFICULTY_IDS:
		parts.append(StoryStore.difficulty_name(difficulty_id).to_upper())
	var mutator_names := StoryMutatorsClass.names(metric.get("mutator_ids", []) as Array)
	if not mutator_names.is_empty():
		parts.append(" + ".join(mutator_names))
	return "" if parts.is_empty() else " · %s" % " + ".join(parts)

func _personal_best_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.10, 0.095, 0.88)
	style.border_color = Color(0.42, 0.82, 0.65, 0.72)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	return style

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.03, 0.06, 0.08, 0.92); style.border_color = Color(0.86, 0.66, 0.22, 0.92); style.set_border_width_all(3); style.corner_radius_top_left = 24; style.corner_radius_top_right = 24; style.corner_radius_bottom_left = 24; style.corner_radius_bottom_right = 24; style.content_margin_left = 28; style.content_margin_right = 28; style.content_margin_top = 24; style.content_margin_bottom = 24; return style

func _map_chapter_style(accent: Color, complete: bool) -> StyleBoxFlat:
	var style := _lobby_button_box(Color(0.025, 0.045, 0.055, 0.94), accent.lightened(0.20) if complete else accent, 4 if complete else 3, 8)
	style.content_margin_left = 20.0; style.content_margin_right = 20.0; style.content_margin_top = 12.0; style.content_margin_bottom = 12.0
	return style

func _style_map_node(button: Button, state: Dictionary, accent: Color, selected: bool) -> void:
	var locked := not bool(state.get("unlocked", false))
	var cleared := bool(state.get("cleared", false))
	var current := bool(state.get("current", false))
	var boss := bool(state.get("boss", false))
	var background := Color(0.07, 0.09, 0.12, 0.96)
	var border := Color(0.38, 0.42, 0.48, 0.84)
	if cleared:
		background = accent.darkened(0.58); border = accent.lightened(0.18)
	if current:
		background = Color(0.10, 0.24, 0.29, 0.98); border = Color("9eefff")
	if boss and not locked:
		border = Color("ffd66b")
	if selected and not locked:
		border = Color.WHITE
	var normal := _lobby_button_box(background, border, 5 if boss or current or selected else 3, 9)
	var hover := _lobby_button_box(background.lightened(0.10), border.lightened(0.10), 5 if boss or current or selected else 3, 10)
	var pressed := _lobby_button_box(background.darkened(0.10), border, 4, 4)
	var disabled := _lobby_button_box(Color(0.045, 0.055, 0.07, 0.90), Color(0.24, 0.27, 0.31, 0.74), 3, 2)
	button.add_theme_stylebox_override("normal", normal); button.add_theme_stylebox_override("hover", hover); button.add_theme_stylebox_override("pressed", pressed); button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color("f3f6f8")); button.add_theme_color_override("font_disabled_color", Color("8a929c"))

func _style_button(button: Button) -> void:
	var normal := _lobby_button_box(Color(0.14, 0.14, 0.22, 0.92), Color(0.55, 0.55, 0.75, 0.75), 2, 7)
	var hover := _lobby_button_box(Color(0.22, 0.22, 0.35, 0.95), Color(0.65, 0.65, 0.88, 0.85), 2, 7)
	var pressed := _lobby_button_box(Color(0.08, 0.08, 0.16, 0.95), Color(0.45, 0.45, 0.65, 0.70), 2, 3)
	var disabled := _lobby_button_box(Color(0.10, 0.10, 0.16, 0.88), Color(0.38, 0.38, 0.54, 0.68), 2, 3)
	button.add_theme_stylebox_override("normal", normal); button.add_theme_stylebox_override("hover", hover); button.add_theme_stylebox_override("pressed", pressed); button.add_theme_stylebox_override("disabled", disabled); button.add_theme_color_override("font_color", Color(0.90, 0.90, 1.0)); button.add_theme_color_override("font_disabled_color", Color(0.52, 0.52, 0.64)); button.focus_mode = Control.FOCUS_NONE

func _lobby_button_box(background: Color, border: Color, width: int, shadow: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = background; style.border_color = border; style.set_border_width_all(width); style.corner_radius_top_left = 28; style.corner_radius_top_right = 28; style.corner_radius_bottom_left = 28; style.corner_radius_bottom_right = 28; style.shadow_color = Color(0, 0, 0, 0.38); style.shadow_size = shadow; style.shadow_offset = Vector2(0, 3); return style
