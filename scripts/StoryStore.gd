class_name StoryStore
extends RefCounted

const StoryMutatorsClass := preload("res://scripts/story/StoryMutators.gd")
const StoryRecordsClass := preload("res://scripts/story/StoryRecords.gd")
const SAVE_PREFIX := "user://capy_story_"
const MAX_GEAR_LEVEL := 10
const REPLAY_REWARD_MULTIPLIER: float = 0.30
const STORY_RUN_RECORD_VERSION: int = 1
const MAX_STORY_RUN_HISTORY: int = 20
const SLOTS := ["weapon", "armor", "pants", "offhand", "headwear", "boots"]

const STORY_DIFFICULTY_IDS := ["normal", "hard", "nightmare"]
const STORY_DIFFICULTIES := {
	"normal":{"name":"Normal", "rank":0, "enemy_hp":1.0, "enemy_damage":1.0, "enemy_speed":1.0, "summary":"Original campaign rules and pacing."},
	"hard":{"name":"Hard", "rank":1, "enemy_hp":1.14, "enemy_damage":1.11, "enemy_speed":1.03, "summary":"More frequent objective pressure and tighter recovery windows."},
	"nightmare":{"name":"Nightmare", "rank":2, "enemy_hp":1.28, "enemy_damage":1.24, "enemy_speed":1.07, "summary":"Relentless mixed-role pressure and demanding objective timing."},
}

# Stage-specific rules are deliberately mechanical. Stat multipliers above are
# conservative and secondary to these pressure, timing, and recovery changes.
const STAGE_DIFFICULTY_RULES := {
	"ch1_1":{"hard":{"summary":"Escort interceptors arrive sooner and extraction draws an extra pursuer.","reinforcement_interval":17.0,"reinforcement_count":1,"spawn_interval_mul":0.90,"pressure_bonus":1},"nightmare":{"summary":"Mixed-role interceptors relentlessly contest the route and extraction.","reinforcement_interval":12.0,"reinforcement_count":2,"spawn_interval_mul":0.78,"pressure_bonus":2}},
	"ch1_2":{"hard":{"summary":"Shrine energy fades faster while cleansing rushers regroup sooner.","reinforcement_interval":18.0,"reinforcement_count":1,"energy_drain_mul":1.25,"spawn_interval_mul":0.88},"nightmare":{"summary":"Rapid mixed rushers force constant spore collection and shrine defence.","reinforcement_interval":12.5,"reinforcement_count":2,"energy_drain_mul":1.50,"spawn_interval_mul":0.76}},
	"ch1_3":{"hard":{"summary":"Nest defenders reinforce sooner and shield sacs attract guards.","reinforcement_interval":18.0,"reinforcement_count":1,"spawn_interval_mul":0.86,"pressure_bonus":1},"nightmare":{"summary":"Every nest relocation is contested by a heavier defender response.","reinforcement_interval":12.0,"reinforcement_count":2,"spawn_interval_mul":0.72,"pressure_bonus":2}},
	"ch1_4":{"hard":{"summary":"Carrier hunts gain guards and the Watchpath gate stays open for less time.","reinforcement_interval":17.0,"reinforcement_count":1,"spawn_interval_mul":0.86,"gate_window":20.0,"pressure_bonus":1},"nightmare":{"summary":"Guarded carriers and a short gate window demand decisive routing.","reinforcement_interval":11.5,"reinforcement_count":2,"spawn_interval_mul":0.72,"gate_window":18.0,"pressure_bonus":2}},
	"ch1_5":{"hard":{"summary":"Barrage cycles fire faster while preserving every readable safe lane.","reinforcement_interval":20.0,"reinforcement_count":1,"shot_interval_mul":0.90,"hazard_speed_mul":1.08},"nightmare":{"summary":"Faster layered barrages add aimed pressure without closing safe lanes.","reinforcement_interval":14.0,"reinforcement_count":2,"shot_interval_mul":0.78,"hazard_speed_mul":1.16}},
	"ch2_1":{"hard":{"summary":"Braziers cool faster and suppressors return sooner during stabilization.","reinforcement_interval":18.0,"reinforcement_count":1,"brazier_decay_mul":1.22,"spawn_interval_mul":0.86},"nightmare":{"summary":"Rapid cooling and frequent suppression strain the four-brazier network.","reinforcement_interval":12.0,"reinforcement_count":2,"brazier_decay_mul":1.45,"spawn_interval_mul":0.72}},
	"ch2_2":{"hard":{"summary":"Captives refreeze faster while jailers contest the moving rescue line.","reinforcement_interval":17.0,"reinforcement_count":1,"refreeze_mul":1.25,"cold_rate_mul":1.12},"nightmare":{"summary":"Multiple threatened captives and harsh cold demand active prioritization.","reinforcement_interval":11.5,"reinforcement_count":2,"refreeze_mul":1.50,"cold_rate_mul":1.25}},
	"ch2_3":{"hard":{"summary":"The rune reveal is shorter and mistakes deepen Cold Exposure.","reinforcement_interval":18.0,"reinforcement_count":1,"reveal_time":4.25,"wrong_penalty_mul":1.25,"cold_rate_mul":1.12},"nightmare":{"summary":"Brief recall windows and severe mistakes pressure a still-solvable sequence.","reinforcement_interval":12.0,"reinforcement_count":2,"reveal_time":3.5,"wrong_penalty_mul":1.50,"cold_rate_mul":1.25}},
	"ch2_4":{"hard":{"summary":"Wrong chest reads summon a stronger recovery ambush.","reinforcement_interval":19.0,"reinforcement_count":1,"wrong_pressure_bonus":2},"nightmare":{"summary":"False chest choices trigger layered frost pressure; clue logic stays deterministic.","reinforcement_interval":12.5,"reinforcement_count":2,"wrong_pressure_bonus":4}},
	"ch2_5":{"hard":{"summary":"Armour exposure cycles arrive faster with supporting frost pressure.","reinforcement_interval":17.0,"reinforcement_count":1,"boss_cycle_mul":0.88},"nightmare":{"summary":"Short, aggressive exposure cycles punish missed crystal opportunities.","reinforcement_interval":11.0,"reinforcement_count":2,"boss_cycle_mul":0.74}},
	"ch3_1":{"hard":{"summary":"Purified pools lose stability faster and reclaimers return sooner.","reinforcement_interval":17.0,"reinforcement_count":1,"stability_drain_mul":1.22,"spawn_interval_mul":0.86},"nightmare":{"summary":"Fast stability loss creates overlapping pool-recovery decisions.","reinforcement_interval":11.5,"reinforcement_count":2,"stability_drain_mul":1.45,"spawn_interval_mul":0.72}},
	"ch3_2":{"hard":{"summary":"Stale trails trigger larger ambushes while hunters contest tracking.","reinforcement_interval":18.0,"reinforcement_count":1,"wrong_pressure_bonus":2},"nightmare":{"summary":"Punishing stale trails and relentless hunters reward prepared trap routing.","reinforcement_interval":12.0,"reinforcement_count":2,"wrong_pressure_bonus":4}},
	"ch3_3":{"hard":{"summary":"Contaminators return sooner while lure channels face support packs.","reinforcement_interval":17.0,"reinforcement_count":1,"spawn_interval_mul":0.86,"channel_time_mul":1.08},"nightmare":{"summary":"Overlapping contamination and longer lure channels test ecosystem control.","reinforcement_interval":11.0,"reinforcement_count":2,"spawn_interval_mul":0.70,"channel_time_mul":1.16}},
	"ch3_4":{"hard":{"summary":"Checkpoint ambushes grow and vial damage is less forgiving.","reinforcement_interval":18.0,"reinforcement_count":1,"vial_damage_mul":1.22,"pressure_bonus":1},"nightmare":{"summary":"Heavy route ambushes threaten the cure without removing recovery altars.","reinforcement_interval":12.0,"reinforcement_count":2,"vial_damage_mul":1.45,"pressure_bonus":2}},
	"ch3_5":{"hard":{"summary":"Brewing heat rises faster and wrong ingredients cost more purity.","reinforcement_interval":18.0,"reinforcement_count":1,"heat_gain_mul":1.20,"wrong_penalty_mul":1.22},"nightmare":{"summary":"Aggressive heat and purity drift demand exact recipe management.","reinforcement_interval":12.0,"reinforcement_count":2,"heat_gain_mul":1.42,"wrong_penalty_mul":1.45}},
	"ch4_1":{"hard":{"summary":"Ore thieves return sooner while mining builds heat more quickly.","reinforcement_interval":17.0,"reinforcement_count":1,"heat_gain_mul":1.20,"spawn_interval_mul":0.84},"nightmare":{"summary":"Frequent thieves and rapid forge heat pressure every ore delivery.","reinforcement_interval":11.0,"reinforcement_count":2,"heat_gain_mul":1.42,"spawn_interval_mul":0.68}},
	"ch4_2":{"hard":{"summary":"Forge Jammers recur sooner and wrong valve states add more heat.","reinforcement_interval":18.0,"reinforcement_count":1,"spawn_interval_mul":0.84,"wrong_penalty_mul":1.25},"nightmare":{"summary":"Layered Jammers contest a deterministic, fully solvable molten circuit.","reinforcement_interval":11.5,"reinforcement_count":2,"spawn_interval_mul":0.68,"wrong_penalty_mul":1.50}},
	"ch4_3":{"hard":{"summary":"Capture channels take longer while tether pressure arrives sooner.","reinforcement_interval":18.0,"reinforcement_count":1,"channel_time_mul":1.12,"spawn_interval_mul":0.86},"nightmare":{"summary":"Extended nonlethal captures must be protected from mixed-role interference.","reinforcement_interval":12.0,"reinforcement_count":2,"channel_time_mul":1.24,"spawn_interval_mul":0.72}},
	"ch4_4":{"hard":{"summary":"Forge chambers reinforce sooner between component recoveries.","reinforcement_interval":17.0,"reinforcement_count":1,"spawn_interval_mul":0.84,"pressure_bonus":1},"nightmare":{"summary":"Rapid chamber hazards force clean component and Guardian transitions.","reinforcement_interval":11.0,"reinforcement_count":2,"spawn_interval_mul":0.68,"pressure_bonus":2}},
	"ch4_5":{"hard":{"summary":"Meltdown heat climbs faster and mistakes intensify regulator pressure.","reinforcement_interval":17.0,"reinforcement_count":1,"heat_gain_mul":1.20,"wrong_penalty_mul":1.25},"nightmare":{"summary":"Mixed-role pressure stresses the valid four-regulator shutdown sequence.","reinforcement_interval":10.5,"reinforcement_count":2,"heat_gain_mul":1.42,"wrong_penalty_mul":1.50}},
	"ch5_1":{"hard":{"summary":"Sentries build Alert faster and quiet-gate progress is more exposed.","reinforcement_interval":18.0,"reinforcement_count":1,"alert_gain_mul":1.20,"gate_time_mul":1.10},"nightmare":{"summary":"Tight stealth recovery and roaming pressure demand disciplined safe-point use.","reinforcement_interval":12.0,"reinforcement_count":2,"alert_gain_mul":1.42,"gate_time_mul":1.22}},
	"ch5_2":{"hard":{"summary":"Soul Binders pursue released spirits more often during portal sealing.","reinforcement_interval":17.0,"reinforcement_count":1,"spirit_pressure_mul":1.18,"seal_time_mul":1.10},"nightmare":{"summary":"Multiple threatened spirits and frequent Binders strain rescue priorities.","reinforcement_interval":11.0,"reinforcement_count":2,"spirit_pressure_mul":1.35,"seal_time_mul":1.22}},
	"ch5_3":{"hard":{"summary":"Wrong mirrors deepen abyss pressure and summon larger reflection ambushes.","reinforcement_interval":18.0,"reinforcement_count":1,"wrong_penalty_mul":1.25,"wrong_pressure_bonus":2},"nightmare":{"summary":"Severe wrong-room recovery preserves deterministic, solvable mirror clues.","reinforcement_interval":12.0,"reinforcement_count":2,"wrong_penalty_mul":1.50,"wrong_pressure_bonus":4}},
	"ch5_4":{"hard":{"summary":"Synchronization and disruption recovery windows are tighter.","reinforcement_interval":17.0,"reinforcement_count":1,"sync_window":12.5,"spawn_interval_mul":0.84},"nightmare":{"summary":"Frequent twin-obelisk disruptions demand exact prepared-route execution.","reinforcement_interval":10.5,"reinforcement_count":2,"sync_window":11.0,"spawn_interval_mul":0.66}},
	"ch5_5":{"hard":{"summary":"Each active ritual Anchor projects a faster signature threat.","reinforcement_interval":16.0,"reinforcement_count":1,"ritual_interval":7.0,"crown_window_mul":0.90},"nightmare":{"summary":"Overlapping Anchor threats and short Crown windows test final-phase mastery.","reinforcement_interval":10.0,"reinforcement_count":2,"ritual_interval":4.8,"crown_window_mul":0.78}},
}

