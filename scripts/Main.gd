extends Node

## Top-level flow controller:
##   Login  →  Lobby  →  Character Select  →  Inventory  →  Match  →  Lobby

const LOGIN_SCENE := preload("res://scenes/Login.tscn")
const LOBBY_SCENE := preload("res://scenes/Lobby.tscn")
const SELECT_SCENE := preload("res://scenes/CharacterSelect.tscn")
const INVENTORY_SCENE := preload("res://scenes/Inventory.tscn")
const MATCH_SCENE := preload("res://scenes/Match.tscn")
const STORY_SCENE := preload("res://scenes/StorySelect.tscn")
const STORY_INVENTORY_SCENE := preload("res://scenes/StoryInventory.tscn")
const HISTORY_SCENE := preload("res://scenes/History.tscn")
const COLLECTIBLES_SCENE := preload("res://scenes/Collectibles.tscn")
const PROFILE_PATH := "user://profile.json"

const HEALTHCHECK_URL: String = "https://capy-dungeon.onrender.com/health"
const INTERNET_FALLBACK_URL: String = "https://www.google.com/generate_204"
const ANDROID_VERSION_CHECK_URL: String = "https://capy-dungeon.onrender.com/app/version/android"
const IOS_VERSION_CHECK_URL: String = "https://capy-dungeon.onrender.com/app/version/ios"
const PLAY_STORE_URL_ANDROID: String = "https://play.google.com/store/apps/details?id=com.capydungeon.game"
const APP_STORE_URL_IOS: String = "https://apps.apple.com/app/id0000000000"
const TESTFLIGHT_URL_IOS: String = "https://testflight.apple.com/join/YYwXxZfJ"

const BGM_LOBBY_PATH:   String = "res://assets/sfx/bgm_lobby.mp3"
const BGM_DUNGEON_PATH: String = "res://assets/sfx/bgm_dungeon.mp3"
const BGM_FADE_TIME:    float  = 1.2   # crossfade duration in seconds
const BGM_LOBBY_VOLUME_DB: float = 0.0
const BGM_DUNGEON_VOLUME_DB: float = -14.0
const HISTORY_SYNC_COOLDOWN_MS: int = 45000
const SESSION_CHECK_INTERVAL: float = 5.0

var _account: Dictionary = {}
var _last_character: CharacterData = null
var _story_stage: Dictionary = {}
var _is_story_test_run: bool = false
var _story_test_stage_id: String = ""
var _open_story_test_selector: bool = false
var _dungeon_mode: String = ""
var _loadout_snapshot: Dictionary = {}

var _startup_gate_passed: bool = false
var _gate_mode: String = "none"
var _update_url_pending: String = ""
var _gate_layer: CanvasLayer = null
var _gate_overlay: ColorRect = null
var _gate_panel: PanelContainer = null
var _gate_title: Label = null
var _gate_message: Label = null
var _gate_primary_btn: Button = null
var _gate_secondary_btn: Button = null
var _runtime_net_timer: Timer = null
var _history_loading_layer: CanvasLayer = null
var _last_history_sync_ms: int = 0
var _display_name_prompt_layer: CanvasLayer = null
var _session_token: String = ""
var _session_check_elapsed: float = 0.0
var _session_check_pending: bool = false
var _session_expired_layer: CanvasLayer = null

# ── Music players ─────────────────────────────────────────────────────────────
var _bgm_a: AudioStreamPlayer = null
var _bgm_b: AudioStreamPlayer = null
var _bgm_fading: bool  = false
var _bgm_fade_t: float = 0.0
var _bgm_current_path: String = ""
var _bgm_active_volume_db: float = BGM_LOBBY_VOLUME_DB
var _bgm_next_volume_db: float = BGM_LOBBY_VOLUME_DB

func _ready() -> void:
	SettingsStore.apply.call_deferred(get_tree())
	_setup_music()
	_build_blocking_gate_ui()
	_update_url_pending = _default_update_url_for_platform()
	if _should_enforce_online_gate():
		_begin_startup_checks()
	else:
		_startup_gate_passed = true
		_resume_persistent_login_or_show_login()
	# Handle cold-start via capydungeon:// deep link (app launched by URL scheme)
	if OS.get_name() == "Android":
		call_deferred("_check_launch_deep_link")
	_setup_runtime_network_timer()
	if _runtime_net_timer != null and _runtime_net_timer.is_stopped() and _should_enforce_online_gate():
		_runtime_net_timer.start()

func _should_enforce_online_gate() -> bool:
	# Enforce startup connectivity/update gate on mobile platforms.
	var os_name := OS.get_name()
	return os_name == "Android" or os_name == "iOS"

func _check_launch_deep_link() -> void:
	var url := _read_android_deep_link()
	if not url.is_empty():
		_on_deep_link(url)

func _setup_music() -> void:
	_bgm_a = AudioStreamPlayer.new()
	_bgm_a.bus = "Music"
	add_child(_bgm_a)
	_bgm_b = AudioStreamPlayer.new()
	_bgm_b.bus = "Music"
	add_child(_bgm_b)

func _play_music(path: String, volume_db: float = BGM_LOBBY_VOLUME_DB) -> void:
	if path == _bgm_current_path:
		_bgm_active_volume_db = volume_db
		if _bgm_a != null and _bgm_a.playing and not _bgm_fading:
			_bgm_a.volume_db = volume_db
		return
	_bgm_current_path = path
	_bgm_next_volume_db = volume_db
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	# Ensure looping regardless of import settings
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	# If nothing playing yet, start immediately
	if not _bgm_a.playing:
		_bgm_a.stream = stream
		_bgm_a.volume_db = volume_db
		_bgm_a.play()
		_bgm_b.stop()
		_bgm_fading = false
		_bgm_active_volume_db = volume_db
		return
	# Crossfade: start new track on B, fade A out
	_bgm_b.stream = stream
	_bgm_b.volume_db = -80.0
	_bgm_b.play()
	_bgm_fading = true
	_bgm_fade_t = 0.0

func _stop_music() -> void:
	_bgm_current_path = ""
	_bgm_a.stop()
	_bgm_b.stop()
	_bgm_fading = false

func _scaled_music_db(target_db: float, factor: float) -> float:
	if factor <= 0.001:
		return -80.0
	return target_db + linear_to_db(clamp(factor, 0.0001, 1.0))

