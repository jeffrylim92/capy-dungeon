extends SceneTree

const StorySelectScene := preload("res://scenes/StorySelect.tscn")
const TEST_USERNAME := "__story_run_history_ui_test__"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var story_select := StorySelectScene.instantiate()
	story_select.account_username = ""
	root.add_child(story_select)
	await process_frame
	assert(story_select.find_child("RecentRunsButton", true, false) != null)
	story_select._show_run_history()
	await process_frame
	assert(story_select.find_child("StoryRunHistory", true, false) != null)
	assert(story_select.find_child("RunHistoryScroll", true, false) != null)
	story_select._close_run_history()
	await process_frame
	await process_frame
	var records: Array = []
	for index in 6:
		records.append({"record_version":1, "run_id":"ui-%d" % index, "context":"story", "stage_id":"ch1_1", "stage_name":"1-1 The Broken Trail", "chapter":1, "difficulty":"normal", "timestamp":1000 + index, "completed":true, "duration_seconds":90.0 + index, "final_level":4, "mutator_ids":[], "mastery_completed":[], "mastery_newly_earned":[], "skills":[], "rings":[], "artifacts":[], "damage_summary":[], "total_damage":0.0, "damage_taken":0.0, "healing":0.0, "kills":0, "boss_damage":0.0, "revives":0})
	StoryStore.purge_user(TEST_USERNAME)
	StoryStore.replace_profile(TEST_USERNAME, {"story_run_history":records})
	story_select.account_username = TEST_USERNAME
	story_select._show_run_history()
	await process_frame
	var entry_count := 0
	for node in story_select.find_children("RunHistoryEntry_*", "Button", true, false):
		entry_count += 1
	assert(entry_count == 6)
	story_select._close_run_history()
	await process_frame
	await process_frame
	for index in range(6, 20):
		var extra := (records[0] as Dictionary).duplicate(true); extra["run_id"] = "ui-%d" % index; extra["timestamp"] = 1000 + index; records.append(extra)
	StoryStore.replace_profile(TEST_USERNAME, {"story_run_history":records})
	story_select._show_run_history()
	await process_frame
	entry_count = story_select.find_children("RunHistoryEntry_*", "Button", true, false).size()
	assert(entry_count == 20)
	var record := (records[0] as Dictionary).duplicate(true); record["skills"] = [{"id":"fireball", "name":"Fireball", "level":2}]; record["damage_summary"] = [{"source_id":"fireball", "damage":120.0}]; record["total_damage"] = 120.0
	story_select._show_run_history_detail(record)
	await process_frame
	assert(story_select.find_child("StoryRunHistoryDetail", true, false) != null)
	story_select._close_run_history_detail()
	await process_frame
	await process_frame
	assert(story_select.find_child("StoryRunHistoryDetail", true, false) == null)
	story_select._close_run_history()
	await process_frame
	await process_frame
	assert(story_select.find_child("StoryRunHistory", true, false) == null)
	story_select.queue_free()
	await process_frame
	StoryStore.purge_user(TEST_USERNAME)
	print("Story Run History UI tests passed: footer entry, empty state, six/20 records, detail, modal cleanup")
	quit(0)