const CHAPTERS := [
	{"name":"THE STOLEN CAMP CREST", "theme":"mushroom woodland", "reward":["twig_blade", "scout_cap"], "stages":["The Broken Trail", "Mushroom Crossing", "Supply Thieves", "The Old Watchpath", "Crestkeeper's Gate"]},
	{"name":"FROSTBOUND HOLLOW", "theme":"frozen hollow", "reward":["moss_vest", "trail_boots"], "stages":["Rekindle the Way", "Frozen Captives", "Runes of Thaw", "The Mimic Treasury", "Frostbound Colossus"]},
	{"name":"BLIGHTROOT MARSH", "theme":"blighted marsh", "reward":["pan_lid", "forager_pants"], "stages":["Cleanse the Mire", "Hunt the Plaguebeast", "Venom Harvest", "The Fragile Cure", "Brew the Grand Antidote"]},
	{"name":"EMBERFORGE RUINS", "theme":"emberforge ruins", "reward":["thorn_spear", "bark_mail"], "stages":["Ore Rush", "Molten Circuit", "Golem Taming", "Forge the Lost Relic", "Stop the Meltdown"]},
	{"name":"ABYSSAL CITADEL", "theme":"abyssal citadel", "reward":["warden_helm", "root_guard"], "stages":["Silent Descent", "Soul Liberation", "Mirror Labyrinth", "Twin Eclipse", "Throne of the Deep"]},
]

# Chapter Mastery rewards stay intentionally modest and use Story upgrade
# materials so the grant and one-time claim ID can be saved together.
const CHAPTER_MASTERY_REWARDS := [
	{"id":"ch1_mastery_5", "chapter":1, "threshold":5, "materials":1, "name":"Trailblazer Cache"},
	{"id":"ch1_mastery_10", "chapter":1, "threshold":10, "materials":2, "name":"Crestkeeper Cache"},
	{"id":"ch1_mastery_15", "chapter":1, "threshold":15, "materials":4, "name":"Chapter Master Cache", "emblem":true},
	{"id":"ch2_mastery_5", "chapter":2, "threshold":5, "materials":1, "name":"Wayfinder Cache"},
	{"id":"ch2_mastery_10", "chapter":2, "threshold":10, "materials":2, "name":"Frostwarden Cache"},
	{"id":"ch2_mastery_15", "chapter":2, "threshold":15, "materials":4, "name":"Chapter Master Cache", "emblem":true},
	{"id":"ch3_mastery_5", "chapter":3, "threshold":5, "materials":1, "name":"Mirekeeper Cache"},
	{"id":"ch3_mastery_10", "chapter":3, "threshold":10, "materials":2, "name":"Blightbreaker Cache"},
	{"id":"ch3_mastery_15", "chapter":3, "threshold":15, "materials":4, "name":"Chapter Master Cache", "emblem":true},
	{"id":"ch4_mastery_5", "chapter":4, "threshold":5, "materials":1, "name":"Forgehand Cache"},
	{"id":"ch4_mastery_10", "chapter":4, "threshold":10, "materials":2, "name":"Emberwarden Cache"},
	{"id":"ch4_mastery_15", "chapter":4, "threshold":15, "materials":4, "name":"Chapter Master Cache", "emblem":true},
	{"id":"ch5_mastery_5", "chapter":5, "threshold":5, "materials":1, "name":"Abysswalker Cache"},
	{"id":"ch5_mastery_10", "chapter":5, "threshold":10, "materials":2, "name":"Citadel Warden Cache"},
	{"id":"ch5_mastery_15", "chapter":5, "threshold":15, "materials":4, "name":"Chapter Master Cache", "emblem":true},
]

const STAGE_OBJECTIVES := [
	[
		{"id":"escort", "desc":"Command the Scout, open the barricade, and secure extraction", "target_seconds":210.0},
		{"id":"defend", "desc":"Gather energy spores and power the Mushroom Shrine", "target_seconds":210.0},
		{"id":"nests", "desc":"Destroy three different Supply Thief Nests", "count":3},
		{"id":"keys", "desc":"Track three key carriers and cross the Watchpath Gate", "count":3},
		{"id":"hazards", "desc":"Master the Crestkeeper barrage and defeat the Crestkeeper", "target_seconds":270.0},
	],
	[
		{"id":"frozen_braziers", "desc":"Carry flame charges and stabilize four connected warmth zones", "count":4},
		{"id":"ice_captives", "desc":"Release, protect and extract five frozen captives", "count":5},
		{"id":"thaw_runes", "desc":"Memorize four runes and finish the sequence under spreading frost", "count":4, "simultaneous_objectives":true},
		{"id":"frost_mimic", "desc":"Investigate clues, identify the real chest and defeat the Frost Mimic", "count":6, "simultaneous_objectives":true},
		{"id":"frost_colossus", "desc":"Expose three integrated armour crystals and defeat the Frostbound Colossus", "count":3, "simultaneous_objectives":true},
	],
	[
		{"id":"cleanse_mire", "desc":"Carry cleansing energy through three different purification mechanics", "count":3, "energy":6, "target_seconds":270.0},
		{"id":"plaguebeast", "desc":"Read tracking clues, prepare traps, and hunt the Plaguebeast", "count":3, "target_seconds":300.0},
		{"id":"venom_harvest", "desc":"Choose three ecosystems and extract guaranteed venom ingredients", "count":3, "target_seconds":270.0},
		{"id":"fragile_cure", "desc":"Choose a route and deliver a fragile antidote vial", "count":3, "target_seconds":300.0},
		{"id":"grand_antidote", "desc":"Manage recipe, heat, purity, and defeat the Blight Vine Tyrant", "count":3, "target_seconds":360.0},
	],
	[
		{"id":"ore_rush", "desc":"Mine, carry and deliver Ember Ore, then escort the loaded mining cart", "count":12, "target_seconds":300.0},
		{"id":"molten_circuit", "desc":"Route lava, traverse the powered circuit and defend its stabilization", "count":3, "target_seconds":300.0, "simultaneous_objectives":true},
		{"id":"golem_taming", "desc":"Learn and complete four different nonlethal rogue golem captures", "count":4, "target_seconds":330.0},
		{"id":"lost_relic", "desc":"Clear three forge chambers, assemble a relic and defeat its guardian", "count":3, "target_seconds":330.0},
		{"id":"meltdown", "desc":"Complete the shutdown sequence while fighting the Thunderforge Behemoth", "count":4, "target_seconds":390.0, "simultaneous_objectives":true, "final_boss":"thunderforge_behemoth"},
	],
	[
		{"id":"silent_descent", "desc":"Cross three stealth safe points and reach the inner citadel without filling the alert meter", "count":3},
		{"id":"soul_liberation", "desc":"Rescue six moving spirits and seal the Abyss Portal", "count":6},
		{"id":"mirror_labyrinth", "desc":"Solve four clue-driven mirror rooms and defeat the Mirror Guardian", "count":4},
		{"id":"twin_eclipse", "desc":"Prepare both obelisks, synchronize them, and defeat the Eclipse Elite", "simultaneous_objectives":true},
		{"id":"abyss_king", "desc":"Interrupt the ritual, break the crown, and defeat the Abyss King", "simultaneous_objectives":true},
	],
]

