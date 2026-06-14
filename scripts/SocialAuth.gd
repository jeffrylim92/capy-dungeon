class_name SocialAuth
extends Node

## OAuth2 social authentication manager — desktop + mobile.
##
## ── Desktop flow (macOS / Windows / Linux) ────────────────────────────────
##   1. Call start(provider) — opens system browser at the provider's auth URL.
##   2. Provider redirects to http://localhost:18742/callback?code=…
##   3. A local TCPServer captures the code, exchanges it for a token,
##      then fetches the user profile.
##   4. Emits auth_success(provider, profile) or auth_failed(provider, error).
##
## ── Mobile flow (Android / iOS) ───────────────────────────────────────────
##   1. Call start(provider) — opens system browser at the provider's auth URL
##      with redirect_uri = "capydungeon://auth/callback".
##   2. Provider redirects the browser to capydungeon://auth/callback?code=…
##   3. The OS intercepts the custom scheme and brings Capy Dungeon to the
##      foreground.  Your platform bridge must then call:
##        SocialAuth.handle_deep_link("capydungeon://auth/callback?code=…")
##   4. SocialAuth exchanges the code and emits auth_success / auth_failed.
##
## ── Platform bridge setup ─────────────────────────────────────────────────
##
## Android (requires Gradle build — enable in export preset):
##   Add to android/build/AndroidManifest.xml inside the <activity> tag:
##     <intent-filter>
##       <action android:name="android.intent.action.VIEW"/>
##       <category android:name="android.intent.category.DEFAULT"/>
##       <category android:name="android.intent.category.BROWSABLE"/>
##       <data android:scheme="capydungeon" android:host="auth"/>
##     </intent-filter>
##   Then in Main.gd (or an autoload), wire the intent arrival to this node:
##     func _notification(what: int) -> void:
##       if what == NOTIFICATION_APPLICATION_FOCUS_IN:
##         var url := _read_android_intent_url()
##         if not url.is_empty():
##           SocialAuth.handle_deep_link(url)
##   Where _read_android_intent_url() uses JavaClassWrapper:
##     func _read_android_intent_url() -> String:
##       if not Engine.has_singleton("AndroidRuntime"):
##         return ""
##       var runtime = Engine.get_singleton("AndroidRuntime")
##       var activity = runtime.call("getActivity")
##       if not activity: return ""
##       var intent = activity.call("getIntent")
##       if not intent: return ""
##       var uri: String = intent.call("getDataString")
##       if uri.begins_with("capydungeon://"):
##         intent.call("setData", null)   # consume so we don't re-process
##         return uri
##       return ""
##
## iOS:
##   Project → Export → iOS → App Settings → Custom URL Scheme: "capydungeon"
##   In your Godot iOS plugin (or GDNative bridge), implement:
##     application:openURL:options: → GDScriptBridge.call("handle_deep_link", url)
##   e.g. via the godot-ios-plugins project's URL scheme handler.
##
## ── Google OAuth client type ───────────────────────────────────────────────
##   Desktop uses a "Desktop app" client (client_secret sent from client — OK
##   because it stays on-device).  For production mobile you should create a
##   separate "Android" / "iOS" client ID in the Google Cloud Console; those
##   client types use PKCE and require no client_secret.
##   Facebook likewise: use the "iOS" / "Android" platform in App Settings.
##
## ── Setup ─────────────────────────────────────────────────────────────────
##   Google  → console.cloud.google.com  (OAuth 2.0 Client ID)
##   Facebook→ developers.facebook.com   (App ID)

signal auth_success(provider: String, profile: Dictionary)
signal auth_failed(provider: String, error: String)

# ── Credentials are loaded at runtime from secrets/oauth_config.cfg ───────────
# Copy secrets/oauth_config.cfg.example to secrets/oauth_config.cfg and fill in
# your credentials. The secrets/ folder is gitignored.
const _SECRETS_PATH: String = "res://secrets/oauth_config.cfg"

# OAuth provider config (URLs only — credentials injected in _ready)
var OAUTH_CONFIG: Dictionary = {
	"google": {
		"client_id":     "",
		"client_secret": "",
		"auth_url":     "https://accounts.google.com/o/oauth2/v2/auth",
		"token_url":    "https://oauth2.googleapis.com/token",
		"scope":        "openid email profile",
		"userinfo_url": "https://openidconnect.googleapis.com/v1/userinfo",
	},
	"facebook": {
		"client_id":     "",
		"client_secret": "",
		"auth_url":      "https://www.facebook.com/v18.0/dialog/oauth",
		"token_url":     "https://graph.facebook.com/v18.0/oauth/access_token",
		"scope":         "email,public_profile",
		"userinfo_url":  "https://graph.facebook.com/me?fields=id,name,email",
	},
}

