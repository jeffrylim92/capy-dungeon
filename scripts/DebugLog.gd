class_name DebugLog
extends RefCounted

static var _msgs: Array[String] = []
static var _max: int = 100
static var dirty: bool = false
## Pinned line shown at the top of the overlay — not evicted by the rolling buffer.
static var sticky: String = ""

static func log(msg: String) -> void:
	print(msg)
	_msgs.append(msg)
	if _msgs.size() > _max:
		_msgs.remove_at(0)
	dirty = true

static func error(msg: String, context: Dictionary = {}) -> void:
	DebugLog.log("[ERROR] " + msg)
	_forward_to_crash_reporter("report_error", msg, context)

static func warning(msg: String, context: Dictionary = {}) -> void:
	DebugLog.log("[WARN] " + msg)
	_forward_to_crash_reporter("report_warning", msg, context)

static func _forward_to_crash_reporter(method: String, msg: String, context: Dictionary) -> void:
	var main_loop: MainLoop = Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return
	var tree := main_loop as SceneTree
	if tree.root == null:
		return
	var reporter := tree.root.get_node_or_null("CrashReporter")
	if reporter != null and reporter.has_method(method):
		reporter.call(method, msg, context)

static func get_text() -> String:
	dirty = false
	if sticky.is_empty():
		return "\n".join(_msgs)
	return sticky + "\n---\n" + "\n".join(_msgs)

static func clear() -> void:
	_msgs.clear()
	sticky = ""
	dirty = true