const MASTERY_OBJECTIVES := {
	"ch1_1":[{"id":"c1s1_scout_safe","title":"Safe Passage","description":"Never let the Scout fall below 40% health."},{"id":"c1s1_route_together","title":"No One Left Behind","description":"Complete the route without an escort recovery."},{"id":"c1s1_clean_extraction","title":"Clean Extraction","description":"Let the Scout take no damage during final extraction."}],
	"ch1_2":[{"id":"c1s2_shrine_guardian","title":"Guardian of the Shrine","description":"Finish with at least 60% Shrine health."},{"id":"c1s2_energy_keeper","title":"Energy Keeper","description":"Never empty Shrine energy during defence."},{"id":"c1s2_perfect_cleanse","title":"Perfect Cleansing","description":"Keep the Shrine at or above 40% during cleansing."}],
	"ch1_3":[{"id":"c1s3_supplies_secured","title":"Supplies Secured","description":"Never let 12 Nest defenders accumulate."},{"id":"c1s3_nest_specialist","title":"Nest Specialist","description":"Clear each Nest's defenders before destroying it."},{"id":"c1s3_foreman_stopped","title":"Stop the Foreman","description":"Stay above 25% health during the Foreman fight."}],
	"ch1_4":[{"id":"c1s4_keymaster","title":"Keymaster","description":"Complete every carrier-track channel without interruption."},{"id":"c1s4_swift_recovery","title":"Swift Recovery","description":"Collect every dropped key within 10 seconds."},{"id":"c1s4_unbroken_crossing","title":"Unbroken Crossing","description":"Cross the gate on the first window."}],
	"ch1_5":[{"id":"c1s5_emitter_breaker","title":"Emitter Breaker","description":"Avoid hits during the radial and aimed emitter barrages."},{"id":"c1s5_safe_lane_master","title":"Safe-Lane Master","description":"Avoid the primary rotating barrage."},{"id":"c1s5_unbroken_finale","title":"Unbroken Finale","description":"Stay above 25% health during the Crestkeeper fight."}],
	"ch2_1":[{"id":"c2s1_eternal_flame","title":"Eternal Flame","description":"Never let a lit Brazier go cold."},{"id":"c2s1_warmth_keeper","title":"Warmth Keeper","description":"Never reach maximum Cold Exposure."},{"id":"c2s1_four_flames","title":"Four Flames","description":"Stabilize the first all-four network attempt."}],
	"ch2_2":[{"id":"c2s2_healthy_rescue","title":"Healthy Rescue","description":"Keep every captive below 75% refreeze progress."},{"id":"c2s2_no_refreezing","title":"No Refreezing","description":"Never allow a captive to become refrozen."},{"id":"c2s2_blizzard_guardian","title":"Blizzard Guardian","description":"Finish the blizzard without a captive being refrozen."}],
	"ch2_3":[{"id":"c2s3_perfect_recall","title":"Perfect Recall","description":"Enter the rune sequence without a wrong rune."},{"id":"c2s3_cold_control","title":"Cold Control","description":"Keep Cold Exposure below 75%."},{"id":"c2s3_unfrozen","title":"Unfrozen","description":"Never reach maximum Cold Exposure."}],
	"ch2_4":[{"id":"c2s4_master_detective","title":"Master Detective","description":"Expose the Mimic without opening a safe chest."},{"id":"c2s4_thorough_investigation","title":"Thorough Investigation","description":"Inspect all five clue tablets."},{"id":"c2s4_trap_sense","title":"Trap Sense","description":"Trigger no frost chest trap."}],
	"ch2_5":[{"id":"c2s5_clean_exposures","title":"Crystal Breaker","description":"Break all crystals without missing an exposure cycle."},{"id":"c2s5_no_regeneration","title":"Systematic Dismantling","description":"Interrupt the armour regeneration crystal cleanly."},{"id":"c2s5_final_armour_lock","title":"Colossus Mastery","description":"Finish without restarting an armour phase."}],
	"ch3_1":[{"id":"c3s1_pure_waters","title":"Pure Waters","description":"Allow no purified pool to reach 0% stability."},{"id":"c3s1_master_purifier","title":"Master Purifier","description":"Keep every pool at 60% stability through the surge."},{"id":"c3s1_hold_the_mire","title":"Hold the Mire","description":"Never let a pool fall below 35% during the surge."}],
	"ch3_2":[{"id":"c3s2_expert_tracker","title":"Expert Tracker","description":"Choose no stale tracking trail."},{"id":"c3s2_prepared_hunter","title":"Prepared Hunter","description":"Choose each correct trail within 12 seconds."},{"id":"c3s2_forced_retreat","title":"Decisive Sighting","description":"Force the first retreat before its escape timeout."}],
	"ch3_3":[{"id":"c3s3_clean_harvest","title":"Clean Harvest","description":"Cleanse each contamination within 5 seconds."},{"id":"c3s3_ecosystem_expert","title":"Ecosystem Expert","description":"Complete all three unique lure channels without interruption."},{"id":"c3s3_perfect_extraction","title":"Perfect Extraction","description":"Extract with no Contaminator enemies active."}],
	"ch3_4":[{"id":"c3s4_untouched_cure","title":"Untouched Cure","description":"Deliver the vial at 100% integrity."},{"id":"c3s4_no_replacement","title":"No Replacement Needed","description":"Complete delivery without shattering the vial."},{"id":"c3s4_risk_taker","title":"Risk Taker","description":"Complete the short hazardous route."}],
	"ch3_5":[{"id":"c3s5_pure_brew","title":"Pure Brew","description":"Finish brewing at 80% Purity or higher."},{"id":"c3s5_master_brewer","title":"Master Brewer","description":"Never reach critical brewing Heat."},{"id":"c3s5_perfect_recipe","title":"Perfect Recipe","description":"Use the correct order and finish at 80% Purity."}],
	"ch4_1":[{"id":"c4s1_leave_nothing","title":"Leave Nothing Behind","description":"Never allow mined ore to be stolen."},{"id":"c4s1_cool_head","title":"Cool Head","description":"Never reach critical forge Heat."},{"id":"c4s1_secure_shipment","title":"Secure Shipment","description":"Clear each cart obstruction within 6 seconds."}],
	"ch4_2":[{"id":"c4s2_perfect_circuit","title":"Perfect Circuit","description":"Reach the powered circuit without a wrong toggle."},{"id":"c4s2_forge_engineer","title":"Forge Engineer","description":"Solve without returning to a previous valve state."},{"id":"c4s2_unjammed","title":"Unjammed","description":"Clear each Forge Jammer within 5 seconds."}],
	"ch4_3":[{"id":"c4s3_gentle_hand","title":"Gentle Hand","description":"Never force a Golem to its protected health floor."},{"id":"c4s3_master_tamer","title":"Master Tamer","description":"Never lose capture-ready state before a capture."},{"id":"c4s3_clean_channels","title":"Clean Channels","description":"Do not interrupt a started capture channel."}],
	"ch4_4":[{"id":"c4s4_chamber_master","title":"Chamber Master","description":"Clear each chamber before a third hazard reinforcement."},{"id":"c4s4_master_smith","title":"Master Smith","description":"Clear chamber hazards before collecting each component."},{"id":"c4s4_relic_mastery","title":"Relic Mastery","description":"Defeat the Guardian with no chamber hazards active."}],
	"ch4_5":[{"id":"c4s5_correct_shutdown","title":"Correct Shutdown","description":"Activate all regulators in the correct order."},{"id":"c4s5_systems_engineer","title":"Systems Engineer","description":"Disable all systems before the boss reaches its protected floor."},{"id":"c4s5_controlled_meltdown","title":"Controlled Meltdown","description":"Never reach critical meltdown Heat."}],
	"ch5_1":[{"id":"c5s1_ghost","title":"Ghost","description":"Never enter Alerted state."},{"id":"c5s1_unsearched","title":"Unsearched","description":"Never cause a sentry to enter Searching."},{"id":"c5s1_silent_exit","title":"Silent Exit","description":"Complete the quiet-gate unlock without interrupting its channel."}],
	"ch5_2":[{"id":"c5s2_all_souls_safe","title":"All Souls Safe","description":"Let no released spirit become lost."},{"id":"c5s2_unbound","title":"Unbound","description":"Let no released spirit become captured."},{"id":"c5s2_perfect_seal","title":"Perfect Seal","description":"Stabilize all three seals before defeating the Keeper."}],
	"ch5_3":[{"id":"c5s3_true_reflection","title":"True Reflection","description":"Choose no wrong mirror."},{"id":"c5s3_false_clue_scholar","title":"Scholar of Mirrors","description":"Interpret the false-clue room correctly."},{"id":"c5s3_unbroken_mind","title":"Unbroken Mind","description":"Reach the Guardian with zero puzzle penalty."}],
	"ch5_4":[{"id":"c5s4_first_alignment","title":"First Alignment","description":"Synchronize on the first attempt."},{"id":"c5s4_prepared_path","title":"Prepared Path","description":"Complete every route preparation action first."},{"id":"c5s4_perfect_eclipse","title":"Perfect Eclipse","description":"Clear every Obelisk disruption within 5 seconds."}],
	"ch5_5":[{"id":"c5s5_break_ritual","title":"Break the Ritual","description":"Break each Anchor only while its vulnerability is active."},{"id":"c5s5_shatter_crown","title":"Shatter the Crown","description":"Open every Crown window with the twin seals; use no recovery channeler."},{"id":"c5s5_king_slayer","title":"King Slayer","description":"Stay above 25% health through final and desperation phases."}],
}

