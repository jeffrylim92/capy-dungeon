extends Node2D

## Local login / registration screen. Emits logged_in(account) when the user
## either signs in successfully or creates a new account.

signal logged_in(account: Dictionary)

enum Mode { LOGIN, REGISTER }

const REMEMBER_PATH := "user://remember.json"
const PORTRAIT_DIR := "res://assets/characters/"
const PORTRAIT_EXTS: Array[String] = [".png", ".webp", ".jpg", ".svg"]

var _mode: int = Mode.LOGIN

var _root: Control
var _title: Label
var _subtitle: Label

# Mode toggle button (single Sign-up / Sign-in toggle).
var _btn_new: Button

# Form fields.
var _username: LineEdit
var _password: LineEdit
var _confirm: LineEdit
var _display_name: LineEdit
var _fav_cards: Array[Button] = []
var _fav_selected_idx: int = -1

var _confirm_row: Control
var _display_row: Control
var _favorite_row: Control
var _remember_check: CheckBox

var _submit: Button
var _status: Label

var _characters: Array[CharacterData] = []
# Snapshot of the login form taken just before entering REGISTER mode so
# the user gets their previous credentials back if they tap "← Sign in".
var _remembered_login: Dictionary = {}

var _social_auth: SocialAuth = null

func _ready() -> void:
	_characters = CharacterLoader.load_all()
	_build_ui()
	_apply_mode()
	_load_remember()

func _build_ui() -> void:
	var view := get_viewport_rect().size

	var bg := TextureRect.new()
	var bg_tex := load("res://assets/backgrounds/bg_login.png") as Texture2D
	if bg_tex:
		bg.texture = bg_tex
	else:
		bg.set_script(null)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = view
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Explicit size: parent is Node2D so anchors alone don't resolve without a Control parent
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

	# PanelContainer auto-sizes to its content — no fixed height needed
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
	inner.add_theme_constant_override("margin_left", 36)
	inner.add_theme_constant_override("margin_right", 36)
	inner.add_theme_constant_override("margin_top", 32)
	inner.add_theme_constant_override("margin_bottom", 32)
	card.add_child(inner)

	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 14)
	inner.add_child(_root)

	_title = Label.new()
	_title.text = "Capy Dungeon"
	_title.add_theme_font_size_override("font_size", 64)
	_title.add_theme_color_override("font_color", Color(0.35, 0.18, 0.08))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_title)

	_subtitle = Label.new()
	_subtitle.text = "Sign in to play"
	_subtitle.add_theme_font_size_override("font_size", 26)
	_subtitle.add_theme_color_override("font_color", Color(0.45, 0.3, 0.18))
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_subtitle)

	# Form.
	_username = _make_input("Username")
	_root.add_child(_make_labeled_row("Username", _username))

	_display_row = _make_labeled_row("Display name", _make_display_input())
	_root.add_child(_display_row)

	_password = _make_input("Password", true)
	_root.add_child(_make_labeled_row("Password", _password))

	_confirm = _make_input("Confirm password", true)
	_confirm_row = _make_labeled_row("Confirm password", _confirm)
	_root.add_child(_confirm_row)

	if _characters.is_empty():
		var empty_fav := Label.new()
		empty_fav.text = "(no characters found)"
		empty_fav.add_theme_font_size_override("font_size", 22)
		_favorite_row = _make_labeled_row("Favorite capybara", empty_fav)
	else:
		_favorite_row = _make_labeled_row("Favorite capybara", _build_fav_picker())
	_root.add_child(_favorite_row)

	_remember_check = CheckBox.new()
	_remember_check.text = "Remember me on this device"
	_remember_check.add_theme_font_size_override("font_size", 22)
	# AA-compliant: ~11:1 contrast against the parchment background.
	# All interactive states must be set explicitly; Godot's default theme uses
	# near-white for hover/pressed which is unreadable on a light background.
	var _cb_ink := Color(0.15, 0.08, 0.02)
	_remember_check.add_theme_color_override("font_color", _cb_ink)
	_remember_check.add_theme_color_override("font_hover_color", _cb_ink)
	_remember_check.add_theme_color_override("font_pressed_color", _cb_ink)
	_remember_check.add_theme_color_override("font_hover_pressed_color", _cb_ink)
	_remember_check.add_theme_color_override("font_focus_color", _cb_ink)
	_root.add_child(_remember_check)

	# ── Action buttons row: [Log In] [Sign Up] ───────────────────────────────
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	_root.add_child(btn_row)

	_submit = Button.new()
	_submit.text = "Log In"
	_submit.custom_minimum_size = Vector2(0, 88)
	_submit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_submit.add_theme_font_size_override("font_size", 34)
	_style_primary(_submit)
	_submit.pressed.connect(_on_submit)
	btn_row.add_child(_submit)

	_btn_new = Button.new()
	_btn_new.text = "Sign Up"
	_btn_new.custom_minimum_size = Vector2(0, 88)
	_btn_new.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_new.add_theme_font_size_override("font_size", 34)
	_style_secondary(_btn_new)
	_btn_new.pressed.connect(_on_mode_toggle)
	btn_row.add_child(_btn_new)

	# ── Social buttons row: [Google] [Facebook] ───────────────────────────────
	_build_social_section()

	_status = Label.new()
	_status.text = ""
	_status.add_theme_font_size_override("font_size", 22)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(0, 60)
	_root.add_child(_status)

