class_name HomeState
extends RefCounted

const StoryCampaignMapClass := preload("res://scripts/story/StoryCampaignMap.gd")

static func story_summary(profile: Dictionary) -> Dictionary:
	var complete := StoryCampaignMapClass.campaign_complete(profile)
	var stage_index := StoryCampaignMapClass.current_stage_index(profile)
	var state := StoryCampaignMapClass.stage_state(profile, stage_index)
	var chapter_number := int(state.get("chapter", 1))
	var chapter := StoryCampaignMapClass.chapter_state(profile, chapter_number)
	var mastery := StoryStore.campaign_mastery(profile)
	var claimable_count := 0
	var claimable_chapter := 0
	for number in range(1, StoryCampaignMapClass.CHAPTER_COUNT + 1):
		var available := StoryStore.available_mastery_rewards(profile, number).size()
		claimable_count += available
		if claimable_chapter == 0 and available > 0:
			claimable_chapter = number
	var chapter_path: Array[String] = []
	for chapter_stage in range(1, StoryCampaignMapClass.STAGES_PER_CHAPTER + 1):
		var path_index := (chapter_number - 1) * StoryCampaignMapClass.STAGES_PER_CHAPTER + chapter_stage - 1
		var path_state := StoryCampaignMapClass.stage_state(profile, path_index)
		chapter_path.append("✓" if bool(path_state.get("cleared", false)) else ("●" if path_index == stage_index else "○"))
	return {
		"campaign_complete":complete,
		"campaign_mastered":mastery >= 75,
		"campaign_mastery":mastery,
		"cleared_count":min((profile.get("cleared", []) as Array).size(), StoryStore.stage_count()),
		"stage_index":stage_index,
		"stage_id":str(state.get("id", "ch1_1")),
		"chapter":chapter_number,
		"chapter_stage":int(state.get("chapter_stage", 1)),
		"stage_title":str(state.get("title", "Story Stage")),
		"stage_mastery":int(state.get("mastery", 0)),
		"chapter_cleared":int(chapter.get("cleared", 0)),
		"chapter_mastery":int(chapter.get("mastery", 0)),
		"chapter_path":"  ".join(chapter_path),
		"chapter_reward_pending":bool(chapter.get("complete", false)) and not bool(chapter.get("claimed", false)),
		"claimable_mastery_count":claimable_count,
		"claimable_mastery_chapter":claimable_chapter,
	}

static func merge_ready_count(stash: Array) -> int:
	var ready_keys: Dictionary = {}
	for item_variant in stash:
		if not item_variant is Dictionary:
			continue
		var ring := item_variant as Dictionary
		if str(RingStore.normalize_ring(ring).get("rarity", "common")).to_lower() == "legendary":
			continue
		var merge_key := RingStore.ring_merge_key(ring)
		if not ready_keys.has(merge_key) and RingStore.count_merge_matches(stash, ring) >= 3:
			ready_keys[merge_key] = true
	return ready_keys.size()

static func build_items(username: String, character_id: String) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var rings := RingStore.get_equipped_rings(username, character_id)
	var artifacts := ArtifactStore.get_equipped_artifacts(username, character_id)
	for slot in ["slot_0", "slot_1"]:
		var ring_variant = rings.get(slot, null)
		if ring_variant is Dictionary:
			var ring := ring_variant as Dictionary
			items.append({"name":str(ring.get("name", "Ring")), "icon":RingStore.ring_icon_path(ring)})
	for slot in ["slot_0", "slot_1"]:
		var artifact_variant = artifacts.get(slot, null)
		if artifact_variant is Dictionary:
			var artifact := artifact_variant as Dictionary
			items.append({"name":str(artifact.get("name", "Artifact")), "icon":ArtifactStore.artifact_icon_path(artifact)})
	return items