# Desktop: TCPServer listens on localhost for the OAuth redirect.
const REDIRECT_URI_DESKTOP: String = "http://localhost:18742/callback"
const CALLBACK_PORT:         int    = 18742

# Mobile: OS custom URL scheme — registered in AndroidManifest / iOS Info.plist.
# The system browser redirects here; the OS reopens the app; the platform
# bridge calls handle_deep_link(url) to hand off the code.
const REDIRECT_URI_MOBILE:  String = "capydungeon://auth/callback"

# Facebook relay server URL — set in secrets/oauth_config.cfg [relay] facebook_relay_url
var FACEBOOK_RELAY_URL: String = "https://capy-fb-relay.onrender.com"

# Maximum seconds to wait for the user to complete auth in the browser.
const MOBILE_AUTH_TIMEOUT:  float  = 300.0

# ── Runtime state ─────────────────────────────────────────────────────────────
var _server:           TCPServer   = null
var _http:             HTTPRequest = null
var _pending_provider: String      = ""
var _pending_state:    String      = ""
var _step:             String      = ""          # "token" | "userinfo"
var _mobile_waiting:   bool        = false
var _mobile_elapsed:   float       = 0.0
var _link_poll_timer:  float       = 0.0         # polls for deep link when app already has focus
var _using_relay:      bool        = false   # true when Facebook relay handles exchange
var _busy:             bool        = false   # true while an auth flow is in progress

func _ready() -> void:
	_load_secrets()
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_http_completed)
	# Reset busy flag whenever auth completes (success or failure)
	auth_success.connect(func(_p: String, _pr: Dictionary) -> void:
		DebugLog.log("[SocialAuth] auth_success emitted for provider=%s" % _p)
		_busy = false)
	auth_failed.connect(func(_p: String, _e: String) -> void:
		DebugLog.log("[SocialAuth] auth_failed emitted for provider=%s error=%s" % [_p, _e])
		_busy = false)

## SocialAuth handles its own Android deep-link so it doesn't depend on Main
## finding it via _find_social_auth.
func _notification(what: int) -> void:
	if not _mobile_waiting:
		return
	if OS.get_name() != "Android":
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		DebugLog.log("[SocialAuth] _notification: focus-in fired, _mobile_waiting=%s" % str(_mobile_waiting))
		var url := _read_own_deep_link()
		DebugLog.log("[SocialAuth] _notification: _read_own_deep_link returned '%s'" % url)
		if not url.is_empty():
			handle_deep_link(url)

func _read_own_deep_link() -> String:
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
		DebugLog.log("[SocialAuth] _read_own_deep_link: FOUND url='%s'" % uri)
		DebugLog.sticky = "LAST_URL: " + uri
		intent.call("setData", null)
		return uri
	DebugLog.log("[SocialAuth] _read_own_deep_link: unexpected URI='%s'" % uri)
	return ""

func _load_secrets() -> void:
	if not FileAccess.file_exists(_SECRETS_PATH):
		push_error("SocialAuth: secrets file not found at '%s'. Copy secrets/oauth_config.cfg.example to secrets/oauth_config.cfg and fill in your credentials." % _SECRETS_PATH)
		return
	var cfg := ConfigFile.new()
	var err := cfg.load(_SECRETS_PATH)
	if err != OK:
		push_error("SocialAuth: could not parse %s (err %d) — OAuth will not work" % [_SECRETS_PATH, err])
		return
	var google_dict: Dictionary = OAUTH_CONFIG["google"]
	google_dict["client_id"]     = cfg.get_value("google",   "client_id",     "")
	google_dict["client_secret"] = cfg.get_value("google",   "client_secret", "")
	google_dict["web_client_id"] = cfg.get_value("google",   "web_client_id", "")
	var fb_dict: Dictionary = OAUTH_CONFIG["facebook"]
	fb_dict["client_id"]     = cfg.get_value("facebook", "client_id",     "")
	fb_dict["client_secret"] = cfg.get_value("facebook", "client_secret", "")
	var relay: String = cfg.get_value("relay", "facebook_relay_url", FACEBOOK_RELAY_URL)
	if not relay.is_empty():
		FACEBOOK_RELAY_URL = relay
	print("SocialAuth: secrets loaded — google client_id=%s… facebook client_id=%s" % [
		(google_dict["client_id"] as String).left(12),
		(fb_dict["client_id"] as String).left(6),
	])

