class_name Juice
extends Node2D

## Visual juice helper: screen shake, hit-stop, particle bursts.
## Add as a child of the scene that should be shaken, then set `target` to
## the Node2D whose `position` should be displaced.

var target: Node2D

func shake(amplitude: float = 14.0, duration: float = 0.25) -> void:
	if target == null:
		return
	var orig := target.position
	var t0 := Time.get_ticks_msec()
	var elapsed := 0.0
	while elapsed < duration:
		var k := 1.0 - elapsed / duration
		target.position = orig + Vector2(
			randf_range(-1.0, 1.0) * amplitude * k,
			randf_range(-1.0, 1.0) * amplitude * k,
		)
		await get_tree().process_frame
		elapsed = (Time.get_ticks_msec() - t0) / 1000.0
	target.position = orig

func hit_stop(duration: float = 0.07, factor: float = 0.04) -> void:
	Engine.time_scale = factor
	# ignore_time_scale = true so the resume timer ticks in real time
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func burst(
	at: Vector2,
	color: Color = Color.WHITE,
	count: int = 18,
	speed: float = 350.0
) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = count
	p.lifetime = 0.55
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 800)
	p.scale_amount_min = 4.0
	p.scale_amount_max = 9.0
	p.color = color
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
