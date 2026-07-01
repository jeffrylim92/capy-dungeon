extends Node

## Top-level flow controller:
##   Login  →  Lobby  →  Character Select  →  Inventory  →  Match  →  Lobby

const LOGIN_SCENE := preload("res://scenes/Login.tscn")
const LOBBY_SCENE := preload("res://scenes/Lobby.tscn")
const SELECT_SCENE := preload("res://scenes/CharacterSelect.tscn")
const INVENTORY_SCENE := preload("res://scenes/Inventory.tscn")
const MATCH_SCENE := preload("res://scenes/Match.tscn")
const HISTORY_SCENE := preload("res://scenes/History.tscn")
const COLLECTIBLES_SCENE := preload("res://scenes/Collectibles.tscn")

const HEALTHCHECK_URL: String = "https://capy-dungeon.onrender.com/health"
const INTERNET_FALLBACK_URL: String = "https://www.google.com/generate_204"
const ANDROID_VERSION_CHECK_URL: String = "https://capy-dungeon.onrender.com/app/version/android"
const PLAY_STORE_URL_ANDROID: String = "https://play.google.com/store/apps/details?id=com.capydungeon.game"

const BGM_LOBBY_PATH:   String = "res://assets/sfx/bgm_lobby.mp3"
const BGM_DUNGEON_PATH: String = "res://assets/sfx/bgm_dungeon.mp3"
const BGM_FADE_TIME:    float  = 1.2   # crossfade duration in seconds
const BGM_LOBBY_VOLUME_DB: float = 0.0
const BGM_DUNGEON_VOLUME_DB: float = -14.0

var _account: Dictionary = {}
var _last_character: CharacterData = null

var _startup_gate_passed: bool = false
var _gate_mode: String = "none"
var _update_url_pending: String = PLAY_STORE_URL_ANDROID
var _gate_layer: CanvasLayer = null
var _gate_overlay: ColorRect = null
var _gate_panel: PanelContainer = null
var _gate_title: Label = null
var _gate_message: Label = null
var _gate_primary_btn: Button = null
var _gate_secondary_btn: Button = null
var _runtime_net_timer: Timer = null

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
	if _should_enforce_online_gate():
		_begin_startup_checks()
	else:
		_startup_gate_passed = true
		_show_login()
	# Handle cold-start via capydungeon:// deep link (app launched by URL scheme)
	if OS.get_name() == "Android":
		call_deferred("_check_launch_deep_link")
	_setup_runtime_network_timer()
	if _runtime_net_timer != null and _runtime_net_timer.is_stopped() and _should_enforce_online_gate():
		_runtime_net_timer.start()

func _should_enforce_online_gate() -> bool:
	# Always enforce on Android (including debug) so test behavior matches production.
	return OS.get_name() == "Android"

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
	if not _bgm_fading:
		return
	_bgm_fade_t += delta
	var t: float = clamp(_bgm_fade_t / BGM_FADE_TIME, 0.0, 1.0)
	_bgm_a.volume_db = _scaled_music_db(_bgm_active_volume_db, 1.0 - t)
	_bgm_b.volume_db = _scaled_music_db(_bgm_next_volume_db, t)
	if t >= 1.0:
		_bgm_a.stop()
		# Swap so A is always the active player
		var tmp: AudioStreamPlayer = _bgm_a
		_bgm_a = _bgm_b
		_bgm_b = tmp
		_bgm_active_volume_db = _bgm_next_volume_db
		_bgm_a.volume_db = _bgm_active_volume_db
		_bgm_fading = false

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
	var social_email: String = String(account.get("social_email", "")).strip_edges().to_lower()
	if not social_email.is_empty():
		return social_email
	return String(account.get("username", "")).strip_edges().to_lower()

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
	_show_gate_message("Checking internet", "Capy Dungeon requires an internet connection to start.", "Retry", "Quit")
	_check_online(func(online: bool) -> void:
		if not online:
			_gate_mode = "offline_startup"
			_show_gate_message("No internet connection", "Please connect to the internet to continue.", "Retry", "Quit")
			return
		_check_android_update(func(info: Dictionary) -> void:
			if not (info.get("checked", false) as bool):
				_gate_mode = "offline_startup"
				_show_gate_message("Could not verify app version", "Connect to the internet and retry so we can check for updates.", "Retry", "Quit")
				return
			var required: bool = info.get("required", false) as bool
			if required:
				_gate_mode = "force_update"
				_update_url_pending = String(info.get("url", PLAY_STORE_URL_ANDROID))
				_show_gate_message("Update required", String(info.get("message", "A newer app version is available. Please update to continue.")), "Open Play Store", "Quit")
				return
			_gate_mode = "none"
			_hide_gate()
			if not _startup_gate_passed:
				_startup_gate_passed = true
				_show_login()
			if _runtime_net_timer != null and _runtime_net_timer.is_stopped():
				_runtime_net_timer.start()
		)
	)

