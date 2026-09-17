class_name StoryNarrative
extends RefCounted

const PRIORITY_FLAVOUR: int = 1
const PRIORITY_WARNING: int = 2
const PRIORITY_MECHANIC: int = 3
const PRIORITY_CRITICAL: int = 4

const SPEAKERS: Array[String] = ["Narrator", "Scout", "Captive", "Herbalist", "Forge Keeper", "Spirit", "Freed Spirit"]

const CHAPTER_MAP_TEXT: Array[Dictionary] = [
	{"active":"Follow the stolen supplies through the woodland trail.", "resolved":"The Camp Crest is restored. A frozen trail opens north."},
	{"active":"Rekindle the Hollow and uncover the source of its unnatural frost.", "resolved":"The Hollow thaws. Dark meltwater runs toward Blightroot Marsh."},
	{"active":"Trace the corruption and brew a cure for the poisoned wetlands.", "resolved":"The antidote holds. Old Forge channels reveal where the blight began."},
	{"active":"Restore the ruined machinery before the Emberforge tears itself apart.", "resolved":"The Forge is silent. An ancient passage opens beneath the ruins."},
	{"active":"Free the trapped spirits and break the Abyss King's ritual.", "resolved":"The Abyss is quiet. The path home is open."},
]

const STAGES: Dictionary = {
	"ch1_1":{
		"intro":{"id":"c1s1_intro", "speaker":"Scout", "text":"The thieves fled through this trail.\nStay close. I'll lead the way.", "priority":2},
		"mid":{
			"c1s1_first_interception":{"speaker":"Scout", "text":"They're trying to cut us off!", "priority":3},
			"c1s1_route_choice":{"speaker":"Scout", "text":"Two paths ahead. Your call.", "priority":2},
			"c1s1_barricade":{"speaker":"Scout", "text":"That barricade wasn't here before.", "priority":3},
			"c1s1_extraction":{"speaker":"Scout", "text":"Almost there. Hold them back!", "priority":4},
		},
		"outro":{"id":"c1s1_outro", "speaker":"Scout", "text":"The trail is open. The thieves went toward the mushroom grove."},
	},
	"ch1_2":{
		"intro":{"id":"c1s2_intro", "speaker":"Scout", "text":"The crossing is overrun.\nThe Shrine may be able to cleanse it.", "priority":2},
		"mid":{
			"c1s2_energy_low":{"speaker":"Scout", "text":"The Shrine needs more spores!", "priority":4},
			"c1s2_shrine_powered":{"speaker":"Scout", "text":"The Shrine is ready. Hold the crossing!", "priority":3},
			"c1s2_final_cleansing":{"speaker":"Scout", "text":"Now! Release the cleansing pulse!", "priority":4},
		},
		"outro":{"id":"c1s2_outro", "speaker":"Scout", "text":"The path is clear... but our supplies are gone."},
	},
	"ch1_3":{
		"intro":{"id":"c1s3_intro", "speaker":"Scout", "text":"Found them.\nThree nests. Three different problems.", "priority":2},
		"mid":{
			"c1s3_first_nest":{"speaker":"Scout", "text":"They're carrying our supplies away!", "priority":3},
			"c1s3_burrowing_nest":{"speaker":"Scout", "text":"It moved underground!", "priority":2},
			"c1s3_feeding_sacs":{"speaker":"Scout", "text":"Those sacs are feeding the nest.", "priority":3},
			"c1s3_foreman":{"speaker":"Scout", "text":"That's the one giving orders!", "priority":3},
		},
		"outro":{"id":"c1s3_outro", "speaker":"Scout", "text":"We recovered enough supplies. One thief carried a Watchpath key."},
	},
	"ch1_4":{
		"intro":{"id":"c1s4_intro", "speaker":"Scout", "text":"The old gate needs three keys.\nThe carriers won't give them up easily.", "priority":2},
		"mid":{
			"c1s4_fleeing_carrier":{"speaker":"Scout", "text":"Don't let that one escape!", "priority":3},
			"c1s4_protected_carrier":{"speaker":"Scout", "text":"Guards on the key carrier!", "priority":3},
			"c1s4_captain":{"speaker":"Scout", "text":"The Captain has the last one.", "priority":3},
			"c1s4_gate_open":{"speaker":"Scout", "text":"That's it. Across the Watchpath!", "priority":4},
		},
		"outro":{"id":"c1s4_outro", "speaker":"Scout", "text":"The Crestkeeper is waiting beyond the gate."},
	},
	"ch1_5":{
		"intro":{"id":"c1s5_intro", "speaker":"Scout", "text":"That's our crest.\nAnd the machine guarding it.", "priority":3},
		"mid":{
			"c1s5_emitter_active":{"speaker":"Scout", "text":"The emitter controls the barrage!", "priority":3},
			"c1s5_final_emitter":{"speaker":"Scout", "text":"The shield is down!", "priority":4},
		},
		"outro":{"id":"c1s5_outro", "speaker":"Scout", "text":"We have our crest back. But these markings... they're frozen."},
	},
	"ch2_1":{
		"intro":{"id":"c2s1_intro", "speaker":"Narrator", "text":"The road ahead is frozen solid.\nFlamekeeper embers can restore the old Braziers.", "priority":2},
		"mid":{
			"c2s1_first_brazier":{"speaker":"Narrator", "text":"Warmth returns to the Hollow.", "priority":2},
			"c2s1_brazier_suppressed":{"speaker":"Narrator", "text":"The frost is smothering the flame!", "priority":4},
			"c2s1_stabilized":{"speaker":"Narrator", "text":"All four flames are connected.", "priority":3},
		},
		"outro":{"id":"c2s1_outro", "speaker":"Narrator", "text":"A weak signal comes from deeper inside the Hollow."},
	},
	"ch2_2":{
		"intro":{"id":"c2s2_intro", "speaker":"Narrator", "text":"Someone is trapped ahead.", "priority":2},
		"mid":{
			"c2s2_first_captive":{"speaker":"Captive", "text":"I thought no one would find us.", "priority":2},
			"c2s2_refreeze":{"speaker":"Narrator", "text":"The Jailer is freezing them again!", "priority":4},
			"c2s2_final_blizzard":{"speaker":"Narrator", "text":"The storm is worsening. Get everyone to warmth!", "priority":4},
		},
		"outro":{"id":"c2s2_outro", "speaker":"Captive", "text":"The frost wasn't natural. Something enormous is beneath the Hollow."},
	},
	"ch2_3":{
		"intro":{"id":"c2s3_intro", "speaker":"Narrator", "text":"These Runes once controlled the frozen paths.", "priority":2},
		"mid":{
			"c2s3_wrong_rune":{"speaker":"Narrator", "text":"The frost reacts violently.", "priority":2},
			"c2s3_path_shifted":{"speaker":"Narrator", "text":"The frozen path shifts.", "priority":3},
		},
		"outro":{"id":"c2s3_outro", "speaker":"Narrator", "text":"The Runes point toward an old treasury."},
	},
	"ch2_4":{
		"intro":{"id":"c2s4_intro", "speaker":"Narrator", "text":"The treasury is full of decoys.\nSomething here is watching us.", "priority":2},
		"mid":{
			"c2s4_first_clue":{"speaker":"Narrator", "text":"A clue. The Mimic left a trace.", "priority":2},
			"c2s4_wrong_chest":{"speaker":"Narrator", "text":"Trap!", "priority":3},
			"c2s4_mimic_revealed":{"speaker":"Narrator", "text":"There!", "priority":3},
		},
		"outro":{"id":"c2s4_outro", "speaker":"Narrator", "text":"A shard of Colossus armour lies among the frozen treasure."},
	},
	"ch2_5":{
		"intro":{"id":"c2s5_intro", "speaker":"Narrator", "text":"The Hollow has a guardian.\nThose crystals are feeding its armour.", "priority":3},
		"mid":{
			"c2s5_crystal_exposed":{"speaker":"Narrator", "text":"A crystal is exposed!", "priority":3},
			"c2s5_armour_broken":{"speaker":"Narrator", "text":"The armour is gone!", "priority":4},
		},
		"outro":{"id":"c2s5_outro", "speaker":"Narrator", "text":"The Hollow thaws. Dark corruption flows downstream."},
	},
	"ch3_1":{
		"intro":{"id":"c3s1_intro", "speaker":"Herbalist", "text":"The corruption has reached the water.\nPurify the pools before it spreads.", "priority":2},
		"mid":{
			"c3s1_first_pool":{"speaker":"Herbalist", "text":"One pool is clean. Keep moving.", "priority":2},
			"c3s1_reclaiming":{"speaker":"Herbalist", "text":"It's reclaiming the purified water!", "priority":4},
			"c3s1_final_surge":{"speaker":"Herbalist", "text":"Hold all three pools!", "priority":4},
		},
		"outro":{"id":"c3s1_outro", "speaker":"Herbalist", "text":"The water is clean, but the source remains."},
	},
	"ch3_2":{
		"intro":{"id":"c3s2_intro", "speaker":"Herbalist", "text":"This creature spreads the blight wherever it goes.", "priority":2},
		"mid":{
			"c3s2_fresh_tracks":{"speaker":"Herbalist", "text":"Fresh tracks.", "priority":1},
			"c3s2_lost_time":{"speaker":"Herbalist", "text":"We lost time. It knows we're following.", "priority":2},
			"c3s2_boss_reveal":{"speaker":"Herbalist", "text":"There it is.", "priority":3},
		},
		"outro":{"id":"c3s2_outro", "speaker":"Herbalist", "text":"Its venom may be useful."},
	},
	"ch3_3":{
		"intro":{"id":"c3s3_intro", "speaker":"Herbalist", "text":"We need three ingredients.\nSpider. Toad. Wasp.", "priority":2},
		"mid":{
			"c3s3_spider_complete":{"speaker":"Herbalist", "text":"Web venom secured.", "priority":1},
			"c3s3_toad_complete":{"speaker":"Herbalist", "text":"Toad bile secured.", "priority":1},
			"c3s3_wasp_complete":{"speaker":"Herbalist", "text":"Wasp venom secured.", "priority":1},
			"c3s3_all_ingredients":{"speaker":"Herbalist", "text":"That's everything. Get them out safely.", "priority":3},
		},
		"outro":{"id":"c3s3_outro", "speaker":"Herbalist", "text":"The ingredients are ready for the cure."},
	},
	"ch3_4":{
		"intro":{"id":"c3s4_intro", "speaker":"Herbalist", "text":"The antidote is unstable.\nOne bad hit could ruin it.", "priority":3},
		"mid":{
			"c3s4_route_selected":{"speaker":"Herbalist", "text":"Protect the vial. We only get one delivery.", "priority":3},
			"c3s4_vial_damaged":{"speaker":"Herbalist", "text":"Protect the vial!", "priority":4},
			"c3s4_final_transfer":{"speaker":"Herbalist", "text":"Hold it steady.", "priority":3},
		},
		"outro":{"id":"c3s4_outro", "speaker":"Herbalist", "text":"The cure works. But we'll need much more."},
	},
	"ch3_5":{
		"intro":{"id":"c3s5_intro", "speaker":"Herbalist", "text":"Heat. Purity. Timing.\nKeep all three under control.", "priority":3},
		"mid":{
			"c3s5_heat_critical":{"speaker":"Herbalist", "text":"Too hot! Vent it!", "priority":4},
			"c3s5_purity_falling":{"speaker":"Herbalist", "text":"The brew is being contaminated!", "priority":4},
			"c3s5_brew_complete":{"speaker":"Herbalist", "text":"The antidote is ready.", "priority":3},
			"c3s5_boss_appears":{"speaker":"Herbalist", "text":"The Tyrant found us.", "priority":3},
		},
		"outro":{"id":"c3s5_outro", "speaker":"Herbalist", "text":"The blight came through old Forge channels."},
	},
	"ch4_1":{
		"intro":{"id":"c4s1_intro", "speaker":"Forge Keeper", "text":"The old machinery still needs ore.\nMine only what we can carry.", "priority":2},
		"mid":{
			"c4s1_heat_high":{"speaker":"Forge Keeper", "text":"You're overheating! Find a vent.", "priority":4},
			"c4s1_ore_stolen":{"speaker":"Forge Keeper", "text":"Thief! That's our ore!", "priority":3},
			"c4s1_cart_loaded":{"speaker":"Forge Keeper", "text":"That's enough. Move the cart.", "priority":3},
			"c4s1_extraction":{"speaker":"Forge Keeper", "text":"Keep it moving!", "priority":4},
		},
		"outro":{"id":"c4s1_outro", "speaker":"Forge Keeper", "text":"Power is returning to the lower Forge."},
	},
	"ch4_2":{
		"intro":{"id":"c4s2_intro", "speaker":"Forge Keeper", "text":"These valves control the lava channels.\nOne wrong route could cook the chamber.", "priority":3},
		"mid":{
			"c4s2_flow_redirected":{"speaker":"Forge Keeper", "text":"Flow redirected.", "priority":2},
			"c4s2_jammer":{"speaker":"Forge Keeper", "text":"Something's blocking the mechanism.", "priority":3},
			"c4s2_stable":{"speaker":"Forge Keeper", "text":"Circuit stable.", "priority":3},
		},
		"outro":{"id":"c4s2_outro", "speaker":"Forge Keeper", "text":"The taming chamber is active."},
	},
	"ch4_3":{
		"intro":{"id":"c4s3_intro", "speaker":"Forge Keeper", "text":"Don't destroy them.\nThese Golems can still be recovered.", "priority":3},
		"mid":{
			"c4s3_golem_one":{"speaker":"Forge Keeper", "text":"Good. One Golem recovered.", "priority":2},
			"c4s3_golem_two":{"speaker":"Forge Keeper", "text":"Cool it first.", "priority":2},
			"c4s3_golem_three":{"speaker":"Forge Keeper", "text":"Separate the repair drones.", "priority":3},
			"c4s3_all_golems":{"speaker":"Forge Keeper", "text":"Four Golems recovered.", "priority":3},
		},
		"outro":{"id":"c4s3_outro", "speaker":"Forge Keeper", "text":"They can open the Relic chambers."},
	},
	"ch4_4":{
		"intro":{"id":"c4s4_intro", "speaker":"Forge Keeper", "text":"Three chambers. Three components.", "priority":2},
		"mid":{
			"c4s4_first_component":{"speaker":"Forge Keeper", "text":"First component secured.", "priority":2},
			"c4s4_relic_assembled":{"speaker":"Forge Keeper", "text":"The Relic is assembled.", "priority":3},
			"c4s4_guardian":{"speaker":"Forge Keeper", "text":"The Forge wants to test its new owner.", "priority":3},
		},
		"outro":{"id":"c4s4_outro", "speaker":"Forge Keeper", "text":"The Relic is ours. But the whole Forge is overheating."},
	},
	"ch4_5":{
		"intro":{"id":"c4s5_intro", "speaker":"Forge Keeper", "text":"Four regulators.\nShut them down before the Forge tears itself apart.", "priority":3},
		"mid":{
			"c4s5_behemoth":{"speaker":"Forge Keeper", "text":"The Behemoth is still powered!", "priority":3},
			"c4s5_regulator_disabled":{"speaker":"Forge Keeper", "text":"One system offline.", "priority":3},
			"c4s5_wrong_regulator":{"speaker":"Forge Keeper", "text":"Wrong sequence! Recover it!", "priority":4},
			"c4s5_final_regulator":{"speaker":"Forge Keeper", "text":"That's the last one! Now finish it!", "priority":4},
		},
		"outro":{"id":"c4s5_outro", "speaker":"Forge Keeper", "text":"Something beneath the Forge was feeding on all that power."},
	},
	"ch5_1":{
		"intro":{"id":"c5s1_intro", "speaker":"Spirit", "text":"They can see movement in the halls.\nMove carefully.", "priority":3},
		"mid":{
			"c5s1_searching":{"speaker":"Spirit", "text":"They're looking for you.", "priority":3},
			"c5s1_alert":{"speaker":"Spirit", "text":"Run!", "priority":4},
			"c5s1_silent_gate":{"speaker":"Spirit", "text":"The gate never knew you were here.", "priority":2},
			"c5s1_detected_gate":{"speaker":"Spirit", "text":"No more hiding. Move!", "priority":4},
		},
		"outro":{"id":"c5s1_outro", "speaker":"Spirit", "text":"Others are trapped below."},
	},
	"ch5_2":{
		"intro":{"id":"c5s2_intro", "speaker":"Spirit", "text":"Six souls remain chained to this place.", "priority":3},
		"mid":{
			"c5s2_first_rescue":{"speaker":"Freed Spirit", "text":"Thank you.", "priority":2},
			"c5s2_spirit_lost":{"speaker":"Narrator", "text":"The Abyss grows stronger.", "priority":3},
			"c5s2_final_seal":{"speaker":"Spirit", "text":"Together. Seal the portal.", "priority":4},
		},
		"outro":{"id":"c5s2_outro", "speaker":"Spirit", "text":"The mirrors ahead guard the inner Citadel."},
	},
	"ch5_3":{
		"intro":{"id":"c5s3_intro", "speaker":"Spirit", "text":"The mirrors show truth and lies.\nRemember what each room teaches you.", "priority":3},
		"mid":{
			"c5s3_wrong_mirror":{"speaker":"Narrator", "text":"The reflection fractures.", "priority":3},
			"c5s3_final_room":{"speaker":"Spirit", "text":"Everything you've learned matters here.", "priority":3},
			"c5s3_guardian":{"speaker":"Spirit", "text":"The Labyrinth has noticed you.", "priority":3},
		},
		"outro":{"id":"c5s3_outro", "speaker":"Spirit", "text":"Two Obelisks hold the path to the throne."},
	},
	"ch5_4":{
		"intro":{"id":"c5s4_intro", "speaker":"Spirit", "text":"The Obelisks must awaken together.\nPrepare the path before you begin.", "priority":3},
		"mid":{
			"c5s4_shortcut":{"speaker":"Spirit", "text":"That route will save time.", "priority":2},
			"c5s4_sync_started":{"speaker":"Spirit", "text":"Now. Reach the second Obelisk!", "priority":4},
			"c5s4_sync_failed":{"speaker":"Spirit", "text":"The first is fading. Try again.", "priority":3},
			"c5s4_sync_success":{"speaker":"Spirit", "text":"Hold them together!", "priority":4},
		},
		"outro":{"id":"c5s4_outro", "speaker":"Spirit", "text":"The throne is open."},
	},
	"ch5_5":{
		"intro":{"id":"c5s5_intro", "speaker":"Spirit", "text":"The King is bound to three Ritual Anchors.\nBreak the ritual.", "priority":4},
		"mid":{
			"c5s5_dominion_broken":{"speaker":"Narrator", "text":"The King's command weakens.", "priority":3},
			"c5s5_ruin_broken":{"speaker":"Narrator", "text":"The corruption recedes.", "priority":3},
			"c5s5_reflection_broken":{"speaker":"Narrator", "text":"The mirrored veil breaks.", "priority":3},
			"c5s5_final_anchor":{"speaker":"Spirit", "text":"The ritual is collapsing!", "priority":4},
			"c5s5_crown_phase":{"speaker":"Spirit", "text":"The Crown is the source.", "priority":3},
			"c5s5_crown_vulnerable":{"speaker":"Spirit", "text":"Now!", "priority":4},
			"c5s5_crown_shattered":{"speaker":"Narrator", "text":"The Abyss Crown breaks.", "priority":4},
			"c5s5_true_final":{"speaker":"Spirit", "text":"This is the King himself.", "priority":3},
			"c5s5_desperation":{"speaker":"Narrator", "text":"The Abyss King abandons restraint.", "priority":4},
		},
		"outro":{"id":"c5s5_outro", "speaker":"Spirit", "text":"It's over. The path home is open."},
	},
}