## Returns the list of providers to show on the current device.
## Facebook uses the relay server on mobile so it works on all platforms.
static func get_available_providers() -> Array[String]:
	return ["google", "facebook"]

static func _is_mobile() -> bool:
	var n := OS.get_name()
	return n == "Android" or n == "iOS"

func _active_redirect_uri() -> String:
	if _using_relay:
		match _pending_provider:
			"facebook": return FACEBOOK_RELAY_URL + "/fb/callback"
			"google":   return FACEBOOK_RELAY_URL + "/google/callback"
			_:          return FACEBOOK_RELAY_URL + "/" + _pending_provider + "/callback"
	return REDIRECT_URI_MOBILE if _is_mobile() else REDIRECT_URI_DESKTOP

## Begin the OAuth flow for a provider string ("google" | "facebook").
func start(provider: String) -> void:
	DebugLog.log("[SocialAuth] start() called: provider=%s _busy=%s _mobile_waiting=%s" % [provider, str(_busy), str(_mobile_waiting)])
	# Allow re-starting if the previous mobile flow is still waiting (user retrying).
	# In that case, reset state so a fresh flow begins.
	if _busy and _mobile_waiting:
		_mobile_waiting = false
		_mobile_elapsed = 0.0
		_busy = false
	if _busy:
		return   # a non-mobile flow (desktop TCP) is genuinely in progress
	if not OAUTH_CONFIG.has(provider):
		auth_failed.emit(provider, "Unknown provider: " + provider)
		return
	var cid: String = (OAUTH_CONFIG[provider] as Dictionary).get("client_id", "") as String
	if cid.is_empty():
		push_error("SocialAuth: %s client_id is empty — did you fill in secrets/oauth_config.cfg?" % provider)
		auth_failed.emit(provider, "App credentials not configured. Please check oauth_config.cfg.")
		return
	_busy             = true
	_pending_provider = provider
	_pending_state    = _random_state()
	_step             = "token"
	# On mobile: relay server handles code exchange and deep-links back for all providers
	_using_relay = _is_mobile()
	if _is_mobile():
		_mobile_waiting  = true
		_mobile_elapsed  = 0.0
		_link_poll_timer = 1.0
	else:
		_start_local_server()
	OS.shell_open(_build_auth_url(provider))

## Called by the platform bridge when the OS reopens the app via a deep link.
## e.g. from Main.gd's _notification(NOTIFICATION_APPLICATION_FOCUS_IN):
##   SocialAuth.handle_deep_link(url)
func handle_deep_link(url: String) -> void:
	DebugLog.log("[SocialAuth] handle_deep_link called: url='%s' _mobile_waiting=%s _pending_state=%s" % [url, str(_mobile_waiting), _pending_state])
	if not _mobile_waiting:
		DebugLog.log("[SocialAuth] handle_deep_link: ignoring — not waiting for mobile auth")
		return
	if not url.begins_with(REDIRECT_URI_MOBILE):
		DebugLog.log("[SocialAuth] handle_deep_link: WRONG URL='%s' expected prefix='%s'" % [url, REDIRECT_URI_MOBILE])
		DebugLog.sticky = "WRONG_URL: " + url
		_mobile_waiting = false
		_busy = false
		auth_failed.emit(_pending_provider, "Unexpected redirect URL — please try again")
		return
	_mobile_waiting = false
	_mobile_elapsed = 0.0
	var was_relay   := _using_relay
	_using_relay    = false
	var qs_idx := url.find("?")
	if qs_idx < 0:
		auth_failed.emit(_pending_provider, "Deep link missing query string")
		return
	var params := _parse_qs(url.substr(qs_idx + 1))
	if params.has("error"):
		auth_failed.emit(_pending_provider, String(params["error"]))
		return
	var got_state := String(params.get("state", ""))
	DebugLog.log("[SocialAuth] handle_deep_link: state check got='%s' expected='%s'" % [got_state, _pending_state])
	if got_state != _pending_state:
		push_error("SocialAuth state mismatch (deep link): got='%s' expected='%s'" % [got_state, _pending_state])
		auth_failed.emit(_pending_provider, "State mismatch — possible CSRF attack")
		return
	# Relay flow: profile data already included in the URL — no code exchange needed.
	DebugLog.log("[SocialAuth] handle_deep_link: was_relay=%s has_provider=%s" % [str(was_relay), str(params.has("provider"))])
	if was_relay and params.has("provider"):
		var profile: Dictionary = {
			"provider":     String(params.get("provider", _pending_provider)),
			"provider_id":  String(params.get("id",       "")),
			"email":        String(params.get("email",    "")),
			"display_name": String(params.get("name",    "Capy Player")),
			"avatar_url":   String(params.get("picture", "")),
		}
		if (profile["provider_id"] as String).is_empty():
			auth_failed.emit(_pending_provider, "Relay returned no user ID")
			return
		auth_success.emit(_pending_provider, profile)
		return
	# Standard code flow (Google mobile).
	if not params.has("code"):
		auth_failed.emit(_pending_provider, "Missing authorization code in deep link")
		return
	_exchange_code(String(params["code"]))