func _process(delta: float) -> void:
	if _bgm_fading:
		_bgm_fade_t += delta
		var t: float = clamp(_bgm_fade_t / BGM_FADE_TIME, 0.0, 1.0)
		_bgm_a.volume_db = _scaled_music_db(_bgm_active_volume_db, 1.0 - t)
		_bgm_b.volume_db = _scaled_music_db(_bgm_next_volume_db, t)
		if t >= 1.0:
			_bgm_a.stop()
			var tmp: AudioStreamPlayer = _bgm_a
			_bgm_a = _bgm_b
			_bgm_b = tmp
			_bgm_active_volume_db = _bgm_next_volume_db
			_bgm_a.volume_db = _bgm_active_volume_db
			_bgm_fading = false
	_poll_account_session(delta)

## Called by the OS when the app is (re)opened via a capydungeon:// deep link.
## Wire this up from your platform bridge:
##   Android — in _notification(NOTIFICATION_APPLICATION_FOCUS_IN):
##     var url := _read_android_deep_link()
##     if not url.is_empty(): _on_deep_link(url)
##   iOS — in your Godot iOS plugin's URL-opened callback:
##     Main._on_deep_link(url_string)
func _on_deep_link(url: String) -> void:
	DebugLog.log("[Main] _on_deep_link: url='%s'" % url)
	if url.begins_with("capydungeon://auth/"):
		var auth_node := _find_social_auth()
		if auth_node:
			auth_node.handle_deep_link(url)
		else:
			DebugLog.log("[Main] _on_deep_link: WARN SocialAuth not found — URL dropped!")

func _notification(what: int) -> void:
	if OS.get_name() != "Android":
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN:
			var url := _read_android_deep_link()
			if not url.is_empty():
				_on_deep_link(url)

## Reads the deep-link URL from the Android Activity intent, then clears it
## so the same URL isn't processed again on the next focus event.
func _read_android_deep_link() -> String:
	if not Engine.has_singleton("AndroidRuntime"):
		return ""
	var runtime = Engine.get_singleton("AndroidRuntime")
	var activity = runtime.call("getActivity")
	if not activity:
		return ""
	var intent = activity.call("getIntent")
	if not intent:
		return ""
	var data = intent.call("getDataString")
	if data == null:
		return ""
	var uri: String = str(data)
	if uri.begins_with("capydungeon://"):
		DebugLog.log("[Main] _read_android_deep_link: FOUND url='%s'" % uri)
		DebugLog.sticky = "LAST_URL: " + uri
		intent.call("setData", null)   # consume — prevents reprocessing on resume
		return uri
	return ""

func _find_social_auth() -> SocialAuth:
	# Try by name first (fast path — works when Login.gd sets node.name = "SocialAuth")
	var by_name := find_child("SocialAuth", true, false)
	if by_name is SocialAuth:
		return by_name as SocialAuth
	# Fallback: walk the entire subtree and match by type.
	# Necessary because SocialAuth.new() may not set the node name to the class name
	# in all Godot 4 versions, causing find_child to return null even though the
	# node is present and receives notifications correctly.
	var result := _find_social_auth_recursive(self)
	if result == null:
		DebugLog.log("[Main] _find_social_auth: not found anywhere in tree")
	return result

func _find_social_auth_recursive(node: Node) -> SocialAuth:
	for child in node.get_children():
		if child is SocialAuth:
			return child as SocialAuth
		var found := _find_social_auth_recursive(child)
		if found:
			return found
	return null

func _cloud_username_for(account: Dictionary) -> String:
	# Prefer social email for cloud sync so Google logins across devices share one key.
	var social_email: String = str(account.get("social_email", "")).strip_edges().to_lower()
	if not social_email.is_empty():
		return social_email
	return str(account.get("username", "")).strip_edges().to_lower()

func _load_profile() -> Dictionary:
	if not FileAccess.file_exists(PROFILE_PATH):
		return {}
	var f := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}

func _save_profile(profile: Dictionary) -> void:
	var f := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(profile))
	f.close()

func _profile_display_name_for(account: Dictionary) -> String:
	var profile: Dictionary = _load_profile()
	var from_profile: String = String(profile.get("display_name", "")).strip_edges()
	if not from_profile.is_empty():
		return from_profile
	var fallback: String = String(account.get("display_name", "")).strip_edges()
	if fallback.is_empty():
		fallback = String(account.get("username", "Capy Player")).strip_edges()
	return fallback

func _ensure_profile_display_name(account: Dictionary, done: Callable) -> void:
	var existing: String = String(_load_profile().get("display_name", "")).strip_edges()
	if not existing.is_empty():
		done.call(existing)
		return

	if _display_name_prompt_layer != null and is_instance_valid(_display_name_prompt_layer):
		_display_name_prompt_layer.queue_free()

	var view: Vector2 = get_viewport().get_visible_rect().size
	_display_name_prompt_layer = CanvasLayer.new()
	_display_name_prompt_layer.layer = 220
	add_child(_display_name_prompt_layer)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.72)
	overlay.size = view
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_display_name_prompt_layer.add_child(overlay)

	var center := CenterContainer.new()
	center.size = view
	_display_name_prompt_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(min(view.x - 96.0, 860.0), 0)
	center.add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.10, 0.08, 0.98)
	panel_style.border_color = Color(0.96, 0.78, 0.40, 0.85)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.corner_radius_bottom_right = 24
	panel_style.corner_radius_bottom_left = 24
	panel_style.content_margin_left = 28
	panel_style.content_margin_right = 28
	panel_style.content_margin_top = 24
	panel_style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Set your display name"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1.0, 0.93, 0.78))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var msg := Label.new()
	msg.text = "Choose a display name for leaderboard and profile. You can change this later in My Profile."
	msg.add_theme_font_size_override("font_size", 28)
	msg.add_theme_color_override("font_color", Color(0.90, 0.84, 0.72))
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(msg)

	var input := LineEdit.new()
	input.custom_minimum_size = Vector2(0, 72)
	input.add_theme_font_size_override("font_size", 32)
	input.placeholder_text = "Display name"
	input.text = _profile_display_name_for(account)
	vbox.add_child(input)

	var status := Label.new()
	status.add_theme_font_size_override("font_size", 22)
	status.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status)

	var save_btn := Button.new()
	save_btn.text = "Continue"
	save_btn.custom_minimum_size = Vector2(0, 84)
	save_btn.add_theme_font_size_override("font_size", 34)
	vbox.add_child(save_btn)

	var submit := func() -> void:
		var chosen: String = input.text.strip_edges()
		if chosen.is_empty():
			status.text = "Display name cannot be empty."
			return
		var profile: Dictionary = _load_profile()
		profile["display_name"] = chosen
		_save_profile(profile)
		if _display_name_prompt_layer != null and is_instance_valid(_display_name_prompt_layer):
			_display_name_prompt_layer.queue_free()
		_display_name_prompt_layer = null
		done.call(chosen)

	save_btn.pressed.connect(submit)
	input.text_submitted.connect(func(_t: String) -> void: submit.call())

