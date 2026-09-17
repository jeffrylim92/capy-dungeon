class_name CombatFeedback
extends Node

## Presentation-only combat feedback coordinator. It never applies damage,
## changes cooldowns, or mutates encounter state.

const TIER_MINOR: int = 1
const TIER_STRONG: int = 2
const TIER_MAJOR: int = 3
const TIER_SIGNATURE: int = 4

const SHAKE_AMPLITUDES: Dictionary = {
	TIER_MINOR: 1.5,
	TIER_STRONG: 3.0,
	TIER_MAJOR: 5.5,
	TIER_SIGNATURE: 9.0,
}
const SHAKE_DURATIONS: Dictionary = {
	TIER_MINOR: 0.08,
	TIER_STRONG: 0.11,
	TIER_MAJOR: 0.16,
	TIER_SIGNATURE: 0.24,
}
const HITSTOP_COOLDOWN_USEC: int = 120000

var _camera: Camera2D
var _vfx: CombatVFX
var _sound: SoundManager
var _blocked_query: Callable
var _shake_scale: float = 1.0
var _effect_scale: float = 1.0
var _flash_scale: float = 1.0
var _haptic_mode: String = "light"
var _shake_amplitude: float = 0.0
var _shake_started_usec: int = 0
var _shake_end_usec: int = 0
var _hitstop_active: bool = false
var _hitstop_end_usec: int = 0
var _hitstop_next_usec: int = 0
var _owned_time_scale: float = 1.0
var _restore_time_scale: float = 1.0
var _overlay: ColorRect
var _overlay_alpha: float = 0.0
var _overlay_color: Color = Color.WHITE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("combat_feedback")
	_build_overlay()

func configure(camera: Camera2D, vfx: CombatVFX, sound: SoundManager, blocked_query: Callable = Callable(), settings: Dictionary = {}) -> void:
	_camera = camera
	_vfx = vfx
	_sound = sound
	_blocked_query = blocked_query
	var applied_settings := SettingsStore.load_all() if settings.is_empty() else settings
	_shake_scale = clampf(float(applied_settings.get("screen_shake", 1.0)), 0.0, 1.0)
	_effect_scale = clampf(float(applied_settings.get("effect_intensity", 1.0)), 0.0, 1.0)
	_flash_scale = clampf(float(applied_settings.get("flash_intensity", 1.0)), 0.0, 1.0)
	_haptic_mode = str(applied_settings.get("haptics", "light"))
	if _vfx != null:
		_vfx.set_effect_intensity(_effect_scale)

func play_enemy_hit(event: Dictionary) -> void:
	if _blocked():
		return
	var tier := classify_hit(event)
	var critical := bool(event.get("critical", false))
	var dot := bool(event.get("dot", false))
	var killing_blow := bool(event.get("killing_blow", false))
	var elite := bool(event.get("elite", false))
	var boss := bool(event.get("boss", false))
	if killing_blow and boss and bool(event.get("custom_boss", false)):
		return
	if _vfx != null:
		_vfx.emit_hit(event)
	if killing_blow:
		if boss:
			_play_audio("elite_death", 0.22, -5.0, 4, 0.03)
			request_shake(TIER_MAJOR)
			request_hitstop(0.035, 0.18)
		elif elite:
			_play_audio("elite_death", 0.22, -7.0, 3, 0.04)
			request_shake(TIER_STRONG)
		else:
			_play_audio("enemy_death", 0.10, -15.0, 2, 0.05)
		return
	if dot:
		return
	if critical:
		_play_audio("combat_crit", 0.12, -10.0, 2, 0.035)
		if float(event.get("damage_ratio", 0.0)) >= 0.045:
			request_hitstop(0.024, 0.22)
	elif tier >= TIER_STRONG:
		_play_audio("combat_heavy", 0.10, -14.0, 2, 0.035)
	else:
		_play_audio("combat_hit", 0.085, -20.0, 1, 0.04)
	if tier >= TIER_MAJOR and not boss:
		request_shake(TIER_STRONG)

