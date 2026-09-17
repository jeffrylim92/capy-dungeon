class_name SettingsStore
extends RefCounted

## Global game settings persisted to user://settings.json. Static helpers
## load/save the dict and apply audio + brightness overlay.

const PATH := "user://settings.json"
const DEFAULTS := {
	"sfx_volume": 80,
	"music_volume": 60,
	"brightness": 1.0,
	"frame_rate": 60,
	"muted": false,
	"show_fps": false,
	"ui_scale": 1.0,
	"objective_text_scale": 1.0,
	"hud_opacity": 1.0,
	"screen_shake": 1.0,
	"flash_intensity": 1.0,
	"effect_intensity": 1.0,
	"player_effects": "high",
	"player_outline": 1.0,
	"haptics": "light",
	"damage_numbers": "all",
	"high_contrast_telegraphs": false,
	"hazard_patterns": "standard",
	"color_independent_indicators": true,
	"touch_control_scale": 1.0,
	"touch_control_opacity": 0.7,
}

const ACCESSIBILITY_KEYS := [
	"ui_scale", "objective_text_scale", "hud_opacity", "screen_shake",
	"flash_intensity", "effect_intensity", "player_effects", "player_outline",
	"haptics", "damage_numbers", "high_contrast_telegraphs", "hazard_patterns",
	"color_independent_indicators", "touch_control_scale", "touch_control_opacity",
]

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
	return normalize(data)

static func save_all(data: Dictionary) -> void:
	var safe_data := normalize(data)
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(safe_data, "\t"))
	f.close()

static func set_value(key: String, value: Variant) -> Dictionary:
	var data := load_all()
	if not DEFAULTS.has(key):
		return data
	data[key] = value
	data = normalize(data)
	save_all(data)
	return data

static func reset_accessibility() -> Dictionary:
	var data := load_all()
	for key in ACCESSIBILITY_KEYS:
		data[key] = DEFAULTS[key]
	data = normalize(data)
	save_all(data)
	return data

## Accepts older save formats and clamps every externally persisted value.
static func normalize(source: Dictionary) -> Dictionary:
	var data: Dictionary = DEFAULTS.duplicate(true)
	for key in source:
		if data.has(key):
			data[key] = source[key]
	data["sfx_volume"] = clampi(roundi(_float_value(data["sfx_volume"], 80.0)), 0, 100)
	data["music_volume"] = clampi(roundi(_float_value(data["music_volume"], 60.0)), 0, 100)
	data["brightness"] = clampf(_float_value(data["brightness"], 1.0), 0.4, 1.0)
	data["frame_rate"] = int(_nearest(_float_value(data["frame_rate"], 60.0), [30.0, 60.0], 60.0))
	data["muted"] = _bool_value(data["muted"], false)
	data["show_fps"] = _bool_value(data["show_fps"], false)
	data["ui_scale"] = _nearest(_float_value(data["ui_scale"], 1.0), [0.8, 0.9, 1.0, 1.1, 1.2], 1.0)
	data["objective_text_scale"] = _nearest(_float_value(data["objective_text_scale"], 1.0), [0.9, 1.0, 1.1, 1.2], 1.0)
	data["hud_opacity"] = clampf(_float_value(data["hud_opacity"], 1.0), 0.8, 1.0)
	data["screen_shake"] = _shake_value(data["screen_shake"])
	data["flash_intensity"] = _shake_value(data["flash_intensity"])
	data["effect_intensity"] = clampf(_float_value(data["effect_intensity"], 1.0), 0.0, 1.0)
	data["player_effects"] = _enum_value(data["player_effects"], ["high", "medium", "low"], "high")
	data["player_outline"] = _outline_value(data["player_outline"])
	data["haptics"] = _enum_value(data["haptics"], ["strong", "light", "off"], "light")
	data["damage_numbers"] = _damage_number_value(data["damage_numbers"])
	data["high_contrast_telegraphs"] = _bool_value(data["high_contrast_telegraphs"], false)
	data["hazard_patterns"] = _enum_value(data["hazard_patterns"], ["standard", "enhanced"], "standard")
	data["color_independent_indicators"] = _bool_value(data["color_independent_indicators"], true)
	data["touch_control_scale"] = _touch_scale_value(data["touch_control_scale"])
	data["touch_control_opacity"] = clampf(_float_value(data["touch_control_opacity"], 0.7), 0.35, 1.0)
	return data

