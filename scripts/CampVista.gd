class_name CampVista
extends Control

signal upgrade_selected(upgrade_id: String)
signal section_selected(section_id: String)

const BACKGROUND: Texture2D = preload("res://assets/backgrounds/bg_camp_clearing.png")
const CAMP_HEIGHT := 720.0
const CHARACTER_IDS: Array[String] = [
	"capy_zoomer", "capy_chef", "capy_swamp", "capy_brown",
	"capy_wizard", "capy_archer", "capy_assassin",
]
const CAMP_RESIDENT_TEXTURES: Dictionary = {
	"capy_wizard": preload("res://assets/camp/capy_wizard.png"),
	"capy_chef": preload("res://assets/camp/capy_chef.png"),
}
const CAMP_WALK_TEXTURES: Dictionary = {
	"capy_wizard": "res://assets/animations/characters/capy_wizard_camp_walk.png",
	"capy_chef": "res://assets/animations/characters/capy_chef_camp_walk.png",
	"capy_brown": "res://assets/animations/characters/capy_brown_camp_walk.png",
	"capy_archer": "res://assets/animations/characters/capy_archer_camp_walk.png",
	"capy_zoomer": "res://assets/animations/characters/capy_zoomer_camp_walk.png",
	"capy_swamp": "res://assets/animations/characters/capy_swamp_camp_walk.png",
	"capy_assassin": "res://assets/animations/characters/capy_assassin_camp_walk.png",
}
const BUILDING_POSITIONS: Array[Vector2] = [
	Vector2(0.03, 0.12), Vector2(0.20, 0.04), Vector2(0.43, 0.25),
	Vector2(0.67, 0.09), Vector2(0.80, 0.19),
]

var _profile: Dictionary = {}
var _username := ""
var _residents: Array[Dictionary] = []
var _saved_residents: Dictionary = {}
var _time := 0.0

func setup(profile: Dictionary, username: String, resident_state: Dictionary = {}) -> void:
	_profile = profile
	_username = username
	_saved_residents = resident_state.duplicate(true)
	custom_minimum_size = Vector2(0, CAMP_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_build_landmarks()
	_build_camp_facilities()
	_build_residents()
	queue_redraw()

func _build_landmarks() -> void:
	var index := 0
	for id_variant in ProgressionStore.UPGRADES:
		var id := String(id_variant)
		var level := ProgressionStore.upgrade_level(_profile, id)
		var definition := ProgressionStore.UPGRADES[id] as Dictionary
		var building := TextureButton.new()
		building.name = "Building_%s" % id
		building.tooltip_text = "%s\nTap to view and improve this building." % String(definition.get("desc", ""))
		var texture := load("res://assets/camp/building_%s.png" % id) as Texture2D
		building.texture_normal = texture
		building.texture_hover = texture
		building.ignore_texture_size = true
		building.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		building.texture_click_mask = _alpha_click_mask(texture)
		building.position = Vector2(BUILDING_POSITIONS[index].x * 720.0, BUILDING_POSITIONS[index].y * CAMP_HEIGHT)
		building.size = Vector2(168, 160)
		building.focus_mode = Control.FOCUS_NONE
		var captured_id := id
		building.pressed.connect(func() -> void: upgrade_selected.emit(captured_id))
		add_child(building)
		_add_building_label("Label_%s" % id, "%s  ·  Lv.%d%s\n%s" % [String(definition.get("name", id.capitalize())), level, _building_details(level), ProgressionStore.upgrade_effect_text(_profile, id)], BUILDING_POSITIONS[index], 154.0)
		_add_upgrade_decor(id, BUILDING_POSITIONS[index], level)
		index += 1

func _add_upgrade_decor(id: String, anchor: Vector2, level: int) -> void:
	if level < 4:
		return
	var decor := Label.new()
	decor.name = "Decor_%s" % id
	decor.text = "✦" if level < 8 else "✦  ✦"
	decor.position = Vector2(anchor.x * 720.0 + 104.0, anchor.y * CAMP_HEIGHT + 8.0)
	decor.size = Vector2(50, 28)
	decor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decor.add_theme_font_size_override("font_size", 22)
	decor.add_theme_color_override("font_color", Color(1.0, 0.76, 0.18))
	decor.add_theme_color_override("font_outline_color", Color(0.12, 0.05, 0.01))
	decor.add_theme_constant_override("outline_size", 4)
	decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor.set_meta("anchor", anchor)
	add_child(decor)

func _build_camp_facilities() -> void:
	_add_facility("missions", "Mission Board", Vector2(0.07, 0.62), Vector2(138, 122))
	_add_facility("difficulty", "Expedition Gate", Vector2(0.74, 0.59), Vector2(176, 132))

func _add_facility(id: String, label_text: String, anchor: Vector2, hotspot_size: Vector2) -> void:
	var hotspot := TextureButton.new()
	hotspot.name = "Facility_%s" % id
	hotspot.position = Vector2(anchor.x * 720.0, anchor.y * CAMP_HEIGHT)
	hotspot.size = hotspot_size
	hotspot.focus_mode = Control.FOCUS_NONE
	hotspot.tooltip_text = "Open %s" % label_text
	var texture := load("res://assets/camp/building_%s.png" % id) as Texture2D
	hotspot.texture_normal = texture
	hotspot.texture_hover = texture
	hotspot.ignore_texture_size = true
	hotspot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	hotspot.texture_click_mask = _alpha_click_mask(texture)
	var captured_id := id
	hotspot.pressed.connect(func() -> void: section_selected.emit(captured_id))
	hotspot.set_meta("anchor", anchor)
	add_child(hotspot)
	_add_building_label("FacilityLabel_%s" % id, label_text, anchor, hotspot_size.y - 2.0)

func _alpha_click_mask(texture: Texture2D) -> BitMap:
	var mask := BitMap.new()
	mask.create_from_image_alpha(texture.get_image(), 0.12)
	return mask

func _add_building_label(node_name: String, text: String, anchor: Vector2, y_offset: float = 84.0) -> void:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.position = Vector2(anchor.x * 720.0 - 5.0, anchor.y * CAMP_HEIGHT + y_offset)
	label.size = Vector2(195, 58)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.66))
	label.add_theme_color_override("font_outline_color", Color(0.06, 0.03, 0.01))
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_meta("anchor", anchor)
	add_child(label)