func _make_input(placeholder: String, is_secret: bool = false) -> LineEdit:
	var le := LineEdit.new()
	le.placeholder_text = placeholder
	le.secret = is_secret
	le.add_theme_font_size_override("font_size", 28)
	le.custom_minimum_size = Vector2(0, 64)
	return le

# ── Social login ─────────────────────────────────────────────────────────────

# Metadata for each provider: label, background colour, text colour
const SOCIAL_META: Dictionary = {
	"google":   {"label": "Continue with Google",   "bg": Color(1.00, 1.00, 1.00), "fg": Color(0.13, 0.13, 0.13), "border": Color(0.75, 0.75, 0.75)},
	"facebook": {"label": "Continue with Facebook", "bg": Color(0.23, 0.35, 0.60), "fg": Color(1.00, 1.00, 1.00), "border": Color(0.20, 0.30, 0.55)},
}

var _social_section: Control = null

func _build_social_section() -> void:
	var providers := SocialAuth.get_available_providers()
	if providers.is_empty():
		return

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	for p in providers:
		if not SOCIAL_META.has(p):
			continue
		var meta: Dictionary = SOCIAL_META[p] as Dictionary
		var btn := _make_social_button(p, meta)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(btn)

	_root.add_child(row)
	_social_section = row

	_social_auth = SocialAuth.new()
	_social_auth.name = "SocialAuth"
	add_child(_social_auth)
	_social_auth.auth_success.connect(_on_social_success)
	_social_auth.auth_failed.connect(_on_social_failed)

func _make_divider_line() -> Control:
	var r := ColorRect.new()
	r.color = Color(0.60, 0.45, 0.28, 0.50)
	r.custom_minimum_size = Vector2(0, 2)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	return r