func _build_blocking_gate_ui() -> void:
	if _gate_layer != null:
		return
	var view: Vector2 = get_viewport().get_visible_rect().size
	_gate_layer = CanvasLayer.new()
	_gate_layer.layer = 200
	_gate_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_gate_layer)

	_gate_overlay = ColorRect.new()
	_gate_overlay.color = Color(0, 0, 0, 0.72)
	_gate_overlay.size = view
	_gate_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_gate_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_gate_layer.add_child(_gate_overlay)

	var center := CenterContainer.new()
	center.size = view
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	_gate_layer.add_child(center)

	_gate_panel = PanelContainer.new()
	_gate_panel.custom_minimum_size = Vector2(min(view.x - 96.0, 860.0), 0)
	_gate_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	center.add_child(_gate_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.10, 0.08, 0.98)
	panel_style.border_color = Color(0.96, 0.78, 0.40, 0.85)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.corner_radius_bottom_right = 24
	panel_style.corner_radius_bottom_left = 24
	panel_style.content_margin_left = 28
	panel_style.content_margin_right = 28
	panel_style.content_margin_top = 24
	panel_style.content_margin_bottom = 24
	_gate_panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	_gate_panel.add_child(vbox)

	_gate_title = Label.new()
	_gate_title.add_theme_font_size_override("font_size", 44)
	_gate_title.add_theme_color_override("font_color", Color(1.0, 0.93, 0.78))
	_gate_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gate_title.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(_gate_title)

	_gate_message = Label.new()
	_gate_message.add_theme_font_size_override("font_size", 30)
	_gate_message.add_theme_color_override("font_color", Color(0.90, 0.84, 0.72))
	_gate_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gate_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gate_message.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(_gate_message)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.process_mode = Node.PROCESS_MODE_ALWAYS
	vbox.add_child(row)

	_gate_primary_btn = Button.new()
	_gate_primary_btn.custom_minimum_size = Vector2(280, 84)
	_gate_primary_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gate_primary_btn.add_theme_font_size_override("font_size", 34)
	_gate_primary_btn.focus_mode = Control.FOCUS_NONE
	_gate_primary_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_gate_primary_btn.pressed.connect(_on_gate_primary_pressed)
	row.add_child(_gate_primary_btn)

	_gate_secondary_btn = Button.new()
	_gate_secondary_btn.custom_minimum_size = Vector2(280, 84)
	_gate_secondary_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gate_secondary_btn.add_theme_font_size_override("font_size", 34)
	_gate_secondary_btn.focus_mode = Control.FOCUS_NONE
	_gate_secondary_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_gate_secondary_btn.pressed.connect(_on_gate_secondary_pressed)
	row.add_child(_gate_secondary_btn)

	_gate_layer.visible = false

func _setup_runtime_network_timer() -> void:
	if _runtime_net_timer != null:
		return
	_runtime_net_timer = Timer.new()
	_runtime_net_timer.wait_time = 7.0
	_runtime_net_timer.one_shot = false
	_runtime_net_timer.autostart = false
	_runtime_net_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_runtime_net_timer.timeout.connect(_on_runtime_network_tick)
	add_child(_runtime_net_timer)

func _begin_startup_checks() -> void:
	_show_gate_message("Checking internet", "Capy Dungeon requires an internet connection to start.", "Retry", "Quit", false)
	_check_online(func(online: bool) -> void:
		if not online:
			_gate_mode = "offline_startup"
			_show_gate_message("No internet connection", "Please connect to the internet to continue.", "Retry", "Quit")
			return
		_show_gate_message("Checking app version", "Please wait while we verify your app version.", "Retry", "Quit", false)
		_check_platform_update(func(info: Dictionary) -> void:
			if not (info.get("checked", false) as bool):
				_gate_mode = "offline_startup"
				_show_gate_message("Could not verify app version", "Connect to the internet and retry so we can check for updates.", "Retry", "Quit")
				return
			var required: bool = info.get("required", false) as bool
			if required:
				_gate_mode = "force_update"
				_update_url_pending = String(info.get("url", _default_update_url_for_platform()))
				_show_gate_message("Update required", String(info.get("message", "A newer app version is available. Please update to continue.")), _update_button_text_for_url(_update_url_pending), "Quit")
				return
			_gate_mode = "none"
			_hide_gate()
			if not _startup_gate_passed:
				_startup_gate_passed = true
				_resume_persistent_login_or_show_login()
			if _runtime_net_timer != null and _runtime_net_timer.is_stopped():
				_runtime_net_timer.start()
		)
	)

func _resume_persistent_login_or_show_login() -> void:
	var persisted: Variant = AccountStore.load_persistent_session()
	if typeof(persisted) == TYPE_DICTIONARY and not (persisted as Dictionary).is_empty():
		_on_logged_in(persisted as Dictionary)
		return
	_show_login()

func _show_gate_message(title: String, message: String, primary_text: String, secondary_text: String, show_buttons: bool = true) -> void:
	if _gate_layer == null:
		return
	_gate_title.text = title
	_gate_message.text = message
	_gate_primary_btn.text = primary_text
	_gate_secondary_btn.text = secondary_text
	_gate_primary_btn.visible = show_buttons
	_gate_secondary_btn.visible = show_buttons
	_gate_primary_btn.disabled = not show_buttons
	_gate_secondary_btn.disabled = not show_buttons
	_gate_layer.visible = true
	# During startup, there is nothing to pause yet; during runtime, this blocks play.
	if _startup_gate_passed:
		get_tree().paused = true

func _hide_gate() -> void:
	if _gate_layer != null:
		_gate_layer.visible = false
	get_tree().paused = false

func _on_gate_primary_pressed() -> void:
	match _gate_mode:
		"offline_startup":
			_begin_startup_checks()
		"offline_runtime":
			_check_online(func(online: bool) -> void:
				if online:
					_gate_mode = "none"
					_hide_gate()
				else:
					_show_gate_message("No internet connection", "Please connect to the internet to continue.", "Retry", "Quit")
			)
		"force_update":
			OS.shell_open(_update_url_pending)
		_:
			_begin_startup_checks()

func _on_gate_secondary_pressed() -> void:
	get_tree().quit()

func _on_runtime_network_tick() -> void:
	if not _startup_gate_passed:
		return
	if _gate_mode == "force_update":
		return
	_check_online(func(online: bool) -> void:
		if online:
			if _gate_mode == "offline_runtime":
				_gate_mode = "none"
				_hide_gate()
		else:
			_gate_mode = "offline_runtime"
			_show_gate_message("Connection lost", "Internet is required during gameplay. Reconnect to continue.", "Retry", "Quit")
	)

