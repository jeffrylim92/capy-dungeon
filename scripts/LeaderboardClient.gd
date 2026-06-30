class_name LeaderboardClient
extends RefCounted

## Thin HTTP client for the Capy Dungeon leaderboard API.
## All methods are static — pass a live Node as `host` so HTTPRequest has a parent.

const BASE_URL := "https://capy-dungeon.onrender.com"
const GLOBAL_LIMIT_ALL := 0

## Submit the calling user's cumulative stats after each match.
## Fire-and-forget: errors are logged but not surfaced.
static func submit_stats(host: Node, username: String, display_name: String) -> void:
	if username.is_empty():
		return
	var all := StatsStore.get_all_for_user(username)
	if all.is_empty():
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

	var body := JSON.stringify({
		"username":              username,
		"display_name":          display_name,
		"total_kills":           best_character_kills,
		"best_survive_seconds":  best_survive,
		"best_kill_character":   best_kill_char,
		"best_survive_character": best_survive_char,
		"stats_json":            StatsStore.get_all_for_user(username),
		"rings_json":            RingStore.load_equipped(username),
	})

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

## Fetch the cloud-backed stats for a user. `callback` receives a Dictionary
## (the per-character stats dict from StatsStore) or {} on failure.
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
			callback.call(parsed.get("stats", {}) as Dictionary)
	)
	var err := http.request(BASE_URL + "/stats/user/" + username.to_lower())
	if err != OK:
		http.queue_free()
		callback.call({})

## Fetch the global kill leaderboard. `callback` receives Array of entry dicts:
##   { rank, display_name, value (int kills), character (id string) }
static func fetch_kills(host: Node, callback: Callable) -> void:
	_fetch_payload(host, BASE_URL + "/stats/leaderboard/kills", func(payload: Dictionary) -> void:
		callback.call(payload.get("entries", []) as Array)
	)

## Fetch the global kill leaderboard plus this user's own best rank.
## `callback` receives { entries: Array, user_entry: Dictionary/null }.
static func fetch_kills_with_user(host: Node, username: String, callback: Callable) -> void:
	_fetch_payload(host, _leaderboard_url("kills", username, GLOBAL_LIMIT_ALL), callback)

## Fetch the global survive leaderboard. `callback` receives Array of entry dicts:
##   { rank, display_name, value (float seconds), character (id string) }
static func fetch_survive(host: Node, callback: Callable) -> void:
	_fetch_payload(host, BASE_URL + "/stats/leaderboard/survive", func(payload: Dictionary) -> void:
		callback.call(payload.get("entries", []) as Array)
	)

## Fetch the global survive leaderboard plus this user's own best rank.
## `callback` receives { entries: Array, user_entry: Dictionary/null }.
static func fetch_survive_with_user(host: Node, username: String, callback: Callable) -> void:
	_fetch_payload(host, _leaderboard_url("survive", username, GLOBAL_LIMIT_ALL), callback)

static func _leaderboard_url(kind: String, username: String, limit: int = GLOBAL_LIMIT_ALL) -> String:
	var url := BASE_URL + "/stats/leaderboard/" + kind
	var query: PackedStringArray = []
	if not username.is_empty():
		query.append("username=" + username.to_lower().uri_encode())
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
				callback.call({"entries": [], "user_entry": null})
				return
			var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
			if typeof(parsed) == TYPE_ARRAY:
				callback.call({"entries": parsed as Array, "user_entry": null})
				return
			if typeof(parsed) != TYPE_DICTIONARY:
				callback.call({"entries": [], "user_entry": null})
				return
			callback.call(parsed as Dictionary)
	)
	var err := http.request(url)
	if err != OK:
		DebugLog.log("[LeaderboardClient] fetch failed to start: %d" % err)
		http.queue_free()
		callback.call({"entries": [], "user_entry": null})
