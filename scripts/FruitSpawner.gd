class_name FruitSpawner
extends Node2D

## Spawns Fruit instances at random horizontal positions on a timer.
## Signals are forwarded so the Match can react to taps / misses.

signal fruit_tapped(fruit_id: String, at: Vector2)
signal fruit_missed(fruit_id: String, at: Vector2)

const FRUIT_SCENE := preload("res://scenes/Fruit.tscn")

const FRUITS := [
	{"id": "apple",  "color": Color(0.95, 0.25, 0.25)},
	{"id": "carrot", "color": Color(1.0, 0.55, 0.1)},
	{"id": "berry",  "color": Color(0.6, 0.2, 0.8)},
	{"id": "leaf",   "color": Color(0.3, 0.8, 0.35)},
]

@export var spawn_interval: float = 0.7
@export var min_spawn_interval: float = 0.25
@export var ramp_per_spawn: float = 0.02  # shave off each spawn
@export var spawn_margin: float = 80.0
@export var spawn_y: float = -100.0

var _timer: Timer
var _running: bool = false

func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.wait_time = spawn_interval
	add_child(_timer)
	_timer.timeout.connect(_spawn_one)

func start() -> void:
	_running = true
	_timer.start()

func stop() -> void:
	_running = false
	_timer.stop()

func _spawn_one() -> void:
	if not _running:
		return
	var fruit: Fruit = FRUIT_SCENE.instantiate()
	var data: Dictionary = FRUITS.pick_random()
	fruit.fruit_id = data["id"]
	fruit.fruit_color = data["color"]
	var view_w := get_viewport_rect().size.x
	fruit.position = Vector2(randf_range(spawn_margin, view_w - spawn_margin), spawn_y)
	fruit.tapped.connect(func(id: String, at: Vector2) -> void: fruit_tapped.emit(id, at))
	fruit.missed.connect(func(id: String, at: Vector2) -> void: fruit_missed.emit(id, at))
	add_child(fruit)
	# difficulty ramp
	_timer.wait_time = max(min_spawn_interval, _timer.wait_time - ramp_per_spawn)