func _check_online(callback: Callable) -> void:
	if _android_network_available_native():
		callback.call(true)
		return
	var urls: Array[String] = [HEALTHCHECK_URL, INTERNET_FALLBACK_URL]
	_check_online_urls(urls, 0, callback)

func _android_network_available_native() -> bool:
	if OS.get_name() != "Android":
		return false
	if not Engine.has_singleton("AndroidRuntime"):
		return false
	var runtime = Engine.get_singleton("AndroidRuntime")
	var activity = runtime.call("getActivity")
	if not activity:
		return false
	var connectivity = activity.call("getSystemService", "connectivity")
	if connectivity == null:
		return false
	# API 23+: ask ConnectivityManager for active network capabilities.
	if connectivity.has_method("getActiveNetwork") and connectivity.has_method("getNetworkCapabilities"):
		var network = connectivity.call("getActiveNetwork")
		if network != null:
			var caps = connectivity.call("getNetworkCapabilities", network)
			if caps != null and caps.has_method("hasCapability"):
				# Android constants: NET_CAPABILITY_INTERNET=12
				if bool(caps.call("hasCapability", 12)):
					return true
	# Legacy fallback for older Android API levels.
	if connectivity.has_method("getActiveNetworkInfo"):
		var info = connectivity.call("getActiveNetworkInfo")
		if info != null and info.has_method("isConnected"):
			return bool(info.call("isConnected"))
	return false

func _check_online_urls(urls: Array[String], idx: int, callback: Callable) -> void:
	if idx >= urls.size():
		callback.call(false)
		return
	var url: String = urls[idx]
	var http := HTTPRequest.new()
	http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http)
	http.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
		http.queue_free()
		# Any successful HTTP response from at least one known host means internet is reachable.
		var reachable: bool = (result == HTTPRequest.RESULT_SUCCESS and code > 0 and code < 500)
		if reachable:
			callback.call(true)
		else:
			_check_online_urls(urls, idx + 1, callback)
	, CONNECT_ONE_SHOT)
	var err := http.request(url)
	if err != OK:
		http.queue_free()
		_check_online_urls(urls, idx + 1, callback)

func _check_android_update(callback: Callable) -> void:
	if OS.get_name() != "Android":
		callback.call({"checked": true, "required": false, "url": PLAY_STORE_URL_ANDROID, "message": ""})
		return
	var current_code: int = _get_android_version_code()
	if current_code <= 0:
		DebugLog.log("[Main] _check_android_update: could not read valid version code (got %d)" % current_code)
		callback.call({"checked": false, "required": false, "url": PLAY_STORE_URL_ANDROID, "message": ""})
		return
	var url := "%s?current_version_code=%d" % [ANDROID_VERSION_CHECK_URL, current_code]
	DebugLog.log("[Main] _check_android_update: querying %s" % url)
	var http := HTTPRequest.new()
	http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http)
	http.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
			callback.call({"checked": false, "required": false, "url": PLAY_STORE_URL_ANDROID, "message": ""})
			return
		var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
		if typeof(parsed) != TYPE_DICTIONARY:
			callback.call({"checked": false, "required": false, "url": PLAY_STORE_URL_ANDROID, "message": ""})
			return
		var payload: Dictionary = parsed as Dictionary
		callback.call({
			"checked": true,
			"required": payload.get("update_required", false) as bool,
			"url": String(payload.get("play_store_url", PLAY_STORE_URL_ANDROID)),
			"message": String(payload.get("message", "A newer app version is available. Please update to continue.")),
		})
	, CONNECT_ONE_SHOT)
	var err := http.request(url)
	if err != OK:
		http.queue_free()
		callback.call({"checked": false, "required": false, "url": PLAY_STORE_URL_ANDROID, "message": ""})

func _check_platform_update(callback: Callable) -> void:
	var os_name := OS.get_name()
	if os_name == "Android":
		_check_android_update(callback)
		return
	if os_name == "iOS":
		_check_ios_update(callback)
		return
	callback.call({"checked": true, "required": false, "url": _default_update_url_for_platform(), "message": ""})

func _check_ios_update(callback: Callable) -> void:
	if OS.get_name() != "iOS":
		callback.call({"checked": true, "required": false, "url": _default_update_url_for_platform(), "message": ""})
		return
	var current_short: String = _get_ios_short_version()
	if current_short.is_empty():
		current_short = String(ProjectSettings.get_setting("application/config/version", "0.0.0")).strip_edges()
	if current_short.is_empty():
		current_short = "0.0.0"
	var current_build: int = _get_ios_build_code()
	if current_build <= 0:
		current_build = max(int(ProjectSettings.get_setting("application/config/version_code", 0)), 0)
	DebugLog.log("[Main] _check_ios_update: local short='%s' build=%d" % [current_short, current_build])
	var query_url := "%s?current_short_version=%s&current_build=%d" % [
		IOS_VERSION_CHECK_URL,
		current_short.uri_encode(),
		current_build
	]
	DebugLog.log("[Main] _check_ios_update: querying %s" % query_url)
	var http := HTTPRequest.new()
	http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(http)
	http.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
			callback.call({"checked": false, "required": false, "url": _default_update_url_for_platform(), "message": ""})
			return
		var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
		if typeof(parsed) != TYPE_DICTIONARY:
			callback.call({"checked": false, "required": false, "url": _default_update_url_for_platform(), "message": ""})
			return
		var payload: Dictionary = parsed as Dictionary
		var required: bool = payload.get("update_required", false) as bool
		if not required:
			var min_short: String = String(payload.get("min_short_version", "")).strip_edges()
			var min_build: int = int(payload.get("min_build", 0))
			if not min_short.is_empty() and _compare_semver(current_short, min_short) < 0:
				required = true
			elif min_build > 0 and current_build < min_build:
				required = true
		callback.call({
			"checked": true,
			"required": required,
			"url": _pick_ios_update_url(payload),
			"message": String(payload.get("message", "A newer app version is available. Please update to continue.")),
		})
	, CONNECT_ONE_SHOT)
	var err := http.request(query_url)
	if err != OK:
		http.queue_free()
		callback.call({"checked": false, "required": false, "url": _default_update_url_for_platform(), "message": ""})