func play_blocked(position: Vector2, color: Color) -> void:
	if _blocked():
		return
	if _vfx != null:
		_vfx.emit_blocked(position, color)
	_play_audio("boss_blocked", 0.20, -11.0, 3, 0.015)

func play_player_damage(position: Vector2, damage_ratio: float) -> void:
	if _blocked():
		return
	var heavy := damage_ratio >= 0.14
	if _vfx != null:
		_vfx.emit_player_damage(position, heavy)
	_play_audio("player_hit", 0.16, -7.0 if heavy else -11.0, 4, 0.025)
	request_shake(TIER_STRONG if heavy else TIER_MINOR)
	_pulse_overlay(Color(0.88, 0.08, 0.06), 0.105 if heavy else 0.055)
	_request_haptic(TIER_STRONG if heavy else TIER_MINOR)

func play_heal(position: Vector2, major: bool = false) -> void:
	if _blocked():
		return
	if _vfx != null:
		_vfx.emit_heal(position, major)
	_play_audio("heal", 0.22, -10.0 if major else -15.0, 2, 0.025)
	_pulse_overlay(Color(0.18, 0.88, 0.42), 0.045 if major else 0.025)

func play_ultimate_activation(position: Vector2) -> void:
	if _blocked():
		return
	if _vfx != null:
		_vfx.emit_ultimate(position)
	_play_audio("ultimate", 0.45, -4.0, 4, 0.02)
	request_shake(TIER_MAJOR)
	request_hitstop(0.036, 0.18)
	_pulse_overlay(Color(1.0, 0.74, 0.16), 0.075)
	_request_haptic(TIER_MAJOR)

func play_signature(strength: float = 9.0) -> void:
	if _blocked():
		return
	_request_shake_values(clampf(strength, 0.0, 15.0) * _shake_scale, 0.32)
	request_hitstop(0.045, 0.16)
	_request_haptic(TIER_MAJOR)

func request_shake(tier: int) -> bool:
	if _blocked() or _camera == null or _shake_scale <= 0.0:
		return false
	var clamped_tier := clampi(tier, TIER_MINOR, TIER_SIGNATURE)
	var requested_amplitude := float(SHAKE_AMPLITUDES[clamped_tier]) * _shake_scale
	var requested_duration := float(SHAKE_DURATIONS[clamped_tier])
	_request_shake_values(requested_amplitude, requested_duration)
	return true

func _request_shake_values(requested_amplitude: float, requested_duration: float) -> void:
	var now := Time.get_ticks_usec()
	_shake_amplitude = maxf(_shake_amplitude, requested_amplitude)
	_shake_started_usec = now
	_shake_end_usec = maxi(_shake_end_usec, now + int(requested_duration * 1000000.0))

func request_hitstop(duration: float, factor: float) -> bool:
	var now := Time.get_ticks_usec()
	if _blocked() or now < _hitstop_next_usec:
		return false
	var safe_duration := clampf(duration, 0.010, 0.060)
	var safe_factor := clampf(factor, 0.12, 0.60)
	if not _hitstop_active:
		_restore_time_scale = Engine.time_scale
	_hitstop_active = true
	_hitstop_end_usec = maxi(_hitstop_end_usec, now + int(safe_duration * 1000000.0))
	_hitstop_next_usec = now + HITSTOP_COOLDOWN_USEC
	_owned_time_scale = minf(Engine.time_scale, safe_factor)
	Engine.time_scale = _owned_time_scale
	return true

func cancel_transients() -> void:
	_restore_hitstop(true)
	_shake_amplitude = 0.0
	_shake_end_usec = 0
	_overlay_alpha = 0.0
	if _overlay != null:
		_overlay.color.a = 0.0
	if _camera != null:
		_camera.offset = Vector2.ZERO
	if _vfx != null:
		_vfx.clear_transients()
	if _sound != null:
		_sound.clear_limits()

