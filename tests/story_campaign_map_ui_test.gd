extends SceneTree

const StorySelectScene := preload("res://scenes/StorySelect.tscn")
const StoryNarrative := preload("res://scripts/story/StoryNarrative.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var story_select := StorySelectScene.instantiate()
	story_select.account_username = ""
	root.add_child(story_select)
	await process_frame
	await process_frame
	var content := story_select.find_child("CampaignContent", true, false) as Control
	assert(content != null)
	var campaign_scroll := story_select.find_child("CampaignScroll", true, false) as ScrollContainer
	assert(campaign_scroll != null)
	assert(campaign_scroll.scroll_deadzone == 24)
	for chapter_number in range(1, 6):
		var chapter_header := story_select.find_child("ChapterHeader_%d" % chapter_number, true, false) as Button
		assert(chapter_header != null)
		assert(chapter_header.text.find("/ 15 ★") >= 0)
		assert(chapter_header.tooltip_text == StoryNarrative.chapter_map_text(chapter_number, false))
	var stage_nodes := 0
	var stage_paths := 0
	for child in content.get_children():
		if child.name.begins_with("StageNode_"):
			stage_nodes += 1
		if child.name.begins_with("StagePath_"):
			stage_paths += 1
	assert(stage_nodes == 25)
	assert(stage_paths == 24)
	for button_variant in story_select.find_children("*", "Button", true, false):
		assert((button_variant as Button).text != "DEV STORY TEST")
	var first_stage := story_select.find_child("StageNode_ch1_1", true, false) as Button
	assert(first_stage != null)
	assert(first_stage.text.contains("C1S1"))
	assert(not first_stage.text.contains("Highest:"))
	var base_font := int(first_stage.get_meta("accessibility_base_font_size", first_stage.get_theme_font_size("font_size")))
	var map_extent: Vector2 = content.custom_minimum_size
	story_select.apply_accessibility_settings({"ui_scale":1.2})
	assert(first_stage.get_theme_font_size("font_size") == roundi(float(base_font) * 1.2))
	assert(content.custom_minimum_size == map_extent)
	story_select.apply_accessibility_settings({"ui_scale":0.8})
	assert(first_stage.get_theme_font_size("font_size") == roundi(float(base_font) * 0.8))
	var baseline_nodes := _descendant_count(story_select)
	story_select._show_stage_details(0)
	await process_frame
	assert(_descendant_count(story_select) > baseline_nodes)
	story_select._show_mutator_selector()
	story_select.apply_accessibility_settings({"ui_scale":1.2})
	await process_frame
	var mutator_scroll := story_select.find_child("MutatorScroll", true, false) as ScrollContainer
	var mutator_list := story_select.find_child("MutatorList", true, false) as Control
	assert(mutator_scroll != null)
	assert(mutator_list != null)
	assert(mutator_list.get_global_rect().position.x >= mutator_scroll.get_global_rect().position.x - 2.0)
	assert(mutator_list.get_global_rect().end.x <= mutator_scroll.get_global_rect().end.x + 2.0)
	story_select._close_mutator_selector()
	await process_frame
	await process_frame
	story_select._close_stage_details()
	await process_frame
	await process_frame
	assert(_descendant_count(story_select) == baseline_nodes)
	story_select._show_chapter_mastery(1)
	await process_frame
	assert(story_select.find_child("ChapterMasteryLayer", true, false) != null)
	assert(story_select.find_child("MasteryReward_ch1_mastery_5", true, false) != null)
	story_select._close_chapter_mastery()
	await process_frame
	await process_frame
	assert(_descendant_count(story_select) == baseline_nodes)
	story_select._show_boss_practice_roster()
	await process_frame
	story_select._close_boss_practice()
	await process_frame
	await process_frame
	assert(_descendant_count(story_select) == baseline_nodes)
	for rebuild_index in 5:
		story_select._build_map(true)
		await process_frame
		await process_frame
		assert(_descendant_count(story_select) == baseline_nodes, str(rebuild_index))
	print("Story Campaign Map UI tests passed: 25 nodes · 24 paths · 5 chapters · Mastery/details/practice cleanup · 5 rebuilds · %d live UI nodes" % baseline_nodes)
	story_select.queue_free()
	await process_frame
	quit(0)

func _descendant_count(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _descendant_count(child)
	return total
