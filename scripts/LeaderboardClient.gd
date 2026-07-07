class_name LeaderboardClient
extends RefCounted

## Thin HTTP client for the Capy Dungeon leaderboard API.
## All methods are static — pass a live Node as `host` so HTTPRequest has a parent.

const BASE_URL := "https://capy-dungeon.onrender.com"
const GLOBAL_LIMIT_ALL := 0
const GLOBAL_LIMIT_TOP20 := 20

## Submit the calling user's cumulative stats after each match.
## Fire-and-forget: errors are logged but not surfaced.
static func submit_stats(host: Node, username: String, display_name: String, stats_username: String = "", latest_match: Dictionary = {}) -> void:
	if username.is_empty():
		return
	var source_username: String = stats_username.strip_edges()
	if source_username.is_empty():
		source_username = username
	var all := StatsStore.get_all_for_user(source_username)
	if all.is_empty():
		DebugLog.log("[LeaderboardClient] submit skipped: no stats for source '%s'" % source_username)
		return

	var best_character_kills: int = 0
	var best_survive: float = 0.0
	var best_kill_char: String    = ""
	var best_survive_char: String = ""

	for cid in all:
		var e: Dictionary = all[cid] as Dictionary
		var kills:   int   = int(e.get("total_kills", 0))
		var survive: float = float(e.get("best_survive_seconds", 0.0))
		if kills > best_character_kills:
			best_character_kills = kills
			best_kill_char = cid
		if survive > best_survive:
			best_survive = survive
			best_survive_char = cid

	var body_payload: Dictionary = {
		"username":              username,
		"display_name":          display_name,
		"total_kills":           best_character_kills,
		"best_survive_seconds":  best_survive,
		"best_kill_character":   best_kill_char,
		"best_survive_character": best_survive_char,
		"stats_json":            StatsStore.get_all_for_user(source_username),
			"rings_json":            RingStore.load_equipped(source_username),
			"ring_stash_json":       RingStore.load_stash(source_username),
			"artifact_stash_json":   ArtifactStore.load_stash(source_username),
			"artifact_equipped_json": ArtifactStore.load_equipped(source_username),
	}
	if not latest_match.is_empty():
		body_payload["latest_match"] = latest_match
	var body := JSON.stringify(body_payload)

	var http := HTTPRequest.new()
	host.add_child(http)
	http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())
	var err := http.request(
		BASE_URL + "/stats/submit",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST, body
	)
	if err != OK:
		DebugLog.log("[LeaderboardClient] submit failed to start: %d" % err)
		http.queue_free()

## Fetch cloud-backed progress for a user.
## `callback` receives a Dictionary with keys:
##   stats, rings_equipped, ring_stash, artifact_stash, artifact_equipped
## or {} on failure.
static func fetch_user_stats(host: Node, username: String, callback: Callable) -> void:
	if username.is_empty():
		callback.call({})
		return
	var http := HTTPRequest.new()
	host.add_child(http)
	http.request_completed.connect(
		func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
			http.queue_free()
			if result != HTTPRequest.RESULT_SUCCESS or code != 200:
				callback.call({})
				return
			var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
			if typeof(parsed) != TYPE_DICTIONARY:
				callback.call({})
				return
			var payload: Dictionary = parsed as Dictionary
			callback.call({
				"stats": payload.get("stats", {}) as Dictionary,
				"rings_equipped": payload.get("rings_json", {}) as Dictionary,
				"ring_stash": payload.get("ring_stash", []) as Array,
				"artifact_stash": payload.get("artifact_stash", []) as Array,
				"artifact_equipped": payload.get("artifact_equipped", {}) as Dictionary,
			})
	)
	var err := http.request(BASE_URL + "/stats/user/" + username.to_lower())
	if err != OK:
		http.queue_free()
		callback.call({})