# ── Internal ──────────────────────────────────────────────────────────────────

func _build_auth_url(provider: String) -> String:
	var cfg: Dictionary = OAUTH_CONFIG[provider] as Dictionary
	# On mobile use the Web application client ID so the relay can exchange the code
	var cid: String = cfg["client_id"] as String
	if _using_relay and provider == "google":
		var web_id: String = cfg.get("web_client_id", "") as String
		if not web_id.is_empty():
			cid = web_id
	var params: Dictionary = {
		"client_id":     cid,
		"redirect_uri":  _active_redirect_uri(),
		"response_type": "code",
		"scope":         cfg["scope"] as String,
		"state":         _pending_state,
	}
	var qs: String = ""
	for key in params:
		if qs != "": qs += "&"
		qs += key + "=" + (params[key] as String).uri_encode()
	return (cfg["auth_url"] as String) + "?" + qs

func _start_local_server() -> void:
	_stop_server()
	_server = TCPServer.new()
	var err := _server.listen(CALLBACK_PORT, "127.0.0.1")
	if err != OK:
		push_warning("SocialAuth: could not bind to port %d (err %d). Is another instance running?" % [CALLBACK_PORT, err])
		_server = null

func _stop_server() -> void:
	if _server != null:
		_server.stop()
		_server = null

func _process(delta: float) -> void:
	# ── Mobile: timeout watchdog + deep-link poll ─────────────────────────────
	if _mobile_waiting:
		_mobile_elapsed += delta
		if _mobile_elapsed >= MOBILE_AUTH_TIMEOUT:
			_mobile_waiting = false
			auth_failed.emit(_pending_provider, "Authentication timed out")
			return
		# Poll the Android intent every ~1 s while waiting. Covers the case where
		# the deep-link intent arrives while the app is already in the foreground
		# (e.g. the user manually switched back before the relay responded), so no
		# NOTIFICATION_APPLICATION_FOCUS_IN fires to trigger _read_own_deep_link.
		if OS.get_name() == "Android":
			_link_poll_timer -= delta
			if _link_poll_timer <= 0.0:
				_link_poll_timer = 1.0
				var url := _read_own_deep_link()
				if not url.is_empty():
					handle_deep_link(url)
		return

	# ── Desktop: TCPServer poll ───────────────────────────────────────────────
	if _server == null or not _server.is_listening():
		return
	if not _server.is_connection_available():
		return
	var conn := _server.take_connection()
	if conn != null:
		_handle_callback_connection(conn)

func _handle_callback_connection(conn: StreamPeerTCP) -> void:
	var raw := PackedByteArray()
	var frames: int = 0
	while frames < 60:   # up to ~1s at 60fps — no OS.delay_msec, no freeze
		conn.poll()
		if conn.get_available_bytes() > 0:
			var chunk: Array = conn.get_data(conn.get_available_bytes())
			if chunk[0] == OK:
				raw.append_array(chunk[1] as PackedByteArray)
		if raw.get_string_from_utf8().contains("\r\n\r\n"):
			break
		await get_tree().process_frame
		frames += 1

	_stop_server()

	# Reply with a page that auto-closes itself after 1 second
	var html := "<!DOCTYPE html><html><head><meta charset='utf-8'>" \
		+ "<script>setTimeout(function(){window.close();},1000);</script></head>" \
		+ "<body style='font-family:sans-serif;text-align:center;padding:80px;background:#1a1a2e;color:#eee'>" \
		+ "<h2 style='color:#4ade80'>&#10003; Signed in!</h2>" \
		+ "<p style='color:#aaa'>You can close this tab and return to Capy Dungeon.</p>" \
		+ "</body></html>"
	var reply := "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\n" \
		+ "Content-Length: %d\r\nConnection: close\r\n\r\n%s" % [html.to_utf8_buffer().size(), html]
	conn.put_data(reply.to_utf8_buffer())
	await get_tree().process_frame
	conn.disconnect_from_host()

	# Bring game window to front
	if not _is_mobile():
		get_window().grab_focus()

	# Parse the query string from the GET request line
	var request_text := raw.get_string_from_utf8()
	var first_line   := request_text.split("\r\n")[0]       # "GET /callback?code=... HTTP/1.1"
	var parts        := first_line.split(" ")
	if parts.size() < 2:
		auth_failed.emit(_pending_provider, "Malformed callback request")
		return
	var path: String = parts[1]
	var qs_idx: int  = path.find("?")
	if qs_idx < 0:
		auth_failed.emit(_pending_provider, "No query string in callback")
		return

	var params := _parse_qs(path.substr(qs_idx + 1))

	if params.has("error"):
		auth_failed.emit(_pending_provider, String(params["error"]))
		return
	if not params.has("code"):
		auth_failed.emit(_pending_provider, "Missing authorization code")
		return
	if String(params.get("state", "")) != _pending_state:
		push_error("SocialAuth state mismatch (desktop): got='%s' expected='%s'" % [
			String(params.get("state", "")), _pending_state])
		auth_failed.emit(_pending_provider, "State mismatch — possible CSRF attack")
		return

	_exchange_code(String(params["code"]))

