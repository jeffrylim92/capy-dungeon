extends Node

## Backend endpoint for non-fatal logs and recovered crash signals.
## Set this to "" to disable remote reporting without removing the autoload.
const ERROR_ENDPOINT: String = "https://capy-dungeon.onrender.com/client-errors"

const STATE_PATH: String = "user://crash_state.json"
const QUEUE_PATH: String = "user://crash_queue.json"
const FLUSH_INTERVAL_SEC: float = 15.0
const MAX_QUEUE_SIZE: int = 100
const MAX_BATCH_SIZE: int = 20

var _session_id: String = ""
var _seq: int = 0
var _flush_elapsed: float = 0.0
var _sending: bool = false
var _inflight_count: int = 0
var _queue: Array[Dictionary] = []
var _http: HTTPRequest = null

func _ready() -> void:
	_session_id = "%d-%d" % [Time.get_unix_time_from_system(), randi()]
	_load_queue()
	_emit_previous_crash_signal_if_needed()
	_mark_clean_exit(false)

	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

	set_process(true)
	_try_flush()

func _exit_tree() -> void:
	_mark_clean_exit(true)

func _process(delta: float) -> void:
	_flush_elapsed += delta
	if _flush_elapsed >= FLUSH_INTERVAL_SEC:
		_flush_elapsed = 0.0
		_try_flush()

func report_error(message: String, context: Dictionary = {}) -> void:
	_enqueue_event("error", message, context)

func report_warning(message: String, context: Dictionary = {}) -> void:
	_enqueue_event("warning", message, context)

func report_log(message: String, context: Dictionary = {}) -> void:
	_enqueue_event("log", message, context)

func _emit_previous_crash_signal_if_needed() -> void:
	var prev: Variant = _read_json_file(STATE_PATH)
	if typeof(prev) != TYPE_DICTIONARY:
		return
	var state: Dictionary = prev as Dictionary
	if bool(state.get("clean_exit", true)):
		return
	var context := {
		"previous_session_id": str(state.get("session_id", "")),
		"previous_platform": str(state.get("platform", "")),
		"previous_started_at": int(state.get("started_at", 0))
	}
	_enqueue_event("crash_recovered", "Previous session ended unexpectedly", context)

func _enqueue_event(kind: String, message: String, context: Dictionary = {}) -> void:
	_seq += 1
	var event: Dictionary = {
		"kind": kind,
		"message": message,
		"context": context,
		"session_id": _session_id,
		"seq": _seq,
		"platform": OS.get_name(),
		"timestamp": Time.get_unix_time_from_system(),
	}
	_queue.append(event)
	while _queue.size() > MAX_QUEUE_SIZE:
		_queue.remove_at(0)
	_write_json_file(QUEUE_PATH, _queue)
	_try_flush()

func _try_flush() -> void:
	if ERROR_ENDPOINT.is_empty() or _sending or _queue.is_empty() or _http == null:
		return
	var count: int = mini(MAX_BATCH_SIZE, _queue.size())
	var batch: Array[Dictionary] = []
	for i in count:
		batch.append(_queue[i])
	var payload: Dictionary = {
		"events": batch,
		"game": ProjectSettings.get_setting("application/config/name", ""),
		"version": ProjectSettings.get_setting("application/config/version", ""),
	}
	var err := _http.request(
		ERROR_ENDPOINT,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	if err != OK:
		push_warning("CrashReporter: failed to start request: %d" % err)
		return
	_inflight_count = count
	_sending = true

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	_sending = false
	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
		for _i in _inflight_count:
			if _queue.is_empty():
				break
			_queue.remove_at(0)
		_write_json_file(QUEUE_PATH, _queue)
	_inflight_count = 0
	_try_flush()

func _mark_clean_exit(clean_exit: bool) -> void:
	var state: Dictionary = {
		"clean_exit": clean_exit,
		"session_id": _session_id,
		"platform": OS.get_name(),
		"started_at": Time.get_unix_time_from_system(),
	}
	_write_json_file(STATE_PATH, state)

func _load_queue() -> void:
	var loaded: Variant = _read_json_file(QUEUE_PATH)
	_queue = []
	if typeof(loaded) != TYPE_ARRAY:
		return
	for item: Variant in (loaded as Array):
		if typeof(item) == TYPE_DICTIONARY:
			_queue.append(item as Dictionary)

func _read_json_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var text: String = f.get_as_text()
	f.close()
	if text.is_empty():
		return null
	return JSON.parse_string(text)

func _write_json_file(path: String, data: Variant) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("CrashReporter: failed to open %s for write" % path)
		return
	f.store_string(JSON.stringify(data))
	f.close()
