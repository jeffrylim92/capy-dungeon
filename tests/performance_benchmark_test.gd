extends SceneTree

const CombatVFXClass := preload("res://scripts/CombatVFX.gd")

const SAMPLE_COUNT: int = 7
const AI_FRAMES: int = 240
const EFFECT_FRAMES: int = 180

var _match
var _normal_enemies: Array[Dictionary] = []
var _dense_enemies: Array[Dictionary] = []
var _vfx: CombatVFX

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var match_script := load("res://scripts/Match.gd")
	assert(match_script != null)
	_match = match_script.new()
	_match._player_pos = Vector2(540.0, 960.0)
	_normal_enemies = _make_enemies(24)
	_dense_enemies = _make_enemies(96)
	_vfx = CombatVFXClass.new()
	_vfx._ready()
	_verify_structural_guards()
	_run_benchmarks()
	quit(0)

func _run_benchmarks() -> void:
	var baseline_objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var results := {
		"A_normal_combat":_median_usec(Callable(self, "_benchmark_normal_ai")),
		"B_dense_combat":_median_usec(Callable(self, "_benchmark_dense_ai")),
		"C_extreme_build":_median_usec(Callable(self, "_benchmark_extreme_vfx")),
		"D_c1s5_bullets":_median_usec(Callable(self, "_benchmark_c1s5_bullets")),
		"E_c5s5_combined":_median_usec(Callable(self, "_benchmark_c5s5_combined")),
	}
	print("PERF_BENCHMARK runtime=headless renderer=%s samples=%d" % [RenderingServer.get_current_rendering_method(), SAMPLE_COUNT])
	for scenario in results:
		print("PERF_RESULT scenario=%s median_usec_per_frame=%.2f" % [scenario, float(results[scenario])])
	print("PERF_COUNTS enemies_normal=%d enemies_dense=%d role_projectiles=%d vfx_active=%d object_delta=%d" % [_normal_enemies.size(), _dense_enemies.size(), 320, _vfx.active_effect_count(), int(Performance.get_monitor(Performance.OBJECT_COUNT)) - baseline_objects])

func _verify_structural_guards() -> void:
	var first_motion := _match._update_enemy_role(_normal_enemies[0], 1.0 / 60.0, _match._player_pos) as Dictionary
	first_motion["benchmark_marker"] = true
	var second_motion := _match._update_enemy_role(_normal_enemies[0], 1.0 / 60.0, _match._player_pos) as Dictionary
	assert(bool(second_motion.get("benchmark_marker", false)))
	second_motion.erase("benchmark_marker")
	_vfx.configure_quality({"player_effects":"medium"})
	var medium_budget := _vfx.debug_budget()
	assert(int(medium_budget["particles"]) <= 190)
	assert(int(medium_budget["pulses"]) <= 36)
	_vfx.configure_quality({"player_effects":"low"})
	var low_budget := _vfx.debug_budget()
	assert(int(low_budget["particles"]) <= 120)
	assert(int(low_budget["pulses"]) <= 24)
	assert(not bool(low_budget["processing"]))
	_vfx.configure_quality({"player_effects":"high"})

func _median_usec(workload: Callable) -> float:
	var samples: Array[float] = []
	workload.call()
	for _sample in SAMPLE_COUNT:
		var started := Time.get_ticks_usec()
		var frames := int(workload.call())
		var elapsed := Time.get_ticks_usec() - started
		samples.append(float(elapsed) / float(maxi(frames, 1)))
	samples.sort()
	return samples[samples.size() / 2]

func _benchmark_normal_ai() -> int:
	for _frame in AI_FRAMES:
		for enemy in _normal_enemies:
			_match._update_enemy_role(enemy, 1.0 / 60.0, _match._player_pos)
	return AI_FRAMES

func _benchmark_dense_ai() -> int:
	for _frame in AI_FRAMES:
		for enemy in _dense_enemies:
			_match._update_enemy_role(enemy, 1.0 / 60.0, _match._player_pos)
	return AI_FRAMES

func _benchmark_extreme_vfx() -> int:
	_vfx.clear_transients()
	_vfx.set_effect_intensity(1.0)
	for frame in EFFECT_FRAMES:
		for hit_index in 18:
			_vfx.emit_hit({"position":Vector2(300 + hit_index * 18, 700 + frame % 7), "critical":hit_index % 7 == 0, "aoe":hit_index % 3 == 0})
		_vfx._process(1.0 / 60.0)
	return EFFECT_FRAMES

func _benchmark_c1s5_bullets() -> int:
	_match._enemy_role_projectiles.clear()
	for index in 320:
		_match._enemy_role_projectiles.append({"pos":Vector2(4000.0 + index, 4000.0), "vel":Vector2(90.0, 15.0), "life":999.0, "dmg":1.0, "kind":"boss_benchmark"})
	for _frame in EFFECT_FRAMES:
		_match._update_enemy_role_projectiles(1.0 / 60.0)
	return EFFECT_FRAMES

func _benchmark_c5s5_combined() -> int:
	for _frame in EFFECT_FRAMES:
		for enemy in _dense_enemies:
			_match._update_enemy_role(enemy, 1.0 / 60.0, _match._player_pos)
		_match._update_enemy_role_projectiles(1.0 / 60.0)
		_vfx._process(1.0 / 60.0)
	return EFFECT_FRAMES

func _make_enemies(count: int) -> Array[Dictionary]:
	var roles := ["chaser", "tank", "charger", "zoner", "sniper", "support", "controller", "summoner"]
	var enemies: Array[Dictionary] = []
	for index in count:
		var role := str(roles[index % roles.size()])
		enemies.append({
			"id":index + 1, "pos":Vector2(100.0 + float(index % 12) * 75.0, 220.0 + float(index / 12) * 80.0),
			"kind":"normal", "story_tag":"", "primary_role":role, "enemy_roles":[role], "role_enabled":true,
			"role_state":"idle", "role_state_t":0.0, "role_cooldown":999.0, "role_leash_center":Vector2.ZERO,
			"spd":120.0, "base_spd":120.0, "dmg":8.0, "hp":100.0, "max_hp":100.0,
		})
	return enemies
