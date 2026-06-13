class_name Capybara
extends Node2D

## Simple character with HP. Visual is a placeholder colored rect for now.
## Stats and look are driven by an optional CharacterData resource.

signal died

@export var max_hp: float = 100.0
@export var tint: Color = Color(0.85, 0.7, 0.5)
@export var label_text: String = "Capy"

## -1 = faces up (player attacks toward top of screen)
## +1 = faces down (opponent attacks toward bottom)
var face_dir: int = -1

var hp: float
var data: CharacterData

@onready var _body: ColorRect = $Body
@onready var _name_label: Label = $NameLabel

const SPRITE_DIR := "res://assets/characters/"
const SPRITE_EXTS: Array[String] = [".png", ".webp", ".jpg", ".svg"]

var _sprite: Sprite2D
var _idle_tween: Tween
var _action_tween: Tween
var _flash_tween: Tween
var _body_home: Vector2 = Vector2.ZERO

func _ready() -> void:
	hp = max_hp
	if _body:
		_body.pivot_offset = _body.size * 0.5
		_body_home = _body.position
	_apply_visuals()
	_start_idle()

func apply_data(d: CharacterData) -> void:
	data = d
	if d == null:
		return
	max_hp = d.max_hp
	tint = d.tint
	label_text = d.display_name
	hp = max_hp
	if is_inside_tree():
		_apply_visuals()

func _apply_visuals() -> void:
	if _body:
		_body.color = tint
		_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _name_label:
		_name_label.text = label_text
		_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_sprite()

## Swap the placeholder colored square for a character portrait if an image
## exists at res://assets/characters/<id>.<ext>. The sprite is parented to
## _body so all existing position/scale/rotation/modulate tweens keep working.
func _apply_sprite() -> void:
	if _body == null:
		return
	var char_id: String = ""
	if data != null:
		char_id = String(data.id)
	var tex: Texture2D = null
	if char_id != "":
		for ext in SPRITE_EXTS:
			var path: String = SPRITE_DIR + char_id + ext
			if ResourceLoader.exists(path):
				tex = load(path) as Texture2D
				break
	if tex == null:
		if _sprite:
			_sprite.queue_free()
			_sprite = null
		return
	if _sprite == null:
		_sprite = Sprite2D.new()
		_body.add_child(_sprite)
	_sprite.texture = tex
	_sprite.position = _body.size * 0.5
	var longest: float = max(tex.get_width(), tex.get_height())
	if longest > 0.0:
		var s: float = _body.size.x / longest
		_sprite.scale = Vector2(s, s)
	# Hide the colored square so only the portrait shows.
	_body.color = Color(1, 1, 1, 0)

func take_damage(amount: float) -> void:
	hp = max(0.0, hp - amount)
	play_hit()
	if hp <= 0.0:
		died.emit()

func hp_fraction() -> float:
	return hp / max_hp if max_hp > 0 else 0.0

# ---- animations -------------------------------------------------------------

