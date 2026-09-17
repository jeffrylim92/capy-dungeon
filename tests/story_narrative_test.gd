extends SceneTree

const Narrative := preload("res://scripts/story/StoryNarrative.gd")
const ChapterFiveController := preload("res://scripts/story/ChapterFiveStageController.gd")

func _init() -> void:
	_test_complete_campaign_coverage()
	_test_line_contracts()
	_test_gameplay_event_registration()
	_test_puzzle_safety()
	_test_chapter_map_framing()
	print("Story Narrative tests passed: 25 stages · stable IDs · mobile limits · puzzle safety · chapter framing")
	quit(0)

func _test_complete_campaign_coverage() -> void:
	assert(Narrative.validate().is_empty(), str(Narrative.validate()))
	assert(Narrative.STAGES.size() == 25)
	var global_ids: Dictionary = {}
	for stage_index in StoryStore.stage_count():
		var stage_id := str(StoryStore.stage(stage_index).get("id", ""))
		assert(Narrative.STAGES.has(stage_id), stage_id)
		var stage_data: Dictionary = Narrative.STAGES[stage_id] as Dictionary
		assert(not (stage_data.get("intro", {}) as Dictionary).is_empty(), stage_id)
		assert(not (stage_data.get("outro", {}) as Dictionary).is_empty(), stage_id)
		assert((stage_data.get("mid", {}) as Dictionary).size() >= 2, stage_id)
		assert(not Narrative.result_text(stage_id).is_empty(), stage_id)
		for event_id in Narrative.event_ids(stage_id):
			assert(not global_ids.has(event_id), event_id)
			global_ids[event_id] = stage_id

func _test_line_contracts() -> void:
	for stage_id_variant in Narrative.STAGES:
		var stage_id := str(stage_id_variant)
		var stage_data: Dictionary = Narrative.STAGES[stage_id] as Dictionary
		var lines: Array[Dictionary] = []
		lines.append(stage_data.intro as Dictionary)
		lines.append(stage_data.outro as Dictionary)
		for mid_variant in (stage_data.mid as Dictionary).values():
			lines.append(mid_variant as Dictionary)
		for line in lines:
			assert(str(line.get("speaker", "")) in Narrative.SPEAKERS, stage_id)
			assert(not str(line.get("text", "")).is_empty(), stage_id)
			assert(str(line.get("text", "")).length() <= 130, stage_id)
		var intro := Narrative.intro(stage_id)
		assert(float(intro.duration) >= 2.4 and float(intro.duration) <= 4.0, stage_id)
		assert(int(intro.priority) >= Narrative.PRIORITY_FLAVOUR and int(intro.priority) <= Narrative.PRIORITY_CRITICAL, stage_id)

func _test_gameplay_event_registration() -> void:
	var match_source := FileAccess.get_file_as_string("res://scripts/Match.gd")
	assert(not match_source.is_empty())
	for stage_id_variant in Narrative.STAGES:
		var stage_data: Dictionary = Narrative.STAGES[stage_id_variant] as Dictionary
		for event_id_variant in (stage_data.mid as Dictionary):
			var event_id := str(event_id_variant)
			assert(match_source.find('"%s"' % event_id) >= 0, "Narrative event has no gameplay registration: %s" % event_id)

func _test_puzzle_safety() -> void:
	var protected_stages := ["ch2_3", "ch2_4", "ch5_3"]
	var forbidden := ["correct", "answer", "solution", "chest 1", "chest 2", "chest 3", "chest 4", "chest 5", "chest 6"]
	for stage_id in protected_stages:
		var serialized := str(Narrative.STAGES[stage_id]).to_lower()
		for forbidden_text in forbidden:
			assert(not _contains_word(serialized, str(forbidden_text)), "%s leaked puzzle token: %s" % [stage_id, forbidden_text])
	var mirror_text := str(Narrative.STAGES["ch5_3"]).to_lower()
	for symbol in ChapterFiveController.MIRROR_SYMBOLS:
		assert(not _contains_word(mirror_text, str(symbol).to_lower()), "ch5_3 leaked mirror symbol: %s" % symbol)
	for direction in ChapterFiveController.MIRROR_DIRECTIONS:
		assert(not _contains_word(mirror_text, str(direction).to_lower()), "ch5_3 leaked mirror direction: %s" % direction)

func _test_chapter_map_framing() -> void:
	assert(Narrative.CHAPTER_MAP_TEXT.size() == 5)
	for chapter_number in range(1, 6):
		var active := Narrative.chapter_map_text(chapter_number, false)
		var resolved := Narrative.chapter_map_text(chapter_number, true)
		assert(not active.is_empty(), str(chapter_number))
		assert(not resolved.is_empty(), str(chapter_number))
		assert(active != resolved, str(chapter_number))

func _contains_word(text_value: String, word: String) -> bool:
	var expression := RegEx.new()
	assert(expression.compile("(^|[^a-z0-9])%s([^a-z0-9]|$)" % word) == OK)
	return expression.search(text_value) != null