func _building_details(level: int) -> String:
	if level >= 8:
		return "  ✦✦"
	if level >= 4:
		return "  ✦"
	return ""

func _build_residents() -> void:
	var unlocked := _unlocked_characters()
	for i in unlocked.size():
		var character_id := unlocked[i]
		var texture_path := "res://assets/characters/%s.png" % character_id
		if not ResourceLoader.exists(texture_path):
			continue
		var resident_node: Node2D
		var resident_scale := 0.1
		var walk_path := String(CAMP_WALK_TEXTURES.get(character_id, "res://assets/animations/characters/%s_walk.png" % character_id))
		if ResourceLoader.exists(walk_path):
			var animated := AnimatedSprite2D.new()
			var frames := SpriteFrames.new()
			frames.add_animation("walk")
			frames.set_animation_speed("walk", 7.0)
			var sheet := load(walk_path) as Texture2D
			var frame_width := int(sheet.get_width() / 3)
			for frame_index in 3:
				var atlas := AtlasTexture.new()
				atlas.atlas = sheet
				atlas.region = Rect2(frame_index * frame_width, 0, frame_width, sheet.get_height())
				frames.add_frame("walk", atlas)
			animated.sprite_frames = frames
			animated.play("walk")
			resident_node = animated
			resident_scale = 96.0 / float(maxi(frame_width, sheet.get_height()))
		else:
			var sprite := Sprite2D.new()
			var texture := CAMP_RESIDENT_TEXTURES.get(character_id, load(texture_path)) as Texture2D
			sprite.texture = texture
			resident_node = sprite
			resident_scale = 88.0 / float(maxi(texture.get_width(), texture.get_height()))
		add_child(resident_node)
		var state: Dictionary = (_saved_residents.get(character_id, {}) as Dictionary).duplicate(true)
		_residents.append({
			"id": character_id,
			"node": resident_node, "x": 70.0 + float(i % 4) * 170.0, "lane": i % 3,
			"speed": 0.0, "target_speed": 18.0 + float(i % 3) * 5.0,
			"direction": 1.0 if i % 2 == 0 else -1.0, "pause": float(i) * 0.65,
			"base_scale": resident_scale,
		})
		var resident := _residents.back() as Dictionary
		for state_key in ["x", "lane", "speed", "target_speed", "direction", "pause"]:
			if state.has(state_key):
				resident[state_key] = state[state_key]

func resident_state() -> Dictionary:
	var out := {}
	for resident in _residents:
		var state := {}
		for key in ["x", "lane", "speed", "target_speed", "direction", "pause"]:
			state[key] = resident[key]
		out[String(resident["id"])] = state
	return out