const GEAR := {
	"twig_blade":{"name":"Trailblazer Twig", "slot":"weapon", "effects":{"skill_dmg":0.06, "crit_chance":0.02}},
	"scout_cap":{"name":"Scout's Leaf Cap", "slot":"headwear", "effects":{"xp_bonus":0.08, "max_hp_pct":0.03}},
	"moss_vest":{"name":"Moss-Stitched Vest", "slot":"armor", "effects":{"max_hp_pct":0.08, "damage_taken_mul":-0.03}},
	"trail_boots":{"name":"Quickstep Sandals", "slot":"boots", "effects":{"move_speed_mul":0.06, "xp_bonus":0.03}},
	"pan_lid":{"name":"Chef's Pan Lid", "slot":"offhand", "effects":{"max_hp_pct":0.05, "damage_taken_mul":-0.04}},
	"forager_pants":{"name":"Forager Trousers", "slot":"pants", "effects":{"xp_bonus":0.07, "move_speed_mul":0.03}},
	"thorn_spear":{"name":"Thornwatch Spear", "slot":"weapon", "effects":{"skill_dmg":0.11, "boss_dmg":0.05}},
	"bark_mail":{"name":"Ironbark Mail", "slot":"armor", "effects":{"max_hp_pct":0.14, "damage_taken_mul":-0.06}},
	"warden_helm":{"name":"Hollow Warden Helm", "slot":"headwear", "effects":{"crit_chance":0.07, "skill_dmg":0.04}},
	"root_guard":{"name":"Rootbound Guard", "slot":"offhand", "effects":{"boss_dmg":0.12, "damage_taken_mul":-0.05}},
	"warden_greaves":{"name":"Warden Greaves", "slot":"pants", "effects":{"skill_dmg":0.07, "max_hp_pct":0.06}},
	"hollow_treads":{"name":"Hollow Treads", "slot":"boots", "effects":{"move_speed_mul":0.10, "damage_taken_mul":-0.03}},
}

static func _path(username: String) -> String:
	return SAVE_PREFIX + username.sha256_text().left(20) + ".json"

static func make_story_run_id() -> String:
	return "%d-%d-%08x" % [Time.get_unix_time_from_system() * 1000.0, Time.get_ticks_usec(), randi()]

static func story_run_history(profile: Dictionary) -> Array[Dictionary]:
	return _sanitize_run_history(profile.get("story_run_history", []))

static func personal_record(profile: Dictionary, stage_id: String) -> Dictionary:
	return StoryRecordsClass.stage_record(profile.get("story_records", {}), stage_id)

static func personal_record_run(profile: Dictionary, run_id: String) -> Dictionary:
	if run_id.is_empty():
		return {}
	for record in story_run_history(profile):
		if str(record.get("run_id", "")) == run_id:
			return record.duplicate(true)
	return {}

static func merge_story_run_history(local_history: Variant, remote_history: Variant) -> Array[Dictionary]:
	var by_id: Dictionary = {}
	for source in [local_history, remote_history]:
		if typeof(source) != TYPE_ARRAY:
			continue
		for record_variant in source as Array:
			var record := _sanitize_run_record(record_variant)
			if record.is_empty():
				continue
			var run_id := str(record.get("run_id", ""))
			var existing: Dictionary = by_id.get(run_id, {}) as Dictionary
			if existing.is_empty() or int(record.get("timestamp", 0)) >= int(existing.get("timestamp", 0)):
				by_id[run_id] = record
	var merged: Array[Dictionary] = []
	for record_variant in by_id.values():
		merged.append((record_variant as Dictionary).duplicate(true))
	merged.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var timestamp_a := int(a.get("timestamp", 0))
		var timestamp_b := int(b.get("timestamp", 0))
		return str(a.get("run_id", "")) > str(b.get("run_id", "")) if timestamp_a == timestamp_b else timestamp_a > timestamp_b
	)
	if merged.size() > MAX_STORY_RUN_HISTORY:
		merged.resize(MAX_STORY_RUN_HISTORY)
	return merged

static func _sanitize_run_history(value: Variant) -> Array[Dictionary]:
	return merge_story_run_history(value, [])

static func _sanitize_string_array(value: Variant, maximum: int = 32) -> Array[String]:
	var output: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return output
	for item in value as Array:
		if typeof(item) != TYPE_STRING:
			continue
		var text := str(item).left(96)
		if not text.is_empty() and text not in output:
			output.append(text)
			if output.size() >= maximum:
				break
	return output

static func _sanitize_snapshot_array(value: Variant, allowed_keys: Array[String], maximum: int) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return output
	for item_variant in value as Array:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_variant as Dictionary
		var clean: Dictionary = {}
		for key in allowed_keys:
			var field: Variant = item.get(key)
			if field is String or field is int or field is float or field is bool:
				clean[key] = str(field).left(160) if field is String else field
			elif typeof(field) == TYPE_DICTIONARY and key in ["effects", "run_effects"]:
				var effects: Dictionary = {}
				for effect_key in (field as Dictionary):
					var effect_value: Variant = (field as Dictionary)[effect_key]
					if effect_value is int or effect_value is float or effect_value is bool or effect_value is String:
						effects[str(effect_key).left(64)] = str(effect_value).left(128) if effect_value is String else effect_value
				clean[key] = effects
		if not clean.is_empty():
			output.append(clean)
			if output.size() >= maximum:
				break
	return output

static func _sanitize_run_record(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var raw: Dictionary = value as Dictionary
	var run_id := str(raw.get("run_id", "")).strip_edges().left(96)
	var stage_id := str(raw.get("stage_id", "")).strip_edges()
	if run_id.is_empty() or stage_id.is_empty() or stage_index(stage_id) < 0 or stage_id != str(stage(stage_index(stage_id)).get("id", "")):
		if OS.is_debug_build(): push_warning("Ignoring malformed Story run history record.")
		return {}
	if not bool(raw.get("completed", false)) or str(raw.get("context", "story")) != "story":
		return {}
	var damage_summary := _sanitize_snapshot_array(raw.get("damage_summary", []), ["source_id", "damage"], 48)
	damage_summary.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("damage", 0.0)) > float(b.get("damage", 0.0)))
	var mutator_ids := StoryMutatorsClass.sanitize_selection({}, stage_id, _sanitize_string_array(raw.get("mutator_ids", []), StoryMutatorsClass.MAX_ACTIVE), true)
	var clean_record := {
		"record_version": clampi(int(raw.get("record_version", STORY_RUN_RECORD_VERSION)), 1, STORY_RUN_RECORD_VERSION),
		"run_id":run_id,
		"context":"story",
		"stage_id":stage_id,
		"stage_name":str(raw.get("stage_name", stage(stage_index(stage_id)).get("name", stage_id))).left(160),
		"chapter":clampi(int(raw.get("chapter", stage(stage_index(stage_id)).get("chapter", 1))), 1, CHAPTERS.size()),
		"difficulty":normalize_difficulty_id(str(raw.get("difficulty", "normal"))),
		"timestamp":maxi(0, int(raw.get("timestamp", 0))),
		"completed":true,
		"duration_seconds":maxf(0.0, float(raw.get("duration_seconds", 0.0))),
		"final_level":maxi(1, int(raw.get("final_level", 1))),
		"mutator_ids":mutator_ids,
		"challenge_score":StoryMutatorsClass.reward_bonus(mutator_ids),
		"mastery_completed":_sanitize_string_array(raw.get("mastery_completed", []), 3),
		"mastery_newly_earned":_sanitize_string_array(raw.get("mastery_newly_earned", []), 3),
		"skills":_sanitize_snapshot_array(raw.get("skills", []), ["id", "name", "level", "evolution", "evolution_name"], 24),
		"rings":_sanitize_snapshot_array(raw.get("rings", []), ["id", "name", "attr", "value", "rarity", "tier"], 4),
		"artifacts":_sanitize_snapshot_array(raw.get("artifacts", []), ["id", "name", "rarity", "desc", "effects", "run_effects"], 4),
		"damage_summary":damage_summary,
		"total_damage":maxf(0.0, float(raw.get("total_damage", 0.0))),
		"healing":maxf(0.0, float(raw.get("healing", 0.0))),
		"kills":maxi(0, int(raw.get("kills", 0))),
		"boss_damage":maxf(0.0, float(raw.get("boss_damage", 0.0))),
		"revives":maxi(0, int(raw.get("revives", 0))),
		"damage_coverage":clampf(float(raw.get("damage_coverage", 0.0)), 0.0, 1.0),
	}
	var raw_damage_taken: Variant = raw.get("damage_taken")
	if (raw_damage_taken is int or raw_damage_taken is float) and not is_nan(float(raw_damage_taken)) and not is_inf(float(raw_damage_taken)) and float(raw_damage_taken) >= 0.0:
		clean_record["damage_taken"] = float(raw_damage_taken)
	return clean_record