static func _float_value(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		var number := float(value)
		return fallback if is_nan(number) or is_inf(number) else number
	if value is String and str(value).is_valid_float():
		var parsed := float(value)
		return fallback if is_nan(parsed) or is_inf(parsed) else parsed
	return fallback

static func _bool_value(value: Variant, fallback: bool) -> bool:
	if value is bool:
		return bool(value)
	if value is int or value is float:
		return not is_zero_approx(float(value))
	if value is String:
		var normalized := str(value).to_lower().strip_edges()
		if normalized in ["true", "on", "yes", "1"]:
			return true
		if normalized in ["false", "off", "no", "0"]:
			return false
	return fallback

static func _shake_value(value: Variant) -> float:
	if value is String:
		var named := str(value).to_lower().replace(" ", "_")
		if named == "off": return 0.0
		if named in ["reduced", "half", "medium"]: return 0.5
		if named in ["full", "high"]: return 1.0
	return _nearest(_float_value(value, 1.0), [0.0, 0.5, 1.0], 1.0)

static func _outline_value(value: Variant) -> float:
	if value is String:
		var named := str(value).to_lower()
		if named == "off": return 0.0
		if named == "normal": return 1.0
		if named == "strong": return 1.5
	return _nearest(_float_value(value, 1.0), [0.0, 1.0, 1.5], 1.0)

static func _touch_scale_value(value: Variant) -> float:
	if value is String:
		var named := str(value).to_lower()
		if named == "small": return 0.85
		if named in ["default", "normal"]: return 1.0
		if named == "large": return 1.2
	return _nearest(_float_value(value, 1.0), [0.85, 1.0, 1.2], 1.0)

static func _nearest(value: float, choices: Array, fallback: float) -> float:
	if is_nan(value) or is_inf(value):
		return fallback
	var best := fallback
	var distance := INF
	for choice in choices:
		var candidate := float(choice)
		var candidate_distance := absf(value - candidate)
		if candidate_distance < distance:
			distance = candidate_distance
			best = candidate
	return best

static func _enum_value(value: Variant, choices: Array, fallback: String) -> String:
	var normalized := str(value).to_lower().replace(" ", "_")
	return normalized if normalized in choices else fallback

static func _damage_number_value(value: Variant) -> String:
	if value is bool:
		return "all" if bool(value) else "off"
	return _enum_value(value, ["all", "critical_only", "off"], "all")

static func apply(tree: SceneTree) -> void:
	if tree == null:
		return
	var data := load_all()
	if OS.get_name() in ["Android", "iOS"]:
		Engine.max_fps = frame_rate_cap(data)
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
		fps_label.add_theme_font_size_override("font_size", roundi(22.0 * float(data.get("ui_scale", 1.0))))
	elif fps_label != null:
		fps_label.queue_free()

	# Screens opt into this group so a setting changed inside a pause overlay can
	# update the already-running match, map, or narrative panel immediately.
	for receiver in tree.get_nodes_in_group("accessibility_settings"):
		if receiver.has_method("apply_accessibility_settings"):
			receiver.call("apply_accessibility_settings", data)

## Scales explicit font overrides and container minimum sizes without scaling
## a whole viewport or changing gameplay coordinates. Baselines are cached so
## repeated live previews never compound rounding errors.
static func apply_ui_scale(root: Node, scale_value: float) -> void:
	if root == null:
		return
	var scale := clampf(scale_value, 0.8, 1.2)
	_apply_control_scale(root, scale)

static func safe_area(viewport_size: Vector2) -> Rect2:
	var full := Rect2(Vector2.ZERO, viewport_size)
	if OS.get_name() not in ["Android", "iOS"]:
		return full
	var window_size := Vector2(DisplayServer.window_get_size())
	var safe_screen := Rect2(DisplayServer.get_display_safe_area())
	if window_size.x <= 0.0 or window_size.y <= 0.0 or safe_screen.size.x <= 0.0 or safe_screen.size.y <= 0.0:
		return full
	var ratio := Vector2(viewport_size.x / window_size.x, viewport_size.y / window_size.y)
	var converted := Rect2(safe_screen.position * ratio, safe_screen.size * ratio)
	return converted.intersection(full)

static func _apply_control_scale(node: Node, scale: float) -> void:
	if node is Control:
		var control := node as Control
		if not bool(control.get_meta("accessibility_no_scale", false)):
			if control.has_theme_font_size_override("font_size"):
				if not control.has_meta("accessibility_base_font_size"):
					control.set_meta("accessibility_base_font_size", control.get_theme_font_size("font_size"))
				var base_font := int(control.get_meta("accessibility_base_font_size"))
				control.add_theme_font_size_override("font_size", maxi(10, roundi(float(base_font) * scale)))
			if control.custom_minimum_size != Vector2.ZERO:
				if not control.has_meta("accessibility_base_minimum_size"):
					control.set_meta("accessibility_base_minimum_size", control.custom_minimum_size)
				control.custom_minimum_size = (control.get_meta("accessibility_base_minimum_size") as Vector2) * scale
			if control.has_theme_constant_override("separation"):
				if not control.has_meta("accessibility_base_separation"):
					control.set_meta("accessibility_base_separation", control.get_theme_constant("separation"))
				control.add_theme_constant_override("separation", roundi(float(control.get_meta("accessibility_base_separation")) * scale))
	for child in node.get_children():
		_apply_control_scale(child, scale)

static func _fps_script() -> GDScript:
	var src := "extends Label\nvar elapsed := 0.25\nfunc _process(delta):\n\telapsed += delta\n\tif elapsed < 0.25:\n\t\treturn\n\telapsed = 0.0\n\ttext = \"FPS %d\" % Engine.get_frames_per_second()\n"
	var gd := GDScript.new()
	gd.source_code = src
	gd.reload()
	return gd

static func frame_rate_cap(settings: Dictionary) -> int:
	return 30 if int(normalize(settings).get("frame_rate", 60)) == 30 else 60

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
