extends SceneTree

const StorySelectScene := preload("res://scenes/StorySelect.tscn")
const TEST_USERNAME := "__story_records_ui_test__"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	StoryStore.purge_user(TEST_USERNAME)
	var mastery_ids: Array[String] = []
	for objective_variant in StoryStore.mastery_objectives("ch1_1").slice(0, 2):
		mastery_ids.append(str((objective_variant as Dictionary).get("id", "")))
	var profile := {
		"cleared":["ch1_1"], "difficulty_clears":{"ch1_1":"hard"}, "mastery":{"ch1_1":mastery_ids},
		"story_records_version":1,
		"story_records":{"ch1_1":{
			"best_time":{"value":266.0, "difficulty":"hard", "mutator_ids":["glass_capy"], "run_id":"pr-time", "timestamp":1000},
			"lowest_damage":{"value":820.0, "difficulty":"normal", "mutator_ids":[], "run_id":"pr-damage", "timestamp":1001},
			"highest_challenge":{"value":0.5, "difficulty":"hard", "mutator_ids":["glass_capy", "no_healing"], "run_id":"pr-challenge", "timestamp":1002},
		}},
	}
	StoryStore.replace_profile(TEST_USERNAME, profile)
	var story_select := StorySelectScene.instantiate()
	story_select.account_username = TEST_USERNAME
	root.add_child(story_select)
	await process_frame
	await process_frame
	story_select._show_stage_details(0)
	await process_frame
	var panel := story_select.find_child("PersonalBestPanel", true, false) as PanelContainer
	var details := story_select.find_child("PersonalBestDetails", true, false) as Label
	assert(panel != null)
	assert(details != null)
	assert(not details.visible)
	var toggle := story_select.find_child("PersonalBestToggle", true, false) as Button
	assert(toggle != null)
	toggle.pressed.emit()
	assert(details.visible)
	assert(details.text.contains("Time: 04:26 · HARD + Glass Capy"))
	assert(details.text.contains("Damage Taken: 820"))
	assert(details.text.contains("Highest Difficulty: HARD"))
	assert(details.text.contains("Mastery: ★★☆"))
	assert(details.text.contains("Highest Challenge: +50%"))
	var base_font := int(details.get_meta("accessibility_base_font_size", details.get_theme_font_size("font_size")))
	story_select.apply_accessibility_settings({"ui_scale":1.2})
	assert(details.get_theme_font_size("font_size") == roundi(float(base_font) * 1.2))
	story_select.apply_accessibility_settings({"ui_scale":0.8})
	assert(details.get_theme_font_size("font_size") == roundi(float(base_font) * 0.8))
	story_select._close_stage_details()
	await process_frame
	await process_frame
	assert(story_select.find_child("PersonalBestPanel", true, false) == null)
	story_select.queue_free()
	await process_frame
	StoryStore.purge_user(TEST_USERNAME)
	print("Story Records UI tests passed: compact summary, Details toggle, contexts, 0.8x/1.2x scaling, cleanup")
	quit(0)