static func _append_story_run_profile(profile: Dictionary, value: Variant, newly_earned: Array[String]) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var candidate: Dictionary = (value as Dictionary).duplicate(true)
	candidate["mastery_newly_earned"] = newly_earned.duplicate()
	var record := _sanitize_run_record(candidate)
	if record.is_empty():
		return {}
	profile["story_run_history"] = merge_story_run_history(profile.get("story_run_history", []), [record])
	return record

static func load_profile(username: String) -> Dictionary:
	var base := {"cleared":[], "difficulty_clears":{}, "claimed":[], "claimed_chapters":[], "mastery_rewards_claimed":[], "owned":[], "equipped":{}, "materials":0, "levels":{}, "results":{}, "mastery":{}, "story_run_history":[], "story_records_version":StoryRecordsClass.VERSION, "story_records":{}, "highest_unlocked_chapter":1, "highest_unlocked_stage":1, "story_complete":false}
	if username.is_empty() or not FileAccess.file_exists(_path(username)):
		return base
	var file := FileAccess.open(_path(username), FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	if file != null:
		file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		base.merge(parsed as Dictionary, true)
	var difficulty_clears: Dictionary = base.get("difficulty_clears", {}) as Dictionary
	for stage_id_variant in base.get("cleared", []) as Array:
		var cleared_stage_id := str(stage_id_variant)
		difficulty_clears[cleared_stage_id] = normalize_difficulty_id(str(difficulty_clears.get(cleared_stage_id, "normal")))
	base["difficulty_clears"] = difficulty_clears
	var normalized_reward_claims: Array[String] = []
	var raw_reward_claims: Variant = base.get("mastery_rewards_claimed", [])
	if typeof(raw_reward_claims) == TYPE_ARRAY:
		for claim_variant in raw_reward_claims as Array:
			if typeof(claim_variant) != TYPE_STRING:
				if OS.is_debug_build(): push_warning("Ignoring malformed Chapter Mastery claim value.")
				continue
			var claim_id := str(claim_variant)
			if claim_id.is_empty() or claim_id in normalized_reward_claims:
				continue
			# Preserve unknown string IDs for forward/backward save compatibility,
			# but they never resolve to or unlock a configured reward.
			if mastery_reward(claim_id).is_empty() and OS.is_debug_build():
				push_warning("Ignoring unknown Chapter Mastery claim ID: %s" % claim_id)
			normalized_reward_claims.append(claim_id)
	else:
		if OS.is_debug_build(): push_warning("Ignoring malformed Chapter Mastery claim list.")
	base["mastery_rewards_claimed"] = normalized_reward_claims
	base["story_run_history"] = _sanitize_run_history(base.get("story_run_history", []))
	var raw_story_records: Variant = base.get("story_records", {})
	var migrated_story_records := StoryRecordsClass.migrate(raw_story_records, base.get("story_run_history", []), base.get("results", {}))
	var records_migration_changed: bool = int(base.get("story_records_version", 0)) != StoryRecordsClass.VERSION or raw_story_records != migrated_story_records
	base["story_records_version"] = StoryRecordsClass.VERSION
	base["story_records"] = migrated_story_records
	var highest_cleared := -1
	for stage_id in base.get("cleared", []) as Array:
		highest_cleared = maxi(highest_cleared, stage_index(str(stage_id)))
	var unlocked_index := clampi(highest_cleared + 1, 0, stage_count() - 1)
	var derived_chapter := floori(float(unlocked_index) / 5.0) + 1
	var derived_stage := unlocked_index % 5 + 1
	if derived_chapter > int(base.get("highest_unlocked_chapter", 1)):
		base["highest_unlocked_chapter"] = derived_chapter
		base["highest_unlocked_stage"] = derived_stage
	elif derived_chapter == int(base.get("highest_unlocked_chapter", 1)):
		base["highest_unlocked_stage"] = maxi(int(base.get("highest_unlocked_stage", 1)), derived_stage)
	base["story_complete"] = bool(base.get("story_complete", false)) or "ch5_5" in (base.get("cleared", []) as Array)
	if records_migration_changed:
		_save(username, base)
	return base

static func _save(username: String, profile: Dictionary) -> bool:
	if username.is_empty(): return false
	profile["updated_at"] = int(Time.get_unix_time_from_system())
	var file := FileAccess.open(_path(username), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(profile))
	file.flush()
	return file.get_error() == OK

static func cloud_snapshot(username: String) -> Dictionary:
	return load_profile(username).duplicate(true)

static func replace_profile(username: String, profile: Dictionary) -> void:
	_save(username, profile.duplicate(true))

static func restore_from_server(username: String, server_profile: Dictionary) -> void:
	if username.is_empty() or server_profile.is_empty():
		return
	var local := load_profile(username)
	var server_is_newer := int(server_profile.get("updated_at", 0)) > int(local.get("updated_at", 0))
	for field in ["cleared", "claimed", "claimed_chapters", "mastery_rewards_claimed", "owned"]:
		var merged: Array = local.get(field, []) as Array
		for value in server_profile.get(field, []) as Array:
			if value not in merged:
				merged.append(value)
		local[field] = merged
	for stage_id in (server_profile.get("mastery", {}) as Dictionary):
		merge_mastery_profile(local, str(stage_id), (server_profile.get("mastery", {}) as Dictionary).get(stage_id, []) as Array)
	for stage_id in (server_profile.get("difficulty_clears", {}) as Dictionary):
		merge_difficulty_clear_profile(local, str(stage_id), str((server_profile.get("difficulty_clears", {}) as Dictionary).get(stage_id, "normal")))
	local["story_run_history"] = merge_story_run_history(local.get("story_run_history", []), server_profile.get("story_run_history", []))
	local["story_records"] = StoryRecordsClass.merge_records(local.get("story_records", {}), server_profile.get("story_records", {}))
	local["story_records_version"] = StoryRecordsClass.VERSION
	var levels: Dictionary = local.get("levels", {}) as Dictionary
	for gear_id in (server_profile.get("levels", {}) as Dictionary):
		levels[gear_id] = maxi(int(levels.get(gear_id, 1)), int((server_profile.get("levels", {}) as Dictionary)[gear_id]))
	local["levels"] = levels
	if server_is_newer:
		local["materials"] = int(server_profile.get("materials", 0))
	var server_equipped: Dictionary = server_profile.get("equipped", {}) as Dictionary
	if server_is_newer or ((local.get("equipped", {}) as Dictionary).is_empty() and not server_equipped.is_empty()):
		local["equipped"] = server_equipped.duplicate(true)
	var results: Dictionary = local.get("results", {}) as Dictionary
	for stage_id in (server_profile.get("results", {}) as Dictionary):
		var server_result: Dictionary = (server_profile.get("results", {}) as Dictionary).get(stage_id, {}) as Dictionary
		var local_result: Dictionary = results.get(stage_id, {}) as Dictionary
		if local_result.is_empty() or int(server_result.get("updated_at", 0)) > int(local_result.get("updated_at", 0)):
			results[stage_id] = server_result.duplicate(true)
	local["results"] = results
	local["story_records"] = StoryRecordsClass.migrate(local.get("story_records", {}), local.get("story_run_history", []), results)
	var local_chapter := int(local.get("highest_unlocked_chapter", 1))
	var server_chapter := int(server_profile.get("highest_unlocked_chapter", 1))
	if server_chapter > local_chapter:
		local["highest_unlocked_chapter"] = server_chapter
		local["highest_unlocked_stage"] = int(server_profile.get("highest_unlocked_stage", 1))
	elif server_chapter == local_chapter:
		local["highest_unlocked_stage"] = maxi(int(local.get("highest_unlocked_stage", 1)), int(server_profile.get("highest_unlocked_stage", 1)))
	local["story_complete"] = bool(local.get("story_complete", false)) or bool(server_profile.get("story_complete", false))
	local["updated_at"] = maxi(int(local.get("updated_at", 0)), int(server_profile.get("updated_at", 0)))
	_save(username, local)

static func purge_user(username: String) -> void:
	if not username.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path(username)))

