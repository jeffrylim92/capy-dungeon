class_name ComboSystem
extends RefCounted

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
	var current_multiplier: float = multiplier()
	combo_changed.emit(count, current_multiplier)
	for milestone: int in MILESTONES:
		if count == milestone and milestone not in _milestones_hit:
			_milestones_hit.append(milestone)
			milestone_reached.emit(milestone)
	return BASE_DAMAGE * current_multiplier

func register_miss() -> void:
	if count > 0:
		combo_broken.emit(count)
	_reset()

func multiplier() -> float:
	return minf(1.0 + count * 0.04, 3.0)

func _reset() -> void:
	count = 0
	last_fruit = ""
	_milestones_hit.clear()
	combo_changed.emit(0, 1.0)