func _exchange_code(code: String) -> void:
	var cfg: Dictionary = OAUTH_CONFIG[_pending_provider] as Dictionary
	var secret: String = cfg.get("client_secret", "") as String
	var body := "grant_type=authorization_code" \
		+ "&code="         + code.uri_encode() \
		+ "&redirect_uri=" + _active_redirect_uri().uri_encode() \
		+ "&client_id="    + (cfg["client_id"] as String).uri_encode() \
		+ ("&client_secret=" + secret.uri_encode() if secret != "" else "")
	var headers: PackedStringArray = PackedStringArray(["Content-Type: application/x-www-form-urlencoded"])
	_step = "token"
	var err := _http.request(cfg["token_url"] as String, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		auth_failed.emit(_pending_provider, "Token request error: %d" % err)

func _on_http_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or (response_code < 200 or response_code >= 300):
		auth_failed.emit(_pending_provider, "HTTP %d (result %d) during step '%s'" % [response_code, result, _step])
		return

	var json: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(json) != TYPE_DICTIONARY:
		auth_failed.emit(_pending_provider, "Non-JSON response during step '%s'" % _step)
		return
	var data: Dictionary = json as Dictionary

	if _step == "token":
		# Received token response — fetch user info (or parse id_token for Apple)
		if not data.has("access_token"):
			auth_failed.emit(_pending_provider, "No access_token in token response")
			return
		_step = "userinfo"
		_fetch_userinfo(data["access_token"] as String, String(data.get("id_token", "")))
	else:
		# Received user-info response
		_handle_profile(data)

func _fetch_userinfo(access_token: String, id_token: String) -> void:
	var cfg: Dictionary = OAUTH_CONFIG[_pending_provider] as Dictionary
	var userinfo_url: String = cfg["userinfo_url"] as String

	if userinfo_url.is_empty():
		auth_failed.emit(_pending_provider, "No userinfo URL configured for this provider")
		return

	var headers: PackedStringArray = PackedStringArray(["Authorization: Bearer " + access_token])
	var err := _http.request(userinfo_url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		auth_failed.emit(_pending_provider, "Userinfo request error: %d" % err)

func _handle_profile(raw: Dictionary) -> void:
	# Normalise field names across providers
	var pid: String   = String(raw.get("sub", raw.get("id", "")))
	var email: String = String(raw.get("email", ""))
	var name_val: String = String(raw.get("name", raw.get("given_name", email)))
	if name_val.is_empty():
		name_val = "Capy Player"
	if pid.is_empty():
		auth_failed.emit(_pending_provider, "Provider returned no user ID")
		return
	var profile: Dictionary = {
		"provider":      _pending_provider,
		"provider_id":   pid,
		"email":         email,
		"display_name":  name_val,
		"avatar_url":    String(raw.get("picture", "")),
	}
	auth_success.emit(_pending_provider, profile)

# ── Helpers ───────────────────────────────────────────────────────────────────

static func _random_state() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return "%08x%08x" % [rng.randi(), rng.randi()]

static func _parse_qs(qs: String) -> Dictionary:
	var result: Dictionary = {}
	for part in qs.split("&", false):
		# maxsplit=1 ensures values containing "=" (e.g. base64 auth codes) are preserved
		var kv := part.split("=", true, 1)
		if kv.size() == 2:
			result[kv[0]] = kv[1].uri_decode()
		elif kv.size() == 1 and kv[0] != "":
			result[kv[0]] = ""
	return result
