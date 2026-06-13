class_name ComboSystem
extends RefCounted

## Pure combo-state logic. Engine-agnostic, fully unit-testable.
##
## Usage:
##   var combo := ComboSystem.new()
##   var dmg := combo.register_hit("apple")  # returns damage dealt
##   combo.register_miss()                   # resets chain

signal combo_changed(count: int, multiplier: float)
signal combo_broken(final_count: int)
signal milestone_reached(count: int)

const BASE_DAMAGE: float = 2.0
const MILESTONES: Array[int] = [10]

var count: int = 0
var last_fruit: String = ""
var _milestones_hit: Array[int] = []

func register_hit(fruit_id: String) -> float:
	count += 1
	last_fruit = fruit_id
	var mult := multiplier()
	combo_changed.emit(count, mult)
	for m in MILESTONES:
		if count == m and m not in _milestones_hit:
			_milestones_hit.append(m)
			milestone_reached.emit(m)
	return BASE_DAMAGE * mult

func register_miss() -> void:
	if count > 0:
		combo_broken.emit(count)
	_reset()

func multiplier() -> float:
	# Steeper curve so the multiplier is visibly rewarding:
	# 1.0 at 0 → 1.5 at 5 → 2.0 at 10 → 3.0 at 20 (capped).
	return min(1.0 + count * 0.1, 3.0)

func _reset() -> void:
	count = 0
	last_fruit = ""
	_milestones_hit.clear()
	combo_changed.emit(0, 1.0)