static func event(stage_id: String, event_id: String) -> Dictionary:
	var stage_data: Dictionary = STAGES.get(stage_id, {}) as Dictionary
	var intro: Dictionary = stage_data.get("intro", {}) as Dictionary
	if str(intro.get("id", "")) == event_id:
		return _normalized(intro, event_id)
	var mid: Dictionary = stage_data.get("mid", {}) as Dictionary
	if mid.has(event_id):
		return _normalized(mid[event_id] as Dictionary, event_id)
	return {}

static func intro(stage_id: String) -> Dictionary:
	var data: Dictionary = (STAGES.get(stage_id, {}) as Dictionary).get("intro", {}) as Dictionary
	return _normalized(data, str(data.get("id", "")))

static func outro(stage_id: String) -> Dictionary:
	return ((STAGES.get(stage_id, {}) as Dictionary).get("outro", {}) as Dictionary).duplicate(true)

static func result_text(stage_id: String) -> String:
	var data := outro(stage_id)
	if data.is_empty():
		return "The road ahead is open."
	return format_line(data)

static func format_line(data: Dictionary) -> String:
	var speaker := str(data.get("speaker", "Narrator"))
	var text_value := str(data.get("text", ""))
	return text_value if speaker == "Narrator" else "%s: %s" % [speaker, text_value]

