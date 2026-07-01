class_name StatsStore
extends RefCounted

## Per-account, per-character match stats persisted to user://stats.json.
## Structure:
##   { <username_lower>: { <character_id>: {matches, wins, losses, draws,
##       best_combo, fastest_win_seconds, finishers_unleashed,
##       total_play_time_seconds, last_played_at } } }

const PATH := "user://stats.json"

const OUTCOME_WIN := "win"
const OUTCOME_LOSS := "loss"
const OUTCOME_DRAW := "draw"

static func _load_all() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

static func _save_all(data: Dictionary) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

static func _blank_entry() -> Dictionary:
	return {
		"matches": 0,
		"wins": 0,
		"losses": 0,
		"draws": 0,
		"best_combo": 0,
		"fastest_win_seconds": 0.0,
		"finishers_unleashed": 0,
		"total_play_time_seconds": 0.0,
		"last_played_at": "",
		"total_kills": 0,
		"best_survive_seconds": 0.0,
		"survive_5min_count": 0,
	}

static func get_for(username: String, character_id: String) -> Dictionary:
	var key := username.to_lower()
	var data := _load_all()
	if not data.has(key):
		return _blank_entry()
	var per_char: Dictionary = data[key]
	if not per_char.has(character_id):
		return _blank_entry()
	var merged := _blank_entry()
	for k in per_char[character_id]:
		merged[k] = per_char[character_id][k]
	return merged

static func get_all_for_user(username: String) -> Dictionary:
	var key := username.to_lower()
	var data := _load_all()
	return data.get(key, {}) as Dictionary

static func reset_user(username: String) -> void:
	var key := username.to_lower()
	var data := _load_all()
	if data.has(key):
		data.erase(key)
		_save_all(data)

static func record_match(username: String, character_id: String, outcome: String, best_combo: int, elapsed_seconds: float, finishers: int, kills: int = 0) -> void:
	if username.is_empty() or character_id.is_empty():
		return
	var key := username.to_lower()
	var data := _load_all()
	if not data.has(key):
		data[key] = {}
	var per_char: Dictionary = data[key]
	var entry: Dictionary = per_char.get(character_id, _blank_entry())
	# Merge any missing default keys (forward compat).
	for k in _blank_entry():
		if not entry.has(k):
			entry[k] = _blank_entry()[k]
	entry["matches"] = int(entry["matches"]) + 1
	match outcome:
		OUTCOME_WIN:
			entry["wins"] = int(entry["wins"]) + 1
			var prev_fast: float = float(entry["fastest_win_seconds"])
			if prev_fast <= 0.0 or elapsed_seconds < prev_fast:
				entry["fastest_win_seconds"] = elapsed_seconds
		OUTCOME_LOSS:
			entry["losses"] = int(entry["losses"]) + 1
		OUTCOME_DRAW:
			entry["draws"] = int(entry["draws"]) + 1
	if best_combo > int(entry["best_combo"]):
		entry["best_combo"] = best_combo
	entry["finishers_unleashed"] = int(entry["finishers_unleashed"]) + finishers
	entry["total_play_time_seconds"] = float(entry["total_play_time_seconds"]) + elapsed_seconds
	entry["total_kills"] = int(entry.get("total_kills", 0)) + kills
	if elapsed_seconds > float(entry.get("best_survive_seconds", 0.0)):
		entry["best_survive_seconds"] = elapsed_seconds
	if elapsed_seconds >= 300.0:
		entry["survive_5min_count"] = int(entry.get("survive_5min_count", 0)) + 1
	entry["last_played_at"] = Time.get_datetime_string_from_system(true)
	per_char[character_id] = entry
	data[key] = per_char
	_save_all(data)

static func record_match_detail(username: String, character_id: String, kills: int, elapsed_seconds: float, rings: Dictionary, artifacts: Dictionary) -> void:
	if username.is_empty() or character_id.is_empty():
		return
	var key: String = username.to_lower()
	var path: String = "user://match_records_%s.json" % key
	var records: Array = []
	if FileAccess.file_exists(path):
		var rf := FileAccess.open(path, FileAccess.READ)
		if rf != null:
			var parsed: Variant = JSON.parse_string(rf.get_as_text())
			rf.close()
			if parsed is Array:
				records = parsed as Array
	records.append({
		"ts": int(Time.get_unix_time_from_system()),
		"character": character_id,
		"kills": kills,
		"survive_seconds": elapsed_seconds,
		"rings": rings.duplicate(true),
		"artifacts": artifacts.duplicate(true),
	})
	while records.size() > 200:
		records.remove_at(0)
	var wf := FileAccess.open(path, FileAccess.WRITE)
	if wf == null:
		return
	wf.store_string(JSON.stringify(records, "\t"))
	wf.close()

