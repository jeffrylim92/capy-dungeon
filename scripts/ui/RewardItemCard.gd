class_name RewardItemCard
extends Button

const RewardPresentationClass := preload("res://scripts/ui/RewardPresentation.gd")
const InventoryCardStyleClass := preload("res://scripts/ui/InventoryCardStyle.gd")

var item_type: String = "ring"
var item_data: Dictionary = {}
var state_flags: Dictionary = {}
var item_count: int = 1
var merge_count: int = 0
var compact: bool = false
var show_effects: bool = true
var style_variant: String = "reward"
var _reveal_tween: Tween = null

func configure(
	type_id: String,
	data: Dictionary,
	flags: Dictionary = {},
	count: int = 1,
	merge_progress_count: int = 0,
	is_compact: bool = false,
	display_effects: bool = true,
	presentation_style: String = "reward"
) -> void:
	item_type = type_id
	item_data = data.duplicate(true)
	state_flags = flags.duplicate(true)
	item_count = maxi(count, 1)
	merge_count = maxi(merge_progress_count, 0)
	compact = is_compact
	show_effects = display_effects
	style_variant = presentation_style
	_build()

func _build() -> void:
	for child in get_children():
		child.queue_free()
	text = ""
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	focus_mode = Control.FOCUS_NONE
	clip_text = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var story_style := style_variant == "story_loadout"
	var equipped_slot := bool(state_flags.get("equipped_slot", false))
	var empty_state := bool(state_flags.get("empty", false))
	custom_minimum_size = Vector2(0.0, 300.0 if equipped_slot else (350.0 if story_style else (360.0 if compact else 330.0)))
	_apply_frame()
	if story_style and not equipped_slot:
		_build_story_stash_card()
		return

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 10.0 if story_style else 14.0
	margin.offset_top = 8.0 if story_style else 12.0
	margin.offset_right = -10.0 if story_style else -14.0
	margin.offset_bottom = -8.0 if story_style else -12.0
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 3 if story_style else (3 if compact else 8))
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(root)

	var top := HBoxContainer.new()
	top.name = "CardHeader"
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var rarity := RewardPresentationClass.normalize_rarity(item_data.get("rarity", "common"))
	var rarity_label := Label.new()
	rarity_label.name = "CardRarity"
	if empty_state:
		rarity_label.text = "%s SLOT" % item_type.to_upper()
	elif item_type in ["currency", "material"]:
		rarity_label.text = "REWARD"
	elif story_style and equipped_slot:
		rarity_label.text = rarity.to_upper()
	else:
		rarity_label.text = RewardPresentationClass.rarity_label(rarity) if story_style or not compact else rarity.to_upper()
	rarity_label.add_theme_font_size_override("font_size", 16 if equipped_slot else (24 if story_style else (18 if compact else 23)))
	rarity_label.add_theme_color_override("font_color", InventoryCardStyleClass.CARD_TEXT if empty_state else RewardPresentationClass.rarity_color(rarity))
	rarity_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(rarity_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	if item_count > 1:
		var count_badge := Label.new()
		count_badge.name = "CardQuantity"
		count_badge.text = "×%d" % item_count
		count_badge.add_theme_font_size_override("font_size", 24 if story_style else (22 if compact else 26))
		count_badge.add_theme_color_override("font_color", Color("fff0b3"))
		top.add_child(count_badge)

	var icon_texture := _resolve_icon()
	if icon_texture != null:
		var icon := TextureRect.new()
		icon.name = "CardArtwork"
		icon.texture = icon_texture
		icon.custom_minimum_size = Vector2(0.0, 88.0 if equipped_slot else (120.0 if story_style else (76.0 if compact else 154.0)))
		icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(icon)
	else:
		var fallback := Label.new()
		fallback.name = "CardArtworkFallback"
		fallback.text = "+" if empty_state else "?"
		fallback.custom_minimum_size = Vector2(0.0, 88.0 if equipped_slot else (120.0 if story_style else (76.0 if compact else 154.0)))
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 42)
		fallback.add_theme_color_override("font_color", Color("b9c3c8"))
		root.add_child(fallback)

	var name_label := Label.new()
	name_label.name = "CardItemName"
	name_label.text = RewardPresentationClass.item_name(item_data, item_type)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.custom_minimum_size = Vector2(0.0, 50.0 if equipped_slot else (52.0 if story_style else (44.0 if compact else 70.0)))
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18 if equipped_slot else (19 if story_style else (19 if compact else 29)))
	name_label.add_theme_color_override("font_color", InventoryCardStyleClass.CARD_TEXT if empty_state else Color("fff4d6"))
	root.add_child(name_label)

	var tier := int(item_data.get("tier", 0))
	if tier > 0 or story_style:
		var tier_label := Label.new()
		tier_label.name = "CardTier"
		tier_label.text = "T%d" % tier if tier > 0 else " "
		tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tier_label.custom_minimum_size = Vector2(0.0, 28.0)
		tier_label.add_theme_font_size_override("font_size", 18 if equipped_slot else (20 if story_style else (18 if compact else 22)))
		tier_label.add_theme_color_override("font_color", RewardPresentationClass.rarity_color(rarity))
		root.add_child(tier_label)

	if show_effects:
		for effect_text in RewardPresentationClass.item_effect_lines(item_type, item_data, 1 if compact else 2):
			var effect := Label.new()
			effect.text = effect_text
			effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			effect.max_lines_visible = 2
			effect.add_theme_font_size_override("font_size", 18 if compact else 23)
			effect.add_theme_color_override("font_color", Color("d8e8e6"))
			root.add_child(effect)

	var badge_texts: Array[String] = []
	if bool(state_flags.get("new", false)): badge_texts.append("NEW")
	if bool(state_flags.get("duplicate", false)): badge_texts.append("DUPLICATE")
	if bool(state_flags.get("merge_ready", false)): badge_texts.append("⇧ MERGE READY")
	if bool(state_flags.get("equipped", false)): badge_texts.append("✓ EQUIPPED")
	if bool(state_flags.get("first_clear", false)): badge_texts.append("★ FIRST CLEAR")
	if compact:
		var badge := Label.new()
		badge.name = "CardStatus"
		if story_style:
			if empty_state:
				badge.text = "TAP STASH TO EQUIP"
			elif bool(state_flags.get("equipped", false)):
				badge.text = "✓ EQUIPPED"
			elif bool(state_flags.get("merge_ready", false)):
				badge.text = "⇧ MERGE READY"
			else:
				badge.text = " "
		else:
			badge.text = "  ·  ".join(badge_texts) if not badge_texts.is_empty() else " "
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		badge.max_lines_visible = 2
		badge.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		badge.custom_minimum_size = Vector2(0.0, 32.0)
		badge.add_theme_font_size_override("font_size", 15 if equipped_slot else (17 if story_style else 16))
		var highlighted_status := story_style and not badge.text.strip_edges().is_empty()
		badge.add_theme_color_override("font_color", Color(0.05, 0.03, 0.0) if highlighted_status else (Color("9ff0ac") if not bool(state_flags.get("duplicate", false)) else Color("ffd18a")))
		if highlighted_status:
			badge.add_theme_stylebox_override("normal", InventoryCardStyleClass.badge_style())
		root.add_child(badge)
		if not equipped_slot:
			var progress := Label.new()
			progress.name = "CardMergeProgress"
			progress.text = RewardPresentationClass.merge_progress(merge_count) if item_type == "ring" and (story_style or bool(state_flags.get("duplicate", false)) or merge_count > 0) else " "
			progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			progress.custom_minimum_size = Vector2(0.0, 22.0 if story_style else 18.0)
			progress.add_theme_font_size_override("font_size", 18 if story_style else 16)
			progress.add_theme_color_override("font_color", Color("ffd66b") if story_style else Color("acd5ff"))
			root.add_child(progress)
	else:
		if not badge_texts.is_empty():
			var badge := Label.new()
			badge.text = "  ·  ".join(badge_texts)
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			badge.add_theme_font_size_override("font_size", 21)
			badge.add_theme_color_override("font_color", Color("9ff0ac") if not bool(state_flags.get("duplicate", false)) else Color("ffd18a"))
			root.add_child(badge)
		if item_type == "ring" and (bool(state_flags.get("duplicate", false)) or merge_count > 0):
			var progress := Label.new()
			progress.text = RewardPresentationClass.merge_progress(merge_count)
			progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			progress.add_theme_font_size_override("font_size", 20)
			progress.add_theme_color_override("font_color", Color("acd5ff"))
			root.add_child(progress)

