class_name JoystickVisual
extends Node2D

## Screen-space virtual joystick visualiser.
## Place this inside a CanvasLayer so it draws in screen coordinates.

var origin:      Vector2 = Vector2.ZERO
var knob:        Vector2 = Vector2.ZERO
var visible_joy: bool    = false

func _process(_delta: float) -> void:
	if visible_joy:
		queue_redraw()

func _draw() -> void:
	if not visible_joy:
		return
	# Base ring
	draw_circle(origin, 80.0, Color(0.08, 0.08, 0.08, 0.30))
	draw_arc(origin, 80.0, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.28), 2.5)
	# Knob
	draw_circle(knob, 34.0, Color(0.98, 0.72, 0.08, 0.70))
	draw_arc(knob, 34.0, 0.0, TAU, 32, Color(1.0, 0.90, 0.50, 0.90), 2.5)
