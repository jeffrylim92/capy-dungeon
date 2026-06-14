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

static func get_text() -> String:
	dirty = false
	if sticky.is_empty():
		return "\n".join(_msgs)
	return sticky + "\n---\n" + "\n".join(_msgs)

static func clear() -> void:
	_msgs.clear()
	sticky = ""
	dirty = true
