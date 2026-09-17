class_name StoryCampaignMap
extends RefCounted

const STAGES_PER_CHAPTER: int = 5
const CHAPTER_COUNT: int = 5
const NODE_SIDE_OFFSETS: Array[float] = [-104.0, 86.0, -72.0, 96.0, -8.0]
const CHAPTER_COLORS: Array[Color] = [
	Color("5fa85c"),
	Color("79c9ef"),
	Color("70b14b"),
	Color("e27a32"),
	Color("8755c7"),
]

static func stage_unlocked(profile: Dictionary, stage_index: int) -> bool:
	var safe_index := clampi(stage_index, 0, StoryStore.stage_count() - 1)
	var stage_id := str(StoryStore.stage(safe_index).get("id", ""))
	return stage_id in (profile.get("cleared", []) as Array) or safe_index <= StoryStore.unlocked_stage(profile)

static func current_stage_index(profile: Dictionary) -> int:
	return StoryStore.stage_count() - 1 if campaign_complete(profile) else StoryStore.unlocked_stage(profile)

static func path_active(profile: Dictionary, from_stage_index: int) -> bool:
	var safe_index := clampi(from_stage_index, 0, StoryStore.stage_count() - 2)
	var stage_id := str(StoryStore.stage(safe_index).get("id", ""))
	return stage_id in (profile.get("cleared", []) as Array) and stage_unlocked(profile, safe_index + 1)

static func stage_state(profile: Dictionary, stage_index: int) -> Dictionary:
	var safe_index := clampi(stage_index, 0, StoryStore.stage_count() - 1)
	var stage := StoryStore.stage(safe_index)
	var stage_id := str(stage.get("id", ""))
	var cleared := stage_id in (profile.get("cleared", []) as Array)
	var unlocked := stage_unlocked(profile, safe_index)
	var mastery := StoryStore.stage_mastery(profile, stage_id)
	var highest_rank := StoryStore.highest_cleared_difficulty(profile, stage_id)
	return {
		"index":safe_index,
		"id":stage_id,
		"chapter":int(stage.get("chapter", 1)),
		"chapter_stage":int(stage.get("chapter_stage", 1)),
		"title":_stage_title(stage),
		"boss":int(stage.get("chapter_stage", 1)) == STAGES_PER_CHAPTER,
		"unlocked":unlocked,
		"cleared":cleared,
		"current":unlocked and not cleared and safe_index == current_stage_index(profile),
		"mastery":mastery,
		"mastered":mastery >= 3,
		"highest_difficulty_rank":highest_rank,
		"highest_difficulty":"NONE" if highest_rank < 0 else StoryStore.highest_cleared_difficulty_name(profile, stage_id).to_upper(),
	}

static func chapter_state(profile: Dictionary, chapter_number: int) -> Dictionary:
	var safe_chapter := clampi(chapter_number, 1, CHAPTER_COUNT)
	var cleared_count := 0
	for stage_number in range(1, STAGES_PER_CHAPTER + 1):
		if "ch%d_%d" % [safe_chapter, stage_number] in (profile.get("cleared", []) as Array):
			cleared_count += 1
	var mastery := StoryStore.chapter_mastery(profile, safe_chapter)
	var available_rewards := StoryStore.available_mastery_rewards(profile, safe_chapter)
	return {
		"chapter":safe_chapter,
		"cleared":cleared_count,
		"complete":StoryStore.is_chapter_complete(profile, safe_chapter),
		"claimed":StoryStore.is_chapter_claimed(profile, safe_chapter),
		"mastery":mastery,
		"mastered":mastery >= 15,
		"mastery_rewards_available":available_rewards.size(),
		"unlocked":stage_unlocked(profile, (safe_chapter - 1) * STAGES_PER_CHAPTER),
	}

static func campaign_complete(profile: Dictionary) -> bool:
	return bool(profile.get("story_complete", false))

static func stage_position(stage_index: int, map_width: float, chapter_height: float, node_gap: float, chapter_top: float) -> Vector2:
	var safe_index := clampi(stage_index, 0, StoryStore.stage_count() - 1)
	var chapter_index := floori(float(safe_index) / float(STAGES_PER_CHAPTER))
	var chapter_stage_index := safe_index % STAGES_PER_CHAPTER
	var offset_scale := minf(1.0, map_width / 1080.0)
	return Vector2(
		map_width * 0.5 + NODE_SIDE_OFFSETS[chapter_stage_index] * offset_scale,
		float(chapter_index) * chapter_height + chapter_top + float(chapter_stage_index) * node_gap
	)

static func chapter_color(chapter_number: int) -> Color:
	return CHAPTER_COLORS[clampi(chapter_number - 1, 0, CHAPTER_COLORS.size() - 1)]

static func validate() -> Array[String]:
	var issues: Array[String] = []
	if StoryStore.stage_count() != CHAPTER_COUNT * STAGES_PER_CHAPTER:
		issues.append("Campaign map expects exactly 25 Story stages.")
	if NODE_SIDE_OFFSETS.size() != STAGES_PER_CHAPTER:
		issues.append("Campaign map requires one side offset per chapter stage.")
	issues.append_array(StoryStore.validate_mastery_rewards())
	var ids: Dictionary = {}
	for stage_index in StoryStore.stage_count():
		var stage_id := str(StoryStore.stage(stage_index).get("id", ""))
		if stage_id.is_empty() or ids.has(stage_id):
			issues.append("Duplicate or empty Story stage ID: %s" % stage_id)
		ids[stage_id] = true
	return issues

static func _stage_title(stage: Dictionary) -> String:
	var display_name := str(stage.get("name", "Story Stage"))
	var separator := display_name.find("  ")
	return display_name.substr(separator + 2) if separator >= 0 else display_name