func _build_story_stash_card() -> void:
	var rarity := RewardPresentationClass.normalize_rarity(item_data.get("rarity", "common"))
	var tier := int(item_data.get("tier", 0))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 10.0
	margin.offset_top = 8.0
	margin.offset_right = -10.0
	margin.offset_bottom = -8.0
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 3)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.name = "CardHeader"
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(header)

	var tier_label := Label.new()
	tier_label.name = "CardTier"
	tier_label.text = "T%d" % tier if tier > 0 else ""
	tier_label.add_theme_font_size_override("font_size", 24)
	tier_label.add_theme_color_override("font_color", Color("ffde93"))
	header.add_child(tier_label)

	var separator := Label.new()
	separator.text = "  ·  " if tier > 0 else ""
	separator.add_theme_font_size_override("font_size", 24)
	separator.add_theme_color_override("font_color", Color("ffde93"))
	header.add_child(separator)

	var name_label := Label.new()
	name_label.name = "CardItemName"
	name_label.text = RewardPresentationClass.item_name(item_data, item_type)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color("ffde93"))
	header.add_child(name_label)

	if item_count > 1:
		var count_badge := Label.new()
		count_badge.name = "CardQuantity"
		count_badge.text = "×%d" % item_count
		count_badge.add_theme_font_size_override("font_size", 22)
		count_badge.add_theme_color_override("font_color", Color("fff0b3"))
		header.add_child(count_badge)

	var icon_texture := _resolve_icon()
	if icon_texture != null:
		var icon := TextureRect.new()
		icon.name = "CardArtwork"
		icon.texture = icon_texture
		icon.custom_minimum_size = Vector2(0.0, 185.0)
		icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(icon)
	else:
		var fallback := Label.new()
		fallback.name = "CardArtworkFallback"
		fallback.text = "?"
		fallback.custom_minimum_size = Vector2(0.0, 185.0)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 42)
		fallback.add_theme_color_override("font_color", Color("b9c3c8"))
		root.add_child(fallback)

	var status := Label.new()
	status.name = "CardStatus"
	status.text = "⇧ MERGE READY" if bool(state_flags.get("merge_ready", false)) else ""
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	status.custom_minimum_size = Vector2(0.0, 28.0)
	status.add_theme_font_size_override("font_size", 15)
	status.add_theme_color_override("font_color", Color(0.05, 0.03, 0.0))
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not status.text.is_empty():
		status.add_theme_stylebox_override("normal", InventoryCardStyleClass.badge_style())
	root.add_child(status)

	var type_label := Label.new()
	type_label.name = "CardItemType"
	type_label.text = "%s · %s" % [item_type.capitalize(), rarity.capitalize()]
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 24)
	type_label.add_theme_color_override("font_color", InventoryCardStyleClass.CARD_TEXT)
	root.add_child(type_label)

	if item_type == "ring":
		var progress := Label.new()
		progress.name = "CardMergeProgress"
		progress.text = RewardPresentationClass.merge_progress(merge_count)
		progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		progress.custom_minimum_size = Vector2(0.0, 22.0)
		progress.add_theme_font_size_override("font_size", 18)
		progress.add_theme_color_override("font_color", Color("ffd66b"))
		root.add_child(progress)