## Delete this user's cloud account data.
## callback receives { ok: bool, deleted: int, error: String }.
static func delete_account(host: Node, username: String, social_email: String, callback: Callable) -> void:
	var key: String = username.strip_edges().to_lower()
	if key.is_empty():
		callback.call({"ok": false, "deleted": 0, "error": "missing username"})
		return
	var payload: Dictionary = {"username": key}
	var email_key: String = social_email.strip_edges().to_lower()
	if not email_key.is_empty():
		payload["social_email"] = email_key
	var http := HTTPRequest.new()
	host.add_child(http)
	http.request_completed.connect(
		func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
			http.queue_free()
			if result != HTTPRequest.RESULT_SUCCESS or code != 200:
				callback.call({"ok": false, "deleted": 0, "error": "request failed"})
				return
			var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
			if typeof(parsed) != TYPE_DICTIONARY:
				callback.call({"ok": false, "deleted": 0, "error": "invalid response"})
				return
			callback.call(parsed as Dictionary)
	)
	var err := http.request(
		BASE_URL + "/account/delete",
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	if err != OK:
		http.queue_free()
		callback.call({"ok": false, "deleted": 0, "error": "request start failed"})

## Fetch the global kill leaderboard.
## `callback` receives { entries:Array, user_entry:Dictionary/null, ok:bool }.
static func fetch_kills(host: Node, callback: Callable, limit: int = GLOBAL_LIMIT_TOP20, character: String = "") -> void:
	_fetch_payload(host, _leaderboard_url("kills", "", limit, character), callback)

## Fetch the global kill leaderboard plus this user's own best rank.
## `callback` receives { entries: Array, user_entry: Dictionary/null }.
static func fetch_kills_with_user(host: Node, username: String, callback: Callable, limit: int = GLOBAL_LIMIT_TOP20, character: String = "") -> void:
	_fetch_payload(host, _leaderboard_url("kills", username, limit, character), callback)

## Fetch the global survive leaderboard.
## `callback` receives { entries:Array, user_entry:Dictionary/null, ok:bool }.
static func fetch_survive(host: Node, callback: Callable, limit: int = GLOBAL_LIMIT_TOP20, character: String = "") -> void:
	_fetch_payload(host, _leaderboard_url("survive", "", limit, character), callback)

## Fetch the global survive leaderboard plus this user's own best rank.
## `callback` receives { entries: Array, user_entry: Dictionary/null }.
static func fetch_survive_with_user(host: Node, username: String, callback: Callable, limit: int = GLOBAL_LIMIT_TOP20, character: String = "") -> void:
	_fetch_payload(host, _leaderboard_url("survive", username, limit, character), callback)

## Fetch the global furthest-wave leaderboard.
## `callback` receives { entries:Array, user_entry:Dictionary/null, ok:bool }.
static func fetch_wave(host: Node, callback: Callable, limit: int = GLOBAL_LIMIT_TOP20, character: String = "") -> void:
	_fetch_payload(host, _leaderboard_url("wave", "", limit, character), callback)

## Fetch the global furthest-wave leaderboard plus this user's own best rank.
## `callback` receives { entries: Array, user_entry: Dictionary/null }.
static func fetch_wave_with_user(host: Node, username: String, callback: Callable, limit: int = GLOBAL_LIMIT_TOP20, character: String = "") -> void:
	_fetch_payload(host, _leaderboard_url("wave", username, limit, character), callback)

static func _leaderboard_url(kind: String, username: String, limit: int = GLOBAL_LIMIT_ALL, character: String = "") -> String:
	var url := BASE_URL + "/stats/leaderboard/" + kind
	var query: PackedStringArray = []
	if not username.is_empty():
		query.append("username=" + username.to_lower().uri_encode())
	if not character.is_empty():
		query.append("character=" + character.strip_edges().to_lower().uri_encode())
	if limit != GLOBAL_LIMIT_ALL:
		query.append("limit=" + str(limit))
	if query.size() > 0:
		url += "?" + "&".join(query)
	return url

static func _fetch_payload(host: Node, url: String, callback: Callable) -> void:
	var http := HTTPRequest.new()
	host.add_child(http)
	http.request_completed.connect(
		func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
			http.queue_free()
			if result != HTTPRequest.RESULT_SUCCESS or code != 200:
				DebugLog.log("[LeaderboardClient] fetch error result=%d code=%d" % [result, code])
				callback.call({"entries": [], "user_entry": null, "ok": false})
				return
			var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
			if typeof(parsed) == TYPE_ARRAY:
				callback.call({"entries": parsed as Array, "user_entry": null, "ok": true})
				return
			if typeof(parsed) != TYPE_DICTIONARY:
				callback.call({"entries": [], "user_entry": null, "ok": false})
				return
			var payload: Dictionary = parsed as Dictionary
			payload["ok"] = true
			callback.call(payload)
	)
	var err := http.request(url)
	if err != OK:
		DebugLog.log("[LeaderboardClient] fetch failed to start: %d" % err)
		http.queue_free()
		callback.call({"entries": [], "user_entry": null, "ok": false})
