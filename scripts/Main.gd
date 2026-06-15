extends Node

## Top-level flow controller:
##   Login  →  Lobby  →  Character Select  →  Inventory  →  Match  →  Lobby

const LOGIN_SCENE := preload("res://scenes/Login.tscn")
const LOBBY_SCENE := preload("res://scenes/Lobby.tscn")
const SELECT_SCENE := preload("res://scenes/CharacterSelect.tscn")
const INVENTORY_SCENE := preload("res://scenes/Inventory.tscn")
const MATCH_SCENE := preload("res://scenes/Match.tscn")
const HISTORY_SCENE := preload("res://scenes/History.tscn")

const BGM_LOBBY_PATH:   String = "res://assets/sfx/bgm_lobby.mp3"
const BGM_DUNGEON_PATH: String = "res://assets/sfx/bgm_dungeon.mp3"
const BGM_FADE_TIME:    float  = 1.2   # crossfade duration in seconds

var _account: Dictionary = {}
var _last_character: CharacterData = null

# ── Music players ─────────────────────────────────────────────────────────────
var _bgm_a: AudioStreamPlayer = null
var _bgm_b: AudioStreamPlayer = null
var _bgm_fading: bool  = false
var _bgm_fade_t: float = 0.0
var _bgm_current_path: String = ""

func _ready() -> void:
	SettingsStore.apply.call_deferred(get_tree())
	_setup_music()
	_show_login()
	# Handle cold-start via capydungeon:// deep link (app launched by URL scheme)
	if OS.get_name() == "Android":
		call_deferred("_check_launch_deep_link")

func _check_launch_deep_link() -> void:
	var url := _read_android_deep_link()
	if not url.is_empty():
		_on_deep_link(url)

func _setup_music() -> void:
	_bgm_a = AudioStreamPlayer.new()
	_bgm_a.bus = "Master"
	add_child(_bgm_a)
	_bgm_b = AudioStreamPlayer.new()
	_bgm_b.bus = "Master"
	add_child(_bgm_b)

func _play_music(path: String) -> void:
	if path == _bgm_current_path:
		return
	_bgm_current_path = path
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	# Ensure looping regardless of import settings
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	# If nothing playing yet, start immediately
	if not _bgm_a.playing:
		_bgm_a.stream = stream
		_bgm_a.volume_db = 0.0
		_bgm_a.play()
		_bgm_b.stop()
		_bgm_fading = false
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

func _process(delta: float) -> void:
	if not _bgm_fading:
		return
	_bgm_fade_t += delta
	var t: float = clamp(_bgm_fade_t / BGM_FADE_TIME, 0.0, 1.0)
	_bgm_a.volume_db = linear_to_db(1.0 - t)
	_bgm_b.volume_db = linear_to_db(t)
	if t >= 1.0:
		_bgm_a.stop()
		# Swap so A is always the active player
		var tmp: AudioStreamPlayer = _bgm_a
		_bgm_a = _bgm_b
		_bgm_b = tmp
		_bgm_a.volume_db = 0.0
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

func _show_login() -> void:
	_account = {}
	_clear_children()
	_play_music(BGM_LOBBY_PATH)
	var login := LOGIN_SCENE.instantiate()
	login.logged_in.connect(_on_logged_in)
	add_child(login)

func _on_logged_in(account: Dictionary) -> void:
	_account = account
	var username: String = String(account.get("username", ""))
	if not username.is_empty():
		# Silently restore cloud-backed stats on login so history survives reinstalls.
		# Runs in background — lobby shows immediately; stats populate before user
		# can navigate to History.
		LeaderboardClient.fetch_user_stats(self, username, func(data: Dictionary) -> void:
			StatsStore.restore_from_server(username, data)
		)
	_show_lobby()

func _show_lobby() -> void:
	_clear_children()
	_play_music(BGM_LOBBY_PATH)
	var lobby := LOBBY_SCENE.instantiate()
	lobby.account = _account
	lobby.start_game_requested.connect(_show_select)
	lobby.history_requested.connect(_show_history)
	lobby.logout_requested.connect(_show_login)
	add_child(lobby)

func _show_history() -> void:
	_clear_children()
	var h := HISTORY_SCENE.instantiate()
	h.account = _account
	h.back_requested.connect(_show_lobby)
	add_child(h)

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
	_play_music(BGM_DUNGEON_PATH)
	var m := MATCH_SCENE.instantiate()
	m.selected_player_character = data
	m.account_username     = String(_account.get("username", ""))
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
