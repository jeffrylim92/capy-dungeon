extends SceneTree

const HomeStateClass := preload("res://scripts/ui/HomeState.gd")
const LobbyScene := preload("res://scenes/Lobby.tscn")
const StorySelectScene := preload("res://scenes/StorySelect.tscn")

var _failures: Array[String] = []

func _initialize() -> void:
	_test_story_states()
	_test_attention_rules()
	call_deferred("_test_home_runtime")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _profile(cleared_count: int, mastered: bool = false) -> Dictionary:
	var cleared: Array[String] = []
	var mastery: Dictionary = {}
	for index in cleared_count:
		var stage_id := str(StoryStore.stage(index).get("id", ""))
		cleared.append(stage_id)
		if mastered:
			var ids: Array[String] = []
			for objective_variant in StoryStore.mastery_objectives(stage_id):
				ids.append(str((objective_variant as Dictionary).get("id", "")))
			mastery[stage_id] = ids
	return {"cleared":cleared, "claimed_chapters":[1, 2, 3, 4, 5], "difficulty_clears":{}, "mastery":mastery, "mastery_rewards_claimed":[], "story_complete":cleared_count >= 25}

func _test_story_states() -> void:
	var fresh := HomeStateClass.story_summary(_profile(0))
	_expect(int(fresh.stage_index) == 0 and int(fresh.chapter) == 1 and int(fresh.chapter_stage) == 1, "Fresh save must continue at C1S1")
	var mid := HomeStateClass.story_summary(_profile(8))
	_expect(int(mid.stage_index) == 8 and int(mid.chapter) == 2 and int(mid.chapter_stage) == 4, "Mid-campaign save must continue at the real unlocked stage")
	var chapter_gate_profile := _profile(5)
	chapter_gate_profile["claimed_chapters"] = []
	var chapter_gate := HomeStateClass.story_summary(chapter_gate_profile)
	_expect(bool(chapter_gate.chapter_reward_pending) and int(chapter_gate.stage_index) == 4, "Unclaimed chapter completion must route to its real reward gate")
	var complete := HomeStateClass.story_summary(_profile(25))
	_expect(bool(complete.campaign_complete) and int(complete.stage_index) == 24, "Completed Story must open the map at the final stage")
	var mastered := HomeStateClass.story_summary(_profile(25, true))
	_expect(bool(mastered.campaign_mastered) and int(mastered.campaign_mastery) == 75, "75/75 must show Campaign Mastered")
	var practice_copy := _profile(8)
	var before := practice_copy.duplicate(true)
	HomeStateClass.story_summary(practice_copy)
	_expect(practice_copy == before, "Home derivation must not mutate real progress for dev/practice presentation")

func _test_attention_rules() -> void:
	var reward_profile := _profile(2)
	var objectives: Array = StoryStore.mastery_objectives("ch1_1")
	reward_profile["mastery"] = {"ch1_1":[str((objectives[0] as Dictionary).get("id", "")), str((objectives[1] as Dictionary).get("id", "")), str((objectives[2] as Dictionary).get("id", ""))], "ch1_2":[str((StoryStore.mastery_objectives("ch1_2")[0] as Dictionary).get("id", "")), str((StoryStore.mastery_objectives("ch1_2")[1] as Dictionary).get("id", ""))]}
	var reward := HomeStateClass.story_summary(reward_profile)
	_expect(int(reward.claimable_mastery_count) == 1 and int(reward.claimable_mastery_chapter) == 1, "Available Mastery reward must produce a genuine deep-link indicator")
	var ring := {"id":"ring_test", "attr":"attack", "rarity":"common", "tier":1, "value":0.1}
	_expect(HomeStateClass.merge_ready_count([ring, ring.duplicate(), ring.duplicate()]) == 1, "Three matching rings must produce one merge-ready group")
	ring["rarity"] = "legendary"
	_expect(HomeStateClass.merge_ready_count([ring, ring.duplicate(), ring.duplicate()]) == 0, "Legendary rings must not claim merge readiness")

func _test_home_runtime() -> void:
	var lobby := LobbyScene.instantiate()
	lobby.account = {"username":"__home_ui_test__", "display_name":"Test Capy", "favorite_capy":"capy_zoomer"}
	root.add_child(lobby)
	await process_frame
	var continue_button := lobby.find_child("ContinueStoryButton", true, false) as Button
	var build_button := lobby.find_child("BuildPreviewButton", true, false) as Button
	_expect(continue_button != null and build_button != null, "Home hierarchy must include Continue Story and Build preview")
	var home_node_count := _descendant_count(lobby)
	_expect(home_node_count <= 90, "Initial Home must stay lightweight (found %d nodes)" % home_node_count)
	_expect(lobby._play_hub_layer == null, "Secondary More content must be lazy-loaded")
	lobby._show_play_hub()
	await process_frame
	_expect(_descendant_count(lobby) > home_node_count, "More content must load only when requested")
	lobby._close_play_hub()
	await process_frame
	await process_frame
	_expect(_descendant_count(lobby) == home_node_count, "Closing More must release its secondary UI")
	var signal_state := {"count":0}
	lobby.continue_story_requested.connect(func(_stage_index: int) -> void: signal_state.count = int(signal_state.count) + 1)
	lobby.story_requested.connect(func() -> void: signal_state.count = int(signal_state.count) + 1)
	if continue_button != null:
		continue_button.pressed.emit()
		continue_button.pressed.emit()
	_expect(int(signal_state.count) == 1, "Rapid taps must emit only one navigation request")
	lobby.apply_accessibility_settings({"ui_scale":0.8})
	var small_height := continue_button.custom_minimum_size.y if continue_button != null else 0.0
	lobby.apply_accessibility_settings({"ui_scale":1.2})
	_expect(continue_button != null and continue_button.custom_minimum_size.y > small_height, "Home must support 80%-120% UI scale")
	var methods: Array[String] = []
	for method in lobby.get_script().get_script_method_list():
		methods.append(str((method as Dictionary).get("name", "")))
	_expect("_process" not in methods, "Home must not poll or animate continuously")
	lobby.queue_free()
	await process_frame
	var story_details := StorySelectScene.instantiate()
	story_details.account_username = ""
	story_details.initial_stage_index = 0
	story_details.open_stage_details_on_ready = true
	root.add_child(story_details)
	await process_frame
	await process_frame
	_expect(story_details._details_layer != null, "Continue deep link must open the existing Stage Details panel")
	story_details.queue_free()
	await process_frame
	var mastery_panel := StorySelectScene.instantiate()
	mastery_panel.account_username = ""
	mastery_panel.initial_mastery_chapter = 1
	root.add_child(mastery_panel)
	await process_frame
	await process_frame
	_expect(mastery_panel.find_child("ChapterMasteryLayer", true, false) != null, "Reward deep link must open the existing Chapter Mastery panel")
	mastery_panel.queue_free()
	await process_frame
	if _failures.is_empty():
		print("HOME_PLAYER_JOURNEY_TEST: PASS · %d initial Home nodes" % home_node_count)
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		print("HOME_PLAYER_JOURNEY_TEST: FAIL (%d)" % _failures.size())
		quit(1)

func _descendant_count(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _descendant_count(child)
	return total