static func stage(index: int) -> Dictionary:
	var safe := clampi(index, 0, stage_count() - 1)
	var chapter_index := floori(float(safe) / 5.0)
	var chapter_stage := safe % 5
	var chapter: Dictionary = CHAPTERS[chapter_index] as Dictionary
	var hp := 1.08 + float(safe) * 0.055 + float(chapter_index) * 0.08
	var damage := 1.0 + float(safe) * 0.04 + float(chapter_index) * 0.05
	var speed := 1.0 + float(safe) * 0.006 + float(chapter_index) * 0.02
	var objective_config: Dictionary = (STAGE_OBJECTIVES[chapter_index][chapter_stage] as Dictionary).duplicate(true)
	var objective := str(objective_config.get("id", "escort"))
	return {"id":"ch%d_%d" % [chapter_index + 1, chapter_stage + 1], "chapter":chapter_index + 1, "chapter_stage":chapter_stage + 1, "name":"%d-%d  %s" % [chapter_index + 1, chapter_stage + 1, str((chapter.stages as Array)[chapter_stage])], "story":"Advance through the %s and uncover the path ahead." % str(chapter.theme), "challenge":"%s\nEnemy health +%d%% · damage +%d%% · speed +%d%%" % [str(objective_config.get("desc", "Complete the objective")), roundi((hp - 1.0) * 100.0), roundi((damage - 1.0) * 100.0), roundi((speed - 1.0) * 100.0)], "objective":objective, "objective_config":objective_config, "enemy_hp":hp, "enemy_damage":damage, "enemy_speed":speed, "boss":"" , "coins":25 + safe * 4, "materials":1 + chapter_index}

static func normalize_difficulty_id(difficulty_id: String) -> String:
	var normalized := difficulty_id.to_lower()
	return normalized if normalized in STORY_DIFFICULTY_IDS else "normal"

static func difficulty_rank(difficulty_id: String) -> int:
	var normalized := normalize_difficulty_id(difficulty_id)
	return int((STORY_DIFFICULTIES[normalized] as Dictionary).get("rank", 0))

static func difficulty_name(difficulty_id: String) -> String:
	var normalized := normalize_difficulty_id(difficulty_id)
	return str((STORY_DIFFICULTIES[normalized] as Dictionary).get("name", "Normal"))

static func difficulty_config(stage_id: String, difficulty_id: String) -> Dictionary:
	var normalized := normalize_difficulty_id(difficulty_id)
	var config: Dictionary = (STORY_DIFFICULTIES[normalized] as Dictionary).duplicate(true)
	var stage_rules: Dictionary = STAGE_DIFFICULTY_RULES.get(stage_id, {}) as Dictionary
	config.merge((stage_rules.get(normalized, {}) as Dictionary).duplicate(true), true)
	config["id"] = normalized
	return config

static func apply_difficulty(stage_data: Dictionary, difficulty_id: String) -> Dictionary:
	var configured := stage_data.duplicate(true)
	var normalized := normalize_difficulty_id(difficulty_id)
	var config := difficulty_config(str(configured.get("id", "")), normalized)
	configured["difficulty"] = normalized
	configured["difficulty_name"] = difficulty_name(normalized)
	configured["difficulty_rank"] = difficulty_rank(normalized)
	configured["difficulty_config"] = config
	return configured

static func apply_mutators(stage_data: Dictionary, mutator_ids: Array, profile: Dictionary = {}, bypass_unlocks: bool = false) -> Dictionary:
	return StoryMutatorsClass.apply_to_stage(stage_data, mutator_ids, profile, bypass_unlocks)

static func configure_run(stage_data: Dictionary, difficulty_id: String, mutator_ids: Array, profile: Dictionary = {}, bypass_unlocks: bool = false) -> Dictionary:
	return apply_mutators(apply_difficulty(stage_data, difficulty_id), mutator_ids, profile, bypass_unlocks)

static func highest_cleared_difficulty(profile: Dictionary, stage_id: String) -> int:
	var stored: Dictionary = profile.get("difficulty_clears", {}) as Dictionary
	if stored.has(stage_id):
		return difficulty_rank(str(stored.get(stage_id, "normal")))
	return 0 if stage_id in (profile.get("cleared", []) as Array) else -1

static func highest_cleared_difficulty_name(profile: Dictionary, stage_id: String) -> String:
	var rank := highest_cleared_difficulty(profile, stage_id)
	return "None" if rank < 0 else difficulty_name(str(STORY_DIFFICULTY_IDS[rank]))

static func difficulty_unlocked(profile: Dictionary, stage_id: String, difficulty_id: String) -> bool:
	var rank := difficulty_rank(difficulty_id)
	return rank == 0 or highest_cleared_difficulty(profile, stage_id) >= rank - 1

static func merge_difficulty_clear_profile(profile: Dictionary, stage_id: String, difficulty_id: String) -> bool:
	var normalized := normalize_difficulty_id(difficulty_id)
	var previous_rank := highest_cleared_difficulty(profile, stage_id)
	var next_rank := difficulty_rank(normalized)
	if next_rank <= previous_rank:
		return false
	var difficulty_clears: Dictionary = profile.get("difficulty_clears", {}) as Dictionary
	difficulty_clears[stage_id] = normalized
	profile["difficulty_clears"] = difficulty_clears
	return true

static func stage_count() -> int:
	return CHAPTERS.size() * 5

static func chapter(index: int) -> Dictionary:
	return CHAPTERS[clampi(index, 0, CHAPTERS.size() - 1)] as Dictionary

static func unlocked_stage(profile: Dictionary) -> int:
	for chapter_number in range(1, CHAPTERS.size() + 1):
		if is_chapter_complete(profile, chapter_number) and not is_chapter_claimed(profile, chapter_number):
			return chapter_number * 5 - 1
	var highest_cleared := -1
	for stage_id_variant in profile.get("cleared", []) as Array:
		highest_cleared = maxi(highest_cleared, stage_index(String(stage_id_variant)))
	return clampi(highest_cleared + 1, 0, stage_count() - 1)

static func record_clear(username: String, stage_id: String, result: Dictionary = {}) -> Dictionary:
	var profile := load_profile(username)
	var difficulty_id := normalize_difficulty_id(str(result.get("difficulty", "normal")))
	var mutator_ids: Array = StoryMutatorsClass.sanitize_selection(profile, stage_id, result.get("mutators", []) as Array, true)
	var mutator_bonus := StoryMutatorsClass.reward_bonus(mutator_ids)
	var mutator_multiplier := StoryMutatorsClass.reward_multiplier(mutator_ids)
	var previous_difficulty_rank := highest_cleared_difficulty(profile, stage_id)
	var chapter_number := int(stage(stage_index(stage_id)).get("chapter", 1))
	var previous_chapter_mastery := chapter_mastery(profile, chapter_number)
	var new_mastery: Array[String] = merge_mastery_profile(profile, stage_id, result.get("mastery_earned", []) as Array)
	var new_mastery_rewards := newly_available_mastery_rewards(profile, chapter_number, previous_chapter_mastery)
	var chapter_mastery_total := chapter_mastery(profile, chapter_number)
	var persisted_run_record := _append_story_run_profile(profile, result.get("run_record", {}), new_mastery)
	var record_evaluation := StoryRecordsClass.evaluate_run(profile.get("story_records", {}), persisted_run_record)
	profile["story_records"] = record_evaluation.get("updated_records", profile.get("story_records", {}))
	profile["story_records_version"] = StoryRecordsClass.VERSION
	record_evaluation.erase("updated_records")
	var results: Dictionary = profile.get("results", {}) as Dictionary
	var previous: Dictionary = results.get(stage_id, {}) as Dictionary
	var elapsed := float(result.get("elapsed", 0.0))
	results[stage_id] = {"latest_seconds":elapsed, "best_seconds":elapsed if previous.is_empty() or elapsed < float(previous.get("best_seconds", elapsed)) else float(previous.get("best_seconds", elapsed)), "kills":int(result.get("kills", 0)), "level":int(result.get("level", 1)), "difficulty":difficulty_id, "updated_at":int(Time.get_unix_time_from_system())}
	profile["results"] = results
	var cleared: Array = profile.get("cleared", []) as Array
	var first_clear := stage_id not in cleared
	var first_difficulty_clear := merge_difficulty_clear_profile(profile, stage_id, difficulty_id)
	var newly_unlocked := ""
	if first_difficulty_clear and difficulty_rank(difficulty_id) < STORY_DIFFICULTY_IDS.size() - 1:
		newly_unlocked = str(STORY_DIFFICULTY_IDS[difficulty_rank(difficulty_id) + 1])
	if stage_id in cleared:
		var replay_stage := stage(stage_index(stage_id))
		var replay_materials: int = floori(float(replay_stage.get("materials", 0)) * REPLAY_REWARD_MULTIPLIER * mutator_multiplier)
		var replay_coins: int = floori(float(replay_stage.get("coins", 0)) * REPLAY_REWARD_MULTIPLIER * mutator_multiplier)
		profile["materials"] = int(profile.get("materials", 0)) + replay_materials
		_add_camp_coins(username, replay_coins)
		_save(username, profile)
		return {"first_clear":false, "first_difficulty_clear":first_difficulty_clear, "difficulty":difficulty_id, "previous_difficulty_rank":previous_difficulty_rank, "newly_unlocked":newly_unlocked, "materials":replay_materials, "coins":replay_coins, "reward_multiplier":REPLAY_REWARD_MULTIPLIER * mutator_multiplier, "mutators":mutator_ids, "mutator_bonus":mutator_bonus, "mutator_multiplier":mutator_multiplier, "new_mastery":new_mastery, "mastery_total":stage_mastery(profile, stage_id), "chapter_mastery":chapter_mastery_total, "new_mastery_rewards":new_mastery_rewards, "chapter_mastered":previous_chapter_mastery < 15 and chapter_mastery_total >= 15, "run_record":persisted_run_record, "record_evaluation":record_evaluation}
	if first_clear:
		cleared.append(stage_id)
		profile["cleared"] = cleared
		var next_index := mini(stage_index(stage_id) + 1, stage_count() - 1)
		profile["highest_unlocked_chapter"] = floori(float(next_index) / 5.0) + 1
		profile["highest_unlocked_stage"] = next_index % 5 + 1
		if stage_id == "ch5_5": profile["story_complete"] = true
	var stage_data := stage(stage_index(stage_id))
	profile["materials"] = int(profile.get("materials", 0)) + int(stage_data.materials)
	_add_camp_coins(username, int(stage_data.coins))
	_save(username, profile)
	return {"first_clear":true, "first_difficulty_clear":first_difficulty_clear, "difficulty":difficulty_id, "previous_difficulty_rank":previous_difficulty_rank, "newly_unlocked":newly_unlocked, "materials":int(stage_data.materials), "coins":int(stage_data.coins), "reward_multiplier":1.0, "mutators":mutator_ids, "mutator_bonus":0.0, "mutator_multiplier":1.0, "new_mastery":new_mastery, "mastery_total":stage_mastery(profile, stage_id), "chapter_mastery":chapter_mastery_total, "new_mastery_rewards":new_mastery_rewards, "chapter_mastered":previous_chapter_mastery < 15 and chapter_mastery_total >= 15, "run_record":persisted_run_record, "record_evaluation":record_evaluation}