func _make_social_button(provider: String, meta: Dictionary) -> Button:
	var bg_col:     Color = meta["bg"] as Color
	var fg_col:     Color = meta["fg"] as Color
	var border_col: Color = meta["border"] as Color

	var n := StyleBoxFlat.new()
	n.bg_color = bg_col
	n.border_color = border_col
	n.set_border_width_all(2)
	n.corner_radius_top_left    = 22
	n.corner_radius_top_right   = 22
	n.corner_radius_bottom_right = 22
	n.corner_radius_bottom_left  = 22
	n.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	n.shadow_size  = 6
	n.shadow_offset = Vector2(0, 3)

	var h := StyleBoxFlat.new()
	h.bg_color = bg_col.lightened(0.08)
	h.border_color = border_col
	h.set_border_width_all(2)
	h.corner_radius_top_left    = 22
	h.corner_radius_top_right   = 22
	h.corner_radius_bottom_right = 22
	h.corner_radius_bottom_left  = 22
	h.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	h.shadow_size  = 8
	h.shadow_offset = Vector2(0, 4)

	var p := StyleBoxFlat.new()
	p.bg_color = bg_col.darkened(0.10)
	p.border_color = border_col
	p.set_border_width_all(2)
	p.corner_radius_top_left    = 22
	p.corner_radius_top_right   = 22
	p.corner_radius_bottom_right = 22
	p.corner_radius_bottom_left  = 22

	var btn := Button.new()
	btn.text = meta["label"] as String
	btn.custom_minimum_size = Vector2(0, 72)
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color", fg_col)
	btn.add_theme_color_override("font_hover_color", fg_col)
	btn.add_theme_color_override("font_pressed_color", fg_col)
	btn.focus_mode = Control.FOCUS_NONE
	var cap_p: String = provider
	btn.pressed.connect(func() -> void: _on_social_btn_pressed(cap_p))
	return btn

func _on_social_btn_pressed(provider: String) -> void:
	_set_status("Opening %s login…" % provider.capitalize(), false)
	if _social_auth != null:
		_social_auth.start(provider)

func _on_social_success(provider: String, profile: Dictionary) -> void:
	var acc: Variant = AccountStore.login_or_register_social(profile)
	if acc == null:
		_set_status("Could not create account for %s login." % provider.capitalize(), true)
		return
	_set_status("Welcome, %s!" % String((acc as Dictionary).get("display_name", "Capy Player")), false)
	logged_in.emit(acc as Dictionary)

func _on_social_failed(provider: String, error: String) -> void:
	_set_status("%s login failed: %s" % [provider.capitalize(), error], true)

func _make_display_input() -> LineEdit:
	_display_name = _make_input("Display name")
	return _display_name

func _make_labeled_row(label_text: String, control: Control) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.35, 0.22, 0.1))
	row.add_child(lbl)
	row.add_child(control)
	return row

func _build_fav_picker() -> Control:
	var view := get_viewport_rect().size
	var n: int = _characters.size()
	var available_w: float = view.x - 152.0
	var gap: float = 8.0
	var btn_w: float = (available_w - float(n - 1) * gap) / float(n)
	var portrait_size: float = min(btn_w - 20.0, 160.0)
	var name_h: float = 36.0
	var btn_h: float = 10.0 + portrait_size + 6.0 + name_h + 10.0
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", int(gap))
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(n):
		var data: CharacterData = _characters[i]
		var btn := _make_fav_button(data, Vector2(btn_w, btn_h), i)
		hbox.add_child(btn)
		_fav_cards.append(btn)
	return hbox

