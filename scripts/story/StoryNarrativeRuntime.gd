class_name StoryNarrativeRuntime
extends CanvasLayer

const StoryNarrativeClass := preload("res://scripts/story/StoryNarrative.gd")
const MAX_QUEUE: int = 4

var _stage_id: String = ""
var _enabled: bool = false
var _clock: float = 0.0
var _remaining: float = 0.0
var _queue: Array[Dictionary] = []
var _seen: Dictionary = {}
var _active: Dictionary = {}
var _combat_suppressed: bool = false
var _panel: Button
var _speaker_label: Label
var _line_label: Label

func _ready() -> void:
	layer = 44
	add_to_group("accessibility_settings")
	_build_ui()
	apply_accessibility_settings(SettingsStore.load_all())

func configure(stage_id: String, enabled: bool = true) -> void:
	_stage_id = stage_id
	_enabled = enabled and StoryNarrativeClass.STAGES.has(stage_id)
	reset_attempt()

func reset_attempt() -> void:
	_clock = 0.0
	_remaining = 0.0
	_queue.clear()
	_seen.clear()
	_active.clear()
	if _panel != null:
		_panel.visible = false

func trigger_intro(minimum_priority: int = StoryNarrativeClass.PRIORITY_FLAVOUR) -> bool:
	var intro := StoryNarrativeClass.intro(_stage_id)
	return trigger(str(intro.get("id", "")), minimum_priority)

func trigger(event_id: String, minimum_priority: int = StoryNarrativeClass.PRIORITY_FLAVOUR) -> bool:
	if not _enabled or event_id.is_empty() or _seen.has(event_id):
		return false
	var item := StoryNarrativeClass.event(_stage_id, event_id)
	if item.is_empty():
		return false
	_seen[event_id] = true
	if int(item.get("priority", 1)) < minimum_priority:
		return false
	item["queued_at"] = _clock
	if _active.is_empty():
		_show_item(item)
		return true
	if int(item.get("priority", 1)) > int(_active.get("priority", 1)):
		_show_item(item)
		return true
	_queue.append(item)
	_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var priority_a := int(a.get("priority", 1)); var priority_b := int(b.get("priority", 1))
		return priority_a > priority_b if priority_a != priority_b else float(a.get("queued_at", 0.0)) < float(b.get("queued_at", 0.0))
	)
	while _queue.size() > MAX_QUEUE:
		_queue.pop_back()
	return item in _queue

func advance(delta: float) -> void:
	if not _enabled:
		return
	_clock += maxf(delta, 0.0)
	if _active.is_empty():
		_show_next()
		return
	_remaining -= maxf(delta, 0.0)
	if _remaining <= 0.0:
		dismiss()

func dismiss() -> void:
	_active.clear()
	_remaining = 0.0
	if _panel != null:
		_panel.visible = false
	_show_next()

func shutdown() -> void:
	_enabled = false
	_queue.clear()
	_active.clear()
	_remaining = 0.0
	if _panel != null:
		_panel.visible = false

func set_combat_suppressed(value: bool) -> void:
	if _combat_suppressed == value:
		return
	_combat_suppressed = value
	if _panel != null and _panel.visible:
		_panel.modulate.a = 0.32 if _combat_suppressed else 1.0

func apply_accessibility_settings(settings: Dictionary) -> void:
	if _panel == null:
		return
	var ui_scale := float(settings.get("ui_scale", 1.0))
	var text_scale := float(settings.get("objective_text_scale", 1.0))
	var combined := clampf(ui_scale * text_scale, 0.8, 1.44)
	var view := get_viewport().get_visible_rect().size
	var safe := SettingsStore.safe_area(view)
	var panel_height := 148.0 * combined
	_panel.position = Vector2(60.0, maxf(424.0 + safe.position.y, view.y * 0.22))
	_panel.size = Vector2(view.x - 120.0, panel_height)
	_speaker_label.position = Vector2(24.0, 10.0 * combined)
	_speaker_label.size = Vector2(_panel.size.x - 48.0, 32.0 * combined)
	_speaker_label.add_theme_font_size_override("font_size", roundi(21.0 * combined))
	_line_label.position = Vector2(24.0, 40.0 * combined)
	_line_label.size = Vector2(_panel.size.x - 48.0, 92.0 * combined)
	_line_label.add_theme_font_size_override("font_size", roundi(27.0 * combined))

func queue_size() -> int:
	return _queue.size()

func active_event_id() -> String:
	return str(_active.get("id", ""))

func has_seen(event_id: String) -> bool:
	return _seen.has(event_id)

func is_enabled() -> bool:
	return _enabled

func _show_next() -> void:
	while not _queue.is_empty():
		var item: Dictionary = _queue.pop_front() as Dictionary
		if _clock - float(item.get("queued_at", 0.0)) <= float(item.get("ttl", 4.0)):
			_show_item(item)
			return

func _show_item(item: Dictionary) -> void:
	_active = item
	_remaining = float(item.get("duration", 3.0))
	if _panel == null:
		return
	_speaker_label.text = str(item.get("speaker", "Narrator")).to_upper()
	_line_label.text = str(item.get("text", ""))
	_panel.visible = true
	var target_alpha := 0.32 if _combat_suppressed else 1.0
	_panel.modulate = Color(1.08, 1.08, 1.08, target_alpha)
	var tween := _panel.create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(_panel, "modulate", Color(1.0, 1.0, 1.0, target_alpha), 0.16)

func _build_ui() -> void:
	var view := get_viewport().get_visible_rect().size
	_panel = Button.new()
	_panel.name = "StoryNarrativePanel"
	_panel.text = ""
	_panel.position = Vector2(60.0, maxf(424.0, view.y * 0.22))
	_panel.size = Vector2(view.x - 120.0, 148.0)
	_panel.focus_mode = Control.FOCUS_NONE
	_panel.clip_contents = true
	_panel.visible = false
	_panel.pressed.connect(dismiss)
	var normal := _panel_style(Color(0.025, 0.045, 0.060, 0.95), Color(0.80, 0.66, 0.32, 0.92), 3)
	var hover := _panel_style(Color(0.040, 0.070, 0.088, 0.97), Color(0.94, 0.78, 0.38, 1.0), 3)
	var pressed := _panel_style(Color(0.018, 0.034, 0.046, 0.98), Color(0.72, 0.58, 0.28, 0.92), 2)
	_panel.add_theme_stylebox_override("normal", normal)
	_panel.add_theme_stylebox_override("hover", hover)
	_panel.add_theme_stylebox_override("pressed", pressed)
	add_child(_panel)
	_speaker_label = Label.new()
	_speaker_label.position = Vector2(24.0, 10.0)
	_speaker_label.size = Vector2(_panel.size.x - 48.0, 32.0)
	_speaker_label.add_theme_font_size_override("font_size", 21)
	_speaker_label.add_theme_color_override("font_color", Color("ffd66b"))
	_speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_speaker_label)
	_line_label = Label.new()
	_line_label.position = Vector2(24.0, 40.0)
	_line_label.size = Vector2(_panel.size.x - 48.0, 92.0)
	_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_label.max_lines_visible = 2
	_line_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_line_label.add_theme_font_size_override("font_size", 27)
	_line_label.add_theme_color_override("font_color", Color("f3f6f8"))
	_line_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_line_label)

func _panel_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0.0, 4.0)
	return style