func _show_gate_message(title: String, message: String, primary_text: String, secondary_text: String) -> void:
	if _gate_layer == null:
		return
	_gate_title.text = title
	_gate_message.text = message
	_gate_primary_btn.text = primary_text
	_gate_secondary_btn.text = secondary_text
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
	_clear_children()
	_play_music(BGM_LOBBY_PATH, BGM_LOBBY_VOLUME_DB)
	var login := LOGIN_SCENE.instantiate()
	login.logged_in.connect(_on_logged_in)
	add_child(login)

func _on_logged_in(account: Dictionary) -> void:
	_account = account
	var username: String = String(account.get("username", "")).strip_edges()
	var cloud_username: String = _cloud_username_for(account)
	if not username.is_empty():
		PurchaseStore.set_username(username)
		_restore_cloud_progress_for_account(account)
		LeaderboardClient.submit_stats(self, cloud_username, String(account.get("display_name", username)))
	_show_lobby()

func _show_lobby() -> void:
	_clear_children()
	_play_music(BGM_LOBBY_PATH, BGM_LOBBY_VOLUME_DB)
	var lobby := LOBBY_SCENE.instantiate()
	lobby.account = _account
	lobby.start_game_requested.connect(_show_select)
	lobby.history_requested.connect(_show_history)
	lobby.collectibles_requested.connect(_show_collectibles)
	lobby.logout_requested.connect(_show_login)
	add_child(lobby)

func _show_collectibles() -> void:
	_clear_children()
	var c := COLLECTIBLES_SCENE.instantiate()
	c.account_username = String(_account.get("username", ""))
	c.back_requested.connect(_show_lobby)
	add_child(c)

func _show_history() -> void:
	var username: String = String(_account.get("username", "")).strip_edges()
	if username.is_empty():
		_clear_children()
		var h_local := HISTORY_SCENE.instantiate()
		h_local.account = _account
		h_local.back_requested.connect(_show_lobby)
		add_child(h_local)
		return
	_restore_cloud_progress_for_account(_account, func() -> void:
		_clear_children()
		var h := HISTORY_SCENE.instantiate()
		h.account = _account
		h.back_requested.connect(_show_lobby)
		add_child(h)
	)

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
				LeaderboardClient.submit_stats(self, cloud_username, String(account.get("display_name", username)))
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
	sel.back_to_menu.connect(_show_lobby)
	add_child(sel)

func _on_character_chosen(data: CharacterData) -> void:
	_last_character = data
	_show_inventory(data)

func _show_inventory(data: CharacterData) -> void:
	_clear_children()
	var inv := INVENTORY_SCENE.instantiate()
	inv.selected_character = data
	inv.account_username   = String(_account.get("username", ""))
	inv.inventory_confirmed.connect(_on_inventory_confirmed)
	inv.back_to_select.connect(_show_select)
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
	m.account_display_name = String(_account.get("display_name", _account.get("username", "")))
	m.match_ended.connect(_on_match_ended)
	add_child(m)

func _on_match_ended(next_action: String) -> void:
	match next_action:
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