func _make_fav_button(data: CharacterData, size: Vector2, idx: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = size
	btn.size = size
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	btn.clip_contents = true
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(1.0, 0.99, 0.96, 1.0)
	bg_style.corner_radius_top_left = 20
	bg_style.corner_radius_top_right = 20
	bg_style.corner_radius_bottom_right = 20
	bg_style.corner_radius_bottom_left = 20
	bg_style.border_color = Color(0.82, 0.72, 0.55, 0.65)
	bg_style.set_border_width_all(2)
	bg_style.shadow_color = Color(0.25, 0.15, 0.05, 0.28)
	bg_style.shadow_size = 10
	bg_style.shadow_offset = Vector2(0, 4)
	btn.add_theme_stylebox_override("normal", bg_style)
	var hover_fav := StyleBoxFlat.new()
	hover_fav.bg_color = Color(0.96, 0.94, 0.86, 1.0)
	hover_fav.corner_radius_top_left = 20
	hover_fav.corner_radius_top_right = 20
	hover_fav.corner_radius_bottom_right = 20
	hover_fav.corner_radius_bottom_left = 20
	hover_fav.border_color = Color(0.88, 0.68, 0.35, 0.9)
	hover_fav.set_border_width_all(3)
	hover_fav.shadow_color = Color(0.25, 0.15, 0.05, 0.35)
	hover_fav.shadow_size = 12
	hover_fav.shadow_offset = Vector2(0, 4)
	btn.add_theme_stylebox_override("hover", hover_fav)
	var padding: float = 10.0
	var portrait_size: float = min(size.x - 2.0 * padding, 160.0)
	var portrait_x: float = (size.x - portrait_size) * 0.5
	var name_h: float = size.y - 2.0 * padding - portrait_size - 6.0
	var portrait: Texture2D = _load_portrait(String(data.id))
	if portrait != null:
		var tex_rect := TextureRect.new()
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture = portrait
		tex_rect.position = Vector2(portrait_x, padding)
		tex_rect.size = Vector2(portrait_size, portrait_size)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tex_rect)
	else:
		var col := ColorRect.new()
		col.color = data.tint
		col.position = Vector2(portrait_x, padding)
		col.size = Vector2(portrait_size, portrait_size)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(col)
	var name_label := Label.new()
	name_label.text = data.display_name
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(0.12, 0.07, 0.02))
	name_label.add_theme_color_override("font_hover_color", Color(0.12, 0.07, 0.02))
	name_label.position = Vector2(portrait_x, padding + portrait_size + 6.0)
	name_label.size = Vector2(portrait_size, name_h)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_label)
	btn.pressed.connect(func() -> void: _on_fav_card_pressed(idx))
	return btn

func _on_fav_card_pressed(idx: int) -> void:
	_select_fav_card(idx)

func _select_fav_card(idx: int) -> void:
	_fav_selected_idx = idx
	for i in _fav_cards.size():
		var btn: Button = _fav_cards[i]
		if i == idx:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			var sel := StyleBoxFlat.new()
			sel.bg_color = Color(1.0, 0.97, 0.82, 1.0)
			sel.corner_radius_top_left = 20
			sel.corner_radius_top_right = 20
			sel.corner_radius_bottom_right = 20
			sel.corner_radius_bottom_left = 20
			sel.set_border_width_all(6)
			sel.border_color = Color(0.98, 0.72, 0.08, 1.0)
			sel.shadow_color = Color(0.98, 0.72, 0.08, 0.60)
			sel.shadow_size = 16
			sel.shadow_offset = Vector2(0, 5)
			btn.add_theme_stylebox_override("normal", sel)
			btn.add_theme_stylebox_override("hover", sel)
			btn.add_theme_stylebox_override("pressed", sel)
		else:
			btn.modulate = Color(0.78, 0.78, 0.78, 1.0)
			btn.remove_theme_stylebox_override("normal")
			btn.remove_theme_stylebox_override("hover")
			btn.remove_theme_stylebox_override("pressed")

func _set_mode(mode: int) -> void:
	_mode = mode
	_status.text = ""
	if mode == Mode.REGISTER:
		# Snapshot the current login form before wiping it, so we can
		# restore it if the user taps "← Sign in".
		_remembered_login = {
			"username": _username.text,
			"password": _password.text,
			"remember": _remember_check.button_pressed,
		}
		_username.text = ""
		_password.text = ""
		_confirm.text = ""
		_display_name.text = ""
		_remember_check.button_pressed = false
		_fav_selected_idx = -1
		for btn in _fav_cards:
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			btn.remove_theme_stylebox_override("normal")
			btn.remove_theme_stylebox_override("hover")
			btn.remove_theme_stylebox_override("pressed")
	elif mode == Mode.LOGIN:
		# If we have a snapshot from a prior visit to the sign-up page,
		# restore it. Otherwise fall back to the persisted remember file.
		if not _remembered_login.is_empty():
			_username.text = String(_remembered_login.get("username", ""))
			_password.text = String(_remembered_login.get("password", ""))
			_remember_check.button_pressed = bool(_remembered_login.get("remember", false))
			_remembered_login = {}
		else:
			_load_remember()
	_apply_mode()