func _pick_ios_update_url(payload: Dictionary) -> String:
	var explicit: String = String(payload.get("url", "")).strip_edges()
	if not explicit.is_empty():
		return explicit
	var tf_url: String = String(payload.get("testflight_url", "")).strip_edges()
	if not tf_url.is_empty() and OS.is_debug_build():
		return tf_url
	var app_store_url: String = String(payload.get("app_store_url", "")).strip_edges()
	if not app_store_url.is_empty():
		return app_store_url
	if OS.is_debug_build() and not TESTFLIGHT_URL_IOS.is_empty() and not TESTFLIGHT_URL_IOS.contains("REPLACE_ME"):
		return TESTFLIGHT_URL_IOS
	if not APP_STORE_URL_IOS.is_empty() and not APP_STORE_URL_IOS.contains("0000000000"):
		return APP_STORE_URL_IOS
	return _default_update_url_for_platform()

func _default_update_url_for_platform() -> String:
	if OS.get_name() == "Android":
		return PLAY_STORE_URL_ANDROID
	if OS.get_name() == "iOS":
		if OS.is_debug_build() and not TESTFLIGHT_URL_IOS.is_empty() and not TESTFLIGHT_URL_IOS.contains("REPLACE_ME"):
			return TESTFLIGHT_URL_IOS
		if not APP_STORE_URL_IOS.is_empty() and not APP_STORE_URL_IOS.contains("0000000000"):
			return APP_STORE_URL_IOS
		return "https://apps.apple.com"
	return ""

func _update_button_text_for_platform() -> String:
	if OS.get_name() == "Android":
		return "Open Play Store"
	if OS.get_name() == "iOS":
		if OS.is_debug_build():
			return "Open TestFlight"
		return "Open App Store"
	return "Open Store"

func _update_button_text_for_url(url: String) -> String:
	if OS.get_name() == "iOS":
		var lowered: String = url.to_lower()
		if lowered.find("testflight.apple.com") != -1:
			return "Open TestFlight"
		if lowered.find("apps.apple.com") != -1:
			return "Open App Store"
	return _update_button_text_for_platform()

func _get_ios_short_version() -> String:
	var raw: Variant = ProjectSettings.get_setting("application/config/version", "")
	return String(raw).strip_edges()

func _get_ios_build_code() -> int:
	var fallback: int = int(ProjectSettings.get_setting("application/config/version_code", 0))
	if OS.get_name() != "iOS":
		return max(fallback, 0)
	if Engine.has_singleton("IOS"):
		var ios = Engine.get_singleton("IOS")
		if ios != null and ios.has_method("get_info_plist_value"):
			var plist_build: Variant = ios.call("get_info_plist_value", "CFBundleVersion")
			if plist_build != null:
				var parsed: int = int(str(plist_build).strip_edges())
				if parsed > 0:
					return parsed
	return max(fallback, 0)

func _compare_semver(a: String, b: String) -> int:
	var a_parts: PackedStringArray = a.split(".", false)
	var b_parts: PackedStringArray = b.split(".", false)
	var max_len: int = maxi(a_parts.size(), b_parts.size())
	for i in range(max_len):
		var ai: int = 0
		var bi: int = 0
		if i < a_parts.size():
			ai = int(a_parts[i])
		if i < b_parts.size():
			bi = int(b_parts[i])
		if ai < bi:
			return -1
		if ai > bi:
			return 1
	return 0

func _get_android_version_code() -> int:
	var fallback: int = int(ProjectSettings.get_setting("application/config/version_code", 0))
	if OS.get_name() != "Android":
		return max(fallback, 0)
	if not Engine.has_singleton("AndroidRuntime"):
		return max(fallback, 0)
	var runtime = Engine.get_singleton("AndroidRuntime")
	var activity = runtime.call("getActivity")
	if not activity:
		return max(fallback, 0)
	var pm = activity.call("getPackageManager")
	var package_name = activity.call("getPackageName")
	if not pm or package_name == null:
		return max(fallback, 0)
	var info = pm.call("getPackageInfo", package_name, 0)
	if not info:
		return max(fallback, 0)
	var detected: int = 0
	# JavaObject may not report Java methods through has_method reliably, so call directly.
	var long_code: Variant = info.call("getLongVersionCode")
	if long_code != null:
		detected = int(long_code)
	if detected <= 0:
		var legacy_code: Variant = info.call("getVersionCode")
		if legacy_code != null:
			detected = int(legacy_code)
	if detected <= 0:
		var field_code: Variant = info.get("versionCode")
		if field_code != null:
			detected = int(field_code)
	DebugLog.log("[Main] _get_android_version_code: detected=%d fallback=%d" % [detected, fallback])
	return max(max(fallback, 0), detected)

func _show_login() -> void:
	_account = {}
	_session_token = ""
	LeaderboardClient.set_session_token("")
	_session_check_elapsed = 0.0
	_session_check_pending = false
	_clear_children()
	_play_music(BGM_LOBBY_PATH, BGM_LOBBY_VOLUME_DB)
	var login := LOGIN_SCENE.instantiate()
	login.logged_in.connect(_on_logged_in)
	add_child(login)

func _on_logged_in(account: Dictionary) -> void:
	_account = account
	_ensure_profile_display_name(account, func(chosen_display_name: String) -> void:
		_account["display_name"] = chosen_display_name
		AccountStore.save_persistent_session(_account)
		var username: String = str(account.get("username", "")).strip_edges()
		var cloud_username: String = _cloud_username_for(account)
		if not username.is_empty():
			PurchaseStore.set_username(username)
			LeaderboardClient.claim_session(self, cloud_username, func(token: String) -> void:
				if token.is_empty():
					_show_login()
					return
				_session_token = token
				LeaderboardClient.set_session_token(token)
				_session_check_elapsed = 0.0
				_restore_cloud_progress_for_account(account, func() -> void:
					_last_history_sync_ms = Time.get_ticks_msec()
					_show_lobby()
					_show_account_linked_message()
				)
			)
		else:
			_show_lobby()
	)

func _show_lobby(open_play_hub: bool = false) -> void:
	_is_story_test_run = false
	_story_test_stage_id = ""
	_open_story_test_selector = false
	_sync_cloud_progress()
	_clear_children()
	_play_music(BGM_LOBBY_PATH, BGM_LOBBY_VOLUME_DB)
	var lobby := LOBBY_SCENE.instantiate()
	lobby.account = _account
	lobby.open_play_hub_on_ready = open_play_hub
	lobby.start_game_requested.connect(func() -> void:
		_story_stage = {}
		_dungeon_mode = ""
		_show_survival_difficulty_picker()
	)
	lobby.dungeon_requested.connect(func(dungeon_id: String) -> void:
		_story_stage = {}
		_dungeon_mode = dungeon_id
		_show_select()
	)
	lobby.story_requested.connect(_show_story)
	lobby.cloud_sync_requested.connect(_sync_cloud_progress)
	lobby.history_requested.connect(_show_history)
	lobby.collectibles_requested.connect(_show_collectibles)
	lobby.logout_requested.connect(func() -> void:
		AccountStore.clear_persistent_session()
		_show_login()
	)
	add_child(lobby)