static func chapter_map_text(chapter_number: int, complete: bool) -> String:
	var index := clampi(chapter_number - 1, 0, CHAPTER_MAP_TEXT.size() - 1)
	return str(CHAPTER_MAP_TEXT[index].get("resolved" if complete else "active", ""))

static func event_ids(stage_id: String) -> Array[String]:
	var ids: Array[String] = []
	var data: Dictionary = STAGES.get(stage_id, {}) as Dictionary
	var intro_data: Dictionary = data.get("intro", {}) as Dictionary
	if not str(intro_data.get("id", "")).is_empty():
		ids.append(str(intro_data.id))
	for event_id_variant in (data.get("mid", {}) as Dictionary):
		ids.append(str(event_id_variant))
	return ids

static func validate() -> Array[String]:
	var issues: Array[String] = []
	if STAGES.size() != StoryStore.stage_count():
		issues.append("Narrative data must cover all 25 Story stages.")
	var global_ids: Dictionary = {}
	for stage_index in StoryStore.stage_count():
		var stage_id := str(StoryStore.stage(stage_index).get("id", ""))
		var data: Dictionary = STAGES.get(stage_id, {}) as Dictionary
		if data.is_empty():
			issues.append("Missing narrative stage: %s" % stage_id)
			continue
		for section in ["intro", "outro"]:
			var line: Dictionary = data.get(section, {}) as Dictionary
			_validate_line(stage_id, str(line.get("id", "%s_%s" % [stage_id, section])), line, issues, global_ids)
		for event_id_variant in (data.get("mid", {}) as Dictionary):
			var event_id := str(event_id_variant)
			_validate_line(stage_id, event_id, (data.mid as Dictionary)[event_id] as Dictionary, issues, global_ids)
	return issues