static func mastery_objectives(stage_id: String) -> Array:
	return (MASTERY_OBJECTIVES.get(stage_id, []) as Array).duplicate(true)

static func earned_mastery(profile: Dictionary, stage_id: String) -> Array:
	var valid_ids: Dictionary = {}
	for objective in mastery_objectives(stage_id):
		valid_ids[str((objective as Dictionary).get("id", ""))] = true
	var earned: Array = []
	for objective_variant in (profile.get("mastery", {}) as Dictionary).get(stage_id, []) as Array:
		var objective_id := str(objective_variant)
		if valid_ids.has(objective_id) and objective_id not in earned:
			earned.append(objective_id)
	return earned

static func merge_mastery_profile(profile: Dictionary, stage_id: String, objective_ids: Array) -> Array[String]:
	var mastery: Dictionary = profile.get("mastery", {}) as Dictionary
	var earned: Array = earned_mastery(profile, stage_id)
	var valid_ids: Dictionary = {}
	for objective in mastery_objectives(stage_id): valid_ids[str((objective as Dictionary).get("id", ""))] = true
	var newly_earned: Array[String] = []
	for objective_variant in objective_ids:
		var objective_id := str(objective_variant)
		if valid_ids.has(objective_id) and objective_id not in earned:
			earned.append(objective_id)
			newly_earned.append(objective_id)
	mastery[stage_id] = earned
	profile["mastery"] = mastery
	return newly_earned

static func stage_mastery(profile: Dictionary, stage_id: String) -> int:
	return earned_mastery(profile, stage_id).size()

static func chapter_mastery(profile: Dictionary, chapter_number: int) -> int:
	var total := 0
	for stage_number in range(1, 6): total += stage_mastery(profile, "ch%d_%d" % [chapter_number, stage_number])
	return total

static func campaign_mastery(profile: Dictionary) -> int:
	var total := 0
	for chapter_number in range(1, 6): total += chapter_mastery(profile, chapter_number)
	return total

static func mastery_reward(reward_id: String) -> Dictionary:
	for reward_variant in CHAPTER_MASTERY_REWARDS:
		var reward: Dictionary = reward_variant as Dictionary
		if str(reward.get("id", "")) == reward_id:
			return reward.duplicate(true)
	return {}

static func chapter_mastery_rewards(chapter_number: int) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	for reward_variant in CHAPTER_MASTERY_REWARDS:
		var reward: Dictionary = reward_variant as Dictionary
		if int(reward.get("chapter", 0)) == chapter_number:
			rewards.append(reward.duplicate(true))
	rewards.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("threshold", 0)) < int(b.get("threshold", 0)))
	return rewards

static func mastery_reward_claimed(profile: Dictionary, reward_id: String) -> bool:
	return reward_id in (profile.get("mastery_rewards_claimed", []) as Array)

static func mastery_reward_state(profile: Dictionary, reward_id: String) -> String:
	var reward := mastery_reward(reward_id)
	if reward.is_empty():
		return "invalid"
	if mastery_reward_claimed(profile, reward_id):
		return "claimed"
	return "available" if chapter_mastery(profile, int(reward.get("chapter", 0))) >= int(reward.get("threshold", 0)) else "locked"

static func available_mastery_rewards(profile: Dictionary, chapter_number: int) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for reward in chapter_mastery_rewards(chapter_number):
		if mastery_reward_state(profile, str(reward.get("id", ""))) == "available":
			available.append(reward)
	return available

static func newly_available_mastery_rewards(profile: Dictionary, chapter_number: int, previous_stars: int) -> Array[String]:
	var reward_ids: Array[String] = []
	var current_stars := chapter_mastery(profile, chapter_number)
	for reward in chapter_mastery_rewards(chapter_number):
		var threshold := int(reward.get("threshold", 0))
		var reward_id := str(reward.get("id", ""))
		if previous_stars < threshold and current_stars >= threshold and not mastery_reward_claimed(profile, reward_id):
			reward_ids.append(reward_id)
	return reward_ids

static func claim_mastery_reward(username: String, chapter_number: int, reward_id: String) -> Dictionary:
	if username.is_empty():
		return {"ok":false, "error":"No account is available."}
	var reward := mastery_reward(reward_id)
	if reward.is_empty() or int(reward.get("chapter", 0)) != chapter_number:
		return {"ok":false, "error":"Invalid Chapter Mastery reward."}
	var profile := load_profile(username)
	var state := mastery_reward_state(profile, reward_id)
	if state == "claimed":
		return {"ok":false, "error":"Reward already claimed."}
	if state != "available":
		return {"ok":false, "error":"More Chapter Mastery stars are required."}
	var materials := maxi(0, int(reward.get("materials", 0)))
	if materials <= 0:
		return {"ok":false, "error":"Reward grant configuration is invalid."}
	var claimed: Array = profile.get("mastery_rewards_claimed", []) as Array
	claimed.append(reward_id)
	profile["mastery_rewards_claimed"] = claimed
	profile["materials"] = int(profile.get("materials", 0)) + materials
	if not _save(username, profile):
		return {"ok":false, "error":"Reward could not be saved. Please try again."}
	return {"ok":true, "id":reward_id, "chapter":chapter_number, "threshold":int(reward.get("threshold", 0)), "materials":materials, "balance":int(profile.get("materials", 0))}

static func validate_mastery_rewards() -> Array[String]:
	var issues: Array[String] = []
	var ids: Dictionary = {}
	for chapter_number in range(1, CHAPTERS.size() + 1):
		var thresholds: Array[int] = []
		for reward in chapter_mastery_rewards(chapter_number):
			var reward_id := str(reward.get("id", ""))
			var threshold := int(reward.get("threshold", 0))
			if reward_id.is_empty() or ids.has(reward_id): issues.append("Duplicate or empty Chapter Mastery reward ID: %s" % reward_id)
			if threshold not in [5, 10, 15] or threshold in thresholds: issues.append("Invalid Chapter %d Mastery threshold: %d" % [chapter_number, threshold])
			if int(reward.get("materials", 0)) <= 0: issues.append("Chapter Mastery reward %s must grant materials." % reward_id)
			ids[reward_id] = true
			thresholds.append(threshold)
		if thresholds.size() != 3: issues.append("Chapter %d must define exactly three Mastery rewards." % chapter_number)
	if ids.size() != CHAPTERS.size() * 3: issues.append("Chapter Mastery track must define exactly 15 unique rewards.")
	return issues

static func stage_reward(stage_id: String, replay: bool = false) -> Dictionary:
	var stage_data: Dictionary = stage(stage_index(stage_id))
	var multiplier: float = REPLAY_REWARD_MULTIPLIER if replay else 1.0
	return {
		"coins": floori(float(stage_data.get("coins", 0)) * multiplier),
		"materials": floori(float(stage_data.get("materials", 0)) * multiplier),
		"multiplier": multiplier,
	}

static func claim_chapter(username: String, chapter_number: int) -> Array[String]:
	var profile := load_profile(username)
	var final_stage_id := "ch%d_5" % chapter_number
	if final_stage_id not in (profile.get("cleared", []) as Array) or is_chapter_claimed(profile, chapter_number):
		return []
	var claimed: Array = profile.get("claimed_chapters", []) as Array
	claimed.append(chapter_number)
	profile["claimed_chapters"] = claimed
	var owned: Array = profile.get("owned", []) as Array
	var newly_owned: Array[String] = []
	for gear_id in (chapter(chapter_number - 1).get("reward", []) as Array):
		if gear_id not in owned:
			owned.append(gear_id)
			newly_owned.append(String(gear_id))
	profile["owned"] = owned
	_save(username, profile)
	return newly_owned

static func stage_index(stage_id: String) -> int:
	var parts := stage_id.trim_prefix("ch").split("_")
	if parts.size() != 2: return 0
	return maxi(0, (int(parts[0]) - 1) * 5 + int(parts[1]) - 1)