func _on_mode_toggle() -> void:
	_set_mode(Mode.LOGIN if _mode == Mode.REGISTER else Mode.REGISTER)

func _apply_mode() -> void:
	var is_register: bool = _mode == Mode.REGISTER
	_subtitle.text = "Create your trainer profile" if is_register else "Welcome back, capy explorer!"
	_submit.text = "Create Account" if is_register else "Log In"
	_btn_new.text = "← Back" if is_register else "Sign Up"
	_confirm_row.visible = is_register
	_display_row.visible = is_register
	_favorite_row.visible = is_register
	if _social_section != null:
		_social_section.visible = not is_register

func _on_submit() -> void:
	if _mode == Mode.REGISTER:
		_do_register()
	else:
		_do_login()

func _do_login() -> void:
	var acc: Variant = AccountStore.login(_username.text, _password.text)
	if acc == null:
		_set_status("Incorrect username or password.", true)
		return
	_persist_remember()
	_set_status("Welcome back, %s!" % acc.get("display_name", _username.text), false)
	logged_in.emit(acc)

func _do_register() -> void:
	var favorite_id: String = ""
	if not _characters.is_empty() and _fav_selected_idx >= 0:
		favorite_id = String(_characters[_fav_selected_idx].id)
	var err := AccountStore.register(
		_username.text,
		_password.text,
		_confirm.text,
		_display_name.text,
		favorite_id,
	)
	if err != "":
		_set_status(err, true)
		return
	var acc: Variant = AccountStore.login(_username.text, _password.text)
	if acc == null:
		_set_status("Account created but auto-login failed. Try logging in.", true)
		return
	_persist_remember()
	_set_status("Account created. Welcome, %s!" % acc.get("display_name", _username.text), false)
	logged_in.emit(acc)

func _load_portrait(char_id: String) -> Texture2D:
	if char_id == "":
		return null
	for ext in PORTRAIT_EXTS:
		var path: String = PORTRAIT_DIR + char_id + ext
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null

func _set_status(msg: String, is_error: bool) -> void:
	_status.text = msg
	_status.add_theme_color_override("font_color", Color(0.75, 0.15, 0.15) if is_error else Color(0.1, 0.45, 0.2))

# ---- Remember me ------------------------------------------------------------
# Credentials are stored locally so the user can skip retyping them. The
# password is base64-obfuscated rather than hashed because AccountStore needs
# the raw value to authenticate. This is a local-only convenience for a
# single-device prototype; do not treat it as a security boundary.

func _load_remember() -> void:
	if not FileAccess.file_exists(REMEMBER_PATH):
		return
	var f := FileAccess.open(REMEMBER_PATH, FileAccess.READ)
	if f == null:
		return
	var raw: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	if not bool(data.get("enabled", false)):
		return
	_username.text = String(data.get("username", ""))
	var pw_b64: String = String(data.get("password", ""))
	if pw_b64 != "":
		var bytes := Marshalls.base64_to_raw(pw_b64)
		_password.text = bytes.get_string_from_utf8()
	_remember_check.button_pressed = true

func _persist_remember() -> void:
	if _remember_check == null:
		return
	if not _remember_check.button_pressed:
		_clear_remember()
		return
	var payload := {
		"enabled": true,
		"username": _username.text,
		"password": Marshalls.raw_to_base64(_password.text.to_utf8_buffer()),
	}
	var f := FileAccess.open(REMEMBER_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(payload))
	f.close()

func _clear_remember() -> void:
	if FileAccess.file_exists(REMEMBER_PATH):
		DirAccess.remove_absolute(REMEMBER_PATH)

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
