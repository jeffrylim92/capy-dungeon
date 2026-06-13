extends Node

## Top-level flow controller:
##   Login  →  Lobby  →  Character Select  →  Inventory  →  Match  →  Lobby

const LOGIN_SCENE := preload("res://scenes/Login.tscn")
const LOBBY_SCENE := preload("res://scenes/Lobby.tscn")
const SELECT_SCENE := preload("res://scenes/CharacterSelect.tscn")
const INVENTORY_SCENE := preload("res://scenes/Inventory.tscn")
const MATCH_SCENE := preload("res://scenes/Match.tscn")
const HISTORY_SCENE := preload("res://scenes/History.tscn")

var _account: Dictionary = {}
var _last_character: CharacterData = null

func _ready() -> void:
	SettingsStore.apply.call_deferred(get_tree())
	_show_login()

## Called by the OS when the app is (re)opened via a capydungeon:// deep link.
## Wire this up from your platform bridge:
##   Android — in _notification(NOTIFICATION_APPLICATION_FOCUS_IN):
##     var url := _read_android_deep_link()
##     if not url.is_empty(): _on_deep_link(url)
##   iOS — in your Godot iOS plugin's URL-opened callback:
##     Main._on_deep_link(url_string)
func _on_deep_link(url: String) -> void:
	if url.begins_with("capydungeon://auth/"):
		# Forward to whichever SocialAuth node is currently active.
		var auth_node := _find_social_auth()
		if auth_node:
			auth_node.handle_deep_link(url)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and OS.get_name() == "Android":
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
	var uri: String = str(intent.call("getDataString"))
	if uri.begins_with("capydungeon://"):
		intent.call("setData", null)   # consume — prevents reprocessing on resume
		return uri
	return ""

func _find_social_auth() -> SocialAuth:
	for child in get_children():
		var auth := child.get_node_or_null("SocialAuth") as SocialAuth
		if auth:
			return auth
		if child is SocialAuth:
			return child as SocialAuth
	return null

func _show_login() -> void:
	_account = {}
	_clear_children()
	var login := LOGIN_SCENE.instantiate()
	login.logged_in.connect(_on_logged_in)
	add_child(login)

func _on_logged_in(account: Dictionary) -> void:
	_account = account
	_show_lobby()

func _show_lobby() -> void:
	_clear_children()
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
	var m := MATCH_SCENE.instantiate()
	m.selected_player_character = data
	m.account_username = String(_account.get("username", ""))
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
		c.queue_free()