func _show_story(advance_after_completion: bool = false) -> void:
	if not _is_story_test_run:
		_sync_cloud_progress()
	elif not _story_test_stage_id.is_empty():
		var exit_stage: Dictionary = StoryStore.stage(StoryStore.stage_index(_story_test_stage_id))
		print("[Story][TEST][C%dS%d][0.00s] Test mode exited" % [int(exit_stage.chapter), int(exit_stage.chapter_stage)])
	var initial_stage_index := -1
	if not _story_stage.is_empty() and not _is_story_test_run:
		var completed_index := StoryStore.stage_index(str(_story_stage.get("id", "")))
		var profile := StoryStore.load_profile(str(_account.get("username", "")))
		var completed_chapter := int(_story_stage.get("chapter", 1))
		var completed_chapter_stage := int(_story_stage.get("chapter_stage", 1))
		if not advance_after_completion or (completed_chapter_stage == 5 and not StoryStore.is_chapter_claimed(profile, completed_chapter)):
			initial_stage_index = completed_index
		else:
			initial_stage_index = mini(completed_index + 1, StoryStore.stage_count() - 1)
	_story_stage = {}
	_is_story_test_run = false
	_story_test_stage_id = ""
	_dungeon_mode = ""
	_clear_children()
	var story := STORY_SCENE.instantiate()
	story.account_username = String(_account.get("username", ""))
	story.initial_stage_index = initial_stage_index
	story.open_dev_test_selector_on_ready = _open_story_test_selector
	_open_story_test_selector = false
	story.stage_selected.connect(func(stage: Dictionary) -> void:
		_is_story_test_run = false
		_story_test_stage_id = ""
		_story_stage = stage
		_show_select()
	)
	story.test_stage_selected.connect(_launch_story_test_stage)
	story.back_requested.connect(_show_lobby.bind(true))
	story.cloud_sync_requested.connect(_sync_cloud_progress)
	add_child(story)

func _launch_story_test_stage(stage: Dictionary) -> void:
	if not OS.is_debug_build():
		push_warning("Story test launch rejected in a release build.")
		return
	var stage_id: String = str(stage.get("id", ""))
	if stage_id.is_empty():
		push_warning("Story test launch rejected because the stage ID is missing.")
		return
	_story_stage = StoryStore.stage(StoryStore.stage_index(stage_id)).duplicate(true)
	_is_story_test_run = true
	_story_test_stage_id = stage_id
	_dungeon_mode = ""
	_show_select()

func _show_survival_difficulty_picker() -> void:
	var layer := CanvasLayer.new(); layer.layer = 160; add_child(layer)
	var view := get_viewport().get_visible_rect().size
	var shade := ColorRect.new(); shade.color = Color(0.01, 0.02, 0.04, 0.94); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; layer.add_child(shade)
	var panel_height := minf(920.0, view.y - 100.0)
	var panel := PanelContainer.new(); panel.position = Vector2(60, (view.y - panel_height) * 0.5); panel.size = Vector2(view.x - 120, panel_height); panel.add_theme_stylebox_override("panel", _survival_picker_panel_style()); layer.add_child(panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 18); panel.add_child(box)
	var title := Label.new(); title.text = "CHOOSE SURVIVAL DIFFICULTY"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 46); title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.34)); box.add_child(title)
	var username := str(_account.get("username", "")); var profile := ProgressionStore.load_profile(username)
	var modifier := ProgressionStore.daily_modifier()
	var challenge := Label.new(); challenge.text = "Today's challenge: %s\n%s" % [str(modifier.name), str(modifier.desc)]; challenge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; challenge.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; challenge.add_theme_font_size_override("font_size", 27); box.add_child(challenge)
	var choices := VBoxContainer.new(); choices.size_flags_vertical = Control.SIZE_EXPAND_FILL; choices.add_theme_constant_override("separation", 14); box.add_child(choices)
	for i in ProgressionStore.DIFFICULTIES.size():
		var index := i; var difficulty: Dictionary = ProgressionStore.DIFFICULTIES[i] as Dictionary
		var selected := int(profile.get("difficulty", 0)) == index
		var button := Button.new(); button.text = "%s%s\nEnemy Health ×%.2f  ·  Enemy Damage ×%.2f  ·  Rewards ×%.2f" % ["SELECTED  ·  " if selected else "", str(difficulty.name), float(difficulty.enemy_hp), float(difficulty.enemy_damage), float(difficulty.reward)]; button.custom_minimum_size = Vector2(0, 112); button.size_flags_vertical = Control.SIZE_EXPAND_FILL; button.add_theme_font_size_override("font_size", 26); button.disabled = ProgressionStore.account_level(profile) < int(difficulty.unlock_level)
		if button.disabled: button.text += "\nUnlocks at Camp Level %d" % int(difficulty.unlock_level)
		_style_survival_picker_button(button, selected)
		button.pressed.connect(func() -> void: ProgressionStore.set_difficulty(username, index); layer.queue_free(); _sync_cloud_progress(); _show_select()); choices.add_child(button)
	var cancel := Button.new(); cancel.text = "Cancel"; cancel.custom_minimum_size = Vector2(0, 82); cancel.add_theme_font_size_override("font_size", 30); _style_survival_picker_button(cancel, false); cancel.pressed.connect(func() -> void: layer.queue_free()); box.add_child(cancel)

func _survival_picker_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color(0.035, 0.045, 0.075, 0.99); style.border_color = Color(0.86, 0.66, 0.22); style.set_border_width_all(4); style.corner_radius_top_left = 28; style.corner_radius_top_right = 28; style.corner_radius_bottom_left = 28; style.corner_radius_bottom_right = 28; style.content_margin_left = 28; style.content_margin_right = 28; style.content_margin_top = 28; style.content_margin_bottom = 28; style.shadow_color = Color(0, 0, 0, 0.48); style.shadow_size = 14; style.shadow_offset = Vector2(0, 5); return style