func cancel_shake() -> void:
	_shake_amplitude = 0.0
	_shake_end_usec = 0
	if _camera != null:
		_camera.offset = Vector2.ZERO

func debug_state() -> Dictionary:
	return {
		"hitstop_active":_hitstop_active,
		"shake_amplitude":_shake_amplitude,
		"shake_end_usec":_shake_end_usec,
		"shake_scale":_shake_scale,
		"flash_scale":_flash_scale,
		"haptic_mode":_haptic_mode,
		"effect_count":_vfx.active_effect_count() if _vfx != null else 0,
	}

static func classify_hit(event: Dictionary) -> int:
	if bool(event.get("signature", false)):
		return TIER_SIGNATURE
	if bool(event.get("ultimate", false)) or bool(event.get("elite", false)) and bool(event.get("killing_blow", false)):
		return TIER_MAJOR
	if bool(event.get("critical", false)) or float(event.get("damage_ratio", 0.0)) >= 0.10:
		return TIER_STRONG
	return TIER_MINOR

static func popup_priority(event: Dictionary) -> int:
	if bool(event.get("player_damage", false)):
		return 5
	if bool(event.get("critical", false)) or bool(event.get("ultimate", false)):
		return 4
	if bool(event.get("boss", false)):
		return 3
	if bool(event.get("dot", false)):
		return 1
	return 2

func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	if _blocked():
		_restore_hitstop(false)
		if _camera != null:
			_camera.offset = Vector2.ZERO
	else:
		_update_hitstop(now)
		_update_shake(now)
	_update_overlay(delta)

func _update_hitstop(now: int) -> void:
	if _hitstop_active and now >= _hitstop_end_usec:
		_restore_hitstop(false)

func _restore_hitstop(force: bool) -> void:
	if not _hitstop_active:
		return
	if force or is_equal_approx(Engine.time_scale, _owned_time_scale):
		Engine.time_scale = _restore_time_scale
	_hitstop_active = false
	_hitstop_end_usec = 0
	_owned_time_scale = Engine.time_scale

func _update_shake(now: int) -> void:
	if _camera == null:
		return
	if now >= _shake_end_usec or _shake_amplitude <= 0.0:
		_shake_amplitude = 0.0
		_camera.offset = Vector2.ZERO
		return
	var duration := maxf(float(_shake_end_usec - _shake_started_usec), 1.0)
	var remaining := clampf(float(_shake_end_usec - now) / duration, 0.0, 1.0)
	_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_amplitude * remaining

func _play_audio(cue: String, interval: float, volume_db: float, priority: int, pitch_variation: float) -> void:
	if _sound != null:
		_sound.play_limited(cue, interval, volume_db, 1.0, priority, pitch_variation)

func _pulse_overlay(color: Color, alpha: float) -> void:
	_overlay_color = color
	_overlay_alpha = maxf(_overlay_alpha, alpha * _effect_scale * _flash_scale)

func _update_overlay(delta: float) -> void:
	if _overlay == null:
		return
	_overlay_alpha = move_toward(_overlay_alpha, 0.0, 1.08 * delta)
	_overlay.color = Color(_overlay_color.r, _overlay_color.g, _overlay_color.b, _overlay_alpha)

func _request_haptic(tier: int) -> void:
	if OS.get_name() not in ["Android", "iOS"] or _haptic_mode == "off":
		return
	var strength := 0.35 if _haptic_mode == "light" else 0.70
	if tier >= TIER_MAJOR:
		strength = minf(1.0, strength + 0.20)
	Input.vibrate_handheld(18 if tier <= TIER_MINOR else 32 if tier == TIER_STRONG else 48, strength)

func _blocked() -> bool:
	if get_tree() == null or get_tree().paused:
		return true
	return _blocked_query.is_valid() and bool(_blocked_query.call())

func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 43
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	layer.add_child(_overlay)

func _exit_tree() -> void:
	cancel_transients()