static func get_recent_match_records(username: String, limit: int = 30) -> Array:
	if username.is_empty():
		return []
	var path: String = "user://match_records_%s.json" % username.to_lower()
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Array:
		var src: Array = parsed as Array
		var out: Array = []
		for i in range(src.size() - 1, -1, -1):
			out.append(src[i])
			if out.size() >= max(limit, 1):
				break
		return out
	return []

static func format_seconds(s: float) -> String:
	if s <= 0.0:
		return "—"
	var total: int = int(round(s))
	var mins: int = int(total / 60.0)
	var secs: int = total - mins * 60
	return "%d:%02d" % [mins, secs]

static func win_rate(entry: Dictionary) -> float:
	var matches: int = int(entry.get("matches", 0))
	if matches <= 0:
		return 0.0
	return float(int(entry.get("wins", 0))) / float(matches)
## Returns how many qualifying (5+ min) runs each unlock-required character has,
## capped at the required 3. Keys: capy_zoomer, capy_chef, capy_swamp.
static func get_brown_unlock_progress(username: String) -> Dictionary:
	var key := username.to_lower()
	var data := _load_all()
	var per_char: Dictionary = data.get(key, {}) as Dictionary
	var result: Dictionary = {}
	for cid in ["capy_zoomer", "capy_chef", "capy_swamp"]:
		var entry: Dictionary = per_char.get(cid, _blank_entry())
		result[cid] = mini(int(entry.get("survive_5min_count", 0)), 3)
	return result

## Restore stats from a server backup if no local data exists for this user.
## Called on login/history-open. Merges server values into local data.
static func restore_from_server(username: String, server_per_char: Dictionary) -> void:
	if server_per_char.is_empty():
		return
	var key := username.to_lower()
	var data := _load_all()
	var local_char: Dictionary = data.get(key, {}) as Dictionary
	for char_id_variant in server_per_char.keys():
		var char_id: String = String(char_id_variant)
		var srv: Dictionary = server_per_char.get(char_id, {}) as Dictionary
		if srv.is_empty():
			continue
		var dst: Dictionary = local_char.get(char_id, _blank_entry()) as Dictionary
		for default_key in _blank_entry().keys():
			if not dst.has(default_key):
				dst[default_key] = _blank_entry()[default_key]
		dst["matches"] = maxi(int(dst.get("matches", 0)), int(srv.get("matches", 0)))
		dst["wins"] = maxi(int(dst.get("wins", 0)), int(srv.get("wins", 0)))
		dst["losses"] = maxi(int(dst.get("losses", 0)), int(srv.get("losses", 0)))
		dst["draws"] = maxi(int(dst.get("draws", 0)), int(srv.get("draws", 0)))
		dst["best_combo"] = maxi(int(dst.get("best_combo", 0)), int(srv.get("best_combo", 0)))
		var dst_fast: float = float(dst.get("fastest_win_seconds", 0.0))
		var srv_fast: float = float(srv.get("fastest_win_seconds", 0.0))
		if dst_fast <= 0.0:
			dst["fastest_win_seconds"] = srv_fast
		elif srv_fast > 0.0:
			dst["fastest_win_seconds"] = min(dst_fast, srv_fast)
		dst["finishers_unleashed"] = maxi(int(dst.get("finishers_unleashed", 0)), int(srv.get("finishers_unleashed", 0)))
		dst["total_play_time_seconds"] = max(float(dst.get("total_play_time_seconds", 0.0)), float(srv.get("total_play_time_seconds", 0.0)))
		dst["total_kills"] = maxi(int(dst.get("total_kills", 0)), int(srv.get("total_kills", 0)))
		dst["best_survive_seconds"] = max(float(dst.get("best_survive_seconds", 0.0)), float(srv.get("best_survive_seconds", 0.0)))
		dst["survive_5min_count"] = maxi(int(dst.get("survive_5min_count", 0)), int(srv.get("survive_5min_count", 0)))
		var dst_played: String = String(dst.get("last_played_at", ""))
		var srv_played: String = String(srv.get("last_played_at", ""))
		if srv_played > dst_played:
			dst["last_played_at"] = srv_played
		local_char[char_id] = dst
	data[key] = local_char
	_save_all(data)

