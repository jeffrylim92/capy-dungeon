class_name StoryAtmosphere
extends Node2D

var stage_index := 0
var _time := 0.0
var _particles: Array[Dictionary] = []

func setup(index: int, view: Vector2) -> void:
	stage_index = index
	for i in 22:
		_particles.append({
			"x":randf_range(0.0, view.x),
			"y":randf_range(0.0, view.y),
			"r":randf_range(2.0, 7.0),
			"speed":randf_range(10.0, 34.0),
			"phase":randf_range(0.0, TAU),
		})
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var view := get_viewport_rect().size
	var colors := [Color(1.0, 0.76, 0.24, 0.72), Color(0.36, 0.94, 0.78, 0.65), Color(1.0, 0.58, 0.20, 0.70), Color(0.62, 1.0, 0.42, 0.66), Color(0.22, 0.96, 0.88, 0.72)]
	var color: Color = colors[clampi(stage_index, 0, colors.size() - 1)]
	for particle in _particles:
		var travel := fposmod(float(particle.y) - _time * float(particle.speed), view.y + 80.0) - 40.0
		var x := float(particle.x) + sin(_time * 0.8 + float(particle.phase)) * 24.0
		var pulse := 0.55 + sin(_time * 2.0 + float(particle.phase)) * 0.25
		draw_circle(Vector2(x, travel), float(particle.r) * pulse, Color(color.r, color.g, color.b, color.a * pulse))
	if stage_index == 1:
		for i in 4:
			var y := view.y * (0.72 + float(i) * 0.055)
			var points := PackedVector2Array()
			for x in range(-20, int(view.x) + 40, 36):
				points.append(Vector2(float(x), y + sin(float(x) * 0.018 + _time * 1.4 + float(i)) * 7.0))
			draw_polyline(points, Color(0.25, 0.90, 0.92, 0.24), 3.0, true)