func _start_idle() -> void:
	if not _body:
		return
	_stop_idle()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(_body, "scale", Vector2(0.96, 1.04), 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(_body, "scale", Vector2(1.0, 1.0), 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_idle() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	_idle_tween = null

func play_hit() -> void:
	if not _body:
		return
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(_body, "modulate", Color(1.8, 0.5, 0.5), 0.05)
	_flash_tween.tween_property(_body, "modulate", Color.WHITE, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func play_attack() -> void:
	if not _body:
		return
	_stop_idle()
	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	var style: String = String(data.id) if data != null else ""
	match style:
		"capy_chef":
			_attack_chef()
		"capy_zoomer":
			_attack_zoomer()
		"capy_brown":
			_attack_brown()
		_:
			_attack_default()
	_action_tween.finished.connect(_on_action_done, CONNECT_ONE_SHOT)

func _attack_default() -> void:
	var anticip: Vector2 = _body_home + Vector2(0.0, -face_dir * 6.0)
	var lunge: Vector2 = _body_home + Vector2(0.0, face_dir * 24.0)
	_action_tween = create_tween()
	_action_tween.tween_property(_body, "position", anticip, 0.05) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_action_tween.tween_property(_body, "position", lunge, 0.07) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_action_tween.tween_property(_body, "position", _body_home, 0.14) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

# Chef: a quick "throw" — cock back, snap forward with a wrist-flick rotation.
func _attack_chef() -> void:
	var wind: Vector2 = _body_home + Vector2(-12.0, -face_dir * 8.0)
	var throw: Vector2 = _body_home + Vector2(10.0, face_dir * 18.0)
	_action_tween = create_tween()
	_action_tween.tween_property(_body, "position", wind, 0.07) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(_body, "rotation", deg_to_rad(-face_dir * 18.0), 0.07)
	_action_tween.tween_property(_body, "position", throw, 0.06) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(_body, "rotation", deg_to_rad(face_dir * 22.0), 0.06)
	_action_tween.tween_property(_body, "position", _body_home, 0.16) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_action_tween.parallel().tween_property(_body, "rotation", 0.0, 0.16)

# Zoomer: snappy headbutt dash — tilt forward then shoot.
func _attack_zoomer() -> void:
	var tilt: Vector2 = _body_home + Vector2(0.0, -face_dir * 4.0)
	var dash: Vector2 = _body_home + Vector2(0.0, face_dir * 36.0)
	_action_tween = create_tween()
	_action_tween.tween_property(_body, "position", tilt, 0.03) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(_body, "rotation", deg_to_rad(face_dir * 14.0), 0.03)
	_action_tween.parallel().tween_property(_body, "scale", Vector2(1.1, 0.9), 0.03)
	_action_tween.tween_property(_body, "position", dash, 0.06) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_action_tween.tween_property(_body, "position", _body_home, 0.10) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_action_tween.parallel().tween_property(_body, "rotation", 0.0, 0.10)
	_action_tween.parallel().tween_property(_body, "scale", Vector2.ONE, 0.10)

# Brown: bouncy splash — squash, hop, land with a little wobble.
func _attack_brown() -> void:
	var squash_pos: Vector2 = _body_home + Vector2(0.0, -face_dir * 2.0)
	var hop: Vector2 = _body_home + Vector2(0.0, face_dir * 22.0 - 14.0)
	_action_tween = create_tween()
	_action_tween.tween_property(_body, "position", squash_pos, 0.06)
	_action_tween.parallel().tween_property(_body, "scale", Vector2(1.15, 0.85), 0.06)
	_action_tween.tween_property(_body, "position", hop, 0.09) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(_body, "scale", Vector2(0.9, 1.15), 0.09)
	_action_tween.tween_property(_body, "position", _body_home, 0.18) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(_body, "scale", Vector2.ONE, 0.18)

func play_finisher() -> void:
	if not _body:
		return
	_stop_idle()
	if _action_tween and _action_tween.is_valid():
		_action_tween.kill()
	var style: String = String(data.id) if data != null else ""
	match style:
		"capy_chef":
			_finisher_chef()
		"capy_zoomer":
			_finisher_zoomer()
		"capy_brown":
			_finisher_brown()
		_:
			_finisher_default()
	_action_tween.finished.connect(_on_action_done, CONNECT_ONE_SHOT)

func _finisher_default() -> void:
	var windup: Vector2 = _body_home + Vector2(0.0, -face_dir * 22.0)
	var slam: Vector2 = _body_home + Vector2(0.0, face_dir * 48.0)
	var bright: Color = tint.lightened(0.5)
	_action_tween = create_tween()
	_action_tween.tween_property(_body, "position", windup, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(_body, "scale", Vector2(1.25, 0.8), 0.18)
	_action_tween.parallel().tween_property(_body, "rotation", deg_to_rad(-face_dir * 15.0), 0.18)
	_action_tween.tween_property(_body, "position", slam, 0.09) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(_body, "scale", Vector2(0.85, 1.25), 0.09)
	_action_tween.parallel().tween_property(_body, "rotation", deg_to_rad(face_dir * 10.0), 0.09)
	_action_tween.parallel().tween_property(_body, "modulate", bright, 0.09)
	_action_tween.tween_property(_body, "position", _body_home, 0.28) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_action_tween.parallel().tween_property(_body, "scale", Vector2.ONE, 0.28)
	_action_tween.parallel().tween_property(_body, "rotation", 0.0, 0.28)
	_action_tween.parallel().tween_property(_body, "modulate", Color.WHITE, 0.28)

# Chef finisher "Yuzu Yeet": full overhead throw with spin.
func _finisher_chef() -> void:
	var bright: Color = tint.lightened(0.5)
	var wind: Vector2 = _body_home + Vector2(-22.0, -face_dir * 28.0)
	var yeet: Vector2 = _body_home + Vector2(18.0, face_dir * 40.0)
	_action_tween = create_tween()
	_action_tween.tween_property(_body, "position", wind, 0.20) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(_body, "rotation", deg_to_rad(-face_dir * 40.0), 0.20)
	_action_tween.parallel().tween_property(_body, "scale", Vector2(1.2, 0.85), 0.20)
	_action_tween.tween_property(_body, "position", yeet, 0.12) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(_body, "rotation", deg_to_rad(face_dir * 360.0), 0.12)
	_action_tween.parallel().tween_property(_body, "scale", Vector2(0.9, 1.2), 0.12)
	_action_tween.parallel().tween_property(_body, "modulate", bright, 0.12)
	_action_tween.tween_property(_body, "position", _body_home, 0.30) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_action_tween.parallel().tween_property(_body, "rotation", 0.0, 0.30)
	_action_tween.parallel().tween_property(_body, "scale", Vector2.ONE, 0.30)
	_action_tween.parallel().tween_property(_body, "modulate", Color.WHITE, 0.30)

# Zoomer finisher: rapid triple headbutt.
func _finisher_zoomer() -> void:
	var bright: Color = tint.lightened(0.5)
	var dash: Vector2 = _body_home + Vector2(0.0, face_dir * 44.0)
	_action_tween = create_tween()
	for i in range(3):
		_action_tween.tween_property(_body, "position", _body_home + Vector2(0.0, -face_dir * 6.0), 0.05) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_action_tween.parallel().tween_property(_body, "rotation", deg_to_rad(face_dir * 18.0), 0.05)
		_action_tween.tween_property(_body, "position", dash, 0.06) \
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		if i == 2:
			_action_tween.parallel().tween_property(_body, "modulate", bright, 0.06)
	_action_tween.tween_property(_body, "position", _body_home, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_action_tween.parallel().tween_property(_body, "rotation", 0.0, 0.18)
	_action_tween.parallel().tween_property(_body, "modulate", Color.WHITE, 0.18)

# Brown finisher "Hot Spring Splash": deep squash, soaring hop, big bounce.
func _finisher_brown() -> void:
	var bright: Color = tint.lightened(0.5)
	var squash_pos: Vector2 = _body_home + Vector2(0.0, -face_dir * 6.0)
	var splash: Vector2 = _body_home + Vector2(0.0, face_dir * 30.0 - 36.0)
	_action_tween = create_tween()
	_action_tween.tween_property(_body, "position", squash_pos, 0.16) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(_body, "scale", Vector2(1.35, 0.7), 0.16)
	_action_tween.tween_property(_body, "position", splash, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(_body, "scale", Vector2(0.8, 1.3), 0.18)
	_action_tween.parallel().tween_property(_body, "modulate", bright, 0.18)
	_action_tween.tween_property(_body, "position", _body_home, 0.40) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_action_tween.parallel().tween_property(_body, "scale", Vector2.ONE, 0.40)
	_action_tween.parallel().tween_property(_body, "modulate", Color.WHITE, 0.40)

func _on_action_done() -> void:
	if not _body:
		return
	_body.position = _body_home
	_body.rotation = 0.0
	_body.scale = Vector2.ONE
	_start_idle()