func _style_survival_picker_button(button: Button, selected: bool) -> void:
	var normal := _survival_picker_panel_style(); normal.bg_color = Color(0.30, 0.21, 0.06, 0.98) if selected else Color(0.10, 0.10, 0.17, 0.98); normal.border_color = Color(1.0, 0.82, 0.28) if selected else Color(0.55, 0.55, 0.75, 0.82); normal.set_border_width_all(4 if selected else 2); normal.content_margin_top = 10; normal.content_margin_bottom = 10; normal.shadow_size = 7
	var hover := normal.duplicate() as StyleBoxFlat; hover.bg_color = normal.bg_color.lightened(0.12)
	var pressed := normal.duplicate() as StyleBoxFlat; pressed.bg_color = normal.bg_color.darkened(0.10); pressed.shadow_size = 3
	var disabled := normal.duplicate() as StyleBoxFlat; disabled.bg_color = Color(0.06, 0.06, 0.08, 0.94); disabled.border_color = Color(0.28, 0.28, 0.32, 0.8); disabled.shadow_size = 0
	button.add_theme_stylebox_override("normal", normal); button.add_theme_stylebox_override("hover", hover); button.add_theme_stylebox_override("pressed", pressed); button.add_theme_stylebox_override("disabled", disabled); button.add_theme_color_override("font_color", Color(1.0, 0.88, 0.56) if selected else Color(0.92, 0.92, 1.0)); button.add_theme_color_override("font_disabled_color", Color(0.48, 0.48, 0.54)); button.focus_mode = Control.FOCUS_NONE

func _show_collectibles() -> void:
	_clear_children()
	var c := COLLECTIBLES_SCENE.instantiate()
	c.account_username = String(_account.get("username", ""))
	c.back_requested.connect(_show_lobby)
	add_child(c)

func _show_history() -> void:
	var username: String = String(_account.get("username", "")).strip_edges()
	_clear_children()
	var h := HISTORY_SCENE.instantiate()
	h.account = _account
	h.back_requested.connect(_show_lobby)
	add_child(h)
	if username.is_empty():
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _last_history_sync_ms < HISTORY_SYNC_COOLDOWN_MS:
		return
	_last_history_sync_ms = now_ms
	_restore_cloud_progress_for_account(_account)

func _show_history_loading_overlay(message: String) -> void:
	_hide_history_loading_overlay()
	var view: Vector2 = get_viewport().get_visible_rect().size
	_history_loading_layer = CanvasLayer.new()
	_history_loading_layer.layer = 210
	add_child(_history_loading_layer)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.70)
	overlay.size = view
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_history_loading_layer.add_child(overlay)

	var label := Label.new()
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.80))
	label.position = Vector2(0, view.y * 0.42)
	label.size = Vector2(view.x, 220)
	_history_loading_layer.add_child(label)

func _hide_history_loading_overlay() -> void:
	if _history_loading_layer != null and is_instance_valid(_history_loading_layer):
		_history_loading_layer.queue_free()
	_history_loading_layer = null

func _apply_cloud_payload(username: String, data: Dictionary) -> void:
	StatsStore.restore_from_server(username, data.get("stats", {}) as Dictionary)
	RingStore.restore_from_server(
		username,
		data.get("ring_stash", []) as Array,
		data.get("rings_equipped", {}) as Dictionary
	)
	ArtifactStore.restore_from_server(
		username,
		data.get("artifact_stash", []) as Array,
		data.get("artifact_equipped", {}) as Dictionary
	)
	StoryStore.restore_from_server(username, data.get("story", {}) as Dictionary)
	ProgressionStore.restore_from_server(username, data.get("progression", {}) as Dictionary)

func _sync_cloud_progress() -> void:
	var username: String = String(_account.get("username", "")).strip_edges()
	if username.is_empty():
		return
	LeaderboardClient.submit_stats(self, _cloud_username_for(_account), _profile_display_name_for(_account), username)

func _poll_account_session(delta: float) -> void:
	if _session_token.is_empty() or _account.is_empty() or _session_check_pending or _session_expired_layer != null:
		return
	_session_check_elapsed += delta
	if _session_check_elapsed < SESSION_CHECK_INTERVAL:
		return
	_session_check_elapsed = 0.0
	_session_check_pending = true
	LeaderboardClient.check_session(self, _cloud_username_for(_account), _session_token, func(active: bool) -> void:
		_session_check_pending = false
		if not active and not _session_token.is_empty():
			_show_session_expired()
	)

func _show_account_linked_message() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 220
	add_child(layer)
	var view := get_viewport().get_visible_rect().size
	var panel := PanelContainer.new()
	panel.position = Vector2(70, 75)
	panel.size = Vector2(view.x - 140, 92)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.24, 0.16, 0.96)
	style.border_color = Color(0.42, 0.88, 0.58)
	style.set_border_width_all(3)
	style.corner_radius_top_left = 24; style.corner_radius_top_right = 24; style.corner_radius_bottom_left = 24; style.corner_radius_bottom_right = 24
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var label := Label.new()
	label.text = "Account successfully linked."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	panel.add_child(label)
	var timer := get_tree().create_timer(3.0)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(layer): layer.queue_free()
	)

func _show_session_expired() -> void:
	if _session_expired_layer != null:
		return
	get_tree().paused = true
	_session_expired_layer = CanvasLayer.new()
	_session_expired_layer.layer = 500
	_session_expired_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_session_expired_layer)
	var view := get_viewport().get_visible_rect().size
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.01, 0.02, 0.94)
	shade.size = view
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_session_expired_layer.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(70, view.y * 0.28)
	panel.size = Vector2(view.x - 140, 600)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.12, 0.99)
	style.border_color = Color(0.76, 0.48, 0.20)
	style.set_border_width_all(4)
	style.corner_radius_top_left = 28; style.corner_radius_top_right = 28; style.corner_radius_bottom_left = 28; style.corner_radius_bottom_right = 28
	style.content_margin_left = 35; style.content_margin_right = 35; style.content_margin_top = 38; style.content_margin_bottom = 38
	panel.add_theme_stylebox_override("panel", style)
	_session_expired_layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 26)
	panel.add_child(box)
	var title := Label.new()
	title.text = "SESSION EXPIRED\nAccount Logged In Elsewhere"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("ffd06a"))
	box.add_child(title)
	var body := Label.new()
	body.text = "This account is now active on another device. Your current game has been paused to protect your progress."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 27)
	body.custom_minimum_size = Vector2(0, 150)
	box.add_child(body)
	var button := Button.new()
	button.text = "RETURN TO TITLE SCREEN"
	button.custom_minimum_size = Vector2(0, 90)
	button.add_theme_font_size_override("font_size", 30)
	button.pressed.connect(_return_to_title_after_session_expired)
	box.add_child(button)

func _return_to_title_after_session_expired() -> void:
	_session_token = ""
	LeaderboardClient.set_session_token("")
	AccountStore.clear_persistent_session()
	if _session_expired_layer != null:
		_session_expired_layer.queue_free()
	_session_expired_layer = null
	get_tree().paused = false
	_show_login()

