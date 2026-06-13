class_name TargetSequence
extends RefCounted

## Manages the queue of upcoming required fruit IDs.
## The sequence is pre-generated and infinite (lazily extended) so the HUD
## can always peek N items ahead without surprises.

signal sequence_changed

const DEFAULT_FRUIT_IDS: Array[String] = ["apple", "carrot", "berry", "leaf"]
const LOOKAHEAD: int = 3
const CHUNK_SIZE: int = 16  # generate this many at a time

var _ids_pool: Array[String]
var _rng: RandomNumberGenerator
var _queue: Array[String] = []
var _index: int = 0

func _init(seed_value: int = 0, ids: Array[String] = DEFAULT_FRUIT_IDS) -> void:
	_ids_pool = ids
	_rng = RandomNumberGenerator.new()
	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	_extend()

func current() -> String:
	_ensure_available(1)
	return _queue[_index]

func peek(n: int = LOOKAHEAD) -> Array[String]:
	_ensure_available(n)
	return _queue.slice(_index, _index + n)

func advance() -> void:
	_index += 1
	_ensure_available(LOOKAHEAD)
	sequence_changed.emit()

func matches(fruit_id: String) -> bool:
	return fruit_id == current()

func _ensure_available(n: int) -> void:
	while _queue.size() - _index < n:
		_extend()

func _extend() -> void:
	# Avoid the same id twice in a row to keep it readable.
	var last := _queue[-1] if _queue.size() > 0 else ""
	for i in range(CHUNK_SIZE):
		var pick := last
		while pick == last:
			pick = _ids_pool[_rng.randi() % _ids_pool.size()]
		_queue.append(pick)
		last = pick