func _process(delta: float) -> void:
	_time += delta
	var width := maxf(size.x, 720.0)
	for building_node in find_children("Building_*", "TextureButton", false, false):
		var building := building_node as TextureButton
		var building_index := -1
		# Positions are assigned by upgrade order; scale the authored 720px anchors to the live width.
		var id := String(building.name).trim_prefix("Building_")
		var ids := ProgressionStore.UPGRADES.keys()
		building_index = ids.find(id)
		if building_index >= 0:
			building.position.x = BUILDING_POSITIONS[building_index].x * width
	for positioned_node in find_children("Facility*", "Control", false, false):
		if positioned_node.has_meta("anchor"):
			var anchor := positioned_node.get_meta("anchor") as Vector2
			positioned_node.position.x = anchor.x * width
	for label_node in find_children("Label_*", "Label", false, false):
		var label_id := String(label_node.name).trim_prefix("Label_")
		var label_index := ProgressionStore.UPGRADES.keys().find(label_id)
		if label_index >= 0:
			label_node.position.x = BUILDING_POSITIONS[label_index].x * width - 5.0
	for decor_node in find_children("Decor_*", "Label", false, false):
		var anchor := decor_node.get_meta("anchor") as Vector2
		decor_node.position.x = anchor.x * width + 104.0
	for resident in _residents:
		resident["pause"] = maxf(float(resident["pause"]) - delta, 0.0)
		var target := 0.0 if float(resident["pause"]) > 0.0 else float(resident["target_speed"])
		resident["speed"] = move_toward(float(resident["speed"]), target, 30.0 * delta)
		resident["x"] = float(resident["x"]) + float(resident["speed"]) * float(resident["direction"]) * delta
		if float(resident["x"]) > width - 78.0:
			resident["x"] = width - 78.0
			resident["direction"] = -1.0
			resident["pause"] = randf_range(0.8, 2.2)
		elif float(resident["x"]) < 12.0:
			resident["x"] = 12.0
			resident["direction"] = 1.0
			resident["pause"] = randf_range(0.8, 2.2)
		elif float(resident["pause"]) <= 0.0 and randf() < delta * 0.035:
			resident["pause"] = randf_range(0.7, 2.5)
		var node := resident["node"] as Node2D
		var lane := int(resident["lane"])
		var depth_scale := float(resident["base_scale"]) * (0.90 + float(lane) * 0.10)
		node.position = Vector2(float(resident["x"]), 520.0 + float(lane) * 32.0)
		node.scale = Vector2(-depth_scale if float(resident["direction"]) < 0.0 else depth_scale, depth_scale)
		if node is AnimatedSprite2D:
			(node as AnimatedSprite2D).speed_scale = clampf(float(resident["speed"]) / 18.0, 0.0, 1.4)
	queue_redraw()

func _draw() -> void:
	var width := maxf(size.x, 720.0)
	draw_texture_rect(BACKGROUND, Rect2(0, 0, width, CAMP_HEIGHT), false)
	# Warm vignette keeps dynamic landmarks grounded in the painted scene.
	draw_rect(Rect2(0, 0, width, CAMP_HEIGHT), Color(0.08, 0.025, 0.02, 0.10))
	var level := ProgressionStore.account_level(_profile)
	var building_index := 0
	for id_variant in ProgressionStore.UPGRADES:
		var upgrade_level := ProgressionStore.upgrade_level(_profile, String(id_variant))
		_draw_building_details(BUILDING_POSITIONS[building_index], upgrade_level, width)
		building_index += 1
	if level >= 7:
		for i in 12:
			var firefly := Vector2(fmod(float(i * 131) + _time * 6.0, width), 310.0 + fmod(float(i * 37), 230.0))
			draw_circle(firefly, 2.5, Color(1.0, 0.78, 0.20, 0.42 + sin(_time * 3.0 + i) * 0.24))
	if level >= 10:
		var trophy_pos := Vector2(width * 0.5, 450)
		draw_circle(trophy_pos, 30.0, Color(1.0, 0.70, 0.10, 0.16))
		draw_string(ThemeDB.fallback_font, trophy_pos + Vector2(-17, 13), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color(1.0, 0.78, 0.20))

func _draw_building_details(anchor: Vector2, level: int, width: float) -> void:
	if level <= 0:
		return
	var origin := Vector2(anchor.x * width + 88.0, anchor.y * CAMP_HEIGHT + 8.0)
	# Every level adds another warm lantern around the structure.
	var lantern_count := mini(level, 5)
	for i in lantern_count:
		var angle := PI + (float(i) / maxf(float(lantern_count - 1), 1.0)) * PI
		var light_pos := origin + Vector2(cos(angle), sin(angle)) * Vector2(54.0, 24.0)
		draw_circle(light_pos, 8.0, Color(1.0, 0.54, 0.12, 0.14))
		draw_circle(light_pos, 3.0, Color(1.0, 0.80, 0.30, 0.95))
	# Mid and high tiers gain permanent banners and a golden roof crest.
	if level >= 4:
		draw_line(origin + Vector2(-48, -4), origin + Vector2(-48, -30), Color(0.30, 0.18, 0.08), 3.0)
		draw_colored_polygon(PackedVector2Array([origin + Vector2(-47, -29), origin + Vector2(-25, -24), origin + Vector2(-47, -16)]), Color(0.72, 0.20, 0.16))
	if level >= 8:
		draw_circle(origin + Vector2(0, -30), 10.0, Color(1.0, 0.67, 0.12, 0.20))
		draw_string(ThemeDB.fallback_font, origin + Vector2(-7, -24), "✦", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.80, 0.24))

func _unlocked_characters() -> Array[String]:
	var out: Array[String] = []
	for id in CHARACTER_IDS:
		if PurchaseStore.PURCHASABLE.has(id) and not PurchaseStore.is_purchased(id):
			continue
		if id == "capy_brown" and not StatsStore.is_brown_unlocked(_username):
			continue
		out.append(id)
	return out
