extends Node

const MIN_LABEL_SIZE: int = 26
const MIN_BUTTON_SIZE: int = 28
const MIN_INPUT_SIZE: int = 28
const MIN_RICH_TEXT_SIZE: int = 26

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_apply_subtree", get_tree().root)

func _on_node_added(node: Node) -> void:
	if node is Control:
		call_deferred("_apply_control", node as Control)
	elif node is PopupMenu:
		call_deferred("_apply_popup", node as PopupMenu)

func _apply_subtree(node: Node) -> void:
	if node is Control:
		_apply_control(node as Control)
	elif node is PopupMenu:
		_apply_popup(node as PopupMenu)
	for child: Node in node.get_children():
		_apply_subtree(child)

func _apply_control(control: Control) -> void:
	if not is_instance_valid(control) or bool(control.get_meta("allow_small_text", false)):
		return
	if control is RichTextLabel:
		_ensure_size(control, "normal_font_size", MIN_RICH_TEXT_SIZE)
		_ensure_size(control, "bold_font_size", MIN_RICH_TEXT_SIZE)
		_ensure_size(control, "italics_font_size", MIN_RICH_TEXT_SIZE)
		_ensure_size(control, "bold_italics_font_size", MIN_RICH_TEXT_SIZE)
	elif control is LineEdit or control is TextEdit or control is SpinBox:
		_ensure_size(control, "font_size", MIN_INPUT_SIZE)
	elif control is Button:
		var button: Button = control as Button
		# Several inventory cards deliberately use a one-pixel blank label because
		# their texture is the entire visual. Do not turn those into visible text.
		if button.text.strip_edges().is_empty() or button.get_theme_font_size("font_size") <= 1:
			return
		_ensure_size(button, "font_size", MIN_BUTTON_SIZE)
	elif control is Label:
		var label: Label = control as Label
		if not label.text.strip_edges().is_empty():
			_ensure_size(label, "font_size", MIN_LABEL_SIZE)
	elif control is ItemList or control is Tree:
		_ensure_size(control, "font_size", MIN_INPUT_SIZE)

func _apply_popup(popup: PopupMenu) -> void:
	if is_instance_valid(popup) and popup.get_theme_font_size("font_size") < MIN_INPUT_SIZE:
		popup.add_theme_font_size_override("font_size", MIN_INPUT_SIZE)

func _ensure_size(control: Control, theme_key: StringName, minimum: int) -> void:
	if control.get_theme_font_size(theme_key) < minimum:
		control.add_theme_font_size_override(theme_key, minimum)
