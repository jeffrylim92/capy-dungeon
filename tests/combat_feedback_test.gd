extends SceneTree

const CombatFeedbackClass := preload("res://scripts/CombatFeedback.gd")
const CombatVFXClass := preload("res://scripts/CombatVFX.gd")
const SoundManagerClass := preload("res://scripts/SoundManager.gd")

var _feedback_is_blocked: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var match_script := load("res://scripts/Match.gd")
	assert(match_script != null)
	_test_damage_number_budget(match_script)
	_test_classification()
	var host := Node2D.new()
	root.add_child(host)
	var camera := Camera2D.new()
	host.add_child(camera)
	var vfx := CombatVFXClass.new()
	host.add_child(vfx)
	var sound := SoundManagerClass.new()
	host.add_child(sound)
	var feedback := CombatFeedbackClass.new()
	host.add_child(feedback)
	feedback.configure(camera, vfx, sound, Callable(self, "_is_feedback_blocked"), {
		"screen_shake":1.0,
		"effect_intensity":1.0,
		"haptics":"off",
	})

	assert(feedback.request_shake(CombatFeedbackClass.TIER_MINOR))
	assert(feedback.request_shake(CombatFeedbackClass.TIER_MAJOR))
	assert(float(feedback.debug_state().get("shake_amplitude", 0.0)) == 5.5)
	feedback.cancel_shake()
	feedback.configure(camera, vfx, sound, Callable(self, "_is_feedback_blocked"), {
		"screen_shake":0.0, "flash_intensity":0.5, "effect_intensity":1.0, "haptics":"off",
	})
	assert(not feedback.request_shake(CombatFeedbackClass.TIER_MAJOR))
	assert(is_equal_approx(float(feedback.debug_state().get("flash_scale", 0.0)), 0.5))
	assert(str(feedback.debug_state().get("haptic_mode", "")) == "off")
	feedback.configure(camera, vfx, sound, Callable(self, "_is_feedback_blocked"), {
		"screen_shake":0.5, "flash_intensity":1.0, "effect_intensity":1.0, "haptics":"light",
	})
	assert(feedback.request_shake(CombatFeedbackClass.TIER_MAJOR))
	assert(is_equal_approx(float(feedback.debug_state().get("shake_amplitude", 0.0)), 2.75))
	feedback.cancel_shake()
	var original_time_scale := Engine.time_scale
	assert(feedback.request_hitstop(0.024, 0.22))
	assert(is_equal_approx(Engine.time_scale, 0.22))
	assert(not feedback.request_hitstop(0.024, 0.22))
	feedback.cancel_transients()
	assert(is_equal_approx(Engine.time_scale, original_time_scale))
	assert(camera.offset == Vector2.ZERO)

	_feedback_is_blocked = true
	assert(not feedback.request_shake(CombatFeedbackClass.TIER_MAJOR))
	assert(not feedback.request_hitstop(0.024, 0.22))
	_feedback_is_blocked = false
	vfx.set_effect_intensity(1.0)
	vfx.emit_hit({"position":Vector2.ZERO, "critical":true})
	var high_effect_count := vfx.active_effect_count()
	vfx.clear_transients()
	vfx.set_effect_intensity(0.58)
	vfx.emit_hit({"position":Vector2.ZERO, "critical":true})
	var low_effect_count := vfx.active_effect_count()
	assert(low_effect_count < high_effect_count)
	vfx.clear_transients()
	vfx.set_effect_intensity(1.0)

	for index in 200:
		vfx.emit_hit({"position":Vector2(float(index), 0.0), "critical":index % 2 == 0})
	assert(vfx.active_effect_count() <= 120)
	vfx.clear_transients()
	assert(vfx.active_effect_count() == 0)
	assert(sound.play_limited("combat_hit", 0.5))
	assert(not sound.play_limited("combat_hit", 0.5))

	feedback.cancel_transients()
	host.queue_free()
	await process_frame
	print("Combat feedback tests passed: hierarchy · bounded shake/hitstop · VFX/audio/number limits · DOT aggregation · cleanup")
	quit(0)

func _test_classification() -> void:
	assert(CombatFeedbackClass.classify_hit({"dot":true}) == CombatFeedbackClass.TIER_MINOR)
	assert(CombatFeedbackClass.classify_hit({"critical":true}) == CombatFeedbackClass.TIER_STRONG)
	assert(CombatFeedbackClass.classify_hit({"ultimate":true}) == CombatFeedbackClass.TIER_MAJOR)
	assert(CombatFeedbackClass.classify_hit({"signature":true}) == CombatFeedbackClass.TIER_SIGNATURE)
	assert(CombatFeedbackClass.popup_priority({"player_damage":true}) == 5)
	assert(CombatFeedbackClass.popup_priority({"critical":true}) == 4)
	assert(CombatFeedbackClass.popup_priority({"boss":true}) == 3)
	assert(CombatFeedbackClass.popup_priority({}) == 2)
	assert(CombatFeedbackClass.popup_priority({"dot":true}) == 1)

func _test_damage_number_budget(match_script: Script) -> void:
	var match_node: Variant = match_script.new()
	match_node._enemies.append({
		"pos":Vector2.ZERO, "hp":100.0, "max_hp":100.0, "kind":"normal",
		"iframes":0.0, "r":20.0, "dmg":1.0, "base_spd":1.0, "spd":1.0,
	})
	match_node._hit_enemy(0, 10.0, {"projectile":true, "source":"test_bolt"})
	assert(is_equal_approx(float(match_node._enemies[0].get("hp", 0.0)), 90.0))
	assert(float(match_node._enemies[0].get("hit_flash_t", 0.0)) > 0.0)
	match_node._damage_popups.clear()
	match_node._damage_number_mode = "off"
	match_node._damage_numbers_enabled = false
	match_node._spawn_damage_popup(Vector2.ZERO, 25.0, true, {"source":"test"})
	assert(match_node._damage_popups.is_empty())
	match_node._damage_number_mode = "critical_only"
	match_node._damage_numbers_enabled = true
	match_node._spawn_damage_popup(Vector2.ZERO, 25.0, false, {"source":"test"})
	assert(match_node._damage_popups.is_empty())
	match_node._spawn_damage_popup(Vector2.ZERO, 25.0, true, {"source":"test"})
	assert(match_node._damage_popups.size() == 1)
	match_node._damage_popups.clear()
	match_node._damage_number_mode = "all"
	for index in 200:
		match_node._spawn_damage_popup(Vector2(float(index) * 100.0, 0.0), 1.0, false, {"dot":true, "source":"dot_%d" % index})
	assert(match_node._damage_popups.size() == int(match_script.DAMAGE_POPUP_MAX))
	match_node._spawn_reaction_popup(Vector2.ZERO, "BLOCKED", Color.WHITE)
	assert(match_node._damage_popups.size() == int(match_script.DAMAGE_POPUP_MAX))
	assert(match_node._damage_popups.any(func(popup: Dictionary) -> bool: return str(popup.get("text", "")) == "BLOCKED"))
	match_node._damage_popups.clear()
	for index in 20:
		match_node._spawn_damage_popup(Vector2.ZERO, 1.0, false, {"dot":true, "source":"poison"})
	assert(match_node._damage_popups.size() == 1)
	assert(is_equal_approx(float(match_node._damage_popups[0].get("value", 0.0)), 20.0))
	match_node.free()

func _is_feedback_blocked() -> bool:
	return _feedback_is_blocked
