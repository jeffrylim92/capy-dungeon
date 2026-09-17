extends SceneTree

const Narrative := preload("res://scripts/story/StoryNarrative.gd")
const NarrativeRuntime := preload("res://scripts/story/StoryNarrativeRuntime.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var runtime := NarrativeRuntime.new()
	root.add_child(runtime)
	await process_frame
	_test_intro_dedup_and_priority(runtime)
	_test_stale_and_bounded_queue(runtime)
	await _test_pause_freeze(runtime)
	_test_tap_dismiss_and_retry(runtime)
	_test_practice_and_shutdown_isolation(runtime)
	runtime.queue_free()
	await process_frame
	print("Story Narrative Runtime tests passed: dedup · priority · stale queue · tap · retry · Practice isolation · cleanup")
	quit(0)

func _test_intro_dedup_and_priority(runtime: NarrativeRuntime) -> void:
	runtime.configure("ch1_1")
	assert(runtime.trigger_intro())
	assert(runtime.active_event_id() == "c1s1_intro")
	assert(not runtime.trigger_intro())
	assert(runtime.trigger("c1s1_route_choice"))
	assert(runtime.queue_size() == 1)
	assert(runtime.trigger("c1s1_first_interception"))
	assert(runtime.active_event_id() == "c1s1_first_interception")
	assert(runtime.has_seen("c1s1_route_choice"))

func _test_stale_and_bounded_queue(runtime: NarrativeRuntime) -> void:
	runtime.advance(6.1)
	assert(runtime.active_event_id().is_empty())
	runtime.configure("ch5_5")
	assert(runtime.trigger_intro())
	for event_id in Narrative.event_ids("ch5_5"):
		if event_id != "c5s5_intro":
			runtime.trigger(event_id)
	assert(runtime.queue_size() <= NarrativeRuntime.MAX_QUEUE)

func _test_pause_freeze(runtime: NarrativeRuntime) -> void:
	runtime.configure("ch1_1")
	assert(runtime.trigger_intro())
	var active_before := runtime.active_event_id()
	await process_frame
	await process_frame
	assert(runtime.active_event_id() == active_before)

func _test_tap_dismiss_and_retry(runtime: NarrativeRuntime) -> void:
	runtime.configure("ch1_1")
	assert(runtime.trigger_intro())
	var panel := runtime.find_child("StoryNarrativePanel", true, false) as Button
	assert(panel != null)
	assert(panel.visible)
	assert(panel.position.y >= 424.0)
	assert(panel.size.x <= root.get_viewport().get_visible_rect().size.x - 120.0)
	panel.pressed.emit()
	assert(runtime.active_event_id().is_empty())
	runtime.reset_attempt()
	assert(not runtime.has_seen("c1s1_intro"))
	assert(runtime.queue_size() == 0)
	assert(runtime.trigger_intro())

func _test_practice_and_shutdown_isolation(runtime: NarrativeRuntime) -> void:
	runtime.configure("ch5_5", false)
	assert(not runtime.is_enabled())
	assert(not runtime.trigger_intro())
	assert(runtime.active_event_id().is_empty())
	runtime.configure("ch5_5", true)
	assert(runtime.trigger_intro())
	runtime.shutdown()
	assert(not runtime.is_enabled())
	assert(runtime.active_event_id().is_empty())
	assert(runtime.queue_size() == 0)
	var panel := runtime.find_child("StoryNarrativePanel", true, false) as Button
	assert(panel != null and not panel.visible)
