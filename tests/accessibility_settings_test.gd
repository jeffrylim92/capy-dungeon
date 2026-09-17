extends SceneTree

const SettingsStoreClass := preload("res://scripts/SettingsStore.gd")
const JoystickVisualClass := preload("res://scripts/JoystickVisual.gd")
const CombatReadabilityClass := preload("res://scripts/CombatReadability.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_validation_and_migration()
	_test_non_compounding_ui_scale()
	_test_touch_and_readability_live_values()
	print("Accessibility settings tests passed: validation · legacy migration · bounded UI scaling · control/readability hooks")
	quit(0)

func _test_validation_and_migration() -> void:
	var normalized := SettingsStoreClass.normalize({
		"frame_rate":44,
		"ui_scale":9.0,
		"objective_text_scale":0.1,
		"hud_opacity":-4.0,
		"screen_shake":0.48,
		"player_effects":"INVALID",
		"player_outline":1.44,
		"haptics":"OFF",
		"damage_numbers":false,
		"hazard_patterns":"ENHANCED",
		"touch_control_scale":1.17,
		"touch_control_opacity":4.0,
		"high_contrast_telegraphs":"false",
	})
	assert(is_equal_approx(float(normalized["ui_scale"]), 1.2))
	assert(int(normalized["frame_rate"]) == 30)
	assert(SettingsStoreClass.frame_rate_cap({"frame_rate":60}) == 60)
	assert(SettingsStoreClass.frame_rate_cap({"frame_rate":29}) == 30)
	assert(is_equal_approx(float(normalized["objective_text_scale"]), 0.9))
	assert(is_equal_approx(float(normalized["hud_opacity"]), 0.8))
	assert(is_equal_approx(float(normalized["screen_shake"]), 0.5))
	assert(str(normalized["player_effects"]) == "high")
	assert(is_equal_approx(float(normalized["player_outline"]), 1.5))
	assert(str(normalized["haptics"]) == "off")
	assert(str(normalized["damage_numbers"]) == "off")
	assert(str(normalized["hazard_patterns"]) == "enhanced")
	assert(not bool(normalized["high_contrast_telegraphs"]))
	assert(is_equal_approx(float(normalized["touch_control_scale"]), 1.2))
	assert(is_equal_approx(float(normalized["touch_control_opacity"]), 1.0))
	var corrupt := SettingsStoreClass.normalize({"ui_scale":{}, "muted":[], "player_outline":"normal", "touch_control_scale":"large"})
	assert(is_equal_approx(float(corrupt["ui_scale"]), 1.0))
	assert(not bool(corrupt["muted"]))
	assert(is_equal_approx(float(corrupt["player_outline"]), 1.0))
	assert(is_equal_approx(float(corrupt["touch_control_scale"]), 1.2))

func _test_non_compounding_ui_scale() -> void:
	var root_control := Control.new()
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 20)
	label.custom_minimum_size = Vector2(100.0, 40.0)
	root_control.add_child(label)
	SettingsStoreClass.apply_ui_scale(root_control, 1.2)
	assert(label.get_theme_font_size("font_size") == 24)
	assert(label.custom_minimum_size.is_equal_approx(Vector2(120.0, 48.0)))
	SettingsStoreClass.apply_ui_scale(root_control, 0.8)
	assert(label.get_theme_font_size("font_size") == 16)
	assert(label.custom_minimum_size.is_equal_approx(Vector2(80.0, 32.0)))
	root_control.free()

func _test_touch_and_readability_live_values() -> void:
	var joystick := JoystickVisualClass.new()
	joystick.configure(1.2, 0.35)
	assert(is_equal_approx(joystick.travel_radius(), 96.0))
	assert(is_equal_approx(joystick.control_opacity, 0.35))
	joystick.free()
	var readability := CombatReadabilityClass.new()
	readability.configure({
		"damage_numbers":"critical_only",
		"high_contrast_telegraphs":true,
		"hazard_patterns":"enhanced",
		"color_independent_indicators":true,
	})
	var state := readability.debug_state()
	assert(bool(state["high_contrast"]))
	assert(bool(state["enhanced_patterns"]))
	assert(bool(state["show_symbols"]))
	assert(str(state["damage_number_mode"]) == "critical_only")
	readability.free()