static func _validate_line(stage_id: String, event_id: String, data: Dictionary, issues: Array[String], global_ids: Dictionary) -> void:
	if event_id.is_empty() or global_ids.has(event_id):
		issues.append("Duplicate or empty narrative event ID: %s" % event_id)
	global_ids[event_id] = stage_id
	var speaker := str(data.get("speaker", ""))
	if speaker not in SPEAKERS:
		issues.append("Invalid narrative speaker for %s: %s" % [event_id, speaker])
	var text_value := str(data.get("text", ""))
	if text_value.is_empty():
		issues.append("Empty narrative text: %s" % event_id)
	if text_value.length() > 130:
		issues.append("Narrative line exceeds mobile text limit: %s" % event_id)

static func _normalized(data: Dictionary, event_id: String) -> Dictionary:
	if data.is_empty() or event_id.is_empty():
		return {}
	var normalized := data.duplicate(true)
	normalized["id"] = event_id
	normalized["priority"] = clampi(int(normalized.get("priority", PRIORITY_FLAVOUR)), PRIORITY_FLAVOUR, PRIORITY_CRITICAL)
	normalized["duration"] = clampf(float(normalized.get("duration", 2.2 + float(str(normalized.get("text", "")).length()) * 0.018)), 2.4, 4.0)
	normalized["ttl"] = clampf(float(normalized.get("ttl", 4.0)), 1.0, 6.0)
	return normalized