static func merge_user_local_data(into_username: String, from_username: String) -> void:
	var into_key := into_username.strip_edges().to_lower()
	var from_key := from_username.strip_edges().to_lower()
	if into_key.is_empty() or from_key.is_empty() or into_key == from_key:
		return
	var data := _load_all()
	var from_per_char: Dictionary = data.get(from_key, {}) as Dictionary
	if not from_per_char.is_empty():
		var into_per_char: Dictionary = data.get(into_key, {}) as Dictionary
		for char_id_variant in from_per_char.keys():
			var char_id: String = String(char_id_variant)
			var src_entry: Dictionary = from_per_char.get(char_id, {}) as Dictionary
			var dst_entry: Dictionary = into_per_char.get(char_id, _blank_entry()) as Dictionary
			for default_key in _blank_entry().keys():
				if not dst_entry.has(default_key):
					dst_entry[default_key] = _blank_entry()[default_key]
			dst_entry["matches"] = int(dst_entry.get("matches", 0)) + int(src_entry.get("matches", 0))
			dst_entry["wins"] = int(dst_entry.get("wins", 0)) + int(src_entry.get("wins", 0))
			dst_entry["losses"] = int(dst_entry.get("losses", 0)) + int(src_entry.get("losses", 0))
			dst_entry["draws"] = int(dst_entry.get("draws", 0)) + int(src_entry.get("draws", 0))
			dst_entry["best_combo"] = maxi(int(dst_entry.get("best_combo", 0)), int(src_entry.get("best_combo", 0)))
			var dst_fast: float = float(dst_entry.get("fastest_win_seconds", 0.0))
			var src_fast: float = float(src_entry.get("fastest_win_seconds", 0.0))
			if dst_fast <= 0.0:
				dst_entry["fastest_win_seconds"] = src_fast
			elif src_fast > 0.0:
				dst_entry["fastest_win_seconds"] = min(dst_fast, src_fast)
			dst_entry["finishers_unleashed"] = int(dst_entry.get("finishers_unleashed", 0)) + int(src_entry.get("finishers_unleashed", 0))
			dst_entry["total_play_time_seconds"] = float(dst_entry.get("total_play_time_seconds", 0.0)) + float(src_entry.get("total_play_time_seconds", 0.0))
			dst_entry["total_kills"] = int(dst_entry.get("total_kills", 0)) + int(src_entry.get("total_kills", 0))
			dst_entry["best_survive_seconds"] = max(float(dst_entry.get("best_survive_seconds", 0.0)), float(src_entry.get("best_survive_seconds", 0.0)))
			dst_entry["survive_5min_count"] = int(dst_entry.get("survive_5min_count", 0)) + int(src_entry.get("survive_5min_count", 0))
			var dst_played: String = String(dst_entry.get("last_played_at", ""))
			var src_played: String = String(src_entry.get("last_played_at", ""))
			if src_played > dst_played:
				dst_entry["last_played_at"] = src_played
			into_per_char[char_id] = dst_entry
		data[into_key] = into_per_char
		data.erase(from_key)
		_save_all(data)
	_merge_match_record_files(into_key, from_key)

static func _merge_match_record_files(into_key: String, from_key: String) -> void:
	var into_path: String = "user://match_records_%s.json" % into_key
	var from_path: String = "user://match_records_%s.json" % from_key
	if into_path == from_path or not FileAccess.file_exists(from_path):
		return
	var records: Array = []
	for path in [into_path, from_path]:
		if not FileAccess.file_exists(path):
			continue
		var f := FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if parsed is Array:
			for entry in parsed as Array:
				records.append(entry)
	records.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int((a as Dictionary).get("ts", 0)) < int((b as Dictionary).get("ts", 0))
	)
	while records.size() > 200:
		records.remove_at(0)
	var wf := FileAccess.open(into_path, FileAccess.WRITE)
	if wf != null:
		wf.store_string(JSON.stringify(records, "\t"))
		wf.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(from_path))

static func is_brown_unlocked(username: String) -> bool:
	if AdminStore.is_admin(username):
		return true
	if username.to_lower() == AccountStore.DEV_USERNAME.to_lower():
		return true
	var prog := get_brown_unlock_progress(username)
	return (prog["capy_zoomer"] as int) >= 3 and (prog["capy_chef"] as int) >= 3 and (prog["capy_swamp"] as int) >= 3