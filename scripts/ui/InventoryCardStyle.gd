class_name InventoryCardStyle
extends RefCounted

const CARD_BACKGROUND := Color(0.035, 0.04, 0.07, 0.98)
const CARD_HOVER_BACKGROUND := Color(0.08, 0.09, 0.14, 1.0)
const CARD_BORDER := Color(0.92, 0.67, 0.18)
const CARD_TEXT := Color(0.94, 0.85, 0.68)

static func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.06, 0.08, 0.98)
	style.border_color = Color(0.86, 0.66, 0.22)
	style.set_border_width_all(3)
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	return style

static func card_style(hovered: bool = false) -> StyleBoxFlat:
	var style := panel_style()
	style.bg_color = CARD_HOVER_BACKGROUND if hovered else CARD_BACKGROUND
	style.border_color = CARD_BORDER
	style.set_border_width_all(3)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

static func apply_card(button: Button) -> void:
	var normal := card_style()
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", card_style(true))
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_stylebox_override("focus", card_style(true))
	button.add_theme_color_override("font_color", CARD_TEXT)

static func badge_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.76, 0.18)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style

static func apply_button(button: Button, primary: bool = false) -> void:
	var normal := button_box(
		Color(0.98, 0.72, 0.08) if primary else Color(0.14, 0.14, 0.22, 0.92),
		Color(0.72, 0.42, 0.0) if primary else Color(0.55, 0.55, 0.75, 0.75),
		3 if primary else 2,
		12 if primary else 7
	)
	var hover := button_box(
		Color(1.0, 0.82, 0.25) if primary else Color(0.22, 0.22, 0.35, 0.95),
		Color(0.72, 0.42, 0.0) if primary else Color(0.65, 0.65, 0.88, 0.85),
		3 if primary else 2,
		12 if primary else 7
	)
	var pressed := button_box(
		Color(0.80, 0.56, 0.03) if primary else Color(0.08, 0.08, 0.16, 0.95),
		Color(0.58, 0.32, 0.0) if primary else Color(0.45, 0.45, 0.65, 0.70),
		3 if primary else 2,
		5 if primary else 3
	)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(0.10, 0.05, 0.0) if primary else Color(0.90, 0.90, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.10, 0.05, 0.0) if primary else Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color(0.10, 0.05, 0.0) if primary else Color(0.82, 0.82, 0.96))
	button.focus_mode = Control.FOCUS_NONE

static func button_box(background: Color, border: Color, width: int, shadow: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = shadow
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 14
	style.content_margin_right = 14
	return style