func _payload_has_progress(data: Dictionary) -> bool:
	var stats: Dictionary = data.get("stats", {}) as Dictionary
	if not stats.is_empty():
		return true
	if not (data.get("ring_stash", []) as Array).is_empty():
		return true
	if not (data.get("artifact_stash", []) as Array).is_empty():
		return true
	if not (data.get("rings_equipped", {}) as Dictionary).is_empty():
		return true
	if not (data.get("artifact_equipped", {}) as Dictionary).is_empty():
		return true
	if not (data.get("story", {}) as Dictionary).is_empty():
		return true
	if not (data.get("progression", {}) as Dictionary).is_empty():
		return true
	return false

func _restore_cloud_progress_for_account(account: Dictionary, done: Callable = Callable()) -> void:
	var username: String = String(account.get("username", "")).strip_edges()
	if username.is_empty():
		if done.is_valid():
			done.call()
		return
	var cloud_username: String = _cloud_username_for(account)
	LeaderboardClient.fetch_user_stats(self, cloud_username, func(data: Dictionary) -> void:
		if _payload_has_progress(data):
			_apply_cloud_payload(username, data)
			if done.is_valid():
				done.call()
			return
		if cloud_username == username:
			if done.is_valid():
				done.call()
			return
		LeaderboardClient.fetch_user_stats(self, username, func(legacy: Dictionary) -> void:
			if _payload_has_progress(legacy):
				_apply_cloud_payload(username, legacy)
				LeaderboardClient.submit_stats(self, cloud_username, _profile_display_name_for(account), username)
			if done.is_valid():
				done.call()
		)
	)

func _show_select() -> void:
	_clear_children()
	var username: String = String(_account.get("username", ""))
	PurchaseStore.set_username(username)
	var sel := SELECT_SCENE.instantiate()
	sel.favourite_character_id = String(_account.get("favorite_capy", ""))
	sel.account_username = username
	sel.character_chosen.connect(_on_character_chosen)
	sel.back_to_menu.connect(_show_story if not _story_stage.is_empty() else _show_lobby)
	add_child(sel)

func _on_character_chosen(data: CharacterData) -> void:
	_last_character = data
	if not _story_stage.is_empty():
		if _is_story_test_run:
			_start_match(data)
		else:
			_show_story_inventory(data)
	else:
		_show_inventory(data)

func _show_story_inventory(data: CharacterData) -> void:
	_clear_children()
	var inv := STORY_INVENTORY_SCENE.instantiate()
	inv.selected_character = data
	inv.account_username = String(_account.get("username", ""))
	inv.confirmed.connect(_start_match)
	inv.back_requested.connect(_show_select)
	inv.cloud_sync_requested.connect(_sync_cloud_progress)
	inv.accessories_requested.connect(_edit_accessories_from_story.bind(data))
	add_child(inv)

func _show_inventory(data: CharacterData) -> void:
	_clear_children()
	var inv := INVENTORY_SCENE.instantiate()
	inv.selected_character = data
	inv.account_username   = String(_account.get("username", ""))
	inv.inventory_confirmed.connect(_on_inventory_confirmed)
	inv.back_to_select.connect(_show_select)
	inv.equipment_requested.connect(_edit_equipment_from_survival.bind(data))
	add_child(inv)

func _edit_accessories_from_story(data: CharacterData) -> void:
	var username := str(_account.get("username", ""))
	_loadout_snapshot = {"ring_stash":RingStore.load_stash(username).duplicate(true), "rings":RingStore.load_equipped(username).duplicate(true), "artifact_stash":ArtifactStore.load_stash(username).duplicate(true), "artifacts":ArtifactStore.load_equipped(username).duplicate(true)}
	_clear_children(); var inv := INVENTORY_SCENE.instantiate(); inv.selected_character = data; inv.account_username = username; inv.accessory_edit_mode = true
	inv.edit_cancelled.connect(func() -> void: RingStore.replace_loadout(username, _loadout_snapshot.ring_stash, _loadout_snapshot.rings); ArtifactStore.replace_loadout(username, _loadout_snapshot.artifact_stash, _loadout_snapshot.artifacts); _show_story_inventory(data))
	inv.edit_applied.connect(func() -> void: _sync_cloud_progress(); _show_story_inventory(data))
	add_child(inv)

func _edit_equipment_from_survival(data: CharacterData) -> void:
	var username := str(_account.get("username", "")); _loadout_snapshot = {"story":StoryStore.cloud_snapshot(username), "progression":ProgressionStore.cloud_snapshot(username)}
	_clear_children(); var inv := STORY_INVENTORY_SCENE.instantiate(); inv.selected_character = data; inv.account_username = username; inv.equipment_edit_mode = true
	inv.edit_cancelled.connect(func() -> void: StoryStore.replace_profile(username, _loadout_snapshot.story); ProgressionStore.replace_profile(username, _loadout_snapshot.progression); _show_inventory(data))
	inv.edit_applied.connect(func() -> void: _sync_cloud_progress(); _show_inventory(data))
	add_child(inv)

func _on_inventory_confirmed(data: CharacterData) -> void:
	_start_match(data)

func _start_match(data: CharacterData) -> void:
	_clear_children()
	_play_music(BGM_DUNGEON_PATH, BGM_DUNGEON_VOLUME_DB)
	var m := MATCH_SCENE.instantiate()
	m.selected_player_character = data
	m.account_username     = String(_account.get("username", ""))
	m.account_cloud_id     = _cloud_username_for(_account)
	m.account_display_name = _profile_display_name_for(_account)
	m.story_stage = _story_stage.duplicate(true)
	m.is_story_test_run = _is_story_test_run and OS.is_debug_build()
	m.dungeon_mode = _dungeon_mode
	m.match_ended.connect(_on_match_ended)
	add_child(m)

func _on_match_ended(next_action: String) -> void:
	var username := str(_account.get("username", ""))
	if not _is_story_test_run:
		ArtifactStore.reconcile_loadout(username)
		_sync_cloud_progress()
	match next_action:
		"story":
			_show_story()
		"story_clear":
			_show_story(true)
		"story_test_retry":
			if OS.is_debug_build() and _is_story_test_run and not _story_test_stage_id.is_empty() and _last_character != null:
				_story_stage = StoryStore.stage(StoryStore.stage_index(_story_test_stage_id)).duplicate(true)
				_start_match(_last_character)
			else:
				push_warning("Story test retry rejected outside an active debug test run.")
				_show_story()
		"story_test_choose":
			_open_story_test_selector = true
			_show_story()
		"story_test_exit":
			_show_story()
		"dungeon":
			_show_lobby(true)
		"rematch":
			if _last_character != null:
				_start_match(_last_character)
			else:
				_show_select()
		"switch":
			_show_select()
		_:
			_show_lobby()

func _clear_children() -> void:
	for c in get_children():
		if c == _bgm_a or c == _bgm_b:
			continue
		c.queue_free()
