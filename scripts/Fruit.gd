class_name Fruit
extends Area2D

## A falling tappable fruit. Emits `tapped(fruit_id)` when player taps it,
## `missed(fruit_id)` when it falls off-screen.

signal tapped(fruit_id: String, at: Vector2)
signal missed(fruit_id: String, at: Vector2)

@export var fall_speed: float = 600.0  # px / sec
@export var fruit_id: String = "apple"
@export var fruit_color: Color = Color.RED

var _alive: bool = true
@onready var _body: ColorRect = $Body

const SPRITE_DIR := "res://assets/fruits/"
const SPRITE_EXTS: Array[String] = [".png", ".webp", ".jpg", ".svg"]
const SPRITE_DISPLAY_SIZE: float = 100.0  # px; sprite is rescaled to this

func _ready() -> void:
	if _body:
		_body.color = fruit_color
		_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_try_apply_sprite()
	input_pickable = true
	input_event.connect(_on_input_event)

## If an image exists at res://assets/fruits/<fruit_id>.<ext>, swap the
## placeholder ColorRect for a Sprite2D using that texture. Falls back to the
## coloured square if no image is found.
func _try_apply_sprite() -> void:
	var tex: Texture2D = null
	for ext in SPRITE_EXTS:
		var path: String = SPRITE_DIR + fruit_id + ext
		if ResourceLoader.exists(path):
			tex = load(path) as Texture2D
			break
	if tex == null:
		return
	if _body:
		_body.visible = false
	var sprite := Sprite2D.new()
	sprite.texture = tex
	var tex_size: Vector2 = tex.get_size()
	var longest: float = max(tex_size.x, tex_size.y)
	if longest > 0.0:
		var s: float = SPRITE_DISPLAY_SIZE / longest
		sprite.scale = Vector2(s, s)
	add_child(sprite)

func _process(delta: float) -> void:
	if not _alive:
		return
	position.y += fall_speed * delta
	# off-screen check (viewport height + buffer)
	if position.y > get_viewport_rect().size.y + 100:
		_alive = false
		missed.emit(fruit_id, position)
		queue_free()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not _alive:
		return
	if event is InputEventScreenTouch and event.pressed:
		_consume_tap()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_consume_tap()

func _consume_tap() -> void:
	_alive = false
	tapped.emit(fruit_id, position)
	_pop_and_free()

func _pop_and_free() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.08)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.12)
	tween.tween_callback(queue_free)
