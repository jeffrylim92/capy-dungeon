class_name JoystickVisual
extends Node2D

## Screen-space virtual joystick visualiser.
## Place this inside a CanvasLayer so it draws in screen coordinates.

var origin:      Vector2 = Vector2.ZERO
var knob:        Vector2 = Vector2.ZERO
var visible_joy: bool    = false
var control_scale: float = 1.0
var control_opacity: float = 0.7

func configure(scale_value: float, opacity_value: float) -> void:
	control_scale = clampf(scale_value, 0.85, 1.2)
	control_opacity = clampf(opacity_value, 0.35, 1.0)
	queue_redraw()

func travel_radius() -> float:
	return 80.0 * control_scale

func _process(_delta: float) -> void:
	if visible_joy:
		queue_redraw()

func _draw() -> void:
	if not visible_joy:
		return
	# Base ring
	var base_radius := travel_radius()
	var knob_radius := 34.0 * control_scale
	draw_circle(origin, base_radius, Color(0.08, 0.08, 0.08, 0.43 * control_opacity))
	draw_arc(origin, base_radius, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.40 * control_opacity), 2.5 * control_scale)
	# Knob
	draw_circle(knob, knob_radius, Color(0.98, 0.72, 0.08, control_opacity))
	draw_arc(knob, knob_radius, 0.0, TAU, 32, Color(1.0, 0.90, 0.50, minf(1.0, control_opacity + 0.18)), 2.5 * control_scale)
