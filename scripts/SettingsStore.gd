class_name SettingsStore
extends RefCounted

## Global game settings persisted to user://settings.json. Static helpers
## load/save the dict and apply audio + brightness overlay.

const PATH := "user://settings.json"
const DEFAULTS := {
	"sfx_volume": 80,
	"music_volume": 60,
	"brightness": 1.0,
	"muted": false,
	"show_fps": false,
}

const OVERLAY_NAME := "_SettingsOverlay"
const FPS_LABEL_NAME := "_FpsLabel"
const BRIGHTNESS_RECT_NAME := "_BrightnessRect"

static func load_all() -> Dictionary:
	var data: Dictionary = DEFAULTS.duplicate(true)
	if not FileAccess.file_exists(PATH):
		return data
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return data
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		for k in (parsed as Dictionary):
			if data.has(k):
				data[k] = parsed[k]
	return data

static func save_all(data: Dictionary) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

static func set_value(key: String, value: Variant) -> Dictionary:
	var data := load_all()
	data[key] = value
	save_all(data)
	return data

static func apply(tree: SceneTree) -> void:
	if tree == null:
		return
	var data := load_all()
	_ensure_audio_bus("Music")
	_ensure_audio_bus("SFX")
	# Audio: mute all from Master, but keep Music and SFX sliders independent.
	var muted: bool = bool(data.get("muted", false))
	var sfx: float = float(data.get("sfx_volume", 80))
	var music: float = float(data.get("music_volume", 60))
	AudioServer.set_bus_volume_db(0, 0.0)
	AudioServer.set_bus_mute(0, muted)
	_set_audio_bus_volume("Music", music)
	_set_audio_bus_volume("SFX", sfx)
	# Brightness overlay + optional FPS label, owned by an autorestoring
	# CanvasLayer under the scene tree root so they survive scene swaps.
	var root := tree.root
	var layer: CanvasLayer = root.get_node_or_null(OVERLAY_NAME)
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = OVERLAY_NAME
		layer.layer = 100
		root.add_child(layer)
	var rect: ColorRect = layer.get_node_or_null(BRIGHTNESS_RECT_NAME)
	if rect == null:
		rect = ColorRect.new()
		rect.name = BRIGHTNESS_RECT_NAME
		rect.color = Color(0, 0, 0, 0)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		layer.add_child(rect)
	var brightness: float = clamp(float(data.get("brightness", 1.0)), 0.4, 1.0)
	rect.color = Color(0, 0, 0, 1.0 - brightness)

	var fps_label: Label = layer.get_node_or_null(FPS_LABEL_NAME)
	var show_fps: bool = bool(data.get("show_fps", false))
	if show_fps:
		if fps_label == null:
			fps_label = Label.new()
			fps_label.name = FPS_LABEL_NAME
			fps_label.add_theme_font_size_override("font_size", 22)
			fps_label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.6))
			fps_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
			fps_label.add_theme_constant_override("outline_size", 4)
			fps_label.position = Vector2(20, 20)
			fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fps_label.set_script(_fps_script())
			layer.add_child(fps_label)
	elif fps_label != null:
		fps_label.queue_free()

static func _fps_script() -> GDScript:
	var src := "extends Label\nfunc _process(_d):\n\ttext = \"FPS %d\" % Engine.get_frames_per_second()\n"
	var gd := GDScript.new()
	gd.source_code = src
	gd.reload()
	return gd

static func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

static func _set_audio_bus_volume(bus_name: String, value: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var normalized: float = clamp(value / 100.0, 0.0, 1.0)
	AudioServer.set_bus_volume_db(idx, -80.0 if normalized <= 0.001 else linear_to_db(normalized))