func play_reveal(settings: Dictionary = {}, importance: String = "useful") -> void:
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
	var quality := str(settings.get("player_effects", "high")).to_lower()
	var duration := 0.12 if quality == "low" else (0.22 if importance == "routine" else 0.34)
	modulate.a = 0.0
	if quality != "low":
		scale = Vector2(0.97, 0.97)
	_reveal_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_reveal_tween.tween_property(self, "modulate:a", 1.0, duration)
	if quality != "low":
		_reveal_tween.tween_property(self, "scale", Vector2.ONE, duration)

func stop_reveal() -> void:
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
	_reveal_tween = null
	modulate.a = 1.0
	scale = Vector2.ONE

func _resolve_icon() -> Texture2D:
	var explicit := str(item_data.get("icon", ""))
	if not explicit.is_empty():
		return RewardPresentationClass.cached_icon(explicit)
	if item_type == "ring":
		return RingStore.ring_icon(item_data)
	if item_type == "artifact":
		return ArtifactStore.artifact_icon(item_data)
	return null

func _apply_frame() -> void:
	if style_variant == "story_loadout":
		InventoryCardStyleClass.apply_card(self)
		return
	var rarity := RewardPresentationClass.normalize_rarity(item_data.get("rarity", "common"))
	var color := RewardPresentationClass.rarity_color(rarity)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.055, 0.06, 0.085, 0.98).lerp(color, 0.08)
	normal.border_color = color
	normal.set_border_width_all(RewardPresentationClass.frame_border_width(rarity))
	var radius := RewardPresentationClass.frame_corner_radius(rarity, item_type)
	normal.corner_radius_top_left = radius
	normal.corner_radius_top_right = radius
	normal.corner_radius_bottom_left = radius
	normal.corner_radius_bottom_right = radius
	normal.content_margin_left = 0.0
	normal.content_margin_top = 0.0
	normal.content_margin_right = 0.0
	normal.content_margin_bottom = 0.0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.09)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.08)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed)
	add_theme_stylebox_override("focus", hover)

func _exit_tree() -> void:
	stop_reveal()