static func is_chapter_complete(profile: Dictionary, chapter_number: int) -> bool:
	return "ch%d_5" % chapter_number in (profile.get("cleared", []) as Array)

static func is_chapter_claimed(profile: Dictionary, chapter_number: int) -> bool:
	for claimed_variant in profile.get("claimed_chapters", []) as Array:
		if int(claimed_variant) == chapter_number:
			return true
	return false

static func _add_camp_coins(username: String, amount: int) -> void:
	var camp := ProgressionStore.load_profile(username)
	camp["coins"] = int(camp.get("coins", 0)) + amount
	ProgressionStore.save_profile(username, camp)

static func equip(username: String, gear_id: String) -> void:
	var profile := load_profile(username)
	if gear_id not in (profile.get("owned", []) as Array) or not GEAR.has(gear_id): return
	var equipped: Dictionary = profile.get("equipped", {}) as Dictionary
	equipped[String((GEAR[gear_id] as Dictionary).get("slot", ""))] = gear_id
	profile["equipped"] = equipped
	_save(username, profile)

static func unequip(username: String, gear_id: String) -> void:
	var profile := load_profile(username)
	var equipped: Dictionary = profile.get("equipped", {}) as Dictionary
	for slot in equipped.keys():
		if String(equipped[slot]) == gear_id: equipped.erase(slot)
	profile["equipped"] = equipped
	_save(username, profile)

static func is_equipped(profile: Dictionary, gear_id: String) -> bool:
	return gear_id in (profile.get("equipped", {}) as Dictionary).values()

static func bonuses(username: String) -> Dictionary:
	var out := {}
	var profile := load_profile(username)
	var equipped: Dictionary = profile.get("equipped", {}) as Dictionary
	for gear_id in equipped.values():
		if not GEAR.has(gear_id): continue
		for key in ((GEAR[gear_id] as Dictionary).get("effects", {}) as Dictionary):
			out[key] = float(out.get(key, 0.0)) + scaled_effect(profile, String(gear_id), String(key))
	return out

static func gear_level(profile: Dictionary, gear_id: String) -> int:
	return maxi(1, int((profile.get("levels", {}) as Dictionary).get(gear_id, 1)))

static func scaled_effect(profile: Dictionary, gear_id: String, key: String) -> float:
	if not GEAR.has(gear_id): return 0.0
	var base := float(((GEAR[gear_id] as Dictionary).get("effects", {}) as Dictionary).get(key, 0.0))
	return base * (1.0 + float(gear_level(profile, gear_id) - 1) * 0.18)

static func upgrade_cost(profile: Dictionary, gear_id: String) -> Dictionary:
	var level := gear_level(profile, gear_id)
	return {"materials":level + 1, "coins":40 + level * 35}

static func upgrade(username: String, gear_id: String) -> String:
	var profile := load_profile(username)
	if gear_id not in (profile.get("owned", []) as Array): return "Equipment not owned."
	var level := gear_level(profile, gear_id)
	if level >= MAX_GEAR_LEVEL: return "Maximum level reached."
	var cost := upgrade_cost(profile, gear_id)
	if int(profile.get("materials", 0)) < int(cost.materials): return "Not enough upgrade materials."
	var camp := ProgressionStore.load_profile(username)
	if int(camp.get("coins", 0)) < int(cost.coins): return "Not enough camp coins."
	profile["materials"] = int(profile.get("materials", 0)) - int(cost.materials)
	var levels: Dictionary = profile.get("levels", {}) as Dictionary
	levels[gear_id] = level + 1
	profile["levels"] = levels
	camp["coins"] = int(camp.get("coins", 0)) - int(cost.coins)
	_save(username, profile)
	ProgressionStore.save_profile(username, camp)
	return ""

static func reset_material_refund(profile: Dictionary, gear_id: String) -> int:
	var refund := 0
	for level in range(1, gear_level(profile, gear_id)):
		refund += level + 1
	return refund

static func reset_coin_refund(profile: Dictionary, gear_id: String) -> int:
	var refund := 0
	for level in range(1, gear_level(profile, gear_id)):
		refund += 40 + level * 35
	return refund

static func reset_upgrade(username: String, gear_id: String) -> int:
	var profile := load_profile(username)
	if gear_id not in (profile.get("owned", []) as Array):
		return 0
	var refund := reset_material_refund(profile, gear_id)
	if refund <= 0:
		return 0
	var coin_refund := reset_coin_refund(profile, gear_id)
	var levels: Dictionary = profile.get("levels", {}) as Dictionary
	levels[gear_id] = 1
	profile["levels"] = levels
	profile["materials"] = int(profile.get("materials", 0)) + refund
	var camp := ProgressionStore.load_profile(username)
	camp["coins"] = int(camp.get("coins", 0)) + coin_refund
	_save(username, profile)
	ProgressionStore.save_profile(username, camp)
	return refund

static func add_materials(username: String, amount: int) -> void:
	if amount <= 0: return
	var profile := load_profile(username)
	profile["materials"] = int(profile.get("materials", 0)) + amount
	_save(username, profile)

static func effect_text(gear_id: String) -> String:
	if not GEAR.has(gear_id): return ""
	var effects: Dictionary = (GEAR[gear_id] as Dictionary).get("effects", {}) as Dictionary
	var parts: Array[String] = []
	for key in effects:
		parts.append("%s +%d%%" % [stat_name(String(key)), display_percent(String(key), float(effects[key]))])
	return ", ".join(parts)

static func scaled_effect_text(profile: Dictionary, gear_id: String) -> String:
	if not GEAR.has(gear_id): return ""
	var parts: Array[String] = []
	for key in ((GEAR[gear_id] as Dictionary).get("effects", {}) as Dictionary):
		parts.append("%s +%d%%" % [stat_name(String(key)), display_percent(String(key), scaled_effect(profile, gear_id, String(key)))])
	return ", ".join(parts)

static func stat_name(key: String) -> String:
	match key:
		"skill_dmg": return "Skill Damage"
		"skill_cd": return "Skill Cooldown"
		"max_hp_pct": return "Maximum Health"
		"max_hp": return "Maximum Health"
		"regen": return "Health Regeneration"
		"damage_taken_mul": return "Damage Taken"
		"move_speed_mul": return "Movement Speed"
		"crit_chance": return "Critical Chance"
		"crit_dmg": return "Critical Damage"
		"boss_dmg": return "Boss Damage"
		"xp_bonus": return "Experience Bonus"
		"aoe_radius": return "Area of Effect Radius"
		"projectile_spd": return "Projectile Speed"
		"projectile_dmg", "projectile_damage": return "Projectile Damage"
		"revive_once": return "Revive Once"
		"revive_hp_pct": return "Restore Health"
		"timed_shield": return "Timed Shield"
		"luck": return "Luck"
		"ring_drop_rate": return "Ring Drop Rate"
		"potion_drop_rate": return "Potion Drop Rate"
		"freeze_duration": return "Freeze Duration"
		"ice_dmg": return "Ice Damage"
		"lightning_chain": return "Lightning Chain"
		"lightning_dmg": return "Lightning Damage"
		"burn_duration": return "Burn Duration"
		"lifesteal": return "Lifesteal"
		"healing_efficiency": return "Healing Effectiveness"
		"enemy_hp_mul": return "Enemy Health"
		"pickup_radius": return "Pickup Radius"
		"projectile_homing": return "Projectile Homing"
		"proj_dup_chance": return "Projectile Duplication Chance"
		"regen_pulse_pct": return "Regeneration Pulse"
		"regen_pulse_interval": return "Regeneration Pulse Interval"
		"blink_interval": return "Blink Interval"
		"blink_dist": return "Blink Distance"
		"blink_iframes": return "Invulnerability Frames"
		"chaos_mystery_box": return "Chaos Mystery Effect"
		"chaos_wheel": return "Chaos Wheel Effect"
		"wheel_duration": return "Wheel Duration"
		"wheel_interval": return "Wheel Interval"
		_: return key.replace("_", " ").capitalize()

static func stat_value_text(key: String, value: float) -> String:
	if key in ["skill_dmg", "projectile_spd", "projectile_dmg", "projectile_damage", "max_hp_pct", "xp_bonus", "crit_chance", "crit_dmg", "luck", "ring_drop_rate", "damage_taken_mul", "enemy_hp_mul", "move_speed_mul", "healing_efficiency", "freeze_duration", "ice_dmg", "lightning_dmg", "burn_duration", "pickup_radius", "projectile_homing", "proj_dup_chance", "regen_pulse_pct", "potion_drop_rate", "aoe_radius", "boss_dmg", "skill_cd"]:
		var percentage := value * 100.0
		return "%+.1f%%" % percentage if absf(percentage) < 1.0 and not is_zero_approx(percentage) else "%+d%%" % roundi(percentage)
	if key in ["wheel_duration", "wheel_interval", "blink_interval", "regen_pulse_interval"]:
		return "%s seconds" % String.num(value, 0)
	if key == "blink_dist": return "%s meters" % String.num(value / 37.5, 0)
	if key == "blink_iframes": return "%s seconds" % String.num(value, 1)
	if key == "regen": return "%+.1f health per second" % value
	if key in ["revive_once", "lightning_chain", "chaos_mystery_box", "chaos_wheel"]: return "+%d" % roundi(value)
	return ("+" if value >= 0.0 else "") + String.num(value, 2)

static func display_percent(key: String, value: float) -> int:
	return roundi(absf(value) * 100.0) if key == "damage_taken_mul" else roundi(value * 100.0)
