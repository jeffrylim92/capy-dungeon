extends Node2D

const StoryTelemetryClass = preload("res://scripts/story/StoryTelemetry.gd")
const StoryCompletionValidatorClass = preload("res://scripts/story/StoryCompletionValidator.gd")
const ChapterOneStageControllerClass = preload("res://scripts/story/ChapterOneStageController.gd")
const ChapterTwoStageControllerClass = preload("res://scripts/story/ChapterTwoStageController.gd")
const ChapterThreeStageControllerClass = preload("res://scripts/story/ChapterThreeStageController.gd")
const ChapterFourStageControllerClass = preload("res://scripts/story/ChapterFourStageController.gd")
const ChapterFiveStageControllerClass = preload("res://scripts/story/ChapterFiveStageController.gd")

## Vampire Survivors-style roguelite.
## Move to survive, skills auto-cast, kill monsters, level up, pick new skills.

signal match_ended(next_action: String)

# ─── Public (set by Main before adding to tree) ───────────────────────────────
var selected_player_character: CharacterData = null
var account_username: String = ""
var account_cloud_id: String = ""
var account_display_name: String = ""
var is_story_test_run: bool = false

# ─── Tuning constants ─────────────────────────────────────────────────────────
const PLAYER_R:    float = 34.0
const PLAYER_DRAW_R: float = 56.0
const PLAYER_SPRITE_SIZE: float = 144.0
const LEVEL_UP_HP_GAIN_PCT: float = 0.08
const LEVEL_UP_HP_GAIN_FLAT: float = 14.0
const LEVEL_UP_HEAL_GAIN_MULT: float = 1.25
const ENEMY_DRAW_SCALE: float = 1.60
const IFRAMES_SEC: float = 0.55
const ORB_ORBIT_R: float = 72.0
const ORB_R:       float = 16.0
const ORB_SPD:     float = 2.2
const BOLT_R:      float = 8.0
const BOLT_LIFE:   float = 3.5
const ICE_ORB_R:   float = 11.0
const ICE_ORB_LIFE: float = 2.0
const PIERCE_ARROW_LIFE: float = 5.0
const XP_ORB_R:    float = 9.0
const XP_COLLECT_R: float = 80.0
const XP_ORB_MAX: int = 240
const XP_FAST_ENEMY_MULT: float = 1.25
const XP_TANK_ENEMY_MULT: float = 1.75
const XP_SPECIAL_ENEMY_MULT: float = 2.0
const XP_BOSS_ENEMY_MULT: float = 6.0
const XP_AFFIX_ENEMY_MULT: float = 1.25
const HUD_UPDATE_INTERVAL: float = 0.10
const ENEMY_HIT_IF: float = 0.28
const ENEMY_SURVIVE_SPEEDUP_SEC: float = 5.0
const ENEMY_SURVIVE_SPEEDUP_MULT: float = 1.10
const TARGET_SKILL_DAMAGE_MULT: float = 1.45
const PROJECTILE_SKILL_DAMAGE_MULT: float = 1.25
const SHOOTER_HOMING_LIFE: float = 4.2
const SHOOTER_HOMING_TURN_RATE: float = 0.55
const SHOOTER_SPREAD_LIFE: float = 3.0
const SHOOTER_MORTAR_WARN_TIME: float = 1.5
const SHOOTER_MORTAR_POOL_LIFE: float = 2.0
const LAVA_LINE_WARN_TIME: float = 1.0
const LAVA_LINE_ERUPT_TIME: float = 3.0
const LAVA_CHARGE_TIME: float = 1.35
const LAVA_CHARGE_TRAIL_LIFE: float = 5.0
const BOSS_ARENA_HALF: Vector2 = Vector2(610.0, 424.0)
const ROOM_SPAN_WAVES: int = 4
const STORY_KEY_DROP_START: float = 0.003
const STORY_KEY_DROP_GROWTH_PER_SECOND: float = 0.0007
const STORY_KEY_DROP_MAX: float = 0.08
const STORY_NEST_SHIELD_SECONDS: float = 10.0
const STORY_NEST_EFFECTIVE_RADIUS: float = 280.0
const SAFE_INTERACTION_RADIUS: float = 190.0
const FORGE_INTERACTION_RADIUS: float = 190.0
const OBJECTIVE_NEST_PATH: String = "res://assets/story/objectives/enemy_nest.png"
const OBJECTIVE_SHRINE_PATH: String = "res://assets/story/objectives/defense_shrine.png"
const OBJECTIVE_SCOUT_PATH: String = "res://assets/story/objectives/scout_npc.png"
const OBJECTIVE_HAZARD_PATH: String = "res://assets/story/objectives/hazard_emitter.png"
const OBJECTIVE_SAFE_PATH: String = "res://assets/story/objectives/coin_safe.png"
const OBJECTIVE_FORGE_PATH: String = "res://assets/story/objectives/forgecore_forge.png"
const CHAPTER_ONE_EXTRACTION_PATH: String = "res://assets/story/objectives/chapter1_scout_extraction.png"
const CHAPTER_ONE_ENERGY_SPORE_PATH: String = "res://assets/story/objectives/chapter1_energy_spore.png"
const CHAPTER_ONE_FEEDING_SAC_PATH: String = "res://assets/story/objectives/chapter1_feeding_sac.png"
const CHAPTER_ONE_WATCHPATH_KEY_PATH: String = "res://assets/story/objectives/chapter1_watchpath_key.png"
const CHAPTER_ONE_WATCHPATH_EXIT_PATH: String = "res://assets/story/objectives/chapter1_watchpath_exit.png"
const CHAPTER_ONE_ANIMAL_TRACKS_PATH: String = "res://assets/story/objectives/chapter1_animal_tracks.png"
const CHAPTER_ONE_BARRICADE_PATH: String = "res://assets/story/objectives/chapter1_barricade.png"
const CHAPTER_ONE_OVERHEAT_BURST_PATH: String = "res://assets/story/objectives/chapter1_overheat_burst.png"
const ROOM_ROUTE: Array = [
	{"id": "lava", "name": "Lava Rooms", "short": "Damage over time", "col": Color(1.0, 0.42, 0.12), "desc": "The ground burns — take periodic fire damage while standing still."},
	{"id": "frozen", "name": "Frozen Floors", "short": "Sliding movement", "col": Color(0.52, 0.84, 1.0), "desc": "Icy surface causes momentum — movement feels slippery and hard to stop."},
	{"id": "poison", "name": "Poison Swamps", "short": "-10% skill damage", "col": Color(0.34, 0.82, 0.34), "desc": "Toxic fumes weaken attacks — all skill damage reduced by 10%."},
	{"id": "spike", "name": "Spike Corridors", "short": "HP regen suppressed", "col": Color(0.92, 0.18, 0.20), "desc": "Jagged spikes disrupt recovery — HP regeneration is fully suppressed."},
	{"id": "darkness", "name": "Darkness Zones", "short": "Reduced vision", "col": Color(0.58, 0.42, 0.92), "desc": "Darkness closes in — vision range is drastically reduced."},
]
const STORY_CHAPTER_ROOM_ROUTE: Array[int] = [2, 1, 2, 0, 4]
const LAVA_ROOM_BG_PATH: String = "res://assets/backgrounds/bg_lava.png"
const LAVA_ROOM_TILE_BG_PATH: String = "res://assets/backgrounds/bg_lava_tile.png"
const FROZEN_ROOM_BG_PATH: String = "res://assets/backgrounds/bg_frozen.png"
const FROZEN_ROOM_TILE_BG_PATH: String = "res://assets/backgrounds/bg_frozen_tile.png"
const POISON_ROOM_BG_PATH: String = "res://assets/backgrounds/bg_poison.png"
const POISON_ROOM_TILE_BG_PATH: String = "res://assets/backgrounds/bg_poison_tile.png"
const SPIKE_ROOM_BG_PATH: String = "res://assets/backgrounds/bg_spike.png"
const SPIKE_ROOM_TILE_BG_PATH: String = "res://assets/backgrounds/bg_spike_tile.png"
const DARKNESS_ROOM_TILE_BG_PATH: String = "res://assets/backgrounds/bg_darkness_tile.png"
const DARKNESS_ROOM_BG_PATH: String = "res://assets/backgrounds/bg_darkness.png"
const PORTAL_ICON_PATH: String = "res://assets/icons/icon_portal.png"
const NEXT_LEVEL_ICON_PATH: String = "res://assets/icons/icon_next_level.png"
const OBJECTIVE_ARROW_PATH: String = "res://assets/icons/objective_arrow.png"
const HUD_LABEL_ICON_PATH: String = "res://assets/icons/icon_label.png"

# ─── Skill definitions ────────────────────────────────────────────────────────
const SKILL_DEFS: Dictionary = {
	"orb": {
		"name": "Capy Orb", "short": "Orbiting damage balls",
		"col": Color(0.98, 0.72, 0.08), "max_lvl": 5,
		"lvl": [
			{"orbs": 3, "dmg": 30.0, "note": "3 hard-hitting orbiting balls"},
			{"orbs": 3, "dmg": 44.0, "note": "+damage"},
			{"orbs": 4, "dmg": 62.0, "note": "4 balls, +damage"},
			{"orbs": 4, "dmg": 84.0, "note": "+damage"},
			{"orbs": 5, "dmg": 112.0, "note": "5 balls — MAX POWER"},
		],
	},
	"bolt": {
		"name": "Capy Bolt", "short": "Auto-targeting lightning",
		"col": Color(1.0, 0.88, 0.10), "max_lvl": 5,
		"lvl": [
			{"n": 1, "dmg": 22.0, "cd": 1.1, "spd": 680.0, "note": "Fires at nearest enemy"},
			{"n": 1, "dmg": 34.0, "cd": 1.0, "spd": 760.0, "note": "+damage, faster"},
			{"n": 2, "dmg": 44.0, "cd": 0.95, "spd": 840.0, "note": "2 bolts per shot"},
			{"n": 2, "dmg": 58.0, "cd": 0.80, "spd": 940.0, "note": "+dmg, faster fire"},
			{"n": 3, "dmg": 76.0, "cd": 0.65, "spd": 1100.0, "note": "3 bolts — MAX POWER"},
		],
	},
	"ice_orb": {
		"name": "Ice Orb", "short": "Straight-line freeze orbs",
		"col": Color(0.60, 0.90, 1.0), "max_lvl": 5,
		"lvl": [
			{"n": 1, "dmg": 36.0, "cd": 2.8, "spd": 320.0, "freeze_r": 90.0,  "slow": 0.70, "note": "Freezing orb, slows enemies"},
			{"n": 1, "dmg": 54.0, "cd": 2.6, "spd": 340.0, "freeze_r": 110.0, "slow": 0.75, "note": "+freeze radius"},
			{"n": 2, "dmg": 74.0, "cd": 2.4, "spd": 360.0, "freeze_r": 130.0, "slow": 0.80, "note": "2 orbs"},
			{"n": 2, "dmg": 98.0, "cd": 2.2, "spd": 380.0, "freeze_r": 155.0, "slow": 0.85, "note": "Bigger freeze zone"},
			{"n": 3, "dmg": 128.0, "cd": 2.0, "spd": 420.0, "freeze_r": 190.0, "slow": 0.92, "note": "3 orbs — MAX FREEZE"},
		],
	},
	"aura": {
		"name": "Mud Aura", "short": "Continuous damage aura",
		"col": Color(0.52, 0.36, 0.18), "max_lvl": 5,
		"lvl": [
			{"r": 150.0, "dps": 12.0, "note": "Damages nearby enemies"},
			{"r": 175.0, "dps": 18.0, "note": "+range & damage"},
			{"r": 200.0, "dps": 25.0, "note": "+range & damage"},
			{"r": 225.0, "dps": 34.0, "note": "+range & damage"},
			{"r": 255.0, "dps": 44.0, "note": "Strong aura — MAX POWER"},
		],
	},
	"wave": {
		"name": "Squeal Wave", "short": "Periodic shockwave",
		"col": Color(0.72, 0.46, 1.0), "max_lvl": 5,
		"lvl": [
			{"r": 380.0, "dmg":  50.0, "cd": 6.5, "note": "Periodic shockwave"},
			{"r": 420.0, "dmg":  70.0, "cd": 6.0, "note": "+range & damage"},
			{"r": 450.0, "dmg":  95.0, "cd": 5.5, "note": "+range & damage"},
			{"r": 500.0, "dmg": 124.0, "cd": 5.0, "note": "+range & damage"},
			{"r": 560.0, "dmg": 160.0, "cd": 4.0, "note": "Huge wave — MAX POWER"},
		],
	},
	"regen": {
		"name": "Capy Calm", "short": "HP regeneration",
		"col": Color(0.90, 0.32, 0.42), "max_lvl": 3,
		"lvl": [
			{"hps": 1.2, "note": "Slowly regenerate HP"},
			{"hps": 2.5, "note": "+regen rate"},
			{"hps": 4.5, "note": "Strong regen — MAX POWER"},
		],
	},
	"magnet": {
		"name": "XP Magnet", "short": "Attract XP from further away",
		"col": Color(0.28, 0.88, 0.60), "max_lvl": 3,
		"lvl": [
			{"rng": 200.0, "note": "Attract XP orbs"},
			{"rng": 340.0, "note": "+attraction range"},
			{"rng": 520.0, "note": "Huge range — MAX POWER"},
		],
	},
	# ── Wizard skills ────────────────────────────────────────────────────────
	"fireball": {
		"name": "Fireball", "short": "Orbiting fire orbs",
		"col": Color(1.0, 0.48, 0.05), "max_lvl": 5,
		"lvl": [
			{"orbs": 2, "dmg": 16.0, "note": "2 orbiting fireballs"},
			{"orbs": 2, "dmg": 26.0, "note": "+damage"},
			{"orbs": 3, "dmg": 38.0, "note": "3 fireballs"},
			{"orbs": 3, "dmg": 52.0, "note": "+damage"},
			{"orbs": 4, "dmg": 72.0, "note": "4 fireballs — INFERNO"},
		],
	},
	"elec_wave": {
		"name": "Elec Shockwave", "short": "Zapping shockwave",
		"col": Color(0.88, 0.98, 0.18), "max_lvl": 5,
		"lvl": [
			{"r": 300.0, "dmg": 55.0, "cd": 5.5, "note": "Electric pulse"},
			{"r": 350.0, "dmg": 78.0, "cd": 5.0, "note": "+range & damage"},
			{"r": 400.0, "dmg": 106.0, "cd": 4.5, "note": "+range & damage"},
			{"r": 460.0, "dmg": 140.0, "cd": 4.0, "note": "+range & damage"},
			{"r": 530.0, "dmg": 190.0, "cd": 3.2, "note": "MAX VOLTAGE"},
		],
	},
	"hurricane": {
		"name": "Hurricane", "short": "Whirling wind aura",
		"col": Color(0.58, 0.88, 0.96), "max_lvl": 5,
		"lvl": [
			{"r": 130.0, "dps": 13.0, "note": "Wind damage aura"},
			{"r": 160.0, "dps": 20.0, "note": "+range & damage"},
			{"r": 195.0, "dps": 28.0, "note": "+range & damage"},
			{"r": 230.0, "dps": 40.0, "note": "+range & damage"},
			{"r": 270.0, "dps": 56.0, "note": "Tornado — MAX POWER"},
		],
	},
	"blizzard": {
		"name": "Blizzard", "short": "Whole-screen ice storm",
		"col": Color(0.78, 0.94, 1.0), "max_lvl": 3,
		"lvl": [
			{"dmg": 620.0, "cd": 20.0, "slow": 0.92, "note": "Screen-wide ice storm"},
			{"dmg": 980.0, "cd": 18.0, "slow": 0.95, "note": "+damage, colder"},
			{"dmg": 1500.0, "cd": 15.0, "slow": 0.98, "note": "ABSOLUTE ZERO"},
		],
	},
	# ── Archer skills ─────────────────────────────────────────────────────────
	"arrow": {
		"name": "Arrow Shot", "short": "Fast piercing arrows",
		"col": Color(0.45, 0.78, 0.25), "max_lvl": 5,
		"lvl": [
			{"n": 1, "dmg": 28.0, "cd": 1.0, "spd": 820.0, "note": "Fast arrow"},
			{"n": 1, "dmg": 44.0, "cd": 0.9, "spd": 900.0, "note": "+damage"},
			{"n": 2, "dmg": 60.0, "cd": 0.85, "spd": 980.0, "note": "2 arrows"},
			{"n": 2, "dmg": 78.0, "cd": 0.75, "spd": 1060.0, "note": "+dmg, faster"},
			{"n": 3, "dmg": 104.0, "cd": 0.65, "spd": 1200.0, "note": "3 arrows — BULL'S-EYE"},
		],
	},
	"split_arrow": {
		"name": "Split Arrow", "short": "Fan of arrows",
		"col": Color(0.55, 0.86, 0.30), "max_lvl": 5,
		"lvl": [
			{"n": 3, "dmg": 20.0, "cd": 2.2, "spd": 720.0, "spread": 0.35, "note": "3-way fan"},
			{"n": 3, "dmg": 32.0, "cd": 2.0, "spd": 760.0, "spread": 0.40, "note": "+damage"},
			{"n": 5, "dmg": 44.0, "cd": 1.9, "spd": 800.0, "spread": 0.45, "note": "5-way split"},
			{"n": 5, "dmg": 60.0, "cd": 1.7, "spd": 840.0, "spread": 0.50, "note": "+damage"},
			{"n": 7, "dmg": 80.0, "cd": 1.5, "spd": 880.0, "spread": 0.55, "note": "7-way — SCATTER"},
		],
	},
	"pierce_arrow": {
		"name": "Pierce Arrow", "short": "Arrow pierces all enemies",
		"col": Color(0.28, 0.90, 0.55), "max_lvl": 5,
		"lvl": [
			{"n": 1, "dmg": 38.0, "cd": 2.5, "spd": 600.0, "note": "Pierces enemies"},
			{"n": 1, "dmg": 56.0, "cd": 2.3, "spd": 650.0, "note": "+damage"},
			{"n": 2, "dmg": 76.0, "cd": 2.1, "spd": 700.0, "note": "2 pierce arrows"},
			{"n": 2, "dmg": 100.0, "cd": 1.9, "spd": 750.0, "note": "+damage"},
			{"n": 3, "dmg": 135.0, "cd": 1.7, "spd": 800.0, "note": "3 arrows — SKEWER"},
		],
	},
	"sky_fall": {
		"name": "Sky Fall", "short": "Rain of arrows — whole screen",
		"col": Color(0.22, 0.72, 0.18), "max_lvl": 3,
		"lvl": [
			{"dmg": 480.0, "cd": 20.0, "note": "Arrow rain — whole screen"},
			{"dmg": 800.0, "cd": 18.0, "note": "+damage"},
			{"dmg": 1280.0, "cd": 15.0, "note": "STORM OF ARROWS"},
		],
	},
	# ── Assassin skills ───────────────────────────────────────────────────────
	"star_knife": {
		"name": "Star Knife", "short": "Spinning star blades",
		"col": Color(0.72, 0.70, 0.82), "max_lvl": 5,
		"lvl": [
			{"n": 1, "dmg": 26.0, "cd": 1.2, "spd": 700.0, "note": "Spinning star knife"},
			{"n": 1, "dmg": 40.0, "cd": 1.1, "spd": 780.0, "note": "+damage"},
			{"n": 2, "dmg": 56.0, "cd": 1.0, "spd": 860.0, "note": "2 star knives"},
			{"n": 2, "dmg": 72.0, "cd": 0.85, "spd": 950.0, "note": "+dmg, faster"},
			{"n": 3, "dmg": 98.0, "cd": 0.70, "spd": 1050.0, "note": "3 knives — DEADLY"},
		],
	},
	"knife_storm": {
		"name": "Knife Storm", "short": "Spinning blade aura",
		"col": Color(0.78, 0.74, 0.88), "max_lvl": 5,
		"lvl": [
			{"r": 180.0, "dps": 22.0, "note": "Close-range blade spin"},
			{"r": 210.0, "dps": 32.0, "note": "+range & damage"},
			{"r": 240.0, "dps": 44.0, "note": "+range & damage"},
			{"r": 270.0, "dps": 58.0, "note": "+range & damage"},
			{"r": 305.0, "dps": 80.0, "note": "Blade frenzy — MAX"},
		],
	},
	"boomerang": {
		"name": "Boomerang Star", "short": "Returns to player, hits twice",
		"col": Color(0.92, 0.84, 0.28), "max_lvl": 5,
		"lvl": [
			{"n": 1, "dmg": 30.0, "cd": 3.0, "spd": 500.0, "note": "Returns to you"},
			{"n": 1, "dmg": 48.0, "cd": 2.8, "spd": 540.0, "note": "+damage"},
			{"n": 2, "dmg": 66.0, "cd": 2.6, "spd": 580.0, "note": "2 boomerangs"},
			{"n": 2, "dmg": 88.0, "cd": 2.3, "spd": 620.0, "note": "+damage"},
			{"n": 3, "dmg": 118.0, "cd": 2.0, "spd": 680.0, "note": "3 boomerangs — MAX"},
		],
	},
	"seven_slash": {
		"name": "7 Slash", "short": "Whole-screen blade storm",
		"col": Color(0.82, 0.24, 0.36), "max_lvl": 3,
		"lvl": [
			{"dmg": 560.0, "cd": 20.0, "note": "7 screen-wide slashes"},
			{"dmg": 950.0, "cd": 18.0, "note": "+damage"},
			{"dmg": 1500.0, "cd": 15.0, "note": "DEATH SENTENCE"},
		],
	},
	# ── Brown Capy ultimate ───────────────────────────────────────────────────
	"swirl_tangerine": {
		"name": "Swirl Tangerine", "short": "Tangerine energy cyclone — whole screen",
		"col": Color(1.0, 0.55, 0.05), "max_lvl": 3,
		"lvl": [
			{"dmg": 180.0, "cd": 20.0, "note": "Tangerine cyclone wipes the screen"},
			{"dmg": 300.0, "cd": 18.0, "note": "+damage, wider vortex"},
			{"dmg": 460.0, "cd": 15.0, "note": "ULTIMATE TANGERINE STORM"},
		],
	},
	# ── Wizard extra skills ──────────────────────────────────────────────────
	"arcane_missile": {
		"name": "Arcane Missile", "short": "Rapid arcane bolts",
		"col": Color(0.72, 0.42, 1.0), "max_lvl": 5,
		"lvl": [
			{"n": 2, "dmg": 24.0, "cd": 0.75, "spd": 290.0, "note": "Slow homing arcane missiles"},
			{"n": 2, "dmg": 36.0, "cd": 0.65, "spd": 310.0, "note": "+damage"},
			{"n": 3, "dmg": 50.0, "cd": 0.60, "spd": 330.0, "note": "3 homing missiles"},
			{"n": 3, "dmg": 66.0, "cd": 0.50, "spd": 350.0, "note": "+damage"},
			{"n": 4, "dmg": 88.0, "cd": 0.42, "spd": 380.0, "note": "4 missiles — ARCANE STORM"},
		],
	},
	"mana_nova": {
		"name": "Mana Burst", "short": "Blue ring pushes enemies outward — no damage",
		"col": Color(0.28, 0.55, 1.0), "max_lvl": 5,
		"lvl": [
			{"r": 260.0, "dmg": 0.0, "cd": 6.0, "note": "Push ring — no damage"},
			{"r": 320.0, "dmg": 0.0, "cd": 5.5, "note": "Wider push"},
			{"r": 380.0, "dmg": 0.0, "cd": 5.0, "note": "Stronger push"},
			{"r": 450.0, "dmg": 0.0, "cd": 4.5, "note": "+range"},
			{"r": 520.0, "dmg": 0.0, "cd": 3.8, "note": "TITAN PUSH"},
		],
	},
	"time_warp": {
		"name": "Time Warp", "short": "Slow zone with tiny clocks — no damage",
		"col": Color(0.55, 0.72, 1.0), "max_lvl": 3,
		"lvl": [
			{"r": 180.0, "slow": 0.35, "cd": 22.0, "life": 8.0, "note": "Slow zone — no damage"},
			{"r": 240.0, "slow": 0.50, "cd": 19.0, "life": 11.0, "note": "Wider, stronger slow"},
			{"r": 310.0, "slow": 0.65, "cd": 16.0, "life": 14.0, "note": "TIME SLOW ZONE"},
		],
	},
	"crystal_prism": {
		"name": "Crystal Prism", "short": "Create prism triangle lasers",
		"col": Color(0.72, 0.96, 1.0), "max_lvl": 5,
		"lvl": [
			{"r": 180.0, "dmg": 40.0, "cd": 6.2, "life": 6.0, "note": "Small laser prism"},
			{"r": 210.0, "dmg": 58.0, "cd": 5.6, "life": 6.8, "note": "+size & damage"},
			{"r": 240.0, "dmg": 78.0, "cd": 5.1, "life": 7.6, "note": "+size & damage"},
			{"r": 270.0, "dmg": 102.0, "cd": 4.6, "life": 8.4, "note": "+size & damage"},
			{"r": 305.0, "dmg": 132.0, "cd": 4.1, "life": 9.2, "note": "PRISMATIC KILL ZONE"},
		],
	},
	"arc_lightning": {
		"name": "Arc Lightning", "short": "Zap one enemy then chain nearby",
		"col": Color(0.96, 1.0, 0.30), "max_lvl": 5,
		"lvl": [
			{"r": 220.0, "dmg": 72.0, "cd": 4.8, "chains": 2, "chain_r": 180.0, "note": "Target zap + short chain"},
			{"r": 250.0, "dmg": 96.0, "cd": 4.3, "chains": 3, "chain_r": 200.0, "note": "+damage & extra chain"},
			{"r": 280.0, "dmg": 124.0, "cd": 3.9, "chains": 4, "chain_r": 220.0, "note": "+range & chain"},
			{"r": 315.0, "dmg": 158.0, "cd": 3.4, "chains": 5, "chain_r": 240.0, "note": "+damage & chain"},
			{"r": 350.0, "dmg": 196.0, "cd": 2.9, "chains": 6, "chain_r": 270.0, "note": "MAX VOLTAGE CHAIN"},
		],
	},
	# ── Archer extra skills ───────────────────────────────────────────────────
	"ricochet_arrow": {
		"name": "Ricochet", "short": "Bouncing bomb arrows",
		"col": Color(0.88, 0.72, 0.24), "max_lvl": 5,
		"lvl": [
			{"n": 1, "dmg": 32.0, "cd": 1.4, "spd": 900.0, "ricochet_pct": 0.25, "bounces": 1, "note": "Bounces once at 25% damage"},
			{"n": 1, "dmg": 48.0, "cd": 1.2, "spd": 970.0, "ricochet_pct": 0.30, "bounces": 1, "note": "Higher ricochet damage"},
			{"n": 2, "dmg": 64.0, "cd": 1.1, "spd": 1040.0, "ricochet_pct": 0.36, "bounces": 1, "note": "2 arrows"},
			{"n": 2, "dmg": 84.0, "cd": 0.95, "spd": 1110.0, "ricochet_pct": 0.43, "bounces": 2, "note": "Can bounce twice"},
			{"n": 3, "dmg": 110.0, "cd": 0.80, "spd": 1200.0, "ricochet_pct": 0.50, "bounces": 2, "note": "Max ricochet: 50% x 2 bounces"},
		],
	},
	"hawk_companion": {
		"name": "Hawk Companion", "short": "Summon hawk for 10s then cooldown",
		"col": Color(0.82, 0.52, 0.12), "max_lvl": 5,
		"lvl": [
			{"r": 320.0, "dmg": 24.0, "cd": 20.0, "life": 10.0, "shots": 1, "note": "Hawk fires nearby feather"},
			{"r": 370.0, "dmg": 34.0, "cd": 19.0, "life": 10.0, "shots": 1, "note": "+range & damage"},
			{"r": 420.0, "dmg": 46.0, "cd": 18.0, "life": 10.0, "shots": 1, "note": "+range & damage"},
			{"r": 480.0, "dmg": 62.0, "cd": 17.0, "life": 10.0, "shots": 1, "note": "+range & damage"},
			{"r": 540.0, "dmg": 80.0, "cd": 16.0, "life": 10.0, "shots": 2, "note": "Twin feathers at max"},
		],
	},
	"trap_arrow": {
		"name": "Trap Arrow", "short": "Ground thorn-vine line traps enemies",
		"col": Color(0.60, 0.90, 0.20), "max_lvl": 3,
		"lvl": [
			{"dmg": 42.0, "cd": 15.0, "life": 7.0, "hold": 3.0, "max_targets": 1, "len": 160.0, "note": "Single-root vine trap"},
			{"dmg": 64.0, "cd": 13.5, "life": 8.0, "hold": 4.0, "max_targets": 2, "len": 190.0, "note": "Longer hold and 2 targets"},
			{"dmg": 88.0, "cd": 12.0, "life": 9.0, "hold": 5.0, "max_targets": 3, "len": 230.0, "note": "3 targets, 5s root"},
		],
	},
	"poison_arrow": {
		"name": "Poison Arrow", "short": "Venom-tipped arrows",
		"col": Color(0.38, 0.86, 0.18), "max_lvl": 5,
		"lvl": [
			{"n": 1, "dmg": 22.0, "cd": 1.3, "spd": 780.0, "poison_dps": 8.0, "poison_t": 3.0, "note": "Poisons on hit"},
			{"n": 1, "dmg": 34.0, "cd": 1.15, "spd": 850.0, "poison_dps": 12.0, "poison_t": 3.2, "note": "+poison damage"},
			{"n": 2, "dmg": 46.0, "cd": 1.05, "spd": 920.0, "poison_dps": 16.0, "poison_t": 3.4, "note": "2 poison arrows"},
			{"n": 2, "dmg": 62.0, "cd": 0.90, "spd": 990.0, "poison_dps": 21.0, "poison_t": 3.6, "note": "Stronger poison"},
			{"n": 3, "dmg": 82.0, "cd": 0.75, "spd": 1080.0, "poison_dps": 28.0, "poison_t": 4.0, "note": "Max poison burst"},
		],
	},
	"phantom_hunt": {
		"name": "Phantom Hunt", "short": "Straight phantom arrows",
		"col": Color(0.42, 0.92, 0.78), "max_lvl": 5,
		"lvl": [
			{"n": 1, "dmg": 84.0, "cd": 8.0, "spd": 980.0, "spawn_n": 3, "spawn_pct": 0.12, "note": "One phantom arrow; kill splits into 3 homing arrows"},
			{"n": 1, "dmg": 112.0, "cd": 7.2, "spd": 1040.0, "spawn_n": 3, "spawn_pct": 0.14, "note": "Higher damage and faster cooldown"},
			{"n": 1, "dmg": 146.0, "cd": 6.4, "spd": 1100.0, "spawn_n": 3, "spawn_pct": 0.16, "note": "Stronger split damage"},
			{"n": 1, "dmg": 184.0, "cd": 5.6, "spd": 1160.0, "spawn_n": 3, "spawn_pct": 0.18, "note": "Faster cycle, harder split hits"},
			{"n": 1, "dmg": 228.0, "cd": 4.8, "spd": 1220.0, "spawn_n": 3, "spawn_pct": 0.20, "note": "MAX phantom burst"},
		],
	},
	"venom_plague": {
		"name": "Venom Plague", "short": "Venom arrows leave toxic pools",
		"col": Color(0.28, 0.92, 0.32), "max_lvl": 5,
		"lvl": [
			{"n": 1, "dmg": 24.0, "cd": 1.25, "spd": 760.0, "pool_r": 52.0, "pool_dps": 12.0, "note": "Leaves venom pool (2s)"},
			{"n": 1, "dmg": 36.0, "cd": 1.10, "spd": 830.0, "pool_r": 56.0, "pool_dps": 16.0, "note": "Stronger pool damage"},
			{"n": 2, "dmg": 50.0, "cd": 0.96, "spd": 900.0, "pool_r": 60.0, "pool_dps": 21.0, "note": "2 venom arrows"},
			{"n": 2, "dmg": 66.0, "cd": 0.84, "spd": 980.0, "pool_r": 64.0, "pool_dps": 27.0, "note": "Bigger and stronger pools"},
			{"n": 3, "dmg": 86.0, "cd": 0.72, "spd": 1060.0, "pool_r": 70.0, "pool_dps": 34.0, "note": "MAX venom spread"},
		],
	},
	# ── Assassin extra skills ─────────────────────────────────────────────────
	"shadow_dagger": {
		"name": "Shadow Dagger", "short": "Lightning-fast shadow blades",
		"col": Color(0.36, 0.24, 0.58), "max_lvl": 5,
		"lvl": [
			{"n": 2, "dmg": 20.0, "cd": 0.70, "spd": 900.0, "note": "Rapid shadow blades"},
			{"n": 2, "dmg": 30.0, "cd": 0.60, "spd": 980.0, "note": "+damage"},
			{"n": 3, "dmg": 42.0, "cd": 0.55, "spd": 1060.0, "note": "3 daggers"},
			{"n": 3, "dmg": 56.0, "cd": 0.45, "spd": 1140.0, "note": "+damage, faster"},
			{"n": 4, "dmg": 74.0, "cd": 0.36, "spd": 1220.0, "note": "4 daggers — SHADOW FURY"},
		],
	},
	"blink_strike": {
		"name": "Blink Strike", "short": "Instant dash through enemies + 0.5s invincibility",
		"col": Color(0.50, 0.18, 0.82), "max_lvl": 5,
		"lvl": [
			{"r": 260.0, "dmg": 58.0, "cd": 5.0, "note": "Blink in move dir, hurt enemies along path"},
			{"r": 310.0, "dmg": 80.0, "cd": 4.5, "note": "+range & damage"},
			{"r": 360.0, "dmg": 108.0, "cd": 4.0, "note": "+range & damage"},
			{"r": 420.0, "dmg": 140.0, "cd": 3.5, "note": "+range & damage"},
			{"r": 480.0, "dmg": 180.0, "cd": 3.0, "note": "SHADOW BLINK — MAX"},
		],
	},
	"smoke_bomb": {
		"name": "Smoke Bomb", "short": "Scattered smoke clouds damage enemies walking through",
		"col": Color(0.62, 0.58, 0.68), "max_lvl": 3,
		"lvl": [
			{"n": 5, "dmg": 22.0, "cd": 18.0, "note": "5 smoke clouds scatter on screen"},
			{"n": 7, "dmg": 36.0, "cd": 15.0, "note": "7 clouds, stronger damage"},
			{"n": 9, "dmg": 55.0, "cd": 12.0, "note": "BLACKOUT SMOKE — 9 clouds"},
		],
	},
	"shadow_clone": {
		"name": "Shadow Clone", "short": "Clone attacks nearby enemies",
		"col": Color(0.44, 0.30, 0.68), "max_lvl": 5,
		"lvl": [
			{"r": 155.0, "dps": 18.0, "note": "Clone strikes nearby enemies"},
			{"r": 182.0, "dps": 26.0, "note": "+range & damage"},
			{"r": 210.0, "dps": 36.0, "note": "+range & damage"},
			{"r": 242.0, "dps": 50.0, "note": "+range & damage"},
			{"r": 278.0, "dps": 68.0, "note": "SHADOW ARMY — MAX POWER"},
		],
	},
	"bleed_mark": {
		"name": "Bleed Mark", "short": "Marked enemies take bonus skill damage",
		"col": Color(0.88, 0.14, 0.26), "max_lvl": 5,
		"lvl": [
			{"n": 1, "dmg": 28.0, "cd": 1.1, "spd": 840.0, "mark_t": 6.0, "bonus": 0.25, "explode_r": 150.0, "note": "Marked target takes +25% damage"},
			{"n": 1, "dmg": 42.0, "cd": 1.0, "spd": 920.0, "mark_t": 6.5, "bonus": 0.3125, "explode_r": 165.0, "note": "Damage amp grows"},
			{"n": 2, "dmg": 58.0, "cd": 0.90, "spd": 1000.0, "mark_t": 7.0, "bonus": 0.375, "explode_r": 180.0, "note": "2 bleed bolts"},
			{"n": 2, "dmg": 76.0, "cd": 0.78, "spd": 1080.0, "mark_t": 7.5, "bonus": 0.4375, "explode_r": 200.0, "note": "More damage amplification"},
			{"n": 3, "dmg": 100.0, "cd": 0.65, "spd": 1160.0, "mark_t": 8.0, "bonus": 0.50, "explode_r": 225.0, "note": "MAX mark: +50% damage"},
		],
	},
	"thousand_blades": {
		"name": "Thousand Blades", "short": "Blades fly out one by one in all directions",
		"col": Color(0.80, 0.20, 0.30), "max_lvl": 3,
		"lvl": [
			{"n": 14, "dmg": 55.0, "cd": 8.5, "spd": 520.0, "note": "Blades fan out one by one"},
			{"n": 18, "dmg": 75.0, "cd": 7.5, "spd": 580.0, "note": "+damage, more blades"},
			{"n": 22, "dmg": 100.0, "cd": 6.5, "spd": 640.0, "note": "DEATH BY A THOUSAND CUTS"},
		],
	},
	# ── Swamp skills ──────────────────────────────────────────────────────────
	"toxic_mushroom": {
		"name": "Toxic Mushroom", "short": "Spawn mushroom that emits green fog",
		"col": Color(0.58, 0.78, 0.22), "max_lvl": 5,
		"lvl": [
			{"dps": 16.0, "cd": 8.0, "life": 4.0, "fog_r": 120.0, "note": "Fog pulse every 2s"},
			{"dps": 22.0, "cd": 10.0, "life": 5.0, "fog_r": 130.0, "note": "Longer life, stronger fog"},
			{"dps": 29.0, "cd": 12.0, "life": 6.0, "fog_r": 140.0, "note": "Longer life"},
			{"dps": 37.0, "cd": 14.0, "life": 7.0, "fog_r": 150.0, "note": "Heavy spores"},
			{"dps": 46.0, "cd": 16.0, "life": 8.0, "fog_r": 165.0, "note": "MAX toxic bloom"},
		],
	},
	"bog_trap": {
		"name": "Bog Trap", "short": "Muddy swamp pool that slows enemies",
		"col": Color(0.42, 0.62, 0.14), "max_lvl": 5,
		"lvl": [
			{"r": 160.0, "slow": 0.20, "dps": 10.0, "cd": 7.5, "life": 3.2, "note": "Mud pool slows and deals 10 DPS"},
			{"r": 190.0, "slow": 0.30, "dps": 15.0, "cd": 7.0, "life": 3.6, "note": "Larger pool, 15 DPS"},
			{"r": 225.0, "slow": 0.40, "dps": 21.0, "cd": 6.5, "life": 4.0, "note": "Deeper swamp, 21 DPS"},
			{"r": 265.0, "slow": 0.52, "dps": 28.0, "cd": 6.0, "life": 4.4, "note": "Heavy slow, 28 DPS"},
			{"r": 310.0, "slow": 0.65, "dps": 36.0, "cd": 5.5, "life": 5.0, "note": "MAX bog: 36 DPS"},
		],
	},
	"leech_vine": {
		"name": "Leech Vine", "short": "Worms latch and drain once",
		"col": Color(0.28, 0.68, 0.18), "max_lvl": 5,
		"lvl": [
			{"n": 2, "dmg": 46.0, "cd": 2.1, "spd": 620.0, "steal": 0.01, "note": "Heal 1% of damage dealt"},
			{"n": 2, "dmg": 62.0, "cd": 1.95, "spd": 700.0, "steal": 0.02, "note": "Heal 2%"},
			{"n": 3, "dmg": 80.0, "cd": 1.80, "spd": 780.0, "steal": 0.03, "note": "Heal 3%"},
			{"n": 3, "dmg": 102.0, "cd": 1.65, "spd": 860.0, "steal": 0.04, "note": "Heal 4%"},
			{"n": 4, "dmg": 128.0, "cd": 1.50, "spd": 940.0, "steal": 0.05, "note": "Heal 5%"},
		],
	},
	"plague_beetles": {
		"name": "Plague Beetles", "short": "Attach swarm to one enemy",
		"col": Color(0.36, 0.56, 0.08), "max_lvl": 5,
		"lvl": [
			{"dps": 18.0, "cd": 4.6, "dur": 3.0, "note": "Attach 3s"},
			{"dps": 26.0, "cd": 4.3, "dur": 3.0, "note": "+damage"},
			{"dps": 35.0, "cd": 4.0, "dur": 3.0, "note": "+damage"},
			{"dps": 46.0, "cd": 3.7, "dur": 3.0, "note": "+damage"},
			{"dps": 58.0, "cd": 3.4, "dur": 3.0, "note": "MAX swarm damage"},
		],
	},
	"corruption_field": {
		"name": "Corruption Field", "short": "Mud patches trap and sink enemies",
		"col": Color(0.50, 0.82, 0.20), "max_lvl": 5,
		"lvl": [
			{"n": 2, "r": 92.0, "dps": 16.0, "cd": 8.0, "sink_t": 3.0, "max_targets": 2, "note": "Large patch, traps up to 2 enemies"},
			{"n": 2, "r": 104.0, "dps": 22.0, "cd": 7.5, "sink_t": 3.0, "max_targets": 2, "note": "Bigger patch"},
			{"n": 3, "r": 116.0, "dps": 29.0, "cd": 7.0, "sink_t": 3.0, "max_targets": 2, "note": "3 trap patches"},
			{"n": 3, "r": 126.0, "dps": 38.0, "cd": 6.5, "sink_t": 3.0, "max_targets": 2, "note": "Stronger sink"},
			{"n": 4, "r": 136.0, "dps": 48.0, "cd": 6.0, "sink_t": 3.0, "max_targets": 2, "note": "MAX sinking field"},
		],
	},
	# ── Chef skills ───────────────────────────────────────────────────────────
	"flying_pan": {
		"name": "Flying Pan", "short": "Spinning pan knocks back enemies",
		"col": Color(0.78, 0.68, 0.50), "max_lvl": 5,
		"lvl": [
			{"n": 1, "dmg": 34.0, "cd": 1.3, "spd": 580.0, "note": "Spin the pan"},
			{"n": 1, "dmg": 52.0, "cd": 1.1, "spd": 630.0, "note": "+damage"},
			{"n": 2, "dmg": 70.0, "cd": 1.0, "spd": 680.0, "note": "2 pans"},
			{"n": 2, "dmg": 92.0, "cd": 0.85, "spd": 730.0, "note": "+damage"},
			{"n": 3, "dmg": 120.0, "cd": 0.72, "spd": 780.0, "note": "3 pans — KITCHEN FURY"},
		],
	},
	"soup_splash": {
		"name": "Soup Splash", "short": "Front cone blast",
		"col": Color(0.92, 0.72, 0.28), "max_lvl": 5,
		"lvl": [
			{"r": 380.0, "dmg": 52.0, "cd": 5.8, "angle_deg": 15.0, "note": "Narrow cone"},
			{"r": 430.0, "dmg": 66.0, "cd": 5.3, "angle_deg": 35.0, "note": "Wider cone"},
			{"r": 480.0, "dmg": 82.0, "cd": 4.8, "angle_deg": 55.0, "note": "Medium cone"},
			{"r": 540.0, "dmg": 100.0, "cd": 4.3, "angle_deg": 75.0, "note": "Wide cone"},
			{"r": 600.0, "dmg": 122.0, "cd": 3.8, "angle_deg": 90.0, "note": "MAX 90 deg cone"},
		],
	},
	"chili_explosion": {
		"name": "Chili Explosion", "short": "Chili shots create ember ground",
		"col": Color(0.98, 0.28, 0.08), "max_lvl": 5,
		"lvl": [
			{"n": 1, "dmg": 86.0, "cd": 20.0, "spd": 820.0, "ember_n": 3, "ember_dps": 10.0, "note": "1 chili"},
			{"n": 1, "dmg": 108.0, "cd": 18.0, "spd": 880.0, "ember_n": 4, "ember_dps": 13.0, "note": "More embers"},
			{"n": 2, "dmg": 132.0, "cd": 16.5, "spd": 940.0, "ember_n": 5, "ember_dps": 16.0, "note": "2 chilies"},
			{"n": 2, "dmg": 160.0, "cd": 15.5, "spd": 1000.0, "ember_n": 6, "ember_dps": 20.0, "note": "Denser embers"},
			{"n": 3, "dmg": 194.0, "cd": 14.5, "spd": 1060.0, "ember_n": 8, "ember_dps": 25.0, "note": "3 chilies max"},
		],
	},
	"healing_feast": {
		"name": "Healing Feast", "short": "Hearty food restores HP",
		"col": Color(0.98, 0.88, 0.60), "max_lvl": 3,
		"lvl": [
			{"hps": 2.0, "note": "A hearty meal slowly heals you"},
			{"hps": 3.8, "note": "+healing power"},
			{"hps": 6.5, "note": "BANQUET — MAX HEALING"},
		],
	},
	"meatball_barrage": {
		"name": "Meatball Barrage", "short": "Meatball shield reflection",
		"col": Color(0.88, 0.54, 0.22), "max_lvl": 5,
		"lvl": [
			{"reflect": 0.05, "note": "5% contact reflection"},
			{"reflect": 0.10, "note": "10% contact reflection"},
			{"reflect": 0.15, "note": "15% contact reflection"},
			{"reflect": 0.20, "note": "20% contact reflection"},
			{"reflect": 0.25, "note": "25% contact reflection"},
		],
	},
	"master_kitchen": {
		"name": "Master Kitchen", "short": "Utensil burst around player",
		"col": Color(1.0, 0.68, 0.22), "max_lvl": 5,
		"lvl": [
			{"r": 230.0, "dmg": 62.0, "cd": 7.6, "n": 6, "note": "Short utensil burst"},
			{"r": 275.0, "dmg": 82.0, "cd": 7.0, "n": 7, "note": "Larger burst"},
			{"r": 325.0, "dmg": 108.0, "cd": 6.5, "n": 8, "note": "More utensils"},
			{"r": 378.0, "dmg": 138.0, "cd": 6.0, "n": 9, "note": "Wider and stronger"},
			{"r": 435.0, "dmg": 172.0, "cd": 5.4, "n": 11, "note": "MAX kitchen storm"},
		],
	},
	# ── Brown Capy extra skills ───────────────────────────────────────────────
	"belly_bounce": {
		"name": "Belly Bounce", "short": "Belly slap shockwave",
		"col": Color(0.88, 0.70, 0.44), "max_lvl": 5,
		"lvl": [
			{"r": 230.0, "dmg": 48.0, "cd": 5.5, "note": "Belly shockwave hits all around"},
			{"r": 270.0, "dmg": 68.0, "cd": 5.0, "note": "+range & damage"},
			{"r": 310.0, "dmg": 92.0, "cd": 4.5, "note": "+range & damage"},
			{"r": 355.0, "dmg": 120.0, "cd": 4.0, "note": "+range & damage"},
			{"r": 405.0, "dmg": 154.0, "cd": 3.5, "note": "BELLY TSUNAMI — MAX POWER"},
		],
	},
	"friendly_aura": {
		"name": "Friendly Aura", "short": "Damages nearby enemies with a friendly aura",
		"col": Color(1.0, 0.82, 0.50), "max_lvl": 5,
		"lvl": [
			{"r": 145.0, "dps": 12.0, "note": "Deals periodic damage to enemies inside the aura"},
			{"r": 175.0, "dps": 18.0, "note": "+range and damage"},
			{"r": 206.0, "dps": 25.0, "note": "+range and damage"},
			{"r": 238.0, "dps": 34.0, "note": "+range and damage"},
			{"r": 274.0, "dps": 46.0, "note": "Maximum aura damage and range"},
		],
	},
	"lucky_clover": {
		"name": "Lucky Clover", "short": "Four-leaf luck: more XP range and healing",
		"col": Color(0.40, 0.96, 0.44), "max_lvl": 3,
		"lvl": [
			{"hps": 1.5, "rng": 180.0, "note": "Lucky! More XP range and healing"},
			{"hps": 2.8, "rng": 280.0, "note": "+luck"},
			{"hps": 4.5, "rng": 420.0, "note": "FOUR-LEAF FORTUNE — MAX"},
		],
	},
	"capy_charge": {
		"name": "Capy Charge", "short": "Charge smashes everything",
		"col": Color(0.82, 0.60, 0.28), "max_lvl": 3,
		"lvl": [
			{"dmg": 180.0, "cd": 8.5, "note": "Charge smashes through everything"},
			{"dmg": 260.0, "cd": 7.5, "note": "+damage, faster charge"},
			{"dmg": 360.0, "cd": 6.5, "note": "STAMPEDE CHARGE"},
		],
	},
	"stampede": {
		"name": "Stampede", "short": "Herd of capybaras tramples screen",
		"col": Color(0.72, 0.50, 0.18), "max_lvl": 3,
		"lvl": [
			{"dmg": 240.0, "cd": 8.5, "note": "The whole herd charges"},
			{"dmg": 340.0, "cd": 7.5, "note": "+damage, bigger herd"},
			{"dmg": 470.0, "cd": 6.5, "note": "INFINITE STAMPEDE"},
		],
	},
	# ── Combo skills ───────────────────────────────────────────────────────────
	"inferno_thunder": {
		"name": "Inferno Thunder", "short": "Plasma balls with chain lightning and EMP",
		"col": Color(0.98, 0.86, 0.26), "max_lvl": 5,
		"lvl": [
			{"n": 2, "dmg": 128.0, "cd": 8.0, "spd": 500.0, "chain_dmg": 64.0, "chains": 2, "emp_r": 95.0, "emp_dmg": 32.0, "note": "Plasma balls chain lightning and EMP"},
			{"n": 2, "dmg": 238.0, "cd": 7.5, "spd": 560.0, "chain_dmg": 119.0, "chains": 2, "emp_r": 110.0, "emp_dmg": 59.0, "note": "+damage and faster cycle"},
			{"n": 3, "dmg": 350.0, "cd": 7.0, "spd": 620.0, "chain_dmg": 175.0, "chains": 3, "emp_r": 122.0, "emp_dmg": 87.0, "note": "3 plasma balls, stronger chains"},
			{"n": 3, "dmg": 462.0, "cd": 6.4, "spd": 700.0, "chain_dmg": 231.0, "chains": 3, "emp_r": 136.0, "emp_dmg": 116.0, "note": "Heavy EMP bursts"},
			{"n": 4, "dmg": 578.0, "cd": 5.8, "spd": 780.0, "chain_dmg": 289.0, "chains": 4, "emp_r": 152.0, "emp_dmg": 145.0, "note": "MAX: storm of plasma and lightning"},
		],
	},
	"frozen_lance": {
		"name": "Frozen Lance", "short": "Piercing crystal spear with freeze explosion",
		"col": Color(0.65, 0.96, 1.0), "max_lvl": 5,
		"lvl": [
			{"n": 1, "dmg": 58.0, "cd": 2.2, "spd": 660.0, "freeze_r": 82.0, "slow": 0.82, "explode_r": 120.0, "explode_dmg": 38.0, "note": "Pierce and freeze, explodes at end"},
			{"n": 1, "dmg": 76.0, "cd": 2.0, "spd": 700.0, "freeze_r": 98.0, "slow": 0.86, "explode_r": 136.0, "explode_dmg": 52.0, "note": "+damage and larger freeze"},
			{"n": 2, "dmg": 96.0, "cd": 1.8, "spd": 760.0, "freeze_r": 114.0, "slow": 0.90, "explode_r": 152.0, "explode_dmg": 68.0, "note": "2 lances"},
			{"n": 2, "dmg": 122.0, "cd": 1.65, "spd": 820.0, "freeze_r": 130.0, "slow": 0.93, "explode_r": 170.0, "explode_dmg": 88.0, "note": "Bigger crystal detonations"},
			{"n": 3, "dmg": 156.0, "cd": 1.45, "spd": 900.0, "freeze_r": 150.0, "slow": 0.96, "explode_r": 192.0, "explode_dmg": 114.0, "note": "MAX: frozen spear barrage"},
		],
	},
	"divine_volley": {
		"name": "Divine Volley", "short": "Splitting holy arrows that keep piercing",
		"col": Color(0.62, 0.95, 0.44), "max_lvl": 5,
		"lvl": [
			{"n": 1, "dmg": 24.0, "cd": 1.0, "spd": 920.0, "splits": 2, "pierce": 2, "note": "Arrow splits twice into holy volley"},
			{"n": 1, "dmg": 34.0, "cd": 0.92, "spd": 980.0, "splits": 2, "pierce": 2, "note": "+damage and speed"},
			{"n": 2, "dmg": 44.0, "cd": 0.84, "spd": 1040.0, "splits": 2, "pierce": 2, "note": "2 divine arrows per shot"},
			{"n": 2, "dmg": 56.0, "cd": 0.76, "spd": 1100.0, "splits": 2, "pierce": 3, "note": "More piercing and faster cadence"},
			{"n": 3, "dmg": 72.0, "cd": 0.68, "spd": 1180.0, "splits": 2, "pierce": 3, "note": "MAX: relentless split barrage"},
		],
	},
	"thunder_god_pulse": {
		"name": "Thunder God Pulse", "short": "Shockwave marks enemies then chains lightning",
		"col": Color(0.94, 0.94, 0.35), "max_lvl": 5,
		"lvl": [
			{"r": 360.0, "dmg": 40.0, "cd": 8.5, "mark_t": 2.0, "chains": 3, "chain_dmg": 14.0, "note": "Pulse marks enemies and chains"},
			{"r": 390.0, "dmg": 54.0, "cd": 8.0, "mark_t": 2.2, "chains": 4, "chain_dmg": 20.0, "note": "+range and chain damage"},
			{"r": 420.0, "dmg": 70.0, "cd": 7.5, "mark_t": 2.4, "chains": 5, "chain_dmg": 26.0, "note": "Wider ring with more jumps"},
			{"r": 460.0, "dmg": 88.0, "cd": 6.8, "mark_t": 2.6, "chains": 6, "chain_dmg": 34.0, "note": "Massive chain storms"},
			{"r": 500.0, "dmg": 110.0, "cd": 6.0, "mark_t": 2.8, "chains": 7, "chain_dmg": 44.0, "note": "MAX: godlike lightning network"},
		],
	},
	"toxic_lightning": {
		"name": "Toxic Lightning", "short": "Poison field plus electric poison spread",
		"col": Color(0.66, 0.92, 0.34), "max_lvl": 5,
		"lvl": [
			{"r": 160.0, "dps": 7.0, "poison_dps": 10.0, "cd": 8.5, "pulse_r": 310.0, "pulse_dmg": 40.0, "spread_r": 100.0, "note": "Poisoned enemies spread toxin when shocked"},
			{"r": 180.0, "dps": 10.0, "poison_dps": 15.0, "cd": 8.0, "pulse_r": 350.0, "pulse_dmg": 54.0, "spread_r": 118.0, "note": "Wider aura and stronger pulse"},
			{"r": 205.0, "dps": 14.0, "poison_dps": 21.0, "cd": 7.4, "pulse_r": 392.0, "pulse_dmg": 70.0, "spread_r": 136.0, "note": "Dense toxic storms"},
			{"r": 230.0, "dps": 18.0, "poison_dps": 28.0, "cd": 6.8, "pulse_r": 436.0, "pulse_dmg": 88.0, "spread_r": 156.0, "note": "Rapid poison propagation"},
			{"r": 258.0, "dps": 23.0, "poison_dps": 36.0, "cd": 6.0, "pulse_r": 482.0, "pulse_dmg": 108.0, "spread_r": 176.0, "note": "MAX: toxic thunderstorm"},
		],
	},
}

const SKILL_EVOLUTIONS: Dictionary = {
	"ice_orb": [
		{"id": "glacier_core", "name": "Glacier Core", "note": "Huge ice orbs: +65% damage and +45% freeze radius", "color": Color(0.42, 0.86, 1.0), "mods": {"dmg_mul": 1.65, "freeze_r_mul": 1.45}},
		{"id": "frost_moons", "name": "Frost Moons", "note": "+2 ice orbs and 25% faster projectiles", "color": Color(0.72, 0.94, 1.0), "mods": {"n_add": 2, "spd_mul": 1.25}},
	],
	"bolt": [
		{"id": "thunder_spear", "name": "Thunder Spear", "note": "+80% bolt damage and larger thunder strikes", "color": Color(1.0, 0.86, 0.12), "mods": {"dmg_mul": 1.80}},
		{"id": "storm_swarm", "name": "Storm Swarm", "note": "+2 bolts with 20% faster recharge", "color": Color(0.72, 0.86, 1.0), "mods": {"n_add": 2, "cd_mul": 0.80}},
	],
	"arrow": [
		{"id": "dragon_arrow", "name": "Dragon Arrow", "note": "+90% arrow damage and +30% projectile speed", "color": Color(1.0, 0.48, 0.16), "mods": {"dmg_mul": 1.90, "spd_mul": 1.30}},
		{"id": "endless_quiver", "name": "Endless Quiver", "note": "+3 arrows with 18% faster recharge", "color": Color(0.46, 1.0, 0.58), "mods": {"n_add": 3, "cd_mul": 0.82}},
	],
	"bog_trap": [
		{"id": "acid_bog", "name": "Acid Bog", "note": "+80% mud damage; poison ignites into Combustion", "color": Color(0.58, 1.0, 0.16), "mods": {"dps_mul": 1.80}},
		{"id": "bottomless_mire", "name": "Bottomless Mire", "note": "+45% pool radius, +40% duration and stronger slow", "color": Color(0.58, 0.38, 0.16), "mods": {"r_mul": 1.45, "life_mul": 1.40, "slow_add": 0.15}},
	],
}

const COMBO_RECIPES: Dictionary = {
	# Combo recipes must stay inside a single character's skill pool.
	# Archer
	"divine_volley":    {"needs": ["arrow", "split_arrow"]},
	# Wizard
	"inferno_thunder":  {"needs": ["fireball", "elec_wave"]},
	# Assassin
	"thousand_blades":  {"needs": ["star_knife", "knife_storm"]},
	# Swamp
	"corruption_field": {"needs": ["leech_vine", "plague_beetles"]},
	# Chef
	"master_kitchen":   {"needs": ["flying_pan", "meatball_barrage"]},
	# Brown
	"stampede":         {"needs": ["belly_bounce", "capy_charge"]},
}

# ─── Character skill pools (per character ID, falls back to _default) ─────────
const CHAR_SKILLS: Dictionary = {
	"_default":      ["regen", "magnet"],
	"capy_brown":    ["orb", "bolt", "wave", "belly_bounce", "friendly_aura", "lucky_clover", "capy_charge", "regen", "magnet", "swirl_tangerine"],
	"capy_wizard":   ["fireball", "elec_wave", "hurricane", "blizzard", "arcane_missile", "mana_nova", "time_warp", "crystal_prism", "arc_lightning", "regen", "magnet"],
	"capy_archer":   ["arrow", "split_arrow", "pierce_arrow", "sky_fall", "ricochet_arrow", "hawk_companion", "trap_arrow", "poison_arrow", "phantom_hunt", "regen", "magnet"],
	"capy_assassin": ["star_knife", "knife_storm", "boomerang", "seven_slash", "shadow_dagger", "blink_strike", "smoke_bomb", "shadow_clone", "bleed_mark", "regen", "magnet"],
	"capy_zoomer":   ["orb", "aura", "ice_orb", "bolt", "wave", "regen", "magnet"],
	"capy_swamp":    ["aura", "wave", "ice_orb", "toxic_mushroom", "bog_trap", "leech_vine", "plague_beetles", "regen", "magnet"],
	"capy_chef":     ["orb", "bolt", "flying_pan", "soup_splash", "chili_explosion", "healing_feast", "meatball_barrage", "magnet"],
}

# ─── Ultimate skill per character (empty string = no ulti) ────────────────────
const ULTI_SKILLS: Dictionary = {
	"capy_brown":    "swirl_tangerine",
	"capy_wizard":   "blizzard",
	"capy_archer":   "sky_fall",
	"capy_assassin": "seven_slash",
	"capy_swamp":    "toxic_mushroom",
	"capy_chef":     "chili_explosion",
}

# ─── Camera ───────────────────────────────────────────────────────────────────
var _camera: Camera2D

# ─── Player ───────────────────────────────────────────────────────────────────
var _player_pos:     Vector2 = Vector2.ZERO
var _player_hp:      float   = 200.0
var _player_max_hp:  float   = 200.0
var _player_base_max_hp: float = 200.0
var _player_speed:   float   = 360.0
var _player_iframes: float   = 0.0
var _player_tint:    Color   = Color(0.62, 0.46, 0.30)
var _player_tex:     Texture2D = null
var _player_walk_tex: Texture2D = null
var _player_facing_x: int     = 1  # 1 = right, -1 = left
var _player_move_dir: Vector2 = Vector2.ZERO
var _enemy_tex:       Dictionary = {}  # kind -> Texture2D
var _enemy_walk_tex:  Dictionary = {}  # kind -> 4-frame horizontal sheet
var _custom_story_asset_tex: Dictionary = {}  # objective/boss asset id -> Texture2D
var _skill_icon_cache: Dictionary = {}  # sid -> cropped Texture2D
var _evolution_definition_cache: Dictionary = {}  # "skill:evolution" -> definition
var _skill_greyscale_material: ShaderMaterial = null
var _skill_hud_widgets: Dictionary = {}  # sid -> {reveal, cooldown_label, level_label, slot}
const DAMAGE_POPUP_MAX: int = 120
const DAMAGE_POPUP_LIFE: float = 0.62
var _damage_popups: Array[Dictionary] = []
var _hud_update_timer: float = 0.0
var _draw_world_rect: Rect2 = Rect2()

# ─── Progression ──────────────────────────────────────────────────────────────
var _xp:      int   = 0
var _xp_next: int   = 50
var _level:   int   = 1
var _elapsed: float = 0.0
var _kills:   int   = 0

# ─── Skills ───────────────────────────────────────────────────────────────────
var _skills:    Array[Dictionary] = []
var _orb_angle: float             = 0.0

# ─── Enemies  {pos,hp,max_hp,spd,r,dmg,col,iframes,kind} ────────────────────
var _enemies:   Array[Dictionary] = []

# ─── Wave system ─────────────────────────────────────────────────────────────
var _wave:            int   = 0       # current wave number (1-indexed when active)
var _wave_state:      String = "spawning"  # "spawning" | "waiting" | "between"
var _wave_spawn_q:    Array[Dictionary] = []  # queued enemies to trickle-spawn
var _wave_spawn_t:    float = 0.0
var _between_t:       float = 0.0    # countdown before next wave
const BETWEEN_DELAY:  float = 2.5   # seconds between waves
const WAVE_BOSS_TYPES: Array = ["teleporter_boss", "shield_boss", "shooter_boss", "lava_boss"]
const PORTAL_BOSS_TYPES: Array = ["abyss_gate_warden", "prism_triarch", "blight_vine_tyrant", "thunderforge_behemoth"]
var _boss_bag:        Array = []
var _portal_boss_bag: Array = []

# ─── Map / room modifiers ───────────────────────────────────────────────────
var _room_index: int = 0
var _room_elapsed: float = 0.0
var _room_lava_tick_t: float = 0.0
var _room_spike_tick_t: float = 0.0
var _room_slide_velocity: Vector2 = Vector2.ZERO
var _stand_still_t: float = 0.0
var _idle_enemy_speed_boost_active: bool = false
var _lava_room_bg_tex: Texture2D = null
var _lava_room_tile_bg_tex: Texture2D = null
var _frozen_room_bg_tex: Texture2D = null
var _frozen_room_tile_bg_tex: Texture2D = null
var _poison_room_bg_tex: Texture2D = null
var _poison_room_tile_bg_tex: Texture2D = null
var _spike_room_bg_tex: Texture2D = null
var _spike_room_tile_bg_tex: Texture2D = null
var _darkness_room_bg_tex: Texture2D = null
var _darkness_room_overlay_tex: Texture2D = null
var _portal_icon_tex: Texture2D = null
var _next_level_icon_tex: Texture2D = null
var _objective_arrow_tex: Texture2D = null

# ─── Enemy modifier system (post wave 10) ───────────────────────────────────
const ENEMY_MOD_POOL: Array = ["fast", "giant", "armored", "explosive", "frozen_trail", "burn_trail"]
var _active_enemy_mod: String = ""
var _active_enemy_mod_name: String = ""
var _active_enemy_mod_desc: String = ""
var _frozen_trails: Array[Dictionary] = []
var _burn_trails:   Array[Dictionary] = []
const TRAIL_FROZEN_MAX: int = 140
const TRAIL_BURN_MAX: int = 120
const TRAIL_FROZEN_LIFE: float = 2.0
const TRAIL_BURN_LIFE: float = 2.0
const TRAIL_FROZEN_EMIT_INTERVAL: float = 0.34
const TRAIL_BURN_EMIT_INTERVAL: float = 0.30
const ICE_PATCH_SLOW_MULT: float = 0.55
const ICE_PATCH_SLOW_DURATION: float = 1.5

# ─── Potions  {pos,life} ─────────────────────────────────────────────────────
var _potions: Array[Dictionary] = []
var _ice_patch_slow_t: float = 0.0

# ─── Ring drops  {pos,life,ring} ─────────────────────────────────────────────
var _ring_drops: Array[Dictionary] = []
var _artifact_drops: Array[Dictionary] = []
var _rings_obtained: Array[Dictionary] = []
var _boss_artifact_results: Array[Dictionary] = []

# ─── Boss projectiles  {pos,vel,dmg,life} ────────────────────────────────
var _boss_projs: Array[Dictionary] = []

# ─── Shooter boss mortar strikes  {pos,life,max_life,dmg,r,launch} ──────────
var _mortar_strikes: Array[Dictionary] = []

# ─── Lava boss line eruptions {start,dir,len,width,life,warn_life,dmg,tick_t} ─
var _lava_lines: Array[Dictionary] = []

# ─── Lava pools  {pos,r,life,max_life,dmg_per_tick,tick_t} ──────────────────
var _lava_pools: Array[Dictionary] = []

# ─── Bolts  {pos,vel,dmg,life} ───────────────────────────────────────────────
var _bolts: Array[Dictionary] = []

# ─── Ice orbs  {pos,vel,dmg,life,freeze_r,slow,lvl} ─────────────────────────
var _ice_orbs: Array[Dictionary] = []

# ─── Pierce arrows  {pos,vel,dmg,life} (pass-through) ────────────────────────
var _pierce_arrows: Array[Dictionary] = []

# ─── Boomerangs  {pos,vel,orig_vel,dmg,life,max_life,returning} ──────────────
var _boomerangs: Array[Dictionary] = []

# ─── Fireballs  {pos,vel,dmg,life,trail_dmg} ────────────────────────────────
var _fireballs: Array[Dictionary] = []

# ─── Fire trails  {pos,life,max_life,dmg_per_tick,tick_t,r} ─────────────────
var _fire_trails: Array[Dictionary] = []

# ─── AOE flashes  {life,max_life,kind} (screen-wide skill visuals) ────────────
var _aoe_flashes: Array[Dictionary] = []

# ─── Wave visuals  {pos,r,max_r,life,max_life,kind} ──────────────────────────
var _waves: Array[Dictionary] = []

# ─── XP orbs  {pos,val} ──────────────────────────────────────────────────────
var _xp_orbs: Array[Dictionary] = []

# ─── HUD refs ─────────────────────────────────────────────────────────────────
var _hp_fill:        Panel
var _xp_fill:        Panel
var _level_lbl:      Label
var _time_lbl:       Label
var _kill_lbl:       Label
var _wave_lbl:       Label
var _skill_icon_scroll: ScrollContainer
var _skill_icon_row: HBoxContainer
var _joy_vis:        JoystickVisual
var _time_chip: TextureRect
var _room_chip: TextureRect
var _keys_chip: TextureRect
var _room_detail_lbl: Label
var _room_effect_lbl: Label
var _room_effect_chip: TextureRect
var _enemy_mod_lbl:   Label
var _affix_chip: TextureRect
var _passive_panel:    PanelContainer
var _passive_scroll:   ScrollContainer
var _passive_list:     VBoxContainer
var _passive_toggle_btn: Button
var _passive_collapsed: bool = true
var _passive_signature: String = ""

# ─── Touch input ──────────────────────────────────────────────────────────────
var _touch_id:     int     = -1
var _touch_origin: Vector2 = Vector2.ZERO
var _touch_cur:    Vector2 = Vector2.ZERO
var _joy_zone:     Rect2

# ─── State flags ──────────────────────────────────────────────────────────────
var _paused:    bool = false
var _game_over: bool = false
var _ring_revive_used: bool = false     # true once the player has used ring revive this run
var _ad_revive_used: bool = false       # true once the player has used ad revive this run
var _skill_reroll_used: bool = false  # true once the player has rerolled skills this level-up
var _loss_recorded: bool = false
var _progression_profile: Dictionary = {}
var _run_difficulty: Dictionary = {}
var _run_modifier: Dictionary = {}
var _progression_reward: Dictionary = {}
var story_stage: Dictionary = {}
var dungeon_mode: String = ""
var _dungeon_depth_cleared: int = 0
var _story_victory_started := false
var _story_victory_validated: bool = false
var _story_primary_complete: bool = false
var _story_required_boss_defeated: bool = false
var _story_required_target_survived: bool = false
var _story_telemetry: StoryTelemetry = null
var _story_debug_overlay: PanelContainer = null
var _story_debug_label: Label = null
var _story_debug_toggle: Button = null
var _story_debug_overlay_visible: bool = false
var _story_debug_update_timer: float = 0.0
var _story_debug_signature: String = ""
var _story_last_victory_request: String = "none"
var _story_last_victory_result: String = "No request yet"
var _adventure_state: String = ""
var _adventure_props: Array[Dictionary] = []
var _adventure_timer: float = 0.0
var _adventure_spawn_timer: float = 0.0
var _adventure_progress: int = 0
var _adventure_target: int = 0
var _story_key_drop_elapsed: float = 0.0
var _story_keys_generated: int = 0
var _story_nests_destroyed: int = 0
var _story_nests_generated: int = 0
var _story_route_waypoints: Array[Vector2] = []
var _story_route_index: int = 0
var _objective_boss_active: bool = false
var _coin_carried: int = 0
var _coin_banked: int = 0
var _forge_modifier: String = ""
var _adventure_choice_layer: CanvasLayer = null
var _story_custom_id: String = ""
var _story_custom_data: Dictionary = {}
var _story_custom_progress: Dictionary = {}
var _story_custom_sequence: Array[int] = []
var _story_custom_timer: float = 0.0
var _story_custom_interaction: float = 0.0
var _story_custom_touch_lock: String = ""
var _story_custom_carried: String = ""
var _story_custom_phase: int = 0
var _story_custom_alert: float = 0.0
var _story_custom_target_enemy: int = -1
var _story_custom_failure: String = ""
var _staged_objective_enabled: bool = false
var _staged_objective_required: int = 0
var _staged_objective_generated: int = 0
var _staged_objective_active: int = 0
var _staged_objective_completed: int = 0
var _staged_objective_spawn_timer: float = 0.0
var _story_stage_origin: Vector2 = Vector2.ZERO
var _story_previous_objective_pos: Vector2 = Vector2.ZERO
var _story_gate_remaining: int = 0
var _story_final_triggered: bool = false
var _story_final_completed: bool = false
var _story_final_remaining: int = 0
var _objective_nest_tex: Texture2D = null
var _objective_shrine_tex: Texture2D = null
var _objective_scout_tex: Texture2D = null
var _objective_hazard_tex: Texture2D = null
var _objective_safe_tex: Texture2D = null
var _objective_forge_tex: Texture2D = null
var _chapter_one_extraction_tex: Texture2D = null
var _chapter_one_energy_spore_tex: Texture2D = null
var _chapter_one_feeding_sac_tex: Texture2D = null
var _chapter_one_watchpath_key_tex: Texture2D = null
var _chapter_one_watchpath_exit_tex: Texture2D = null
var _chapter_one_animal_tracks_tex: Texture2D = null
var _chapter_one_barricade_tex: Texture2D = null
var _chapter_one_overheat_burst_tex: Texture2D = null
var _objective_start_btn: Button = null
var _story_hazard_arena_center: Vector2 = Vector2.ZERO
var _story_hazard_shot_timer: float = 0.0
var _story_hazard_pattern: int = 0
var _chapter_one: RefCounted = null
var _chapter_two: RefCounted = null
var _chapter_three: RefCounted = null
var _chapter_four: RefCounted = null
var _chapter_five: RefCounted = null
var _c2_spawn_timer: float = 0.0
var _c3_spawn_timer: float = 0.0
var _c3_action_timer: float = 0.0
var _c4_spawn_timer: float = 0.0
var _c4_action_timer: float = 0.0
var _c2_interaction: float = 0.0
var _c2_cold_threshold: int = 0
var _c2_bonus_levels_pending: int = 0
var _c1_phase_timer: float = 0.0
var _c1_interaction: float = 0.0
var _c1_spawn_budget: float = 0.0
var _c1_command: String = "follow"
var _c1_route_choice: String = ""
var _c1_threshold: int = 0
var _c1_milestones: int = 0

# ─── Ads ──────────────────────────────────────────────────────────────────────
var _ad_manager: AdManager = null
var _sound: SoundManager = null
var _combat_vfx: CombatVFX = null
var _sfx_next_allowed: Dictionary = {}

# ─── Character / ulti tracking ────────────────────────────────────────────────
var _char_id:       String = ""
var _ulti_unlocked: bool   = false
var _ulti_offered:  bool   = false
var _combo_locked_skills: Dictionary = {}

# ─── Ring bonuses (applied at match start) ───────────────────────────────────
var _ring_bonuses:  Dictionary = {}
var _ring_shield_cycle_t: float = 9.0
var _artifact_wheel_t: float = 0.0
var _artifact_wheel_left: float = 0.0
var _artifact_wheel_skill_dmg: float = 0.0
var _artifact_wheel_move_mul: float = 0.0
var _artifact_wheel_cd: float = 0.0
var _artifact_blink_t: float = 0.0
var _artifact_regen_pulse_t: float = 0.0

# ─── Combo visuals ───────────────────────────────────────────────────────────
var _combo_arcs:    Array[Dictionary] = []
var _shadow_clones: Array[Dictionary] = []
var _blade_queue:   Array[Dictionary] = []
var _smoke_clouds:  Array[Dictionary] = []
var _time_warp_zones: Array[Dictionary] = []
var _arc_zaps: Array[Dictionary] = []
var _prism_traps: Array[Dictionary] = []
var _ground_traps: Array[Dictionary] = []
var _hawk_companions: Array[Dictionary] = []
var _venom_pools: Array[Dictionary] = []
var _toxic_mushrooms: Array[Dictionary] = []
var _bog_pools: Array[Dictionary] = []
var _corruption_pools: Array[Dictionary] = []
var _kitchen_queue: Array[Dictionary] = []

# Boss skill effects
var _boss_chains: Array[Dictionary] = []
var _prism_zones: Array[Dictionary] = []
var _venom_pods: Array[Dictionary] = []
var _lightning_markers: Array[Dictionary] = []
var _thorn_patches: Array[Dictionary] = []
var _boss_summons: Array[Dictionary] = []  # reserved for future boss summon feature

# ─── Jump state for belly bounce ──────────────────────────────────────────────
var _player_jump_vel_y: float = 0.0

# ─── Stampede centipede  {pos,dir,life,max_life,dmg,speed,hit_enemies} ─
var _stampedes: Array[Dictionary] = []

# ─── Capy Charge shadow rush  {pos,dir,life,max_life,dmg,speed,hit_enemies} ──
var _capy_charge_rushes: Array[Dictionary] = []

# ─── Boss intermission challenge ───────────────────────────────────────────
var _boss_keys: int = 0
var _run_key_dropped: bool = false
var _boss_key_spent_this_run: int = 0
var _boss_intermission: Dictionary = {"state": "none", "door_pos": Vector2.ZERO, "ladder_pos": Vector2.ZERO, "arena_center": Vector2.ZERO, "arena_half": BOSS_ARENA_HALF, "last_boss_wave": 0}
var _boss_portal_confirm_layer: CanvasLayer = null
var _boss_wave_locked: bool = false

# ═════════════════════════════════════════════════════════════════════════════
# SETUP
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	if is_story_test_run and not OS.is_debug_build():
		push_warning("Story test run rejected in a release build.")
		is_story_test_run = false
		story_stage = {}
	SettingsStore.apply(get_tree())
	_progression_profile = ProgressionStore.load_profile(account_username) if not account_username.is_empty() else {}
	_run_difficulty = ProgressionStore.difficulty(_progression_profile) if not _progression_profile.is_empty() else {"name": "Cozy", "enemy_hp": 1.0, "enemy_damage": 1.0, "reward": 1.0}
	_run_modifier = ProgressionStore.daily_modifier()
	if not story_stage.is_empty():
		_run_difficulty = {"name":"Story", "enemy_hp":1.0, "enemy_damage":1.0, "reward":1.0}
		_run_modifier = {}
	elif not dungeon_mode.is_empty():
		_run_difficulty = {"name":"Resource Dungeon", "enemy_hp":1.0 + float(_wave) * 0.08, "enemy_damage":1.0 + float(_wave) * 0.06, "reward":1.0}
		_run_modifier = {}
	_sound = SoundManager.new()
	add_child(_sound)
	_combat_vfx = CombatVFX.new()
	add_child(_combat_vfx)
	var view: Vector2 = get_viewport_rect().size
	_joy_zone = Rect2(0.0, view.y * (2.0 / 3.0), view.x, view.y / 3.0)

	if selected_player_character != null:
		_player_base_max_hp = float(selected_player_character.max_hp)
		_player_max_hp = _player_base_max_hp
		_player_hp     = _player_max_hp
		_player_speed  = 300.0 + float(selected_player_character.attack - 7) * 12.0
		_player_tint   = selected_player_character.tint
		_char_id = String(selected_player_character.id)
		if not account_username.is_empty() and not is_story_test_run:
			ProgressionStore.record_mission_event(account_username, "characters", 1, _char_id)
		# Auto-grant character's starting skill
		var base_sid: String = selected_player_character.base_skill
		if not base_sid.is_empty() and SKILL_DEFS.has(base_sid):
			_skills.append({"id": base_sid, "level": 1, "timer": 0.0})
		# Load portrait texture via ResourceLoader (works on Android + desktop)
		var tex_path: String = "res://assets/characters/" + String(selected_player_character.id) + ".png"
		if ResourceLoader.exists(tex_path):
			_player_tex = load(tex_path) as Texture2D
		var walk_path := "res://assets/animations/characters/%s_walk.png" % String(selected_player_character.id)
		if ResourceLoader.exists(walk_path):
			_player_walk_tex = load(walk_path) as Texture2D

	if ResourceLoader.exists(LAVA_ROOM_BG_PATH):
		_lava_room_bg_tex = load(LAVA_ROOM_BG_PATH) as Texture2D
	if ResourceLoader.exists(LAVA_ROOM_TILE_BG_PATH):
		_lava_room_tile_bg_tex = load(LAVA_ROOM_TILE_BG_PATH) as Texture2D
	if ResourceLoader.exists(FROZEN_ROOM_BG_PATH):
		_frozen_room_bg_tex = load(FROZEN_ROOM_BG_PATH) as Texture2D
	if ResourceLoader.exists(FROZEN_ROOM_TILE_BG_PATH):
		_frozen_room_tile_bg_tex = load(FROZEN_ROOM_TILE_BG_PATH) as Texture2D
	if ResourceLoader.exists(POISON_ROOM_BG_PATH):
		_poison_room_bg_tex = load(POISON_ROOM_BG_PATH) as Texture2D
	if ResourceLoader.exists(POISON_ROOM_TILE_BG_PATH):
		_poison_room_tile_bg_tex = load(POISON_ROOM_TILE_BG_PATH) as Texture2D
	if ResourceLoader.exists(SPIKE_ROOM_BG_PATH):
		_spike_room_bg_tex = load(SPIKE_ROOM_BG_PATH) as Texture2D
	if ResourceLoader.exists(SPIKE_ROOM_TILE_BG_PATH):
		_spike_room_tile_bg_tex = load(SPIKE_ROOM_TILE_BG_PATH) as Texture2D
	if ResourceLoader.exists(DARKNESS_ROOM_TILE_BG_PATH):
		_darkness_room_bg_tex = load(DARKNESS_ROOM_TILE_BG_PATH) as Texture2D
	if ResourceLoader.exists(DARKNESS_ROOM_BG_PATH):
		_darkness_room_overlay_tex = load(DARKNESS_ROOM_BG_PATH) as Texture2D
	if ResourceLoader.exists(PORTAL_ICON_PATH):
		_portal_icon_tex = load(PORTAL_ICON_PATH) as Texture2D
	if ResourceLoader.exists(NEXT_LEVEL_ICON_PATH):
		_next_level_icon_tex = load(NEXT_LEVEL_ICON_PATH) as Texture2D
	if ResourceLoader.exists(OBJECTIVE_ARROW_PATH):
		_objective_arrow_tex = load(OBJECTIVE_ARROW_PATH) as Texture2D
	if ResourceLoader.exists(OBJECTIVE_NEST_PATH):
		_objective_nest_tex = load(OBJECTIVE_NEST_PATH) as Texture2D
	if ResourceLoader.exists(OBJECTIVE_SHRINE_PATH):
		_objective_shrine_tex = load(OBJECTIVE_SHRINE_PATH) as Texture2D
	if ResourceLoader.exists(OBJECTIVE_SCOUT_PATH):
		_objective_scout_tex = load(OBJECTIVE_SCOUT_PATH) as Texture2D
	if ResourceLoader.exists(OBJECTIVE_HAZARD_PATH):
		_objective_hazard_tex = load(OBJECTIVE_HAZARD_PATH) as Texture2D
	if ResourceLoader.exists(OBJECTIVE_SAFE_PATH):
		_objective_safe_tex = load(OBJECTIVE_SAFE_PATH) as Texture2D
	if ResourceLoader.exists(OBJECTIVE_FORGE_PATH):
		_objective_forge_tex = load(OBJECTIVE_FORGE_PATH) as Texture2D
	if ResourceLoader.exists(CHAPTER_ONE_EXTRACTION_PATH):
		_chapter_one_extraction_tex = load(CHAPTER_ONE_EXTRACTION_PATH) as Texture2D
	if ResourceLoader.exists(CHAPTER_ONE_ENERGY_SPORE_PATH):
		_chapter_one_energy_spore_tex = load(CHAPTER_ONE_ENERGY_SPORE_PATH) as Texture2D
	if ResourceLoader.exists(CHAPTER_ONE_FEEDING_SAC_PATH):
		_chapter_one_feeding_sac_tex = load(CHAPTER_ONE_FEEDING_SAC_PATH) as Texture2D
	if ResourceLoader.exists(CHAPTER_ONE_WATCHPATH_KEY_PATH):
		_chapter_one_watchpath_key_tex = load(CHAPTER_ONE_WATCHPATH_KEY_PATH) as Texture2D
	if ResourceLoader.exists(CHAPTER_ONE_WATCHPATH_EXIT_PATH):
		_chapter_one_watchpath_exit_tex = load(CHAPTER_ONE_WATCHPATH_EXIT_PATH) as Texture2D
	if ResourceLoader.exists(CHAPTER_ONE_ANIMAL_TRACKS_PATH):
		_chapter_one_animal_tracks_tex = load(CHAPTER_ONE_ANIMAL_TRACKS_PATH) as Texture2D
	if ResourceLoader.exists(CHAPTER_ONE_BARRICADE_PATH):
		_chapter_one_barricade_tex = load(CHAPTER_ONE_BARRICADE_PATH) as Texture2D
	if ResourceLoader.exists(CHAPTER_ONE_OVERHEAT_BURST_PATH):
		_chapter_one_overheat_burst_tex = load(CHAPTER_ONE_OVERHEAT_BURST_PATH) as Texture2D

	# ── Apply ring bonuses ────────────────────────────────────────────────
	if not account_username.is_empty() and not _char_id.is_empty():
		var bonuses: Dictionary = RingStore.get_bonuses(account_username, _char_id)
		var artifact_bonuses: Dictionary = ArtifactStore.get_bonuses(account_username, _char_id)
		for k in artifact_bonuses.keys():
			bonuses[k] = float(bonuses.get(k, 0.0)) + float(artifact_bonuses[k])
		var camp_bonuses := ProgressionStore.gameplay_bonuses(_progression_profile, _char_id)
		for k in camp_bonuses.keys():
			bonuses[k] = float(bonuses.get(k, 0.0)) + float(camp_bonuses[k])
		if not story_stage.is_empty():
			var story_bonuses := StoryStore.bonuses(account_username)
			for k in story_bonuses.keys():
				bonuses[k] = float(bonuses.get(k, 0.0)) + float(story_bonuses[k])
		bonuses["skill_dmg"] = float(bonuses.get("skill_dmg", 0.0)) + float(_run_modifier.get("skill_dmg", 0.0))
		bonuses["xp_bonus"] = float(bonuses.get("xp_bonus", 0.0)) + float(_run_modifier.get("xp_bonus", 0.0))
		bonuses["move_speed_mul"] = float(bonuses.get("move_speed_mul", 0.0)) + float(_run_modifier.get("move_speed", 0.0))
		_ring_bonuses = bonuses
		if bonuses.has("max_hp"):
			_player_max_hp += float(bonuses["max_hp"])
			_player_hp      = _player_max_hp
			_player_base_max_hp += float(bonuses["max_hp"])
		if bonuses.has("max_hp_pct"):
			_player_max_hp *= 1.0 + float(bonuses["max_hp_pct"])
			_player_hp = _player_max_hp
			_player_base_max_hp *= 1.0 + float(bonuses["max_hp_pct"])
		if bonuses.has("move_speed"):
			_player_speed += float(bonuses["move_speed"])
		if bonuses.has("move_speed_mul"):
			_player_speed *= 1.0 + float(bonuses["move_speed_mul"])
		if bonuses.has("chaos_mystery_box") and float(bonuses["chaos_mystery_box"]) > 0.0:
			_apply_mystery_box_chaos()
		if bonuses.has("chaos_wheel") and float(bonuses["chaos_wheel"]) > 0.0:
			_artifact_wheel_t = 0.0
			_artifact_wheel_left = 0.0
		if bonuses.has("blink_interval"):
			_artifact_blink_t = float(bonuses["blink_interval"])
		if bonuses.has("regen_pulse_interval"):
			_artifact_regen_pulse_t = float(bonuses["regen_pulse_interval"])

	_camera = Camera2D.new()
	_camera.position = _player_pos
	add_child(_camera)

	_build_hud()
	_update_skill_icons()
	_show_skill_select(true)
	# Kick off wave 1 after a short delay
	_wave        = 0
	_wave_state  = "between"
	_between_t   = 2.0  # 2s grace period before first wave
	_boss_wave_locked = false
	_sync_room_state(true)
	if not story_stage.is_empty():
		_story_telemetry = StoryTelemetryClass.new()
		_story_telemetry.start(story_stage, is_story_test_run)
		if is_story_test_run:
			_story_telemetry.log_event("Test stage started")
	_setup_adventure_mode()

	# Load enemy textures
	var _enemy_tex_map: Dictionary = {
		"normal":      "res://assets/enemies/enemy_normal.png",
		"normal_tank": "res://assets/enemies/enemy_tank.png",
		"normal_fast": "res://assets/enemies/enemy_fast.png",
		"teleporter_boss": "res://assets/bosses/boss_teleporter.png",
		"shield_boss":     "res://assets/bosses/boss_shield.png",
		"shooter_boss":    "res://assets/bosses/boss_shooter.png",
		"lava_boss":       "res://assets/bosses/boss_lava.png",
		"abyss_gate_warden": "res://assets/bosses/boss_abyss_gate_warden.png",
		"prism_triarch":     "res://assets/bosses/boss_prism_triarch.png",
		"blight_vine_tyrant":    "res://assets/bosses/boss_blight_vine_tyrant.png",
		"thunderforge_behemoth":       "res://assets/bosses/boss_thunderforge_behemoth.png",
	}
	for ek in _enemy_tex_map:
		var ep2: String = _enemy_tex_map[ek]
		if ResourceLoader.exists(ep2):
			_enemy_tex[ek] = load(ep2) as Texture2D
	var enemy_walk_paths := {
		"normal": "res://assets/animations/enemies/enemy_normal_walk.png",
		"normal_fast": "res://assets/animations/enemies/enemy_fast_run.png",
	}
	for enemy_kind in enemy_walk_paths:
		var walk_path: String = enemy_walk_paths[enemy_kind]
		if ResourceLoader.exists(walk_path):
			_enemy_walk_tex[enemy_kind] = load(walk_path) as Texture2D
	_load_custom_story_assets()

	# Initialise ad manager
	_ad_manager = AdManager.new()
	add_child(_ad_manager)

	# ========== SKILL SYSTEM INITIALIZATION ==========
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player == null:
		anim_player = AnimationPlayer.new()
		add_child(anim_player)

	SetupSkillAnimations.setup_all_animations(anim_player)
	await SkillMgr.tree_entered
	while not SkillMgr.is_ready:
		await get_tree().process_frame
	
	# Log final status
	var skill_count = SkillMgr.skill_manager._skill_data.size() if SkillMgr.skill_manager else 0
	print("✓ Skill system ready with %d skills loaded!" % skill_count)
	# ====================================================

# ═════════════════════════════════════════════════════════════════════════════
# INPUT
# ═════════════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if _paused or _game_over:
		return
	if event is InputEventScreenTouch:
		var te: InputEventScreenTouch = event as InputEventScreenTouch
		if te.pressed and _touch_id < 0 and _joy_zone.has_point(te.position):
			_touch_id = te.index
			_touch_origin = te.position
			_touch_cur = te.position
			_joy_vis.origin = _touch_origin
			_joy_vis.knob = _touch_origin + (_touch_cur - _touch_origin).limit_length(80.0)
			_joy_vis.visible_joy = true
			_joy_vis.queue_redraw()
		elif not te.pressed and te.index == _touch_id:
			_reset_touch_input()
	elif event is InputEventScreenDrag:
		var de: InputEventScreenDrag = event as InputEventScreenDrag
		if de.index == _touch_id:
			_touch_cur = de.position
			var diff: Vector2    = de.position - _touch_origin
			var clamped: Vector2 = diff.limit_length(80.0)
			_joy_vis.knob = _touch_origin + clamped
			_joy_vis.queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_reset_touch_input()

func _reset_touch_input() -> void:
	_touch_id = -1
	_touch_origin = Vector2.ZERO
	_touch_cur = Vector2.ZERO
	_player_move_dir = Vector2.ZERO
	_room_slide_velocity = Vector2.ZERO
	if _joy_vis != null:
		_joy_vis.visible_joy = false
		_joy_vis.queue_redraw()

func _get_move_dir() -> Vector2:
	var kd: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    kd.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  kd.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  kd.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): kd.x += 1.0
	if kd != Vector2.ZERO:
		return kd.normalized()
	if _touch_id >= 0:
		var diff: Vector2 = _touch_cur - _touch_origin
		if diff.length() > 12.0:
			return diff.normalized()
	return Vector2.ZERO

# ═════════════════════════════════════════════════════════════════════════════
# MAIN LOOP
# ═════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if _game_over or _paused:
		return
	_elapsed           += delta
	_room_elapsed      += delta
	_ice_patch_slow_t = max(_ice_patch_slow_t - delta, 0.0)
	_sync_room_state()
	_update_boss_intermission(delta)
	_update_artifact_runtime(delta)
	_player_iframes    = max(0.0, _player_iframes - delta)
	var _pmove: Vector2 = _get_move_dir()
	_player_move_dir    = _pmove
	_update_idle_enemy_boost(delta, _pmove)
	_apply_room_movement(delta, _pmove)
	_apply_story_hazard_arena_bounds()
	
	# Update belly bounce jump
	if _player_jump_vel_y != 0.0:
		_player_jump_vel_y -= 800.0 * delta  # Gravity
		if _player_jump_vel_y <= 0.0:
			_player_jump_vel_y = 0.0
	
	if _pmove.x > 0.01:    _player_facing_x = 1
	elif _pmove.x < -0.01: _player_facing_x = -1
	_camera.position = _story_hazard_arena_center if _is_story_hazard_arena_active() else _player_pos
	_update_ring_shield(delta)
	_apply_room_hazards(delta)
	_update_enemy_trails(delta)
	_update_skills(delta)
	_check_orb_hits()
	_update_enemies(delta)
	_update_bolts(delta)
	_update_ice_orbs(delta)
	_update_fireballs(delta)
	_update_fire_trails(delta)
	_update_pierce_arrows(delta)
	_update_boomerangs(delta)
	_update_shadow_clones(delta)
	_update_hawk_companions(delta)
	_update_blade_queue(delta)
	_update_smoke_clouds(delta)
	_update_time_warp_zones(delta)
	_update_prism_traps(delta)
	_update_ground_traps(delta)
	_update_arc_zaps(delta)
	_update_venom_pools(delta)
	_update_toxic_mushrooms(delta)
	_update_bog_pools(delta)
	_update_corruption_pools(delta)
	_update_kitchen_queue(delta)
	_update_combo_arcs(delta)
	_update_aoe_flashes(delta)
	_update_waves(delta)
	_update_capy_charge_rushes(delta)
	_update_stampedes(delta)
	_update_xp_orbs(delta)
	_update_potions(delta)
	_update_boss_chains(delta)
	_update_prism_zones(delta)
	_update_venom_pods(delta)
	_update_lightning_markers(delta)
	_update_thorn_patches(delta)
	_update_ring_drops(delta)
	_update_artifact_drops(delta)
	_update_boss_projs(delta)
	_update_mortar_strikes(delta)
	_update_lava_lines(delta)
	_update_lava_pools(delta)
	_update_adventure_mode(delta)
	_update_story_debug_overlay(delta)
	_lock_story_hazard_camera()
	if story_stage.is_empty() and dungeon_mode.is_empty():
		_update_spawner(delta)
	_update_damage_popups(delta)
	queue_redraw()
	_hud_update_timer -= delta
	if _hud_update_timer <= 0.0:
		_hud_update_timer = HUD_UPDATE_INTERVAL
		_update_hud()

func _update_ring_shield(delta: float) -> void:
	if _ring_bonus("timed_shield") <= 0.0:
		return
	_ring_shield_cycle_t = fmod(_ring_shield_cycle_t + delta, 10.0)

func _is_ring_shield_active() -> bool:
	return _ring_bonus("timed_shield") > 0.0 and _ring_shield_cycle_t < 1.0

func _update_idle_enemy_boost(delta: float, move_dir: Vector2) -> void:
	if move_dir.length_squared() <= 0.0001:
		_stand_still_t += delta
	else:
		_stand_still_t = 0.0
		_idle_enemy_speed_boost_active = false
	_idle_enemy_speed_boost_active = _stand_still_t >= 2.0

func _idle_enemy_speed_boost_multiplier() -> float:
	if _stand_still_t < 2.0:
		return 1.0
	var extra_time: float = _stand_still_t - 2.0
	return 1.0 + extra_time * 0.18

func _boss_progression_tier() -> int:
	return max(int(floor(float(max(_wave, 4) - 4) / 4.0)), 0)

func _boss_progression_multiplier() -> Dictionary:
	var tier: int = _boss_progression_tier()
	return {
		"hp": 1.0 + float(tier) * 0.12,
		"dmg": 1.0 + float(tier) * 0.08,
		"spd": 1.0 + float(tier) * 0.035,
	}

func _sync_room_state(force_reset: bool = false) -> void:
	var new_index: int = _current_room_index()
	if force_reset or new_index != _room_index:
		_room_index = new_index
		_room_elapsed = 0.0
		_room_lava_tick_t = 0.0
		_room_spike_tick_t = 0.0
		_room_slide_velocity = Vector2.ZERO
	else:
		pass

func _current_room_index() -> int:
	var wave_slot: int = max(_wave, 1) - 1
	var route_offset := 0
	if not story_stage.is_empty():
		var chapter_index := clampi(int(story_stage.get("chapter", 1)) - 1, 0, STORY_CHAPTER_ROOM_ROUTE.size() - 1)
		return STORY_CHAPTER_ROOM_ROUTE[chapter_index]
	elif dungeon_mode == "coin_burrow": route_offset = 2
	elif dungeon_mode == "forgecore": route_offset = 3
	return (int(floor(float(wave_slot) / float(ROOM_SPAN_WAVES))) + route_offset) % ROOM_ROUTE.size()

func _current_room() -> Dictionary:
	return ROOM_ROUTE[_room_index] as Dictionary

func _apply_room_movement(delta: float, move_dir: Vector2) -> void:
	var room_type: String = _current_room().get("id", "lava") as String
	var move_mul: float = 1.0 + _artifact_wheel_move_mul
	if _ice_patch_slow_t > 0.0:
		move_mul *= ICE_PATCH_SLOW_MULT
	if _chapter_two != null and int(story_stage.get("chapter", 0)) == 2:
		if _chapter_two.cold_exposure >= 100.0:
			move_mul *= 0.85
		elif _chapter_two.cold_exposure >= 75.0:
			move_mul *= 0.92
	if _chapter_five != null and _chapter_five.stage_number == 4 and _chapter_five.phase == "sync_attempt" and _chapter_five.flag("route_prepared"):
		move_mul *= 1.15
	if room_type == "frozen":
		var target_vel: Vector2 = move_dir * _player_speed * 1.08 * move_mul
		if move_dir == Vector2.ZERO:
			_room_slide_velocity = _room_slide_velocity.move_toward(Vector2.ZERO, 240.0 * delta)
		else:
			_room_slide_velocity = _room_slide_velocity.move_toward(target_vel, 920.0 * delta)
		_player_pos += _room_slide_velocity * delta
	else:
		_room_slide_velocity = Vector2.ZERO
		_player_pos += move_dir * _player_speed * move_mul * delta
	if (_boss_intermission.get("state", "none") as String) == "arena":
		var ac: Vector2 = _boss_intermission.get("arena_center", _player_pos) as Vector2
		var ah: Vector2 = _boss_intermission.get("arena_half", BOSS_ARENA_HALF) as Vector2
		_player_pos.x = clamp(_player_pos.x, ac.x - ah.x, ac.x + ah.x)
		_player_pos.y = clamp(_player_pos.y, ac.y - ah.y, ac.y + ah.y)

func _story_hazard_arena_half_size() -> Vector2:
	var view := get_viewport_rect().size
	return Vector2(maxf(120.0, view.x * 0.5 - PLAYER_R - 24.0), maxf(180.0, view.y * 0.5 - PLAYER_R - 24.0))

func _is_story_hazard_arena_active() -> bool:
	return _adventure_state == "story_hazards" or (_adventure_state == "story_chapter_one" and _chapter_one != null and _chapter_one.stage_number == 5)

func _apply_story_hazard_arena_bounds() -> void:
	if not _is_story_hazard_arena_active():
		return
	var half_size := _story_hazard_arena_half_size()
	_player_pos.x = clampf(_player_pos.x, _story_hazard_arena_center.x - half_size.x, _story_hazard_arena_center.x + half_size.x)
	_player_pos.y = clampf(_player_pos.y, _story_hazard_arena_center.y - half_size.y, _story_hazard_arena_center.y + half_size.y)

func _lock_story_hazard_camera() -> void:
	if _camera == null or not _is_story_hazard_arena_active():
		return
	_camera.position_smoothing_enabled = false
	_camera.drag_horizontal_enabled = false
	_camera.drag_vertical_enabled = false
	_camera.position = _story_hazard_arena_center
	_camera.reset_smoothing()
	_camera.force_update_scroll()

func _apply_room_hazards(delta: float) -> void:
	var room_type: String = _current_room().get("id", "lava") as String
	match room_type:
		"lava":
			if _player_move_dir.length_squared() > 0.0:
				_room_lava_tick_t = 0.4
				return
			_room_lava_tick_t -= delta
			if _room_lava_tick_t <= 0.0:
				_room_lava_tick_t = 1.15
				if _player_iframes <= 0.0:
					_damage_player(1.8 + float(_wave) * 0.12, 0.22)
		# spike: regen is suppressed via _room_regen_multiplier() — no tick damage
		_:
			pass

func _room_heal_multiplier() -> float:
	# Spike corridors suppress regen entirely; poison no longer penalises healing
	return 0.0 if (_current_room().get("id", "lava") as String) == "spike" else 1.0

func _room_potion_heal_multiplier() -> float:
	return 1.0

func _room_skill_dmg_multiplier() -> float:
	# Poison swamp reduces all skill damage by 10%
	return 0.90 if (_current_room().get("id", "lava") as String) == "poison" else 1.0

func _room_vision_radius() -> float:
	return 290.0 if (_current_room().get("id", "lava") as String) == "darkness" else 520.0

func _damage_player(amount: float, iframe_time: float) -> bool:
	if _is_inside_vulnerable_crown_window():
		_player_iframes = maxf(_player_iframes, minf(iframe_time, 0.2))
		return false
	if _is_ring_shield_active():
		_player_iframes = max(_player_iframes, min(iframe_time, 0.25))
		return false
	var story_damage: float = float(story_stage.get("enemy_damage", 1.0)) if not story_stage.is_empty() else 1.0
	var final_amount := amount * (1.0 + _ring_bonus("damage_taken_mul")) * float(_run_difficulty.get("enemy_damage", 1.0)) * float(_run_modifier.get("damage_taken", 1.0)) * story_damage
	_player_hp -= final_amount
	if _chapter_two != null and _chapter_two.stage_number == 1 and _story_custom_carried == "flame_charge" and final_amount >= _player_max_hp * 0.08:
		_chapter_two.cold_exposure = minf(100.0, _chapter_two.cold_exposure + 6.0)
		_story_log("Flame charge weakened by heavy frost damage")
	if _chapter_three != null and _chapter_three.stage_number == 4 and _story_custom_carried == "antidote_vial" and final_amount >= _player_max_hp * 0.04:
		var vial_damage: float = clampf(final_amount / maxf(_player_max_hp, 1.0) * 70.0, 6.0, 14.0)
		_chapter_three.adjust_meter("vial_integrity", -vial_damage)
		_story_log("Vial damaged: integrity %d%%" % roundi(_chapter_three.meter("vial_integrity")))
		if _chapter_three.meter("vial_integrity") <= 0.0:
			_story_custom_failure = "The antidote vial shattered."
			_player_hp = 0.0
			_handle_player_death()
			return true
	elif _story_custom_id == "cleanse_mire" and final_amount >= _player_max_hp * 0.05:
		_story_custom_progress["energy"] = maxi(0, int(_story_custom_progress.get("energy", 0)) - 1)
	_player_iframes = iframe_time
	if _player_hp <= 0.0:
		_handle_player_death()
		return true
	return false

# ═════════════════════════════════════════════════════════════════════════════
# SKILL UPDATES
# ═════════════════════════════════════════════════════════════════════════════

func _play_skill_sfx(cue: String, volume_db: float = -6.0, pitch_scale: float = 1.0, min_interval: float = 0.05) -> void:
	var next_allowed: float = float(_sfx_next_allowed.get(cue, -1.0))
	if _elapsed < next_allowed:
		return
	_sfx_next_allowed[cue] = _elapsed + min_interval
	if _sound != null:
		_sound.play(cue, volume_db, pitch_scale)
	if _combat_vfx != null:
		_combat_vfx.emit_cast(cue, _player_pos)

func _projectile_sfx_cue(kind: String) -> String:
	match kind:
		"arrow":
			return "skill_arrow"
		"split_arrow":
			return "skill_split_arrow"
		"star_knife":
			return "skill_star_knife"
		_:
			return "skill_bolt"

func _update_skills(delta: float) -> void:
	# ── Orb: rotate angle ──────────────────────────────────────────────────
	if _has_skill("orb"):
		_orb_angle = fmod(_orb_angle + ORB_SPD * delta, TAU)

	# ── Bolt: fire on cooldown ─────────────────────────────────────────────
	if _has_skill("bolt"):
		var bs: Dictionary  = _get_skill("bolt")
		bs["timer"] = (bs["timer"] as float) - delta
		if (bs["timer"] as float) <= 0.0:
			var bdef: Dictionary = _slvl("bolt", bs["level"] as int)
			bs["timer"] = bdef["cd"] as float
			_fire_bolts(bdef["n"] as int, bdef["dmg"] as float, bdef["spd"] as float)

	# ── Fireball: shoot toward nearest enemy, leave flame trail ───────────
	if _has_skill("fireball"):
		var fs: Dictionary = _get_skill("fireball")
		if not fs.has("timer"): fs["timer"] = 0.0
		fs["timer"] = (fs["timer"] as float) - delta
		if (fs["timer"] as float) <= 0.0:
			var fdef: Dictionary = _slvl("fireball", fs["level"] as int)
			var fire_cd: float = _apply_skill_cooldown_bonus(1.2 - float(fs["level"] as int) * 0.12)
			fs["timer"] = fire_cd
			_fire_fireball(fdef["orbs"] as int, fdef["dmg"] as float, _apply_projectile_speed_bonus(480.0))

	# ── Wave: trigger on cooldown ──────────────────────────────────────────
	if _has_skill("wave"):
		var ws: Dictionary = _get_skill("wave")
		ws["timer"] = (ws["timer"] as float) - delta
		if (ws["timer"] as float) <= 0.0:
			var wdef: Dictionary = _slvl("wave", ws["level"] as int)
			ws["timer"] = wdef["cd"] as float
			_trigger_wave_kind(wdef["r"] as float, wdef["dmg"] as float, "wave")

	# ── Aura: tick every 0.5 s ────────────────────────────────────────────
	if _has_skill("aura"):
		var as_: Dictionary = _get_skill("aura")
		if not as_.has("aura_t"):
			as_["aura_t"] = 0.0
		as_["aura_t"] = (as_["aura_t"] as float) - delta
		if (as_["aura_t"] as float) <= 0.0:
			as_["aura_t"] = 0.5
			_play_skill_sfx("skill_aura", -14.0, 1.0, 0.75)
			var adef: Dictionary = _slvl("aura", as_["level"] as int)
			var ar: float        = adef["r"] as float
			var tick: float      = (adef.get("dps", 0.0) as float) * 0.5
			for i in range(_enemies.size() - 1, -1, -1):
				var ep: Vector2 = _enemies[i]["pos"] as Vector2
				if ep.distance_to(_player_pos) <= ar + (_enemies[i]["r"] as float):
					_hit_enemy(i, tick)

	# ── Regen ─────────────────────────────────────────────────────────────
	var regen_rate: float = _ring_bonus("regen")
	if _has_skill("regen"):
		var rdef: Dictionary = _slvl("regen", _get_skill("regen")["level"] as int)
		regen_rate += rdef["hps"] as float
	if _has_skill("healing_feast"):
		var hfdef: Dictionary = _slvl("healing_feast", _get_skill("healing_feast")["level"] as int)
		regen_rate += (hfdef["hps"] as float) * 1.10
	if _has_skill("lucky_clover"):
		var lcdef: Dictionary = _slvl("lucky_clover", _get_skill("lucky_clover")["level"] as int)
		regen_rate += lcdef["hps"] as float
	if regen_rate > 0.0:
		regen_rate *= 1.0 + _ring_bonus("healing_efficiency")
		regen_rate *= _room_heal_multiplier()
		if _player_hp < _player_max_hp:
			_play_skill_sfx("skill_regen", -16.0, 1.0, 1.2)
		_player_hp = min(_player_max_hp, _player_hp + regen_rate * delta)
	# ── Ice Orb: fire on cooldown ─────────────────────────────────────
	if _has_skill("ice_orb"):
		var is_: Dictionary = _get_skill("ice_orb")
		is_["timer"] = (is_["timer"] as float) - delta
		if (is_["timer"] as float) <= 0.0:
			var idef: Dictionary = _slvl("ice_orb", is_["level"] as int)
			is_["timer"] = idef["cd"] as float
			_fire_ice_orbs(idef["n"] as int, idef["dmg"] as float,
					idef["spd"] as float, idef["freeze_r"] as float,
					idef["slow"] as float, is_["level"] as int)

	# ── Arrow (same fire mechanic as bolt) ────────────────────────────────
	if _has_skill("arrow"):
		var ar_s: Dictionary = _get_skill("arrow")
		ar_s["timer"] = (ar_s["timer"] as float) - delta
		if (ar_s["timer"] as float) <= 0.0:
			var ardef: Dictionary = _slvl("arrow", ar_s["level"] as int)
			ar_s["timer"] = ardef["cd"] as float
			_fire_bolts(ardef["n"] as int, ardef["dmg"] as float, ardef["spd"] as float, "arrow")

	# ── Split Arrow ───────────────────────────────────────────────────────
	if _has_skill("split_arrow"):
		var ss: Dictionary = _get_skill("split_arrow")
		ss["timer"] = (ss["timer"] as float) - delta
		if (ss["timer"] as float) <= 0.0:
			var sdef: Dictionary = _slvl("split_arrow", ss["level"] as int)
			ss["timer"] = sdef["cd"] as float
			_fire_split_arrows(sdef["n"] as int, sdef["dmg"] as float, sdef["spd"] as float, sdef["spread"] as float)

	# ── Pierce Arrow ──────────────────────────────────────────────────────
	if _has_skill("pierce_arrow"):
		var ps: Dictionary = _get_skill("pierce_arrow")
		ps["timer"] = (ps["timer"] as float) - delta
		if (ps["timer"] as float) <= 0.0:
			var pdef: Dictionary = _slvl("pierce_arrow", ps["level"] as int)
			ps["timer"] = pdef["cd"] as float
			_fire_pierce_arrows(pdef["n"] as int, pdef["dmg"] as float, pdef["spd"] as float)

	# ── Star Knife (same fire mechanic as bolt) ─────────────────────────────
	if _has_skill("star_knife"):
		var sk_s: Dictionary = _get_skill("star_knife")
		sk_s["timer"] = (sk_s["timer"] as float) - delta
		if (sk_s["timer"] as float) <= 0.0:
			var skdef: Dictionary = _slvl("star_knife", sk_s["level"] as int)
			sk_s["timer"] = skdef["cd"] as float
			_fire_bolts(skdef["n"] as int, skdef["dmg"] as float, skdef["spd"] as float, "star_knife")

	# ── Boomerang ───────────────────────────────────────────────────────────
	if _has_skill("boomerang"):
		var bm: Dictionary = _get_skill("boomerang")
		bm["timer"] = (bm["timer"] as float) - delta
		if (bm["timer"] as float) <= 0.0:
			var bmdef: Dictionary = _slvl("boomerang", bm["level"] as int)
			bm["timer"] = bmdef["cd"] as float
			_fire_boomerangs(bmdef["n"] as int, bmdef["dmg"] as float, bmdef["spd"] as float)

	# ── Hurricane (aura-type) ──────────────────────────────────────────────
	if _has_skill("hurricane"):
		var hs: Dictionary = _get_skill("hurricane")
		if not hs.has("aura_t"): hs["aura_t"] = 0.0
		hs["aura_t"] = (hs["aura_t"] as float) - delta
		if (hs["aura_t"] as float) <= 0.0:
			hs["aura_t"] = 0.5
			_play_skill_sfx("skill_hurricane", -15.0, 1.0, 0.75)
			var hdef: Dictionary = _slvl("hurricane", hs["level"] as int)
			var hr: float = hdef["r"] as float
			var htick: float = (hdef.get("dps", 0.0) as float) * 0.5
			for i in range(_enemies.size() - 1, -1, -1):
				var ep: Vector2 = _enemies[i]["pos"] as Vector2
				if ep.distance_to(_player_pos) <= hr + (_enemies[i]["r"] as float):
					_hit_enemy(i, htick)

	# ── Knife Storm (aura-type) ─────────────────────────────────────────────
	if _has_skill("knife_storm"):
		var ks: Dictionary = _get_skill("knife_storm")
		if not ks.has("aura_t"): ks["aura_t"] = 0.0
		ks["aura_t"] = (ks["aura_t"] as float) - delta
		if (ks["aura_t"] as float) <= 0.0:
			ks["aura_t"] = 0.5
			_play_skill_sfx("skill_knife_storm", -14.0, 1.0, 0.75)
			var kdef: Dictionary = _slvl("knife_storm", ks["level"] as int)
			var kr: float = kdef["r"] as float
			var ktick: float = (kdef.get("dps", 0.0) as float) * 0.5
			for i in range(_enemies.size() - 1, -1, -1):
				var ep: Vector2 = _enemies[i]["pos"] as Vector2
				if ep.distance_to(_player_pos) <= kr + (_enemies[i]["r"] as float):
					_hit_enemy(i, ktick)

	# ── Electric Wave ─────────────────────────────────────────────────────
	if _has_skill("elec_wave"):
		var ew: Dictionary = _get_skill("elec_wave")
		ew["timer"] = (ew["timer"] as float) - delta
		if (ew["timer"] as float) <= 0.0:
			var ewdef: Dictionary = _slvl("elec_wave", ew["level"] as int)
			ew["timer"] = ewdef["cd"] as float
			_trigger_wave_kind(ewdef["r"] as float, ewdef["dmg"] as float, "elec_wave")

	# ── Inferno Thunder (Fireball + Capy Bolt) ───────────────────────────
	if _has_skill("inferno_thunder"):
		var its: Dictionary = _get_skill("inferno_thunder")
		its["timer"] = (its["timer"] as float) - delta
		if (its["timer"] as float) <= 0.0:
			var itdef: Dictionary = _slvl("inferno_thunder", its["level"] as int)
			its["timer"] = itdef["cd"] as float
			_fire_inferno_plasma(
				itdef["n"] as int,
				itdef["dmg"] as float,
				itdef["spd"] as float,
				itdef["chain_dmg"] as float,
				itdef["chains"] as int,
				itdef["emp_r"] as float,
				itdef["emp_dmg"] as float
			)

	# ── Frozen Lance (Ice Orb + Pierce Arrow) ─────────────────────────────
	if _has_skill("frozen_lance"):
		var fls: Dictionary = _get_skill("frozen_lance")
		fls["timer"] = (fls["timer"] as float) - delta
		if (fls["timer"] as float) <= 0.0:
			var fldef: Dictionary = _slvl("frozen_lance", fls["level"] as int)
			fls["timer"] = fldef["cd"] as float
			_fire_frozen_lances(
				fldef["n"] as int,
				fldef["dmg"] as float,
				fldef["spd"] as float,
				fldef["freeze_r"] as float,
				fldef["slow"] as float,
				fldef["explode_r"] as float,
				fldef["explode_dmg"] as float
			)

	# ── Divine Volley (Arrow Shot + Split Arrow) ──────────────────────────
	if _has_skill("divine_volley"):
		var dvs: Dictionary = _get_skill("divine_volley")
		dvs["timer"] = (dvs["timer"] as float) - delta
		if (dvs["timer"] as float) <= 0.0:
			var dvdef: Dictionary = _slvl("divine_volley", dvs["level"] as int)
			dvs["timer"] = dvdef["cd"] as float
			_fire_divine_volley(
				dvdef["n"] as int,
				dvdef["dmg"] as float,
				dvdef["spd"] as float,
				dvdef["splits"] as int,
				dvdef["pierce"] as int
			)

	# ── Thunder God Pulse (Elec Shockwave + Capy Bolt) ───────────────────
	if _has_skill("thunder_god_pulse"):
		var tgs: Dictionary = _get_skill("thunder_god_pulse")
		tgs["timer"] = (tgs["timer"] as float) - delta
		if (tgs["timer"] as float) <= 0.0:
			var tgdef: Dictionary = _slvl("thunder_god_pulse", tgs["level"] as int)
			tgs["timer"] = tgdef["cd"] as float
			_trigger_thunder_god_pulse(
				tgdef["r"] as float,
				tgdef["dmg"] as float,
				tgdef["mark_t"] as float,
				tgdef["chains"] as int,
				tgdef["chain_dmg"] as float
			)

	# ── Toxic Lightning (Mud Aura + Elec Shockwave) ───────────────────────
	if _has_skill("toxic_lightning"):
		var tls: Dictionary = _get_skill("toxic_lightning")
		if not tls.has("aura_t"):
			tls["aura_t"] = 0.0
		if not tls.has("pulse_t"):
			tls["pulse_t"] = 0.0
		var tldef: Dictionary = _slvl("toxic_lightning", tls["level"] as int)
		tls["aura_t"] = (tls["aura_t"] as float) - delta
		if (tls["aura_t"] as float) <= 0.0:
			tls["aura_t"] = 0.5
			var aura_r: float = tldef["r"] as float
			var aura_tick: float = (tldef.get("dps", 0.0) as float) * 0.5
			for i in range(_enemies.size() - 1, -1, -1):
				var ep: Vector2 = _enemies[i]["pos"] as Vector2
				if ep.distance_to(_player_pos) <= aura_r + (_enemies[i]["r"] as float):
					_apply_poison_to_enemy_idx(i, 3.0, tldef["poison_dps"] as float)
					_hit_enemy(i, aura_tick)
		tls["pulse_t"] = (tls["pulse_t"] as float) - delta
		if (tls["pulse_t"] as float) <= 0.0:
			tls["pulse_t"] = tldef["cd"] as float
			_trigger_toxic_lightning_pulse(
				tldef["pulse_r"] as float,
				tldef["pulse_dmg"] as float,
				tldef["spread_r"] as float,
				tldef["poison_dps"] as float
			)

	# ── New bolt-type skills ─────────────────────────────────────────────────
	for _nb_sid in ["arcane_missile", "ricochet_arrow", "shadow_dagger", "bleed_mark", "poison_arrow", "venom_plague", "flying_pan", "leech_vine"]:
		if _has_skill(_nb_sid):
			var _nb_s: Dictionary = _get_skill(_nb_sid)
			_nb_s["timer"] = (_nb_s["timer"] as float) - delta
			if (_nb_s["timer"] as float) <= 0.0:
				var _nb_def: Dictionary = _slvl(_nb_sid, _nb_s["level"] as int)
				_nb_s["timer"] = _nb_def["cd"] as float
				if _nb_sid == "leech_vine":
					_fire_bolts(_nb_def["n"] as int, _nb_def["dmg"] as float, _nb_def["spd"] as float, "leech_vine")
				else:
					_fire_bolts(_nb_def["n"] as int, _nb_def["dmg"] as float, _nb_def["spd"] as float, _nb_sid)

	# ── New aura-type skills ──────────────────────────────────────────────────
	for _na_sid in ["friendly_aura"]:
		if _has_skill(_na_sid):
			var _na_s: Dictionary = _get_skill(_na_sid)
			if not _na_s.has("aura_t"): _na_s["aura_t"] = 0.0
			_na_s["aura_t"] = (_na_s["aura_t"] as float) - delta
			if (_na_s["aura_t"] as float) <= 0.0:
				_na_s["aura_t"] = 0.5
				var _na_def: Dictionary = _slvl(_na_sid, _na_s["level"] as int)
				var _na_r: float = _na_def["r"] as float
				var _na_tick: float = (_na_def.get("dps", 0.0) as float) * 0.5
				for _i in range(_enemies.size() - 1, -1, -1):
					var _ep: Vector2 = _enemies[_i]["pos"] as Vector2
					if _ep.distance_to(_player_pos) <= _na_r + (_enemies[_i]["r"] as float):
						_hit_enemy(_i, _na_tick)
				_aoe_flashes.append({"life": 0.7, "max_life": 0.7, "kind": _na_sid, "pos": _player_pos})

	# ── Shadow Clone: spawn a persistent ghost clone entity ─────────────────────
	if _has_skill("shadow_clone"):
		var _sc_s: Dictionary = _get_skill("shadow_clone")
		_sc_s["timer"] = (_sc_s["timer"] as float) - delta
		if (_sc_s["timer"] as float) <= 0.0:
			var _sc_lvl: int = _sc_s["level"] as int
			_sc_s["timer"] = max(4.0, 10.0 - float(_sc_lvl) * 1.2)
			_spawn_shadow_clone(_player_pos, _player_max_hp * 0.15, _sc_lvl)

	# ── New wave-type skills ──────────────────────────────────────────────────
	for _nw_sid in ["belly_bounce"]:
		if _has_skill(_nw_sid):
			var _nw_s: Dictionary = _get_skill(_nw_sid)
			_nw_s["timer"] = (_nw_s["timer"] as float) - delta
			if (_nw_s["timer"] as float) <= 0.0:
				var _nw_def: Dictionary = _slvl(_nw_sid, _nw_s["level"] as int)
				_nw_s["timer"] = _nw_def["cd"] as float
				# Add jump effect for belly bounce
				var jump_height: float = 40.0
				_player_jump_vel_y = sqrt(2.0 * jump_height * 800.0)  # Physics: v = sqrt(2*g*h)
				_trigger_wave_kind(_nw_def["r"] as float, _nw_def["dmg"] as float, _nw_sid)

	# ── Toxic Mushroom: spawn local mushroom that pulses fog every 2s ─────────
	if _has_skill("toxic_mushroom"):
		var tm_s: Dictionary = _get_skill("toxic_mushroom")
		tm_s["timer"] = (tm_s["timer"] as float) - delta
		if (tm_s["timer"] as float) <= 0.0:
			var tm_def: Dictionary = _slvl("toxic_mushroom", tm_s["level"] as int)
			tm_s["timer"] = tm_def["cd"] as float
			_spawn_toxic_mushroom(tm_def)

	# ── Bog Trap: muddy pool slow only ────────────────────────────────────────
	if _has_skill("bog_trap"):
		var bg_s: Dictionary = _get_skill("bog_trap")
		bg_s["timer"] = (bg_s["timer"] as float) - delta
		if (bg_s["timer"] as float) <= 0.0:
			var bg_def: Dictionary = _slvl("bog_trap", bg_s["level"] as int)
			bg_s["timer"] = bg_def["cd"] as float
			_spawn_bog_pool(bg_def)

	# ── Corruption Field: trap pools that sink enemies for 3s ─────────────────
	if _has_skill("corruption_field"):
		var cf_s: Dictionary = _get_skill("corruption_field")
		cf_s["timer"] = (cf_s["timer"] as float) - delta
		if (cf_s["timer"] as float) <= 0.0:
			var cf_def: Dictionary = _slvl("corruption_field", cf_s["level"] as int)
			cf_s["timer"] = cf_def["cd"] as float
			_spawn_corruption_pools(cf_def)

	# ── Plague Beetles: attach swarm to one enemy for 3s DOT ──────────────────
	if _has_skill("plague_beetles"):
		var pb_s: Dictionary = _get_skill("plague_beetles")
		pb_s["timer"] = (pb_s["timer"] as float) - delta
		if (pb_s["timer"] as float) <= 0.0:
			var pb_def: Dictionary = _slvl("plague_beetles", pb_s["level"] as int)
			pb_s["timer"] = pb_def["cd"] as float
			_attach_plague_beetles(pb_def)

	# ── Soup Splash: cone toward nearest enemy, half-screen range ─────────────
	if _has_skill("soup_splash"):
		var ss_s: Dictionary = _get_skill("soup_splash")
		ss_s["timer"] = (ss_s["timer"] as float) - delta
		if (ss_s["timer"] as float) <= 0.0:
			var ss_def: Dictionary = _slvl("soup_splash", ss_s["level"] as int)
			ss_s["timer"] = ss_def["cd"] as float
			_cast_soup_cone(ss_def)

	# ── Chili Explosion: chilies that leave ember pools ───────────────────────
	if _has_skill("chili_explosion"):
		var ce_s: Dictionary = _get_skill("chili_explosion")
		ce_s["timer"] = (ce_s["timer"] as float) - delta
		if (ce_s["timer"] as float) <= 0.0:
			var ce_def: Dictionary = _slvl("chili_explosion", ce_s["level"] as int)
			ce_s["timer"] = ce_def["cd"] as float
			_fire_chili_explosion(ce_def)

	# ── Master Kitchen: short-range utensil bursts at staggered timings ───────
	if _has_skill("master_kitchen"):
		var mk_s: Dictionary = _get_skill("master_kitchen")
		mk_s["timer"] = (mk_s["timer"] as float) - delta
		if (mk_s["timer"] as float) <= 0.0:
			var mk_def: Dictionary = _slvl("master_kitchen", mk_s["level"] as int)
			mk_s["timer"] = mk_def["cd"] as float
			_queue_master_kitchen(mk_def)

	# ── Phantom Hunt: straight white projectiles ──────────────────────────────
	if _has_skill("phantom_hunt"):
		var ph_s: Dictionary = _get_skill("phantom_hunt")
		ph_s["timer"] = (ph_s["timer"] as float) - delta
		if (ph_s["timer"] as float) <= 0.0:
			var ph_def: Dictionary = _slvl("phantom_hunt", ph_s["level"] as int)
			ph_s["timer"] = ph_def["cd"] as float
			_fire_phantom_hunt(ph_def)

	# ── Mana Burst: push enemies outward — no damage ─────────────────────────
	if _has_skill("mana_nova"):
		var _mn_s: Dictionary = _get_skill("mana_nova")
		_mn_s["timer"] = (_mn_s["timer"] as float) - delta
		if (_mn_s["timer"] as float) <= 0.0:
			var _mn_def: Dictionary = _slvl("mana_nova", _mn_s["level"] as int)
			_mn_s["timer"] = _mn_def["cd"] as float
			_do_mana_push(_mn_def["r"] as float, 180.0 + (_mn_def["r"] as float) * 0.45)

	# ── Blink Strike: instant dash in move direction ──────────────────────────
	if _has_skill("blink_strike"):
		var _bs_s: Dictionary = _get_skill("blink_strike")
		_bs_s["timer"] = (_bs_s["timer"] as float) - delta
		if (_bs_s["timer"] as float) <= 0.0:
			var _bs_def: Dictionary = _slvl("blink_strike", _bs_s["level"] as int)
			_bs_s["timer"] = _bs_def["cd"] as float
			_do_blink_strike(_bs_def["r"] as float, _bs_def["dmg"] as float)

	# ── Capy Charge: shadow rush toward nearest enemy ─────────────────────────
	if _has_skill("capy_charge"):
		var _cc_s: Dictionary = _get_skill("capy_charge")
		_cc_s["timer"] = (_cc_s["timer"] as float) - delta
		if (_cc_s["timer"] as float) <= 0.0 and not _enemies.is_empty():
			var _cc_def: Dictionary = _slvl("capy_charge", _cc_s["level"] as int)
			_cc_s["timer"] = _cc_def["cd"] as float
			_do_capy_charge_shadow(_cc_def["dmg"] as float)

	# ── Stampede: centipede rush in random direction ──────────────────────────
	if _has_skill("stampede"):
		var _st_s: Dictionary = _get_skill("stampede")
		_st_s["timer"] = (_st_s["timer"] as float) - delta
		if (_st_s["timer"] as float) <= 0.0:
			var _st_def: Dictionary = _slvl("stampede", _st_s["level"] as int)
			_st_s["timer"] = _st_def["cd"] as float
			_do_stampede_charge(_st_def["dmg"] as float, _st_s["level"] as int)

	# ── Screen AOE skills (excluding capy_charge and stampede) ──────────────────────────
	for aoe_sid in ["blizzard", "sky_fall", "seven_slash", "swirl_tangerine"]:
		if _has_skill(aoe_sid):
			var ao: Dictionary = _get_skill(aoe_sid)
			ao["timer"] = (ao["timer"] as float) - delta
			if (ao["timer"] as float) <= 0.0:
				var aodef: Dictionary = _slvl(aoe_sid, ao["level"] as int)
				ao["timer"] = aodef["cd"] as float
				var slow_val: float = aodef.get("slow", 0.0) as float
				_trigger_aoe(aoe_sid, aodef["dmg"] as float, slow_val)

	# ── Smoke Bomb: scatter cloud entities on screen ─────────────────────────
	if _has_skill("smoke_bomb"):
		var _sb_s: Dictionary = _get_skill("smoke_bomb")
		_sb_s["timer"] = (_sb_s["timer"] as float) - delta
		if (_sb_s["timer"] as float) <= 0.0:
			var _sb_def: Dictionary = _slvl("smoke_bomb", _sb_s["level"] as int)
			_sb_s["timer"] = _sb_def["cd"] as float
			_spawn_smoke_clouds(_sb_def["n"] as int, _sb_def["dmg"] as float)

	# ── Thousand Blades: queue blades to fly out one by one ──────────────────
	if _has_skill("thousand_blades"):
		var _tb_s: Dictionary = _get_skill("thousand_blades")
		_tb_s["timer"] = (_tb_s["timer"] as float) - delta
		if (_tb_s["timer"] as float) <= 0.0:
			var _tb_def: Dictionary = _slvl("thousand_blades", _tb_s["level"] as int)
			_tb_s["timer"] = _tb_def["cd"] as float
			_queue_thousand_blades(_tb_def["n"] as int, _tb_def["dmg"] as float, _tb_def["spd"] as float)

	# ── Time Warp: place a slow zone on the ground ───────────────────────────
	if _has_skill("time_warp"):
		var _tw_s: Dictionary = _get_skill("time_warp")
		_tw_s["timer"] = (_tw_s["timer"] as float) - delta
		if (_tw_s["timer"] as float) <= 0.0:
			var _tw_def: Dictionary = _slvl("time_warp", _tw_s["level"] as int)
			_tw_s["timer"] = _tw_def["cd"] as float
			_trigger_time_warp_zone(_tw_def["r"] as float, _tw_def["slow"] as float, _tw_def["life"] as float)

	# ── Arc Lightning: zap nearest enemy and chain ───────────────────────────
	if _has_skill("arc_lightning"):
		var _al_s: Dictionary = _get_skill("arc_lightning")
		_al_s["timer"] = (_al_s["timer"] as float) - delta
		if (_al_s["timer"] as float) <= 0.0:
			var _al_def: Dictionary = _slvl("arc_lightning", _al_s["level"] as int)
			_al_s["timer"] = _al_def["cd"] as float
			_cast_arc_lightning(_al_def["r"] as float, _al_def["dmg"] as float, _al_def.get("chains", 2) as int, _al_def.get("chain_r", 180.0) as float)

	# ── Crystal Prism: place a triangle laser trap ───────────────────────────
	if _has_skill("crystal_prism"):
		var _cp_s: Dictionary = _get_skill("crystal_prism")
		_cp_s["timer"] = (_cp_s["timer"] as float) - delta
		if (_cp_s["timer"] as float) <= 0.0:
			var _cp_def: Dictionary = _slvl("crystal_prism", _cp_s["level"] as int)
			_cp_s["timer"] = _cp_def["cd"] as float
			_spawn_prism_trap(_cp_def["r"] as float, _cp_def["dmg"] as float, _cp_def.get("life", 7.0) as float)

	# ── Trap Arrow: place thorn-vine ground line trap ────────────────────────
	if _has_skill("trap_arrow"):
		var _ta_s: Dictionary = _get_skill("trap_arrow")
		_ta_s["timer"] = (_ta_s["timer"] as float) - delta
		if (_ta_s["timer"] as float) <= 0.0:
			var _ta_def: Dictionary = _slvl("trap_arrow", _ta_s["level"] as int)
			_ta_s["timer"] = _ta_def["cd"] as float
			_fire_trap_arrow(_ta_def)

	# ── Hawk Companion: summon hawk for active duration, cooldown starts after ─
	if _has_skill("hawk_companion"):
		var _hk_s: Dictionary = _get_skill("hawk_companion")
		if not _hk_s.has("active_t"):
			_hk_s["active_t"] = 0.0
		if not _hk_s.has("timer"):
			_hk_s["timer"] = 0.0
		if (_hk_s["active_t"] as float) > 0.0:
			_hk_s["active_t"] = max((_hk_s["active_t"] as float) - delta, 0.0)
			if (_hk_s["active_t"] as float) <= 0.0:
				var _hk_end_def: Dictionary = _slvl("hawk_companion", _hk_s["level"] as int)
				_hk_s["timer"] = _hk_end_def["cd"] as float
		else:
			_hk_s["timer"] = (_hk_s["timer"] as float) - delta
			if (_hk_s["timer"] as float) <= 0.0:
				var _hk_def: Dictionary = _slvl("hawk_companion", _hk_s["level"] as int)
				_hk_s["active_t"] = _hk_def.get("life", 10.0) as float
				_spawn_hawk_companion(_hk_def)

func _check_orb_hits() -> void:
	if _has_skill("orb"):
		var orb_def: Dictionary = _slvl("orb", _get_skill("orb")["level"] as int)
		var n: int     = orb_def["orbs"] as int
		var dmg: float = orb_def["dmg"] as float
		var orbit_r: float = _capy_orb_orbit_radius()
		var hit_r: float = _capy_orb_hit_radius()
		for i in n:
			var ang: float  = _orb_angle + float(i) * TAU / float(n)
			var op: Vector2 = _player_pos + Vector2(cos(ang), sin(ang)) * orbit_r
			for j in range(_enemies.size() - 1, -1, -1):
				if (_enemies[j]["iframes"] as float) > 0.0:
					continue
				if op.distance_to(_enemies[j]["pos"] as Vector2) < hit_r + (_enemies[j]["r"] as float):
					_play_skill_sfx("skill_orb", -12.0, 1.0, 0.18)
					_hit_enemy(j, dmg)
					break

func _fire_bolts(n: int, dmg: float, spd: float, kind: String = "bolt") -> void:
	if _enemies.is_empty():
		return
	var sfx_volume: float = -12.0 if kind == "bolt" else -7.0
	_play_skill_sfx(_projectile_sfx_cue(kind), sfx_volume, 1.0, 0.08)
	var shot_dmg: float = dmg * TARGET_SKILL_DAMAGE_MULT
	var checked: Array[int] = []
	for _i in n:
		var best: float = INF
		var best_j: int = -1
		for j in _enemies.size():
			if j < 0 or j >= _enemies.size():
				continue
			if checked.has(j):
				continue
			var d: float = _player_pos.distance_to(_enemies[j]["pos"] as Vector2)
			if d < best:
				best = d
				best_j = j
		if best_j < 0:
			break
		if best_j >= _enemies.size():
			break
		checked.append(best_j)
		var dir: Vector2 = ((_enemies[best_j]["pos"] as Vector2) - _player_pos).normalized()
		_bolts.append({"pos": _player_pos, "vel": dir * spd, "dmg": shot_dmg, "life": BOLT_LIFE, "kind": kind, "base_spd": spd})

func _trigger_wave_kind(r: float, dmg: float, kind: String = "wave") -> void:
	_play_skill_sfx("skill_elec_wave" if kind == "elec_wave" else "skill_wave", -5.0, 1.0, 0.2)
	var vp: Rect2 = get_viewport_rect()
	for i in range(_enemies.size() - 1, -1, -1):
		if i < 0 or i >= _enemies.size():
			continue
		var ep: Vector2 = _enemies[i]["pos"] as Vector2
		var sp: Vector2 = ep - _camera.position + vp.size * 0.5
		if not vp.grow(60.0).has_point(sp): continue
		if ep.distance_to(_player_pos) <= r:
			_hit_enemy(i, dmg)
	_waves.append({"pos": _player_pos, "r": 0.0, "max_r": r, "life": 0.55, "max_life": 0.55, "kind": kind})

func _do_capy_charge_shadow(dmg: float) -> void:
	if _enemies.is_empty():
		return
	# Find nearest enemy
	var nearest_idx: int = 0
	var nearest_dist: float = INF
	for i in range(_enemies.size()):
		if i < 0 or i >= _enemies.size():
			continue
		var e: Dictionary = _enemies[i]
		var ed: float = _player_pos.distance_to(e.get("pos", Vector2.ZERO) as Vector2)
		if ed < nearest_dist:
			nearest_dist = ed
			nearest_idx = i
	# Create shadow rush toward that enemy
	if nearest_idx >= 0 and nearest_idx < _enemies.size():
		var target_pos: Vector2 = (_enemies[nearest_idx].get("pos", Vector2.ZERO) as Vector2)
		var rush_dir: Vector2 = (target_pos - _player_pos).normalized()
		_capy_charge_rushes.append({
			"pos": _player_pos,
			"dir": rush_dir,
			"life": 0.6,
			"max_life": 0.6,
			"dmg": dmg,
			"speed": 1200.0,
			"hit_enemies": [],
			"id": randi(),
		})
		# Grant temporary invincibility during charge
		_player_iframes += 0.65
		_play_skill_sfx("skill_capy_charge", -3.0, 1.0, 0.5)

func _update_capy_charge_rushes(delta: float) -> void:
	for i in range(_capy_charge_rushes.size() - 1, -1, -1):
		if i < 0 or i >= _capy_charge_rushes.size():
			continue
		var rush: Dictionary = _capy_charge_rushes[i]
		rush["life"] = (rush["life"] as float) - delta
		var rush_pos: Vector2 = (rush["pos"] as Vector2) + (rush["dir"] as Vector2) * (rush["speed"] as float) * delta
		rush["pos"] = rush_pos
		# Check collision with enemies - flow through all
		for j in range(_enemies.size() - 1, -1, -1):
			if j < 0 or j >= _enemies.size():
				continue
			var e: Dictionary = _enemies[j]
			var ep: Vector2 = e.get("pos", Vector2.ZERO) as Vector2
			var enemy_id: int = e.get("id", -1) as int
			var hit_list: Array = rush.get("hit_enemies", []) as Array
			if ep.distance_to(rush_pos) < 80.0 and enemy_id not in hit_list:
				_hit_enemy(j, rush["dmg"] as float)
				hit_list.append(enemy_id)
				rush["hit_enemies"] = hit_list
		if (rush["life"] as float) <= 0.0:
			_capy_charge_rushes.remove_at(i)

func _do_stampede_charge(dmg: float, level: int) -> void:
	# Spawn 3 + level centipedes that hunt nearest enemies
	var num_centipedes: int = max(2, 2 + int(floor(float(level) * 0.5)))
	var base_dmg: float = dmg * (0.42 + float(level) * 0.06)  # Damage scales with level
	
	for c in range(num_centipedes):
		var spawn_angle: float = float(c) * TAU / float(num_centipedes)  # Spread out in different directions
		var spawn_offset: Vector2 = Vector2(cos(spawn_angle), sin(spawn_angle)) * 80.0
		_stampedes.append({
			"start_pos": _player_pos,
			"pos": _player_pos + spawn_offset,
			"spawn_angle": spawn_angle,  # Remember direction for visual
			"target_id": -1,  # Will track nearest enemy
			"elapsed": 0.0,
			"life": 2.5,
			"max_life": 2.5,
			"dmg": base_dmg,
			"speed": 270.0 + float(level) * 16.0,  # Speed increases with level
			"hit_enemies": [],
			"has_hit": false,  # Track if this centipede has hit an enemy
			"id": randi(),
		})
	_play_skill_sfx("skill_stampede", -3.0, 1.0, 0.5)

func _update_stampedes(delta: float) -> void:
	var vp: Rect2 = get_viewport_rect()
	var screen_edge_margin: float = 200.0
	for i in range(_stampedes.size() - 1, -1, -1):
		if i < 0 or i >= _stampedes.size():
			continue
		var centipede: Dictionary = _stampedes[i]
		centipede["elapsed"] = (centipede["elapsed"] as float) + delta
		centipede["life"] = (centipede["life"] as float) - delta
		
		var cent_pos: Vector2 = centipede.get("pos", _player_pos) as Vector2
		
		# Find nearest enemy to hunt (update target every frame)
		var best_dist: float = 99999.0
		var best_idx: int = -1
		for j in range(_enemies.size()):
			if j < 0 or j >= _enemies.size():
				continue
			var ep: Vector2 = (_enemies[j].get("pos", Vector2.ZERO)) as Vector2
			var d: float = cent_pos.distance_to(ep)
			if d < best_dist:
				best_dist = d
				best_idx = j
		
		# Chase nearest enemy or move forward from start position
		if best_idx >= 0 and best_idx < _enemies.size():
			var target_pos: Vector2 = (_enemies[best_idx].get("pos", Vector2.ZERO)) as Vector2
			var dir: Vector2 = (target_pos - cent_pos).normalized()
			cent_pos += dir * (centipede["speed"] as float) * delta
		else:
			# No enemies found, move in direction away from player
			var start_pos: Vector2 = centipede.get("start_pos", _player_pos) as Vector2
			var outward_dir: Vector2 = (cent_pos - start_pos).normalized()
			if outward_dir.length_squared() < 0.01:
				outward_dir = Vector2(cos(float(i) * TAU / 3.0), sin(float(i) * TAU / 3.0))
			cent_pos += outward_dir * (centipede["speed"] as float) * delta
		
		centipede["pos"] = cent_pos
		
		# Check if reached screen edge and fade out
		var cam_pos: Vector2 = _camera.position
		var screen_pos: Vector2 = cent_pos - cam_pos + vp.size * 0.5
		if not vp.grow(screen_edge_margin).has_point(screen_pos):
			centipede["life"] = min((centipede["life"] as float), 0.4)
		
		# Check collision with enemies - disappear on first hit
		var hit_this_frame: bool = false
		for j in range(_enemies.size() - 1, -1, -1):
			if j < 0 or j >= _enemies.size():
				continue
			var e: Dictionary = _enemies[j]
			var ep: Vector2 = e.get("pos", Vector2.ZERO) as Vector2
			var dist: float = ep.distance_to(cent_pos)
			
			# Hit detected - damage and disappear
			if dist < 60.0:
				_hit_enemy(j, centipede["dmg"] as float * 1.0)
				centipede["has_hit"] = true
				hit_this_frame = true
				break  # Only hit first enemy, then disappear
			elif dist < 100.0:
				_hit_enemy(j, centipede["dmg"] as float * 0.75)
				centipede["has_hit"] = true
				hit_this_frame = true
				break  # Only hit first enemy, then disappear
		
		if hit_this_frame:
			centipede["life"] = 0.0  # Disappear immediately after hitting
		if (centipede["life"] as float) <= 0.0:
			_stampedes.remove_at(i)

func _trigger_aoe(kind: String, dmg: float, slow: float) -> void:
	# Trigger SkillMgr animations/effects for AOE skills (updated for new JSON format)
	if SkillMgr and SkillMgr.cast_skill:
		# Map old skill IDs to new JSON skill names
		var skill_name = _get_json_skill_name(kind)
		if SkillMgr.cast_skill(skill_name, self):
			print("[Match] ✓ Triggered skill effect: %s" % skill_name)
		else:
			print("[Match] ✗ Failed to trigger skill: %s (ID: %s)" % [skill_name, kind])
	
	_play_skill_sfx("skill_" + kind, -3.0, 1.0, 0.5)
	var vp: Rect2 = get_viewport_rect()
	for i in range(_enemies.size() - 1, -1, -1):
		var ep: Vector2 = (_enemies[i]["pos"] as Vector2)
		var sp: Vector2 = ep - _camera.position + vp.size * 0.5
		if not vp.grow(40.0).has_point(sp): continue
		_hit_enemy(i, dmg)
		if slow > 0.0 and i < _enemies.size():
			var aoe_base_s: float = (_enemies[i]["base_spd"] as float)
			var aoe_min_s: float  = max(aoe_base_s * max(0.50 - float(_level) * 0.012, 0.20), 30.0)
			_enemies[i]["spd"] = max((_enemies[i]["spd"] as float) * (1.0 - slow), aoe_min_s)
	_aoe_flashes.append({"life": 1.4, "max_life": 1.4, "kind": kind})

## Convert old internal skill ID to new JSON skill name
## Maps old skill slots (e.g., "blizzard", "orb") to new proper names (e.g., "Blizzard", "Capy Orb")
func _get_json_skill_name(skill_id: String) -> String:
	var mapping = {
		# Common (7/7 updated)
		"orb": "Capy Orb",
		"bolt": "Capy Bolt",
		"ice_orb": "Ice Orb",
		"mud_aura": "Mud Aura",
		"squeal_wave": "Squeal Wave",
		"calm": "Capy Calm",
		"xp_bonus": "XP Magnet",
		
		# Wizard (4/4 updated)
		"fireball": "Fireball",
		"elec_wave": "Elec Shockwave",
		"wave": "Hurricane",
		"blizzard": "Blizzard",
		
		# Archer (4/4 updated)
		"arrow": "Arrow Shot",
		"split_arrow": "Split Arrow",
		"pierce_arrow": "Pierce Arrow",
		"sky_fall": "Sky Fall",
		
		# Pending skills (not yet in updated JSON)
		# Assassin (4 pending)
		"star_knife": "Star Knife",
		"knife_storm": "Knife Storm",
		"boomerang": "Boomerang Star",
		"seven_slash": "7 Slash",
		
		# Special (2 pending)
		"swirl_tangerine": "Swirl Tangerine",
		"capy_brown": "Capy Brown",
	}
	
	return mapping.get(skill_id, skill_id)  # Return mapped name or original if not in mapping

func _fire_shooter_boss_pattern(boss: Dictionary) -> void:
	var boss_pos: Vector2 = boss["pos"] as Vector2
	var aim: Vector2 = (_player_pos - boss_pos).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT
	var base_dmg: float = boss["dmg"] as float
	match randi() % 3:
		0:
			_boss_projs.append({
				"kind": "homing",
				"pos": boss_pos,
				"vel": aim * 245.0,
				"speed": 245.0,
				"turn_rate": SHOOTER_HOMING_TURN_RATE,
				"dmg": base_dmg * 0.82,
				"life": SHOOTER_HOMING_LIFE,
			})
		1:
			for angle_offset in [-0.24, 0.0, 0.24]:
				var dir: Vector2 = aim.rotated(float(angle_offset))
				_boss_projs.append({
					"kind": "straight",
					"pos": boss_pos,
					"vel": dir * 300.0,
					"dmg": base_dmg * 0.62,
					"life": SHOOTER_SPREAD_LIFE,
				})
		_:
			for i in 3:
				var spread_angle: float = float(i - 1) * 0.9 + randf_range(-0.22, 0.22)
				var target_offset: Vector2 = aim.rotated(spread_angle) * randf_range(45.0, 105.0)
				var side_offset: Vector2 = Vector2(-aim.y, aim.x) * randf_range(-70.0, 70.0)
				var target_pos: Vector2 = _player_pos + target_offset + side_offset
				_mortar_strikes.append({
					"pos": target_pos,
					"life": SHOOTER_MORTAR_WARN_TIME,
					"max_life": SHOOTER_MORTAR_WARN_TIME,
					"dmg": base_dmg * 0.55,
					"r": 40.0,
					"launch": boss_pos,
				})

func _update_lava_boss_special(boss: Dictionary, delta: float) -> void:
	if not boss.has("lava_state"):
		boss["lava_state"] = "idle"
		boss["lava_state_t"] = 0.0
		boss["lava_trail_t"] = 0.0
		boss["reflect_cd"] = 0.0
	boss["reflect_cd"] = max((boss.get("reflect_cd", 0.0) as float) - delta, 0.0)
	var state: String = boss.get("lava_state", "idle") as String
	if state != "idle":
		boss["lava_state_t"] = (boss.get("lava_state_t", 0.0) as float) - delta
		if (boss["lava_state_t"] as float) <= 0.0:
			boss["lava_state"] = "idle"
			boss["shield_active"] = false
			boss["special_timer"] = 0.0
		return
	boss["special_timer"] = (boss["special_timer"] as float) + delta
	if (boss["special_timer"] as float) < 1.3:
		return
	boss["special_timer"] = 0.0
	match randi() % 3:
		0:
			_start_lava_line_attack(boss)
		1:
			_start_lava_shield(boss)
		_:
			_start_lava_charge(boss)

func _start_lava_line_attack(boss: Dictionary) -> void:
	var boss_pos: Vector2 = boss["pos"] as Vector2
	var aim: Vector2 = (_player_pos - boss_pos).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT
	boss["lava_state"] = "slam"
	boss["lava_state_t"] = LAVA_LINE_WARN_TIME
	_lava_lines.append({
		"start": boss_pos + aim * (boss["r"] as float) * 0.45,
		"dir": aim,
		"len": 760.0,
		"width": 34.0,
		"life": LAVA_LINE_WARN_TIME + LAVA_LINE_ERUPT_TIME,
		"max_life": LAVA_LINE_WARN_TIME + LAVA_LINE_ERUPT_TIME,
		"warn_life": LAVA_LINE_WARN_TIME,
		"dmg": (boss["dmg"] as float) * 1.35,
		"tick_t": 0.0,
	})

func _start_lava_shield(boss: Dictionary) -> void:
	boss["lava_state"] = "shield"
	boss["lava_state_t"] = 3.0
	boss["shield_active"] = true
	boss["reflect_cd"] = 0.0

func _start_lava_charge(boss: Dictionary) -> void:
	var boss_pos: Vector2 = boss["pos"] as Vector2
	var aim: Vector2 = (_player_pos - boss_pos).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT
	boss["lava_state"] = "charge"
	boss["lava_state_t"] = LAVA_CHARGE_TIME
	boss["charge_dir"] = aim
	boss["charge_speed"] = 430.0
	boss["lava_trail_t"] = 0.0

func _add_lava_charge_trail(boss: Dictionary, delta: float) -> void:
	boss["lava_trail_t"] = (boss.get("lava_trail_t", 0.0) as float) - delta
	if (boss["lava_trail_t"] as float) > 0.0:
		return
	boss["lava_trail_t"] = 0.16
	_lava_pools.append({
		"kind": "lava_charge",
		"pos": boss["pos"] as Vector2,
		"r": 36.0,
		"life": LAVA_CHARGE_TRAIL_LIFE,
		"max_life": LAVA_CHARGE_TRAIL_LIFE,
		"dmg_per_tick": (boss["dmg"] as float) * 0.45,
		"tick_t": 0.0,
	})

func _reflect_lava_shield(boss: Dictionary) -> void:
	if (boss.get("reflect_cd", 0.0) as float) > 0.0:
		return
	boss["reflect_cd"] = 0.35
	var boss_pos: Vector2 = boss["pos"] as Vector2
	var target: Vector2 = _player_pos
	var aim: Vector2 = (target - boss_pos).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT
	var speed: float = 380.0
	var travel_time: float = max(boss_pos.distance_to(target) / speed, 0.35)
	_boss_projs.append({
		"kind": "lava_reflect",
		"pos": boss_pos,
		"vel": aim * speed,
		"target": target,
		"dmg": (boss["dmg"] as float) * 1.05,
		"life": travel_time + 0.25,
		"explode_r": 58.0,
	})

# ═════════════════════════════════════════════════════════════════════════════
# ABYSS GATE WARDEN SKILLS
# ═════════════════════════════════════════════════════════════════════════════

func _update_abyss_warden_special(boss: Dictionary, delta: float) -> void:
	if not boss.has("warden_state"):
		boss["warden_state"] = "idle"
		boss["warden_state_t"] = 0.0
		boss["special_timer"] = 0.0
		boss["skill_cycle_num"] = -1
	
	boss["special_timer"] = (boss["special_timer"] as float) + delta
	var st: float = boss["special_timer"] as float
	
	# Phase 2 and 3 transitions based on HP
	var hp_ratio: float = (boss["hp"] as float) / (boss["max_hp"] as float)
	var phase: int = 1 if hp_ratio > 0.66 else (2 if hp_ratio > 0.33 else 3)
	boss["phase"] = phase
	
	var cycle_num: int = int(st / 7.5)
	if cycle_num != (boss.get("skill_cycle_num", -1) as int):
		boss["skill_cycle_num"] = cycle_num
		boss["chain_fired"] = false
		boss["pulse_fired"] = false
		boss["summon_fired"] = false
	var skill_cycle: float = fmod(st, 7.5)
	var chapter_five_king: bool = str(boss.get("story_tag", "")) == "abyss_king" and _chapter_five != null
	if skill_cycle < 2.25 and not boss.get("chain_fired", false):
		if not chapter_five_king or _chapter_five.boss_ability_enabled("mirrored_projectiles"):
			_fire_abyss_chain(boss, phase)
		boss["chain_fired"] = true
	elif skill_cycle >= 2.25 and skill_cycle < 4.5 and not boss.get("pulse_fired", false):
		if not chapter_five_king or _chapter_five.boss_ability_enabled("corruption"):
			_fire_abyss_pulse(boss, phase)
		boss["pulse_fired"] = true
	elif skill_cycle >= 4.5 and not boss.get("summon_fired", false):
		if not chapter_five_king or _chapter_five.boss_ability_enabled("summons"):
			_fire_abyss_summon(boss)
		boss["summon_fired"] = true

func _fire_abyss_chain(boss: Dictionary, phase: int) -> void:
	var boss_pos: Vector2 = boss["pos"] as Vector2
	var num_chains: int = 4 + phase
	var base_dmg: float = boss["dmg"] as float
	
	for i in num_chains:
		var angle: float = float(i) / float(num_chains) * TAU
		var chain_dir: Vector2 = Vector2(cos(angle), sin(angle))
		_boss_chains.append({
			"boss_pos": boss_pos,
			"direction": chain_dir,
			"length": 120.0,
			"state": "extend",
			"state_t": 0.0,
			"retract_t": 0.8,
			"total_t": 0.0,
			"dmg": base_dmg * 1.2,
			"corrupted": phase >= 2,
		})

func _fire_abyss_pulse(boss: Dictionary, phase: int) -> void:
	var boss_pos: Vector2 = boss["pos"] as Vector2
	var base_dmg: float = boss["dmg"] as float
	var num_waves: int = 1 if phase == 1 else 2
	
	for w in num_waves:
		var delay: float = float(w) * 0.3
		_mortar_strikes.append({
			"pos": boss_pos,
			"r": 160.0,
			"life": delay + 0.6,
			"max_life": delay + 0.6,
			"dmg": base_dmg * 1.3,
			"kind": "abyss_pulse",
			"warning_life": delay,
		})

func _fire_abyss_summon(boss: Dictionary) -> void:
	# Summon 2-3 corrupted enemies, max 6 total
	if (_enemies.size() as int) > 10:
		return
	# Calculate wave scaling from boss's hp_mult (back out from hp_mult = 32.0 * ws)
	var ws: float = (boss.get("hp_mult", 32.0) as float) / 32.0
	var num_spawn: int = 2 + randi() % 2
	for _i in num_spawn:
		var spawn_angle: float = randf() * TAU
		var spawn_dist: float = 200.0
		var spawn_pos: Vector2 = (boss["pos"] as Vector2) + Vector2(cos(spawn_angle), sin(spawn_angle)) * spawn_dist
		var summon_kind: String = ["normal", "normal_tank", "normal_fast"][randi() % 3]
		_spawn_enemy_from(_make_enemy_data(summon_kind, ws))
		_enemies[-1]["pos"] = spawn_pos
		_enemies[-1]["corrupted"] = true

# ═════════════════════════════════════════════════════════════════════════════
# PRISM TRIARCH SKILLS
# ═════════════════════════════════════════════════════════════════════════════

func _update_prism_triarch_special(boss: Dictionary, delta: float) -> void:
	if not boss.has("prism_state"):
		boss["prism_state"] = "idle"
		boss["prism_angle"] = 0.0
		boss["special_timer"] = 0.0
	
	boss["special_timer"] = (boss["special_timer"] as float) + delta
	boss["prism_angle"] = (boss["prism_angle"] as float) + delta * 1.2
	
	var st: float = boss["special_timer"] as float
	var cycle_num: int = int(st / 6.0)
	if cycle_num != (boss.get("skill_cycle_num", -1) as int):
		boss["skill_cycle_num"] = cycle_num
		boss["link_fired"] = false
		boss["barrage_fired"] = false
		boss["link2_fired"] = false
		boss["collapse_fired"] = false
	var skill_cycle: float = fmod(st, 6.0)
	
	# Skill rotation: Link (1.5s) → Barrage (1.5s) → Link (1.5s) → Ultimate (1.5s)
	if skill_cycle < 1.5 and not boss.get("link_fired", false):
		_fire_prism_link(boss)
		boss["link_fired"] = true
	elif skill_cycle >= 1.5 and skill_cycle < 3.0 and not boss.get("barrage_fired", false):
		_fire_prism_barrage(boss)
		boss["barrage_fired"] = true
	elif skill_cycle >= 3.0 and skill_cycle < 4.5 and not boss.get("link2_fired", false):
		_fire_prism_link(boss)
		boss["link2_fired"] = true
	elif skill_cycle >= 4.5 and not boss.get("collapse_fired", false):
		_fire_prism_collapse(boss)
		boss["collapse_fired"] = true

func _fire_prism_link(boss: Dictionary) -> void:
	var boss_pos: Vector2 = boss["pos"] as Vector2
	var base_dmg: float = boss["dmg"] as float
	var angle: float = boss.get("prism_angle", 0.0) as float
	
	# Create 3 prism nodes in triangle formation
	var nodes: Array[Vector2] = []
	for i in 3:
		var node_angle: float = angle + float(i) / 3.0 * TAU
		var node_pos: Vector2 = boss_pos + Vector2(cos(node_angle), sin(node_angle)) * 85.0
		nodes.append(node_pos)
	
	_prism_zones.append({
		"boss_pos": boss_pos,
		"nodes": nodes,
		"state": "forming",
		"state_t": 0.0,
		"duration": 2.0,
		"dmg": base_dmg * 1.1,
		"rotating": false,
	})

func _fire_prism_barrage(boss: Dictionary) -> void:
	var boss_pos: Vector2 = boss["pos"] as Vector2
	var base_dmg: float = boss["dmg"] as float
	var aim: Vector2 = (_player_pos - boss_pos).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT
	
	# Fire beam that splits into 3, then 6 rays
	for split_num in [1, 3, 6]:
		var delay: float = 0.15 * float(split_num - 1) / 2.0
		for i in split_num:
			var angle_offset: float = (float(i) - float(split_num - 1) * 0.5) * (PI / 6.0)
			var dir: Vector2 = aim.rotated(angle_offset)
			_boss_projs.append({
				"kind": "prism_beam",
				"pos": boss_pos,
				"vel": dir * 280.0,
				"dmg": base_dmg * 0.75,
				"life": 3.0,
				"delay": delay,
			})

func _fire_prism_collapse(boss: Dictionary) -> void:
	var boss_pos: Vector2 = boss["pos"] as Vector2
	var base_dmg: float = boss["dmg"] as float
	
	_prism_zones.append({
		"boss_pos": boss_pos,
		"state": "collapse",
		"state_t": 0.0,
		"collapse_duration": 2.5,
		"dmg": base_dmg * 2.0,
		"rotating": true,
	})

# ═════════════════════════════════════════════════════════════════════════════
# BLIGHT VINE TYRANT SKILLS
# ═════════════════════════════════════════════════════════════════════════════

func _update_blight_tyrant_special(boss: Dictionary, delta: float) -> void:
	if not boss.has("blight_state"):
		boss["blight_state"] = "idle"
		boss["special_timer"] = 0.0
	
	boss["special_timer"] = (boss["special_timer"] as float) + delta
	
	var st: float = boss["special_timer"] as float
	var cycle_num: int = int(st / 6.75)
	if cycle_num != (boss.get("skill_cycle_num", -1) as int):
		boss["skill_cycle_num"] = cycle_num
		boss["lash_fired"] = false
		boss["pods_fired"] = false
		boss["lash2_fired"] = false
		boss["bloom_fired"] = false
	var skill_cycle: float = fmod(st, 6.75)
	
	# Skill rotation: Lash (1.5s) → Pods (1.5s) → Lash (1.5s) → Bloom (2.25s)
	if skill_cycle < 1.5 and not boss.get("lash_fired", false):
		_fire_thorn_lash(boss)
		boss["lash_fired"] = true
	elif skill_cycle >= 1.5 and skill_cycle < 3.0 and not boss.get("pods_fired", false):
		_fire_venom_pods(boss)
		boss["pods_fired"] = true
	elif skill_cycle >= 3.0 and skill_cycle < 4.5 and not boss.get("lash2_fired", false):
		_fire_thorn_lash(boss)
		boss["lash2_fired"] = true
	elif skill_cycle >= 4.5 and not boss.get("bloom_fired", false):
		_fire_corrupted_bloom(boss)
		boss["bloom_fired"] = true

func _fire_thorn_lash(boss: Dictionary) -> void:
	var boss_pos: Vector2 = boss["pos"] as Vector2
	var base_dmg: float = boss["dmg"] as float
	var aim: Vector2 = (_player_pos - boss_pos).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.DOWN
	
	# 3 cone directions: left, center, right
	for cone_offset in [-0.5, 0.0, 0.5]:
		var dir: Vector2 = aim.rotated(float(cone_offset))
		_boss_projs.append({
			"kind": "thorn",
			"pos": boss_pos,
			"vel": dir * 240.0,
			"dmg": base_dmg * 0.9,
			"life": 2.5,
		})
		
		# Create thorn patch where it lands
		_thorn_patches.append({
			"pos": boss_pos + dir * 150.0,
			"r": 35.0,
			"life": 3.0,
			"max_life": 3.0,
			"dmg_per_tick": base_dmg * 0.4,
			"tick_t": 0.0,
		})

func _fire_venom_pods(boss: Dictionary) -> void:
	var boss_pos: Vector2 = boss["pos"] as Vector2
	var num_pods: int = 4 + randi() % 3
	
	for _i in num_pods:
		var angle: float = randf() * TAU
		var speed: float = randf_range(150.0, 220.0)
		_venom_pods.append({
			"pos": boss_pos,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"life": 2.0,
			"max_life": 2.0,
			"pop_t": 0.0,
			"dmg": boss["dmg"] as float * 1.1,
		})

func _fire_corrupted_bloom(boss: Dictionary) -> void:
	var boss_pos: Vector2 = boss["pos"] as Vector2
	var base_dmg: float = boss["dmg"] as float
	
	# Create expanding root eruptions
	var num_roots: int = 8
	for i in num_roots:
		var angle: float = float(i) / float(num_roots) * TAU
		var root_pos: Vector2 = boss_pos + Vector2(cos(angle), sin(angle)) * 200.0
		_mortar_strikes.append({
			"pos": root_pos,
			"r": 50.0,
			"life": 1.2,
			"max_life": 1.2,
			"dmg": base_dmg * 1.4,
			"kind": "blight_root",
			"warning_life": 0.6,
		})

# ═════════════════════════════════════════════════════════════════════════════
# THUNDERFORGE BEHEMOTH SKILLS
# ═════════════════════════════════════════════════════════════════════════════

func _update_thunderforge_special(boss: Dictionary, delta: float) -> void:
	if not boss.has("storm_state"):
		boss["storm_state"] = "idle"
		boss["special_timer"] = 0.0
	
	boss["special_timer"] = (boss["special_timer"] as float) + delta
	var chapter_four_boss: bool = str(boss.get("story_tag", "")) == "c4_thunderforge_behemoth" and _chapter_four != null
	if chapter_four_boss and not bool(boss.get("system_1_disabled", false)):
		boss["hp"] = minf(float(boss.get("max_hp", boss.hp)), float(boss.hp) + float(boss.get("max_hp", boss.hp)) * 0.0025 * delta)
	
	var st: float = boss["special_timer"] as float
	var cycle_duration: float = 6.2 if chapter_four_boss and _chapter_four.flag("shutdown_complete") else 7.5
	var cycle_num: int = int(st / cycle_duration)
	if cycle_num != (boss.get("skill_cycle_num", -1) as int):
		boss["skill_cycle_num"] = cycle_num
		boss["hammer_fired"] = false
		boss["coil_fired"] = false
		boss["hammer2_fired"] = false
		boss["cataclysm_fired"] = false
	var skill_cycle: float = fmod(st, cycle_duration)
	
	# Skill rotation: Hammer (1.5s) → Coil (1.5s) → Hammer (1.5s) → Cataclysm (3s)
	if skill_cycle < 1.5 and not boss.get("hammer_fired", false):
		if not chapter_four_boss or not bool(boss.get("system_0_disabled", false)): _fire_thunder_hammer(boss)
		boss["hammer_fired"] = true
	elif skill_cycle >= 1.5 and skill_cycle < 3.0 and not boss.get("coil_fired", false):
		if not chapter_four_boss or not bool(boss.get("system_2_disabled", false)): _fire_arc_coil(boss)
		boss["coil_fired"] = true
	elif skill_cycle >= 3.0 and skill_cycle < 4.5 and not boss.get("hammer2_fired", false):
		if not chapter_four_boss or not bool(boss.get("system_0_disabled", false)): _fire_thunder_hammer(boss)
		boss["hammer2_fired"] = true
	elif skill_cycle >= 4.5 and not boss.get("cataclysm_fired", false):
		if not chapter_four_boss or not bool(boss.get("system_3_disabled", false)): _fire_storm_cataclysm(boss)
		boss["cataclysm_fired"] = true

func _fire_thunder_hammer(boss: Dictionary) -> void:
	var boss_pos: Vector2 = boss["pos"] as Vector2
	var base_dmg: float = boss["dmg"] as float
	
	# X-shaped fissure pattern (4 lines)
	for angle_base in [0.0, PI / 4.0]:
		for offset in [-1.0, 1.0]:
			var angle: float = angle_base + offset * (PI / 8.0)
			var fissure_pos: Vector2 = boss_pos + Vector2(cos(angle), sin(angle)) * 140.0
			_mortar_strikes.append({
				"pos": fissure_pos,
				"r": 60.0,
				"life": 0.8,
				"max_life": 0.8,
				"dmg": base_dmg * 1.5,
				"kind": "lightning_strike",
				"warning_life": 0.4,
			})

func _fire_arc_coil(boss: Dictionary) -> void:
	var boss_pos: Vector2 = boss["pos"] as Vector2
	var num_balls: int = 6 + randi() % 5
	
	for _i in num_balls:
		var angle: float = randf() * TAU
		var orbit_r: float = randf_range(180.0, 280.0)
		_lightning_markers.append({
			"pos": boss_pos + Vector2(cos(angle), sin(angle)) * orbit_r,
			"angle": angle,
			"orbit_r": orbit_r,
			"life": 4.0,
			"max_life": 4.0,
			"charge_t": 0.0,
			"dmg": boss["dmg"] as float * 0.9,
		})

func _fire_storm_cataclysm(boss: Dictionary) -> void:
	var boss_pos: Vector2 = boss["pos"] as Vector2
	var base_dmg: float = boss["dmg"] as float
	
	# Random lightning markers that intensify
	var num_markers: int = 12
	for _i in num_markers:
		var angle: float = randf() * TAU
		var dist: float = randf_range(100.0, 250.0)
		_lightning_markers.append({
			"pos": boss_pos + Vector2(cos(angle), sin(angle)) * dist,
			"cataclysm": true,
			"life": 3.5,
			"max_life": 3.5,
			"dmg": base_dmg * 1.6,
			"phase": 0,
		})

# ═════════════════════════════════════════════════════════════════════════════
# BOSS SKILL EFFECT UPDATES
# ═════════════════════════════════════════════════════════════════════════════

func _update_boss_chains(delta: float) -> void:
	for i in range(_boss_chains.size() - 1, -1, -1):
		var chain: Dictionary = _boss_chains[i]
		chain["total_t"] = (chain["total_t"] as float) + delta
		var state: String = chain.get("state", "extend") as String
		
		if state == "extend":
			chain["state_t"] = (chain["state_t"] as float) + delta
			if (chain["state_t"] as float) >= 0.8:
				chain["state"] = "retract"
				chain["state_t"] = 0.0
		elif state == "retract":
			chain["state_t"] = (chain["state_t"] as float) + delta
			var retract_t: float = chain.get("retract_t", 0.8) as float
			if (chain["state_t"] as float) >= retract_t:
				# Check player damage during retract
				if _player_iframes <= 0.0:
					var chain_end: Vector2 = (chain["boss_pos"] as Vector2) + (chain["direction"] as Vector2) * (chain["length"] as float)
					if _player_pos.distance_to(chain_end) < PLAYER_R + 20.0:
						_damage_player(chain["dmg"] as float, 0.45)
				_boss_chains.remove_at(i)
				continue
		
		# Check if player touches chain during extension
		if state == "extend" and _player_iframes <= 0.0:
			var chain_pos: Vector2 = (chain["boss_pos"] as Vector2) + (chain["direction"] as Vector2) * (chain["length"] as float) * ((chain["state_t"] as float) / 0.8)
			if _player_pos.distance_to(chain_pos) < PLAYER_R + 15.0:
				_damage_player(chain["dmg"] as float * 0.6, 0.3)

func _update_prism_zones(delta: float) -> void:
	for i in range(_prism_zones.size() - 1, -1, -1):
		var zone: Dictionary = _prism_zones[i]
		var state: String = zone.get("state", "forming") as String
		zone["state_t"] = (zone["state_t"] as float) + delta
		
		if state == "forming":
			var duration: float = zone.get("duration", 2.0) as float
			if (zone["state_t"] as float) >= duration:
				_prism_zones.remove_at(i)
				continue
			
			# Damage check - only if player is within zone area
			if _player_iframes <= 0.0:
				var boss_pos: Vector2 = zone.get("boss_pos", Vector2.ZERO) as Vector2
				var nodes: Array = zone.get("nodes", []) as Array
				if nodes.size() >= 3:
					# Check if player is within the triangle zone (distance to center)
					var zone_center: Vector2 = Vector2.ZERO
					for node in nodes:
						zone_center += node as Vector2
					zone_center /= 3.0
					var zone_radius: float = 120.0
					if _player_pos.distance_to(zone_center) < zone_radius:
						_damage_player(zone["dmg"] as float * delta, 0.1)
		
		elif state == "collapse":
			var collapse_duration: float = zone.get("collapse_duration", 2.5) as float
			if (zone["state_t"] as float) >= collapse_duration:
				# Final shockwave damage
				if _player_iframes <= 0.0 and _player_pos.distance_to(zone["boss_pos"] as Vector2) < 250.0:
					_damage_player(zone["dmg"] as float * 0.5, 0.4)
				_prism_zones.remove_at(i)

func _update_venom_pods(delta: float) -> void:
	for i in range(_venom_pods.size() - 1, -1, -1):
		var pod: Dictionary = _venom_pods[i]
		pod["pos"] = (pod["pos"] as Vector2) + (pod["vel"] as Vector2) * delta * 0.85  # Friction
		pod["life"] = (pod["life"] as float) - delta
		
		if (pod["life"] as float) <= 0.0:
			# Pop into poison cloud
			_venom_pools.append({
				"kind": "venom_cloud",
				"pos": pod["pos"] as Vector2,
				"r": 50.0,
				"life": 2.5,
				"max_life": 2.5,
				"dmg_per_tick": pod["dmg"] as float * 0.5,
				"tick_t": 0.0,
			})
			_venom_pods.remove_at(i)
			continue
		
		# Player collision
		if _player_iframes <= 0.0 and (pod["pos"] as Vector2).distance_to(_player_pos) < PLAYER_R + 15.0:
			_damage_player(pod["dmg"] as float * 0.4, 0.25)
			_venom_pods.remove_at(i)

func _update_lightning_markers(delta: float) -> void:
	for i in range(_lightning_markers.size() - 1, -1, -1):
		var marker: Dictionary = _lightning_markers[i]
		marker["life"] = (marker["life"] as float) - delta
		
		if marker.get("cataclysm", false):
			marker["charge_t"] = (marker.get("charge_t", 0.0) as float) + delta
			var max_life: float = marker.get("max_life", 3.5) as float
			var elapsed: float = max_life - (marker["life"] as float)
			var phase: int = int(elapsed / (max_life / 3.0))
			marker["phase"] = phase
			
			if (marker["life"] as float) <= 0.0:
				if _player_iframes <= 0.0 and _player_pos.distance_to(marker["pos"] as Vector2) < 100.0 + (float(phase) * 20.0):
					_damage_player(marker["dmg"] as float, 0.3)
				_lightning_markers.remove_at(i)
		else:
			# Orbiting lightning balls
			var elapsed: float = (marker.get("max_life", 4.0) as float) - (marker["life"] as float)
			var dmg_threshold: float = (marker.get("max_life", 4.0) as float) * 0.75
			if elapsed >= dmg_threshold and _player_iframes <= 0.0:
				if _player_pos.distance_to(marker["pos"] as Vector2) < 150.0:
					_damage_player(marker["dmg"] as float * 0.3, 0.2)
			
			if (marker["life"] as float) <= 0.0:
				_lightning_markers.remove_at(i)

func _update_thorn_patches(delta: float) -> void:
	for i in range(_thorn_patches.size() - 1, -1, -1):
		var patch: Dictionary = _thorn_patches[i]
		patch["life"] = (patch["life"] as float) - delta
		patch["tick_t"] = (patch.get("tick_t", 0.0) as float) + delta
		
		if (patch["tick_t"] as float) >= 0.4:
			if _player_iframes <= 0.0 and _player_pos.distance_to(patch["pos"] as Vector2) < PLAYER_R + (patch["r"] as float):
				_damage_player(patch["dmg_per_tick"] as float, 0.2)
			patch["tick_t"] = 0.0
		
		if (patch["life"] as float) <= 0.0:
			_thorn_patches.remove_at(i)

# ═════════════════════════════════════════════════════════════════════════════
# ENTITY UPDATES
# ═════════════════════════════════════════════════════════════════════════════

func _update_enemies(delta: float) -> void:
	for i in range(_enemies.size() - 1, -1, -1):
		var e: Dictionary = _enemies[i]
		if (e["iframes"] as float) > 0.0:
			e["iframes"] = (e["iframes"] as float) - delta
		e["tg_mark_t"] = max((e.get("tg_mark_t", 0.0) as float) - delta, 0.0)
		e["poison_t"]  = max((e.get("poison_t",  0.0) as float) - delta, 0.0)
		e["chilled_t"] = max((e.get("chilled_t", 0.0) as float) - delta, 0.0)
		e["burn_t"] = max((e.get("burn_t", 0.0) as float) - delta, 0.0)
		e["mud_t"] = max((e.get("mud_t", 0.0) as float) - delta, 0.0)
		e["bleed_t"]   = max((e.get("bleed_t",   0.0) as float) - delta, 0.0)
		e["tw_slow_t"] = max((e.get("tw_slow_t", 0.0) as float) - delta, 0.0)
		e["trap_t"]    = max((e.get("trap_t",    0.0) as float) - delta, 0.0)
		e["trap_vine_t"] = max((e.get("trap_vine_t", 0.0) as float) - delta, 0.0)
		e["beetle_t"]  = max((e.get("beetle_t",  0.0) as float) - delta, 0.0)
		# Speed recovery when no longer slowed by time warp
		if (e["tw_slow_t"] as float) <= 0.0:
			var base_s: float = e["base_spd"] as float
			if (e["spd"] as float) < base_s:
				e["spd"] = min((e["spd"] as float) + base_s * delta * 2.5, base_s)
		if (e["poison_t"] as float) > 0.0:
			e["poison_tick_t"] = (e.get("poison_tick_t", 0.5) as float) - delta
			if (e["poison_tick_t"] as float) <= 0.0:
				e["poison_tick_t"] = 0.5
				if i < _enemies.size():
					_hit_enemy(i, (e.get("poison_dps", 0.0) as float) * 0.5)
					if i >= _enemies.size():
						continue
		if (e["beetle_t"] as float) > 0.0:
			e["beetle_tick_t"] = (e.get("beetle_tick_t", 0.5) as float) - delta
			if (e["beetle_tick_t"] as float) <= 0.0:
				e["beetle_tick_t"] = 0.5
				if i < _enemies.size():
					_hit_enemy(i, (e.get("beetle_dps", 0.0) as float) * 0.5)
					if i >= _enemies.size():
						continue
		e["alive_t"] = (e.get("alive_t", 0.0) as float) + delta
		if not (e.get("speed_boosted", false) as bool) and (e.get("alive_t", 0.0) as float) >= ENEMY_SURVIVE_SPEEDUP_SEC:
			e["speed_boosted"] = true
			e["base_spd"] = (e["base_spd"] as float) * ENEMY_SURVIVE_SPEEDUP_MULT
			e["spd"] = (e["spd"] as float) * ENEMY_SURVIVE_SPEEDUP_MULT
		var ep: Vector2 = e["pos"] as Vector2
		var ekind: String = e.get("kind", "normal") as String
		var objective_target_index := _enemy_objective_target_index()
		var enemy_target := _player_pos
		if e.has("objective_target_pos") and e["objective_target_pos"] is Vector2:
			enemy_target = e["objective_target_pos"] as Vector2
		elif objective_target_index >= 0:
			enemy_target = _adventure_props[objective_target_index].pos as Vector2
		var _emove_dir: Vector2 = (enemy_target - ep).normalized()
		var move_speed: float = e["spd"] as float
		if _idle_enemy_speed_boost_active:
			var ep_screen: Vector2 = ep - _camera.position + get_viewport_rect().size * 0.5
			if get_viewport_rect().grow(40.0).has_point(ep_screen):
				move_speed *= _idle_enemy_speed_boost_multiplier()
		if (e.get("trap_t", 0.0) as float) > 0.0:
			move_speed = 0.0
		if ekind == "lava_boss":
			var lava_state: String = e.get("lava_state", "idle") as String
			if lava_state == "charge":
				_emove_dir = e.get("charge_dir", _emove_dir) as Vector2
				move_speed = e.get("charge_speed", 430.0) as float
				_add_lava_charge_trail(e, delta)
			elif lava_state == "slam" or lava_state == "shield":
				move_speed *= 0.20
		e["pos"] = ep + _emove_dir * move_speed * delta
		if abs(_emove_dir.x) > 0.05:
			e["facing_x"] = 1 if _emove_dir.x > 0.0 else -1
		if objective_target_index >= 0:
			e["objective_hit_t"] = maxf(float(e.get("objective_hit_t", 0.0)) - delta, 0.0)
			if (_enemies[i]["pos"] as Vector2).distance_to(enemy_target) < 72.0 + (e["r"] as float) and float(e.objective_hit_t) <= 0.0:
				e.objective_hit_t = 0.75
				_damage_adventure_prop(objective_target_index, float(e.dmg) * 0.34)
		var damages_player_while_targeting: bool = _adventure_state == "story_chapter_one" and _chapter_one != null and _chapter_one.stage_number == 1
		if (objective_target_index < 0 or damages_player_while_targeting) and _player_iframes <= 0.0:
			if (_enemies[i]["pos"] as Vector2).distance_to(_player_pos) < PLAYER_R + (e["r"] as float):
				if _has_skill("meatball_barrage"):
					var mb_lvl: int = _get_skill("meatball_barrage").get("level", 1) as int
					var mb_def: Dictionary = _slvl("meatball_barrage", mb_lvl)
					_hit_enemy(i, (e["dmg"] as float) * (mb_def.get("reflect", 0.05) as float))
					if i >= _enemies.size():
						continue
					_aoe_flashes.append({"life": 0.55, "max_life": 0.55, "kind": "meatball_barrage", "pos": _player_pos})
				if _damage_player(e["dmg"] as float, IFRAMES_SEC):
					return

		# ── Boss special behaviors ──────────────────────────────────
		if ekind == "teleporter_boss":
			e["special_timer"] = (e["special_timer"] as float) + delta
			if (e["special_timer"] as float) >= 1.8:
				e["special_timer"] = 0.0
				var cur_p: Vector2 = e["pos"] as Vector2
				var to_player: Vector2 = _player_pos - cur_p
				if to_player.length() > 120.0:
					e["pos"] = cur_p + to_player * 0.60
		elif ekind == "shield_boss":
			e["special_timer"] = (e["special_timer"] as float) + delta
			var cycle: float = fmod(e["special_timer"] as float, 8.5)
			e["shield_active"] = cycle >= 6.0
		elif ekind == "shooter_boss":
			e["special_timer"] = (e["special_timer"] as float) + delta
			if (e["special_timer"] as float) >= 1.3:
				e["special_timer"] = -randf_range(0.15, 0.35)
				_fire_shooter_boss_pattern(e)
		elif ekind == "lava_boss":
			_update_lava_boss_special(e, delta)
		elif ekind == "abyss_gate_warden":
			_update_abyss_warden_special(e, delta)
		elif ekind == "prism_triarch":
			_update_prism_triarch_special(e, delta)
		elif ekind == "blight_vine_tyrant":
			_update_blight_tyrant_special(e, delta)
		elif ekind == "thunderforge_behemoth":
			_update_thunderforge_special(e, delta)
		elif ekind == "portal_keeper_boss":
			e["special_timer"] = float(e.get("special_timer", 0.0)) + delta
			if float(e["special_timer"]) >= 1.8:
				e["special_timer"] = 0.0
				_fire_shooter_boss_pattern(e)
		elif ekind == "mirror_guardian_boss":
			_update_prism_triarch_special(e, delta)
		elif ekind == "eclipse_elite_boss":
			_update_abyss_warden_special(e, delta)
		elif ekind == "abyss_king_boss":
			if _chapter_five != null and _chapter_five.phase in ["final_boss_c", "desperation"]:
				_update_prism_triarch_special(e, delta)
			else:
				_update_abyss_warden_special(e, delta)

func _enemy_objective_target_index() -> int:
	if _adventure_state == "story_escort":
		return _find_adventure_prop("scout")
	if _adventure_state == "story_defend":
		return _find_adventure_prop("shrine")
	if _adventure_state == "story_chapter_one" and _chapter_one != null:
		if _chapter_one.stage_number == 1:
			return _find_adventure_prop("scout")
		if _chapter_one.stage_number == 2:
			return _find_adventure_prop("shrine")
	return -1

func _damage_adventure_prop(index: int, damage: float) -> void:
	if index < 0 or index >= _adventure_props.size():
		return
	var prop := _adventure_props[index]
	prop.hp = float(prop.get("hp", 1.0)) - damage
	_adventure_props[index] = prop
	if _adventure_state == "story_chapter_one" and _chapter_one != null:
		var ratio: float = clampf(float(prop.get("hp", 0.0)) / maxf(float(prop.get("max_hp", 1.0)), 1.0), 0.0, 1.0)
		for threshold in [0.75, 0.50, 0.25, 0.0]:
			var threshold_key: String = "%s_hp_%d" % [str(prop.get("kind", "target")), roundi(threshold * 100.0)]
			if ratio <= threshold and not bool(_story_custom_progress.get(threshold_key, false)):
				_story_custom_progress[threshold_key] = true
				_story_log("Defence health state: %s %d%%" % [str(prop.get("kind", "target")), roundi(ratio * 100.0)])

func _update_bolts(delta: float) -> void:
	var vp: Rect2 = get_viewport_rect()
	for i in range(_bolts.size() - 1, -1, -1):
		var b: Dictionary = _bolts[i]
		var bkind: String = b.get("kind", "bolt") as String
		b["pos"]  = (b["pos"] as Vector2) + (b["vel"] as Vector2) * delta
		b["life"] = (b["life"] as float) - delta
		var bp: Vector2 = b["pos"] as Vector2
		var sp: Vector2 = bp - _camera.position + vp.size * 0.5
		if (b["life"] as float) <= 0.0 or not vp.grow(30.0).has_point(sp):
			_bolts.remove_at(i)
			continue
		# Arcane missile homing: steer toward nearest enemy
		if bkind == "arcane_missile" and not _enemies.is_empty():
			var hm_j: int   = -1
			var hm_d: float = 700.0
			for j in _enemies.size():
				var d: float = bp.distance_to(_enemies[j]["pos"] as Vector2)
				if d < hm_d:
					hm_d = d
					hm_j = j
			if hm_j >= 0:
				var t_dir: Vector2 = ((_enemies[hm_j]["pos"] as Vector2) - bp).normalized()
				var spd:   float   = (b["vel"] as Vector2).length()
				var turn_mul: float = 1.0 + _ring_bonus("projectile_homing")
				b["vel"] = (b["vel"] as Vector2).move_toward(t_dir * spd, spd * 3.5 * turn_mul * delta)
		elif bkind == "arcane_missile" and (b["vel"] as Vector2).length() < 20.0:
			var rescue_dir: Vector2 = _player_move_dir
			if rescue_dir.length_squared() < 0.01:
				rescue_dir = Vector2(float(_player_facing_x), 0.0)
			b["vel"] = rescue_dir.normalized() * float(b.get("base_spd", 700.0))
		if bkind == "divine_volley":
			var hit_index: int = -1
			for j in range(_enemies.size() - 1, -1, -1):
				if bp.distance_to(_enemies[j]["pos"] as Vector2) < BOLT_R + (_enemies[j]["r"] as float):
					hit_index = j
					break
			if hit_index >= 0:
				var source_pos: Vector2 = _enemies[hit_index]["pos"] as Vector2
				_hit_enemy(hit_index, b["dmg"] as float)
				var splits_left: int = b.get("splits_left", 0) as int
				var pierce_left: int = b.get("pierce_left", 1) as int
				var speed: float = (b["vel"] as Vector2).length()
				var forward: Vector2 = (b["vel"] as Vector2).normalized()
				if splits_left > 0:
					_spawn_divine_split(source_pos, forward, speed, (b["dmg"] as float) * 0.68, splits_left - 1, max(pierce_left - 1, 1))
					_spawn_combo_arc(bp, source_pos, Color(0.60, 1.0, 0.55, 0.95), 0.12, 1.8)
					_bolts.remove_at(i)
					continue
				b["pierce_left"] = pierce_left - 1
				if (b["pierce_left"] as int) <= 0:
					_bolts.remove_at(i)
			continue
		if bkind == "ricochet_arrow":
			if not b.has("ricochet_pct") or not b.has("bounces_left"):
				var rlvl: int = 1
				if _has_skill("ricochet_arrow"):
					rlvl = _get_skill("ricochet_arrow").get("level", 1) as int
				var rdef: Dictionary = _slvl("ricochet_arrow", rlvl)
				b["ricochet_pct"] = rdef.get("ricochet_pct", 0.25) as float
				b["bounces_left"] = rdef.get("bounces", 1) as int
				b["base_dmg"] = b["dmg"] as float
			var rj: int = -1
			for j in range(_enemies.size() - 1, -1, -1):
				if bp.distance_to(_enemies[j]["pos"] as Vector2) < BOLT_R + (_enemies[j]["r"] as float):
					rj = j
					break
			if rj >= 0:
				var hit_pos: Vector2 = _enemies[rj]["pos"] as Vector2
				var base_dmg: float = b.get("base_dmg", b["dmg"] as float) as float
				var bounce_pct: float = b.get("ricochet_pct", 0.25) as float
				var bounces_left: int = b.get("bounces_left", 1) as int
				var next_target_pos: Vector2 = Vector2.ZERO
				var has_next_target: bool = false
				for cand in range(_enemies.size() - 1, -1, -1):
					if cand == rj:
						continue
					var cand_pos: Vector2 = _enemies[cand]["pos"] as Vector2
					if cand_pos.distance_to(hit_pos) <= 320.0:
						next_target_pos = cand_pos
						has_next_target = true
						break
				_hit_enemy(rj, b["dmg"] as float)
				if bounces_left > 0 and has_next_target:
					var dir_r: Vector2 = (next_target_pos - hit_pos).normalized()
					if dir_r.length_squared() > 0.001:
						_bolts.append({
							"pos": hit_pos,
							"vel": dir_r * max((b["vel"] as Vector2).length(), 920.0),
							"dmg": base_dmg * bounce_pct,
							"base_dmg": base_dmg,
							"life": BOLT_LIFE,
							"kind": "ricochet_arrow",
							"ricochet_pct": bounce_pct,
							"bounces_left": bounces_left - 1,
						})
						_spawn_combo_arc(hit_pos, next_target_pos, Color(0.22, 0.22, 0.22, 0.92), 0.10, 1.8)
				_bolts.remove_at(i)
			continue
		if bkind == "phantom_hunt":
			var pj: int = -1
			for j in range(_enemies.size() - 1, -1, -1):
				if bp.distance_to(_enemies[j]["pos"] as Vector2) < BOLT_R + (_enemies[j]["r"] as float):
					pj = j
					break
			if pj >= 0:
				var ppos: Vector2 = _enemies[pj]["pos"] as Vector2
				var split_n: int = b.get("spawn_n", 3) as int
				var split_pct: float = b.get("spawn_pct", 0.10) as float
				var pbase: float = b.get("base_dmg", b["dmg"] as float) as float
				var died: bool = _hit_enemy_with_result(pj, b["dmg"] as float)
				if died:
					for _k in maxi(split_n, 3):
						var tidx: int = _nearest_enemy_index(ppos, 3200.0)
						if tidx < 0:
							break
						var vdir: Vector2 = ((_enemies[tidx]["pos"] as Vector2) - ppos).normalized()
						_bolts.append({
							"pos": ppos,
							"vel": vdir * 760.0,
							"dmg": pbase * split_pct,
							"life": 1.9,
							"kind": "phantom_homing",
						})
				_bolts.remove_at(i)
			continue
		if bkind == "phantom_homing" and not _enemies.is_empty():
			var hidx: int = _nearest_enemy_index(bp, 700.0)
			if hidx >= 0:
				var hdir: Vector2 = ((_enemies[hidx]["pos"] as Vector2) - bp).normalized()
				var hspd: float = (b["vel"] as Vector2).length()
				b["vel"] = (b["vel"] as Vector2).move_toward(hdir * hspd, hspd * 4.0 * delta)
		var hit: bool = false
		var hit_j: int = -1
		for j in range(_enemies.size() - 1, -1, -1):
			if bp.distance_to(_enemies[j]["pos"] as Vector2) < BOLT_R + (_enemies[j]["r"] as float):
				var bolt_element := "physical"
				if bkind == "bolt": bolt_element = "lightning"
				elif bkind == "chili_explosion": bolt_element = "fire"
				_hit_enemy_element(j, b["dmg"] as float, bolt_element)
				hit = true
				hit_j = j
				break
		if hit:
			if bkind == "chili_explosion":
				_spawn_embers(bp, b.get("ember_n", 3) as int, b.get("ember_dps", 10.0) as float)
			if bkind == "trap_arrow" and hit_j >= 0 and hit_j < _enemies.size():
				var ta_lvl: int = 1
				if _has_skill("trap_arrow"):
					ta_lvl = _get_skill("trap_arrow")["level"] as int
				var ta_def: Dictionary = _slvl("trap_arrow", ta_lvl)
				_enemies[hit_j]["trap_t"] = max((_enemies[hit_j].get("trap_t", 0.0) as float), ta_def.get("hold", 3.0) as float)
				_enemies[hit_j]["trap_vine_t"] = max((_enemies[hit_j].get("trap_vine_t", 0.0) as float), ta_def.get("hold", 3.0) as float)
			if bkind == "poison_arrow" and hit_j >= 0 and hit_j < _enemies.size():
				var pa_lvl: int = _get_skill("poison_arrow").get("level", 1) as int
				var pa_def: Dictionary = _slvl("poison_arrow", pa_lvl)
				_apply_poison_to_enemy_idx(hit_j, pa_def.get("poison_t", 3.0) as float, pa_def.get("poison_dps", 8.0) as float)
			if bkind == "venom_plague" and hit_j >= 0 and hit_j < _enemies.size():
				var vp_lvl: int = _get_skill("venom_plague").get("level", 1) as int
				var vp_def: Dictionary = _slvl("venom_plague", vp_lvl)
				_spawn_venom_pool(_enemies[hit_j]["pos"] as Vector2, vp_def)
			if bkind == "leech_vine" and hit_j >= 0:
				var lv_lvl: int = _get_skill("leech_vine").get("level", 1) as int
				var lv_def2: Dictionary = _slvl("leech_vine", lv_lvl)
				var steal: float = lv_def2.get("steal", 0.01) as float
				_player_hp = min(_player_max_hp, _player_hp + (b["dmg"] as float) * steal)
			if bkind == "bleed_mark" and hit_j >= 0 and hit_j < _enemies.size():
				var bm_lvl: int = 1
				if _has_skill("bleed_mark"):
					bm_lvl = _get_skill("bleed_mark")["level"] as int
				var bm_def: Dictionary = _slvl("bleed_mark", bm_lvl)
				_enemies[hit_j]["bleed_t"] = bm_def.get("mark_t", 6.0) as float
				_enemies[hit_j]["bleed_bonus"] = bm_def.get("bonus", _bleed_bonus_from_level(bm_lvl)) as float
				_enemies[hit_j]["bleed_explode_r"] = bm_def.get("explode_r", 190.0) as float
				_enemies[hit_j]["bleed_seed"] = true
				_enemies[hit_j]["bleed_chain"] = false
			_bolts.remove_at(i)

func _fire_trap_arrow(def: Dictionary) -> void:
	var dmg: float = (def.get("dmg", 42.0) as float) * TARGET_SKILL_DAMAGE_MULT
	var spd: float = 860.0 + float(def.get("len", 160.0) as float) * 0.55
	var target_idx: int = _nearest_enemy_index(_player_pos, 1500.0)
	var dir: Vector2 = _player_move_dir
	if target_idx >= 0:
		dir = ((_enemies[target_idx]["pos"] as Vector2) - _player_pos).normalized()
	if dir.length_squared() < 0.01:
		dir = Vector2(float(_player_facing_x), 0.0)
	_bolts.append({
		"pos": _player_pos,
		"vel": dir.normalized() * spd,
		"dmg": dmg,
		"life": BOLT_LIFE,
		"kind": "trap_arrow",
		"trap_hold": def.get("hold", 3.0) as float,
	})

func _hit_enemy_with_result(idx: int, dmg: float) -> bool:
	if idx < 0 or idx >= _enemies.size():
		return false
	var hp_before: float = _enemies[idx]["hp"] as float
	_hit_enemy(idx, dmg)
	if idx >= _enemies.size():
		return true
	return (_enemies[idx]["hp"] as float) < hp_before and (_enemies[idx]["hp"] as float) <= 0.0

func _nearest_enemy_index(from_pos: Vector2, max_dist: float, exclude: Array = []) -> int:
	var best: float = max_dist
	var best_idx: int = -1
	for i in _enemies.size():
		if exclude.has(i):
			continue
		var d: float = from_pos.distance_to(_enemies[i]["pos"] as Vector2)
		if d < best:
			best = d
			best_idx = i
	return best_idx

func _update_waves(delta: float) -> void:
	for i in range(_waves.size() - 1, -1, -1):
		var w: Dictionary = _waves[i]
		var expand: float = (w["max_r"] as float) / (w["max_life"] as float) * delta
		w["r"]    = (w["r"] as float) + expand
		w["life"] = (w["life"] as float) - delta
		if (w["life"] as float) <= 0.0:
			_waves.remove_at(i)

func _update_combo_arcs(delta: float) -> void:
	for i in range(_combo_arcs.size() - 1, -1, -1):
		var arc: Dictionary = _combo_arcs[i]
		arc["life"] = (arc["life"] as float) - delta
		if (arc["life"] as float) <= 0.0:
			_combo_arcs.remove_at(i)

func _spawn_shadow_clone(pos: Vector2, hp: float, level: int) -> void:
	_shadow_clones.append({
		"pos":      pos,
		"hp":       hp,
		"max_hp":   hp,
		"life":     8.0 + float(level) * 1.5,
		"max_life": 8.0 + float(level) * 1.5,
		"fire_t":   0.8,
		"level":    level,
		"facing_x": _player_facing_x,
	})

func _update_shadow_clones(delta: float) -> void:
	var clone_dmg: float = 32.0
	if _has_skill("shadow_clone"):
		clone_dmg = (_slvl("shadow_clone", _get_skill("shadow_clone")["level"] as int).get("dps", 0.0) as float) * 2.0 * 0.14
	for i in range(_shadow_clones.size() - 1, -1, -1):
		var c: Dictionary = _shadow_clones[i]
		c["life"] = (c["life"] as float) - delta
		if (c["life"] as float) <= 0.0 or (c["hp"] as float) <= 0.0:
			_shadow_clones.remove_at(i)
			continue
		if c.get("passive", false) as bool:
			continue
		var cpos: Vector2 = c["pos"] as Vector2
		# Enemies that touch the clone deal damage to it
		for j in range(_enemies.size() - 1, -1, -1):
			if j >= _enemies.size(): continue
			if cpos.distance_to(_enemies[j]["pos"] as Vector2) < 30.0 + (_enemies[j]["r"] as float):
				var enemy_dmg: float = float((_enemies[j] as Dictionary).get("dmg", 0.0))
				c["hp"] = (c["hp"] as float) - enemy_dmg * delta * 2.0
				if (c["hp"] as float) <= 0.0: break
		if (c["hp"] as float) <= 0.0: continue
		# Clone fires shadow daggers toward the nearest enemy within range
		c["fire_t"] = (c["fire_t"] as float) - delta
		if (c["fire_t"] as float) <= 0.0:
			c["fire_t"] = 0.9
			var best_j: int   = -1
			var best_d: float = 400.0
			for j in _enemies.size():
				var d: float = cpos.distance_to(_enemies[j]["pos"] as Vector2)
				if d < best_d:
					best_d = d
					best_j = j
			if best_j >= 0:
				var dir: Vector2 = ((_enemies[best_j]["pos"] as Vector2) - cpos).normalized()
				_bolts.append({"pos": cpos, "vel": dir * 820.0, "dmg": clone_dmg, "life": BOLT_LIFE, "kind": "shadow_dagger"})

func _do_mana_push(radius: float, force: float) -> void:
	_play_skill_sfx("skill_wave", -4.0, 0.88, 0.12)
	_waves.append({"pos": _player_pos, "r": 0.0, "max_r": radius, "life": 0.55, "max_life": 0.55, "kind": "mana_push"})
	for i in range(_enemies.size() - 1, -1, -1):
		var ep: Vector2 = _enemies[i]["pos"] as Vector2
		var d: float    = ep.distance_to(_player_pos)
		if d < radius + (_enemies[i]["r"] as float):
			var dir: Vector2      = (ep - _player_pos).normalized()
			var strength: float   = force * max(0.15, 1.0 - d / max(radius, 1.0))
			_enemies[i]["pos"]    = ep + dir * strength

func _do_blink_strike(dash_r: float, dmg: float) -> void:
	_play_skill_sfx("skill_blink_strike", -5.0, 1.0, 0.08)
	# Find nearest enemy and blink towards it
	var dir: Vector2 = Vector2(float(_player_facing_x), 0.0)
	var nearest_dist: float = INF
	for enemy in _enemies:
		var ep: Vector2 = enemy["pos"] as Vector2
		var dist: float = _player_pos.distance_to(ep)
		if dist < nearest_dist:
			nearest_dist = dist
			dir = (ep - _player_pos).normalized()
	# Fallback if no enemies
	if dir.length_squared() < 0.01:
		dir = Vector2(float(_player_facing_x), 0.0)
	dir = dir.normalized()
	var start_pos: Vector2 = _player_pos
	var end_pos:   Vector2 = _player_pos + dir * (dash_r * 1.35)
	if _combat_vfx != null:
		_combat_vfx.emit_dash(start_pos, end_pos, "skill_blink_strike")
	var blink_dmg: float   = dmg * TARGET_SKILL_DAMAGE_MULT
	for i in range(_enemies.size() - 1, -1, -1):
		var ep: Vector2 = _enemies[i]["pos"] as Vector2
		if _point_to_segment_dist(ep, start_pos, end_pos) < 64.0 + (_enemies[i]["r"] as float):
			_hit_enemy(i, blink_dmg)
	# New behavior: keep player position, create a long slash and leave a short-lived shadow clone at slash end.
	_shadow_clones.append({
		"pos": end_pos,
		"hp": 9999.0,
		"max_hp": 9999.0,
		"life": 2.0,
		"max_life": 2.0,
		"fire_t": 99.0,
		"level": 1,
		"facing_x": 1 if dir.x >= 0.0 else -1,
		"passive": true,
	})
	_player_iframes        = max(_player_iframes, 0.35)
	_aoe_flashes.append({"life": 0.45, "max_life": 0.45, "kind": "blink_trail",
		"pos": start_pos, "end_pos": end_pos})
	_spawn_combo_arc(start_pos, end_pos, Color(0.20, 0.10, 0.28, 0.95), 0.20, 7.0)

func _point_to_segment_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2   = b - a
	var len_sq: float = ab.length_squared()
	if len_sq < 0.001: return p.distance_to(a)
	var t: float = clamp((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return (p - (a + ab * t)).length()

func _spawn_smoke_clouds(n: int, dmg_per_tick: float) -> void:
	_play_skill_sfx("skill_smoke_bomb", -5.0, 1.0, 0.1)
	var vp: Rect2 = get_viewport_rect()
	for i in n:
		var cx: float = _player_pos.x + randf_range(-vp.size.x * 0.38, vp.size.x * 0.38)
		var cy: float = _player_pos.y + randf_range(-vp.size.y * 0.36, vp.size.y * 0.36)
		var life: float = 9.0 + randf() * 5.0
		_smoke_clouds.append({
			"pos":      Vector2(cx, cy),
			"r":        52.0 + randf() * 42.0,
			"life":     life,
			"max_life": life,
			"dmg":      dmg_per_tick,
			"tick_t":   0.0,
		})

func _update_smoke_clouds(delta: float) -> void:
	for i in range(_smoke_clouds.size() - 1, -1, -1):
		var c: Dictionary = _smoke_clouds[i]
		c["life"] = (c["life"] as float) - delta
		if (c["life"] as float) <= 0.0:
			_smoke_clouds.remove_at(i)
			continue
		c["tick_t"] = (c["tick_t"] as float) + delta
		if (c["tick_t"] as float) >= 0.5:
			c["tick_t"] = 0.0
			var cpos: Vector2 = c["pos"] as Vector2
			var cr:   float   = c["r"] as float
			for j in range(_enemies.size() - 1, -1, -1):
				if j >= _enemies.size():
					continue
				if (_enemies[j]["pos"] as Vector2).distance_to(cpos) < cr + (_enemies[j]["r"] as float):
					_hit_enemy(j, c["dmg"] as float)

func _queue_thousand_blades(n: int, dmg: float, spd: float) -> void:
	_play_skill_sfx("skill_knife_storm", -6.0, 1.0, 0.1)
	var base_a: float = randf() * TAU
	for i in n:
		_blade_queue.append({
			"dir":     Vector2(1.0, 0.0).rotated(float(i) / float(n) * TAU + base_a + randf_range(-0.22, 0.22)),
			"dmg":     dmg,
			"spd":     spd + randf_range(-50.0, 50.0),
			"spawn_t": float(i) * 0.075,
			"style":   i % 4,
		})

func _update_blade_queue(delta: float) -> void:
	for i in range(_blade_queue.size() - 1, -1, -1):
		_blade_queue[i]["spawn_t"] = (_blade_queue[i]["spawn_t"] as float) - delta
		if (_blade_queue[i]["spawn_t"] as float) <= 0.0:
			var b: Dictionary = _blade_queue[i]
			var bdmg: float   = (b["dmg"] as float) * TARGET_SKILL_DAMAGE_MULT
			_bolts.append({
				"pos":  _player_pos,
				"vel":  (b["dir"] as Vector2) * (b["spd"] as float),
				"dmg":  bdmg,
				"life": 0.80,
				"kind": "tb_" + str(b["style"] as int),
			})
			_blade_queue.remove_at(i)

func _trigger_time_warp_zone(radius: float, slow: float, life: float) -> void:
	_play_skill_sfx("skill_time_warp", -5.0, 1.0, 0.2)
	_time_warp_zones.append({
		"pos":      _player_pos,
		"r":        0.0,
		"max_r":    radius,
		"life":     life,
		"max_life": life,
		"slow":     slow,
	})

func _update_time_warp_zones(delta: float) -> void:
	for i in range(_time_warp_zones.size() - 1, -1, -1):
		var z: Dictionary = _time_warp_zones[i]
		z["life"] = (z["life"] as float) - delta
		if (z["life"] as float) <= 0.0:
			_time_warp_zones.remove_at(i)
			continue
		z["r"] = min((z["r"] as float) + (z["max_r"] as float) * delta * 0.45, z["max_r"] as float)
		var zpos:   Vector2 = z["pos"] as Vector2
		var zr:     float   = z["r"] as float
		var slow_f: float   = z["slow"] as float
		for j in range(_enemies.size() - 1, -1, -1):
			if j >= _enemies.size(): continue
			if (_enemies[j]["pos"] as Vector2).distance_to(zpos) < zr + (_enemies[j]["r"] as float):
				_enemies[j]["tw_slow_t"] = 0.25
				_enemies[j]["spd"]       = max((_enemies[j]["base_spd"] as float) * (1.0 - slow_f), 12.0)

func _cast_arc_lightning(cast_r: float, dmg: float, chains: int, chain_r: float) -> void:
	if _enemies.is_empty():
		return
	var half_screen: float = min(get_viewport_rect().size.x, get_viewport_rect().size.y) * 0.50
	cast_r = max(cast_r, half_screen)
	chain_r = max(chain_r, 260.0)
	_play_skill_sfx("skill_elec_wave", -4.0, 1.12, 0.10)
	var start_idx: int = -1
	var best_d: float = cast_r
	for i in _enemies.size():
		var d: float = _player_pos.distance_to(_enemies[i]["pos"] as Vector2)
		if d < best_d:
			best_d = d
			start_idx = i
	if start_idx < 0:
		return
	var used: Array[int] = [start_idx]
	var last_pos: Vector2 = _enemies[start_idx]["pos"] as Vector2
	_hit_enemy(start_idx, dmg)
	_arc_zaps.append({"a": _player_pos, "b": last_pos, "life": 0.17, "max_life": 0.17})
	for _c in chains:
		var next_idx: int = -1
		var next_d: float = chain_r
		for j in _enemies.size():
			if used.has(j):
				continue
			var d2: float = last_pos.distance_to(_enemies[j]["pos"] as Vector2)
			if d2 < next_d:
				next_d = d2
				next_idx = j
		if next_idx < 0:
			break
		var next_pos: Vector2 = _enemies[next_idx]["pos"] as Vector2
		_arc_zaps.append({"a": last_pos, "b": next_pos, "life": 0.17, "max_life": 0.17})
		_hit_enemy(next_idx, dmg * 0.86)
		used.append(next_idx)
		last_pos = next_pos

func _spawn_prism_trap(radius: float, dmg: float, life: float) -> void:
	_play_skill_sfx("skill_crystal_prism", -5.0, 1.0, 0.12)
	var base_a: float = randf() * TAU
	var pts: Array[Vector2] = []
	for i in 3:
		var a: float = base_a + float(i) / 3.0 * TAU
		pts.append(_player_pos + Vector2(cos(a), sin(a)) * radius)
	_prism_traps.append({
		"pts": pts,
		"dmg": dmg,
		"life": life,
		"max_life": life,
		"tick_t": 0.0,
	})

func _update_prism_traps(delta: float) -> void:
	for i in range(_prism_traps.size() - 1, -1, -1):
		var p: Dictionary = _prism_traps[i]
		p["life"] = (p["life"] as float) - delta
		if (p["life"] as float) <= 0.0:
			_prism_traps.remove_at(i)
			continue
		p["tick_t"] = (p["tick_t"] as float) + delta
		if (p["tick_t"] as float) < 0.25:
			continue
		p["tick_t"] = 0.0
		var pts: Array = p["pts"] as Array
		if pts.size() < 3 or _enemies.is_empty():
			continue
		for ei in range(_enemies.size() - 1, -1, -1):
			if ei < 0 or ei >= _enemies.size():
				continue
			var ep: Vector2 = _enemies[ei]["pos"] as Vector2
			var hit: bool = false
			for edge_i in 3:
				var a: Vector2 = pts[edge_i]
				var b: Vector2 = pts[(edge_i + 1) % 3]
				if _point_to_segment_dist(ep, a, b) <= 12.0 + (_enemies[ei]["r"] as float):
					hit = true
					break
			if hit:
				_hit_enemy(ei, p["dmg"] as float)

func _spawn_ground_trap(trap_len: float, dmg: float, hold_t: float, max_targets: int, life: float) -> void:
	_play_skill_sfx("skill_trap_arrow", -4.0, 0.95, 0.14)
	var dir: Vector2 = _player_move_dir
	if dir.length_squared() < 0.01:
		dir = Vector2(float(_player_facing_x), 0.0)
	dir = dir.normalized()
	var center: Vector2 = _player_pos + dir * 120.0
	var a: Vector2 = center - dir * (trap_len * 0.5)
	var b: Vector2 = center + dir * (trap_len * 0.5)
	_ground_traps.append({
		"a": a,
		"b": b,
		"dmg": dmg,
		"hold": hold_t,
		"max_targets": max_targets,
		"life": life,
		"max_life": life,
		"armed": {},
	})

func _update_ground_traps(delta: float) -> void:
	for i in range(_ground_traps.size() - 1, -1, -1):
		var t: Dictionary = _ground_traps[i]
		t["life"] = (t["life"] as float) - delta
		if (t["life"] as float) <= 0.0:
			_ground_traps.remove_at(i)
			continue
		var armed: Dictionary = t["armed"] as Dictionary
		for id_key in armed.keys():
			armed[id_key] = max((armed[id_key] as float) - delta, 0.0)
		for id_key in armed.keys().duplicate():
			if (armed[id_key] as float) <= 0.0:
				armed.erase(id_key)
		if armed.size() >= (t["max_targets"] as int):
			continue
		for ei in range(_enemies.size() - 1, -1, -1):
			var key: String = str(ei)
			if armed.has(key):
				continue
			if _point_to_segment_dist(_enemies[ei]["pos"] as Vector2, t["a"] as Vector2, t["b"] as Vector2) <= 10.0 + (_enemies[ei]["r"] as float):
				armed[key] = t["hold"] as float
				_enemies[ei]["trap_t"] = max((_enemies[ei].get("trap_t", 0.0) as float), t["hold"] as float)
				_enemies[ei]["trap_vine_t"] = max((_enemies[ei].get("trap_vine_t", 0.0) as float), t["hold"] as float)
				_hit_enemy(ei, t["dmg"] as float)
				if armed.size() >= (t["max_targets"] as int):
					break

func _spawn_hawk_companion(hdef: Dictionary) -> void:
	_hawk_companions.clear()
	_hawk_companions.append({
		"pos": _player_pos + Vector2(0.0, -68.0),
		"r": hdef.get("r", 220.0) as float,
		"dmg": hdef.get("dmg", 24.0) as float,
		"shots": hdef.get("shots", 1) as int,
		"fire_t": 0.0,
	})

func _update_hawk_companions(delta: float) -> void:
	if _hawk_companions.is_empty():
		return
	var active: bool = false
	if _has_skill("hawk_companion"):
		var hs: Dictionary = _get_skill("hawk_companion")
		active = (hs.get("active_t", 0.0) as float) > 0.0
	if not active:
		_hawk_companions.clear()
		return
	for i in range(_hawk_companions.size() - 1, -1, -1):
		var h: Dictionary = _hawk_companions[i]
		var target_pos: Vector2 = _player_pos + Vector2(cos(_elapsed * 3.2 + float(i) * 0.8) * 54.0, -70.0 + sin(_elapsed * 5.0 + float(i)) * 8.0)
		h["pos"] = (h["pos"] as Vector2).lerp(target_pos, min(delta * 7.0, 1.0))
		h["fire_t"] = (h["fire_t"] as float) - delta
		if (h["fire_t"] as float) > 0.0:
			continue
		h["fire_t"] = 0.45
		var hr: float = h["r"] as float
		var hpos: Vector2 = h["pos"] as Vector2
		var in_range: Array[int] = []
		for ei in _enemies.size():
			if (_enemies[ei]["pos"] as Vector2).distance_to(hpos) <= hr:
				in_range.append(ei)
		if in_range.is_empty():
			continue
		var near: Array[int] = []
		var nshots: int = min(h["shots"] as int, in_range.size())
		for _pick in nshots:
			var best_i: int = -1
			var best_d: float = INF
			for cand in in_range:
				if near.has(cand):
					continue
				var d: float = (_enemies[cand]["pos"] as Vector2).distance_to(hpos)
				if d < best_d:
					best_d = d
					best_i = cand
			if best_i >= 0:
				near.append(best_i)
		for si in nshots:
			var idx: int = near[si] as int
			if idx < 0 or idx >= _enemies.size():
				continue
			var dir: Vector2 = ((_enemies[idx]["pos"] as Vector2) - (h["pos"] as Vector2)).normalized()
			_bolts.append({"pos": h["pos"], "vel": dir * 900.0, "dmg": (h["dmg"] as float) * PROJECTILE_SKILL_DAMAGE_MULT, "life": 1.0, "kind": "hawk_feather"})

func _update_arc_zaps(delta: float) -> void:
	for i in range(_arc_zaps.size() - 1, -1, -1):
		_arc_zaps[i]["life"] = (_arc_zaps[i]["life"] as float) - delta
		if (_arc_zaps[i]["life"] as float) <= 0.0:
			_arc_zaps.remove_at(i)

func _spawn_venom_pool(pos: Vector2, def: Dictionary) -> void:
	_venom_pools.append({
		"pos": pos,
		"r": def.get("pool_r", 54.0) as float,
		"life": 2.0,
		"max_life": 2.0,
		"dps": def.get("pool_dps", 12.0) as float,
		"tick_t": 0.0,
	})

func _update_venom_pools(delta: float) -> void:
	for i in range(_venom_pools.size() - 1, -1, -1):
		var p: Dictionary = _venom_pools[i]
		p["life"] = (p["life"] as float) - delta
		if (p["life"] as float) <= 0.0:
			_venom_pools.remove_at(i)
			continue
		p["tick_t"] = (p["tick_t"] as float) + delta
		if (p["tick_t"] as float) < 0.5:
			continue
		p["tick_t"] = 0.0
		for ei in range(_enemies.size() - 1, -1, -1):
			if (_enemies[ei]["pos"] as Vector2).distance_to(p["pos"] as Vector2) <= (p["r"] as float) + (_enemies[ei]["r"] as float):
				_hit_enemy(ei, (p.get("dps", 0.0) as float) * 0.5)

func _spawn_toxic_mushroom(def: Dictionary) -> void:
	var ang: float = randf() * TAU
	var dist: float = randf_range(120.0, 320.0)
	_toxic_mushrooms.append({
		"pos": _player_pos + Vector2(cos(ang), sin(ang)) * dist,
		"r": def.get("fog_r", 120.0) as float,
		"dps": def.get("dps", 16.0) as float,
		"life": def.get("life", 4.0) as float,
		"max_life": def.get("life", 4.0) as float,
		"pulse_t": 0.0,
	})

func _update_toxic_mushrooms(delta: float) -> void:
	for i in range(_toxic_mushrooms.size() - 1, -1, -1):
		var m: Dictionary = _toxic_mushrooms[i]
		m["life"] = (m["life"] as float) - delta
		if (m["life"] as float) <= 0.0:
			_toxic_mushrooms.remove_at(i)
			continue
		m["pulse_t"] = (m["pulse_t"] as float) + delta
		if (m["pulse_t"] as float) >= 2.0:
			m["pulse_t"] = 0.0
			for ei in range(_enemies.size() - 1, -1, -1):
				if (_enemies[ei]["pos"] as Vector2).distance_to(m["pos"] as Vector2) <= (m["r"] as float) + (_enemies[ei]["r"] as float):
					_hit_enemy(ei, (m.get("dps", 0.0) as float) * 0.7)

func _spawn_bog_pool(def: Dictionary) -> void:
	var ang: float = randf() * TAU
	var dist: float = randf_range(140.0, 340.0)
	_bog_pools.append({
		"pos": _player_pos + Vector2(cos(ang), sin(ang)) * dist,
		"r": def.get("r", 160.0) as float,
		"slow": def.get("slow", 0.2) as float,
		"dps": def.get("dps", 10.0) as float,
		"tick_t": 0.0,
		"life": def.get("life", 3.2) as float,
		"max_life": def.get("life", 3.2) as float,
	})

func _update_bog_pools(delta: float) -> void:
	for i in range(_bog_pools.size() - 1, -1, -1):
		var p: Dictionary = _bog_pools[i]
		p["life"] = (p["life"] as float) - delta
		if (p["life"] as float) <= 0.0:
			_bog_pools.remove_at(i)
			continue
		p["tick_t"] = float(p.get("tick_t", 0.0)) - delta
		var should_damage := float(p["tick_t"]) <= 0.0
		if should_damage:
			p["tick_t"] = 0.5
		for ei in range(_enemies.size() - 1, -1, -1):
			# Killing a boss can clear the entire enemy array inside _hit_enemy().
			if ei >= _enemies.size():
				continue
			if (_enemies[ei]["pos"] as Vector2).distance_to(p["pos"] as Vector2) <= (p["r"] as float) + (_enemies[ei]["r"] as float):
				_enemies[ei]["tw_slow_t"] = max(_enemies[ei].get("tw_slow_t", 0.0) as float, 0.25)
				_enemies[ei]["mud_t"] = max(float(_enemies[ei].get("mud_t", 0.0)), 1.0)
				_enemies[ei]["spd"] = max((_enemies[ei]["base_spd"] as float) * (1.0 - (p["slow"] as float)), 8.0)
				if should_damage:
					_hit_enemy_element(ei, float(p.get("dps", 10.0)) * 0.5, "poison")

func _spawn_corruption_pools(def: Dictionary) -> void:
	var n: int = def.get("n", 2) as int
	for i in n:
		var ang: float = randf() * TAU
		var dist: float = randf_range(130.0, 360.0)
		_corruption_pools.append({
			"pos": _player_pos + Vector2(cos(ang), sin(ang)) * dist,
			"r": def.get("r", 62.0) as float,
			"dps": def.get("dps", 16.0) as float,
			"sink_t": def.get("sink_t", 3.0) as float,
			"max_targets": def.get("max_targets", 2) as int,
			"life": 4.0,
			"max_life": 4.0,
			"enemy_idxs": [],
			"tick_t": 0.0,
		})

func _update_corruption_pools(delta: float) -> void:
	for i in range(_corruption_pools.size() - 1, -1, -1):
		var p: Dictionary = _corruption_pools[i]
		p["life"] = (p["life"] as float) - delta
		if (p["life"] as float) <= 0.0:
			_corruption_pools.remove_at(i)
			continue
		var trapped: Array = p.get("enemy_idxs", []) as Array
		for ti in range(trapped.size() - 1, -1, -1):
			var idx: int = trapped[ti] as int
			if idx < 0 or idx >= _enemies.size():
				trapped.remove_at(ti)
				continue
			_enemies[idx]["trap_t"] = max(_enemies[idx].get("trap_t", 0.0) as float, 0.12)
			_enemies[idx]["corr_sink_t"] = max((_enemies[idx].get("corr_sink_t", 0.0) as float) - delta, 0.0)
			if (_enemies[idx].get("corr_sink_t", 0.0) as float) <= 0.0:
				trapped.remove_at(ti)

		var max_targets: int = max(p.get("max_targets", 2) as int, 1)
		if trapped.size() < max_targets:
			for ei in range(_enemies.size() - 1, -1, -1):
				if trapped.size() >= max_targets:
					break
				if trapped.has(ei):
					continue
				if (_enemies[ei]["pos"] as Vector2).distance_to(p["pos"] as Vector2) <= (p["r"] as float) + (_enemies[ei]["r"] as float):
					trapped.append(ei)
					_enemies[ei]["corr_sink_t"] = p["sink_t"] as float

		p["enemy_idxs"] = trapped
		p["tick_t"] = (p["tick_t"] as float) + delta
		if (p["tick_t"] as float) >= 0.5:
			p["tick_t"] = 0.0
			for ti in range(trapped.size() - 1, -1, -1):
				var idx2: int = trapped[ti] as int
				if idx2 >= 0 and idx2 < _enemies.size():
					_hit_enemy(idx2, (p.get("dps", 0.0) as float) * 0.5)

func _attach_plague_beetles(def: Dictionary) -> void:
	if _enemies.is_empty():
		return
	var idx: int = _nearest_enemy_index(_player_pos, 720.0)
	if idx < 0:
		return
	_enemies[idx]["beetle_t"] = def.get("dur", 3.0) as float
	_enemies[idx]["beetle_dps"] = def.get("dps", 18.0) as float
	_enemies[idx]["beetle_tick_t"] = 0.0

func _cast_soup_cone(def: Dictionary) -> void:
	var nearest_idx: int = _nearest_enemy_index(_player_pos, 1200.0)
	var fwd: Vector2 = _player_move_dir
	if nearest_idx >= 0:
		fwd = ((_enemies[nearest_idx]["pos"] as Vector2) - _player_pos).normalized()
	if fwd.length_squared() < 0.01:
		fwd = Vector2(float(_player_facing_x), 0.0)
	var cone_angle: float = deg_to_rad(def.get("angle_deg", 15.0) as float)
	var cone_r: float = def.get("r", 380.0) as float
	for ei in range(_enemies.size() - 1, -1, -1):
		var to_e: Vector2 = (_enemies[ei]["pos"] as Vector2) - _player_pos
		if to_e.length() > cone_r + (_enemies[ei]["r"] as float):
			continue
		if abs(wrapf(to_e.angle() - fwd.angle(), -PI, PI)) <= cone_angle * 0.5:
			_hit_enemy(ei, def.get("dmg", 52.0) as float)
	_aoe_flashes.append({"life": 0.55, "max_life": 0.55, "kind": "soup_splash", "pos": _player_pos, "dir": fwd, "cone_angle": cone_angle, "cone_r": cone_r})

func _fire_chili_explosion(def: Dictionary) -> void:
	if _enemies.is_empty():
		return
	var n: int = def.get("n", 1) as int
	for i in n:
		var idx: int = _nearest_enemy_index(_player_pos, 1100.0)
		if idx < 0:
			break
		var dir: Vector2 = ((_enemies[idx]["pos"] as Vector2) - _player_pos).normalized().rotated(randf_range(-0.10, 0.10))
		_bolts.append({
			"pos": _player_pos,
			"vel": dir * (def.get("spd", 820.0) as float),
			"dmg": def.get("dmg", 86.0) as float,
			"life": 1.2,
			"kind": "chili_explosion",
			"ember_n": def.get("ember_n", 3) as int,
			"ember_dps": def.get("ember_dps", 10.0) as float,
		})

func _spawn_embers(center: Vector2, count: int, dps: float) -> void:
	for i in count:
		var ang: float = randf() * TAU
		var dist: float = randf_range(8.0, 42.0)
		_lava_pools.append({
			"kind": "chili_ember",
			"pos": center + Vector2(cos(ang), sin(ang)) * dist,
			"r": 16.0,
			"life": 3.0,
			"max_life": 3.0,
			"dmg_per_tick": dps,
			"tick_t": 0.0,
		})

func _queue_master_kitchen(def: Dictionary) -> void:
	var base_r: float = (def.get("r", 210.0) as float) * 1.25
	var dmg: float = def.get("dmg", 36.0) as float
	var n: int = maxi(def.get("n", 6) as int, 12)
	var utensil_types: Array[String] = ["knife", "spoon", "spatula", "board", "hat", "fork", "grater", "whisk", "soup", "shoup", "hotdog", "meatball", "pizza"]
	for i in n:
		var a: float = float(i) / float(max(n, 1)) * TAU
		var u: String = utensil_types[i % utensil_types.size()]
		var width: float = 28.0
		if u == "board":
			width = 36.0
		elif u == "hat":
			width = 30.0
		elif u == "hotdog":
			width = 34.0
		_kitchen_queue.append({
			"delay": float(i) * 0.04,
			"dir": Vector2(cos(a), sin(a)),
			"r": base_r,
			"dmg": dmg,
			"width": width,
			"utensil": u,
		})

func _update_kitchen_queue(delta: float) -> void:
	for i in range(_kitchen_queue.size() - 1, -1, -1):
		var q: Dictionary = _kitchen_queue[i]
		q["delay"] = (q["delay"] as float) - delta
		if (q["delay"] as float) > 0.0:
			continue
		var dir: Vector2 = q["dir"] as Vector2
		var radius: float = q["r"] as float
		var width: float = q.get("width", 22.0) as float
		var start: Vector2 = _player_pos
		var tip: Vector2 = start + dir * radius
		for ei in range(_enemies.size() - 1, -1, -1):
			if ei < 0 or ei >= _enemies.size():
				continue
			var enemy: Dictionary = _enemies[ei]
			if _point_to_segment_dist(enemy.get("pos", Vector2.ZERO) as Vector2, start, tip) <= width + (enemy.get("r", 24.0) as float):
				_hit_enemy(ei, q["dmg"] as float)
		_aoe_flashes.append({"life": 0.30, "max_life": 0.30, "kind": "master_kitchen", "pos": start, "from_pos": start, "to_pos": tip, "dir": dir, "r": radius, "utensil": q.get("utensil", "knife") as String})
		_kitchen_queue.remove_at(i)

func _fire_phantom_hunt(def: Dictionary) -> void:
	var n: int = def.get("n", 3) as int
	var shot_dmg: float = def.get("dmg", 70.0) as float * PROJECTILE_SKILL_DAMAGE_MULT
	var spd: float = def.get("spd", 960.0) as float * 0.90
	var ph_level: int = 1
	if _has_skill("phantom_hunt"):
		ph_level = _get_skill("phantom_hunt").get("level", 1) as int
	var split_n: int = (def.get("spawn_n", 3) as int) + maxi(0, ph_level - 1)
	var split_pct: float = def.get("spawn_pct", 0.10) as float
	for i in n:
		var idx: int = _nearest_enemy_index(_player_pos, 1200.0)
		var dir: Vector2 = _player_move_dir
		if idx >= 0:
			dir = ((_enemies[idx]["pos"] as Vector2) - _player_pos).normalized()
		if dir.length_squared() < 0.01:
			dir = Vector2(float(_player_facing_x), 0.0)
		dir = dir.rotated((float(i) - float(n - 1) * 0.5) * 0.10)
		_bolts.append({
			"pos": _player_pos,
			"vel": dir * spd,
			"dmg": shot_dmg,
			"base_dmg": shot_dmg,
			"life": 1.8,
			"kind": "phantom_hunt",
			"spawn_n": split_n,
			"spawn_pct": split_pct,
		})

func _update_boss_intermission(_delta: float) -> void:
	var state: String = _boss_intermission.get("state", "none") as String
	if state == "none":
		if _boss_portal_confirm_layer != null:
			_boss_portal_confirm_layer.queue_free()
			_boss_portal_confirm_layer = null
		return
	var door_pos: Vector2 = _boss_intermission.get("door_pos", _player_pos) as Vector2
	var ladder_pos: Vector2 = _boss_intermission.get("ladder_pos", _player_pos) as Vector2
	if state == "await_choice":
		if _player_pos.distance_to(door_pos) < PLAYER_R + 150.0 and PurchaseStore.get_key_count(account_username) > 0:
			if _boss_portal_confirm_layer == null:
				_show_boss_portal_confirm()
		elif _player_pos.distance_to(ladder_pos) < PLAYER_R + 150.0:
			if _boss_portal_confirm_layer == null:
				_show_ladder_confirm()
	elif state == "await_ladder":
		if _player_pos.distance_to(ladder_pos) < PLAYER_R + 150.0:
			if _boss_portal_confirm_layer == null:
				_show_ladder_confirm()

func _show_ladder_confirm() -> void:
	if _boss_portal_confirm_layer != null:
		return
	var view: Vector2 = get_viewport_rect().size
	var layer := CanvasLayer.new()
	layer.layer = 125
	add_child(layer)
	_boss_portal_confirm_layer = layer

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.58)
	overlay.size = view
	layer.add_child(overlay)

	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.08, 0.06, 0.97)
	ps.corner_radius_top_left = 18
	ps.corner_radius_top_right = 18
	ps.corner_radius_bottom_right = 18
	ps.corner_radius_bottom_left = 18
	ps.border_color = Color(0.92, 0.76, 0.32, 0.90)
	ps.set_border_width_all(2)
	ps.content_margin_left = 18
	ps.content_margin_right = 18
	ps.content_margin_top = 14
	ps.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", ps)
	panel.custom_minimum_size = Vector2(min(view.x - 80.0, 700.0), 0.0)
	panel.position = Vector2((view.x - panel.custom_minimum_size.x) * 0.5, view.y * 0.33)
	layer.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	var title := Label.new()
	title.text = "Descend to Next Depth?" if not dungeon_mode.is_empty() else "Proceed to Next Wave?"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.76))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var msg := Label.new()
	msg.text = "Use the ladder to descend to the next dungeon depth?" if not dungeon_mode.is_empty() else "Use the ladder to advance to the next wave?"
	msg.add_theme_font_size_override("font_size", 26)
	msg.add_theme_color_override("font_color", Color(0.95, 0.82, 0.70))
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(msg)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)

	var cancel_btn := _pause_btn("Cancel", Color(0.20, 0.20, 0.26), Color(0.94, 0.94, 0.98))
	cancel_btn.custom_minimum_size = Vector2(0, 70)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cancel_btn)

	var use_btn := _pause_btn("Climb", Color(0.46, 0.30, 0.08), Color(1.0, 0.95, 0.85))
	use_btn.custom_minimum_size = Vector2(0, 70)
	use_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(use_btn)

	cancel_btn.pressed.connect(func() -> void:
		if _boss_portal_confirm_layer != null:
			_boss_portal_confirm_layer.queue_free()
			_boss_portal_confirm_layer = null
	)
	use_btn.pressed.connect(func() -> void:
		if _boss_portal_confirm_layer != null:
			_boss_portal_confirm_layer.queue_free()
			_boss_portal_confirm_layer = null
		_boss_intermission["state"] = "none"
		_wave += 1
		_start_wave(_wave)
	)

func _show_boss_portal_confirm() -> void:
	if _boss_portal_confirm_layer != null:
		return
	var view: Vector2 = get_viewport_rect().size
	var layer := CanvasLayer.new()
	layer.layer = 125
	add_child(layer)
	_boss_portal_confirm_layer = layer

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.58)
	overlay.size = view
	layer.add_child(overlay)

	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.08, 0.06, 0.97)
	ps.corner_radius_top_left = 18
	ps.corner_radius_top_right = 18
	ps.corner_radius_bottom_right = 18
	ps.corner_radius_bottom_left = 18
	ps.border_color = Color(0.92, 0.76, 0.32, 0.90)
	ps.set_border_width_all(2)
	ps.content_margin_left = 18
	ps.content_margin_right = 18
	ps.content_margin_top = 14
	ps.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", ps)
	panel.custom_minimum_size = Vector2(min(view.x - 80.0, 700.0), 0.0)
	panel.position = Vector2((view.x - panel.custom_minimum_size.x) * 0.5, view.y * 0.33)
	layer.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	var title := Label.new()
	title.text = "Unlock Portal?"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.76))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var msg := Label.new()
	msg.text = "Use 1 stash key to unlock the artifact portal and enter the boss challenge arena?"
	msg.add_theme_font_size_override("font_size", 26)
	msg.add_theme_color_override("font_color", Color(0.95, 0.82, 0.70))
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(msg)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)

	var cancel_btn := _pause_btn("Cancel", Color(0.20, 0.20, 0.26), Color(0.94, 0.94, 0.98))
	cancel_btn.custom_minimum_size = Vector2(0, 70)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cancel_btn)

	var use_btn := _pause_btn("Use Key", Color(0.46, 0.30, 0.08), Color(1.0, 0.95, 0.85))
	use_btn.custom_minimum_size = Vector2(0, 70)
	use_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(use_btn)

	cancel_btn.pressed.connect(func() -> void:
		if _boss_portal_confirm_layer != null:
			_boss_portal_confirm_layer.queue_free()
			_boss_portal_confirm_layer = null
	)
	use_btn.pressed.connect(func() -> void:
		if is_story_test_run:
			push_warning("Permanent key use is disabled during a Story test run.")
			return
		if PurchaseStore.consume_key(account_username):
			_boss_key_spent_this_run += 1
			if _boss_portal_confirm_layer != null:
				_boss_portal_confirm_layer.queue_free()
				_boss_portal_confirm_layer = null
			_enter_boss_challenge_arena()
	)

func _enter_boss_challenge_arena() -> void:
	_boss_intermission["state"] = "arena"
	_boss_intermission["arena_center"] = _player_pos
	_boss_intermission["arena_half"] = BOSS_ARENA_HALF
	_enemies.clear()
	_wave_spawn_q.clear()
	var ws: float = 1.0 + float(max(_wave, 1) - 1) * 0.22
	var btype: String = _next_portal_boss_type()
	var data: Dictionary = _make_enemy_data(btype, ws * 1.45)
	data["spawn_pos"] = _random_arena_edge_spawn_pos(_player_pos, BOSS_ARENA_HALF, 56.0)
	_spawn_enemy_from(data)

func _random_arena_edge_spawn_pos(center: Vector2, half: Vector2, inset: float = 56.0) -> Vector2:
	var h: Vector2 = Vector2(max(half.x - inset, 32.0), max(half.y - inset, 32.0))
	var side: int = randi() % 4
	match side:
		0:
			return center + Vector2(randf_range(-h.x, h.x), -h.y)
		1:
			return center + Vector2(randf_range(-h.x, h.x), h.y)
		2:
			return center + Vector2(-h.x, randf_range(-h.y, h.y))
		_:
			return center + Vector2(h.x, randf_range(-h.y, h.y))

func _on_arena_boss_cleared() -> void:
	_boss_intermission = {
		"state": "await_ladder",
		"door_pos": _player_pos + Vector2(250.0, 20.0),
		"ladder_pos": _player_pos + Vector2(-250.0, 20.0),
		"arena_center": _player_pos,
		"arena_half": BOSS_ARENA_HALF,
		"last_boss_wave": _wave,
	}
	var reward: Dictionary = {} if is_story_test_run else _award_random_artifact()
	if not reward.is_empty():
		_boss_artifact_results.append(reward)
	if reward.get("duplicated", false) as bool and _boss_key_spent_this_run > 0:
		PurchaseStore.add_keys(account_username, 1)
		_boss_key_spent_this_run -= 1
	# Add artifact visual drop with a short pickup grace period so it is visible.
	var art: Dictionary = reward.get("artifact", {}) as Dictionary
	if not art.is_empty():
		var spawn_dir: Vector2 = Vector2.from_angle(randf() * TAU)
		var spawn_offset: Vector2 = spawn_dir * randf_range(84.0, 128.0)
		_artifact_drops.append({
			"pos": _player_pos + spawn_offset,
			"life": 25.0,
			"pickup_delay": 0.85,
			"artifact": art,
		})

func _award_random_artifact() -> Dictionary:
	if account_username.is_empty():
		return {}
	var art: Dictionary = ArtifactStore.roll_artifact()
	var duplicated: bool = _has_artifact_in_inventory(art)
	if duplicated:
		return {"artifact": art, "duplicated": true}
	ArtifactStore.add_artifact_to_stash(account_username, art)
	return {"artifact": art, "duplicated": false}

func _has_artifact_in_inventory(artifact: Dictionary) -> bool:
	if account_username.is_empty() or artifact.is_empty():
		return false
	var target_name: String = artifact.get("name", "") as String
	if target_name.is_empty():
		return false
	for a in ArtifactStore.load_stash(account_username):
		if typeof(a) == TYPE_DICTIONARY and str((a as Dictionary).get("name", "")) == target_name:
			return true
	var equipped_all: Dictionary = ArtifactStore.load_equipped(account_username)
	for char_id in equipped_all.keys():
		var slot_any = equipped_all.get(char_id, {})
		if typeof(slot_any) != TYPE_DICTIONARY:
			continue
		var slots: Dictionary = slot_any as Dictionary
		for slot in range(2):
			var item = slots.get("slot_%d" % slot, null)
			if item != null and typeof(item) == TYPE_DICTIONARY and str((item as Dictionary).get("name", "")) == target_name:
				return true
	return false


func _spawn_combo_arc(a: Vector2, b: Vector2, col: Color, life: float = 0.14, width: float = 2.0) -> void:
	_combo_arcs.append({
		"a": a,
		"b": b,
		"life": life,
		"max_life": life,
		"col": col,
		"width": width,
	})

func _fire_inferno_plasma(n: int, dmg: float, spd: float, chain_dmg: float, chains: int, emp_r: float, emp_dmg: float) -> void:
	_play_skill_sfx("skill_fireball", -5.0, 1.08, 0.10)
	var plasma_dmg: float = dmg * TARGET_SKILL_DAMAGE_MULT
	if _enemies.is_empty():
		for i in n:
			var dir: Vector2 = Vector2(1, 0).rotated(float(i) / float(max(n, 1)) * TAU)
			_fireballs.append({
				"pos": _player_pos,
				"vel": dir * spd,
				"dmg": plasma_dmg,
				"trail_dmg": plasma_dmg * 0.14,
				"life": 3.8,
				"kind": "inferno_plasma",
				"chain_dmg": chain_dmg,
				"chains": chains,
				"emp_r": emp_r,
				"emp_dmg": emp_dmg,
			})
		return
	var checked: Array[int] = []
	for i in n:
		var best: float = INF
		var best_j: int = -1
		for j in _enemies.size():
			if checked.has(j):
				continue
			var d: float = _player_pos.distance_to(_enemies[j]["pos"] as Vector2)
			if d < best:
				best = d
				best_j = j
		var dir: Vector2
		if best_j >= 0:
			checked.append(best_j)
			dir = ((_enemies[best_j]["pos"] as Vector2) - _player_pos).normalized()
		else:
			dir = Vector2(1, 0).rotated(float(i) / float(max(n, 1)) * TAU)
		_fireballs.append({
			"pos": _player_pos,
			"vel": dir * spd,
			"dmg": plasma_dmg,
			"trail_dmg": plasma_dmg * 0.14,
			"life": 3.8,
			"kind": "inferno_plasma",
			"chain_dmg": chain_dmg,
			"chains": chains,
			"emp_r": emp_r,
			"emp_dmg": emp_dmg,
		})

func _inferno_chain(start_pos: Vector2, start_idx: int, chain_dmg: float, chains: int) -> void:
	var used: Array[int] = [start_idx]
	var last_pos: Vector2 = start_pos
	for _step in chains:
		var best: float = INF
		var best_idx: int = -1
		for i in _enemies.size():
			if used.has(i):
				continue
			var ep: Vector2 = _enemies[i]["pos"] as Vector2
			var d: float = ep.distance_to(last_pos)
			if d < best and d <= 260.0:
				best = d
				best_idx = i
		if best_idx < 0:
			break
		var target_pos: Vector2 = _enemies[best_idx]["pos"] as Vector2
		_spawn_combo_arc(last_pos, target_pos, Color(1.0, 0.95, 0.52, 0.95), 0.16, 2.2)
		_hit_enemy(best_idx, chain_dmg)
		used.append(best_idx)
		last_pos = target_pos

func _inferno_emp(center: Vector2, radius: float, dmg: float) -> void:
	_waves.append({"pos": center, "r": 0.0, "max_r": radius, "life": 0.40, "max_life": 0.40, "kind": "inferno_emp"})
	for i in range(_enemies.size() - 1, -1, -1):
		var ep: Vector2 = _enemies[i]["pos"] as Vector2
		if ep.distance_to(center) <= radius + (_enemies[i]["r"] as float):
			var falloff: float = clamp(1.0 - ep.distance_to(center) / max(radius, 1.0), 0.35, 1.0)
			_hit_enemy(i, dmg * falloff)

func _fire_frozen_lances(n: int, dmg: float, spd: float, freeze_r: float, slow: float, explode_r: float, explode_dmg: float) -> void:
	_play_skill_sfx("skill_pierce_arrow", -6.0, 0.95, 0.10)
	var lance_dmg: float = dmg * PROJECTILE_SKILL_DAMAGE_MULT
	if _enemies.is_empty():
		for i in n:
			var dir: Vector2 = Vector2(1, 0).rotated(_orb_angle + float(i) / float(max(n, 1)) * TAU)
			_pierce_arrows.append({
				"pos": _player_pos,
				"vel": dir * spd,
				"dmg": lance_dmg,
				"life": PIERCE_ARROW_LIFE,
				"kind": "frozen_lance",
				"freeze_r": freeze_r,
				"slow": slow,
				"explode_r": explode_r,
				"explode_dmg": explode_dmg,
			})
		return
	var checked: Array[int] = []
	for _i in n:
		var best: float = INF
		var best_j: int = -1
		for j in _enemies.size():
			if checked.has(j):
				continue
			var d: float = _player_pos.distance_to(_enemies[j]["pos"] as Vector2)
			if d < best:
				best = d
				best_j = j
		var dir: Vector2 = Vector2(1, 0).rotated(_orb_angle)
		if best_j >= 0:
			checked.append(best_j)
			dir = ((_enemies[best_j]["pos"] as Vector2) - _player_pos).normalized()
		_pierce_arrows.append({
			"pos": _player_pos,
			"vel": dir * spd,
			"dmg": lance_dmg,
			"life": PIERCE_ARROW_LIFE,
			"kind": "frozen_lance",
			"freeze_r": freeze_r,
			"slow": slow,
			"explode_r": explode_r,
			"explode_dmg": explode_dmg,
		})

func _trigger_frozen_lance_explosion(center: Vector2, radius: float, dmg: float, slow: float) -> void:
	_waves.append({"pos": center, "r": 0.0, "max_r": radius, "life": 0.42, "max_life": 0.42, "kind": "frozen_lance"})
	for i in range(_enemies.size() - 1, -1, -1):
		var ep: Vector2 = _enemies[i]["pos"] as Vector2
		if ep.distance_to(center) <= radius + (_enemies[i]["r"] as float):
			_hit_enemy(i, dmg)
			if i < _enemies.size():
				var base_s: float = _enemies[i]["base_spd"] as float
				var min_s: float = max(base_s * max(0.50 - float(_level) * 0.012, 0.20), 30.0)
				_enemies[i]["spd"] = max((_enemies[i]["spd"] as float) * (1.0 - slow), min_s)

func _fire_divine_volley(n: int, dmg: float, spd: float, splits: int, pierce_hits: int) -> void:
	_play_skill_sfx("skill_split_arrow", -6.0, 1.05, 0.10)
	var arrow_dmg: float = dmg * PROJECTILE_SKILL_DAMAGE_MULT
	var aim_dir: Vector2 = Vector2.RIGHT.rotated(_orb_angle)
	if not _enemies.is_empty():
		var best: float = INF
		var best_j: int = 0
		for j in _enemies.size():
			var d: float = _player_pos.distance_to(_enemies[j]["pos"] as Vector2)
			if d < best:
				best = d
				best_j = j
		aim_dir = ((_enemies[best_j]["pos"] as Vector2) - _player_pos).normalized()
	for i in n:
		var spread_t: float = (float(i) - float(n - 1) * 0.5) / float(max(n - 1, 1))
		var dir: Vector2 = aim_dir.rotated(spread_t * 0.22)
		_bolts.append({
			"pos": _player_pos,
			"vel": dir * spd,
			"dmg": arrow_dmg,
			"life": BOLT_LIFE,
			"kind": "divine_volley",
			"splits_left": splits,
			"pierce_left": pierce_hits,
		})

func _spawn_divine_split(source_pos: Vector2, forward: Vector2, spd: float, dmg: float, splits_left: int, pierce_hits: int) -> void:
	for ang in [-0.30, 0.0, 0.30]:
		var dir: Vector2 = forward.rotated(float(ang)).normalized()
		_bolts.append({
			"pos": source_pos,
			"vel": dir * spd,
			"dmg": dmg,
			"life": BOLT_LIFE,
			"kind": "divine_volley",
			"splits_left": splits_left,
			"pierce_left": pierce_hits,
		})

func _trigger_thunder_god_pulse(radius: float, dmg: float, mark_t: float, chain_count: int, chain_dmg: float) -> void:
	_play_skill_sfx("skill_elec_wave", -4.0, 1.05, 0.16)
	_waves.append({"pos": _player_pos, "r": 0.0, "max_r": radius, "life": 0.52, "max_life": 0.52, "kind": "thunder_god"})
	var marked: Array[int] = []
	for i in range(_enemies.size() - 1, -1, -1):
		var ep: Vector2 = _enemies[i]["pos"] as Vector2
		if ep.distance_to(_player_pos) <= radius + (_enemies[i]["r"] as float):
			_enemies[i]["tg_mark_t"] = mark_t
			marked.append(i)
			_hit_enemy(i, dmg)
	if marked.is_empty():
		return
	var used: Array[int] = []
	var start_idx: int = -1
	var start_dist: float = INF
	for idx_variant in marked:
		var idx: int = idx_variant as int
		if idx < 0 or idx >= _enemies.size():
			continue
		if start_idx < 0:
			start_idx = idx
		var d: float = (_enemies[idx]["pos"] as Vector2).distance_to(_player_pos)
		if d < start_dist:
			start_dist = d
			start_idx = idx
	if start_idx < 0 or start_idx >= _enemies.size():
		return
	used.append(start_idx)
	var last_pos: Vector2 = _enemies[start_idx]["pos"] as Vector2
	for _step in chain_count:
		var best: float = INF
		var best_idx: int = -1
		for idx_variant in marked:
			var idx: int = idx_variant as int
			if idx < 0 or idx >= _enemies.size() or used.has(idx):
				continue
			var ep: Vector2 = _enemies[idx]["pos"] as Vector2
			var d: float = ep.distance_to(last_pos)
			if d < best and d <= 290.0:
				best = d
				best_idx = idx
		if best_idx < 0:
			break
		var target_pos: Vector2 = _enemies[best_idx]["pos"] as Vector2
		_spawn_combo_arc(last_pos, target_pos, Color(1.0, 1.0, 0.60, 0.98), 0.18, 2.6)
		_hit_enemy(best_idx, chain_dmg)
		used.append(best_idx)
		last_pos = target_pos

func _apply_poison_to_enemy_idx(idx: int, duration: float, dps: float) -> void:
	if idx < 0 or idx >= _enemies.size():
		return
	_enemies[idx]["poison_t"] = max(_enemies[idx].get("poison_t", 0.0) as float, duration)
	_enemies[idx]["poison_dps"] = max(_enemies[idx].get("poison_dps", 0.0) as float, dps)
	if not _enemies[idx].has("poison_tick_t"):
		_enemies[idx]["poison_tick_t"] = 0.5

func _spread_poison(center: Vector2, radius: float, duration: float, dps: float) -> void:
	for i in range(_enemies.size() - 1, -1, -1):
		if (_enemies[i]["pos"] as Vector2).distance_to(center) <= radius + (_enemies[i]["r"] as float):
			_apply_poison_to_enemy_idx(i, duration, dps)

func _trigger_toxic_lightning_pulse(radius: float, dmg: float, spread_r: float, poison_dps: float) -> void:
	_play_skill_sfx("skill_elec_wave", -5.0, 0.95, 0.18)
	_waves.append({"pos": _player_pos, "r": 0.0, "max_r": radius, "life": 0.50, "max_life": 0.50, "kind": "toxic_lightning"})
	for i in range(_enemies.size() - 1, -1, -1):
		var ep: Vector2 = _enemies[i]["pos"] as Vector2
		if ep.distance_to(_player_pos) <= radius + (_enemies[i]["r"] as float):
			var poisoned: bool = (_enemies[i].get("poison_t", 0.0) as float) > 0.0
			_hit_enemy(i, dmg)
			if poisoned:
				_spawn_combo_arc(ep, ep + Vector2.RIGHT * 0.1, Color(0.70, 1.0, 0.36, 0.9), 0.10, 2.8)
				_spread_poison(ep, spread_r, 2.8, poison_dps * 0.85)

func _fire_ice_orbs(n: int, dmg: float, spd: float, freeze_r: float, slow: float, lvl: int) -> void:
	_play_skill_sfx("skill_ice_orb", -6.0, 1.0, 0.12)
	var orb_dmg: float = dmg * TARGET_SKILL_DAMAGE_MULT
	# Fire n orbs in evenly spaced straight-line directions, aimed toward spread enemies
	# or uniformly spread if no enemies visible
	var dirs: Array[Vector2] = []
	if _enemies.is_empty():
		for i in n:
			dirs.append(Vector2(cos(float(i) / float(n) * TAU + _orb_angle), sin(float(i) / float(n) * TAU + _orb_angle)))
	else:
		var checked: Array[int] = []
		for _i in n:
			var best: float = INF
			var best_j: int = -1
			for j in _enemies.size():
				if checked.has(j):
					continue
				var d: float = _player_pos.distance_to(_enemies[j]["pos"] as Vector2)
				if d < best:
					best = d
					best_j = j
			if best_j >= 0:
				checked.append(best_j)
				dirs.append(((_enemies[best_j]["pos"] as Vector2) - _player_pos).normalized())
			else:
				dirs.append(Vector2(cos(float(_i) / float(n) * TAU), sin(float(_i) / float(n) * TAU)))
	for dir in dirs:
		_ice_orbs.append({"pos": _player_pos, "vel": dir * spd, "dmg": orb_dmg,
				"life": ICE_ORB_LIFE, "freeze_r": freeze_r, "slow": slow, "lvl": lvl})

func _update_ice_orbs(delta: float) -> void:
	for i in range(_ice_orbs.size() - 1, -1, -1):
		var b: Dictionary = _ice_orbs[i]
		b["pos"]  = (b["pos"] as Vector2) + (b["vel"] as Vector2) * delta
		b["life"] = (b["life"] as float) - delta
		if (b["life"] as float) <= 0.0:
			_ice_orbs.remove_at(i)
			continue
		var bp: Vector2 = b["pos"] as Vector2
		var fr: float   = b["freeze_r"] as float
		var slow: float = b["slow"] as float
		var dmg: float  = b["dmg"] as float
		for j in range(_enemies.size() - 1, -1, -1):
			if (_enemies[j]["pos"] as Vector2).distance_to(bp) < fr:
				_hit_enemy_element(j, dmg * delta, "ice")
				if j < _enemies.size():
					var base_s: float = (_enemies[j]["base_spd"] as float)
					var min_s: float = max(base_s * max(0.50 - float(_level) * 0.012, 0.20), 30.0)
					_enemies[j]["spd"] = max((_enemies[j]["spd"] as float) * (1.0 - slow * delta), min_s)

func _fire_split_arrows(n: int, dmg: float, spd: float, spread: float) -> void:
	_play_skill_sfx("skill_split_arrow", -7.0, 1.0, 0.12)
	var arrow_dmg: float = dmg * PROJECTILE_SKILL_DAMAGE_MULT
	var aim_dir: Vector2
	if _enemies.is_empty():
		aim_dir = Vector2(1, 0).rotated(_orb_angle)
	else:
		var best: float = INF
		var best_j: int = 0
		for j in _enemies.size():
			var d: float = _player_pos.distance_to(_enemies[j]["pos"] as Vector2)
			if d < best:
				best = d
				best_j = j
		aim_dir = ((_enemies[best_j]["pos"] as Vector2) - _player_pos).normalized()
	for i in n:
		var t: float = (float(i) - float(n - 1) * 0.5) / float(max(n - 1, 1)) * spread * 2.0
		var dir: Vector2 = aim_dir.rotated(t)
		_bolts.append({"pos": _player_pos, "vel": dir * spd, "dmg": arrow_dmg, "life": BOLT_LIFE, "kind": "split_arrow"})

func _fire_pierce_arrows(n: int, dmg: float, spd: float) -> void:
	_play_skill_sfx("skill_pierce_arrow", -7.0, 1.0, 0.12)
	var arrow_dmg: float = dmg * PROJECTILE_SKILL_DAMAGE_MULT
	if _enemies.is_empty():
		for i in n:
			var dir: Vector2 = Vector2(1, 0).rotated(_orb_angle + float(i) / float(n) * TAU)
			_pierce_arrows.append({"pos": _player_pos, "vel": dir * spd, "dmg": arrow_dmg, "life": PIERCE_ARROW_LIFE})
		return
	var checked: Array[int] = []
	for _i in n:
		var best: float = INF
		var best_j: int = -1
		for j in _enemies.size():
			if checked.has(j): continue
			var d: float = _player_pos.distance_to(_enemies[j]["pos"] as Vector2)
			if d < best:
				best = d
				best_j = j
		if best_j < 0: break
		checked.append(best_j)
		var dir: Vector2 = ((_enemies[best_j]["pos"] as Vector2) - _player_pos).normalized()
		_pierce_arrows.append({"pos": _player_pos, "vel": dir * spd, "dmg": arrow_dmg, "life": PIERCE_ARROW_LIFE})

func _fire_boomerangs(n: int, dmg: float, spd: float) -> void:
	_play_skill_sfx("skill_boomerang", -7.0, 1.0, 0.14)
	var boom_dmg: float = dmg * PROJECTILE_SKILL_DAMAGE_MULT
	var dirs: Array[Vector2] = []
	if _enemies.is_empty():
		for i in n:
			dirs.append(Vector2(1, 0).rotated(_orb_angle + float(i) / float(n) * TAU))
	else:
		var checked: Array[int] = []
		for _i in n:
			var best: float = INF
			var best_j: int = -1
			for j in _enemies.size():
				if checked.has(j): continue
				var d: float = _player_pos.distance_to(_enemies[j]["pos"] as Vector2)
				if d < best:
					best = d
					best_j = j
			if best_j >= 0:
				checked.append(best_j)
				dirs.append(((_enemies[best_j]["pos"] as Vector2) - _player_pos).normalized())
			else:
				dirs.append(Vector2(1, 0).rotated(float(_i) / float(n) * TAU))
	var life_dur: float = 3.0
	for dir in dirs:
		_boomerangs.append({"pos": _player_pos, "vel": dir * spd, "orig_vel": dir * spd,
				"dmg": boom_dmg, "life": life_dur, "max_life": life_dur, "returning": false})

func _fire_fireball(n: int, dmg: float, spd: float) -> void:
	_play_skill_sfx("skill_fireball", -6.0, 1.0, 0.12)
	var fire_dmg: float = dmg * TARGET_SKILL_DAMAGE_MULT
	if _enemies.is_empty():
		# No enemies — spread in evenly spaced directions
		for i in n:
			var dir: Vector2 = Vector2(1, 0).rotated(float(i) / float(n) * TAU)
			_fireballs.append({"pos": _player_pos, "vel": dir * spd,
				"dmg": fire_dmg, "trail_dmg": fire_dmg * 0.18, "life": 4.0})
		return
	var checked: Array[int] = []
	for _i in n:
		var best: float = INF
		var best_j: int = -1
		for j in _enemies.size():
			if checked.has(j): continue
			var d: float = _player_pos.distance_to(_enemies[j]["pos"] as Vector2)
			if d < best:
				best = d
				best_j = j
		if best_j >= 0:
			checked.append(best_j)
			var dir: Vector2 = ((_enemies[best_j]["pos"] as Vector2) - _player_pos).normalized()
			_fireballs.append({"pos": _player_pos, "vel": dir * spd,
				"dmg": fire_dmg, "trail_dmg": fire_dmg * 0.18, "life": 4.0})
		else:
			var dir: Vector2 = Vector2(1, 0).rotated(float(_i) / float(n) * TAU)
			_fireballs.append({"pos": _player_pos, "vel": dir * spd,
				"dmg": fire_dmg, "trail_dmg": fire_dmg * 0.18, "life": 4.0})

func _update_fireballs(delta: float) -> void:
	var vp: Rect2 = get_viewport_rect()
	# Advance fireballs, spawn trail segments, check direct hit
	for i in range(_fireballs.size() - 1, -1, -1):
		var fb: Dictionary = _fireballs[i]
		var fb_kind: String = fb.get("kind", "fireball") as String
		var old_pos: Vector2 = fb["pos"] as Vector2
		fb["pos"]  = old_pos + (fb["vel"] as Vector2) * delta
		fb["life"] = (fb["life"] as float) - delta
		var fbp: Vector2 = fb["pos"] as Vector2
		var sp: Vector2  = fbp - _camera.position + vp.size * 0.5
		if (fb["life"] as float) <= 0.0 or not vp.grow(30.0).has_point(sp):
			if fb_kind == "inferno_plasma":
				_inferno_emp(fbp, fb.get("emp_r", 100.0) as float, fb.get("emp_dmg", 18.0) as float)
			_fireballs.remove_at(i)
			continue
		# Spawn a trail segment every ~50 px — fewer segments for performance
		if not fb.has("trail_acc"): fb["trail_acc"] = 0.0
		fb["trail_acc"] = (fb["trail_acc"] as float) + (fb["vel"] as Vector2).length() * delta
		if (fb["trail_acc"] as float) >= 50.0 and _fire_trails.size() < 40:
			fb["trail_acc"] = 0.0
			var trail_life: float = 1.8 * (1.0 + _ring_bonus("burn_duration"))
			_fire_trails.append({
				"pos": old_pos,
				"life": trail_life, "max_life": trail_life,
				"dmg_per_tick": fb["trail_dmg"] as float,
				"tick_t": 0.0,
				"r": 16.0
			})
		# Direct hit check
		for j in range(_enemies.size() - 1, -1, -1):
			if (_enemies[j]["iframes"] as float) > 0.0: continue
			if fbp.distance_to(_enemies[j]["pos"] as Vector2) < 10.0 + (_enemies[j]["r"] as float):
				if fb_kind == "inferno_plasma":
					var hit_pos: Vector2 = _enemies[j]["pos"] as Vector2
					_hit_enemy(j, fb["dmg"] as float)
					_inferno_chain(hit_pos, j, fb.get("chain_dmg", 0.0) as float, fb.get("chains", 0) as int)
					_inferno_emp(hit_pos, fb.get("emp_r", 100.0) as float, fb.get("emp_dmg", 18.0) as float)
				else:
					_hit_enemy_element(j, fb["dmg"] as float, "fire")
				_fireballs.remove_at(i)
				break

func _update_fire_trails(delta: float) -> void:
	# Tick each trail segment: damage enemies touching it every 0.35s
	for i in range(_fire_trails.size() - 1, -1, -1):
		var ft: Dictionary = _fire_trails[i]
		ft["life"]   = (ft["life"] as float) - delta
		if (ft["life"] as float) <= 0.0:
			_fire_trails.remove_at(i)
			continue
		ft["tick_t"] = (ft["tick_t"] as float) + delta
		if (ft["tick_t"] as float) >= 0.35:
			ft["tick_t"] = 0.0
			var ftp: Vector2 = ft["pos"] as Vector2
			var ftr: float   = ft["r"] as float
			for j in range(_enemies.size() - 1, -1, -1):
				if (_enemies[j]["iframes"] as float) > 0.0: continue
				if ftp.distance_to(_enemies[j]["pos"] as Vector2) < ftr + (_enemies[j]["r"] as float):
					_hit_enemy_element(j, ft["dmg_per_tick"] as float, "fire")

func _update_pierce_arrows(delta: float) -> void:
	var vp: Rect2 = get_viewport_rect()
	for i in range(_pierce_arrows.size() - 1, -1, -1):
		var b: Dictionary = _pierce_arrows[i]
		var bkind: String = b.get("kind", "pierce_arrow") as String
		b["pos"]  = (b["pos"] as Vector2) + (b["vel"] as Vector2) * delta
		b["life"] = (b["life"] as float) - delta
		var bp: Vector2 = b["pos"] as Vector2
		var sp: Vector2 = bp - _camera.position + vp.size * 0.5
		if (b["life"] as float) <= 0.0 or not vp.grow(30.0).has_point(sp):
			if bkind == "frozen_lance":
				_trigger_frozen_lance_explosion(
					bp,
					b.get("explode_r", 120.0) as float,
					b.get("explode_dmg", 30.0) as float,
					b.get("slow", 0.8) as float
				)
			_pierce_arrows.remove_at(i)
			continue
		for j in range(_enemies.size() - 1, -1, -1):
			if (_enemies[j]["iframes"] as float) > 0.0: continue
			if bp.distance_to(_enemies[j]["pos"] as Vector2) < BOLT_R + (_enemies[j]["r"] as float):
				var element := "lightning" if bkind == "bolt" else "physical"
				_hit_enemy_element(j, b["dmg"] as float, element)
				if bkind == "frozen_lance" and j < _enemies.size():
					var base_s: float = _enemies[j]["base_spd"] as float
					var min_s: float = max(base_s * max(0.50 - float(_level) * 0.012, 0.20), 30.0)
					_enemies[j]["spd"] = max((_enemies[j]["spd"] as float) * (1.0 - (b.get("slow", 0.8) as float) * 0.35), min_s)

func _update_boomerangs(delta: float) -> void:
	for i in range(_boomerangs.size() - 1, -1, -1):
		var b: Dictionary = _boomerangs[i]
		b["pos"]  = (b["pos"] as Vector2) + (b["vel"] as Vector2) * delta
		b["life"] = (b["life"] as float) - delta
		if (b["life"] as float) <= 0.0:
			_boomerangs.remove_at(i)
			continue
		if not (b["returning"] as bool) and (b["life"] as float) < (b["max_life"] as float) * 0.5:
			b["vel"]       = -((b["orig_vel"] as Vector2) * 1.15)
			b["returning"] = true
		var bp: Vector2 = b["pos"] as Vector2
		for j in range(_enemies.size() - 1, -1, -1):
			if (_enemies[j]["iframes"] as float) > 0.0: continue
			if bp.distance_to(_enemies[j]["pos"] as Vector2) < BOLT_R + (_enemies[j]["r"] as float):
				_hit_enemy(j, b["dmg"] as float)

func _update_aoe_flashes(delta: float) -> void:
	for i in range(_aoe_flashes.size() - 1, -1, -1):
		_aoe_flashes[i]["life"] = (_aoe_flashes[i]["life"] as float) - delta
		if (_aoe_flashes[i]["life"] as float) <= 0.0:
			_aoe_flashes.remove_at(i)

func _update_xp_orbs(delta: float) -> void:
	var cr: float = XP_COLLECT_R
	var magnet_active := _has_skill("magnet") or _has_skill("lucky_clover")
	cr *= 1.0 + _ring_bonus("pickup_radius")
	if _has_skill("magnet"):
		cr = (_slvl("magnet", _get_skill("magnet")["level"] as int))["rng"] as float
	if _has_skill("lucky_clover"):
		var _lc_rng: float = (_slvl("lucky_clover", _get_skill("lucky_clover")["level"] as int))["rng"] as float
		cr = max(cr, _lc_rng)
	for i in range(_xp_orbs.size() - 1, -1, -1):
		var orb: Dictionary = _xp_orbs[i]
		var op: Vector2     = orb["pos"] as Vector2
		var d: float        = op.distance_to(_player_pos)
		if d < cr:
			if magnet_active and d > XP_COLLECT_R:
				_play_skill_sfx("skill_magnet", -18.0, 1.0, 0.35)
			orb["pos"] = op.move_toward(_player_pos, 320.0 * delta)
		if d < 20.0:
			_gain_xp(orb["val"] as int)
			_xp_orbs.remove_at(i)

const MAX_ENEMIES: int = 150

# ─────────────────────────────────────────────────────────────────────────────
# ADVENTURE OBJECTIVES
# ─────────────────────────────────────────────────────────────────────────────

func _setup_adventure_mode() -> void:
	_reset_staged_objective_state()
	_chapter_one = null
	_chapter_two = null
	_chapter_three = null
	_chapter_four = null
	_chapter_five = null
	_story_stage_origin = _player_pos
	_story_previous_objective_pos = _player_pos
	_story_victory_started = false
	_story_victory_validated = false
	_story_primary_complete = false
	_story_required_boss_defeated = false
	_story_required_target_survived = false
	_objective_boss_active = false
	if not story_stage.is_empty():
		var objective := str(story_stage.get("objective", "escort"))
		if int(story_stage.get("chapter", 1)) > 1:
			_setup_custom_story_objective(objective, story_stage.get("objective_config", {}) as Dictionary)
			return
		_setup_chapter_one_stage(objective)
		_adventure_spawn_timer = 1.5
	elif dungeon_mode == "coin_burrow":
		_begin_coin_depth(_next_dungeon_depth())
	elif dungeon_mode == "forgecore":
		_begin_forge_depth(_next_dungeon_depth())

func _setup_custom_story_objective(objective: String, config: Dictionary) -> void:
	_story_custom_id = objective
	_story_custom_data = config.duplicate(true)
	_story_custom_progress = {}
	_story_custom_sequence.clear()
	_story_custom_timer = float(config.get("timer", 0.0))
	_story_custom_interaction = 0.0
	_story_custom_touch_lock = ""
	_story_custom_carried = ""
	_story_custom_phase = 0
	_story_custom_alert = 0.0
	_story_custom_target_enemy = -1
	_story_custom_failure = ""
	_reset_staged_objective_state()
	_story_stage_origin = _player_pos
	_story_previous_objective_pos = _player_pos
	_story_gate_remaining = 0
	_story_final_triggered = false
	_story_final_completed = false
	_story_final_remaining = 0
	_adventure_state = "story_custom"
	_adventure_progress = 0
	_adventure_target = int(config.get("count", 1))
	_adventure_props.clear()
	_enemies.clear()
	if int(story_stage.get("chapter", 0)) == 2:
		_setup_chapter_two_stage(objective)
		_adventure_spawn_timer = 0.8
		_sync_room_state(true)
		return
	if int(story_stage.get("chapter", 0)) == 3:
		_setup_chapter_three_stage(objective)
		_adventure_spawn_timer = 0.8
		_sync_room_state(true)
		return
	if int(story_stage.get("chapter", 0)) == 4:
		_setup_chapter_four_stage(objective)
		_adventure_spawn_timer = 1.2
		_sync_room_state(true)
		return
	if int(story_stage.get("chapter", 0)) == 5:
		_setup_chapter_five_stage(objective)
		_adventure_spawn_timer = 1.4
		_sync_room_state(true)
		return
	match objective:
		"frozen_braziers":
			_configure_staged_objectives(config)
		"ice_captives":
			_configure_staged_objectives(config)
		"thaw_runes":
			_story_custom_sequence = [0, 1, 2, 3]
			_story_custom_sequence.shuffle()
			_story_custom_timer = 5.0
			_story_custom_progress["entered"] = 0
			for i in 4:
				_spawn_custom_prop("thaw_rune", _story_objective_zone_position(i, 620.0), {"rune":i})
		"frost_mimic":
			_story_custom_timer = 1.0
			_spawn_next_mimic_chest()
		"frost_colossus":
			_configure_staged_objectives(config)
			_spawn_story_objective_enemy("shield_boss", "frost_colossus", 1.25, _player_pos + Vector2(0, -430))
		"cleanse_mire":
			_story_custom_progress = {"energy":0, "energy_needed":int(config.get("energy", 3))}
			_configure_staged_objectives(config)
		"plaguebeast":
			_story_custom_progress["escapes"] = 0
			_spawn_story_objective_enemy("normal_tank", "plaguebeast", 4.2, _custom_objective_position(1150.0))
			_spawn_custom_prop("tracker", _player_pos, {})
		"venom_harvest":
			_story_custom_progress = {"spider":0, "toad":0, "wasp":0, "phase":0}
		"fragile_cure":
			_story_custom_progress = {"vial":100.0, "checkpoints":0}
			_spawn_cure_checkpoint(0)
			_adventure_props.append_array(_custom_prop_ring("healing_fountain", 2, 480.0, 1.0))
		"grand_antidote":
			_story_custom_sequence = [0, 1, 2]
			_story_custom_sequence.shuffle()
			_story_custom_progress["submitted"] = 0
			_spawn_custom_prop("cauldron", _player_pos + Vector2(0, -160), {})
			_spawn_current_antidote_ingredient()
		"silent_descent":
			_story_custom_progress = {"alert":0.0, "lockdowns":0, "safe_points":0}
			var descent_direction: Vector2 = Vector2.UP.rotated(randf_range(-0.45, 0.45))
			var descent_side: Vector2 = descent_direction.rotated(PI * 0.5)
			for section in 3:
				var section_center: Vector2 = _story_stage_origin + descent_direction * (1150.0 + float(section) * 1250.0)
				_spawn_custom_prop("hiding_zone", section_center, {"section":section, "visited":false, "activation_progress":0.0})
				for side_sign in [-1.0, 1.0]:
					var patrol_side: Vector2 = descent_side * side_sign * (265.0 + float(section % 2) * 45.0)
					var patrol_start: Vector2 = section_center + patrol_side - descent_direction * 250.0
					var patrol_end: Vector2 = section_center + patrol_side + descent_direction * 250.0
					if side_sign < 0.0:
						var swap_position: Vector2 = patrol_start
						patrol_start = patrol_end
						patrol_end = swap_position
					_spawn_custom_prop("sentry", patrol_start, {"facing":patrol_start.direction_to(patrol_end), "patrol_start":patrol_start, "patrol_end":patrol_end, "patrol_target":patrol_end, "patrol_speed":82.0 + float(section) * 8.0})
			_spawn_custom_prop("citadel_gate", _story_stage_origin + descent_direction * 4900.0, {})
		"soul_liberation":
			_spawn_custom_prop("abyss_portal", _player_pos + Vector2(0, -650), {})
			_spawn_soul_chain()
		"mirror_labyrinth":
			_story_custom_progress["room"] = 0
			_spawn_mirror_room()
		"twin_eclipse":
			_story_custom_progress = {"first":-1, "window":0.0}
			_spawn_custom_prop("eclipse_obelisk", _story_stage_origin + Vector2(-700.0, 0.0), {"obelisk":0})
			_spawn_custom_prop("eclipse_obelisk", _story_stage_origin + Vector2(700.0, 0.0), {"obelisk":1})
			_spawn_story_gate_ambush(12)
		"abyss_king":
			_story_custom_phase = 1
			_story_custom_timer = 150.0
			_spawn_next_ritual_anchor()
	_adventure_spawn_timer = 0.8
	_story_log_phase("setup", objective)
	if _story_custom_timer > 0.0:
		_story_log("Timer started: %.2fs" % _story_custom_timer)
	_sync_room_state(true)

func _reset_staged_objective_state() -> void:
	_staged_objective_enabled = false
	_staged_objective_required = 0
	_staged_objective_generated = 0
	_staged_objective_active = 0
	_staged_objective_completed = 0
	_staged_objective_spawn_timer = 0.0
	_story_gate_remaining = 0

func _configure_staged_objectives(config: Dictionary) -> void:
	_staged_objective_enabled = bool(config.get("progressive_spawn", false))
	_staged_objective_required = int(config.get("count", 1))
	_staged_objective_spawn_timer = float(config.get("first_spawn_delay", 0.0))

func _update_staged_objective_spawning(delta: float) -> void:
	if not _staged_objective_enabled or _staged_objective_generated >= _staged_objective_required:
		return
	_staged_objective_spawn_timer = maxf(0.0, _staged_objective_spawn_timer - delta)
	var max_active: int = maxi(1, int(_story_custom_data.get("max_active_objectives", 1)))
	var wait_for_previous: bool = bool(_story_custom_data.get("spawn_after_previous_completed", true))
	if _staged_objective_spawn_timer > 0.0 or _staged_objective_active >= max_active or _story_gate_remaining > 0:
		return
	if wait_for_previous and _staged_objective_completed < _staged_objective_generated:
		return
	_spawn_next_staged_objective()

func _spawn_next_staged_objective() -> void:
	if _staged_objective_generated >= _staged_objective_required:
		return
	var sequence_index: int = _staged_objective_generated
	var zone_distance: float = float(_story_custom_data.get("objective_zone_distance", 700.0))
	var objective_pos: Vector2 = _story_objective_zone_position(sequence_index, zone_distance)
	match _story_custom_id:
		"frozen_braziers":
			_spawn_custom_prop("brazier", objective_pos, {"active":false, "order":sequence_index})
		"ice_captives":
			var prison_hp: float = 140.0 + float(sequence_index) * 28.0
			_spawn_custom_prop("ice_prison", objective_pos, {"hp":prison_hp, "max_hp":prison_hp})
		"frost_colossus":
			var crystal_hp: float = 200.0 + float(sequence_index) * 65.0
			_spawn_custom_prop("armour_crystal", objective_pos, {"hp":crystal_hp, "max_hp":crystal_hp})
		"cleanse_mire":
			_story_custom_progress["energy_needed"] = 3 + sequence_index
			_spawn_custom_prop("corrupted_pool", objective_pos, {})
		_:
			return
	_staged_objective_generated += 1
	_staged_objective_active += 1
	if _story_telemetry != null:
		_story_telemetry.objective_spawned(_story_custom_id, "required_generated=%d/%d active=%d" % [_staged_objective_generated, _staged_objective_required, _staged_objective_active])
	_story_previous_objective_pos = objective_pos

func _story_objective_zone_position(sequence_index: int, distance: float) -> Vector2:
	var directions: Array[Vector2] = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2(0.72, -0.69), Vector2(0.72, 0.69), Vector2(-0.72, 0.69), Vector2(-0.72, -0.69)]
	var direction: Vector2 = directions[sequence_index % directions.size()].normalized()
	var candidate := _story_stage_origin + direction * (distance + float(sequence_index % 3) * 110.0)
	if candidate.distance_to(_story_previous_objective_pos) < distance * 0.75:
		candidate = _story_stage_origin - direction * (distance + 160.0)
	return candidate

func _complete_staged_objective_instance() -> void:
	if not _staged_objective_enabled:
		_adventure_progress += 1
		return
	_staged_objective_active = maxi(0, _staged_objective_active - 1)
	_staged_objective_completed = mini(_staged_objective_required, _staged_objective_completed + 1)
	if _story_telemetry != null:
		_story_telemetry.objective_completed(_story_custom_id, "required_completed=%d/%d active=%d" % [_staged_objective_completed, _staged_objective_required, _staged_objective_active])
	_adventure_progress = _staged_objective_completed
	_staged_objective_spawn_timer = float(_story_custom_data.get("spawn_interval", 0.0))
	if _staged_objective_completed < _staged_objective_required:
		var ambush_counts: Array = _story_custom_data.get("ambush_counts", []) as Array
		var ambush_index: int = _staged_objective_completed - 1
		if ambush_index >= 0 and ambush_index < ambush_counts.size():
			_spawn_story_gate_ambush(int(ambush_counts[ambush_index]))
	_try_finish_staged_objectives()

func _spawn_story_gate_ambush(count: int) -> void:
	_story_gate_remaining = maxi(0, count)
	for enemy_index in count:
		var kind := "normal_tank" if enemy_index % 5 == 4 else ("normal_fast" if enemy_index % 3 == 2 else "normal")
		_spawn_story_objective_enemy(kind, "objective_gate", 1.0 + float(_staged_objective_completed) * 0.22, _player_pos + Vector2.RIGHT.rotated(float(enemy_index) * TAU / float(maxi(count, 1))) * randf_range(330.0, 470.0))

func _retry_staged_objective_instance() -> void:
	if not _staged_objective_enabled:
		return
	_staged_objective_active = maxi(0, _staged_objective_active - 1)
	_staged_objective_generated = maxi(_staged_objective_completed, _staged_objective_generated - 1)
	_staged_objective_spawn_timer = float(_story_custom_data.get("spawn_interval", 0.0))
	if _story_telemetry != null:
		_story_telemetry.retry("staged_objective_instance")

func _try_finish_staged_objectives() -> void:
	if not _staged_objective_enabled:
		return
	if _staged_objective_generated < _staged_objective_required or _staged_objective_completed < _staged_objective_required or _staged_objective_active > 0:
		return
	if bool(_story_custom_data.get("final_objective_requires_boss", false)):
		_story_custom_phase = maxi(_story_custom_phase, 1)
	else:
		_complete_custom_story_stage()

func _custom_objective_position(distance: float) -> Vector2:
	return _player_pos + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * distance

func _custom_prop_ring(kind: String, count: int, radius: float, hp: float) -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	for i in count:
		var angle := float(i) / float(count) * TAU - PI * 0.5
		props.append({"kind":kind, "pos":_player_pos + Vector2.from_angle(angle) * radius, "hp":hp, "max_hp":hp, "inside":false})
	return props

func _spawn_custom_prop(kind: String, pos: Vector2, extra: Dictionary) -> void:
	var prop := {"kind":kind, "pos":pos, "hp":1.0, "max_hp":1.0, "inside":false}
	prop.merge(extra, true)
	_adventure_props.append(prop)
	if _story_telemetry != null:
		_story_telemetry.objective_spawned(kind)

func _spawn_story_objective_enemy(kind: String, tag: String, strength: float, pos: Vector2) -> void:
	_spawn_enemy_from(_make_enemy_data(kind, strength * _story_stage_strength()))
	if _enemies.is_empty(): return
	var index := _enemies.size() - 1
	_enemies[index]["story_tag"] = tag
	_enemies[index]["pos"] = pos
	_enemies[index]["objective_max_hp"] = float(_enemies[index].get("hp", 1.0))
	_story_custom_target_enemy = index
	if _story_telemetry != null:
		var required_remaining: int = _story_final_remaining if tag == "story_final" else 0
		_story_telemetry.story_enemy_spawned(tag, _enemies.size(), required_remaining, 0)
		if _is_boss_kind(kind):
			_story_telemetry.log_event("Boss spawned: %s · objective=%s" % [kind, tag])

func _spawn_soul_chain() -> void:
	if _adventure_progress >= _adventure_target: return
	var chain_hp: float = 95.0 + float(_adventure_progress) * 18.0
	_spawn_custom_prop("soul_chain", _story_objective_zone_position(_adventure_progress, 720.0), {"hp":chain_hp, "max_hp":chain_hp})

func _spawn_mirror_room() -> void:
	_adventure_props = _custom_prop_ring("mirror_portal", 3, 360.0, 1.0)
	var correct := randi_range(0, 2)
	_story_custom_progress["correct"] = correct
	for i in _adventure_props.size(): _adventure_props[i]["portal"] = i

func _make_objective_ring(kind: String, count: int, radius: float, hp: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in count:
		var angle := float(i) / float(count) * TAU - PI * 0.5
		result.append({"kind":kind, "pos":_player_pos + Vector2(cos(angle), sin(angle)) * radius, "hp":hp, "max_hp":hp})
	return result

func _begin_coin_depth(depth: int) -> void:
	_wave = depth
	_dungeon_depth_cleared = maxi(_dungeon_depth_cleared, depth - 1)
	_adventure_state = "coin_hunt"
	_adventure_timer = 55.0 + minf(float(depth) * 1.5, 30.0)
	_adventure_progress = 0
	_adventure_target = 5
	_adventure_spawn_timer = 1.0
	_adventure_props.clear()
	_spawn_coin_safe()
	_enemies.clear()
	_sync_room_state(true)

func _begin_forge_depth(depth: int) -> void:
	_wave = depth
	_dungeon_depth_cleared = maxi(_dungeon_depth_cleared, depth - 1)
	_adventure_state = "forge_activate"
	_adventure_progress = 0
	_adventure_target = 3
	_adventure_spawn_timer = 1.0
	_adventure_props.clear()
	_spawn_forge()
	_enemies.clear()
	_sync_room_state(true)

func _next_dungeon_depth() -> int:
	var profile := ProgressionStore.load_profile(account_username)
	var depths: Dictionary = profile.get("dungeon_depths", {}) as Dictionary
	return maxi(1, int(depths.get(dungeon_mode, 0)) + 1)

func _dungeon_objective_position() -> Vector2:
	var view := get_viewport_rect().size
	var distance := maxf(maxf(view.x, view.y) * 0.62, 520.0)
	return _player_pos + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * distance

func _spawn_coin_safe() -> void:
	var safe_hp := 85.0 + float(_wave) * 22.0
	_adventure_props.append({"kind":"safe", "pos":_dungeon_objective_position(), "hp":safe_hp, "max_hp":safe_hp})

func _spawn_forge() -> void:
	var hp_bonus := 1.4 if _forge_modifier == "reinforced" else 1.0
	var forge_hp := (180.0 + float(_wave) * 26.0) * hp_bonus
	var process_time := 12.0 + minf(float(_wave) * 0.75, 12.0)
	_adventure_props.append({"kind":"forge", "pos":_dungeon_objective_position(), "hp":forge_hp, "max_hp":forge_hp, "charge":0.0, "target_charge":process_time, "active":false})

func _update_adventure_mode(delta: float) -> void:
	if _adventure_state.is_empty() or _adventure_state.ends_with("choice") or _objective_boss_active:
		return
	_adventure_spawn_timer -= delta
	var is_c3_venom_harvest: bool = _adventure_state == "story_custom" and _chapter_three != null and _chapter_three.stage_number == 3
	var is_story_ambient: bool = _adventure_state == "story_custom" and not story_stage.is_empty()
	var is_silent_descent: bool = _adventure_state == "story_custom" and _story_custom_id == "silent_descent"
	var adventure_enemy_cap := 70 if _adventure_state == "story_defend" else (mini(48 + _wave * 5, 110) if not dungeon_mode.is_empty() else (32 if is_silent_descent else (50 if is_c3_venom_harvest else (48 if is_story_ambient else 42))))
	var custom_spawns_enabled := _adventure_state != "story_chapter_one" and _story_gate_remaining <= 0 and not _story_final_triggered
	if _chapter_two != null and _chapter_two.stage_number == 3 and _chapter_two.phase == "sequence_reveal":
		custom_spawns_enabled = false
	if _chapter_two != null and _chapter_two.stage_number == 5:
		custom_spawns_enabled = false
	if custom_spawns_enabled and _adventure_state != "story_nests" and _adventure_spawn_timer <= 0.0 and _enemies.size() < adventure_enemy_cap:
		var defense_progress := clampf((120.0 - _adventure_timer) / 120.0, 0.0, 1.0) if _adventure_state == "story_defend" else 0.0
		var spawn_interval := maxf(0.42, 0.85 - defense_progress * 0.38) if _adventure_state == "story_defend" else (1.05 if _adventure_state == "story_escort" else (maxf(0.42, 1.75 - float(max(_wave, 1)) * 0.055) if not dungeon_mode.is_empty() else maxf(0.8, 3.0 - float(max(_wave, 1)) * 0.08)))
		if is_story_ambient:
			spawn_interval = 1.65 if is_silent_descent else (1.55 if is_c3_venom_harvest else 1.70)
		_adventure_spawn_timer = spawn_interval
		var count: int = 4 + floori(defense_progress * 4.0) if _adventure_state == "story_defend" else (3 if _adventure_state == "story_escort" else 2 + mini(floori(float(max(_wave, 1)) / 2.0), 8))
		if is_story_ambient:
			count = 3 + (mini(_chapter_three.count("regions_complete"), 1) if is_c3_venom_harvest else 0)
		var story_defend_strength := 1.0
		if _adventure_state == "story_defend": story_defend_strength += (120.0 - _adventure_timer) / 90.0
		for i in count:
			var kind := "normal_tank" if dungeon_mode == "forgecore" and randf() < 0.7 else ("normal_fast" if randf() < 0.45 else "normal")
			if _adventure_state == "story_custom" and _story_custom_id == "venom_harvest":
				var venom_phase: int = int(_story_custom_progress.get("phase", 0))
				kind = "normal_fast" if venom_phase == 0 else ("normal_tank" if venom_phase == 1 else "normal")
			var story_strength := _story_stage_strength() if not story_stage.is_empty() else 1.0
			_spawn_enemy_from(_make_enemy_data(kind, (0.82 + float(max(_wave, 1)) * 0.12) * story_defend_strength * story_strength))
	match _adventure_state:
		"story_chapter_one": _update_chapter_one_stage(delta)
		"story_escort_wait": pass
		"story_escort": _update_story_escort(delta)
		"story_defend_wait": pass
		"story_defend": _update_defense_objective(delta, true)
		"story_nests": _update_story_nests(delta)
		"story_keys": _update_story_keys(delta)
		"story_hazards": _update_story_hazards(delta)
		"story_custom": _update_custom_story_objective(delta)
		"coin_hunt": _update_coin_hunt(delta)
		"forge_activate": _update_forges(delta)

func _update_custom_story_objective(delta: float) -> void:
	if _chapter_two != null and int(story_stage.get("chapter", 0)) == 2:
		_update_chapter_two_stage(delta)
		return
	if _chapter_three != null and int(story_stage.get("chapter", 0)) == 3:
		_update_chapter_three_stage(delta)
		return
	if _chapter_four != null and int(story_stage.get("chapter", 0)) == 4:
		_update_chapter_four_stage(delta)
		return
	if _chapter_five != null and int(story_stage.get("chapter", 0)) == 5:
		_update_chapter_five_stage(delta)
		return
	_update_staged_objective_spawning(delta)
	match _story_custom_id:
		"frozen_braziers": _update_frozen_braziers(delta)
		"ice_captives": _update_custom_breakables(delta, "ice_prison", 185.0)
		"thaw_runes": _update_thaw_runes(delta)
		"frost_mimic": _update_frost_mimic(delta)
		"frost_colossus": _update_custom_breakables(delta, "armour_crystal", 185.0)
		"cleanse_mire": _update_cleanse_mire(delta)
		"plaguebeast": _update_plaguebeast()
		"venom_harvest": _update_venom_harvest()
		"fragile_cure": _update_fragile_cure(delta)
		"grand_antidote": _update_grand_antidote()
		"silent_descent": _update_silent_descent(delta)
		"soul_liberation": _update_soul_liberation(delta)
		"mirror_labyrinth": _update_mirror_labyrinth()
		"twin_eclipse": _update_twin_eclipse(delta)
		"abyss_king": _update_abyss_king(delta)

func _setup_chapter_five_stage(objective: String) -> void:
	_chapter_five = ChapterFiveStageControllerClass.new()
	_chapter_five.reset(int(story_stage.get("chapter_stage", 1)))
	_story_custom_phase = 1
	_story_custom_progress = {}
	_story_custom_timer = 0.0
	match objective:
		"silent_descent":
			_chapter_five.enter("route_selection")
			_story_custom_progress = {"detection_time":0.0, "scan_ambush_cooldown":0.0}
		"soul_liberation":
			_chapter_five.enter("spirit_rescue")
			_chapter_five.set_count("spirits_required", 6)
			_spawn_custom_prop("abyss_portal", _story_stage_origin + Vector2(0.0, -920.0), {"suppression":0.0})
			_spawn_custom_prop("spirit_safe_zone", _story_stage_origin + Vector2(0.0, 280.0), {})
			_spawn_c5_soul_chain(0)
		"mirror_labyrinth":
			_chapter_five.enter("mirror_room")
			_spawn_c5_mirror_room()
		"twin_eclipse":
			_chapter_five.enter("obelisk_preparation")
			var obelisk_a: Vector2 = _story_stage_origin + Vector2(-1250.0, -180.0)
			var obelisk_b: Vector2 = _story_stage_origin + Vector2(1250.0, 180.0)
			_spawn_custom_prop("eclipse_obelisk", obelisk_a, {"obelisk":0, "stabilized":false, "progress":0.0})
			_spawn_custom_prop("eclipse_obelisk", obelisk_b, {"obelisk":1, "stabilized":false, "progress":0.0})
			_spawn_custom_prop("eclipse_seal", obelisk_a + Vector2(230.0, 0.0), {"obelisk":0, "hp":180.0, "max_hp":180.0})
			_spawn_custom_prop("eclipse_ring", obelisk_b + Vector2(-230.0, 0.0), {"obelisk":1, "progress":0.0})
			_spawn_custom_prop("eclipse_shortcut", _story_stage_origin, {"active":false, "progress":0.0})
		"abyss_king":
			_chapter_five.enter("ritual_anchors")
			_chapter_five.set_timer("ritual", 210.0)
			_chapter_five.set_count("anchors_destroyed", 0)
			_chapter_five.set_flag("boss_spawned")
			_spawn_story_objective_enemy("abyss_king_boss", "abyss_king", 2.4, _story_stage_origin + Vector2(0.0, -430.0))
			_spawn_c5_anchors()
	_story_log_phase("setup", _chapter_five.phase)

func _c5_enter_phase(next_phase: String) -> void:
	var previous: String = _chapter_five.enter(next_phase)
	_story_custom_phase += 1
	_story_log_phase(previous, next_phase)

func _update_chapter_five_stage(delta: float) -> void:
	match _chapter_five.stage_number:
		1: _update_c5_silent_descent(delta)
		2: _update_c5_soul_liberation(delta)
		3: _update_c5_mirror_labyrinth()
		4: _update_c5_twin_eclipse(delta)
		5: _update_c5_abyss_king(delta)

func _begin_c5_infiltration(route: String) -> void:
	if _chapter_five == null or _chapter_five.stage_number != 1 or _chapter_five.phase != "route_selection":
		return
	_chapter_five.route = route
	_chapter_five.set_flag("route_selected")
	_chapter_five.set_flag("infiltration_started")
	_c5_enter_phase("infiltration")
	var direction: Vector2 = Vector2.UP.rotated(randf_range(-0.30, 0.30))
	var side: Vector2 = direction.rotated(PI * 0.5)
	var spacing: float = 1450.0 if route == "shadow" else (1120.0 if route == "mechanism" else 900.0)
	var sentries_per_section: int = 1 if route == "shadow" else (2 if route == "mechanism" else 3)
	for section in 3:
		var center: Vector2 = _story_stage_origin + direction * (1100.0 + float(section) * spacing)
		_spawn_custom_prop("hiding_zone", center + (side * 230.0 if route == "shadow" else Vector2.ZERO), {"section":section, "visited":false, "activation_progress":0.0})
		if route == "mechanism":
			_spawn_custom_prop("security_switch", center - side * 330.0, {"section":section, "disabled":false, "progress":0.0})
		for sentry_index in sentries_per_section:
			var lateral: float = (float(sentry_index) - float(sentries_per_section - 1) * 0.5) * 280.0
			var start: Vector2 = center + side * lateral - direction * 310.0
			var finish: Vector2 = center + side * lateral + direction * 310.0
			_spawn_custom_prop("sentry", start, {"section":section, "state":"unaware", "suspicion":0.0, "facing":start.direction_to(finish), "patrol_start":start, "patrol_end":finish, "patrol_target":finish, "patrol_speed":72.0 + float(sentry_index) * 9.0, "disabled":false})
	var gate_distance: float = 1100.0 + spacing * 3.0
	_spawn_custom_prop("citadel_gate", _story_stage_origin + direction * gate_distance, {"unlock":0.0, "opened":false})
	_story_log("Route selected: %s" % route)

func _update_c5_silent_descent(delta: float) -> void:
	if _chapter_five.phase == "route_selection":
		return
	var hidden: bool = false
	var detected: bool = false
	var current_checkpoint: int = _chapter_five.count("checkpoints_reached")
	for prop_index in _adventure_props.size():
		var prop: Dictionary = _adventure_props[prop_index]
		var kind: String = str(prop.get("kind", ""))
		var pos: Vector2 = prop.get("pos", Vector2.ZERO) as Vector2
		if kind == "hiding_zone" and pos.distance_to(_player_pos) < 165.0:
			hidden = true
			if int(prop.get("section", -1)) == current_checkpoint and not bool(prop.get("visited", false)):
				prop["activation_progress"] = minf(10.0, float(prop.get("activation_progress", 0.0)) + delta)
				if float(prop["activation_progress"]) >= 10.0:
					prop["visited"] = true
					current_checkpoint = _chapter_five.add_count("checkpoints_reached")
					_story_log("Infiltration checkpoint reached: %d/3" % current_checkpoint)
				_adventure_props[prop_index] = prop
		elif kind == "security_switch" and not bool(prop.get("disabled", false)) and pos.distance_to(_player_pos) < 170.0:
			prop["progress"] = minf(4.0, float(prop.get("progress", 0.0)) + delta)
			if float(prop["progress"]) >= 4.0:
				prop["disabled"] = true
				_chapter_five.add_count("mechanisms_disabled")
				_story_log("Security mechanism disabled")
			_adventure_props[prop_index] = prop
		elif kind == "sentry" and not bool(prop.get("disabled", false)):
			if _chapter_five.route == "mechanism" and int(prop.get("section", -1)) < _chapter_five.count("mechanisms_disabled"):
				prop["disabled"] = true
				prop["state"] = "disabled"
				_adventure_props[prop_index] = prop
				continue
			var target: Vector2 = prop.get("patrol_target", pos) as Vector2
			var start: Vector2 = prop.get("patrol_start", pos) as Vector2
			var finish: Vector2 = prop.get("patrol_end", pos) as Vector2
			if pos.distance_to(target) < 8.0:
				target = start if target.distance_to(finish) < 8.0 else finish
				prop["patrol_target"] = target
			var move_direction: Vector2 = pos.direction_to(target)
			prop["facing"] = move_direction
			pos = pos.move_toward(target, float(prop.get("patrol_speed", 78.0)) * delta)
			prop["pos"] = pos
			var in_cone: bool = pos.distance_to(_player_pos) < 410.0 and absf(move_direction.angle_to(pos.direction_to(_player_pos))) < 0.58 and not hidden
			var suspicion: float = clampf(float(prop.get("suspicion", 0.0)) + (38.0 if in_cone else -24.0) * delta, 0.0, 100.0)
			prop["suspicion"] = suspicion
			prop["state"] = "alerted" if suspicion >= 100.0 else ("searching" if suspicion >= 65.0 else ("suspicious" if suspicion > 0.0 else "unaware"))
			detected = detected or in_cone
			if suspicion >= 100.0 and not bool(prop.get("ambush_triggered", false)):
				prop["ambush_triggered"] = true
				_spawn_silent_descent_ambush(4)
				_story_log("Detection state: Alerted")
			_adventure_props[prop_index] = prop
		elif kind == "citadel_gate" and current_checkpoint >= 3:
			if pos.distance_to(_player_pos) < 180.0:
				if _chapter_five.count("lockdowns") == 0:
					prop["unlock"] = minf(8.0, float(prop.get("unlock", 0.0)) + delta)
					if float(prop["unlock"]) >= 8.0:
						prop["opened"] = true
						_chapter_five.set_flag("gate_opened")
						_chapter_five.set_flag("silent_finale_selected")
						_c5_enter_phase("quiet_exit")
						_spawn_custom_prop("final_threshold", pos + _story_stage_origin.direction_to(pos) * 650.0, {})
				else:
					prop["opened"] = true
					_chapter_five.set_flag("gate_opened")
					_chapter_five.set_flag("detected_finale_selected")
					_c5_enter_phase("moving_escape")
					_spawn_custom_prop("final_threshold", pos + pos.direction_to(_player_pos) * -850.0, {})
					_spawn_silent_descent_ambush(8)
					_story_log("Detected finale started: moving escape")
				_adventure_props[prop_index] = prop
		elif kind == "final_threshold" and pos.distance_to(_player_pos) < 160.0:
			_chapter_five.set_flag("final_threshold_crossed")
	if hidden != _chapter_five.flag("hidden"):
		_chapter_five.set_flag("hidden", hidden)
		_story_log("Hiding state changed: %s" % ("hidden" if hidden else "exposed"))
	if _chapter_five.flag("final_threshold_crossed") and not _chapter_five.flag("transition_pending"):
		_chapter_five.set_flag("final_route_complete")
		_chapter_five.set_flag("primary_complete")
		_story_primary_complete = true
		_request_story_victory("chapter_five_infiltration_complete")
	var alert_rate: float = -18.0 if hidden else (13.0 if detected else -7.0)
	_chapter_five.adjust_meter("alert", alert_rate * delta)
	_story_custom_alert = _chapter_five.meter("alert")
	if _story_custom_alert >= 100.0:
		if _chapter_five.count("lockdowns") == 0:
			_chapter_five.set_count("lockdowns", 1)
			_chapter_five.set_meter("alert", 55.0)
			_story_custom_alert = 55.0
			_spawn_silent_descent_ambush(6)
			_story_log("Alert threshold: first lockdown")
		else:
			_fail_custom_story_stage("Second citadel lockdown triggered.")

func _spawn_c5_soul_chain(index: int) -> void:
	var chain_pos: Vector2 = _story_objective_zone_position(index + 1, 700.0 + float(index % 2) * 180.0)
	_spawn_custom_prop("soul_chain", chain_pos, {"soul":index, "hp":125.0 + float(index) * 22.0, "max_hp":125.0 + float(index) * 22.0})
	_chapter_five.add_count("chains_generated")

func _update_c5_soul_liberation(delta: float) -> void:
	if _chapter_five.phase == "portal_sealing":
		_update_c5_portal_seal(delta)
		return
	for prop_index in range(_adventure_props.size() - 1, -1, -1):
		var prop: Dictionary = _adventure_props[prop_index]
		var kind: String = str(prop.get("kind", ""))
		var pos: Vector2 = prop.get("pos", Vector2.ZERO) as Vector2
		if kind == "soul_chain" and pos.distance_to(_player_pos) < 180.0:
			prop["hp"] = float(prop.get("hp", 1.0)) - (34.0 + float(_level) * 3.0) * delta
			if float(prop["hp"]) <= 0.0:
				var soul_id: int = int(prop.get("soul", 0))
				_adventure_props.remove_at(prop_index)
				_spawn_custom_prop("released_soul", pos, {"soul":soul_id, "spirit_type":soul_id % 3, "captured":false, "saved":false})
				_chapter_five.add_count("spirits_released")
				_story_log("Spirit released: %d" % (soul_id + 1))
				continue
			_adventure_props[prop_index] = prop
		elif kind == "released_soul":
			var portal_index: int = _find_adventure_prop("abyss_portal")
			var safe_index: int = _find_adventure_prop("spirit_safe_zone")
			if portal_index < 0 or safe_index < 0: continue
			var portal_pos: Vector2 = _adventure_props[portal_index].pos as Vector2
			var safe_pos: Vector2 = _adventure_props[safe_index].pos as Vector2
			var binder_near: bool = false
			for enemy in _enemies:
				if str(enemy.get("story_tag", "")) == "c5_soul_binder" and (enemy.pos as Vector2).distance_to(pos) < 220.0:
					binder_near = true
					break
			var was_captured: bool = bool(prop.get("captured", false))
			prop["captured"] = binder_near
			if binder_near != was_captured:
				_story_log("Spirit capture state changed: %s" % ("captured" if binder_near else "released"))
			if not binder_near:
				var guided: bool = pos.distance_to(_player_pos) < 230.0
				var target: Vector2 = safe_pos if guided else portal_pos
				var speed: float = [62.0, 88.0, 52.0][int(prop.get("spirit_type", 0))]
				pos = pos.move_toward(target, speed * delta)
				prop["pos"] = pos
			if pos.distance_to(safe_pos) < 105.0:
				_adventure_props.remove_at(prop_index)
				var saved: int = _chapter_five.add_count("spirits_saved")
				_player_hp = minf(_player_max_hp, _player_hp + _player_max_hp * 0.08)
				_story_log("Spirit saved: %d/6" % saved)
				continue
			if pos.distance_to(portal_pos) < 90.0:
				_adventure_props.remove_at(prop_index)
				_chapter_five.add_count("spirits_lost")
				_chapter_five.adjust_meter("abyss_pressure", 18.0)
				var recovery_id: int = _chapter_five.count("chains_generated")
				_spawn_c5_soul_chain(recovery_id)
				_story_log("Spirit lost: recovery chain generated")
				continue
			_adventure_props[prop_index] = prop
	var active_spirits: int = _count_adventure_props("released_soul")
	var active_chains: int = _count_adventure_props("soul_chain")
	var unresolved: int = active_spirits + active_chains
	var generated: int = _chapter_five.count("chains_generated")
	if _chapter_five.count("spirits_saved") < 6 and generated < 6 + _chapter_five.count("spirits_lost") and unresolved < (2 if generated >= 2 else 1):
		_spawn_c5_soul_chain(generated)
	if active_spirits > 0 and _find_story_enemy("c5_soul_binder") < 0 and _enemies.size() < 28:
		_spawn_story_objective_enemy("normal_tank", "c5_soul_binder", 1.35, _custom_objective_position(520.0))
	if _chapter_five.count("spirits_saved") >= 6 and active_spirits == 0:
		_c5_enter_phase("portal_sealing")
		_adventure_props.clear()
		for seal_index in 3:
			_spawn_custom_prop("portal_seal", _story_stage_origin + Vector2.from_angle(float(seal_index) * TAU / 3.0) * 420.0, {"seal":seal_index, "progress":0.0, "stable":false})
		_spawn_story_objective_enemy("portal_keeper_boss", "c5_portal_keeper", 2.2, _story_stage_origin + Vector2(0.0, -520.0))
		_chapter_five.set_flag("portal_sealing_started")
		_chapter_five.set_flag("boss_spawned")

func _update_c5_portal_seal(delta: float) -> void:
	var stable_count: int = 0
	for prop_index in _adventure_props.size():
		var prop: Dictionary = _adventure_props[prop_index]
		if str(prop.get("kind", "")) != "portal_seal": continue
		if (prop.pos as Vector2).distance_to(_player_pos) < 175.0:
			prop["progress"] = minf(6.0, float(prop.get("progress", 0.0)) + delta)
		if float(prop.get("progress", 0.0)) >= 6.0:
			prop["stable"] = true
		if bool(prop.get("stable", false)): stable_count += 1
		_adventure_props[prop_index] = prop
	_chapter_five.set_count("seals_stable", stable_count)
	if stable_count >= 3 and _chapter_five.flag("boss_defeated"):
		_chapter_five.set_flag("portal_sealed")
		_chapter_five.set_flag("primary_complete")
		_story_primary_complete = true
		_request_story_victory("chapter_five_portal_sealed")

func _spawn_c5_mirror_room() -> void:
	var room_index: int = _chapter_five.count("rooms_completed")
	var room: Dictionary = _chapter_five.generate_mirror_room(room_index, int(story_stage.get("chapter_stage", 3)) * 1000 + room_index)
	_adventure_props.clear()
	var mirrors: Array = room.get("mirrors", []) as Array
	for portal_index in 3:
		var portal_data: Dictionary = mirrors[portal_index] as Dictionary
		var portal_position: Vector2 = _story_stage_origin + Vector2.from_angle(-PI * 0.5 + float(portal_index - 1) * 1.25) * 480.0
		_spawn_custom_prop("mirror_portal", portal_position, {"portal":portal_index, "symbol":portal_data.symbol, "direction":portal_data.direction, "pulses":portal_data.pulses, "inside":portal_position.distance_to(_player_pos) < 115.0})
	_spawn_custom_prop("mirror_clue", _story_stage_origin + Vector2(0.0, 180.0), {"text":str(room.get("clue", ""))})
	_chapter_five.set_flag("clue_state_valid", ChapterFiveStageControllerClass.validate_mirror_room(room))
	_story_log("Mirror clue generated: room=%d clue=%s" % [room_index + 1, str(room.get("clue", ""))])

func _update_c5_mirror_labyrinth() -> void:
	if _chapter_five.phase == "guardian":
		var exit_index: int = _find_adventure_prop("labyrinth_exit")
		if exit_index >= 0 and (_adventure_props[exit_index].pos as Vector2).distance_to(_player_pos) < 160.0:
			_chapter_five.set_flag("labyrinth_exit_reached")
			if _chapter_five.flag("guardian_defeated"):
				_finish_c5_mirror_guardian()
		return
	for prop_index in _adventure_props.size():
		var prop: Dictionary = _adventure_props[prop_index]
		if str(prop.get("kind", "")) != "mirror_portal": continue
		var inside: bool = (prop.pos as Vector2).distance_to(_player_pos) < 115.0
		if inside and not bool(prop.get("inside", false)):
			var selected: int = int(prop.get("portal", -1))
			var correct: int = int(_chapter_five.mirror_room.get("correct", -2))
			_story_log("Mirror selected: room=%d portal=%d" % [_chapter_five.count("rooms_completed") + 1, selected + 1])
			if selected == correct:
				_chapter_five.remember_mirror()
				var completed: int = _chapter_five.add_count("rooms_completed")
				_story_log("Mirror room solved: %d/4" % completed)
				if completed >= 4:
					_c5_enter_phase("guardian")
					_adventure_props.clear()
					_spawn_custom_prop("labyrinth_exit", _story_stage_origin + Vector2(0.0, -250.0), {"reached":false})
					_spawn_story_objective_enemy("mirror_guardian_boss", "c5_mirror_guardian", 2.1 + float(_chapter_five.count("wrong_choices")) * 0.16, _story_stage_origin + Vector2(0.0, -520.0))
					_chapter_five.set_flag("guardian_spawned")
					_chapter_five.set_flag("boss_spawned")
				else: _spawn_c5_mirror_room()
			else:
				_chapter_five.add_count("wrong_choices")
				_chapter_five.adjust_meter("abyss_pressure", 12.0)
				_spawn_silent_descent_ambush(3)
				_story_log("Wrong mirror: recoverable reflection room")
				_spawn_c5_mirror_room()
			return
		prop["inside"] = inside
		_adventure_props[prop_index] = prop

func _finish_c5_mirror_guardian() -> void:
	if _chapter_five == null or _chapter_five.stage_number != 3: return
	if not _chapter_five.flag("labyrinth_exit_reached"):
		_story_log("Guardian defeated: reach the Labyrinth Exit")
		return
	_chapter_five.set_flag("primary_complete")
	_story_primary_complete = true
	_request_story_victory("chapter_five_mirror_guardian_defeated")

func _update_c5_twin_eclipse(delta: float) -> void:
	if _chapter_five.phase == "obelisk_preparation":
		var obelisk_a_was_stable: bool = _chapter_five.flag("obelisk_a_stabilized")
		var obelisk_b_was_stable: bool = _chapter_five.flag("obelisk_b_stabilized")
		_update_custom_breakables(delta, "eclipse_seal", 190.0)
		for prop_index in _adventure_props.size():
			var prop: Dictionary = _adventure_props[prop_index]
			var kind: String = str(prop.get("kind", ""))
			if kind == "eclipse_ring" and (prop.pos as Vector2).distance_to(_player_pos) < 185.0:
				prop["progress"] = minf(6.0, float(prop.get("progress", 0.0)) + delta)
				if float(prop["progress"]) >= 6.0: _chapter_five.set_flag("obelisk_b_stabilized")
				_adventure_props[prop_index] = prop
			elif kind == "eclipse_shortcut" and (prop.pos as Vector2).distance_to(_player_pos) < 175.0:
				prop["progress"] = minf(4.0, float(prop.get("progress", 0.0)) + delta)
				if float(prop["progress"]) >= 4.0:
					prop["active"] = true
					_chapter_five.set_flag("route_prepared")
				_adventure_props[prop_index] = prop
		if _find_adventure_prop("eclipse_seal") < 0: _chapter_five.set_flag("obelisk_a_stabilized")
		if not obelisk_a_was_stable and _chapter_five.flag("obelisk_a_stabilized"):
			_story_log("Obelisk A stabilized")
		if not obelisk_b_was_stable and _chapter_five.flag("obelisk_b_stabilized"):
			_story_log("Obelisk B stabilized")
		if _chapter_five.flag("obelisk_a_stabilized") and _chapter_five.flag("obelisk_b_stabilized"):
			_chapter_five.set_flag("preparation_complete")
	elif _chapter_five.phase == "sync_attempt":
		if _chapter_five.tick_timer("sync", delta) <= 0.0:
			_chapter_five.adjust_meter("eclipse_pressure", 12.0)
			_chapter_five.add_count("sync_failures")
			_c5_enter_phase("obelisk_preparation")
			_story_log("Synchronization failed: attempt reset")
			return
		for prop in _adventure_props:
			if str(prop.get("kind", "")) == "eclipse_obelisk" and int(prop.get("obelisk", -1)) == 1 and (prop.pos as Vector2).distance_to(_player_pos) < 170.0:
				_chapter_five.set_flag("sync_succeeded")
				_chapter_five.set_timer("hold", 25.0)
				_chapter_five.set_timer("elite_disrupt", 4.0)
				_c5_enter_phase("sync_hold")
				_spawn_story_objective_enemy("eclipse_elite_boss", "c5_eclipse_elite", 2.2, _story_stage_origin)
				_chapter_five.set_flag("boss_spawned")
				_story_log("Synchronization succeeded")
				return
	elif _chapter_five.phase == "sync_hold":
		_update_custom_breakables(delta, "eclipse_disruption", 175.0)
		var disruption_active: bool = _find_adventure_prop("eclipse_disruption") >= 0
		if disruption_active:
			_chapter_five.set_flag("elite_disruption_active")
		elif _chapter_five.flag("elite_disruption_active"):
			_chapter_five.set_flag("elite_disruption_active", false)
			_chapter_five.set_timer("elite_disrupt", 5.0)
			_story_log("Eclipse Elite disruption interrupted")
		elif not _chapter_five.flag("boss_defeated") and _chapter_five.tick_timer("elite_disrupt", delta) <= 0.0 and not _chapter_five.flag("sync_hold_complete"):
			var target_obelisk: int = _chapter_five.count("elite_disruptions") % 2
			var target_position: Vector2 = _story_stage_origin + Vector2(-1250.0, -180.0) if target_obelisk == 0 else _story_stage_origin + Vector2(1250.0, 180.0)
			_spawn_custom_prop("eclipse_disruption", target_position, {"hp":150.0, "max_hp":150.0, "obelisk":target_obelisk})
			_chapter_five.add_count("elite_disruptions")
			_chapter_five.set_flag("elite_disruption_active")
			_story_log("Eclipse Elite disruption started: Obelisk %s" % ("A" if target_obelisk == 0 else "B"))
		if not _chapter_five.flag("elite_disruption_active") and _chapter_five.tick_timer("hold", delta) <= 0.0:
			_chapter_five.set_flag("sync_hold_complete")
		if _chapter_five.flag("sync_hold_complete") and _chapter_five.flag("boss_defeated"):
			_chapter_five.set_flag("primary_complete")
			_story_primary_complete = true
			_request_story_victory("chapter_five_eclipse_synchronized")

func _begin_c5_eclipse_sync() -> void:
	if _chapter_five == null or _chapter_five.stage_number != 4 or not _chapter_five.flag("preparation_complete") or not _chapter_five.flag("route_prepared") or _chapter_five.phase != "obelisk_preparation": return
	var obelisk_a_index: int = -1
	for prop_index in _adventure_props.size():
		if str(_adventure_props[prop_index].get("kind", "")) == "eclipse_obelisk" and int(_adventure_props[prop_index].get("obelisk", -1)) == 0:
			obelisk_a_index = prop_index
			break
	if obelisk_a_index < 0 or (_adventure_props[obelisk_a_index].pos as Vector2).distance_to(_player_pos) > 210.0:
		_story_log("Synchronization start rejected: return to Obelisk A")
		return
	_chapter_five.set_flag("sync_attempt_started")
	_chapter_five.set_timer("sync", 14.0 if _chapter_five.flag("route_prepared") else 18.0)
	_c5_enter_phase("sync_attempt")
	_story_log("Synchronization attempt started")

func _spawn_c5_anchors() -> void:
	var anchor_types: Array[String] = ["dominion", "ruin", "reflection"]
	for anchor_index in 3:
		_spawn_custom_prop("ritual_anchor", _story_stage_origin + Vector2.from_angle(-PI * 0.5 + float(anchor_index) * TAU / 3.0) * 620.0, {"anchor":anchor_index, "anchor_type":anchor_types[anchor_index], "hp":330.0, "max_hp":330.0, "progress":0.0})

func _update_c5_abyss_king(delta: float) -> void:
	var boss_index: int = _find_story_enemy("abyss_king")
	if _chapter_five.phase == "ritual_anchors":
		if _chapter_five.tick_timer("ritual", delta) <= 0.0:
			_fail_custom_story_stage("The Abyss ritual consumed the throne room.")
			return
		var corrupted_add_count: int = 0
		for enemy in _enemies:
			if bool((enemy as Dictionary).get("corrupted", false)):
				corrupted_add_count += 1
		for prop_index in range(_adventure_props.size() - 1, -1, -1):
			var anchor: Dictionary = _adventure_props[prop_index]
			if str(anchor.get("kind", "")) != "ritual_anchor": continue
			var anchor_type: String = str(anchor.get("anchor_type", ""))
			if not bool(anchor.get("selected", false)) and (anchor.get("pos", Vector2.ZERO) as Vector2).distance_to(_player_pos) < 260.0:
				anchor["selected"] = true
				_story_log("Ritual anchor selected: %s" % anchor_type)
			var distance: float = (anchor.pos as Vector2).distance_to(_player_pos)
			var vulnerable: bool = (anchor_type == "dominion" and distance < 210.0) or (anchor_type == "ruin" and corrupted_add_count <= 8) or (anchor_type == "reflection" and fmod(_elapsed, 7.0) < 3.0)
			if vulnerable and distance < 230.0:
				anchor["hp"] = float(anchor.get("hp", 1.0)) - (32.0 + float(_level) * 3.0) * delta
			if float(anchor.get("hp", 1.0)) <= 0.0:
				var destroyed_type: String = anchor_type
				_adventure_props.remove_at(prop_index)
				var destroyed: int = _chapter_five.record_anchor_destroyed(destroyed_type)
				_chapter_five.adjust_meter("abyss_pressure", -12.0)
				_story_log("Anchor destroyed: %s · %d/3" % [destroyed_type, destroyed])
				continue
			_adventure_props[prop_index] = anchor
		if _chapter_five.count("anchors_destroyed") >= 3:
			_chapter_five.set_flag("anchor_transitions_complete")
			_c5_enter_phase("abyss_crown")
			_spawn_custom_prop("abyss_crown", _story_stage_origin + Vector2(0.0, -260.0), {"hp":520.0, "max_hp":520.0, "sections":4})
			_spawn_custom_prop("crown_seal", _story_stage_origin + Vector2(-330.0, 180.0), {"seal":0})
			_spawn_custom_prop("crown_seal", _story_stage_origin + Vector2(330.0, 180.0), {"seal":1})
			_chapter_five.set_flag("crown_spawned")
			_chapter_five.set_timer("crown_cycle", 3.0)
	elif _chapter_five.phase == "abyss_crown":
		if _chapter_five.tick_timer("crown_cycle", delta) <= 0.0:
			var crown_cycle: int = _chapter_five.add_count("crown_cycles")
			var seals_active: bool = _chapter_five.flag("seal_a_active") and _chapter_five.flag("seal_b_active")
			if seals_active:
				_chapter_five.set_timer("crown_vulnerable", 7.0)
				_chapter_five.set_flag("seal_a_active", false)
				_chapter_five.set_flag("seal_b_active", false)
				_story_log("Crown vulnerability opened: twin seals")
			elif crown_cycle % 2 == 0 and _find_story_enemy("c5_crown_channeler") < 0:
				_spawn_story_objective_enemy("normal_tank", "c5_crown_channeler", 2.0, _story_stage_origin + Vector2(0.0, 430.0))
				_story_log("Crown vulnerability objective: interrupt ritual channeler")
			_chapter_five.set_timer("crown_cycle", 5.0)
		for prop in _adventure_props:
			if str(prop.get("kind", "")) == "crown_seal" and (prop.pos as Vector2).distance_to(_player_pos) < 145.0:
				var seal_name: String = "a" if int(prop.get("seal", 0)) == 0 else "b"
				_chapter_five.set_flag("seal_%s_active" % seal_name)
		var vulnerable_time: float = _chapter_five.tick_timer("crown_vulnerable", delta)
		var crown_index: int = _find_adventure_prop("abyss_crown")
		if crown_index >= 0 and vulnerable_time > 0.0 and (_adventure_props[crown_index].pos as Vector2).distance_to(_player_pos) < 210.0:
			var crown: Dictionary = _adventure_props[crown_index]
			var previous_sections: int = int(crown.get("sections", 4))
			crown["hp"] = float(crown.get("hp", 1.0)) - (38.0 + float(_level) * 3.5) * delta
			var sections: int = ceili(float(crown["hp"]) / 130.0)
			crown["sections"] = maxi(0, sections)
			if sections < previous_sections:
				_chapter_five.set_count("crown_sections_broken", mini(4, _chapter_five.count("crown_sections_broken") + previous_sections - maxi(0, sections)))
				_story_log("Crown section broken: %d/4" % _chapter_five.count("crown_sections_broken"))
			if float(crown["hp"]) <= 0.0:
				_adventure_props.remove_at(crown_index)
				_chapter_five.set_flag("crown_destroyed")
				_chapter_five.set_flag("crown_transition_complete")
				_chapter_five.set_flag("final_phase_entered")
				_c5_enter_phase("final_boss_a")
				if boss_index >= 0:
					_enemies[boss_index]["shield_active"] = false
					_enemies[boss_index]["hp"] = _enemies[boss_index].get("objective_max_hp", _enemies[boss_index].hp)
				_story_log("Boss phase transition: Final Phase A")
			else: _adventure_props[crown_index] = crown
	elif _chapter_five.phase.begins_with("final_boss") and boss_index >= 0:
		var boss: Dictionary = _enemies[boss_index]
		var hp_ratio: float = float(boss.get("hp", 1.0)) / maxf(float(boss.get("objective_max_hp", 1.0)), 1.0)
		if hp_ratio <= 0.65 and _chapter_five.phase == "final_boss_a":
			_c5_enter_phase("final_boss_b")
			_spawn_custom_prop("healing_fountain", _story_stage_origin + Vector2(0.0, 260.0), {})
			_story_log("Boss phase transition: Final Phase B · warmth callback")
		elif hp_ratio <= 0.35 and _chapter_five.phase == "final_boss_b":
			_c5_enter_phase("final_boss_c")
			_story_log("Boss phase transition: Final Phase C · mirror attacks")
		elif hp_ratio <= 0.22 and _chapter_five.phase == "final_boss_c":
			_c5_enter_phase("desperation")
			_chapter_five.set_flag("desperation_entered")
			_story_log("Boss phase transition: Desperation")

func _count_adventure_props(kind: String) -> int:
	var count: int = 0
	for prop in _adventure_props:
		if str(prop.get("kind", "")) == kind: count += 1
	return count

func _c5_captured_spirit_count() -> int:
	var captured: int = 0
	for prop in _adventure_props:
		if str(prop.get("kind", "")) == "released_soul" and bool(prop.get("captured", false)):
			captured += 1
	return captured

func _setup_chapter_two_stage(objective: String) -> void:
	_chapter_two = ChapterTwoStageControllerClass.new()
	_chapter_two.reset(int(story_stage.get("chapter_stage", 1)))
	_c2_spawn_timer = 0.0
	_c2_interaction = 0.0
	_c2_cold_threshold = 0
	_c2_bonus_levels_pending = 0
	_story_custom_phase = 1
	_story_custom_progress = {}
	_story_custom_timer = 0.0
	_story_custom_carried = ""
	_adventure_progress = 0
	_adventure_target = int(_story_custom_data.get("count", 1))
	match objective:
		"frozen_braziers":
			_adventure_target = 4
			_chapter_two.set_count("braziers_generated", 0)
			_chapter_two.set_count("braziers_lit", 0)
			_chapter_two.enter("opening_cold")
			_spawn_c2_flamekeeper()
		"ice_captives":
			_adventure_target = 5
			_chapter_two.set_count("prisons_generated", 0)
			_chapter_two.set_count("prisons_destroyed", 0)
			_chapter_two.set_count("captives_released", 0)
			_chapter_two.set_count("captives_extracted", 0)
			_chapter_two.enter("rescue_1")
			_spawn_custom_prop("brazier", _story_stage_origin, {"active":true, "heat":100.0, "camp":true})
			_spawn_c2_prison(0)
		"thaw_runes":
			_adventure_target = 4
			_story_custom_sequence = [0, 1, 2, 3]
			_story_custom_sequence.shuffle()
			_story_custom_timer = 5.0
			_chapter_two.set_flag("sequence_generated")
			_chapter_two.set_flag("rune_sequence_started", false)
			_chapter_two.set_count("runes_correct", 0)
			_chapter_two.enter("sequence_reveal")
			var rune_slots: Array[int] = [0, 2, 4, 6]
			rune_slots.shuffle()
			for rune_index in 4:
				var rune_pos: Vector2 = _story_objective_zone_position(rune_slots[rune_index], 760.0)
				_spawn_custom_prop("thaw_rune", rune_pos, {"rune":rune_index, "feedback":"", "fixed_pos":rune_pos})
		"frost_mimic":
			_adventure_target = 6
			var real_chest: int = randi_range(0, _adventure_target - 1)
			_chapter_two.set_count("real_chest", real_chest)
			_chapter_two.set_count("clues_found", 0)
			_chapter_two.set_count("suspects_remaining", _adventure_target)
			_chapter_two.enter("treasury_investigation")
			for chest_index in _adventure_target:
				var chest_pos: Vector2 = _story_objective_zone_position(chest_index, 650.0)
				_spawn_custom_prop("mimic_chest", chest_pos, {"chest":chest_index, "real":chest_index == real_chest, "inspected":false, "excluded":false})
				_spawn_custom_prop("frost_clue", chest_pos + Vector2(0.0, 92.0), {"chest":chest_index})
		"frost_colossus":
			_adventure_target = 3
			_chapter_two.set_count("crystals_broken", 0)
			_chapter_two.set_count("armour_transitions", 0)
			_chapter_two.set_timer("attack_cycle", 4.0)
			_chapter_two.enter("armoured_colossus")
			for crystal_index in 3:
				var crystal_pos: Vector2 = _story_stage_origin + Vector2.from_angle(-PI * 0.5 + TAU * float(crystal_index) / 3.0) * 430.0
				_spawn_custom_prop("armour_crystal", crystal_pos, {"crystal":crystal_index, "hp":260.0, "max_hp":260.0, "exposed":false, "broken":false})
			_spawn_story_objective_enemy("shield_boss", "frost_colossus", 1.5, _story_stage_origin + Vector2(0.0, -180.0))
			_chapter_two.set_flag("boss_spawned")
	_story_log_phase("setup", _chapter_two.phase)
	_story_log("Objective activation: Chapter 2 stage %d" % _chapter_two.stage_number)

func _c2_enter_phase(next_phase: String) -> void:
	var previous: String = _chapter_two.enter(next_phase)
	_story_custom_phase += 1
	_story_log_phase(previous, next_phase)

func _update_chapter_two_stage(delta: float) -> void:
	_update_c2_cold_exposure(delta)
	match _chapter_two.stage_number:
		1: _update_c2_rekindle(delta)
		2: _update_c2_captives(delta)
		3: _update_c2_runes(delta)
		4: _update_c2_mimic(delta)
		5: _update_c2_colossus(delta)

func _update_c2_cold_exposure(delta: float) -> void:
	if _chapter_two.stage_number == 4:
		_chapter_two.cold_exposure = maxf(0.0, _chapter_two.cold_exposure - delta * 5.0)
		return
	var in_warmth: bool = false
	for prop in _adventure_props:
		if str(prop.get("kind", "")) == "brazier" and bool(prop.get("active", false)) and not bool(prop.get("suppressed", false)) and float(prop.get("heat", 0.0)) > 0.0:
			if (prop.get("pos", Vector2.ZERO) as Vector2).distance_to(_player_pos) <= 245.0:
				in_warmth = true
				break
	var cold_rate: float = 2.4 if _chapter_two.stage_number in [1, 2, 3] else 1.6
	if _chapter_two.stage_number == 2 and _chapter_two.phase == "blizzard_extraction":
		cold_rate = 4.0
	_chapter_two.cold_exposure = clampf(_chapter_two.cold_exposure + (-8.0 if in_warmth else cold_rate) * delta, 0.0, 100.0)
	var threshold: int = 100 if _chapter_two.cold_exposure >= 100.0 else (75 if _chapter_two.cold_exposure >= 75.0 else (50 if _chapter_two.cold_exposure >= 50.0 else 0))
	if threshold > _c2_cold_threshold:
		_c2_cold_threshold = threshold
		_story_log("Cold Exposure threshold: %d%%" % threshold)
	elif threshold == 0:
		_c2_cold_threshold = 0

func _spawn_c2_flamekeeper() -> void:
	if _find_story_enemy("c2_flamekeeper") >= 0 or _story_custom_carried == "flame_charge":
		return
	_spawn_story_objective_enemy("normal_tank", "c2_flamekeeper", 1.0, _custom_objective_position(650.0))
	_story_log("Objective activation: Flamekeeper")

func _spawn_c2_brazier(index: int) -> void:
	if index >= 4:
		return
	var position: Vector2 = _story_objective_zone_position(index, 620.0 + float(index) * 115.0)
	_spawn_custom_prop("brazier", position, {"order":index, "active":false, "heat":0.0, "suppressed":false})
	_chapter_two.set_count("braziers_generated", maxi(_chapter_two.count("braziers_generated"), index + 1))
	_story_log("Objective activation: Brazier %d" % (index + 1))

func _update_c2_rekindle(delta: float) -> void:
	_resolve_c2_suppressor_arrival()
	_c2_spawn_timer = maxf(0.0, _c2_spawn_timer - delta)
	if _c2_spawn_timer <= 0.0:
		_c2_spawn_timer = 7.0
		_spawn_c2_flamekeeper()
	var active_count: int = 0
	var lit_count: int = 0
	var reactivated_order: int = -1
	for prop_index in _adventure_props.size():
		var brazier: Dictionary = _adventure_props[prop_index]
		if str(brazier.get("kind", "")) != "brazier":
			continue
		if bool(brazier.get("active", false)):
			brazier["heat"] = maxf(0.0, float(brazier.get("heat", 0.0)) - delta * (0.28 if _chapter_two.count("braziers_lit") < 2 else 0.42))
			if float(brazier["heat"]) <= 0.0:
				brazier["active"] = false
				_story_log("Brazier heat change: Brazier %d went cold" % (int(brazier.get("order", 0)) + 1))
		if bool(brazier.get("active", false)):
			lit_count += 1
			if not bool(brazier.get("suppressed", false)):
				active_count += 1
		if (brazier.get("pos", Vector2.ZERO) as Vector2).distance_to(_player_pos) < 165.0 and _story_custom_carried == "flame_charge":
			brazier["active"] = true
			brazier["heat"] = 100.0
			brazier["suppressed"] = false
			_story_custom_carried = ""
			var order: int = int(brazier.get("order", 0))
			reactivated_order = order
			_chapter_two.set_count("braziers_lit", maxi(_chapter_two.count("braziers_lit"), order + 1))
			_story_log("Brazier heat change: Brazier %d rekindled" % (order + 1))
			if _chapter_two.count("braziers_generated") < 4:
				_spawn_c2_brazier(_chapter_two.count("braziers_generated"))
		_adventure_props[prop_index] = brazier
	if reactivated_order >= 0:
		for prop_index in range(_adventure_props.size() - 1, -1, -1):
			if str(_adventure_props[prop_index].get("kind", "")) == "c2_brazier_suppression" and int(_adventure_props[prop_index].get("order", -2)) == reactivated_order:
				_adventure_props.remove_at(prop_index)
		_story_custom_progress.erase("suppressed_brazier")
	_chapter_two.set_count("active_braziers", active_count)
	if _chapter_two.count("braziers_generated") == 0 and _story_custom_carried == "flame_charge":
		_spawn_c2_brazier(0)
	if _chapter_two.count("braziers_lit") >= 4 and active_count >= 4:
		if _chapter_two.phase != "warmth_stabilization":
			_c2_enter_phase("warmth_stabilization")
			_chapter_two.set_timer("stabilization", 22.0)
			_chapter_two.set_timer("suppression", 6.0)
			_story_log("Timer started: warmth stabilization 22s")
		else:
			if _chapter_two.tick_timer("suppression", delta) <= 0.0 and _find_story_enemy("c2_brazier_suppressor") < 0:
				var candidates: Array[int] = []
				for candidate_index in _adventure_props.size():
					if str(_adventure_props[candidate_index].get("kind", "")) == "brazier" and bool(_adventure_props[candidate_index].get("active", false)):
						candidates.append(candidate_index)
				if not candidates.is_empty():
					var suppress_index: int = candidates.pick_random()
					var suppressed_order: int = int(_adventure_props[suppress_index].get("order", 0))
					var suppression_pos: Vector2 = _adventure_props[suppress_index].get("pos", Vector2.ZERO) as Vector2
					_spawn_story_objective_enemy("normal_tank", "c2_brazier_suppressor", 1.35, _story_stage_origin)
					var suppressor_index: int = _find_story_enemy("c2_brazier_suppressor")
					if suppressor_index >= 0:
						_enemies[suppressor_index]["objective_target_pos"] = suppression_pos
						_enemies[suppressor_index]["objective_target_order"] = suppressed_order
					_story_log("Suppression growth approaching Brazier %d" % (suppressed_order + 1))
				_chapter_two.set_timer("suppression", 7.0)
			if _chapter_two.tick_timer("stabilization", delta) <= 0.0:
				_chapter_two.set_flag("warmth_stabilized")
				_chapter_two.set_flag("finale_complete")
				_chapter_two.set_flag("primary_complete")
				_story_primary_complete = true
				_request_story_victory("chapter_two_warmth_chain_stable")
	elif _chapter_two.phase == "warmth_stabilization":
		_c2_enter_phase("network_recovery")
		_chapter_two.set_timer("stabilization", 22.0)

func _resolve_c2_suppressor_arrival() -> void:
	var enemy_index: int = _find_story_enemy("c2_brazier_suppressor")
	if enemy_index < 0:
		return
	var target_order: int = int(_enemies[enemy_index].get("objective_target_order", -1))
	var target_pos: Vector2 = _enemies[enemy_index].get("objective_target_pos", Vector2.ZERO) as Vector2
	if (_enemies[enemy_index].get("pos", Vector2.ZERO) as Vector2).distance_to(target_pos) > 92.0:
		return
	for prop_index in _adventure_props.size():
		if str(_adventure_props[prop_index].get("kind", "")) != "brazier" or int(_adventure_props[prop_index].get("order", -2)) != target_order:
			continue
		_adventure_props[prop_index]["active"] = false
		_adventure_props[prop_index]["suppressed"] = true
		_adventure_props[prop_index]["heat"] = 0.0
		break
	_story_custom_progress["suppressed_brazier"] = target_order
	_spawn_custom_prop("c2_brazier_suppression", target_pos + Vector2(72.0, -24.0), {"order":target_order})
	_enemies.remove_at(enemy_index)
	_chapter_two.set_timer("stabilization", 22.0)
	_story_log("Brazier suppressed on arrival: %d · stabilization reset" % (target_order + 1))

func _spawn_c2_prison(index: int) -> void:
	var position: Vector2 = _story_objective_zone_position(index + 1, 720.0)
	var hp: float = 180.0 + float(index) * 35.0
	_spawn_custom_prop("ice_prison", position, {"prison":index, "hp":hp, "max_hp":hp, "regen":index == 1, "jailer":index >= 2})
	if index == 1:
		for crystal in 2:
			_spawn_custom_prop("armour_crystal", position + Vector2(-210.0 if crystal == 0 else 210.0, -120.0), {"prison_crystal":index, "hp":100.0, "max_hp":100.0})
	if index >= 2:
		_spawn_story_objective_enemy("normal_tank", "c2_jailer_%d" % index, 1.15 + float(index) * 0.12, position + Vector2(220.0, 0.0))
	_chapter_two.set_count("prisons_generated", index + 1)
	_story_log("Objective activation: Prison %d" % (index + 1))

func _update_c2_captives(delta: float) -> void:
	_update_c2_prisons(delta)
	var camp_position: Vector2 = _story_stage_origin
	var all_released: bool = _chapter_two.count("captives_released") >= 5
	var refrozen_count: int = 0
	for prop_index in range(_adventure_props.size() - 1, -1, -1):
		var captive: Dictionary = _adventure_props[prop_index]
		if str(captive.get("kind", "")) != "released_soul":
			continue
		var captive_pos: Vector2 = captive.get("pos", Vector2.ZERO) as Vector2
		if bool(captive.get("refrozen", false)):
			refrozen_count += 1
			if captive_pos.distance_to(_player_pos) < 145.0:
				captive["thaw"] = minf(3.0, float(captive.get("thaw", 0.0)) + delta)
				if float(captive["thaw"]) >= 3.0:
					captive["refrozen"] = false
					captive["refreeze"] = 0.0
					_story_log("Captive recovered from refreeze")
		else:
			captive_pos = captive_pos.move_toward(camp_position, (88.0 if all_released else 72.0) * delta)
			captive["pos"] = captive_pos
			var nearby_jailer: bool = false
			for enemy in _enemies:
				if str(enemy.get("story_tag", "")).begins_with("c2_jailer") and (enemy.get("pos", Vector2.ZERO) as Vector2).distance_to(captive_pos) < 250.0:
					nearby_jailer = true
					break
			captive["refreeze"] = clampf(float(captive.get("refreeze", 0.0)) + (18.0 if nearby_jailer else -12.0) * delta, 0.0, 100.0)
			if float(captive["refreeze"]) >= 100.0:
				captive["refrozen"] = true
				_story_log("Captive refrozen")
			if captive_pos.distance_to(camp_position) < 95.0 and not bool(captive.get("safe", false)):
				captive["safe"] = true
				_chapter_two.add_count("captives_extracted")
				_story_log("Captive extracted: %d/5" % _chapter_two.count("captives_extracted"))
		_adventure_props[prop_index] = captive
	_chapter_two.set_count("captives_refrozen", refrozen_count)
	if _chapter_two.count("captives_released") >= 5 and _chapter_two.phase != "blizzard_extraction":
		_c2_enter_phase("blizzard_extraction")
		_spawn_story_objective_enemy("normal_tank", "c2_jailer_elite", 2.2, _custom_objective_position(620.0))
	if _chapter_two.phase == "blizzard_extraction" and _chapter_two.count("captives_extracted") >= 5 and _find_story_enemy("c2_jailer_elite") < 0:
		_chapter_two.set_flag("jailer_elite_resolved")
		_chapter_two.set_flag("finale_complete")
		_chapter_two.set_flag("primary_complete")
		_story_primary_complete = true
		_request_story_victory("chapter_two_captives_extracted")

func _update_c2_prisons(delta: float) -> void:
	for prop_index in range(_adventure_props.size() - 1, -1, -1):
		var prop: Dictionary = _adventure_props[prop_index]
		var kind: String = str(prop.get("kind", ""))
		if kind == "armour_crystal" and prop.has("prison_crystal"):
			if (prop.get("pos", Vector2.ZERO) as Vector2).distance_to(_player_pos) < 175.0:
				prop["hp"] = float(prop.get("hp", 1.0)) - (32.0 + float(_level) * 3.0) * delta
				if float(prop["hp"]) <= 0.0:
					_adventure_props.remove_at(prop_index)
					continue
			_adventure_props[prop_index] = prop
		elif kind == "ice_prison":
			var prison_number: int = int(prop.get("prison", 0))
			var crystals_remain: bool = false
			for other in _adventure_props:
				if str(other.get("kind", "")) == "armour_crystal" and int(other.get("prison_crystal", -1)) == prison_number:
					crystals_remain = true
					break
			if bool(prop.get("regen", false)) and crystals_remain:
				prop["hp"] = minf(float(prop.get("max_hp", 1.0)), float(prop.get("hp", 1.0)) + 18.0 * delta)
			elif (prop.get("pos", Vector2.ZERO) as Vector2).distance_to(_player_pos) < 185.0:
				prop["hp"] = float(prop.get("hp", 1.0)) - (30.0 + float(_level) * 3.0) * delta
			if float(prop["hp"]) <= 0.0:
				var release_pos: Vector2 = prop.get("pos", Vector2.ZERO) as Vector2
				_adventure_props.remove_at(prop_index)
				_chapter_two.add_count("prisons_destroyed")
				_chapter_two.add_count("captives_released")
				_spawn_custom_prop("released_soul", release_pos, {"captive":prison_number, "refreeze":0.0, "refrozen":false, "safe":false})
				_story_log("Captive released: %d/5" % _chapter_two.count("captives_released"))
				if _chapter_two.count("prisons_generated") < 5:
					_spawn_c2_prison(_chapter_two.count("prisons_generated"))
				continue
			_adventure_props[prop_index] = prop

func _update_c2_runes(delta: float) -> void:
	if _chapter_two.phase == "sequence_reveal":
		_story_custom_timer = maxf(0.0, _story_custom_timer - delta)
		if _story_custom_timer <= 0.0:
			_chapter_two.set_flag("sequence_reveal_complete")
			_c2_enter_phase("rune_search")
		return
	for prop_index in _adventure_props.size():
		var rune: Dictionary = _adventure_props[prop_index]
		if str(rune.get("kind", "")) != "thaw_rune":
			continue
		rune["pos"] = rune.get("fixed_pos", rune.get("pos", Vector2.ZERO)) as Vector2
		if bool(rune.get("completed", false)):
			_adventure_props[prop_index] = rune
			continue
		var inside: bool = (rune.get("pos", Vector2.ZERO) as Vector2).distance_to(_player_pos) < 105.0
		if inside and not bool(rune.get("inside", false)):
			var entered: int = _chapter_two.count("runes_correct")
			if entered < 4 and int(rune.get("rune", -1)) == _story_custom_sequence[entered]:
				rune["completed"] = true
				rune["feedback"] = "correct"
				if entered == 0:
					_chapter_two.set_flag("rune_sequence_started")
				entered = _chapter_two.add_count("runes_correct")
				_story_log("Rune correct: %d/4" % entered)
				if entered == 3:
					_c2_enter_phase("spreading_freeze")
					_chapter_two.set_timer("freeze_finale", 35.0)
				elif entered >= 4:
					_chapter_two.set_flag("final_rune_activated")
					_chapter_two.set_flag("spreading_freeze_resolved")
					_chapter_two.set_flag("finale_complete")
					_chapter_two.set_flag("primary_complete")
					_story_primary_complete = true
					rune["inside"] = true
					_adventure_props[prop_index] = rune
					_request_story_victory("chapter_two_thaw_sequence_complete")
					return
			else:
				rune["feedback"] = "wrong"
				var reduced: int = maxi(0, entered - 1)
				if entered > 0:
					var reopened_rune: int = _story_custom_sequence[entered - 1]
					for reopen_index in _adventure_props.size():
						if str(_adventure_props[reopen_index].get("kind", "")) == "thaw_rune" and int(_adventure_props[reopen_index].get("rune", -1)) == reopened_rune:
							_adventure_props[reopen_index]["completed"] = false
							_adventure_props[reopen_index]["feedback"] = ""
							break
				_chapter_two.set_count("runes_correct", reduced)
				_chapter_two.cold_exposure = minf(100.0, _chapter_two.cold_exposure + 18.0)
				_story_log("Rune incorrect: sequence progress reduced to %d/4" % reduced)
			rune["inside"] = true
		elif not inside:
			rune["inside"] = false
		_adventure_props[prop_index] = rune
	if _chapter_two.phase == "spreading_freeze":
		_chapter_two.tick_timer("freeze_finale", delta)

func _update_c2_mimic(_delta: float) -> void:
	for prop_index in range(_adventure_props.size() - 1, -1, -1):
		var chest: Dictionary = _adventure_props[prop_index]
		if str(chest.get("kind", "")) != "mimic_chest" or bool(chest.get("locked", false)):
			continue
		var inside: bool = (chest.get("pos", Vector2.ZERO) as Vector2).distance_to(_player_pos) < 110.0
		if inside and not bool(chest.get("inside", false)):
			var chest_id: int = int(chest.get("chest", -1))
			var reveal_pos: Vector2 = chest.get("pos", Vector2.ZERO) as Vector2
			if bool(chest.get("real", false)):
				for other_index in range(_adventure_props.size() - 1, -1, -1):
					if str(_adventure_props[other_index].get("kind", "")) in ["mimic_chest", "frost_clue"]:
						_adventure_props.remove_at(other_index)
				_chapter_two.set_flag("real_mimic_opened")
				_chapter_two.set_flag("mimic_spawned")
				_c2_enter_phase("frost_mimic_battle")
				_spawn_story_objective_enemy("teleporter_boss", "frost_mimic", 1.35, reveal_pos)
				_story_log("Correct Chest opened: Frost Mimic revealed")
				return
			_adventure_props.remove_at(prop_index)
			for clue_index in range(_adventure_props.size() - 1, -1, -1):
				if str(_adventure_props[clue_index].get("kind", "")) == "frost_clue" and int(_adventure_props[clue_index].get("chest", -2)) == chest_id:
					_adventure_props.remove_at(clue_index)
			var wrong_chests: int = _chapter_two.add_count("wrong_chests")
			_chapter_two.set_count("suspects_remaining", maxi(1, _chapter_two.count("suspects_remaining") - 1))
			_c1_spawn_pressure(5 + wrong_chests * 2, "c2_mimic_ambush", reveal_pos, 1.0 + float(wrong_chests) * 0.12)
			_story_log("Wrong Chest opened: ambush %d triggered" % wrong_chests)
			return
		elif not inside:
			chest["inside"] = false
		_adventure_props[prop_index] = chest

func _update_c2_colossus(delta: float) -> void:
	if _c2_bonus_levels_pending > 0:
		_c2_bonus_levels_pending -= 1
		_gain_xp(maxi(1, _xp_next - _xp))
		_story_log("Armour Crystal experience reward: level gained · %d bonus levels pending" % _c2_bonus_levels_pending)
		return
	if _chapter_two.phase == "final_vulnerable":
		return
	if _chapter_two.tick_timer("attack_cycle", delta) <= 0.0:
		var next_crystal: int = _chapter_two.count("crystals_broken")
		_chapter_two.set_timer("attack_cycle", 6.0)
		_chapter_two.set_timer("exposure_window", 5.0)
		for prop_index in _adventure_props.size():
			if str(_adventure_props[prop_index].get("kind", "")) == "armour_crystal":
				_adventure_props[prop_index]["exposed"] = int(_adventure_props[prop_index].get("crystal", -1)) == next_crystal
		_trigger_c2_colossus_exposure(next_crystal)
		_story_log("Crystal exposed: %s" % ["Frost Beam", "Ground Freeze", "Armour Regeneration"][next_crystal])
	if _chapter_two.tick_timer("exposure_window", delta) <= 0.0:
		for prop_index in _adventure_props.size():
			if str(_adventure_props[prop_index].get("kind", "")) == "armour_crystal":
				_adventure_props[prop_index]["exposed"] = false
	for prop_index in range(_adventure_props.size() - 1, -1, -1):
		var crystal: Dictionary = _adventure_props[prop_index]
		if str(crystal.get("kind", "")) != "armour_crystal" or not bool(crystal.get("exposed", false)):
			continue
		if (crystal.get("pos", Vector2.ZERO) as Vector2).distance_to(_player_pos) < 185.0:
			crystal["hp"] = float(crystal.get("hp", 1.0)) - (30.0 + float(_level) * 3.0) * delta
			if float(crystal["hp"]) <= 0.0:
				var broken: int = _chapter_two.add_count("crystals_broken")
				_chapter_two.add_count("armour_transitions")
				_c2_bonus_levels_pending += 2
				_adventure_progress = broken
				_adventure_props.remove_at(prop_index)
				_story_log("Crystal destroyed: %d/3 · boss phase transition · 2 bonus levels awarded" % broken)
				if broken < 3:
					_c1_spawn_pressure(2, "c2_colossus_summon", _story_stage_origin, 0.95)
				if broken >= 3:
					_chapter_two.set_flag("all_armour_transitions_complete")
					_chapter_two.set_flag("final_vulnerable_phase")
					_story_custom_phase = 10
					_c2_enter_phase("final_vulnerable")
				return
		_adventure_props[prop_index] = crystal

func _trigger_c2_colossus_exposure(crystal_index: int) -> void:
	var boss_index: int = _find_story_enemy("frost_colossus")
	if boss_index < 0:
		return
	var boss: Dictionary = _enemies[boss_index]
	var boss_pos: Vector2 = boss.get("pos", _story_stage_origin) as Vector2
	match crystal_index:
		0:
			var beam_direction: Vector2 = boss_pos.direction_to(_player_pos)
			if beam_direction.is_zero_approx(): beam_direction = Vector2.DOWN
			for spread in [-0.18, -0.09, 0.0, 0.09, 0.18]:
				_boss_projs.append({"kind":"straight", "pos":boss_pos, "vel":beam_direction.rotated(float(spread)) * 360.0, "dmg":float(boss.get("dmg", 10.0)) * 0.55, "life":4.0})
			_story_log("Boss phase transition: Frost Beam fired · beam crystal exposed")
		1:
			for strike_index in 5:
				var strike_pos: Vector2 = _player_pos + Vector2.from_angle(TAU * float(strike_index) / 5.0) * 105.0
				_mortar_strikes.append({"pos":strike_pos, "life":1.15, "max_life":1.15, "dmg":float(boss.get("dmg", 10.0)) * 0.60, "r":48.0, "launch":boss_pos})
			_story_log("Boss phase transition: Ground Freeze slam · ground crystal exposed")
		2:
			var boss_max_hp: float = float(boss.get("objective_max_hp", boss.get("hp", 1.0)))
			boss["hp"] = minf(boss_max_hp, float(boss.get("hp", 1.0)) + boss_max_hp * 0.08)
			_enemies[boss_index] = boss
			_story_log("Boss phase transition: Armour regeneration channel · regeneration crystal exposed")

func _update_frozen_braziers(delta: float) -> void:
	var index := _find_adventure_prop("brazier")
	if index < 0: return
	var prop := _adventure_props[index]
	if (prop.pos as Vector2).distance_to(_player_pos) < 175.0:
		_story_custom_interaction += delta
	else:
		_story_custom_interaction = 0.0
	if _story_custom_interaction >= float(_story_custom_data.get("interact", 3.0)):
		_adventure_props.remove_at(index)
		_story_custom_interaction = 0.0
		_complete_staged_objective_instance()

func _update_thaw_runes(delta: float) -> void:
	_story_custom_timer = maxf(0.0, _story_custom_timer - delta)
	_update_ordered_props("thaw_rune", "rune", false)

func _update_custom_breakables(delta: float, kind: String, radius: float) -> void:
	for i in range(_adventure_props.size() - 1, -1, -1):
		var prop := _adventure_props[i]
		if str(prop.get("kind", "")) != kind: continue
		if (prop.pos as Vector2).distance_to(_player_pos) < radius:
			prop["hp"] = float(prop.get("hp", 1.0)) - (30.0 + float(_level) * 3.0) * delta
			_adventure_props[i] = prop
			if float(prop.hp) <= 0.0:
				_adventure_props.remove_at(i)
				if kind in ["ice_prison", "ember_ore", "armour_crystal"]:
					_complete_staged_objective_instance()
				elif kind != "soul_chain":
					_adventure_progress += 1

func _update_ordered_props(kind: String, value_key: String, penalize: bool) -> void:
	for i in _adventure_props.size():
		var prop := _adventure_props[i]
		if str(prop.get("kind", "")) != kind: continue
		var inside := (prop.pos as Vector2).distance_to(_player_pos) < 105.0
		if inside and not bool(prop.get("inside", false)):
			var entered := int(_story_custom_progress.get("entered", 0))
			var value := int(prop.get(value_key, -1))
			if entered < _story_custom_sequence.size() and value == _story_custom_sequence[entered]:
				entered += 1
				_story_custom_progress["entered"] = entered
				_story_log("Objective progress: %s %d/%d" % [_story_custom_id, entered, _story_custom_sequence.size()])
				if entered >= _story_custom_sequence.size():
					_complete_custom_story_stage()
					return
			else:
				_story_custom_progress["entered"] = maxi(0, entered - 1) if penalize else 0
				_spawn_story_penalty_elite()
		prop["inside"] = inside
		_adventure_props[i] = prop

func _update_frost_mimic(delta: float) -> void:
	_story_custom_timer = maxf(0.0, _story_custom_timer - delta)
	if _find_adventure_prop("mimic_chest") < 0 and _find_story_enemy("frost_mimic") < 0 and _story_gate_remaining <= 0 and _adventure_progress < _adventure_target and _story_custom_timer <= 0.0:
		_spawn_next_mimic_chest()
	for i in range(_adventure_props.size() - 1, -1, -1):
		var chest := _adventure_props[i]
		if str(chest.get("kind", "")) != "mimic_chest": continue
		if (chest.pos as Vector2).distance_to(_player_pos) < 105.0:
			_adventure_props.remove_at(i)
			if bool(chest.get("real", false)):
				_adventure_progress = _adventure_target
				_spawn_story_objective_enemy("teleporter_boss", "frost_mimic", 1.2, chest.pos as Vector2)
			else:
				_adventure_progress += 1
				_story_log("Objective progress: frost_mimic %d/%d" % [_adventure_progress, _adventure_target])
				_story_custom_timer = 2.0
				_spawn_story_gate_ambush(4 + _adventure_progress * 2)
				if _adventure_progress in [2, 4]: _damage_player(_player_max_hp * 0.05, 0.25)
			return

func _spawn_next_mimic_chest() -> void:
	var encounter_index: int = _adventure_progress
	var is_real: bool = encounter_index >= _adventure_target - 1
	_spawn_custom_prop("mimic_chest", _story_objective_zone_position(encounter_index, 700.0), {"real":is_real, "encounter":encounter_index})

func _setup_chapter_three_stage(objective: String) -> void:
	_chapter_three = ChapterThreeStageControllerClass.new()
	_chapter_three.reset(int(story_stage.get("chapter_stage", 1)))
	_c3_spawn_timer = 0.0
	_c3_action_timer = 0.0
	match objective:
		"cleanse_mire":
			_chapter_three.set_count("pools_generated", 3)
			_chapter_three.set_count("pools_purified", 0)
			_chapter_three.set_count("nodes_resolved", 0)
			_chapter_three.set_count("energy", 0)
			_chapter_three.set_count("energy_max", 6)
			for pool_index in 3:
				_spawn_custom_prop("corrupted_pool", _story_objective_zone_position(pool_index, 560.0), {"pool":pool_index, "active":pool_index == 0, "progress":0.0, "stability":100.0})
			for energy_index in 3:
				_spawn_custom_prop("c3_cleansing_energy", _player_pos + Vector2.from_angle(float(energy_index) * TAU / 3.0 - PI * 0.5) * 185.0, {"value":2})
			_c3_enter_phase("direct_purification")
		"plaguebeast":
			_chapter_three.set_count("tracking_phases_complete", 0)
			_chapter_three.set_count("correct_routes", 0)
			_chapter_three.set_count("wrong_routes", 0)
			_chapter_three.set_count("tracking_trails", 5)
			_chapter_three.set_flag("escape_pending", true)
			_spawn_story_objective_enemy("normal_tank", "c3_plague_sighting", 2.4, _story_objective_zone_position(0, 520.0))
			_c3_enter_phase("first_sighting")
		"venom_harvest":
			_chapter_three.set_count("selection_region", -1)
			for ingredient_index in 3:
				var ingredient: String = str(["spider", "toad", "wasp"][ingredient_index])
				_chapter_three.set_count(ingredient, 0)
				_chapter_three.set_flag("%s_complete" % ingredient, false)
			_spawn_c3_region_choices()
			_c3_enter_phase("region_select")
		"fragile_cure":
			_chapter_three.set_meter("vial_integrity", 100.0)
			_chapter_three.set_count("route_checkpoints", 0)
			_chapter_three.set_count("route_checkpoints_required", 2)
			_chapter_three.set_count("selection_route", -1)
			_chapter_three.set_count("repair_charges", 1)
			_spawn_custom_prop("c3_vial", _player_pos + Vector2(0.0, -230.0), {})
			_c3_enter_phase("vial_collection")
		"grand_antidote":
			var recipe_options: Array[int] = [0, 1, 2, 3]
			recipe_options.shuffle()
			recipe_options.resize(3)
			_chapter_three.recipe = recipe_options
			_chapter_three.set_count("ingredients_acquired", 0)
			_chapter_three.set_count("ingredients_submitted", 0)
			_chapter_three.set_meter("heat", 50.0)
			_chapter_three.set_meter("purity", 82.0)
			_chapter_three.set_meter("brew_progress", 0.0)
			_spawn_custom_prop("cauldron", _story_stage_origin + Vector2(0.0, -120.0), {})
			for ingredient_index in 4:
				_spawn_custom_prop("c3_brew_ingredient", _story_objective_zone_position(ingredient_index, 460.0), {"ingredient":ingredient_index})
			_story_log("Recipe generated: %s" % _sequence_text(_chapter_three.recipe))
			_c3_enter_phase("ingredient_collection")
	_story_log("Chapter 3 stage initialized: %s" % objective)

func _c3_enter_phase(next_phase: String) -> void:
	if _chapter_three == null: return
	var previous: String = _chapter_three.enter(next_phase)
	_story_log_phase(previous, next_phase)

func _update_chapter_three_stage(delta: float) -> void:
	match _chapter_three.stage_number:
		1: _update_c3_cleanse_mire(delta)
		2: _update_c3_plaguebeast(delta)
		3: _update_c3_venom_harvest(delta)
		4: _update_c3_fragile_cure(delta)
		5: _update_c3_grand_antidote(delta)

func _c3_spawn_pressure(count: int, tag: String = "c3_pressure", strength: float = 1.0) -> void:
	for enemy_index in count:
		var kind: String = "normal_fast" if enemy_index % 3 == 0 else ("normal_tank" if enemy_index % 5 == 0 else "normal")
		_spawn_story_objective_enemy(kind, tag, strength, _player_pos + Vector2.from_angle(float(enemy_index) * TAU / float(maxi(1, count))) * randf_range(380.0, 540.0))

func _update_c3_cleanse_mire(delta: float) -> void:
	for energy_index in range(_adventure_props.size() - 1, -1, -1):
		var energy_prop: Dictionary = _adventure_props[energy_index]
		if str(energy_prop.get("kind", "")) != "c3_cleansing_energy": continue
		if _chapter_three.count("energy") >= _chapter_three.count("energy_max"):
			_adventure_props.remove_at(energy_index)
			continue
		if (energy_prop.pos as Vector2).distance_to(_player_pos) < 105.0 and _chapter_three.count("energy") < _chapter_three.count("energy_max"):
			var gained: int = mini(int(energy_prop.get("value", 2)), _chapter_three.count("energy_max") - _chapter_three.count("energy"))
			_chapter_three.add_count("energy", gained)
			_adventure_props.remove_at(energy_index)
			_story_log("Cleansing energy collected: %d/%d" % [_chapter_three.count("energy"), _chapter_three.count("energy_max")])
	_c3_spawn_timer -= delta
	if _c3_spawn_timer <= 0.0 and _chapter_three.count("energy") < _chapter_three.count("energy_max") and _find_story_enemy("c3_energy_carrier") < 0:
		var carrier_pos: Vector2 = _player_pos + Vector2.from_angle(randf_range(0.0, TAU)) * 330.0
		_spawn_story_objective_enemy("normal_fast", "c3_energy_carrier", 1.1 + float(_chapter_three.count("pools_purified")) * 0.18, carrier_pos)
		_c3_spawn_timer = 3.0
	if _chapter_three.phase == "reclamation_surge":
		var remaining: float = _chapter_three.tick_timer("reclamation", delta)
		var all_stable: bool = true
		for i in _adventure_props.size():
			var pool: Dictionary = _adventure_props[i]
			if str(pool.get("kind", "")) != "corrupted_pool": continue
			var stability: float = float(pool.get("stability", 100.0))
			if remaining > 0.0:
				stability -= delta * 1.6
			if (pool.pos as Vector2).distance_to(_player_pos) < 180.0:
				stability += delta * (18.0 if remaining <= 0.0 else 11.0)
			pool["stability"] = clampf(stability, 0.0, 100.0)
			_adventure_props[i] = pool
			all_stable = all_stable and stability >= 35.0
		_chapter_three.set_flag("pool_reclaiming", not all_stable)
		_c3_spawn_timer -= delta
		if _c3_spawn_timer <= 0.0:
			_c3_spawn_pressure(3, "c3_reclaimer", 1.25)
			_c3_spawn_timer = 4.0
		if remaining <= 0.0 and all_stable:
			_chapter_three.set_flag("reclamation_complete")
			_chapter_three.set_flag("all_pools_stable")
			_chapter_three.set_flag("pool_reclaiming", false)
			_chapter_three.set_flag("primary_complete")
			_story_primary_complete = true
			_story_log("Objective completion: reclamation surge")
			_request_story_victory("chapter_three_mire_stable")
		return
	var active_pool: int = _chapter_three.count("pools_purified")
	for i in range(_adventure_props.size() - 1, -1, -1):
		var pool: Dictionary = _adventure_props[i]
		if str(pool.get("kind", "")) != "corrupted_pool" or int(pool.get("pool", -1)) != active_pool: continue
		var near: bool = (pool.pos as Vector2).distance_to(_player_pos) < 175.0
		if active_pool == 0 and near and _chapter_three.count("energy") > 0:
			_c3_action_timer += delta
			if _c3_action_timer >= 1.0:
				_c3_action_timer = 0.0
				_chapter_three.add_count("energy", -1)
				pool["progress"] = float(pool.get("progress", 0.0)) + 1.0
		elif active_pool == 1:
			var moving_center: Vector2 = (pool.pos as Vector2) + Vector2.from_angle(_elapsed * 0.7) * 105.0
			pool["zone_pos"] = moving_center
			if moving_center.distance_to(_player_pos) < 125.0 and _chapter_three.count("energy") > 0:
				pool["progress"] = float(pool.get("progress", 0.0)) + delta
				_c3_action_timer += delta
				if _c3_action_timer >= 2.0:
					_c3_action_timer = 0.0
					_chapter_three.add_count("energy", -1)
		elif active_pool == 2:
			if _find_adventure_prop("c3_corruption_node") < 0 and _chapter_three.count("nodes_resolved") < 3:
				var node_index: int = _chapter_three.count("nodes_resolved")
				_spawn_custom_prop("c3_corruption_node", (pool.pos as Vector2) + Vector2.from_angle(float(node_index) * TAU / 3.0) * 190.0, {"node":node_index})
			var node: int = _find_adventure_prop("c3_corruption_node")
			if node >= 0 and (_adventure_props[node].pos as Vector2).distance_to(_player_pos) < 120.0 and _chapter_three.count("energy") > 0:
				_c3_action_timer += delta
				if _c3_action_timer >= 1.4:
					_c3_action_timer = 0.0
					_chapter_three.add_count("energy", -1)
					_chapter_three.add_count("nodes_resolved")
					_adventure_props.remove_at(node)
					pool["progress"] = float(_chapter_three.count("nodes_resolved"))
		else: _c3_action_timer = 0.0
		var target: float = 3.0 if active_pool != 1 else 8.0
		if float(pool.get("progress", 0.0)) >= target:
			pool["active"] = false
			pool["purified"] = true
			_chapter_three.add_count("pools_purified")
			_story_log("Pool purified: %d/3" % _chapter_three.count("pools_purified"))
			if _chapter_three.count("pools_purified") >= 3:
				_chapter_three.set_timer("reclamation", 42.0)
				_c3_spawn_timer = 1.0
				_c3_enter_phase("reclamation_surge")
			else:
				_c3_enter_phase("moving_purification" if active_pool == 0 else "multi_point_purification")
		_adventure_props[i] = pool
		return

func _spawn_c3_tracking_choices() -> void:
	_adventure_props.clear()
	var trail_count: int = maxi(1, _chapter_three.count("tracking_trails"))
	var correct_route: int = randi_range(0, trail_count - 1)
	for route in trail_count:
		var angle: float = -PI * 0.85 + PI * 1.7 * (float(route) / float(maxi(1, trail_count - 1)))
		var trail_pos: Vector2 = _player_pos + Vector2.from_angle(angle) * 390.0
		_spawn_custom_prop("c3_tracking_clue", trail_pos, {"route":route, "correct":correct_route == route})
	_chapter_three.set_flag("transition_pending", false)

func _update_c3_plaguebeast(delta: float) -> void:
	if _chapter_three.phase == "first_sighting":
		var beast_index: int = _find_story_enemy("c3_plague_sighting")
		_c3_action_timer += delta
		if beast_index >= 0:
			var beast: Dictionary = _enemies[beast_index]
			var hp_ratio: float = float(beast.hp) / maxf(float(beast.get("objective_max_hp", beast.hp)), 1.0)
			if hp_ratio <= 0.72 or _c3_action_timer >= 18.0:
				_enemies.remove_at(beast_index)
				_chapter_three.set_flag("escape_pending", false)
				_chapter_three.set_count("tracking_phases_complete", 0)
				_story_log("Beast escaped: first sighting")
				_spawn_c3_tracking_choices()
				_c3_enter_phase("tracking")
		return
	if _chapter_three.phase == "tracking":
		for i in range(_adventure_props.size() - 1, -1, -1):
			var clue: Dictionary = _adventure_props[i]
			if str(clue.get("kind", "")) != "c3_tracking_clue" or (clue.pos as Vector2).distance_to(_player_pos) >= 110.0: continue
			var correct: bool = bool(clue.get("correct", false))
			_chapter_three.add_count("correct_routes" if correct else "wrong_routes")
			_adventure_props.clear()
			if not correct:
				_chapter_three.set_count("tracking_trails", maxi(1, _chapter_three.count("tracking_trails") - 1))
				_story_log("Wrong trail selected: ambush triggered")
				_c3_spawn_pressure(7, "c3_pursuit", 1.2 + float(_chapter_three.count("wrong_routes")) * 0.12)
				_c3_enter_phase("tracking_ambush")
				return
			_chapter_three.add_count("tracking_phases_complete")
			_chapter_three.set_count("tracking_trails", 5)
			_story_log("Correct trail selected · clue %d/3" % _chapter_three.count("tracking_phases_complete"))
			_story_log("Trap placed: %s" % str(["Snare Trap", "Antidote Trap", "Noise Trap"][_chapter_three.count("tracking_phases_complete") - 1]))
			if _chapter_three.count("tracking_phases_complete") >= 3:
				_chapter_three.set_flag("final_arena_reached")
				_chapter_three.set_flag("final_phase_started")
				_chapter_three.set_flag("boss_spawned")
				_spawn_story_objective_enemy("normal_tank", "c3_plaguebeast_final", 3.8 + float(_chapter_three.count("wrong_routes")) * 0.35 - float(_chapter_three.count("correct_routes")) * 0.18, _story_objective_zone_position(7, 560.0))
				_c3_enter_phase("final_hunt")
			else:
				_spawn_c3_tracking_choices()
			return
	if _chapter_three.phase == "tracking_ambush":
		if _find_story_enemy("c3_pursuit") < 0:
			_spawn_c3_tracking_choices()
			_c3_enter_phase("tracking")
			_story_log("Ambush cleared: %d trails remain" % _chapter_three.count("tracking_trails"))
		return

func _spawn_c3_region_choices() -> void:
	_adventure_props.clear()
	for region in 3:
		var key: String = str(["spider", "toad", "wasp"][region])
		if not _chapter_three.flag("%s_complete" % key):
			_spawn_custom_prop("c3_region", _story_objective_zone_position(region, 440.0), {"region":region})

func _spawn_c3_region_target(region: int) -> void:
	var kind: String = str(["c3_web_nest", "c3_bile_vessel", "c3_wasp_hive"][region])
	_spawn_custom_prop(kind, _story_objective_zone_position(region + _chapter_three.count("regions_complete"), 470.0), {"region":region, "progress":0.0})

func _c3_region_lure_duration(region: int) -> float:
	return float([5.0, 6.0, 5.0][clampi(region, 0, 2)])

func _spawn_c3_venom_pack(region: int, center: Vector2) -> void:
	var enemy_kind: String = str(["normal_fast", "normal_tank", "normal_fast"][region])
	var marked_tag: String = str(["c3_marked_spider", "c3_marked_toad", "c3_marked_wasp"][region])
	var pack_tag: String = str(["c3_spider_pack", "c3_toad_pack", "c3_wasp_pack"][region])
	var pack_size: int = int([6, 4, 7][region])
	var strength: float = 1.3 + float(_chapter_three.count("regions_complete")) * 0.25
	var spawn_direction: Vector2 = _player_pos.direction_to(center)
	if spawn_direction.is_zero_approx():
		spawn_direction = Vector2.from_angle(randf_range(0.0, TAU))
	var pack_center: Vector2 = center + spawn_direction * 480.0
	_spawn_story_objective_enemy(enemy_kind, marked_tag, strength, pack_center)
	for pack_index in range(pack_size - 1):
		var angle: float = float(pack_index) * TAU / float(maxi(1, pack_size - 1))
		var pack_pos: Vector2 = pack_center + Vector2.from_angle(angle) * randf_range(130.0, 220.0)
		var player_to_spawn: Vector2 = pack_pos - _player_pos
		if player_to_spawn.length() < 460.0:
			var safe_direction: Vector2 = player_to_spawn.normalized() if not player_to_spawn.is_zero_approx() else spawn_direction
			pack_pos = _player_pos + safe_direction * 460.0
		_spawn_story_objective_enemy(enemy_kind, pack_tag, strength * 0.82, pack_pos)
	_story_log("Venom pack lured: %s x%d" % [str(["Spider", "Toad", "Wasp"][region]), pack_size])

func _update_c3_venom_harvest(delta: float) -> void:
	if _chapter_three.flag("ingredients_contaminated"):
		var station: int = _find_adventure_prop("c3_cleanse_station")
		if station >= 0 and (_adventure_props[station].pos as Vector2).distance_to(_player_pos) < 130.0:
			_c3_action_timer += delta
			if _c3_action_timer >= 2.0:
				_chapter_three.set_flag("ingredients_contaminated", false)
				_adventure_props.remove_at(station)
				_c3_action_timer = 0.0
				_story_log("Ingredient contamination cleansed")
				_spawn_c3_region_choices()
		return
	if _chapter_three.phase == "region_select":
		var region_nearby: bool = false
		for prop in _adventure_props:
			if str(prop.get("kind", "")) == "c3_region" and (prop.pos as Vector2).distance_to(_player_pos) < 115.0:
				var region: int = int(prop.get("region", 0))
				var region_key: String = "c3_region_%d" % region
				if _story_custom_touch_lock != region_key:
					_story_custom_touch_lock = region_key
					_c3_action_timer = 0.0
				_chapter_three.set_count("selection_region", region)
				_c3_action_timer += delta
				region_nearby = true
				if _c3_action_timer < 2.0:
					break
				_chapter_three.set_count("active_region", region)
				_adventure_props.clear()
				_story_custom_touch_lock = ""
				_c3_action_timer = 0.0
				_spawn_c3_region_target(region)
				_c3_enter_phase("region_hunt")
				return
		if not region_nearby:
			_story_custom_touch_lock = ""
			_c3_action_timer = 0.0
			_chapter_three.set_count("selection_region", -1)
	elif _chapter_three.phase == "region_hunt":
		var region: int = _chapter_three.count("active_region")
		var target_kind: String = str(["c3_web_nest", "c3_bile_vessel", "c3_wasp_hive"][region])
		var target: int = _find_adventure_prop(target_kind)
		if target >= 0 and (_adventure_props[target].pos as Vector2).distance_to(_player_pos) < 145.0:
			_c3_action_timer += delta
			_adventure_props[target]["progress"] = _c3_action_timer
			if _c3_action_timer >= _c3_region_lure_duration(region):
				var lure_position: Vector2 = _adventure_props[target].pos as Vector2
				_c3_action_timer = 0.0
				_adventure_props.remove_at(target)
				_spawn_c3_venom_pack(region, lure_position)
		else:
			_c3_action_timer = 0.0
			if target >= 0:
				_adventure_props[target]["progress"] = 0.0
	elif _chapter_three.phase == "ingredient_extraction":
		var extraction: int = _find_adventure_prop("c3_extraction")
		if extraction >= 0 and (_adventure_props[extraction].pos as Vector2).distance_to(_player_pos) < 145.0:
			_chapter_three.set_flag("ingredient_case_extracted")
			_chapter_three.set_flag("primary_complete")
			_story_primary_complete = true
			_story_log("Objective completion: ingredient case extracted")
			_request_story_victory("chapter_three_venom_extracted")
		_c3_spawn_timer -= delta
		if _c3_spawn_timer <= 0.0:
			_c3_spawn_pressure(2, "c3_contaminator", 1.25)
			_c3_spawn_timer = 4.0

func _update_c3_fragile_cure(delta: float) -> void:
	if _chapter_three.phase == "vial_collection":
		var vial: int = _find_adventure_prop("c3_vial")
		if vial >= 0 and (_adventure_props[vial].pos as Vector2).distance_to(_player_pos) < 105.0:
			_adventure_props.remove_at(vial)
			_story_custom_carried = "antidote_vial"
			_chapter_three.set_flag("vial_collected")
			_spawn_custom_prop("c3_route", _story_stage_origin + Vector2(-390.0, -260.0), {"route":0})
			_spawn_custom_prop("c3_route", _story_stage_origin + Vector2(390.0, -260.0), {"route":1})
			_story_log("Vial picked up: integrity 100%")
			_c3_enter_phase("route_select")
	elif _chapter_three.phase == "route_select":
		var route_nearby: bool = false
		for prop in _adventure_props:
			if str(prop.get("kind", "")) == "c3_route" and (prop.pos as Vector2).distance_to(_player_pos) < 115.0:
				var route: int = int(prop.get("route", 0))
				var route_key: String = "c3_route_%d" % route
				if _story_custom_touch_lock != route_key:
					_story_custom_touch_lock = route_key
					_c3_action_timer = 0.0
				_chapter_three.set_count("selection_route", route)
				_c3_action_timer += delta
				route_nearby = true
				if _c3_action_timer < 2.5:
					break
				_chapter_three.set_count("route", route)
				_chapter_three.set_count("route_checkpoints_required", 3 if route == 0 else 4)
				_adventure_props.clear()
				_story_custom_touch_lock = ""
				_c3_action_timer = 0.0
				_spawn_c3_cure_checkpoint(0)
				_story_log("Route selected: %s" % ("Short hazardous route" if route == 0 else "Long combat route"))
				_c3_enter_phase("vial_delivery")
				return
		if not route_nearby:
			_story_custom_touch_lock = ""
			_c3_action_timer = 0.0
			_chapter_three.set_count("selection_route", -1)
	elif _chapter_three.phase == "vial_delivery":
		var checkpoint: int = _find_adventure_prop("c3_cure_checkpoint")
		if checkpoint >= 0 and _story_custom_carried == "antidote_vial" and (_adventure_props[checkpoint].pos as Vector2).distance_to(_player_pos) < 125.0:
			_c3_action_timer += delta
			_adventure_props[checkpoint]["progress"] = _c3_action_timer
			var checkpoint_duration: float = 5.0 if _chapter_three.count("route") == 0 else 4.0
			if _c3_action_timer >= checkpoint_duration:
				_c3_action_timer = 0.0
				_adventure_props.remove_at(checkpoint)
				var reached: int = _chapter_three.add_count("route_checkpoints")
				if _chapter_three.count("route") == 1: _chapter_three.adjust_meter("vial_integrity", 8.0)
				_story_log("Checkpoint reached: %d/%d" % [reached, _chapter_three.count("route_checkpoints_required")])
				_c3_spawn_pressure(6 if _chapter_three.count("route") == 0 else 4, "c3_route_guard", 1.3 + float(reached) * 0.12)
				_c3_enter_phase("route_ambush")
		else:
			_c3_action_timer = 0.0
			if checkpoint >= 0:
				_adventure_props[checkpoint]["progress"] = 0.0
	elif _chapter_three.phase == "route_ambush":
		if _find_story_enemy("c3_route_guard") < 0:
			var reached: int = _chapter_three.count("route_checkpoints")
			if reached < _chapter_three.count("route_checkpoints_required"):
				_spawn_c3_cure_checkpoint(reached)
				_c3_enter_phase("vial_delivery")
			else:
				_spawn_custom_prop("infected_altar", _story_objective_zone_position(7, 620.0), {"progress":0.0})
				_c3_enter_phase("infected_altar")
	elif _chapter_three.phase == "infected_altar":
		var altar: int = _find_adventure_prop("infected_altar")
		if altar >= 0 and (_adventure_props[altar].pos as Vector2).distance_to(_player_pos) < 145.0:
			_c3_action_timer += delta
			_adventure_props[altar]["progress"] = _c3_action_timer
			if _c3_action_timer >= 4.0:
				_c3_action_timer = 0.0
				_chapter_three.set_flag("vial_at_altar")
				_story_custom_carried = ""
				_chapter_three.set_timer("transfer", 42.0)
				_c3_spawn_timer = 1.0
				_story_log("Vial placed: antidote transfer started")
				_c3_enter_phase("antidote_transfer")
		else:
			_c3_action_timer = 0.0
			if altar >= 0:
				_adventure_props[altar]["progress"] = 0.0
	elif _chapter_three.phase == "antidote_transfer":
		var altar: int = _find_adventure_prop("infected_altar")
		if altar < 0: return
		var near: bool = (_adventure_props[altar].pos as Vector2).distance_to(_player_pos) < 210.0
		if near: _chapter_three.tick_timer("transfer", delta)
		_c3_spawn_timer -= delta
		if _c3_spawn_timer <= 0.0:
			_c3_spawn_pressure(3, "c3_vial_hunter", 1.3)
			_c3_spawn_timer = 3.0
		if _chapter_three.timer("transfer") <= 0.0:
			_chapter_three.set_flag("transfer_complete")
			_chapter_three.set_flag("altar_cured")
			_chapter_three.set_flag("primary_complete")
			_story_primary_complete = true
			_request_story_victory("chapter_three_altar_cured")

func _spawn_c3_cure_checkpoint(checkpoint: int) -> void:
	var route_offset: int = 0 if _chapter_three.count("route") == 0 else 4
	_spawn_custom_prop("c3_cure_checkpoint", _story_objective_zone_position(route_offset + checkpoint, 470.0 + float(checkpoint) * 80.0), {"checkpoint":checkpoint, "progress":0.0})

func _update_c3_grand_antidote(delta: float) -> void:
	if _story_custom_timer > 0.0:
		_story_custom_timer = maxf(0.0, _story_custom_timer - delta)
	if _chapter_three.phase == "ingredient_collection":
		for i in range(_adventure_props.size() - 1, -1, -1):
			var prop: Dictionary = _adventure_props[i]
			if str(prop.get("kind", "")) == "c3_brew_ingredient" and _story_custom_carried.is_empty() and (prop.pos as Vector2).distance_to(_player_pos) < 100.0:
				_story_custom_carried = str(prop.get("ingredient", 0))
				_chapter_three.add_count("ingredients_acquired")
				_adventure_props.remove_at(i)
				_story_log("Ingredient obtained: %s" % _ingredient_name(_story_custom_carried))
				return
		var cauldron: int = _find_adventure_prop("cauldron")
		if cauldron >= 0 and not _story_custom_carried.is_empty() and (_adventure_props[cauldron].pos as Vector2).distance_to(_player_pos) < 125.0 and _story_custom_touch_lock != "c3_cauldron":
			var submitted: int = _chapter_three.count("ingredients_submitted")
			if submitted < _chapter_three.recipe.size() and int(_story_custom_carried) == _chapter_three.recipe[submitted]:
				_chapter_three.add_count("ingredients_submitted")
				var next_step: int = _chapter_three.count("ingredients_submitted")
				_story_custom_progress["brew_feedback"] = "CORRECT · Next: %s" % (_ingredient_name(str(_chapter_three.recipe[next_step])) if next_step < _chapter_three.recipe.size() else "Begin brewing")
				_story_custom_timer = 2.5
				_story_log("Ingredient submitted: correct · %d/3" % _chapter_three.count("ingredients_submitted"))
			else:
				_chapter_three.adjust_meter("heat", 18.0)
				_chapter_three.adjust_meter("purity", -12.0)
				_spawn_custom_prop("c3_brew_ingredient", _custom_objective_position(320.0), {"ingredient":int(_story_custom_carried)})
				var required_name: String = _ingredient_name(str(_chapter_three.recipe[submitted])) if submitted < _chapter_three.recipe.size() else "none"
				_story_custom_progress["brew_feedback"] = "WRONG INGREDIENT · Bring %s" % required_name
				_story_custom_timer = 3.5
				_story_log("Ingredient submitted: wrong · heat raised, purity reduced")
			_story_custom_carried = ""
			_story_custom_touch_lock = "c3_cauldron"
			if _chapter_three.count("ingredients_submitted") >= 3:
				_c3_enter_phase("active_brewing")
		else:
			if cauldron < 0 or (_adventure_props[cauldron].pos as Vector2).distance_to(_player_pos) >= 150.0: _story_custom_touch_lock = ""
	elif _chapter_three.phase == "active_brewing":
		var cauldron: int = _find_adventure_prop("cauldron")
		var near: bool = cauldron >= 0 and (_adventure_props[cauldron].pos as Vector2).distance_to(_player_pos) < 155.0
		_chapter_three.adjust_meter("heat", delta * (1.6 if not near else -2.4))
		if near: _chapter_three.adjust_meter("purity", delta * 0.55)
		var heat: float = _chapter_three.meter("heat")
		if heat >= 35.0 and heat <= 82.0 and _chapter_three.meter("purity") >= 35.0:
			_chapter_three.adjust_meter("brew_progress", delta * 2.7)
		_c3_spawn_timer -= delta
		if _c3_spawn_timer <= 0.0:
			_c3_spawn_pressure(2, "c3_brew_pressure", 1.35)
			_c3_spawn_timer = 4.5
		if _chapter_three.meter("brew_progress") >= 100.0:
			_chapter_three.set_flag("brew_complete")
			_chapter_three.set_flag("boss_spawned")
			_story_log("Brew completed: purity %d%%" % roundi(_chapter_three.meter("purity")))
			_spawn_story_objective_enemy("blight_vine_tyrant", "c3_blight_tyrant", 4.4 - _chapter_three.meter("purity") * 0.012, _story_objective_zone_position(7, 540.0))
			_c3_enter_phase("blight_tyrant")

func _setup_chapter_four_stage(objective: String) -> void:
	_chapter_four = ChapterFourStageControllerClass.new()
	_chapter_four.reset(int(story_stage.get("chapter_stage", 1)))
	_c4_spawn_timer = 1.0
	_c4_action_timer = 0.0
	_story_custom_touch_lock = ""
	_story_custom_carried = ""
	match objective:
		"ore_rush":
			_chapter_four.set_meter("heat", 28.0)
			_chapter_four.set_count("ore_required", 12)
			_chapter_four.set_count("ore_generated", 0)
			_chapter_four.set_count("ore_mined", 0)
			_chapter_four.set_count("ore_delivered", 0)
			_chapter_four.set_count("ore_carried", 0)
			_chapter_four.set_count("ore_stolen", 0)
			_chapter_four.set_timer("ore_thief", 18.0)
			for deposit_index in 6:
				var deposit_type: int = deposit_index % 3
				var ore_yield: int = int([1, 3, 2][deposit_type])
				_chapter_four.add_count("ore_generated", ore_yield)
				_spawn_custom_prop("c4_ore_deposit", _story_objective_zone_position(deposit_index, 520.0 + float(deposit_type) * 90.0), {"deposit_type":deposit_type, "yield":ore_yield, "progress":0.0})
			_spawn_custom_prop("c4_mining_cart", _story_stage_origin + Vector2(0.0, -180.0), {"loaded":0, "progress":0.0, "blocked":false})
			_spawn_custom_prop("c4_cooling_vent", _story_stage_origin + Vector2(-420.0, 250.0), {"charges":3, "cooldown":0.0, "progress":0.0})
			_spawn_custom_prop("c4_cooling_vent", _story_stage_origin + Vector2(420.0, 250.0), {"charges":3, "cooldown":0.0, "progress":0.0})
			_c4_enter_phase("mining_logistics")
		"molten_circuit":
			_chapter_four.set_meter("heat", 42.0)
			_chapter_four.set_flag("puzzle_initialized")
			_chapter_four.set_count("valve_mask", 0)
			_chapter_four.set_count("mechanisms_powered", 0)
			_chapter_four.set_count("route_nodes", 0)
			for valve_index in 3:
				_spawn_custom_prop("lava_valve", _story_objective_zone_position(valve_index, 620.0), {"valve":valve_index, "toggle_mask":int([1, 2, 4][valve_index]), "inside":false})
				_spawn_custom_prop("c4_forge_mechanism", _story_objective_zone_position(valve_index + 3, 480.0), {"mechanism":valve_index, "powered":false, "jammed":false})
			_c4_enter_phase("lava_routing")
		"golem_taming":
			_chapter_four.set_meter("heat", 38.0)
			_chapter_four.set_count("golems_captured", 0)
			_chapter_four.set_flag("capture_pending")
			_spawn_c4_golem(0)
			_c4_enter_phase("charge_stun")
		"lost_relic":
			_chapter_four.set_meter("heat", 35.0)
			_chapter_four.set_count("components_collected", 0)
			_spawn_c4_chamber(0)
			_c4_enter_phase("flame_chamber")
		"meltdown":
			_chapter_four.set_meter("heat", 76.0)
			_chapter_four.set_count("regulators_disabled", 0)
			_chapter_four.sequence.assign([0, 1, 2, 3])
			_chapter_four.sequence.shuffle()
			_chapter_four.set_timer("critical_grace", 10.0)
			for regulator_index in 4:
				_spawn_custom_prop("regulator", _story_objective_zone_position(regulator_index, 690.0), {"regulator":regulator_index, "disabled":false, "progress":0.0})
			_c4_enter_phase("initial_meltdown")
	_story_log("Chapter 4 stage initialized: %s" % objective)

func _c4_enter_phase(next_phase: String) -> void:
	if _chapter_four == null: return
	var previous: String = _chapter_four.enter(next_phase)
	_story_log_phase(previous, next_phase)

func _update_chapter_four_stage(delta: float) -> void:
	if _chapter_four == null: return
	_update_c4_heat_failure(delta)
	if _game_over: return
	match _chapter_four.stage_number:
		1: _update_c4_ore_rush(delta)
		2: _update_c4_molten_circuit(delta)
		3: _update_c4_golem_taming(delta)
		4: _update_c4_lost_relic(delta)
		5: _update_c4_meltdown(delta)

func _update_c4_heat_failure(delta: float) -> void:
	var heat: float = _chapter_four.meter("heat")
	if heat >= 70.0 and not _chapter_four.flag("heat_warning_logged"):
		_chapter_four.set_flag("heat_warning_logged")
		_story_log("Heat threshold: WARNING %d%%" % roundi(heat))
	if heat >= 90.0 and not _chapter_four.flag("heat_critical_logged"):
		_chapter_four.set_flag("heat_critical_logged")
		_story_log("Heat threshold: CRITICAL %d%%" % roundi(heat))
	if heat >= 100.0:
		_chapter_four.set_flag("heat_failure_active")
		var grace: float = _chapter_four.tick_timer("critical_grace", delta)
		if grace <= 0.0:
			_story_custom_failure = "Forge heat remained critical for too long."
			_fail_custom_story_stage()
	else:
		_chapter_four.set_flag("heat_failure_active", false)
		_chapter_four.set_timer("critical_grace", 10.0)

func _update_c4_ore_rush(delta: float) -> void:
	_chapter_four.adjust_meter("heat", -delta * 0.12)
	_update_c4_ore_thieves(delta)
	for i in range(_adventure_props.size() - 1, -1, -1):
		var prop: Dictionary = _adventure_props[i]
		var kind: String = str(prop.get("kind", ""))
		var near: bool = (prop.pos as Vector2).distance_to(_player_pos) < 135.0
		if kind == "c4_ore_deposit":
			var deposit_type: int = int(prop.get("deposit_type", 0))
			prop["heat_locked"] = deposit_type == 1 and _chapter_four.meter("heat") >= 85.0
			if near and _chapter_four.count("ore_carried") < 3 and not bool(prop.get("heat_locked", false)):
				var duration: float = float([3.0, 5.0, 4.0][deposit_type])
				prop["progress"] = float(prop.get("progress", 0.0)) + delta
				_chapter_four.adjust_meter("heat", delta * float([1.2, 2.8, 2.0][deposit_type]))
				if float(prop["progress"]) >= duration:
					var ore_yield: int = int(prop.get("yield", 1))
					var capacity: int = 3 - _chapter_four.count("ore_carried")
					var carried: int = mini(capacity, ore_yield)
					_chapter_four.add_count("ore_carried", carried)
					_chapter_four.add_count("ore_mined", ore_yield)
					for dropped_index in range(ore_yield - carried):
						_spawn_custom_prop("c4_ore_bag", prop.pos as Vector2 + Vector2.from_angle(float(dropped_index) * 2.4) * 75.0, {"value":1, "stolen":false})
					if deposit_type == 2:
						_spawn_custom_prop("c4_lava_vent", prop.pos as Vector2, {"life":14.0})
						_story_log("Unstable deposit collapsed: temporary lava vent opened")
					_story_log("Ore mined: type=%d yield=%d heat=%d" % [deposit_type, ore_yield, roundi(_chapter_four.meter("heat"))])
					_adventure_props.remove_at(i)
					continue
			else:
				prop["progress"] = 0.0
			_adventure_props[i] = prop
		elif kind == "c4_ore_bag" and near and _chapter_four.count("ore_carried") < 3:
			_chapter_four.add_count("ore_carried")
			_adventure_props.remove_at(i)
		elif kind == "c4_cooling_vent":
			prop["cooldown"] = maxf(0.0, float(prop.get("cooldown", 0.0)) - delta)
			if near and int(prop.get("charges", 0)) > 0 and float(prop.get("cooldown", 0.0)) <= 0.0:
				prop["progress"] = float(prop.get("progress", 0.0)) + delta
				if float(prop["progress"]) >= 2.0:
					prop["progress"] = 0.0
					prop["charges"] = int(prop.get("charges", 0)) - 1
					prop["cooldown"] = 18.0
					_chapter_four.adjust_meter("heat", -28.0)
					_story_log("Cooling vent activated: heat=%d" % roundi(_chapter_four.meter("heat")))
			elif not near: prop["progress"] = 0.0
			_adventure_props[i] = prop
		elif kind == "c4_lava_vent":
			prop["life"] = float(prop.get("life", 0.0)) - delta
			if near: _chapter_four.adjust_meter("heat", delta * 1.8)
			if float(prop["life"]) <= 0.0: _adventure_props.remove_at(i)
			else: _adventure_props[i] = prop
	var cart_index: int = _find_adventure_prop("c4_mining_cart")
	if cart_index < 0: return
	var cart: Dictionary = _adventure_props[cart_index]
	if _chapter_four.phase == "mining_logistics":
		if (cart.pos as Vector2).distance_to(_player_pos) < 150.0 and _chapter_four.count("ore_carried") > 0:
			var delivered: int = mini(_chapter_four.count("ore_carried"), _chapter_four.count("ore_required") - _chapter_four.count("ore_delivered"))
			_chapter_four.add_count("ore_delivered", delivered)
			_chapter_four.add_count("ore_carried", -delivered)
			cart["loaded"] = _chapter_four.count("ore_delivered")
			_adventure_props[cart_index] = cart
			_story_log("Ore delivered: %d/%d" % [_chapter_four.count("ore_delivered"), _chapter_four.count("ore_required")])
		if _chapter_four.count("ore_delivered") >= _chapter_four.count("ore_required"):
			_chapter_four.set_flag("cart_loaded")
			_chapter_four.set_flag("extraction_started")
			_spawn_custom_prop("c4_extraction", _story_objective_zone_position(7, 1050.0), {})
			_c4_enter_phase("cart_extraction")
	elif _chapter_four.phase == "cart_extraction":
		var extraction_index: int = _find_adventure_prop("c4_extraction")
		if extraction_index < 0: return
		var destination: Vector2 = _adventure_props[extraction_index].pos as Vector2
		var cart_blocked: bool = _find_story_enemy("c4_cart_blocker") >= 0
		if (cart.pos as Vector2).distance_to(_player_pos) < 280.0 and not cart_blocked:
			cart["pos"] = (cart.pos as Vector2).move_toward(destination, delta * 105.0)
			cart["progress"] = 1.0 - (cart.pos as Vector2).distance_to(destination) / maxf(_story_stage_origin.distance_to(destination), 1.0)
			_adventure_props[cart_index] = cart
		var cart_progress: float = float(cart.get("progress", 0.0))
		for blockage_number in 2:
			var blockage_key: String = "cart_blockage_%d" % (blockage_number + 1)
			if cart_progress >= float(blockage_number + 1) * 0.32 and not _chapter_four.flag(blockage_key):
				_chapter_four.set_flag(blockage_key)
				_spawn_story_objective_enemy("normal_tank", "c4_cart_blocker", 2.1 + float(blockage_number) * 0.35, cart.pos as Vector2 + Vector2(190.0, 0.0))
				_story_log("Cart movement blocked: clear the forge obstruction")
		if (cart.pos as Vector2).distance_to(destination) < 45.0:
			_chapter_four.set_flag("cart_reached_extraction")
			_chapter_four.set_flag("no_ore_stolen")
			_chapter_four.set_flag("cargo_transition_clear")
			_chapter_four.set_flag("primary_complete")
			_story_primary_complete = true
			_request_story_victory("chapter_four_ore_extracted")

func _update_c4_ore_thieves(delta: float) -> void:
	if _chapter_four.phase != "mining_logistics": return
	if _chapter_four.tick_timer("ore_thief", delta) <= 0.0:
		if _find_adventure_prop("c4_ore_bag") >= 0 and _find_story_enemy("c4_ore_thief") < 0:
			_spawn_story_objective_enemy("normal_fast", "c4_ore_thief", 1.35, _custom_objective_position(460.0))
			_story_log("Ore thief entered: unattended ore at risk")
		_chapter_four.set_timer("ore_thief", 18.0)
	var thief_index: int = _find_story_enemy("c4_ore_thief")
	if thief_index < 0: return
	var thief: Dictionary = _enemies[thief_index]
	if int(thief.get("stolen_ore", 0)) <= 0:
		var bag_index: int = _find_adventure_prop("c4_ore_bag")
		if bag_index >= 0:
			var bag_pos: Vector2 = _adventure_props[bag_index].pos as Vector2
			thief["pos"] = (thief.pos as Vector2).move_toward(bag_pos, delta * 150.0)
			if (thief.pos as Vector2).distance_to(bag_pos) < 55.0:
				_adventure_props.remove_at(bag_index)
				thief["stolen_ore"] = 1
				_chapter_four.add_count("ore_stolen")
				_story_log("Ore stolen: recover it from the marked thief")
	else:
		var thief_exit: Vector2 = _story_stage_origin + Vector2(1050.0, 0.0)
		thief["pos"] = (thief.pos as Vector2).move_toward(thief_exit, delta * 125.0)
	_enemies[thief_index] = thief

func _update_c4_molten_circuit(delta: float) -> void:
	if _chapter_four.phase == "lava_routing":
		for i in _adventure_props.size():
			var prop: Dictionary = _adventure_props[i]
			if str(prop.get("kind", "")) != "lava_valve": continue
			var inside: bool = (prop.pos as Vector2).distance_to(_player_pos) < 110.0
			if inside and not bool(prop.get("inside", false)):
				var mask: int = _chapter_four.count("valve_mask") ^ int(prop.get("toggle_mask", 0))
				_chapter_four.set_count("valve_mask", mask)
				_chapter_four.set_count("mechanisms_powered", _bit_count(mask))
				_chapter_four.adjust_meter("heat", 5.0 if mask != 7 else -12.0)
				_story_log("Valve activated: %d · powered=%d/3" % [int(prop.get("valve", 0)) + 1, _bit_count(mask)])
				for mechanism_index in _adventure_props.size():
					if str(_adventure_props[mechanism_index].get("kind", "")) == "c4_forge_mechanism":
						var mechanism: int = int(_adventure_props[mechanism_index].get("mechanism", 0))
						_adventure_props[mechanism_index]["powered"] = (mask & (1 << mechanism)) != 0
				if mask == 7:
					for route_index in 3:
						_spawn_custom_prop("c4_route_node", _story_objective_zone_position(route_index + 4, 540.0), {"route":route_index})
					_c4_enter_phase("powered_traversal")
			prop["inside"] = inside
			_adventure_props[i] = prop
	elif _chapter_four.phase == "powered_traversal":
		var next_route: int = _chapter_four.count("route_nodes")
		for i in range(_adventure_props.size() - 1, -1, -1):
			var prop: Dictionary = _adventure_props[i]
			if str(prop.get("kind", "")) == "c4_route_node" and int(prop.get("route", -1)) == next_route and (prop.pos as Vector2).distance_to(_player_pos) < 125.0:
				_adventure_props.remove_at(i)
				_chapter_four.add_count("route_nodes")
				if _chapter_four.count("route_nodes") >= 3:
					_chapter_four.set_flag("route_traversal_complete")
					_chapter_four.set_timer("stabilization", 35.0)
					_c4_spawn_timer = 3.0
					_c4_enter_phase("forge_stabilization")
				return
	elif _chapter_four.phase == "forge_stabilization":
		var jammer_active: bool = _find_story_enemy("c4_forge_jammer") >= 0
		_chapter_four.set_flag("mandatory_jam_active", jammer_active)
		for mechanism_index in _adventure_props.size():
			if str(_adventure_props[mechanism_index].get("kind", "")) == "c4_forge_mechanism":
				_adventure_props[mechanism_index]["jammed"] = jammer_active
		if not jammer_active: _chapter_four.tick_timer("stabilization", delta)
		_c4_spawn_timer -= delta
		if _c4_spawn_timer <= 0.0 and not jammer_active:
			_spawn_story_objective_enemy("normal_fast", "c4_forge_jammer", 1.45, _custom_objective_position(420.0))
			_c4_spawn_timer = 9.0
		if _chapter_four.timer("stabilization") <= 0.0 and not jammer_active:
			_chapter_four.set_flag("puzzle_initialized")
			_chapter_four.set_flag("mechanisms_powered")
			_chapter_four.set_flag("stabilization_complete")
			_chapter_four.set_flag("no_mandatory_jam")
			_chapter_four.set_flag("primary_complete")
			_story_primary_complete = true
			_request_story_victory("chapter_four_circuit_stable")

func _spawn_c4_golem(index: int) -> void:
	_adventure_props.clear()
	var position: Vector2 = _story_objective_zone_position(index, 560.0)
	_spawn_story_objective_enemy("normal_tank", "c4_golem_%d" % (index + 1), 3.0 + float(index) * 0.45, position)
	if index == 0: _spawn_custom_prop("c4_charge_wall", position + Vector2(420.0, 0.0), {})
	elif index == 1: _spawn_custom_prop("c4_cooling_vent", position + Vector2(-360.0, 100.0), {"charges":99, "progress":0.0})
	elif index == 2:
		for drone_index in 3: _spawn_story_objective_enemy("normal_fast", "c4_repair_drone", 1.2, position + Vector2.from_angle(float(drone_index) * TAU / 3.0) * 220.0)
	else:
		_spawn_custom_prop("c4_tether", position + Vector2(-300.0, 0.0), {"tether":0, "active":false, "progress":0.0})
		_spawn_custom_prop("c4_tether", position + Vector2(300.0, 0.0), {"tether":1, "active":false, "progress":0.0})

func _update_c4_golem_taming(delta: float) -> void:
	var golem_number: int = _chapter_four.count("golems_captured") + 1
	var golem_index: int = _find_story_enemy("c4_golem_%d" % golem_number)
	if golem_index < 0: return
	var golem: Dictionary = _enemies[golem_index]
	var hp_ratio: float = float(golem.hp) / maxf(float(golem.get("objective_max_hp", golem.hp)), 1.0)
	var ready: bool = false
	if golem_number == 1:
		var wall: int = _find_adventure_prop("c4_charge_wall")
		ready = hp_ratio <= 0.35 and wall >= 0 and (golem.pos as Vector2).distance_to(_adventure_props[wall].pos as Vector2) < 330.0
	elif golem_number == 2:
		var vent: int = _find_adventure_prop("c4_cooling_vent")
		if vent >= 0:
			var cooling_vent: Dictionary = _adventure_props[vent]
			var golem_in_cooling: bool = (golem.pos as Vector2).distance_to(cooling_vent.pos as Vector2) < 380.0
			var player_at_vent: bool = (cooling_vent.pos as Vector2).distance_to(_player_pos) < 240.0
			if hp_ratio <= 0.35 and golem_in_cooling and player_at_vent and not bool(cooling_vent.get("cooled", false)):
				cooling_vent["progress"] = float(cooling_vent.get("progress", 0.0)) + delta
				if float(cooling_vent["progress"]) >= 2.0:
					cooling_vent["cooled"] = true
					_story_log("Golem mechanic state: cooling core exposed")
			elif not player_at_vent:
				cooling_vent["progress"] = 0.0
			_adventure_props[vent] = cooling_vent
			ready = bool(cooling_vent.get("cooled", false))
	elif golem_number == 3:
		var repair_drone_count: int = 0
		for enemy in _enemies:
			if str(enemy.get("story_tag", "")) == "c4_repair_drone": repair_drone_count += 1
		if repair_drone_count > 0:
			golem["hp"] = minf(float(golem.get("objective_max_hp", golem.hp)), float(golem.hp) + float(golem.get("objective_max_hp", golem.hp)) * 0.012 * float(repair_drone_count) * delta)
			_enemies[golem_index] = golem
		ready = hp_ratio <= 0.35 and _find_story_enemy("c4_repair_drone") < 0
	else:
		for tether_index in _adventure_props.size():
			var tether: Dictionary = _adventure_props[tether_index]
			if str(tether.get("kind", "")) != "c4_tether" or bool(tether.get("active", false)): continue
			if (tether.pos as Vector2).distance_to(_player_pos) < 120.0:
				tether["progress"] = float(tether.get("progress", 0.0)) + delta
				var tether_duration: float = 1.2 if _chapter_four.count("golems_captured") >= 3 else 2.0
				if float(tether["progress"]) >= tether_duration:
					tether["active"] = true
					_story_log("Captured Golem assistance: tether stabilized")
			else: tether["progress"] = 0.0
			_adventure_props[tether_index] = tether
		ready = hp_ratio <= 0.35 and _count_c4_active_tethers() >= 2
	if hp_ratio <= 0.20:
		golem["hp"] = float(golem.get("objective_max_hp", 100.0)) * 0.20
		_enemies[golem_index] = golem
	_chapter_four.set_flag("capture_ready", ready)
	var capture_range: float = 230.0 if golem_number in [1, 2] else 145.0
	var capture_channel_active: bool = ready and (golem.pos as Vector2).distance_to(_player_pos) < capture_range
	_chapter_four.set_flag("capture_channel_active", capture_channel_active)
	if capture_channel_active:
		_c4_action_timer += delta
		if _c4_action_timer >= 2.5:
			_c4_action_timer = 0.0
			_enemies.remove_at(golem_index)
			var captured: int = _chapter_four.add_count("golems_captured")
			_chapter_four.set_flag("golem_%d_captured" % captured)
			_story_log("Golem captured: %d/4" % captured)
			if captured >= 4:
				_chapter_four.set_flag("assistance_resolved")
				_chapter_four.set_flag("capture_pending", false)
				_chapter_four.set_flag("capture_channel_active", false)
				_chapter_four.set_flag("capture_ready", false)
				_chapter_four.set_flag("primary_complete")
				_story_primary_complete = true
				_request_story_victory("chapter_four_golems_captured")
			else:
				_spawn_c4_golem(captured)
				_c4_enter_phase(str(["charge_stun", "cooling_capture", "drone_separation", "tether_capture"][captured]))
	else: _c4_action_timer = 0.0

func _count_c4_active_tethers() -> int:
	var count: int = 0
	for prop in _adventure_props:
		if str(prop.get("kind", "")) == "c4_tether" and bool(prop.get("active", false)): count += 1
	return count

func _spawn_c4_chamber(index: int) -> void:
	_adventure_props.clear()
	_spawn_custom_prop("relic_chamber", _story_objective_zone_position(index, 680.0), {"component":index, "opened":false})

func _update_c4_lost_relic(delta: float) -> void:
	var components: int = _chapter_four.count("components_collected")
	if components < 3:
		var chamber: int = _find_adventure_prop("relic_chamber")
		if chamber >= 0 and not bool(_adventure_props[chamber].get("opened", false)) and (_adventure_props[chamber].pos as Vector2).distance_to(_player_pos) < 140.0:
			_adventure_props[chamber]["opened"] = true
			_spawn_story_objective_enemy("normal_tank" if components != 1 else "normal_fast", "c4_chamber_guardian_%d" % (components + 1), 2.8 + float(components) * 0.55, _adventure_props[chamber].pos as Vector2)
			_c4_spawn_timer = 2.0
			_c4_enter_phase(str(["flame_guardian", "collapse_guardian", "reflection_guardian"][components]))
		_c4_spawn_timer -= delta
		if _c4_spawn_timer <= 0.0 and _find_story_enemy("c4_chamber_guardian_%d" % (components + 1)) >= 0:
			_c3_spawn_pressure(2, "c4_chamber_hazard", 1.1 + float(components) * 0.12)
			_c4_spawn_timer = 7.0
	elif not _chapter_four.flag("relic_choice_committed"):
		if _find_adventure_prop("relic_forge") < 0: _spawn_custom_prop("relic_forge", _story_stage_origin + Vector2(0.0, -220.0), {})
		var forge: int = _find_adventure_prop("relic_forge")
		if forge >= 0 and (_adventure_props[forge].pos as Vector2).distance_to(_player_pos) < 145.0:
			_show_c4_relic_choice()

func _show_c4_relic_choice() -> void:
	if _adventure_choice_layer != null: return
	_paused = true
	var layer := CanvasLayer.new(); layer.layer = 130; add_child(layer); _adventure_choice_layer = layer
	var view: Vector2 = get_viewport_rect().size
	var shade := ColorRect.new(); shade.color = Color(0.02, 0.02, 0.03, 0.90); shade.size = view; layer.add_child(shade)
	var box := VBoxContainer.new(); box.position = Vector2(70.0, view.y * 0.24); box.size = Vector2(view.x - 140.0, 520.0); box.add_theme_constant_override("separation", 18); layer.add_child(box)
	var title := Label.new(); title.text = "FORGE THE LOST RELIC"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 40); box.add_child(title)
	for choice: Dictionary in [{"id":"power", "text":"POWER RELIC · Higher attack"}, {"id":"guard", "text":"GUARD RELIC · Defensive shield"}, {"id":"swift", "text":"SWIFT RELIC · Movement and cooldown"}]:
		var button := _pause_btn(str(choice.text), Color(0.42, 0.20, 0.08), Color.WHITE); button.custom_minimum_size = Vector2(0.0, 92.0); box.add_child(button)
		button.pressed.connect(_select_c4_relic.bind(str(choice.id)))

func _select_c4_relic(choice: String) -> void:
	_close_adventure_choice()
	_chapter_four.set_flag("relic_assembled")
	_chapter_four.set_flag("relic_choice_committed")
	_story_custom_progress["relic_choice"] = choice
	if choice == "power": _ring_bonuses["skill_dmg"] = float(_ring_bonuses.get("skill_dmg", 0.0)) + 0.25
	elif choice == "guard": _player_max_hp *= 1.20; _player_hp = minf(_player_max_hp, _player_hp + _player_max_hp * 0.20)
	else: _player_speed *= 1.15
	_adventure_props.clear()
	_spawn_story_objective_enemy("normal_tank", "c4_relic_guardian", 4.0, _story_objective_zone_position(7, 560.0))
	_chapter_four.set_flag("relic_guardian_spawned")
	_chapter_four.set_flag("boss_spawned")
	_c4_enter_phase("relic_guardian")

func _update_c4_meltdown(delta: float) -> void:
	var shutdown: int = _chapter_four.count("regulators_disabled")
	if _chapter_four.flag("shutdown_complete"):
		_chapter_four.adjust_meter("heat", -delta * 1.15)
	else:
		_chapter_four.adjust_meter("heat", delta * (0.24 + float(4 - shutdown) * 0.06))
	for i in _adventure_props.size():
		var regulator: Dictionary = _adventure_props[i]
		if str(regulator.get("kind", "")) != "regulator" or bool(regulator.get("disabled", false)): continue
		var near: bool = (regulator.pos as Vector2).distance_to(_player_pos) < 120.0
		if near:
			regulator["progress"] = float(regulator.get("progress", 0.0)) + delta
			if float(regulator["progress"]) >= 2.0:
				regulator["progress"] = 0.0
				var regulator_id: int = int(regulator.get("regulator", 0))
				var expected: int = _chapter_four.sequence[shutdown]
				if regulator_id == expected:
					regulator["disabled"] = true
					shutdown = _chapter_four.add_count("regulators_disabled")
					_chapter_four.set_count("boss_regulator_phases_completed", shutdown)
					_chapter_four.adjust_meter("heat", -18.0)
					_story_log("Regulator activated: correct %d/4" % shutdown)
					_story_log("Boss ability disabled: %s" % str(["Lava Eruption", "Armour Regeneration", "Projectile Forge", "Arena Heat Pulse"][regulator_id]))
					_chapter_four.set_flag("boss_system_%d_disabled" % regulator_id)
					if shutdown == 2 and not _chapter_four.flag("boss_spawned"):
						_spawn_story_objective_enemy("thunderforge_behemoth", "c4_thunderforge_behemoth", 4.8, _story_stage_origin + Vector2(0.0, -520.0))
						_chapter_four.set_flag("boss_spawned")
						var spawned_boss_index: int = _find_story_enemy("c4_thunderforge_behemoth")
						if spawned_boss_index >= 0:
							_enemies[spawned_boss_index]["forge_systems_active"] = 2
							for disabled_system in 4:
								_enemies[spawned_boss_index]["system_%d_disabled" % disabled_system] = _chapter_four.flag("boss_system_%d_disabled" % disabled_system)
						if _chapter_four.meter("heat") >= 55.0:
							var remaining_regulator: int = _chapter_four.sequence[2]
							_chapter_four.sequence[2] = _chapter_four.sequence[3]
							_chapter_four.sequence[3] = remaining_regulator
							_story_log("Shutdown order changed: new environmental clue active")
						_c4_enter_phase("overlapping_shutdown")
					var active_boss_index: int = _find_story_enemy("c4_thunderforge_behemoth")
					if active_boss_index >= 0:
						_enemies[active_boss_index]["forge_systems_active"] = maxi(0, 4 - shutdown)
						_enemies[active_boss_index]["system_%d_disabled" % regulator_id] = true
						_enemies[active_boss_index]["dmg"] = float(_enemies[active_boss_index].get("dmg", 1.0)) * 0.88
					if shutdown >= 4:
						_chapter_four.set_flag("shutdown_complete")
						_chapter_four.set_flag("shutdown_committed")
						_chapter_four.set_flag("final_phase_entered")
						_chapter_four.adjust_meter("heat", -30.0)
						_c4_enter_phase("behemoth_final")
				else:
					_chapter_four.adjust_meter("heat", 14.0)
					_chapter_four.set_flag("regulator_transition_pending", true)
					_story_log("Regulator activated: wrong · heat increased")
					call_deferred("_clear_c4_regulator_transition")
		else: regulator["progress"] = 0.0
		_adventure_props[i] = regulator
	var behemoth_index: int = _find_story_enemy("c4_thunderforge_behemoth")
	if behemoth_index >= 0:
		var behemoth: Dictionary = _enemies[behemoth_index]
		for active_regulator in _adventure_props:
			if str(active_regulator.get("kind", "")) != "regulator" or bool(active_regulator.get("disabled", false)): continue
			var away_from_regulator: Vector2 = (active_regulator.pos as Vector2).direction_to(behemoth.pos as Vector2)
			if away_from_regulator.is_zero_approx(): away_from_regulator = Vector2.RIGHT
			if (behemoth.pos as Vector2).distance_to(active_regulator.pos as Vector2) < 190.0:
				behemoth["pos"] = active_regulator.pos as Vector2 + away_from_regulator * 190.0
		_enemies[behemoth_index] = behemoth

func _clear_c4_regulator_transition() -> void:
	if _chapter_four != null: _chapter_four.set_flag("regulator_transition_pending", false)

func _update_cleanse_mire(delta: float) -> void:
	var needed := int(_story_custom_progress.get("energy_needed", 3))
	for i in range(_adventure_props.size() - 1, -1, -1):
		var pool := _adventure_props[i]
		if str(pool.get("kind", "")) != "corrupted_pool": continue
		if int(_story_custom_progress.get("energy", 0)) >= needed and (pool.pos as Vector2).distance_to(_player_pos) < 175.0:
			_story_custom_interaction += delta
			if _story_custom_interaction >= 2.5:
				_story_custom_progress["energy"] = int(_story_custom_progress.get("energy", 0)) - needed
				_story_custom_interaction = 0.0
				_adventure_props.remove_at(i)
				_complete_staged_objective_instance()
			return
	_story_custom_interaction = 0.0

func _update_plaguebeast() -> void:
	var index := _find_story_enemy("plaguebeast")
	var tracker := _find_adventure_prop("tracker")
	if index < 0: return
	if tracker >= 0: _adventure_props[tracker]["pos"] = _enemies[index].pos
	var enemy := _enemies[index]
	if bool(enemy.get("shield_active", false)):
		if _story_gate_remaining <= 0:
			enemy["shield_active"] = false
			_enemies[index] = enemy
		else:
			return
	var hp_ratio := float(enemy.hp) / maxf(float(enemy.get("objective_max_hp", enemy.hp)), 1.0)
	var escapes := int(_story_custom_progress.get("escapes", 0))
	var threshold := 0.68 if escapes == 0 else 0.35
	if escapes < 2 and hp_ratio <= threshold:
		enemy["pos"] = _custom_objective_position(760.0 + float(escapes) * 160.0)
		enemy["shield_active"] = true
		_enemies[index] = enemy
		_story_custom_progress["escapes"] = escapes + 1
		_spawn_story_gate_ambush(8 + escapes * 4)

func _update_venom_harvest() -> void:
	var phase: int = int(_story_custom_progress.get("phase", 0))
	var phase_key: String = str(["spider", "toad", "wasp"][clampi(phase, 0, 2)])
	if int(_story_custom_progress.get(phase_key, 0)) >= 3 and phase < 2:
		_story_custom_progress["phase"] = phase + 1
		_spawn_story_gate_ambush(6 + phase * 3)
	if int(_story_custom_progress.get("spider", 0)) >= 3 and int(_story_custom_progress.get("toad", 0)) >= 3 and int(_story_custom_progress.get("wasp", 0)) >= 3:
		_complete_custom_story_stage()

func _update_fragile_cure(delta: float) -> void:
	var checkpoints: int = int(_story_custom_progress.get("checkpoints", 0))
	if checkpoints < 3 and _find_adventure_prop("cure_checkpoint") < 0 and _story_gate_remaining <= 0:
		_spawn_cure_checkpoint(checkpoints)
	elif checkpoints >= 3 and _find_adventure_prop("infected_altar") < 0 and _story_gate_remaining <= 0:
		_spawn_custom_prop("infected_altar", _story_objective_zone_position(3, 900.0), {})
	for i in range(_adventure_props.size() - 1, -1, -1):
		var prop := _adventure_props[i]
		var kind := str(prop.get("kind", ""))
		if kind == "cure_checkpoint" and int(prop.get("checkpoint", -1)) == int(_story_custom_progress.get("checkpoints", 0)) and (prop.pos as Vector2).distance_to(_player_pos) < 125.0:
			_story_custom_progress["checkpoints"] = int(_story_custom_progress.get("checkpoints", 0)) + 1
			_adventure_props.remove_at(i)
			_spawn_story_gate_ambush(6 + int(_story_custom_progress.get("checkpoints", 0)) * 2)
			return
		if kind == "infected_altar" and int(_story_custom_progress.get("checkpoints", 0)) >= 3 and _story_gate_remaining <= 0 and (prop.pos as Vector2).distance_to(_player_pos) < 145.0:
			_complete_custom_story_stage(); return
		if kind == "healing_fountain" and (prop.pos as Vector2).distance_to(_player_pos) < 130.0:
			_story_custom_progress["vial"] = minf(100.0, float(_story_custom_progress.get("vial", 100.0)) + 18.0 * delta)

func _spawn_cure_checkpoint(checkpoint: int) -> void:
	_spawn_custom_prop("cure_checkpoint", _story_objective_zone_position(checkpoint, 680.0), {"checkpoint":checkpoint})

func _update_grand_antidote() -> void:
	if _find_adventure_prop("ingredient") < 0 and _story_custom_carried.is_empty() and _story_gate_remaining <= 0 and int(_story_custom_progress.get("submitted", 0)) < _story_custom_sequence.size():
		_spawn_current_antidote_ingredient()
	for i in range(_adventure_props.size() - 1, -1, -1):
		var prop := _adventure_props[i]
		if str(prop.get("kind", "")) == "ingredient" and (prop.pos as Vector2).distance_to(_player_pos) < 90.0 and _story_custom_carried.is_empty():
			_story_custom_carried = str(prop.get("ingredient", -1))
			_adventure_props.remove_at(i)
			return
	var cauldron := _find_adventure_prop("cauldron")
	if cauldron < 0 or _story_custom_carried.is_empty(): return
	var near := (_adventure_props[cauldron].pos as Vector2).distance_to(_player_pos) < 120.0
	if near and _story_custom_touch_lock != "cauldron":
		var submitted := int(_story_custom_progress.get("submitted", 0))
		if int(_story_custom_carried) == _story_custom_sequence[submitted]:
			submitted += 1
			_story_custom_progress["submitted"] = submitted
			if submitted >= _story_custom_sequence.size(): _complete_custom_story_stage()
			else:
				_spawn_story_gate_ambush(5 + submitted * 3)
		else:
			_story_custom_progress["submitted"] = 0
			_spawn_story_penalty_elite()
			_respawn_antidote_ingredients()
		_story_custom_carried = ""
		_story_custom_touch_lock = "cauldron"
	elif not near:
		_story_custom_touch_lock = ""

func _respawn_antidote_ingredients() -> void:
	for i in range(_adventure_props.size() - 1, -1, -1):
		if str(_adventure_props[i].get("kind", "")) == "ingredient": _adventure_props.remove_at(i)
	_spawn_current_antidote_ingredient()

func _spawn_current_antidote_ingredient() -> void:
	var submitted: int = int(_story_custom_progress.get("submitted", 0))
	if submitted < 0 or submitted >= _story_custom_sequence.size(): return
	_spawn_custom_prop("ingredient", _story_objective_zone_position(submitted, 720.0), {"ingredient":_story_custom_sequence[submitted]})

func _update_silent_descent(delta: float) -> void:
	var hidden: bool = false
	var detected: bool = false
	_story_custom_progress["inside_active_safe_point"] = false
	for prop_index in _adventure_props.size():
		var prop: Dictionary = _adventure_props[prop_index]
		var kind: String = str(prop.get("kind", ""))
		var pos: Vector2 = prop.pos
		if kind == "hiding_zone" and pos.distance_to(_player_pos) < 150.0:
			hidden = true
			var current_safe_point: int = int(_story_custom_progress.get("safe_points", 0))
			if not bool(prop.get("visited", false)) and int(prop.get("section", -1)) == current_safe_point:
				_story_custom_progress["inside_active_safe_point"] = true
				var activation_progress: float = minf(10.0, float(prop.get("activation_progress", 0.0)) + delta)
				prop["activation_progress"] = activation_progress
				_story_custom_progress["safe_point_hold"] = activation_progress
				if activation_progress >= 10.0:
					prop["visited"] = true
					_story_custom_progress["safe_points"] = current_safe_point + 1
					_story_custom_progress["safe_point_hold"] = 0.0
					_story_log("Stealth safe point activated: %d/3" % int(_story_custom_progress["safe_points"]))
				_adventure_props[prop_index] = prop
		elif kind == "sentry":
			var patrol_target: Vector2 = prop.get("patrol_target", pos) as Vector2
			var patrol_start: Vector2 = prop.get("patrol_start", pos) as Vector2
			var patrol_end: Vector2 = prop.get("patrol_end", pos) as Vector2
			if pos.distance_to(patrol_target) <= 6.0:
				patrol_target = patrol_start if patrol_target.distance_to(patrol_end) <= 6.0 else patrol_end
				prop["patrol_target"] = patrol_target
			var movement_direction: Vector2 = pos.direction_to(patrol_target)
			if not movement_direction.is_zero_approx():
				prop["facing"] = movement_direction
				pos = pos.move_toward(patrol_target, float(prop.get("patrol_speed", 82.0)) * delta)
				prop["pos"] = pos
			_adventure_props[prop_index] = prop
			var facing: Vector2 = prop.get("facing", Vector2.RIGHT) as Vector2
			if pos.distance_to(_player_pos) < 380.0 and absf(facing.angle_to(pos.direction_to(_player_pos))) < 0.58:
				detected = true
		elif kind == "citadel_gate" and pos.distance_to(_player_pos) < 145.0:
			if int(_story_custom_progress.get("safe_points", 0)) >= 3:
				_story_custom_progress["gate_reached"] = true
				_complete_custom_story_stage(); return
	var detection_time: float = float(_story_custom_progress.get("detection_time", 0.0))
	var ambush_cooldown: float = maxf(0.0, float(_story_custom_progress.get("scan_ambush_cooldown", 0.0)) - delta)
	if detected and not hidden and ambush_cooldown <= 0.0:
		_spawn_silent_descent_ambush(6)
		ambush_cooldown = 8.0
		_story_log("Patrol sighting: stealth ambush spawned")
	if detected and not hidden:
		detection_time = minf(2.0, detection_time + delta)
	else:
		detection_time = maxf(0.0, detection_time - delta * 2.0)
	_story_custom_progress["detection_time"] = detection_time
	_story_custom_progress["scan_ambush_cooldown"] = ambush_cooldown
	_story_custom_progress["hidden"] = hidden
	_story_custom_progress["detected"] = detected
	# Briefly crossing a sight cone only raises suspicion. Alert begins after one
	# continuous second of exposure and is never raised merely by nearby enemies.
	var rate: float = -24.0 if hidden else (8.0 if detection_time >= 1.0 else -10.0)
	_story_custom_alert = clampf(_story_custom_alert + rate * delta, 0.0, 100.0)
	if _story_custom_alert >= 100.0:
		var lockdowns: int = int(_story_custom_progress.get("lockdowns", 0))
		if lockdowns == 0:
			_story_custom_progress["lockdowns"] = 1
			_story_custom_progress["detection_time"] = 0.0
			_story_custom_alert = 45.0
			_spawn_story_gate_ambush(6)
		else:
			_fail_custom_story_stage()

func _spawn_silent_descent_ambush(count: int) -> void:
	for enemy_index in count:
		var kind: String = "normal_tank" if enemy_index % 4 == 3 else ("normal_fast" if enemy_index % 2 == 0 else "normal")
		var spawn_direction: Vector2 = Vector2.RIGHT.rotated(float(enemy_index) * TAU / float(maxi(count, 1)))
		var spawn_position: Vector2 = _player_pos + spawn_direction * randf_range(380.0, 520.0)
		_spawn_story_objective_enemy(kind, "silent_descent_ambush", 1.12, spawn_position)

func _update_soul_liberation(delta: float) -> void:
	_update_custom_breakables(delta, "soul_chain", 165.0)
	if _find_adventure_prop("soul_chain") < 0 and _find_adventure_prop("released_soul") < 0 and _adventure_progress < _adventure_target:
		_spawn_custom_prop("released_soul", _custom_objective_position(280.0), {})
	var soul := _find_adventure_prop("released_soul")
	var portal := _find_adventure_prop("abyss_portal")
	if soul < 0 or portal < 0: return
	var soul_pos: Vector2 = _adventure_props[soul].pos
	var portal_pos: Vector2 = _adventure_props[portal].pos
	soul_pos = soul_pos.move_toward(portal_pos, 105.0 * delta)
	_adventure_props[soul]["pos"] = soul_pos
	if soul_pos.distance_to(_player_pos) < 70.0:
		_adventure_props.remove_at(soul)
		_adventure_progress += 1
		if _adventure_progress >= _adventure_target: _complete_custom_story_stage()
		else: _spawn_soul_chain()
	elif soul_pos.distance_to(portal_pos) < 65.0:
		_adventure_props.remove_at(soul)
		_spawn_soul_chain()

func _update_mirror_labyrinth() -> void:
	for i in _adventure_props.size():
		var prop := _adventure_props[i]
		var inside := (prop.pos as Vector2).distance_to(_player_pos) < 100.0
		if inside and not bool(prop.get("inside", false)):
			if int(prop.get("portal", -1)) == int(_story_custom_progress.get("correct", -2)):
				_adventure_progress += 1
				_story_custom_progress["room"] = _adventure_progress
				if _adventure_progress >= _adventure_target: _complete_custom_story_stage()
				else: _spawn_mirror_room()
			else:
				_adventure_progress = maxi(0, _adventure_progress - 1)
				_spawn_story_penalty_elite()
				_spawn_mirror_room()
			return
		prop["inside"] = inside
		_adventure_props[i] = prop

func _update_twin_eclipse(delta: float) -> void:
	if _story_gate_remaining > 0: return
	var first := int(_story_custom_progress.get("first", -1))
	if first >= 0:
		_story_custom_progress["window"] = float(_story_custom_progress.get("window", 10.0)) - delta
		if float(_story_custom_progress.get("window", 0.0)) <= 0.0:
			_story_custom_progress = {"first":-1, "window":0.0}
	for i in _adventure_props.size():
		var prop := _adventure_props[i]
		var inside := (prop.pos as Vector2).distance_to(_player_pos) < 115.0
		if inside and not bool(prop.get("inside", false)):
			var obelisk := int(prop.get("obelisk", i))
			first = int(_story_custom_progress.get("first", -1))
			if first < 0:
				_story_custom_progress = {"first":obelisk, "window":10.0}
			elif first != obelisk:
				_complete_custom_story_stage()
				return
		prop["inside"] = inside
		_adventure_props[i] = prop

func _update_abyss_king(delta: float) -> void:
	if _story_custom_phase == 1:
		_story_custom_timer -= delta
		if _story_custom_timer <= 0.0:
			_story_log("Timer expired: abyss_king_ritual")
			_fail_custom_story_stage()
			return
		_update_custom_breakables(delta, "ritual_anchor", 180.0)
		if _adventure_progress < 3 and _find_adventure_prop("ritual_anchor") < 0:
			if int(_story_custom_progress.get("anchor_ambush_for", -1)) != _adventure_progress:
				_story_custom_progress["anchor_ambush_for"] = _adventure_progress
				_spawn_story_gate_ambush(6 + _adventure_progress * 3)
			elif _story_gate_remaining <= 0:
				_spawn_next_ritual_anchor()
		if _adventure_progress >= 3:
			_story_log_phase("ritual_anchors", "abyss_crown")
			_story_custom_phase = 2
			_adventure_progress = 0
			_adventure_props.clear()
			_spawn_custom_prop("abyss_crown", _player_pos + Vector2(0, -360), {"hp":320.0, "max_hp":320.0})
	elif _story_custom_phase == 2:
		var reflection_active: bool = not _is_abyss_crown_vulnerable()
		if not reflection_active:
			_update_custom_breakables(delta, "abyss_crown", 180.0)
		else:
			var crown := _find_adventure_prop("abyss_crown")
			_story_custom_interaction = maxf(0.0, _story_custom_interaction - delta)
			if crown >= 0 and (_adventure_props[crown].pos as Vector2).distance_to(_player_pos) < 180.0 and _story_custom_interaction <= 0.0:
				_story_custom_interaction = 0.8
				_damage_player(_player_max_hp * 0.06, 0.35)
		if _find_adventure_prop("abyss_crown") < 0:
			_story_log_phase("abyss_crown", "abyss_king")
			_story_custom_phase = 3
			_adventure_progress = 0
			_spawn_story_objective_enemy("abyss_king_boss", "abyss_king", 1.8, _player_pos + Vector2(0, -430))

func _is_abyss_crown_vulnerable() -> bool:
	return _story_custom_id == "abyss_king" and _story_custom_phase == 2 and fmod(_elapsed, 4.0) < 1.6

func _is_inside_vulnerable_crown_window() -> bool:
	if not _is_abyss_crown_vulnerable():
		return false
	var crown_index: int = _find_adventure_prop("abyss_crown")
	if crown_index < 0:
		return false
	var crown_position: Vector2 = _adventure_props[crown_index].get("pos", Vector2.ZERO) as Vector2
	return crown_position.distance_to(_player_pos) < 200.0

func _spawn_next_ritual_anchor() -> void:
	if _adventure_progress >= 3 or _find_adventure_prop("ritual_anchor") >= 0: return
	var anchor_hp: float = 220.0 + float(_adventure_progress) * 75.0
	_spawn_custom_prop("ritual_anchor", _story_objective_zone_position(_adventure_progress, 620.0), {"hp":anchor_hp, "max_hp":anchor_hp})

func _find_story_enemy(tag: String) -> int:
	for i in _enemies.size():
		if str(_enemies[i].get("story_tag", "")) == tag: return i
	return -1

func _spawn_story_penalty_elite() -> void:
	_spawn_story_objective_enemy("normal_tank", "objective_penalty", 2.0, _custom_objective_position(260.0))

func _handle_custom_story_enemy_death(enemy: Dictionary) -> bool:
	var tag := str(enemy.get("story_tag", ""))
	if tag == "objective_gate":
		_story_gate_remaining = maxi(0, _story_gate_remaining - 1)
		return false
	if _adventure_state == "story_chapter_one" and _chapter_one != null:
		match tag:
			"spore_carrier":
				_adventure_props.append({"kind":"c1_energy_spore", "pos":enemy.pos as Vector2, "hp":1.0, "max_hp":1.0, "energy":2.0})
				_story_log("Objective activation: energy spore dropped")
			"supply_foreman":
				_chapter_one.set_flag("foreman_resolved")
				_chapter_one.set_flag("supplies_secured")
				_chapter_one.set_flag("feeding_sacs_resolved")
				_chapter_one.set_flag("primary_complete")
				_story_primary_complete = true
				call_deferred("_request_story_victory", "chapter_one_supplies_secured")
			"fleeing_key_carrier", "protected_key_carrier", "watchpath_captain":
				_adventure_props.append({"kind":"key", "pos":enemy.pos as Vector2, "hp":1.0, "max_hp":1.0})
				_chapter_one.set_flag("key_enemy_held", false)
				_story_log("Objective completion: key carrier defeated")
			"crestkeeper":
				_chapter_one.set_flag("boss_defeated")
				_chapter_one.set_flag("finale_complete")
				_chapter_one.set_flag("primary_complete")
				_story_primary_complete = true
				_story_required_boss_defeated = true
				_story_log("Boss death: Crestkeeper")
		return false
	if _adventure_state != "story_custom": return false
	if _chapter_five != null and int(story_stage.get("chapter", 0)) == 5:
		match tag:
			"c5_soul_binder":
				_story_log("Spirit capture resolved: Soul Binder defeated")
				return false
			"c5_portal_keeper":
				_chapter_five.set_flag("boss_defeated")
				_chapter_five.set_flag("portal_keeper_resolved")
				_story_required_boss_defeated = true
				_story_log("Boss death: Portal Keeper Elite")
				return false
			"c5_mirror_guardian":
				_chapter_five.set_flag("boss_defeated")
				_chapter_five.set_flag("guardian_defeated")
				_story_required_boss_defeated = true
				_story_log("Boss death: Mirror Guardian")
				call_deferred("_finish_c5_mirror_guardian")
				return false
			"c5_eclipse_elite":
				_chapter_five.set_flag("boss_defeated")
				_chapter_five.set_flag("eclipse_elite_resolved")
				_story_required_boss_defeated = true
				_story_log("Boss death: Eclipse Elite")
				return false
			"c5_crown_channeler":
				_chapter_five.set_timer("crown_vulnerable", 7.0)
				_story_log("Crown vulnerability opened: ritual channeler interrupted")
				return false
			"abyss_king":
				if not _chapter_five.flag("final_phase_entered"):
					return true
				_chapter_five.set_flag("boss_defeated")
				_chapter_five.set_flag("primary_complete")
				_chapter_five.set_flag("boss_transition_pending", false)
				_story_required_boss_defeated = true
				_story_primary_complete = true
				_story_log("Boss death: actual Abyss King")
				call_deferred("_request_story_victory", "chapter_five_abyss_king_defeated")
				return false
	if _chapter_four != null and int(story_stage.get("chapter", 0)) == 4:
		if tag == "c4_ore_thief":
			var recovered_ore: int = int(enemy.get("stolen_ore", 0))
			if recovered_ore > 0:
				_spawn_custom_prop("c4_ore_bag", enemy.pos as Vector2, {"value":recovered_ore, "stolen":false})
				_chapter_four.add_count("ore_stolen", -recovered_ore)
				_story_log("Ore recovered from thief: %d" % recovered_ore)
			return false
		if tag == "c4_cart_blocker":
			_story_log("Cart obstruction cleared: extraction resumed")
			return false
		if tag.begins_with("c4_golem_"):
			# Rogue golems are captured, never killed. A lethal hit leaves them weakened.
			var golem_index: int = _find_story_enemy(tag)
			if golem_index >= 0:
				var golem: Dictionary = _enemies[golem_index]
				golem["hp"] = maxf(1.0, float(golem.get("objective_max_hp", 100.0)) * 0.20)
				_enemies[golem_index] = golem
			_story_log("Golem weakened: capture mechanic required")
			return true
		if tag.begins_with("c4_chamber_guardian_"):
			var component_number: int = _chapter_four.add_count("components_collected")
			_chapter_four.set_flag("chamber_%d_complete" % component_number)
			var component_name: String = str(["Ember Core", "Forge Frame", "Relic Heart"][component_number - 1])
			if component_number == 1:
				_player_max_hp *= 1.12
				_player_hp = minf(_player_max_hp, _player_hp + _player_max_hp * 0.20)
			elif component_number == 2:
				_player_speed *= 1.10
			_story_log("Relic component collected: %s · %d/3" % [component_name, component_number])
			if component_number < 3:
				_spawn_c4_chamber(component_number)
				_c4_enter_phase(str(["flame_chamber", "collapse_chamber", "reflection_chamber"][component_number]))
			else:
				_adventure_props.clear()
				_spawn_custom_prop("relic_forge", _story_stage_origin + Vector2(0.0, -220.0), {})
				_c4_enter_phase("relic_assembly")
			return false
		if tag == "c4_relic_guardian":
			_chapter_four.set_flag("boss_defeated")
			_chapter_four.set_flag("primary_complete")
			_story_required_boss_defeated = true
			_story_primary_complete = true
			_story_log("Boss death: Lost Relic Guardian")
			call_deferred("_request_story_victory", "chapter_four_relic_guardian_defeated")
			return false
		if tag == "c4_thunderforge_behemoth":
			if not _chapter_four.flag("shutdown_complete"):
				var behemoth_index: int = _find_story_enemy(tag)
				if behemoth_index >= 0:
					var behemoth: Dictionary = _enemies[behemoth_index]
					behemoth["hp"] = maxf(1.0, float(behemoth.get("objective_max_hp", 100.0)) * 0.25)
					_enemies[behemoth_index] = behemoth
				_story_log("Boss defeat blocked: finish the shutdown sequence")
				return true
			_chapter_four.set_flag("boss_defeated")
			_chapter_four.set_flag("primary_complete")
			_story_required_boss_defeated = true
			_story_primary_complete = true
			_story_log("Boss death: Thunderforge Behemoth")
			call_deferred("_request_story_victory", "chapter_four_meltdown_stopped")
			return false
	if _chapter_three != null and int(story_stage.get("chapter", 0)) == 3:
		match tag:
			"c3_energy_carrier":
				_spawn_custom_prop("c3_cleansing_energy", enemy.pos as Vector2, {"value":2})
				_story_log("Cleansing energy dropped by marked carrier")
				return false
			"c3_plague_sighting":
				# The first sighting always escapes; it cannot be killed early.
				_chapter_three.set_flag("escape_pending", false)
				_spawn_c3_tracking_choices()
				_c3_enter_phase("tracking")
				_story_log("Beast escaped: forced sighting threshold")
				var sighting_index: int = _find_story_enemy(tag)
				if sighting_index >= 0: _enemies.remove_at(sighting_index)
				return true
			"c3_plaguebeast_final":
				_chapter_three.set_flag("boss_defeated")
				_chapter_three.set_flag("escape_pending", false)
				_chapter_three.set_flag("primary_complete")
				_story_required_boss_defeated = true
				_story_primary_complete = true
				_story_log("Boss death: Plaguebeast")
				var plaguebeast_index: int = _find_story_enemy(tag)
				if plaguebeast_index >= 0: _enemies.remove_at(plaguebeast_index)
				call_deferred("_request_story_victory", "chapter_three_plaguebeast_defeated")
				return true
			"c3_marked_spider", "c3_marked_toad", "c3_marked_wasp":
				var ingredient: String = str({"c3_marked_spider":"spider", "c3_marked_toad":"toad", "c3_marked_wasp":"wasp"}[tag])
				var count: int = _chapter_three.add_count(ingredient)
				_story_log("Ingredient obtained: %s %d/3" % [ingredient.capitalize(), count])
				if count >= 3:
					_chapter_three.set_flag("%s_complete" % ingredient)
					_chapter_three.add_count("regions_complete")
					if _chapter_three.count("regions_complete") >= 3:
						_chapter_three.set_flag("ingredient_case_assembled")
						_story_custom_carried = "ingredient_case"
						_adventure_props.clear()
						_spawn_custom_prop("c3_extraction", _story_objective_zone_position(7, 620.0), {})
						_c3_spawn_timer = 1.0
						_c3_enter_phase("ingredient_extraction")
					else:
						_chapter_three.set_flag("ingredients_contaminated")
						_adventure_props.clear()
						_spawn_custom_prop("c3_cleanse_station", _player_pos + Vector2(0.0, -210.0), {})
						_c3_enter_phase("region_select")
				else:
					_spawn_c3_region_target(_chapter_three.count("active_region"))
				return false
			"c3_blight_tyrant":
				_chapter_three.set_flag("boss_defeated")
				_chapter_three.set_flag("primary_complete")
				_story_required_boss_defeated = true
				_story_primary_complete = true
				_story_log("Boss death: Blight Vine Tyrant")
				var tyrant_index: int = _find_story_enemy(tag)
				if tyrant_index >= 0: _enemies.remove_at(tyrant_index)
				call_deferred("_request_story_victory", "chapter_three_blight_tyrant_defeated")
				return true
	if _chapter_two != null and int(story_stage.get("chapter", 0)) == 2:
		match tag:
			"c2_flamekeeper":
				_story_custom_carried = "flame_charge"
				_story_log("Objective completion: Flamekeeper dropped flame charge")
				return false
			"c2_brazier_suppressor":
				_story_log("Suppression growth intercepted before reaching a brazier")
				return false
			"c2_jailer_elite":
				_chapter_two.set_flag("jailer_elite_resolved")
				_story_log("Objective completion: Jailer Elite resolved")
				return false
			"frost_mimic":
				_chapter_two.set_flag("mimic_defeated")
				_chapter_two.set_flag("boss_defeated")
				_chapter_two.set_flag("finale_complete")
				_chapter_two.set_flag("primary_complete")
				_story_required_boss_defeated = true
				_story_primary_complete = true
				_story_log("Boss death: actual Frost Mimic")
				call_deferred("_request_story_victory", "chapter_two_frost_mimic_defeated")
				return true
			"frost_colossus":
				if _chapter_two.count("crystals_broken") >= 3 and _chapter_two.flag("all_armour_transitions_complete"):
					_chapter_two.set_flag("boss_defeated")
					_chapter_two.set_flag("finale_complete")
					_chapter_two.set_flag("primary_complete")
					_story_required_boss_defeated = true
					_story_primary_complete = true
					_story_log("Boss death: Frostbound Colossus")
					call_deferred("_request_story_victory", "chapter_two_colossus_defeated")
					return true
	if tag == "story_final":
		if _is_boss_kind(str(enemy.get("kind", ""))):
			_story_required_boss_defeated = true
			_story_log("Boss defeated: %s" % str(enemy.get("kind", "")))
		_story_final_remaining = maxi(0, _story_final_remaining - 1)
		if _story_final_remaining <= 0:
			_story_final_completed = true
			_story_log("Objective completed: final_assault · required_completed=all")
			_complete_custom_story_stage()
			return true
		return false
	if _story_custom_id == "cleanse_mire":
		_story_custom_progress["energy"] = mini(9, int(_story_custom_progress.get("energy", 0)) + 1)
	elif _story_custom_id == "venom_harvest":
		var enemy_kind := str(enemy.get("kind", "normal"))
		var ingredient := "spider" if enemy_kind == "normal_fast" else ("toad" if enemy_kind == "normal_tank" else "wasp")
		_story_custom_progress[ingredient] = mini(3, int(_story_custom_progress.get(ingredient, 0)) + 1)
	match tag:
		"frost_mimic", "plaguebeast", "abyss_king":
			_story_required_boss_defeated = true
			_story_log("Boss defeated: %s" % tag)
			_complete_custom_story_stage()
			return true
		"frost_colossus":
			if _story_custom_phase >= 1:
				_story_required_boss_defeated = true
				_story_log("Boss defeated: frost_colossus")
				_complete_custom_story_stage()
				return true
	return false

func _complete_custom_story_stage() -> void:
	_story_primary_complete = true
	if _story_telemetry != null:
		_story_telemetry.log_once("primary_complete", "Objective completed: %s" % _story_custom_id)
	_request_story_victory("%s_complete" % _story_custom_id)

func _request_story_victory(reason: String) -> bool:
	if story_stage.is_empty():
		return false
	if _story_telemetry != null:
		_story_telemetry.victory_requested(reason)
	_story_last_victory_request = reason
	var state := _story_completion_state()
	var result: Dictionary = StoryCompletionValidatorClass.validate(story_stage, state)
	if not bool(result.get("accepted", false)):
		var rejection_reason: String = str(result.get("reason", "requirements_incomplete"))
		if _story_telemetry != null:
			_story_telemetry.victory_rejected(rejection_reason, _story_completion_snapshot(state))
		_story_last_victory_result = "BLOCKED — %s" % rejection_reason
		_refresh_story_debug_overlay(true)
		if bool(result.get("start_finale", false)) and not _story_final_triggered:
			_begin_custom_story_final_encounter()
		return false
	_story_victory_validated = true
	_story_victory_started = true
	if _story_telemetry != null:
		_story_telemetry.victory_accepted(str(result.get("reason", "all_required_conditions_complete")))
	_story_last_victory_result = "ACCEPTED — %s" % str(result.get("reason", "all_required_conditions_complete"))
	_refresh_story_debug_overlay(true)
	_adventure_state = "story_complete"
	_adventure_props.clear()
	_enemies.clear()
	_reset_staged_objective_state()
	call_deferred("_show_story_victory")
	return true

func _story_completion_state() -> Dictionary:
	var objective: String = str(story_stage.get("objective", ""))
	var finale_required: bool = _story_custom_data.has("final_boss") or int(_story_custom_data.get("final_enemy_count", 0)) > 0
	if int(story_stage.get("chapter", 0)) in [2, 3, 4]:
		finale_required = false
	var required_total: int = _staged_objective_required if _staged_objective_enabled else _adventure_target
	var required_generated: int = _staged_objective_generated if _staged_objective_enabled else _adventure_target
	var required_completed: int = _staged_objective_completed if _staged_objective_enabled else _adventure_progress
	var required_active: int = _staged_objective_active
	if int(story_stage.get("chapter", 1)) == 1:
		match objective:
			"nests":
				required_total = 3
				required_generated = _story_nests_generated
				required_completed = _story_nests_destroyed
				required_active = 1 if _find_adventure_prop("nest") >= 0 else 0
			"keys":
				required_total = _adventure_target
				required_generated = _story_keys_generated
				required_completed = _adventure_progress
				required_active = 1 if _find_adventure_prop("key") >= 0 else 0
	var target_alive := _story_required_target_survived
	if objective == "escort" and not _adventure_props.is_empty():
		target_alive = str(_adventure_props[0].get("kind", "")) == "scout" and float(_adventure_props[0].get("hp", 0.0)) > 0.0
	elif objective == "defend" and not _adventure_props.is_empty():
		target_alive = str(_adventure_props[0].get("kind", "")) == "shrine" and float(_adventure_props[0].get("hp", 0.0)) > 0.0
	var state: Dictionary = {
		"victory_committed": _story_victory_started,
		"primary_complete": _story_primary_complete,
		"objective_started": _adventure_state not in ["story_escort_wait", "story_defend_wait"],
		"staged_required": _staged_objective_enabled,
		"required_total": required_total,
		"required_generated": required_generated,
		"required_completed": required_completed,
		"required_active": required_active,
		"pending_spawn": _staged_objective_enabled and _staged_objective_generated < _staged_objective_required,
		"required_gate_remaining": _story_gate_remaining,
		"timer_expired": _adventure_timer <= 0.0,
		"route_complete": _story_route_index >= _story_route_waypoints.size() and not _story_route_waypoints.is_empty(),
		"target_alive": target_alive,
		"finale_required": finale_required,
		"finale_triggered": _story_final_triggered,
		"finale_complete": _story_final_completed,
		"boss_required": (int(story_stage.get("chapter", 1)) == 1 and int(story_stage.get("chapter_stage", 1)) == 5) or objective in ["frost_mimic", "plaguebeast", "frost_colossus", "abyss_king"] or not str(_story_custom_data.get("final_boss", "")).is_empty(),
		"boss_defeated": _story_required_boss_defeated,
		"stage_phase": _story_custom_phase,
		"failure_active": not _story_custom_failure.is_empty(),
	}
	if _chapter_one != null and int(story_stage.get("chapter", 0)) == 1:
		state.merge(_chapter_one.completion_state(), true)
		state["primary_complete"] = _story_primary_complete and _chapter_one.flag("primary_complete")
		state["target_alive"] = _chapter_one.flag("target_alive") and target_alive
		state["barrage_phases_completed"] = _adventure_progress if objective == "hazards" else 0
		state["feeding_sacs_resolved"] = int(_story_custom_progress.get("feeding_sacs", 0)) >= 3
		state["foreman_resolved"] = _chapter_one.flag("foreman_resolved")
		state["supplies_secured"] = _chapter_one.flag("supplies_secured")
	if _chapter_two != null and int(story_stage.get("chapter", 0)) == 2:
		state.merge(_chapter_two.completion_state(), true)
		state["primary_complete"] = _story_primary_complete and _chapter_two.flag("primary_complete")
		state["boss_defeated"] = _story_required_boss_defeated or _chapter_two.flag("boss_defeated")
		state["pending_transition"] = _chapter_two.flag("transition_pending")
	if _chapter_three != null and int(story_stage.get("chapter", 0)) == 3:
		state.merge(_chapter_three.completion_state(), true)
		state["primary_complete"] = _story_primary_complete and _chapter_three.flag("primary_complete")
		state["boss_defeated"] = _story_required_boss_defeated or _chapter_three.flag("boss_defeated")
	if _chapter_four != null and int(story_stage.get("chapter", 0)) == 4:
		state.merge(_chapter_four.completion_state(), true)
		state["primary_complete"] = _story_primary_complete and _chapter_four.flag("primary_complete")
		state["boss_defeated"] = _story_required_boss_defeated or _chapter_four.flag("boss_defeated")
	if _chapter_five != null and int(story_stage.get("chapter", 0)) == 5:
		state.merge(_chapter_five.completion_state(), true)
		state["primary_complete"] = _story_primary_complete and _chapter_five.flag("primary_complete")
		state["active_soul_chains"] = _count_adventure_props("soul_chain")
		state["active_spirits"] = _count_adventure_props("released_soul")
		state["spirits_captured"] = _c5_captured_spirit_count()
		state["elite_disruption_active"] = _find_adventure_prop("eclipse_disruption") >= 0
		state["boss_defeated"] = _story_required_boss_defeated or _chapter_five.flag("boss_defeated")
		state["spirits_captured"] = _c5_captured_spirit_count()
	return state

func _story_completion_snapshot(state: Dictionary) -> String:
	var fields: Array[String] = ["primary_complete=%s" % str(state.get("primary_complete", false))]
	if bool(state.get("staged_required", false)) or int(state.get("required_total", 0)) > 0:
		fields.append("required_generated=%d/%d" % [int(state.get("required_generated", 0)), int(state.get("required_total", 0))])
		fields.append("required_completed=%d/%d" % [int(state.get("required_completed", 0)), int(state.get("required_total", 0))])
		fields.append("required_active=%d" % int(state.get("required_active", 0)))
	if bool(state.get("staged_required", false)):
		fields.append("pending_spawn=%s" % str(state.get("pending_spawn", false)))
	if int(state.get("required_gate_remaining", 0)) > 0:
		fields.append("required_gate_remaining=%d" % int(state.get("required_gate_remaining", 0)))
	if bool(state.get("finale_required", false)):
		fields.append("finale_triggered=%s" % str(state.get("finale_triggered", false)))
		fields.append("finale_complete=%s" % str(state.get("finale_complete", false)))
	if bool(state.get("boss_required", false)):
		fields.append("boss_defeated=%s" % str(state.get("boss_defeated", false)))
	return " ".join(fields)

func _story_log(message: String) -> void:
	if _story_telemetry != null:
		_story_telemetry.log_event(message)

func _story_log_phase(previous: String, current: String) -> void:
	if _story_telemetry != null:
		_story_telemetry.phase_changed(previous, current)

func _begin_custom_story_final_encounter() -> void:
	if _story_final_triggered:
		return
	_story_final_triggered = true
	_story_final_completed = false
	_story_log_phase("primary_objective", "final_assault")
	_story_gate_remaining = 0
	_adventure_props.clear()
	_enemies.clear()
	_boss_projs.clear()
	var final_boss: String = str(_story_custom_data.get("final_boss", ""))
	if not final_boss.is_empty():
		_story_final_remaining = 1
		_spawn_story_objective_enemy(final_boss, "story_final", 1.4 + float(story_stage.get("chapter", 1)) * 0.16, _player_pos + Vector2(0.0, -520.0))
		return
	var final_count: int = maxi(1, int(_story_custom_data.get("final_enemy_count", 10)))
	_story_final_remaining = final_count
	for enemy_index in final_count:
		var kind := "normal_tank" if enemy_index % 4 == 3 else ("normal_fast" if enemy_index % 3 == 2 else "normal")
		_spawn_story_objective_enemy(kind, "story_final", 1.15 + float(story_stage.get("chapter", 1)) * 0.12, _player_pos + Vector2.RIGHT.rotated(float(enemy_index) * TAU / float(final_count)) * randf_range(420.0, 560.0))

func _fail_custom_story_stage(reason: String = "") -> void:
	if _game_over: return
	_story_custom_failure = reason
	if _story_custom_failure.is_empty():
		match _story_custom_id:
			"ore_rush": _story_custom_failure = "The forge overheated before twelve ore were mined."
			"meltdown": _story_custom_failure = "The Emberforge core melted down."
			"silent_descent": _story_custom_failure = "The citadel alert meter reached maximum."
			"abyss_king": _story_custom_failure = "The Abyss King's corruption ritual completed."
			_: _story_custom_failure = "The objective was not completed."
	_reset_staged_objective_state()
	_player_hp = 0.0
	_on_death()

func _setup_chapter_one_stage(objective: String) -> void:
	_chapter_one = ChapterOneStageControllerClass.new()
	_chapter_one.reset(int(story_stage.get("chapter_stage", 1)))
	_story_custom_id = "chapter_one_%s" % objective
	_story_custom_phase = 0
	_story_custom_progress = {}
	_story_custom_failure = ""
	_story_final_triggered = false
	_story_final_completed = false
	_story_nests_destroyed = 0
	_story_nests_generated = 0
	_story_keys_generated = 0
	_adventure_progress = 0
	_adventure_target = 3
	_adventure_state = "story_chapter_one"
	_adventure_props.clear()
	_enemies.clear()
	_boss_projs.clear()
	_c1_phase_timer = 0.0
	_c1_interaction = 0.0
	_c1_spawn_budget = 0.0
	_c1_command = "follow"
	_c1_route_choice = ""
	_c1_threshold = 0
	_c1_milestones = 0
	if objective == "defend":
		_adventure_props.append({"kind":"shrine", "pos":_player_pos + Vector2(380.0, 0.0), "hp":900.0, "max_hp":900.0, "energy":20.0})
	elif objective == "hazards":
		_chapter_one.set_flag("mission_started")
		_c1_enter_phase("radial_barrage", 48.0)
		_story_hazard_arena_center = _player_pos
		_story_hazard_shot_timer = 0.8
		_story_hazard_pattern = 0
		_adventure_props.append({"kind":"hazard_emitter", "pos":_story_hazard_arena_center, "hp":1.0, "max_hp":1.0})
		_lock_story_hazard_camera()
	_story_log("Objective activation: Chapter 1 stage %d setup" % _chapter_one.stage_number)

func _c1_enter_phase(next_phase: String, duration: float = 0.0) -> void:
	var previous: String = _chapter_one.enter(next_phase)
	_story_custom_phase += 1
	_c1_phase_timer = duration
	_chapter_one.set_flag("transition_pending", false)
	_story_log_phase(previous, next_phase)
	_story_log("Objective activation: %s" % next_phase)

func _update_chapter_one_stage(delta: float) -> void:
	match int(story_stage.get("chapter_stage", 1)):
		1: _update_c1_broken_trail(delta)
		2: _update_c1_mushroom_crossing(delta)
		3: _update_c1_supply_thieves(delta)
		4: _update_c1_watchpath(delta)
		5: _update_c1_crestkeeper_gate(delta)

func _c1_spawn_pressure(count: int, tag: String, center: Vector2, strength: float = 1.0) -> void:
	for enemy_index in count:
		var kind: String = "normal_tank" if enemy_index % 5 == 4 else ("normal_fast" if enemy_index % 2 == 0 else "normal")
		var position: Vector2 = center + Vector2.RIGHT.rotated(TAU * float(enemy_index) / float(maxi(count, 1))) * randf_range(390.0, 540.0)
		_spawn_story_objective_enemy(kind, tag, strength * _story_stage_strength(), position)

func _update_c1_broken_trail(delta: float) -> void:
	if not _chapter_one.flag("mission_started") or _adventure_props.is_empty():
		return
	var scout_index: int = _find_adventure_prop("scout")
	if scout_index < 0:
		_fail_custom_story_stage("The Scout was lost.")
		return
	var scout: Dictionary = _adventure_props[scout_index]
	if float(scout.get("hp", 0.0)) <= 0.0:
		_fail_custom_story_stage("The Scout was defeated.")
		return
	var phase: String = _chapter_one.phase
	if phase in ["first_route", "short_route", "long_route", "final_pursuit"]:
		if _story_route_index < _story_route_waypoints.size() and _c1_command != "wait":
			var destination: Vector2 = _story_route_waypoints[_story_route_index]
			var speed: float = 105.0 if _c1_command == "hurry" else (125.0 if phase == "final_pursuit" else 90.0)
			if (scout.pos as Vector2).distance_to(_player_pos) > 720.0:
				speed *= 0.35
			scout.pos = (scout.pos as Vector2).move_toward(destination, speed * delta)
			if (scout.pos as Vector2).distance_to(destination) < 36.0:
				_story_route_index += 1
				_story_log("Route progress: %d/%d" % [_story_route_index, _story_route_waypoints.size()])
				if phase == "first_route" and _story_route_index >= 2:
					_chapter_one.set_flag("transition_pending")
					_c1_enter_phase("route_choice")
					call_deferred("_show_c1_route_choice")
				elif phase in ["short_route", "long_route"] and _story_route_index >= _story_route_waypoints.size():
					_spawn_c1_barricade(scout.pos as Vector2)
					_c1_enter_phase("barricade")
				elif phase == "final_pursuit" and _story_route_index >= _story_route_waypoints.size():
					_chapter_one.set_flag("route_complete")
					_chapter_one.set_flag("extraction_reached")
					_adventure_props.append({"kind":"c1_extraction", "pos":scout.pos as Vector2, "hp":1.0, "max_hp":1.0})
					_c1_enter_phase("extraction", 18.0)
		_c1_spawn_budget -= delta
		if _c1_spawn_budget <= 0.0 and _enemies.size() < 44:
			_c1_spawn_budget = 2.1 if phase != "final_pursuit" else 1.25
			var travel_direction: Vector2 = Vector2.RIGHT
			if _story_route_index < _story_route_waypoints.size():
				travel_direction = (scout.pos as Vector2).direction_to(_story_route_waypoints[_story_route_index])
			var ambush_center: Vector2 = (scout.pos as Vector2) + travel_direction * 900.0
			var pursuit_count: int = 8 if phase == "final_pursuit" else (7 if phase == "short_route" else 5)
			_c1_spawn_pressure(pursuit_count, "escort_pursuer", ambush_center, 0.82)
	elif phase == "barricade":
		_c1_spawn_budget -= delta
		if _c1_spawn_budget <= 0.0 and _enemies.size() < 40:
			_c1_spawn_budget = 1.7
			_c1_spawn_pressure(6, "barricade_blocker", scout.pos as Vector2, 0.9)
		var barricade_index: int = _find_adventure_prop("c1_barricade")
		if barricade_index >= 0 and (_adventure_props[barricade_index].pos as Vector2).distance_to(_player_pos) < 175.0:
			_c1_interaction += delta
			_story_custom_progress["channel"] = clampf(_c1_interaction / 10.0, 0.0, 1.0)
		else:
			_c1_interaction = maxf(0.0, _c1_interaction - delta * 0.4)
		if _c1_interaction >= 10.0:
			if barricade_index >= 0: _adventure_props.remove_at(barricade_index)
			_chapter_one.set_flag("interaction_complete")
			_story_route_waypoints = [(scout.pos as Vector2) + Vector2(1800.0, -300.0), (scout.pos as Vector2) + Vector2(4200.0, 180.0)]
			_story_route_index = 0
			_c1_enter_phase("final_pursuit")
	elif phase == "extraction":
		_c1_phase_timer = maxf(0.0, _c1_phase_timer - delta)
		_c1_spawn_budget -= delta
		if _c1_spawn_budget <= 0.0 and _enemies.size() < 40:
			_c1_spawn_budget = 1.6
			_c1_spawn_pressure(6, "extraction_raider", scout.pos as Vector2, 0.95)
		if _c1_phase_timer <= 0.0:
			_chapter_one.set_flag("extraction_complete")
			_chapter_one.set_flag("primary_complete")
			_story_primary_complete = true
			_request_story_victory("chapter_one_extraction_complete")
	if scout_index < _adventure_props.size():
		_adventure_props[scout_index] = scout

func _spawn_c1_barricade(position: Vector2) -> void:
	_adventure_props.append({"kind":"c1_barricade", "pos":position + Vector2(180.0, 0.0), "hp":1.0, "max_hp":1.0})
	_c1_spawn_pressure(12, "barricade_blocker", position + Vector2(260.0, 0.0), 0.9)

func _update_c1_mushroom_crossing(delta: float) -> void:
	if not _chapter_one.flag("mission_started"):
		return
	var spore_radius: float = 190.0 if str(_story_custom_progress.get("blessing", "")) == "wider_spore_collection" else 105.0
	for prop_index in range(_adventure_props.size() - 1, -1, -1):
		var pickup: Dictionary = _adventure_props[prop_index]
		if str(pickup.get("kind", "")) == "c1_energy_spore" and (pickup.pos as Vector2).distance_to(_player_pos) <= spore_radius:
			var pickup_shrine_index: int = _find_adventure_prop("shrine")
			if pickup_shrine_index >= 0:
				var pickup_shrine: Dictionary = _adventure_props[pickup_shrine_index]
				pickup_shrine.energy = minf(100.0, float(pickup_shrine.get("energy", 0.0)) + float(pickup.get("energy", 2.0)))
				_adventure_props[pickup_shrine_index] = pickup_shrine
				if float(pickup_shrine.energy) >= 100.0 and not _chapter_one.flag("timer_complete"):
					_chapter_one.set_flag("timer_complete")
					_story_log("Objective completion: Shrine fully powered")
			_adventure_props.remove_at(prop_index)
			_story_log("Objective progress: energy spore collected")
	var shrine_index: int = _find_adventure_prop("shrine")
	if shrine_index < 0 or float(_adventure_props[shrine_index].get("hp", 0.0)) <= 0.0:
		_fail_custom_story_stage("The Mushroom Shrine was destroyed.")
		return
	var shrine: Dictionary = _adventure_props[shrine_index]
	if _chapter_one.phase == "energy_defence":
		shrine.energy = 100.0 if _chapter_one.flag("timer_complete") else maxf(0.0, float(shrine.get("energy", 20.0)) - delta * 0.05)
		_c1_spawn_budget -= delta
		if _c1_spawn_budget <= 0.0:
			_c1_spawn_budget = 6.0
			var pressure_tag: String = "shrine_attacker" if _chapter_one.flag("timer_complete") else "spore_carrier"
			_c1_spawn_pressure(4 + _c1_milestones, pressure_tag, shrine.pos as Vector2, 0.75 + float(_c1_milestones) * 0.12)
		var energy: float = float(shrine.get("energy", 0.0))
		var milestone: int = floori(energy / 25.0)
		if milestone > _c1_milestones:
			_c1_milestones = milestone
			_story_log("Timer progress milestone: shrine energy %d%%" % (milestone * 25))
			if milestone in [2, 3]:
				_story_custom_progress["blessing"] = "healing_pulse" if milestone == 2 else "wider_spore_collection"
				_player_hp = minf(_player_max_hp, _player_hp + _player_max_hp * 0.16)
		if _chapter_one.flag("timer_complete"):
			_chapter_one.set_flag("growth_resolved")
			_c1_enter_phase("cleansing_channel", 12.0)
			_c1_spawn_budget = 0.0
	elif _chapter_one.phase == "cleansing_channel":
		_c1_phase_timer = maxf(0.0, _c1_phase_timer - delta)
		_c1_spawn_budget -= delta
		if _c1_spawn_budget <= 0.0 and _enemies.size() < 36:
			_c1_spawn_budget = 1.3
			_c1_spawn_pressure(5 + mini(_c1_milestones, 2), "cleansing_rusher", shrine.pos as Vector2, 1.05)
		if _c1_phase_timer <= 0.0:
			_chapter_one.set_flag("finale_complete")
			_chapter_one.set_flag("primary_complete")
			_story_primary_complete = true
			_request_story_victory("chapter_one_shrine_cleansed")
	if shrine_index < _adventure_props.size():
		_adventure_props[shrine_index] = shrine

func _update_c1_supply_thieves(delta: float) -> void:
	for prop_index in range(_adventure_props.size() - 1, -1, -1):
		var objective_prop: Dictionary = _adventure_props[prop_index]
		if str(objective_prop.get("kind", "")) != "c1_feeding_sac":
			continue
		if (objective_prop.pos as Vector2).distance_to(_player_pos) < 155.0:
			objective_prop.hp = float(objective_prop.hp) - (26.0 + _level * 2.5) * delta
			_adventure_props[prop_index] = objective_prop
			if float(objective_prop.hp) <= 0.0:
				_adventure_props.remove_at(prop_index)
				_story_custom_progress["feeding_sacs"] = int(_story_custom_progress.get("feeding_sacs", 0)) + 1
				_story_log("Objective progress: Nest's shields %d/3" % int(_story_custom_progress["feeding_sacs"]))
	var nest_index: int = _find_adventure_prop("nest")
	if nest_index < 0:
		return
	var nest: Dictionary = _adventure_props[nest_index]
	var nest_number: int = int(nest.get("nest_number", 1))
	_c1_spawn_budget -= delta
	if _c1_spawn_budget <= 0.0 and _enemies.size() < 22:
		_c1_spawn_budget = 2.6 if nest_number == 1 else 4.2
		_c1_spawn_pressure(2 + nest_number, "supply_thief" if nest_number == 1 else "nest_defender", nest.pos as Vector2, 0.75 + nest_number * 0.12)
	if nest_number == 2:
		var health_step: int = ceili(clampf(float(nest.hp) / float(nest.max_hp), 0.0, 1.0) * 3.0)
		if health_step < int(nest.get("health_step", 3)):
			nest.health_step = health_step
			nest.pos = _story_objective_zone_position(health_step + 1, 560.0)
			_story_log("Objective progress: Burrowing Nest relocated")
	var can_damage: bool = nest_number < 3 or int(_story_custom_progress.get("feeding_sacs", 0)) >= 3
	if can_damage and (nest.pos as Vector2).distance_to(_player_pos) < STORY_NEST_EFFECTIVE_RADIUS:
		nest.hp = float(nest.hp) - (24.0 + _level * 2.5) * delta
	_adventure_props[nest_index] = nest
	if float(nest.hp) <= 0.0:
		_adventure_props.remove_at(nest_index)
		_story_nests_destroyed += 1
		_story_log("Objective completion: Nest %d destroyed" % nest_number)
		if nest_number < 3:
			_chapter_one.set_flag("transition_pending")
			_c1_phase_timer = 3.0
			_spawn_c1_nest(nest_number + 1)
		else:
			_spawn_story_objective_enemy("normal_tank", "supply_foreman", 1.5 * _story_stage_strength(), nest.pos as Vector2)
			_c1_enter_phase("foreman_finale")

func _spawn_c1_nest(number: int) -> void:
	_story_nests_generated = maxi(_story_nests_generated, number)
	var position: Vector2 = _story_objective_zone_position(number, 620.0)
	var hp: float = (520.0 + number * 160.0) * _story_stage_strength()
	_adventure_props.append({"kind":"nest", "nest_number":number, "pos":position, "hp":hp, "max_hp":hp, "shield_t":0.0, "health_step":3})
	if number == 3:
		_story_custom_progress["feeding_sacs"] = 0
		var shield_offsets: Array[Vector2] = [Vector2(-520.0, -280.0), Vector2(470.0, -440.0), Vector2(620.0, 350.0)]
		for sac_index in 3:
			_adventure_props.append({"kind":"c1_feeding_sac", "sac":sac_index, "pos":position + shield_offsets[sac_index], "hp":90.0, "max_hp":90.0})
	_c1_enter_phase("nest_%d" % number)

func _update_c1_watchpath(_delta: float) -> void:
	_c1_spawn_budget -= _delta
	if _chapter_one.flag("mission_started") and _chapter_one.phase != "gate_window" and _c1_spawn_budget <= 0.0 and _enemies.size() < 36:
		_c1_spawn_budget = maxf(1.8, 2.8 - float(_adventure_progress) * 0.35)
		var reinforcement_count: int = 4 + _adventure_progress
		_c1_spawn_pressure(reinforcement_count, "watchpath_reinforcement", _player_pos, 0.82 + float(_adventure_progress) * 0.12)
	var examining_track: bool = false
	for prop_index in range(_adventure_props.size() - 1, -1, -1):
		var prop: Dictionary = _adventure_props[prop_index]
		var prop_kind: String = str(prop.get("kind", ""))
		if prop_kind == "c1_track_marker":
			if (prop.pos as Vector2).distance_to(_player_pos) < 150.0:
				examining_track = true
				_c1_interaction = minf(5.0, _c1_interaction + _delta)
				_story_custom_progress["track_examine"] = _c1_interaction / 5.0
				if _c1_interaction >= 5.0:
					_adventure_props.remove_at(prop_index)
					_c1_interaction = 0.0
					_story_custom_progress["track_examine"] = 0.0
					var tracks_found: int = int(_story_custom_progress.get("tracks_found", 0)) + 1
					_story_custom_progress["tracks_found"] = tracks_found
					_story_log("Route progress: carrier tracks %d/4 examined" % tracks_found)
					if tracks_found >= 4:
						_spawn_c1_key_carrier(int(_story_custom_progress.get("hunt_key", _adventure_progress + 1)))
					else:
						_spawn_c1_track_marker()
			continue
		if prop_kind == "key" and (prop.pos as Vector2).distance_to(_player_pos) < 78.0:
			_adventure_props.remove_at(prop_index)
			_adventure_progress += 1
			_chapter_one.set_flag("key_enemy_held", false)
			_story_log("Route progress: key %d/3 recovered" % _adventure_progress)
			if _adventure_progress < 3:
				_begin_c1_key_hunt(_adventure_progress + 1)
			else:
				_chapter_one.set_flag("gate_unlocked")
				_c1_enter_phase("gate_window", 22.0)
				_adventure_props.append({"kind":"c1_gate", "pos":_player_pos + Vector2(1500.0, 0.0), "hp":1.0, "max_hp":1.0})
	if not examining_track and _find_adventure_prop("c1_track_marker") >= 0:
		_c1_interaction = maxf(0.0, _c1_interaction - _delta * 1.5)
		_story_custom_progress["track_examine"] = _c1_interaction / 5.0
	if _chapter_one.phase == "gate_window":
		_c1_phase_timer = maxf(0.0, _c1_phase_timer - _delta)
		var gate_index: int = _find_adventure_prop("c1_gate")
		if gate_index >= 0 and (_adventure_props[gate_index].pos as Vector2).distance_to(_player_pos) < 110.0:
			_chapter_one.set_flag("gate_crossed")
			_chapter_one.set_flag("primary_complete")
			_story_primary_complete = true
			_request_story_victory("chapter_one_watchpath_crossed")
			return
		elif _c1_phase_timer <= 0.0:
			_c1_phase_timer = 14.0
			_story_log("Gate window missed: reopening window")
			if _story_telemetry != null:
				_story_telemetry.recovery("watchpath_gate_reopened")

func _begin_c1_key_hunt(number: int) -> void:
	_story_custom_progress["hunt_key"] = number
	_story_custom_progress["tracks_found"] = 0
	_chapter_one.set_flag("key_enemy_held", false)
	_c1_enter_phase("tracking_carrier_%d" % number)
	_spawn_c1_track_marker()

func _spawn_c1_track_marker() -> void:
	var key_number: int = int(_story_custom_progress.get("hunt_key", 1))
	var track_number: int = int(_story_custom_progress.get("tracks_found", 0))
	var marker_position: Vector2 = _story_objective_zone_position(key_number * 5 + track_number, 1150.0)
	_adventure_props.append({"kind":"c1_track_marker", "pos":marker_position, "hp":1.0, "max_hp":1.0})
	_story_previous_objective_pos = marker_position
	_c1_interaction = 0.0
	_story_custom_progress["track_examine"] = 0.0

func _spawn_c1_key_carrier(number: int) -> void:
	_story_keys_generated = maxi(_story_keys_generated, number)
	var tag: String = "fleeing_key_carrier" if number == 1 else ("protected_key_carrier" if number == 2 else "watchpath_captain")
	_spawn_story_objective_enemy("normal_fast" if number == 1 else "normal_tank", tag, (1.0 + number * 0.18) * _story_stage_strength(), _player_pos + Vector2(1150.0, -180.0 + number * 120.0))
	_chapter_one.set_flag("key_enemy_held")
	_c1_enter_phase(tag)
	if number == 2:
		_c1_spawn_pressure(4, "carrier_guard", _player_pos + Vector2(600.0, 60.0), 0.9)

func _update_c1_crestkeeper_gate(delta: float) -> void:
	if _chapter_one.phase in ["radial_barrage", "aimed_barrage", "rotating_barrage"]:
		_c1_phase_timer = maxf(0.0, _c1_phase_timer - delta)
		_story_hazard_shot_timer -= delta
		if _story_hazard_shot_timer <= 0.0:
			_story_hazard_shot_timer = 0.95 if _chapter_one.phase == "radial_barrage" else (0.72 if _chapter_one.phase == "aimed_barrage" else 1.15)
			_story_hazard_pattern += 1
			_fire_c1_arena_pattern(_chapter_one.phase)
		if _c1_phase_timer <= 0.0:
			_adventure_progress += 1
			_story_log("Timer progress milestone: barrage %d/3 complete" % _adventure_progress)
			if _adventure_progress == 1:
				_c1_enter_phase("aimed_barrage", 52.0)
			elif _adventure_progress == 2:
				_c1_enter_phase("rotating_barrage", 55.0)
			else:
				_chapter_one.set_flag("timer_complete")
				_boss_projs.clear()
				_c1_enter_phase("overheat_burst", 2.5)
				_story_log("Objective activation: emitter ruptured with bomb and gas")
	elif _chapter_one.phase == "overheat_burst":
		_c1_phase_timer = maxf(0.0, _c1_phase_timer - delta)
		if _c1_phase_timer <= 0.0:
			_chapter_one.set_flag("boss_spawned")
			_objective_boss_active = true
			_c1_enter_phase("crestkeeper_boss")
			_spawn_story_objective_enemy("blight_vine_tyrant", "crestkeeper", 1.55 * _story_stage_strength(), _story_hazard_arena_center + Vector2(0.0, -280.0))
			_story_log("Boss spawned: Crestkeeper")

func _fire_c1_arena_pattern(pattern: String) -> void:
	var count: int = 8 if pattern == "rotating_barrage" else 10
	var offset: float = _story_hazard_pattern * 0.18
	for projectile_index in count:
		var angle: float = offset + TAU * float(projectile_index) / float(count)
		# Every fourth lane remains empty and readable.
		if projectile_index % 4 == _story_hazard_pattern % 4:
			continue
		var perimeter_direction: Vector2 = Vector2.from_angle(angle)
		var travel_direction: Vector2 = -perimeter_direction
		if pattern == "rotating_barrage":
			travel_direction = travel_direction.rotated(0.24 if _story_hazard_pattern % 2 == 0 else -0.24)
		var projectile_speed: float = 230.0 if pattern == "rotating_barrage" else 280.0
		var projectile_damage: float = 5.0 if pattern == "rotating_barrage" else 6.0
		_boss_projs.append({"kind":"hazard_orb", "pos":_story_hazard_arena_center + perimeter_direction * 560.0, "vel":travel_direction * projectile_speed, "life":5.0, "dmg":projectile_damage, "phase_flicker":pattern == "rotating_barrage", "flicker_offset":float(projectile_index) * 0.11})
	if pattern == "aimed_barrage":
		var launch_direction: Vector2 = Vector2.from_angle(offset + PI)
		var launch_position: Vector2 = _story_hazard_arena_center + launch_direction * 560.0
		var aimed: Vector2 = launch_position.direction_to(_player_pos)
		for spread in [-0.22, 0.0, 0.22]:
			_boss_projs.append({"kind":"hazard_orb", "pos":launch_position, "vel":aimed.rotated(spread) * 330.0, "life":5.0, "dmg":7.0})

func _update_story_escort(delta: float) -> void:
	if _adventure_props.is_empty(): return
	var scout := _adventure_props[0]
	var scout_pos: Vector2 = scout.pos
	_adventure_timer = maxf(0.0, _adventure_timer - delta)
	if _adventure_timer <= 0.0 and _story_telemetry != null:
		_story_telemetry.log_once("escort_timer_expired", "Timer expired: story_escort")
	if _story_gate_remaining <= 0 and _story_route_index < _story_route_waypoints.size():
		var waypoint: Vector2 = _story_route_waypoints[_story_route_index]
		var move_direction: Vector2 = scout_pos.direction_to(waypoint)
		if scout_pos.distance_to(_player_pos) > 620.0:
			move_direction = scout_pos.direction_to(_player_pos)
		scout_pos += move_direction * 88.0 * delta
		if scout_pos.distance_to(waypoint) < 35.0:
			_story_route_index += 1
			if _story_route_index < _story_route_waypoints.size():
				_spawn_story_gate_ambush(5 + _story_route_index * 3)
	scout.pos = scout_pos
	_adventure_props[0] = scout
	if float(scout.hp) <= 0.0:
		_damage_player(_player_max_hp * 2.0, 0.1)
	elif _adventure_timer <= 0.0 and _story_route_index >= _story_route_waypoints.size() and _story_gate_remaining <= 0 and _enemies.is_empty():
		_start_story_objective_boss()
	elif _adventure_timer <= 0.0 and _story_route_index >= _story_route_waypoints.size() and _story_gate_remaining <= 0:
		_stop_story_background_spawns()

func _stop_story_background_spawns() -> void:
	_adventure_spawn_timer = 999.0
	_wave_spawn_q.clear()
	_wave_spawn_t = 999.0

func _begin_story_escort() -> void:
	_story_log_phase("story_escort_wait", "story_escort")
	_adventure_state = "story_escort"
	_adventure_timer = 90.0
	_adventure_spawn_timer = 0.4
	_enemies.clear()
	_story_stage_origin = _player_pos
	_story_gate_remaining = 0
	_story_route_index = 0
	_story_route_waypoints = [
		_story_stage_origin + Vector2(620.0, -240.0),
		_story_stage_origin + Vector2(980.0, 380.0),
		_story_stage_origin + Vector2(260.0, 760.0),
		_story_stage_origin + Vector2(-520.0, 360.0),
	]
	var scout_hp := 320.0
	_adventure_props = [{"kind":"scout", "pos":_player_pos + Vector2(-90, 20), "hp":scout_hp, "max_hp":scout_hp, "wander_dir":Vector2.RIGHT.rotated(randf_range(0.0, TAU)), "wander_t":2.0}]
	_story_log("Objective spawned: scout · Timer started: 90.00s")

func _begin_story_defense() -> void:
	_story_log_phase("story_defend_wait", "story_defend")
	_adventure_state = "story_defend"
	_adventure_timer = 120.0
	_adventure_spawn_timer = 0.6
	_enemies.clear()
	var shrine_hp := 850.0
	_adventure_props = [{"kind":"shrine", "pos":_player_pos + Vector2(240, 0), "hp":shrine_hp, "max_hp":shrine_hp}]
	_story_log("Objective spawned: shrine · Timer started: 120.00s")

func _update_defense_objective(delta: float, is_story: bool) -> void:
	_adventure_timer = maxf(0.0, _adventure_timer - delta)
	if is_story and _adventure_timer <= 0.0 and _story_telemetry != null:
		_story_telemetry.log_once("defence_timer_expired", "Timer expired: story_defend")
	var shrine := _adventure_props[0]
	if float(shrine.hp) <= 0.0:
		_damage_player(_player_max_hp * 2.0, 0.1)
	elif _adventure_timer <= 0.0 and is_story and _enemies.is_empty():
		_start_story_objective_boss()
	elif _adventure_timer <= 0.0:
		_stop_story_background_spawns()

func _update_story_nests(delta: float) -> void:
	var nest_index := _find_adventure_prop("nest")
	if nest_index < 0:
		return
	var nest := _adventure_props[nest_index]
	nest.shield_t = maxf(float(nest.get("shield_t", 0.0)) - delta, 0.0)
	_adventure_spawn_timer -= delta
	var nest_number := _story_nests_destroyed + 1
	var enemy_cap := 5 + nest_number * 5
	if _adventure_spawn_timer <= 0.0 and _enemies.size() < enemy_cap:
		_adventure_spawn_timer = maxf(0.32, 0.72 - float(nest_number) * 0.10)
		var enemy_kind := "normal" if nest_number == 1 else ("normal_fast" if nest_number == 2 and randf() < 0.55 else "normal_tank")
		_spawn_enemy_from(_make_enemy_data(enemy_kind, (0.75 + float(nest_number) * 0.42) * _story_stage_strength()))
		if not _enemies.is_empty():
			var spawned_enemy := _enemies[-1]
			spawned_enemy.pos = (nest.pos as Vector2) + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(70.0, 115.0)
			_enemies[-1] = spawned_enemy
	if float(nest.shield_t) <= 0.0 and (nest.pos as Vector2).distance_to(_player_pos) < STORY_NEST_EFFECTIVE_RADIUS:
		nest.hp = float(nest.hp) - (28.0 + float(_level) * 3.0) * delta
	_adventure_props[nest_index] = nest
	if float(nest.hp) <= 0.0:
		_adventure_props.remove_at(nest_index)
		_story_nests_destroyed += 1
		if _story_telemetry != null:
			_story_telemetry.objective_completed("enemy_nest", "required_completed=%d/3" % _story_nests_destroyed)
		_adventure_spawn_timer = 0.8
		if _story_nests_generated >= 3 and _story_nests_destroyed >= 3 and _find_adventure_prop("nest") < 0:
			_start_story_objective_boss()

func _spawn_story_nest() -> void:
	if _adventure_state != "story_nests" or _story_nests_generated >= 3 or _find_adventure_prop("nest") >= 0:
		return
	var nest_number := _story_nests_generated + 1
	var nest_hp := (160.0 + float(nest_number - 1) * 110.0) * _story_stage_strength()
	var nest_pos: Vector2 = _story_objective_zone_position(_story_nests_generated, 720.0)
	_adventure_props.append({"kind":"nest", "pos":nest_pos, "hp":nest_hp, "max_hp":nest_hp, "shield_t":STORY_NEST_SHIELD_SECONDS})
	_story_previous_objective_pos = nest_pos
	_story_nests_generated += 1
	if _story_telemetry != null:
		_story_telemetry.objective_spawned("enemy_nest", "required_generated=%d/3" % _story_nests_generated)
	_adventure_spawn_timer = 0.0

func _find_adventure_prop(kind: String) -> int:
	for i in _adventure_props.size():
		if String(_adventure_props[i].get("kind", "")) == kind:
			return i
	return -1

func _update_breakables(delta: float, kind: String) -> void:
	for i in range(_adventure_props.size() - 1, -1, -1):
		var prop := _adventure_props[i]
		if String(prop.kind) == kind and (prop.pos as Vector2).distance_to(_player_pos) < 150.0:
			prop.hp = float(prop.hp) - (28.0 + float(_level) * 3.0) * delta
			_adventure_props[i] = prop
			if float(prop.hp) <= 0.0:
				_adventure_props.remove_at(i)

func _update_story_keys(delta: float) -> void:
	_story_key_drop_elapsed += delta
	for i in range(_adventure_props.size() - 1, -1, -1):
		if String(_adventure_props[i].get("kind", "")) == "key" and (_adventure_props[i].pos as Vector2).distance_to(_player_pos) < 70.0:
			_adventure_props.remove_at(i)
			_adventure_progress += 1
			if _story_telemetry != null:
				_story_telemetry.objective_completed("key", "required_completed=%d/%d" % [_adventure_progress, _adventure_target])
	if _story_keys_generated >= _adventure_target and _adventure_progress >= _adventure_target and _find_adventure_prop("key") < 0:
		_start_story_objective_boss()

func _story_key_drop_chance() -> float:
	return minf(STORY_KEY_DROP_START + _story_key_drop_elapsed * STORY_KEY_DROP_GROWTH_PER_SECOND, STORY_KEY_DROP_MAX)

func _try_drop_story_key(pos: Vector2, is_boss: bool) -> void:
	if _adventure_state != "story_keys" or is_boss:
		return
	var keys_on_ground := 0
	for prop in _adventure_props:
		if String(prop.get("kind", "")) == "key":
			keys_on_ground += 1
	if keys_on_ground >= 1 or _story_keys_generated >= _adventure_target:
		return
	if randf() <= _story_key_drop_chance():
		_adventure_props.append({"kind":"key", "pos":pos, "hp":1.0, "max_hp":1.0})
		_story_keys_generated += 1
		if _story_telemetry != null:
			_story_telemetry.objective_spawned("key", "required_generated=%d/%d" % [_story_keys_generated, _adventure_target])
		_story_key_drop_elapsed = 0.0

func _update_story_hazards(delta: float) -> void:
	_adventure_timer -= delta
	_story_hazard_shot_timer -= delta
	if _story_hazard_shot_timer <= 0.0:
		var elapsed_ratio := clampf(1.0 - _adventure_timer / float(_adventure_target), 0.0, 1.0)
		_story_hazard_shot_timer = maxf(0.42, 0.82 - elapsed_ratio * 0.32)
		_story_hazard_pattern += 1
		var projectile_count := 8 + mini(floori(elapsed_ratio * 4.0), 4)
		var angle_offset := float(_story_hazard_pattern) * 0.23
		var projectile_speed := 250.0 + elapsed_ratio * 90.0
		var projectile_damage := 5.5 + float(story_stage.get("chapter", 1)) * 0.8 + float(story_stage.get("chapter_stage", 1)) * 0.45
		for projectile_index in projectile_count:
			var angle := angle_offset + float(projectile_index) / float(projectile_count) * TAU
			var direction := Vector2.from_angle(angle)
			_boss_projs.append({"kind":"hazard_orb", "pos":_story_hazard_arena_center + direction * 92.0, "vel":direction * projectile_speed, "life":5.0, "dmg":projectile_damage})
		if _story_hazard_pattern % 3 == 0:
			var aimed_direction := _story_hazard_arena_center.direction_to(_player_pos)
			for spread in [-0.22, 0.0, 0.22]:
				var aimed_projectile_direction := aimed_direction.rotated(float(spread))
				_boss_projs.append({"kind":"hazard_orb", "pos":_story_hazard_arena_center + aimed_projectile_direction * 92.0, "vel":aimed_projectile_direction * (projectile_speed + 45.0), "life":5.0, "dmg":projectile_damage})
	if _adventure_timer <= 0.0:
		if _story_telemetry != null:
			_story_telemetry.log_once("hazard_timer_expired", "Timer expired: story_hazards")
		_stop_story_background_spawns()
		if _enemies.is_empty(): _start_story_objective_boss()

func _start_story_objective_boss() -> void:
	if _objective_boss_active:
		return
	_objective_boss_active = true
	_story_primary_complete = true
	var objective: String = str(story_stage.get("objective", ""))
	if objective in ["escort", "defend"] and not _adventure_props.is_empty():
		_story_required_target_survived = float(_adventure_props[0].get("hp", 0.0)) > 0.0
	_story_log_phase(_adventure_state, "story_boss")
	_adventure_state = "story_boss"
	_adventure_props.clear()
	_enemies.clear()
	_boss_projs.clear()
	var bosses: Array[String] = ["blight_vine_tyrant", "teleporter_boss", "lava_boss", "prism_triarch", "shield_boss", "thunderforge_behemoth"]
	var chapter_index := clampi(int(story_stage.get("chapter", 1)) - 1, 0, bosses.size() - 1)
	var stage_in_chapter := maxi(int(story_stage.get("chapter_stage", 1)) - 1, 0)
	var boss_strength := (0.95 + float(chapter_index) * 0.18 + float(stage_in_chapter) * 0.08) * _story_stage_strength()
	_spawn_enemy_from(_make_enemy_data(bosses[chapter_index], boss_strength))
	_story_log("Boss spawned: %s" % bosses[chapter_index])

func _story_stage_strength() -> float:
	return float(story_stage.get("enemy_hp", 1.0)) if not story_stage.is_empty() else 1.0

func _update_coin_hunt(delta: float) -> void:
	_adventure_timer -= delta
	var safe_index := _find_adventure_prop("safe")
	if safe_index >= 0:
		var safe := _adventure_props[safe_index]
		if (safe.pos as Vector2).distance_to(_player_pos) < SAFE_INTERACTION_RADIUS:
			safe.hp = float(safe.hp) - (28.0 + float(_level) * 3.0) * delta
			_adventure_props[safe_index] = safe
			if float(safe.hp) <= 0.0:
				_adventure_props.remove_at(safe_index)
				_adventure_progress += 1
				_coin_carried += 12 + _wave * 5
				if _adventure_progress < _adventure_target:
					_spawn_coin_safe()
	if _adventure_timer <= 0.0 or _adventure_progress >= _adventure_target:
		if _adventure_progress >= _adventure_target:
			ProgressionStore.record_dungeon_depth_completed(account_username, dungeon_mode, _wave)
		_show_coin_extraction_choice()

func _update_forges(delta: float) -> void:
	var forge_index := _find_adventure_prop("forge")
	if forge_index >= 0:
		var forge := _adventure_props[forge_index]
		if not bool(forge.active) and (forge.pos as Vector2).distance_to(_player_pos) < FORGE_INTERACTION_RADIUS:
			forge.active = true
		if bool(forge.active):
			var speed := 1.45 if _forge_modifier == "overclock" else 1.0
			forge.charge = float(forge.charge) + delta * speed
			for enemy in _enemies:
				if (enemy.pos as Vector2).distance_to(forge.pos as Vector2) < 105.0:
					forge.hp = float(forge.hp) - float(enemy.dmg) * delta * 0.22
			if float(forge.hp) <= 0.0:
				_damage_player(_player_max_hp * 2.0, 0.1)
				return
			if float(forge.charge) >= float(forge.target_charge):
				_adventure_props.remove_at(forge_index)
				_adventure_progress += 1
				if _adventure_progress < _adventure_target:
					_spawn_forge()
			else:
				_adventure_props[forge_index] = forge
	if _adventure_progress >= _adventure_target:
		_objective_boss_active = true
		_adventure_state = "forge_guardian"
		_enemies.clear()
		var guardian := "thunderforge_behemoth" if _wave % 3 == 0 else ("shield_boss" if _wave % 2 == 0 else "lava_boss")
		_spawn_enemy_from(_make_enemy_data(guardian, 0.9 + float(_wave) * 0.16))

func _show_coin_extraction_choice() -> void:
	if _adventure_choice_layer != null:
		return
	_adventure_state = "coin_choice"
	_enemies.clear()
	_paused = true
	var layer := CanvasLayer.new(); layer.layer = 130; add_child(layer); _adventure_choice_layer = layer
	var view := get_viewport_rect().size
	var shade := ColorRect.new(); shade.color = Color(0.02, 0.03, 0.02, 0.86); shade.size = view; layer.add_child(shade)
	var panel := PanelContainer.new(); panel.position = Vector2(55, view.y * 0.23); panel.size = Vector2(view.x - 110, view.y * 0.54); panel.add_theme_stylebox_override("panel", _adventure_choice_panel_style()); layer.add_child(panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 18); panel.add_child(box)
	var title := Label.new(); title.text = "EXTRACT THE TREASURE?"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 46); box.add_child(title)
	var depth_complete := _adventure_progress >= _adventure_target
	var choice_text := "descend deeper for richer safes" if depth_complete else "replay Depth %d to finish cracking all five safes" % _wave
	var body := Label.new(); body.text = "Safes cracked: %d of %d\nCarrying %d Camp Coins\nExtract now and keep everything, or %s.\nIf defeated, only 40%% of carried treasure is recovered." % [_adventure_progress, _adventure_target, _coin_carried, choice_text]; body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; body.add_theme_font_size_override("font_size", 27); box.add_child(body)
	var extract := _pause_btn("Extract Safely", Color(0.18, 0.48, 0.25), Color.WHITE); extract.custom_minimum_size = Vector2(0, 82); box.add_child(extract)
	var next_depth := _wave + 1 if depth_complete else _wave
	var continue_text := "Risk It · Descend to Depth %d" % next_depth if depth_complete else "Replay Depth %d" % _wave
	var deeper := _pause_btn(continue_text, Color(0.52, 0.28, 0.08), Color.WHITE); deeper.custom_minimum_size = Vector2(0, 82); box.add_child(deeper)
	extract.pressed.connect(func() -> void:
		_coin_banked = _coin_carried
		var completed_depth := _wave if depth_complete else _wave - 1
		_progression_reward = ProgressionStore.record_dungeon_run(account_username, dungeon_mode, completed_depth, _coin_banked)
		_loss_recorded = true
		_close_adventure_choice()
		_show_dungeon_completion("TREASURE EXTRACTED!", "%d Camp Coins secured at Depth %d." % [_coin_banked, _wave])
	)
	deeper.pressed.connect(func() -> void:
		_close_adventure_choice()
		_begin_coin_depth(next_depth)
	)

func _show_forge_modifier_choice() -> void:
	if _adventure_choice_layer != null:
		return
	_adventure_state = "forge_choice"
	_paused = true
	var layer := CanvasLayer.new(); layer.layer = 130; add_child(layer); _adventure_choice_layer = layer
	var view := get_viewport_rect().size
	var shade := ColorRect.new(); shade.color = Color(0.03, 0.02, 0.04, 0.88); shade.size = view; layer.add_child(shade)
	var panel := PanelContainer.new(); panel.position = Vector2(55, view.y * 0.16); panel.size = Vector2(view.x - 110, view.y * 0.68); panel.add_theme_stylebox_override("panel", _adventure_choice_panel_style()); layer.add_child(panel)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 14); panel.add_child(box)
	var title := Label.new(); title.text = "FORGECORE STABILIZED"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 44); box.add_child(title)
	var body := Label.new(); body.text = "Choose one forge protocol for the next depth."; body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; body.add_theme_font_size_override("font_size", 26); box.add_child(body)
	var options := [
		{"id":"reinforced", "text":"Reinforced Casings\nForges gain 40% durability"},
		{"id":"overclock", "text":"Overclock\nForges process 45% faster"},
		{"id":"rich_vein", "text":"Rich Vein\nGain 50% more materials when the run ends"},
	]
	for option in options:
		var chosen: String = option.id
		var button := _pause_btn(String(option.text), Color(0.24, 0.22, 0.38), Color.WHITE); button.custom_minimum_size = Vector2(0, 88); box.add_child(button)
		button.pressed.connect(func() -> void:
			_forge_modifier = chosen
			_close_adventure_choice()
			_begin_forge_depth(_wave + 1)
		)
	var finish := _pause_btn("End Expedition · Claim Materials", Color(0.22, 0.42, 0.30), Color.WHITE); finish.custom_minimum_size = Vector2(0, 78); box.add_child(finish)
	finish.pressed.connect(func() -> void:
		_progression_reward = ProgressionStore.record_dungeon_run(account_username, dungeon_mode, _dungeon_depth_cleared)
		var materials := int(_progression_reward.get("materials", 0))
		if _forge_modifier == "rich_vein": materials = ceili(float(materials) * 1.5)
		_progression_reward["materials"] = materials
		StoryStore.add_materials(account_username, materials)
		_loss_recorded = true
		_close_adventure_choice()
		_show_dungeon_completion("FORGE EXPEDITION COMPLETE!", "%d upgrade materials recovered from Depth %d." % [materials, _dungeon_depth_cleared])
	)

func _close_adventure_choice() -> void:
	if _adventure_choice_layer != null:
		_adventure_choice_layer.queue_free()
		_adventure_choice_layer = null
	_paused = false

func _adventure_choice_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.06, 0.09, 0.98)
	style.border_color = Color(0.86, 0.66, 0.25, 0.92)
	style.set_border_width_all(3)
	style.set_corner_radius_all(28)
	style.set_content_margin_all(24.0)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	return style

func _show_dungeon_completion(title_text: String, body_text: String) -> void:
	_game_over = true
	_paused = true
	var layer := CanvasLayer.new(); layer.layer = 140; add_child(layer)
	var view := get_viewport_rect().size
	var shade := ColorRect.new(); shade.color = Color(0.02, 0.03, 0.04, 0.94); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; layer.add_child(shade)
	var title := Label.new(); title.text = title_text; title.position = Vector2(0, view.y * 0.24); title.size = Vector2(view.x, 90); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 58); title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32)); layer.add_child(title)
	var body := Label.new(); body.text = body_text; body.position = Vector2(60, view.y * 0.40); body.size = Vector2(view.x - 120, 180); body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; body.add_theme_font_size_override("font_size", 32); layer.add_child(body)
	var back := _pause_btn("Return to Camp", Color(0.20, 0.32, 0.48), Color.WHITE); back.position = Vector2((view.x - 430) * 0.5, view.y * 0.68); back.size = Vector2(430, 90); back.pressed.connect(func() -> void: match_ended.emit("dungeon")); layer.add_child(back)

# ─────────────────────────────────────────────────────────────────────────────
# WAVE SYSTEM
# ─────────────────────────────────────────────────────────────────────────────

func _update_spawner(delta: float) -> void:
	if (_boss_intermission.get("state", "none") as String) != "none":
		return
	if _boss_wave_locked and _wave_state != "spawning":
		return
	match _wave_state:
		"between":
			# Countdown before next wave starts
			_between_t -= delta
			if _between_t <= 0.0:
				_wave += 1
				_start_wave(_wave)
		"spawning":
			# Trickle out queued enemies
			if _wave_spawn_q.is_empty():
				_wave_state = "waiting"
				return
			_wave_spawn_t -= delta
			while _wave_spawn_t <= 0.0 and not _wave_spawn_q.is_empty():
				var e_data: Dictionary = _wave_spawn_q.pop_front()
				_spawn_enemy_from(e_data)
				var spawn_interval := 0.38
				if dungeon_mode == "coin_burrow": spawn_interval = 0.22
				elif dungeon_mode == "forgecore": spawn_interval = 0.30
				_wave_spawn_t += spawn_interval
		"waiting":
			# Next wave starts after 5 s max, or immediately when all enemies cleared
			_between_t -= delta
			if _enemies.is_empty() or _between_t <= 0.0:
				if not dungeon_mode.is_empty() and _enemies.is_empty():
					_dungeon_depth_cleared = maxi(_dungeon_depth_cleared, _wave)
				_wave_state = "between"
				_between_t  = BETWEEN_DELAY

func _start_wave(w: int) -> void:
	_wave_state    = "spawning"
	_wave_spawn_t  = 0.0
	_wave_spawn_q.clear()
	_between_t     = 5.0   # max seconds before next wave forces regardless
	var ws: float  = 1.0 + float(w - 1) * 0.18
	if not story_stage.is_empty():
		ws *= float(story_stage.get("enemy_hp", 1.0))
		if str(story_stage.get("objective", "escort")) == "nests":
			ws *= 0.84

	# After wave 10 pick one random enemy modifier per wave.
	if w >= 10:
		_pick_enemy_floor_mod()
	else:
		_active_enemy_mod = ""
		_active_enemy_mod_name = ""
		_active_enemy_mod_desc = ""

	# Each mode has its own guardian cadence instead of sharing Survival's wave-four boss.
	if _is_mode_boss_wave(w):
		var btype: String = _mode_boss_type(w)
		# Every 8th wave: full-strength boss; every 4th (not 8th): 65% strength
		var boss_ws: float = ws if (w % 8 == 0) else ws * 0.65
		if dungeon_mode == "coin_burrow": boss_ws = ws * 0.82
		elif dungeon_mode == "forgecore": boss_ws = ws * (0.78 + float(w) * 0.025)
		elif not story_stage.is_empty(): boss_ws = ws * 0.90
		_wave_spawn_q.append(_make_enemy_data(btype, boss_ws))
		_boss_wave_locked = true
	else:
		_boss_wave_locked = false
		var base_count: int = mini(40 + w * 8, MAX_ENEMIES)
		if dungeon_mode == "coin_burrow": base_count = mini(22 + w * 6, 100)
		elif dungeon_mode == "forgecore": base_count = mini(18 + w * 4, 90)
		elif not story_stage.is_empty():
			match str(story_stage.get("objective", "escort")):
				"escort": base_count = mini(22 + w * 5, 75)
				"defend": base_count = mini(34 + w * 10, 125)
				"nests": base_count = mini(48 + w * 12, 140)
				"keys": base_count = mini(20 + w * 4, 60)
				_: base_count = mini(32 + w * 7, 120)
		for _i in base_count:
			# Randomly pick one of 3 normal subtypes
			var roll: float = randf()
			if dungeon_mode == "coin_burrow" and roll < 0.60:
				_wave_spawn_q.append(_make_enemy_data("normal_fast", ws * 0.90))
			elif dungeon_mode == "forgecore" and roll < 0.65:
				_wave_spawn_q.append(_make_enemy_data("normal_tank", ws * 1.12))
			elif not story_stage.is_empty() and str(story_stage.get("objective", "escort")) == "escort" and roll < 0.55:
				_wave_spawn_q.append(_make_enemy_data("normal_fast", ws * 0.92))
			elif not story_stage.is_empty() and str(story_stage.get("objective", "escort")) == "nests" and roll < 0.75:
				_wave_spawn_q.append(_make_enemy_data("normal", ws))
			elif not story_stage.is_empty() and str(story_stage.get("objective", "escort")) == "hazards" and roll < 0.55:
				_wave_spawn_q.append(_make_enemy_data("normal_tank", ws * 1.08))
			elif roll < 0.30:
				_wave_spawn_q.append(_make_enemy_data("normal_tank", ws))
			elif roll < 0.60:
				_wave_spawn_q.append(_make_enemy_data("normal_fast", ws))
			else:
				_wave_spawn_q.append(_make_enemy_data("normal", ws))

func _story_victory_wave() -> int:
	match str(story_stage.get("objective", "escort")):
		"escort": return 3
		"defend": return 5
		"nests": return 4
		"keys": return 4
		_: return 6

func _is_mode_boss_wave(w: int) -> bool:
	if dungeon_mode == "coin_burrow": return w % 5 == 0
	if dungeon_mode == "forgecore": return w % 2 == 0
	if not story_stage.is_empty():
		# Story bosses are authored objective encounters, never generic wave bosses.
		return false
	return w % 4 == 0

func _mode_boss_type(w: int) -> String:
	if dungeon_mode == "coin_burrow": return "teleporter_boss" if floori(float(w) / 5.0) % 2 == 1 else "shooter_boss"
	if dungeon_mode == "forgecore": return "shield_boss" if floori(float(w) / 2.0) % 2 == 1 else "lava_boss"
	if not story_stage.is_empty():
		if int(story_stage.get("chapter_stage", 1)) == 4 and w == 2: return _next_boss_type()
		if int(story_stage.get("chapter_stage", 1)) == 5:
			return PORTAL_BOSS_TYPES[(int(story_stage.get("chapter", 1)) - 1) % PORTAL_BOSS_TYPES.size()] as String
		var configured := str(story_stage.get("boss", ""))
		return configured if not configured.is_empty() else _next_boss_type()
	return _next_boss_type()

func _mode_objective_text() -> String:
	if dungeon_mode == "coin_burrow": return "Crack safe %d of %d · %d coins carried · %ds remaining" % [_adventure_progress + 1, _adventure_target, _coin_carried, maxi(0, ceili(_adventure_timer))]
	if dungeon_mode == "forgecore": return "Activate and defend forge %d of %d" % [mini(_adventure_progress + 1, _adventure_target), _adventure_target]
	if not story_stage.is_empty():
		if int(story_stage.get("chapter", 1)) > 1: return _custom_story_objective_text()
		if _chapter_one != null: return _chapter_one_objective_text()
		match str(story_stage.get("objective", "escort")):
			"escort":
				if _adventure_state == "story_escort_wait": return "Prepare, then start the wandering scout escort"
				if _story_gate_remaining > 0: return "Escort checkpoint %d of %d · clear %d attackers" % [_story_route_index, _story_route_waypoints.size(), _story_gate_remaining]
				return "Protect Scout · checkpoint %d/%d · %ds" % [_story_route_index, _story_route_waypoints.size(), maxi(0, ceili(_adventure_timer))]
			"defend":
				if _adventure_state == "story_defend_wait": return "Prepare, then summon the shrine when ready"
				return "Defend the shrine · %ds remaining" % maxi(0, ceili(_adventure_timer))
			"nests":
				var nest_index := _find_adventure_prop("nest")
				if nest_index < 0: return "Prepare, then spawn nest %d of 3" % (_story_nests_destroyed + 1)
				var shield_left := float(_adventure_props[nest_index].get("shield_t", 0.0))
				return "Nest %d of 3 · %s" % [_story_nests_destroyed + 1, "Shielded %.1fs" % shield_left if shield_left > 0.0 else "Destroy it now"]
			"keys": return "Keys %d of %d · Enemy drop chance %.1f%%" % [_adventure_progress, _adventure_target, _story_key_drop_chance() * 100.0]
			_: return "Avoid the hazard barrage and defeat enemies · %ds remaining" % maxi(0, ceili(_adventure_timer))
	return ""

func _chapter_one_objective_text() -> String:
	match _chapter_one.stage_number:
		1:
			if not _chapter_one.flag("mission_started"): return "Escort the Scout · Follow, Wait, and Hurry commands"
			if _chapter_one.phase == "barricade": return "Open the barricade · Progress %d%%" % roundi(float(_story_custom_progress.get("channel", 0.0)) * 100.0)
			if _chapter_one.phase == "extraction": return "Protect the extraction · %ds" % ceili(_c1_phase_timer)
			return "Escort the Scout · Route %d/%d · Command %s" % [_story_route_index, _story_route_waypoints.size(), _c1_command.capitalize()]
		2:
			var shrine_index: int = _find_adventure_prop("shrine")
			var energy: int = roundi(float(_adventure_props[shrine_index].get("energy", 0.0))) if shrine_index >= 0 else 0
			if not _chapter_one.flag("mission_started"): return "Summon the Shrine when ready · Energy spores power it"
			if _chapter_one.phase == "cleansing_channel": return "Protect the cleansing pulse · %ds" % ceili(_c1_phase_timer)
			return "Shrine Energy %d%% · Each spore adds 2%%" % energy
		3:
			if not _chapter_one.flag("mission_started"): return "Track three different Supply Thief Nests"
			if _chapter_one.phase == "nest_3": return "Nest's Shields %d/3 · Nest Core %s" % [int(_story_custom_progress.get("feeding_sacs", 0)), "Vulnerable" if int(_story_custom_progress.get("feeding_sacs", 0)) >= 3 else "Protected"]
			return "Destroy %s · Nests %d/3" % [_chapter_one.phase.replace("_", " ").capitalize(), _story_nests_destroyed]
		4:
			if _chapter_one.phase == "gate_window": return "Gate Closing %ds · Reach the exit" % ceili(_c1_phase_timer)
			if _chapter_one.phase.begins_with("tracking_carrier_"):
				var examine_percent: int = roundi(float(_story_custom_progress.get("track_examine", 0.0)) * 100.0)
				return "Examine footprint %d%% · Tracks %d/4 · Keys %d/3" % [examine_percent, int(_story_custom_progress.get("tracks_found", 0)), _adventure_progress]
			return "Keys Recovered %d/3 · %s" % [_adventure_progress, _chapter_one.phase.replace("_", " ").capitalize()]
		5:
			if _chapter_one.phase == "crestkeeper_boss": return "Crestkeeper's Gate · Defeat the Crestkeeper"
			if _chapter_one.phase == "overheat_burst": return "Machine ruptured · Boss incoming · %ds" % ceili(_c1_phase_timer)
			if _chapter_one.phase == "rotating_barrage" and _c1_phase_timer <= 5.0: return "MACHINE OVERHEATING · %ds" % ceili(_c1_phase_timer)
			return "Crestkeeper's Gate · Barrage Phase %d/3 · %ds until next phase" % [mini(_adventure_progress + 1, 3), ceili(_c1_phase_timer)]
	return "Complete the Story objective"

func _custom_story_objective_text() -> String:
	if _chapter_two != null and int(story_stage.get("chapter", 0)) == 2:
		return _chapter_two_objective_text()
	if _chapter_three != null and int(story_stage.get("chapter", 0)) == 3:
		return _chapter_three_objective_text()
	if _chapter_four != null and int(story_stage.get("chapter", 0)) == 4:
		return _chapter_four_objective_text()
	if _chapter_five != null and int(story_stage.get("chapter", 0)) == 5:
		return _chapter_five_objective_text()
	if _story_final_triggered and not _story_final_completed:
		return "Final encounter · %d required enemies remaining" % _story_final_remaining
	if _story_gate_remaining > 0:
		return "Objective secured · clear the ambush: %d remaining" % _story_gate_remaining
	match _story_custom_id:
		"frozen_braziers": return "Rekindle brazier %d of %d · %.1fs" % [mini(_adventure_progress + 1, _adventure_target), _adventure_target, _story_custom_interaction]
		"ice_captives": return "Captives freed: %d of %d" % [_adventure_progress, _adventure_target]
		"thaw_runes": return "Memorize: %s" % _sequence_text(_story_custom_sequence) if _story_custom_timer > 0.0 else "Rune sequence hidden · entered %d of 4" % int(_story_custom_progress.get("entered", 0))
		"frost_mimic": return "Treasury encounters: %d of %d · resolve each chest" % [_adventure_progress, _adventure_target]
		"frost_colossus": return "Break armour crystals: %d of %d" % [_adventure_progress, _adventure_target] if _story_custom_phase == 0 else "Armour broken · defeat the Frostbound Colossus"
		"cleanse_mire": return "Pools purified: %d of %d · cleansing energy: %d/%d" % [_adventure_progress, _adventure_target, int(_story_custom_progress.get("energy", 0)), int(_story_custom_progress.get("energy_needed", 3))]
		"plaguebeast": return "Track the Plaguebeast · escapes: %d of 2" % int(_story_custom_progress.get("escapes", 0))
		"venom_harvest": return "Spider Venom %d/3 · Toad Bile %d/3 · Wasp Stinger %d/3" % [int(_story_custom_progress.get("spider", 0)), int(_story_custom_progress.get("toad", 0)), int(_story_custom_progress.get("wasp", 0))]
		"fragile_cure": return "Carry cure · checkpoint %d/3 · vial %d%%" % [int(_story_custom_progress.get("checkpoints", 0)), floori(float(_story_custom_progress.get("vial", 100.0)))]
		"grand_antidote": return "Recipe %s · submitted %d/3 · carrying %s" % [_sequence_text(_story_custom_sequence), int(_story_custom_progress.get("submitted", 0)), _ingredient_name(_story_custom_carried)]
		"silent_descent":
			var safe_points: int = int(_story_custom_progress.get("safe_points", 0))
			if bool(_story_custom_progress.get("hidden", false)):
				var hold_progress: float = float(_story_custom_progress.get("safe_point_hold", 0.0))
				if safe_points < 3 and bool(_story_custom_progress.get("inside_active_safe_point", false)):
					return "ACTIVATING SAFE POINT %d/3 · Stay inside %ds · Alert falling %d%%" % [safe_points + 1, ceili(10.0 - hold_progress), floori(_story_custom_alert)]
				return "SAFE POINT COVER · HIDDEN · Alert falling %d%%" % floori(_story_custom_alert)
			if bool(_story_custom_progress.get("detected", false)) and float(_story_custom_progress.get("detection_time", 0.0)) < 1.0:
				return "SENTRY NOTICING YOU · Leave the purple sight cone · Alert %d%%" % floori(_story_custom_alert)
			if safe_points < 3:
				return "Reach marked Safe Point %d/3 · Avoid sight cones · Alert %d%%" % [safe_points + 1, floori(_story_custom_alert)]
			return "All Safe Points reached · Enter the Inner Gate · Alert %d%%" % floori(_story_custom_alert)
		"soul_liberation": return "Souls collected: %d/6 · catch each released soul" % _adventure_progress
		"mirror_labyrinth": return "Labyrinth room %d/%d · Choose one of three mirrors · A wrong mirror triggers an ambush" % [_adventure_progress + 1, _adventure_target]
		"twin_eclipse": return "Activate both obelisks · window: %.1fs" % float(_story_custom_progress.get("window", 0.0))
		"abyss_king":
			if _story_custom_phase == 1: return "Phase 1 · destroy ritual anchors: %d/3 · corruption %ds" % [_adventure_progress, maxi(0, ceili(_story_custom_timer))]
			if _story_custom_phase == 2: return "Phase 2 · %s" % ("Crown vulnerable · strike now · safe inside strike area" if _is_abyss_crown_vulnerable() else "Crown reflecting · keep away")
			return "Phase 3 · defeat the fully vulnerable Abyss King"
	return str(_story_custom_data.get("desc", "Complete the objective"))

func _chapter_five_objective_text() -> String:
	match _chapter_five.stage_number:
		1:
			if _chapter_five.phase == "route_selection": return "Silent Descent · Choose an infiltration route"
			if _chapter_five.phase == "quiet_exit": return "Quiet unlock complete · Cross the final threshold · Alert %d%%" % roundi(_chapter_five.meter("alert"))
			if _chapter_five.phase == "moving_escape": return "Lockdown escape · Cross the final threshold · Alert %d%%" % roundi(_chapter_five.meter("alert"))
			return "Silent Descent · Checkpoints %d/3 · Alert %d%% · %s" % [_chapter_five.count("checkpoints_reached"), roundi(_chapter_five.meter("alert")), _c5_sentry_status()]
		2:
			if _chapter_five.phase == "portal_sealing": return "Seal the Abyss Portal · Stabilizers %d/3 · Portal Keeper %s" % [_chapter_five.count("seals_stable"), "defeated" if _chapter_five.flag("boss_defeated") else "active"]
			return "Soul Liberation · Saved %d/6 · Active %d · Abyss Pressure %d%%" % [_chapter_five.count("spirits_saved"), _count_adventure_props("released_soul"), roundi(_chapter_five.meter("abyss_pressure"))]
		3:
			if _chapter_five.phase == "guardian": return "Reach the Labyrinth Exit · Defeat the Mirror Guardian"
			return "Mirror Labyrinth · Room %d/4 · %s · Abyss Pressure %d%%" % [_chapter_five.count("rooms_completed") + 1, str(_chapter_five.mirror_room.get("clue", "Read the inscription")), roundi(_chapter_five.meter("abyss_pressure"))]
		4:
			if _chapter_five.phase == "sync_attempt": return "SYNC WINDOW %.1fs · Reach Obelisk B" % _chapter_five.timer("sync")
			if _chapter_five.phase == "sync_hold": return "%s · %.1fs · Stop the Eclipse Elite" % ["SYNC INTERRUPTED" if _chapter_five.flag("elite_disruption_active") else "Hold synchronization", _chapter_five.timer("hold")]
			if _chapter_five.flag("preparation_complete") and _chapter_five.flag("route_prepared"): return "Twin Eclipse ready · Return to Obelisk A and start synchronization"
			return "Twin Eclipse · Obelisk A: %s · Obelisk B: %s · Prepare route" % ["Stable" if _chapter_five.flag("obelisk_a_stabilized") else "Unstable", "Stable" if _chapter_five.flag("obelisk_b_stabilized") else "Unstable"]
		5:
			if _chapter_five.phase == "ritual_anchors": return "Throne of the Deep · Ritual Anchors %d/3 · Ritual %.0fs" % [_chapter_five.count("anchors_destroyed"), _chapter_five.timer("ritual")]
			if _chapter_five.phase == "abyss_crown": return "Break the Abyss Crown · Sections %d/4 · Activate both seals" % _chapter_five.count("crown_sections_broken")
			return "Abyss King · %s" % _chapter_five.phase.replace("_", " ").capitalize()
	return "Complete the Chapter 5 objective"

func _c5_sentry_status() -> String:
	if _chapter_five != null and _chapter_five.flag("hidden"):
		return "Hidden"
	var rank: Dictionary = {"unaware":0, "suspicious":1, "searching":2, "alerted":3}
	var status: String = "unaware"
	for prop in _adventure_props:
		if str(prop.get("kind", "")) == "sentry" and int(rank.get(str(prop.get("state", "unaware")), 0)) > int(rank.get(status, 0)):
			status = str(prop.get("state", "unaware"))
	return status.capitalize()

func _chapter_four_objective_text() -> String:
	var heat: int = roundi(_chapter_four.meter("heat"))
	match _chapter_four.stage_number:
		1:
			if _chapter_four.phase == "cart_extraction":
				return "%s · Forge heat %d%%" % ["Clear the marked cart obstruction" if _find_story_enemy("c4_cart_blocker") >= 0 else "Escort the loaded mining cart to extraction", heat]
			return "Mine and deliver Ember Ore %d/12 · Carrying %d/3 · Forge heat %d%%" % [_chapter_four.count("ore_delivered"), _chapter_four.count("ore_carried"), heat]
		2:
			if _chapter_four.phase == "powered_traversal": return "Follow the powered lava route · Junction %d/3 · Heat %d%%" % [_chapter_four.count("route_nodes"), heat]
			if _chapter_four.phase == "forge_stabilization":
				var jammed: bool = _find_story_enemy("c4_forge_jammer") >= 0
				return "%s · Stabilization %ds · Heat %d%%" % ["Defeat the Forge Jammer" if jammed else "Defend the powered circuit", ceili(_chapter_four.timer("stabilization")), heat]
			return "Toggle lava valves · Forge mechanisms powered %d/3 · Heat %d%%" % [_chapter_four.count("mechanisms_powered"), heat]
		3:
			if _chapter_four.flag("capture_channel_active"):
				return "CAPTURING GOLEM · Hold position · %d%%" % roundi(clampf(_c4_action_timer / 2.5, 0.0, 1.0) * 100.0)
			var mechanic: String = str(["Charge it into the wall", "Cool it at the vent", "Destroy its repair drones", "Activate both forge tethers"][_chapter_four.count("golems_captured")]) if _chapter_four.count("golems_captured") < 4 else "Capture complete"
			return "Rogue Golems %d/4 · Weaken without killing · %s" % [_chapter_four.count("golems_captured"), mechanic]
		4:
			if _chapter_four.phase == "relic_assembly": return "Assemble the Lost Relic at the central forge · Components 3/3"
			if _chapter_four.phase == "relic_guardian": return "Use your forged relic to defeat the Relic Guardian"
			return "Clear the forge chamber · Relic components %d/3" % _chapter_four.count("components_collected")
		5:
			var shutdown: int = _chapter_four.count("regulators_disabled")
			var clue: String = "complete"
			if shutdown < _chapter_four.sequence.size(): clue = str(_chapter_four.sequence[shutdown] + 1)
			return "Shutdown regulator %s · %d/4 · Heat %d%% · %s" % [clue, shutdown, heat, "Boss systems %d" % maxi(0, 4 - shutdown) if _chapter_four.flag("boss_spawned") else "Contain meltdown"]
	return "Complete the Emberforge objective"

func _chapter_three_objective_text() -> String:
	match _chapter_three.stage_number:
		1:
			if _chapter_three.phase == "reclamation_surge":
				if _chapter_three.timer("reclamation") <= 0.0:
					var unstable_pools: int = 0
					for pool in _adventure_props:
						if str(pool.get("kind", "")) == "corrupted_pool" and float(pool.get("stability", 100.0)) < 35.0:
							unstable_pools += 1
					return "Reclamation Overtime · stabilize %d weakening pool%s" % [unstable_pools, "" if unstable_pools == 1 else "s"]
				return "Reclamation Surge · %ds · stabilize weakening pools" % ceili(_chapter_three.timer("reclamation"))
			var instruction: String = "Collect the glowing energy, then stand beside Pool 1"
			if _chapter_three.phase == "moving_purification": instruction = "Follow the moving antidote marker around Pool 2"
			elif _chapter_three.phase == "multi_point_purification": instruction = "Carry energy to each marked corruption node"
			return "Pools: %d/3 · Energy: %d/%d · %s" % [_chapter_three.count("pools_purified"), _chapter_three.count("energy"), _chapter_three.count("energy_max"), instruction]
		2:
			if _chapter_three.phase == "final_hunt": return "Final Hunt · defeat the actual Plaguebeast"
			if _chapter_three.phase == "tracking_ambush": return "Wrong trail · defeat the ambush before tracking resumes"
			if _chapter_three.phase == "first_sighting": return "Force the Plaguebeast to retreat, then follow its trail"
			return "Choose 1 of %d trails · correct clues: %d/3" % [_chapter_three.count("tracking_trails"), _chapter_three.count("tracking_phases_complete")]
		3:
			if _chapter_three.phase == "ingredient_extraction": return "Carry the Ingredient Case to extraction"
			if _chapter_three.flag("ingredients_contaminated"): return "Ingredients contaminated · stand near the Cleansing Station for 2 seconds"
			if _chapter_three.phase == "region_select":
				var selection_region: int = _chapter_three.count("selection_region")
				if selection_region >= 0:
					return "Remain near %s for %ds to choose it" % [str(["Spider Grounds", "Toad Marsh", "Wasp Hive"][selection_region]), maxi(0, ceili(2.0 - _c3_action_timer))]
				return "Choose a hunting ground · stand near Spider, Toad, or Wasp for 2 seconds"
			if _chapter_three.phase == "region_hunt":
				var active_region: int = _chapter_three.count("active_region")
				var creature_name: String = str(["Spider", "Toad", "Wasp"][active_region])
				var target_kind: String = str(["c3_web_nest", "c3_bile_vessel", "c3_wasp_hive"][active_region])
				var marked_tag: String = str(["c3_marked_spider", "c3_marked_toad", "c3_marked_wasp"][active_region])
				if _find_adventure_prop(target_kind) >= 0:
					return "%s venom %d/3 · stand near the marked habitat for %ds to lure it" % [creature_name, _chapter_three.count(creature_name.to_lower()), maxi(0, ceili(_c3_region_lure_duration(active_region) - _c3_action_timer))]
				if _find_story_enemy(marked_tag) >= 0:
					return "%s venom %d/3 · defeat the marked %s" % [creature_name, _chapter_three.count(creature_name.to_lower()), creature_name]
			return "Venom Harvest · Spider %d/3 · Toad %d/3 · Wasp %d/3" % [_chapter_three.count("spider"), _chapter_three.count("toad"), _chapter_three.count("wasp")]
		4:
			var integrity: int = roundi(_chapter_three.meter("vial_integrity"))
			if _chapter_three.phase == "vial_collection": return "Collect the fragile Antidote Vial"
			if _chapter_three.phase == "route_select":
				var selection_route: int = _chapter_three.count("selection_route")
				if selection_route >= 0: return "Hold near the %s Route for %ds to select it" % ["Short" if selection_route == 0 else "Long", maxi(0, ceili(2.5 - _c3_action_timer))]
				return "Choose a route · remain near Short or Long for 3 seconds"
			if _chapter_three.phase == "vial_delivery":
				var hold_duration: float = 5.0 if _chapter_three.count("route") == 0 else 4.0
				return "Vial integrity %d%% · hold at checkpoint %d/%d for %ds" % [integrity, _chapter_three.count("route_checkpoints") + 1, _chapter_three.count("route_checkpoints_required"), maxi(0, ceili(hold_duration - _c3_action_timer))]
			if _chapter_three.phase == "route_ambush": return "Vial integrity %d%% · defeat the checkpoint guards" % integrity
			if _chapter_three.phase == "infected_altar": return "Vial integrity %d%% · hold near the altar for %ds to place it" % [integrity, maxi(0, ceili(4.0 - _c3_action_timer))]
			if _chapter_three.phase == "antidote_transfer": return "Antidote Transfer · %ds · remain near the altar and survive" % ceili(_chapter_three.timer("transfer"))
			return "Antidote Integrity: %d%% · Checkpoints: %d/%d" % [integrity, _chapter_three.count("route_checkpoints"), _chapter_three.count("route_checkpoints_required")]
		5:
			if _chapter_three.phase == "blight_tyrant": return "Grand Antidote brewed · defeat the Blight Vine Tyrant"
			if _chapter_three.phase == "ingredient_collection":
				if _story_custom_timer > 0.0 and not str(_story_custom_progress.get("brew_feedback", "")).is_empty():
					return str(_story_custom_progress.get("brew_feedback", ""))
				var submitted: int = _chapter_three.count("ingredients_submitted")
				var next_ingredient: String = _ingredient_name(str(_chapter_three.recipe[submitted])) if submitted < _chapter_three.recipe.size() else "Begin brewing"
				if not _story_custom_carried.is_empty():
					return "Carry %s to the cauldron · Next required: %s" % [_ingredient_name(_story_custom_carried), next_ingredient]
				return "Collect and deliver in order: %s · Next: %s" % [_ingredient_recipe_text(_chapter_three.recipe), next_ingredient]
			if _chapter_three.phase == "active_brewing":
				var heat: int = roundi(_chapter_three.meter("heat"))
				var purity: int = roundi(_chapter_three.meter("purity"))
				var brew: int = roundi(_chapter_three.meter("brew_progress"))
				if purity < 35: return "Purity %d%% too low · stand near the cauldron to restore purity" % purity
				if heat < 35: return "Heat %d%% too low · move away from the cauldron to raise it above 35%%" % heat
				if heat > 82: return "Heat %d%% too high · stand near the cauldron to cool it below 82%%" % heat
				return "Brewing %d%% · Heat %d%% is stable · stay near to cool, move away to heat" % [brew, heat]
			return "Grand Antidote · follow the marked objectives"
	return "Complete the Blightroot Marsh objective"

func _chapter_two_objective_text() -> String:
	var cold_status: String = "Freezing" if _chapter_two.cold_exposure >= 100.0 else ("Severely Chilled" if _chapter_two.cold_exposure >= 75.0 else ("Chilled" if _chapter_two.cold_exposure >= 50.0 else "Stable"))
	var cold_text: String = " · Cold Exposure: %d%% (%s)" % [roundi(_chapter_two.cold_exposure), cold_status]
	match _chapter_two.stage_number:
		1:
			if _chapter_two.phase == "warmth_stabilization":
				return "Stabilize the Warmth Chain · %ds · Active Warmth %d/4%s" % [ceili(_chapter_two.timer("stabilization")), _chapter_two.count("active_braziers"), cold_text]
			return "Braziers Lit: %d/4 · Active Warmth: %d/4 · Carrying %s%s" % [_chapter_two.count("braziers_lit"), _chapter_two.count("active_braziers"), "Flame Charge" if _story_custom_carried == "flame_charge" else "No Flame", cold_text]
		2:
			return "Captives Released: %d/5 · Captives Safe: %d/5 · Refrozen: %d%s" % [_chapter_two.count("captives_released"), _chapter_two.count("captives_extracted"), _chapter_two.count("captives_refrozen"), cold_text]
		3:
			if _chapter_two.phase == "sequence_reveal":
				return "Memorize: %s · %.1fs%s" % [_sequence_text(_story_custom_sequence), _story_custom_timer, cold_text]
			return "Thaw Sequence: %d/4 · %s%s" % [_chapter_two.count("runes_correct"), "Spreading freeze" if _chapter_two.phase == "spreading_freeze" else "Find the next rune", cold_text]
		4:
			if _chapter_two.phase == "frost_mimic_battle": return "Defeat the actual Frost Mimic"
			return "Open one chest · Wrong chests trigger an ambush · Chests Remaining: %d" % _chapter_two.count("suspects_remaining")
		5:
			if _chapter_two.phase == "final_vulnerable": return "Frostbound Colossus · Armour broken · Defeat it%s" % cold_text
			return "Frostbound Colossus · Armour Crystals: %d/3 · Attack the exposed crystal%s" % [3 - _chapter_two.count("crystals_broken"), cold_text]
	return "Complete the Frostbound Hollow objective"

func _sequence_text(sequence: Array[int]) -> String:
	var parts: Array[String] = []
	for value in sequence: parts.append(str(value + 1))
	return " → ".join(parts)

func _ingredient_recipe_text(sequence: Array[int]) -> String:
	var parts: Array[String] = []
	for value in sequence:
		parts.append(_ingredient_name(str(value)))
	return " → ".join(parts)

func _ingredient_name(value: String) -> String:
	if value.is_empty(): return "none"
	var names := ["Spider Venom", "Toad Bile", "Wasp Stinger", "Mirecap Mushroom"]
	var index := clampi(int(value), 0, names.size() - 1)
	return names[index]

func _bit_count(value: int) -> int:
	var count := 0
	for bit in 3:
		if (value & (1 << bit)) != 0: count += 1
	return count

func _enemy_mod_display_name(mod: String) -> String:
	match mod:
		"fast":         return "Haste"
		"giant":        return "Giant"
		"armored":      return "Armored"
		"explosive":    return "Explosive"
		"frozen_trail": return "Frozen Trail"
		"burn_trail":   return "Burn Trail"
		_:              return mod

func _enemy_mod_description(mod: String) -> String:
	match mod:
		"fast":
			return "Enemies move faster on this floor."
		"giant":
			return "Enemies are larger and tougher to take down."
		"armored":
			return "Enemies have heavy armor and more HP."
		"explosive":
			return "Enemies explode when they die."
		"frozen_trail":
			return "Enemies leave ice patches on death; running over one slows you for 1.5s."
		"burn_trail":
			return "Enemies spawn 2-3 embers on death; running over embers damages you."
		_:
			return ""

func _pick_enemy_floor_mod() -> void:
	if ENEMY_MOD_POOL.is_empty():
		_active_enemy_mod = ""
		_active_enemy_mod_name = ""
		_active_enemy_mod_desc = ""
		return
	var mod: String = ENEMY_MOD_POOL[randi() % ENEMY_MOD_POOL.size()] as String
	_active_enemy_mod = mod
	_active_enemy_mod_name = _enemy_mod_display_name(mod)
	_active_enemy_mod_desc = _enemy_mod_description(mod)

func _next_boss_type() -> String:
	if _boss_bag.is_empty():
		_boss_bag = WAVE_BOSS_TYPES.duplicate()
		_boss_bag.shuffle()
	return _boss_bag.pop_back() as String

func _next_portal_boss_type() -> String:
	if _portal_boss_bag.is_empty():
		_portal_boss_bag = PORTAL_BOSS_TYPES.duplicate()
		_portal_boss_bag.shuffle()
	return _portal_boss_bag.pop_back() as String

func _is_boss_kind(kind: String) -> bool:
	return kind.ends_with("_boss") or PORTAL_BOSS_TYPES.has(kind)

func _make_enemy_data(kind: String, ws: float) -> Dictionary:
	var boss_progress: Dictionary = _boss_progression_multiplier()
	var boss_hp_mult: float = float(boss_progress.get("hp", 1.0))
	var boss_dmg_mult: float = float(boss_progress.get("dmg", 1.0))
	var boss_spd_mult: float = float(boss_progress.get("spd", 1.0))
	match kind:
		"portal_keeper_boss":
			return {"kind":"portal_keeper_boss", "hp_mult":22.0 * ws * boss_hp_mult, "spd_fixed":92.0 * boss_spd_mult, "dmg_mult":1.45 * ws * boss_dmg_mult, "r":72.0, "col":Color(0.34, 0.18, 0.62)}
		"mirror_guardian_boss":
			return {"kind":"mirror_guardian_boss", "hp_mult":24.0 * ws * boss_hp_mult, "spd_fixed":128.0 * boss_spd_mult, "dmg_mult":1.40 * ws * boss_dmg_mult, "r":68.0, "col":Color(0.76, 0.32, 0.92)}
		"eclipse_elite_boss":
			return {"kind":"eclipse_elite_boss", "hp_mult":25.0 * ws * boss_hp_mult, "spd_fixed":106.0 * boss_spd_mult, "dmg_mult":1.55 * ws * boss_dmg_mult, "r":74.0, "col":Color(0.92, 0.54, 0.16)}
		"abyss_king_boss":
			return {"kind":"abyss_king_boss", "hp_mult":42.0 * ws * boss_hp_mult, "spd_fixed":96.0 * boss_spd_mult, "dmg_mult":1.85 * ws * boss_dmg_mult, "r":92.0, "col":Color(0.42, 0.12, 0.68)}
		"teleporter_boss":
			return {
				"kind": "teleporter_boss",
				"hp_mult": 14.0 * ws * boss_hp_mult, "spd_fixed": 130.0 * boss_spd_mult, "dmg_mult": 1.5 * ws * boss_dmg_mult,
				"r": 62.0, "col": Color(0.55, 0.10, 0.82)
			}
		"shield_boss":
			return {
				"kind": "shield_boss",
				"hp_mult": 30.0 * ws * boss_hp_mult, "spd_fixed": 75.0 * boss_spd_mult, "dmg_mult": 2.0 * ws * boss_dmg_mult,
				"r": 78.0, "col": Color(0.20, 0.55, 0.90)
			}
		"shooter_boss":
			return {
				"kind": "shooter_boss",
				"hp_mult": 20.0 * ws * boss_hp_mult, "spd_fixed": 60.0 * boss_spd_mult, "dmg_mult": 1.2 * ws * boss_dmg_mult,
				"r": 68.0, "col": Color(0.85, 0.55, 0.05)
			}
		"lava_boss":
			return {
				"kind": "lava_boss",
				"hp_mult": 35.0 * ws * boss_hp_mult, "spd_fixed": 50.0 * boss_spd_mult, "dmg_mult": 1.8 * ws * boss_dmg_mult,
				"r": 88.0, "col": Color(0.90, 0.25, 0.02)
			}
		"abyss_gate_warden":
			return {
				"kind": "abyss_gate_warden",
				"hp_mult": 38.0 * ws * boss_hp_mult, "spd_fixed": 77.0 * boss_spd_mult, "dmg_mult": 1.9 * ws * boss_dmg_mult,
				"r": 86.0, "col": Color(0.20, 0.85, 0.95)
			}
		"prism_triarch":
			return {
				"kind": "prism_triarch",
				"hp_mult": 38.0 * ws * boss_hp_mult, "spd_fixed": 154.0 * boss_spd_mult, "dmg_mult": 1.6 * ws * boss_dmg_mult,
				"r": 64.0, "col": Color(0.85, 0.20, 0.90)
			}
		"blight_vine_tyrant":
			return {
				"kind": "blight_vine_tyrant",
				"hp_mult": 38.0 * ws * boss_hp_mult, "spd_fixed": 98.0 * boss_spd_mult, "dmg_mult": 1.7 * ws * boss_dmg_mult,
				"r": 80.0, "col": Color(0.30, 0.85, 0.25)
			}
		"thunderforge_behemoth":
			return {
				"kind": "thunderforge_behemoth",
				"hp_mult": 38.0 * ws * boss_hp_mult, "spd_fixed": 63.0 * boss_spd_mult, "dmg_mult": 2.1 * ws * boss_dmg_mult,
				"r": 92.0, "col": Color(0.95, 0.75, 0.20)
			}
		# ── Normal subtypes ───────────────────────────────────────────────────
		"normal_tank":  # Slow, bulky, high damage
			return {
				"kind": "normal_tank",
				"hp_mult": ws * 2.8, "spd_mult": 0.52, "dmg_mult": ws * 1.6,
				"r": randf_range(38.0, 48.0),
				"col": Color.from_hsv(0.06, 0.85, 0.45 + randf() * 0.15)  # dark orange-brown
			}
		"normal_fast":  # Fast, fragile, low damage
			return {
				"kind": "normal_fast",
				"hp_mult": ws * 0.45, "spd_mult": 1.70, "dmg_mult": ws * 0.65,
				"r": randf_range(18.0, 26.0),
				"col": Color.from_hsv(0.55, 0.70, 0.80 + randf() * 0.20)  # bright cyan-blue
			}
		_:  # normal — balanced
			return {
				"kind": "normal",
				"hp_mult": ws, "spd_mult": 1.0, "dmg_mult": ws,
				"r": randf_range(28.0, 38.0),
				"col": Color.from_hsv(randf_range(0.0, 0.12), 0.8, 0.35 + randf() * 0.2)
			}

func _spawn_enemy_from(data: Dictionary) -> void:
	var view: Vector2 = get_viewport_rect().size
	var sr: float     = max(view.x, view.y) * 0.62 + 60.0
	var angle: float  = randf() * TAU
	var pos: Vector2  = _player_pos + Vector2(cos(angle), sin(angle)) * sr
	if data.has("spawn_pos") and data["spawn_pos"] is Vector2:
		pos = data["spawn_pos"] as Vector2
	var base_hp: float  = (18.0 + float(_level) * 5.0) * (data["hp_mult"] as float)
	base_hp *= 1.0 + _ring_bonus("enemy_hp_mul")
	base_hp *= float(_run_difficulty.get("enemy_hp", 1.0)) * float(_run_modifier.get("enemy_hp", 1.0))
	var base_spd: float
	if data.has("spd_fixed"):
		base_spd = data["spd_fixed"] as float
	else:
		var wave_bonus: float = float(_wave) * 2.5
		base_spd = (randf_range(72.0, 105.0) + wave_bonus) * (data["spd_mult"] as float)
	if not story_stage.is_empty():
		base_spd *= float(story_stage.get("enemy_speed", 1.0))
	var base_dmg: float = (4.5 + float(_level) * 1.0) * (data["dmg_mult"] as float)
	var base_r: float   = data["r"] as float
	var base_col: Color = data["col"] as Color

	# Apply the current floor affix to non-boss enemies.
	var assigned_mod: String = ""
	var ekind_spawn: String = data["kind"] as String
	if _wave >= 10 and not _active_enemy_mod.is_empty() and not _is_boss_kind(ekind_spawn):
		assigned_mod = _active_enemy_mod
		match assigned_mod:
			"fast":      base_spd *= 1.60
			"giant":     base_r *= 1.55;  base_hp *= 2.2;  base_dmg *= 1.3
			"armored":   base_hp *= 3.0;  base_col = base_col.lerp(Color(0.55, 0.55, 0.60), 0.55)
			"burn_trail": base_col = base_col.lerp(Color(1.0, 0.35, 0.05), 0.50)
			"frozen_trail": base_col = base_col.lerp(Color(0.45, 0.85, 1.0), 0.55)
			_: pass

	_enemies.append({
		"pos": pos, "hp": base_hp, "max_hp": base_hp,
		"spd": base_spd, "base_spd": base_spd, "r": base_r,
		"dmg": base_dmg, "col": base_col,
		"iframes": 0.0, "kind": ekind_spawn,
		"alive_t": 0.0, "speed_boosted": false, "facing_x": 1,
		"special_timer": 0.0, "shield_active": false,
		"mod": assigned_mod,
		"trail_t": 0.0,
	})

func _hit_enemy_element(idx: int, dmg: float, element: String) -> void:
	if idx < 0 or idx >= _enemies.size():
		return
	var enemy := _enemies[idx] as Dictionary
	var reaction := ""
	var reaction_color := Color.WHITE
	var multiplier := 1.0
	match element:
		"ice":
			if float(enemy.get("burn_t", 0.0)) > 0.0:
				reaction = "THERMAL SHOCK"
				reaction_color = Color(0.56, 0.92, 1.0)
				multiplier = 1.55
				enemy["burn_t"] = 0.0
			enemy["chilled_t"] = 3.0
		"fire":
			if float(enemy.get("chilled_t", 0.0)) > 0.0:
				reaction = "SHATTER"
				reaction_color = Color(0.72, 0.94, 1.0)
				multiplier = 1.50
				enemy["chilled_t"] = 0.0
			elif float(enemy.get("poison_t", 0.0)) > 0.0:
				reaction = "COMBUSTION"
				reaction_color = Color(0.72, 1.0, 0.20)
				multiplier = 1.40
				enemy["poison_t"] = 0.0
			enemy["burn_t"] = 3.0
		"lightning":
			if float(enemy.get("mud_t", 0.0)) > 0.0:
				reaction = "OVERCHARGE"
				reaction_color = Color(1.0, 0.92, 0.16)
				multiplier = 1.45
				enemy["mud_t"] = 0.0
	if not reaction.is_empty():
		_spawn_reaction_popup(enemy["pos"] as Vector2, reaction, reaction_color)
		_waves.append({"pos": enemy["pos"], "r": 8.0, "max_r": 70.0, "life": 0.28, "max_life": 0.28, "kind": element})
	_hit_enemy(idx, dmg * multiplier)

func _hit_enemy(idx: int, dmg: float) -> void:
	if idx < 0 or idx >= _enemies.size():
		return
	var e: Dictionary = _enemies[idx]
	var ekind: String = e.get("kind", "normal") as String
	# Shielded bosses absorb hits.
	if (e.get("shield_active", false) as bool):
		return
	# Apply crit from ring bonus
	var final_dmg: float = dmg
	if (e.get("bleed_t", 0.0) as float) > 0.0:
		final_dmg *= 1.0 + (e.get("bleed_bonus", 0.25) as float)
	if _is_boss_kind(ekind):
		final_dmg *= 1.0 + _ring_bonus("boss_dmg")
	if str(e.get("story_tag", "")) == "frost_colossus" and _chapter_two != null and _chapter_two.count("crystals_broken") < 3:
		final_dmg *= 0.04
	if str(e.get("story_tag", "")) == "protected_key_carrier":
		for guard in _enemies:
			if str(guard.get("story_tag", "")) == "carrier_guard":
				final_dmg *= 0.05
				break
	var crit_chance: float = _ring_bonus("crit_chance")
	var did_crit: bool = false
	if crit_chance > 0.0 and randf() < crit_chance:
		did_crit = true
		final_dmg *= 1.8 + _ring_bonus("crit_dmg")
	if _ring_bonus("lifesteal") > 0.0:
		_player_hp = min(_player_max_hp, _player_hp + final_dmg * _ring_bonus("lifesteal"))
	var impact_pos: Vector2 = e["pos"] as Vector2
	if _draw_world_rect.size == Vector2.ZERO or _is_world_pos_visible(impact_pos, 120.0):
		_spawn_damage_popup(impact_pos, final_dmg, did_crit)
		if _combat_vfx != null:
			_combat_vfx.emit_impact(impact_pos, did_crit, (e["hp"] as float) - final_dmg <= 0.0)
	e["hp"]      = (e["hp"] as float) - final_dmg
	e["iframes"] = ENEMY_HIT_IF
	var story_enemy_tag: String = str(e.get("story_tag", ""))
	if story_enemy_tag == "abyss_king" and _chapter_five != null and not _chapter_five.flag("final_phase_entered"):
		var ritual_floor: float = maxf(1.0, float(e.get("objective_max_hp", 100.0)) * 0.72)
		e["hp"] = maxf(float(e["hp"]), ritual_floor)
		if not _chapter_five.flag("ritual_shield_announced"):
			_chapter_five.set_flag("ritual_shield_announced")
			_spawn_reaction_popup(e["pos"] as Vector2, "RITUAL SHIELD", Color(0.78, 0.42, 1.0))
			_story_log("Boss phase gate: Ritual Shield Active")
	elif story_enemy_tag == "abyss_king" and _chapter_five != null:
		var phase_floor_ratio: float = {"final_boss_a":0.65, "final_boss_b":0.35, "final_boss_c":0.22}.get(_chapter_five.phase, 0.0) as float
		if phase_floor_ratio > 0.0:
			e["hp"] = maxf(float(e["hp"]), float(e.get("objective_max_hp", 100.0)) * phase_floor_ratio)
	if story_enemy_tag.begins_with("c4_golem_") and _chapter_four != null:
		var capture_floor: float = maxf(1.0, float(e.get("objective_max_hp", 100.0)) * 0.20)
		e["hp"] = maxf(float(e["hp"]), capture_floor)
	elif story_enemy_tag == "c4_thunderforge_behemoth" and _chapter_four != null and not _chapter_four.flag("shutdown_complete"):
		var shutdown_floor: float = maxf(1.0, float(e.get("objective_max_hp", 100.0)) * 0.25)
		e["hp"] = maxf(float(e["hp"]), shutdown_floor)
		if float(e["hp"]) <= shutdown_floor and not _chapter_four.flag("boss_protection_announced"):
			_chapter_four.set_flag("boss_protection_announced")
			_spawn_reaction_popup(e["pos"] as Vector2, "FORGE PROTECTED", Color(1.0, 0.56, 0.16))
			_story_log("Boss phase gate: Forge protection holds until shutdown completes")
	if str(e.get("story_tag", "")) == "frost_colossus" and _chapter_two != null and _chapter_two.count("crystals_broken") < 3 and float(e.hp) <= 0.0:
		e["hp"] = 1.0
	if (e["hp"] as float) <= 0.0:
		var ep: Vector2   = e["pos"] as Vector2
		_append_xp_orb(ep, _xp_drop(e))
		_kills += 1
		if _handle_custom_story_enemy_death(e):
			return
		var is_boss: bool = _is_boss_kind(ekind)
		_try_drop_story_key(ep, is_boss)
		# Potion drop: 25% base + ring bonus, from any boss
		var potion_rate: float = 0.25 + _ring_bonus("potion_drop_rate")
		if is_boss and randf() < potion_rate:
			_potions.append({"pos": ep + Vector2(randf_range(-20, 20), randf_range(-20, 20)), "life": 15.0})
		if is_boss:
			if not story_stage.is_empty():
				_story_log("Boss defeated: %s" % ekind)
			if not account_username.is_empty() and not is_story_test_run: ProgressionStore.record_mission_event(account_username, "boss_kills")
			if not dungeon_mode.is_empty() and _adventure_state not in ["coin_hunt", "forge_activate"]:
				_dungeon_depth_cleared = maxi(_dungeon_depth_cleared, _wave)
			_boss_keys += 1
			_try_drop_dungeon_key(ep, ekind)
			if _objective_boss_active and not story_stage.is_empty():
				_objective_boss_active = false
				_story_required_boss_defeated = true
				_enemies.remove_at(idx)
				_request_story_victory("objective_boss_defeated")
				return
			if _objective_boss_active and dungeon_mode == "forgecore":
				_objective_boss_active = false
				_dungeon_depth_cleared = maxi(_dungeon_depth_cleared, _wave)
				ProgressionStore.record_dungeon_depth_completed(account_username, dungeon_mode, _wave)
				_enemies.remove_at(idx)
				call_deferred("_show_forge_modifier_choice")
				return
			if not story_stage.is_empty() and int(story_stage.get("chapter", 1)) == 1 and int(story_stage.get("chapter_stage", 1)) == 5 and _wave >= _story_victory_wave():
				_request_story_victory("chapter_one_wave_boss_defeated")
		# Ring drop: 60% base chance from any boss (+ ring bonus, clamped).
		var ring_rate: float = min(1.0, 0.60 + _ring_bonus("ring_drop_rate"))
		if is_boss and not is_story_test_run and randf() < ring_rate:
			var ring: Dictionary = RingStore.roll_ring()
			_ring_drops.append({"pos": ep + Vector2(randf_range(-30, 30), randf_range(-30, 30)), "life": 20.0, "ring": ring})
		var bleed_seed: bool = e.get("bleed_seed", false) as bool
		var bleed_chain: bool = e.get("bleed_chain", false) as bool
		if bleed_seed and not bleed_chain:
			_spread_bleed_explosion(ep, e.get("bleed_bonus", 0.25) as float, e.get("bleed_t", 5.0) as float, e.get("bleed_explode_r", 190.0) as float)
		_enemies.remove_at(idx)
		if (_boss_intermission.get("state", "none") as String) == "arena" and is_boss and _enemies.is_empty():
			_on_arena_boss_cleared()
		elif is_boss and (_boss_intermission.get("state", "none") as String) == "none":
			_enemies.clear()
			_boss_intermission = {
				"state": "await_ladder" if not story_stage.is_empty() or not dungeon_mode.is_empty() else "await_choice",
				"door_pos": _player_pos + Vector2(250.0, 20.0),
				"ladder_pos": _player_pos + Vector2(-250.0, 20.0),
				"arena_center": _player_pos,
				"arena_half": BOSS_ARENA_HALF,
				"last_boss_wave": _wave,
			}
			_wave_state = "waiting"
			_between_t = 9999.0
		# Explosive on death
		if e.get("mod", "") == "explosive":
			var exp_r: float = 80.0 + (e["r"] as float)
			if _player_pos.distance_to(ep) < exp_r and _player_iframes <= 0.0:
				_damage_player((e["dmg"] as float) * 0.6, 0.40)
			_waves.append({"pos": ep, "r": 10.0, "max_r": exp_r, "life": 0.5, "max_life": 0.5, "kind": "wave"})
		# Emit a final burst of trail on death for trail types
		var death_mod: String = e.get("mod", "") as String
		if death_mod == "frozen_trail":
			_append_frozen_trail(ep)
		elif death_mod == "burn_trail":
			var ember_count: int = randi_range(2, 3)
			for _bi in ember_count:
				var off: Vector2 = Vector2(randf_range(-28, 28), randf_range(-28, 28))
				_append_burn_trail(ep + off, 2.2 + float(_wave) * 0.08)

func _spawn_damage_popup(world_pos: Vector2, damage: float, critical: bool) -> void:
	if damage <= 0.0 or is_nan(damage) or is_inf(damage):
		return
	if _damage_popups.size() >= DAMAGE_POPUP_MAX:
		_damage_popups.remove_at(0)
	_damage_popups.append({
		"pos": world_pos + Vector2(randf_range(-14.0, 14.0), randf_range(-10.0, -2.0)),
		"vel": Vector2(randf_range(-24.0, 24.0), randf_range(-128.0, -96.0)),
		"life": DAMAGE_POPUP_LIFE,
		"max_life": DAMAGE_POPUP_LIFE,
		"text": str(int(round(damage))),
		"size": 36 if critical else 30,
		"color": Color(1.0, 0.86, 0.38, 1.0) if critical else Color(0.96, 0.96, 0.96, 1.0),
	})

func _spawn_reaction_popup(world_pos: Vector2, label: String, color: Color) -> void:
	if _damage_popups.size() >= DAMAGE_POPUP_MAX:
		_damage_popups.remove_at(0)
	_damage_popups.append({
		"pos": world_pos + Vector2(0.0, -28.0),
		"vel": Vector2(0.0, -82.0),
		"life": 0.90,
		"max_life": 0.90,
		"text": label,
		"size": 24,
		"color": color,
	})

func _update_damage_popups(delta: float) -> void:
	for i in range(_damage_popups.size() - 1, -1, -1):
		var p: Dictionary = _damage_popups[i]
		p["life"] = (p["life"] as float) - delta
		if (p["life"] as float) <= 0.0:
			_damage_popups.remove_at(i)
			continue
		var vel: Vector2 = p["vel"] as Vector2
		vel.y += 220.0 * delta
		p["vel"] = vel
		p["pos"] = (p["pos"] as Vector2) + vel * delta
		_damage_popups[i] = p

func _draw_damage_popups() -> void:
	if _damage_popups.is_empty():
		return
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	var default_font_size: int = maxi(ThemeDB.fallback_font_size, 16)
	for p in _damage_popups:
		var life: float = float(p.get("life", 0.0))
		var max_life: float = max(float(p.get("max_life", DAMAGE_POPUP_LIFE)), 0.001)
		var alpha: float = clampf(life / max_life, 0.0, 1.0)
		var fade: float = alpha * alpha
		var size: int = int(round(max(float(p.get("size", default_font_size)) * (1.0 + (1.0 - alpha) * 0.08), 10.0)))
		var text: String = String(p.get("text", ""))
		if text.is_empty():
			continue
		var color: Color = p.get("color", Color.WHITE) as Color
		color.a = fade
		var shadow: Color = Color(0.0, 0.0, 0.0, min(0.92, fade + 0.25))
		var pos: Vector2 = p.get("pos", Vector2.ZERO) as Vector2
		var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
		var draw_pos: Vector2 = pos - Vector2(text_size.x * 0.5, 0.0)
		draw_string(font, draw_pos + Vector2(2.0, 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, shadow)
		draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _bleed_bonus_from_level(level: int) -> float:
	var max_lvl: int = int(SKILL_DEFS["bleed_mark"]["max_lvl"])
	if max_lvl <= 1:
		return 0.50
	var t: float = clamp(float(level - 1) / float(max_lvl - 1), 0.0, 1.0)
	return lerp(0.25, 0.50, t)

func _spread_bleed_explosion(center: Vector2, bonus: float, mark_t: float, radius: float) -> void:
	_waves.append({"pos": center, "r": 0.0, "max_r": radius, "life": 0.45, "max_life": 0.45, "kind": "bleed_burst"})
	for i in range(_enemies.size() - 1, -1, -1):
		if (_enemies[i]["pos"] as Vector2).distance_to(center) <= radius + (_enemies[i]["r"] as float):
			_enemies[i]["bleed_t"] = max((_enemies[i].get("bleed_t", 0.0) as float), mark_t)
			_enemies[i]["bleed_bonus"] = max((_enemies[i].get("bleed_bonus", 0.0) as float), bonus)
			_enemies[i]["bleed_seed"] = false
			_enemies[i]["bleed_chain"] = true

# ─── Enemy trail updates ────────────────────────────────────────────────────

func _update_enemy_trails(delta: float) -> void:
	# Tick frozen trails (slow player if overlapping)
	for i in range(_frozen_trails.size() - 1, -1, -1):
		var ft: Dictionary = _frozen_trails[i]
		ft["life"] = (ft["life"] as float) - delta
		if (ft["life"] as float) <= 0.0:
			_frozen_trails.remove_at(i)
			continue
		if _player_pos.distance_to(ft["pos"] as Vector2) < 34.0:
			_ice_patch_slow_t = max(_ice_patch_slow_t, ICE_PATCH_SLOW_DURATION)
	# Tick burn trails (damage player if overlapping)
	for i in range(_burn_trails.size() - 1, -1, -1):
		var bt: Dictionary = _burn_trails[i]
		bt["life"]  = (bt["life"] as float) - delta
		bt["tick_t"] = (bt["tick_t"] as float) + delta
		if (bt["life"] as float) <= 0.0:
			_burn_trails.remove_at(i)
			continue
		if (bt["tick_t"] as float) >= 0.40:
			bt["tick_t"] = 0.0
			if _player_pos.distance_to(bt["pos"] as Vector2) < 32.0 and _player_iframes <= 0.0:
				_damage_player(bt["dmg_per_tick"] as float, 0.18)

func _append_frozen_trail(pos: Vector2) -> void:
	_frozen_trails.append({"pos": pos, "life": TRAIL_FROZEN_LIFE, "max_life": TRAIL_FROZEN_LIFE})
	if _frozen_trails.size() > TRAIL_FROZEN_MAX:
		_frozen_trails.remove_at(0)

func _append_burn_trail(pos: Vector2, dmg_per_tick: float) -> void:
	_burn_trails.append({
		"pos": pos,
		"life": TRAIL_BURN_LIFE,
		"max_life": TRAIL_BURN_LIFE,
		"dmg_per_tick": dmg_per_tick,
		"tick_t": 0.0,
	})
	if _burn_trails.size() > TRAIL_BURN_MAX:
		_burn_trails.remove_at(0)

func _update_potions(delta: float) -> void:
	for i in range(_potions.size() - 1, -1, -1):
		var p: Dictionary = _potions[i]
		p["life"] = (p["life"] as float) - delta
		if (p["life"] as float) <= 0.0:
			_potions.remove_at(i)
			continue
		if (_player_pos.distance_to(p["pos"] as Vector2)) < 28.0:
			# Heal 25% of max HP
			var potion_heal: float = _player_max_hp * 0.25 * _room_potion_heal_multiplier()
			potion_heal *= 1.0 + _ring_bonus("healing_efficiency")
			_player_hp = min(_player_hp + potion_heal, _player_max_hp)
			_potions.remove_at(i)

func _update_ring_drops(delta: float) -> void:
	for i in range(_ring_drops.size() - 1, -1, -1):
		var rd: Dictionary = _ring_drops[i]
		rd["life"] = (rd["life"] as float) - delta
		if (rd["life"] as float) <= 0.0:
			_ring_drops.remove_at(i)
			continue
		if (_player_pos.distance_to(rd["pos"] as Vector2)) < 32.0:
			var ring: Dictionary = RingStore.normalize_ring(rd["ring"] as Dictionary)
			if not is_story_test_run:
				RingStore.add_ring_to_stash(account_username, ring)
				_rings_obtained.append(ring)
			_ring_drops.remove_at(i)

func _update_artifact_drops(delta: float) -> void:
	for i in range(_artifact_drops.size() - 1, -1, -1):
		var ad: Dictionary = _artifact_drops[i]
		ad["life"] = (ad["life"] as float) - delta
		ad["pickup_delay"] = max(float(ad.get("pickup_delay", 0.0)) - delta, 0.0)
		if (ad["life"] as float) <= 0.0:
			_artifact_drops.remove_at(i)
			continue
		if float(ad.get("pickup_delay", 0.0)) > 0.0:
			continue
		if (_player_pos.distance_to(ad["pos"] as Vector2)) < 32.0:
			var artifact: Dictionary = ad["artifact"] as Dictionary
			if not is_story_test_run:
				ArtifactStore.ensure_artifact_in_stash(account_username, artifact)
			_artifact_drops.remove_at(i)

func _update_boss_projs(delta: float) -> void:
	var vp: Rect2 = get_viewport_rect()
	for i in range(_boss_projs.size() - 1, -1, -1):
		var bp: Dictionary = _boss_projs[i]
		var proj_kind: String = bp.get("kind", "straight") as String
		if proj_kind == "homing":
			var to_player: Vector2 = _player_pos - (bp["pos"] as Vector2)
			if to_player.length_squared() > 1.0:
				var speed: float = bp.get("speed", 245.0) as float
				var desired_vel: Vector2 = to_player.normalized() * speed
				var turn: float = min((bp.get("turn_rate", SHOOTER_HOMING_TURN_RATE) as float) * delta, 0.08)
				bp["vel"] = (bp["vel"] as Vector2).lerp(desired_vel, turn)
		bp["pos"]  = (bp["pos"] as Vector2) + (bp["vel"] as Vector2) * delta
		bp["life"] = (bp["life"] as float) - delta
		var bpp: Vector2 = bp["pos"] as Vector2
		if proj_kind == "lava_reflect":
			var target: Vector2 = bp["target"] as Vector2
			if (bp["life"] as float) <= 0.0 or bpp.distance_to(target) <= 26.0:
				_explode_lava_fireball(target, bp["dmg"] as float, bp.get("explode_r", 58.0) as float)
				_boss_projs.remove_at(i)
				continue
		var sp: Vector2  = bpp - _camera.position + vp.size * 0.5
		if (bp["life"] as float) <= 0.0 or not vp.grow(40.0).has_point(sp):
			_boss_projs.remove_at(i)
			continue
		# Damage player if they touch it
		var can_hit: bool = not bool(bp.get("phase_flicker", false)) or _c1_projectile_flicker_alpha(bp) >= 0.45
		if can_hit and _player_iframes <= 0.0 and bpp.distance_to(_player_pos) < PLAYER_R + 12.0:
			if _damage_player(bp["dmg"] as float, IFRAMES_SEC):
				return
			_boss_projs.remove_at(i)

func _c1_projectile_flicker_alpha(projectile: Dictionary) -> float:
	var cycle: float = fmod(_elapsed / 2.4 + float(projectile.get("flicker_offset", 0.0)), 1.0)
	if cycle < 0.60:
		return 0.04
	if cycle < 0.72:
		return lerpf(0.04, 1.0, (cycle - 0.60) / 0.12)
	if cycle < 0.90:
		return 1.0
	return lerpf(1.0, 0.04, (cycle - 0.90) / 0.10)

func _explode_lava_fireball(pos: Vector2, dmg: float, radius: float) -> void:
	if _player_iframes <= 0.0 and _player_pos.distance_to(pos) < PLAYER_R + radius:
		_damage_player(dmg, 0.55)
	_lava_pools.append({
		"kind": "lava_reflect",
		"pos": pos,
		"r": radius * 0.72,
		"life": 1.8,
		"max_life": 1.8,
		"dmg_per_tick": dmg * 0.38,
		"tick_t": 0.0,
	})

func _update_mortar_strikes(delta: float) -> void:
	for i in range(_mortar_strikes.size() - 1, -1, -1):
		var strike: Dictionary = _mortar_strikes[i]
		strike["life"] = (strike["life"] as float) - delta
		if (strike["life"] as float) > 0.0:
			continue
		var impact_pos: Vector2 = strike["pos"] as Vector2
		var radius: float = strike["r"] as float
		if _player_iframes <= 0.0 and _player_pos.distance_to(impact_pos) < PLAYER_R + radius:
			if _damage_player(strike["dmg"] as float, 0.45):
				return
		_lava_pools.append({
			"kind": "shooter_mortar",
			"pos": impact_pos,
			"r": radius,
			"life": SHOOTER_MORTAR_POOL_LIFE,
			"max_life": SHOOTER_MORTAR_POOL_LIFE,
			"dmg_per_tick": (strike["dmg"] as float) * 0.55,
			"tick_t": 0.0,
		})
		_mortar_strikes.remove_at(i)

func _update_lava_lines(delta: float) -> void:
	for i in range(_lava_lines.size() - 1, -1, -1):
		var line: Dictionary = _lava_lines[i]
		line["life"] = (line["life"] as float) - delta
		line["warn_life"] = max((line["warn_life"] as float) - delta, 0.0)
		if (line["life"] as float) <= 0.0:
			_lava_lines.remove_at(i)
			continue
		if (line["warn_life"] as float) > 0.0:
			continue
		line["tick_t"] = (line["tick_t"] as float) + delta
		if (line["tick_t"] as float) < 0.25:
			continue
		line["tick_t"] = 0.0
		var start_pos: Vector2 = line["start"] as Vector2
		var end_pos: Vector2 = start_pos + (line["dir"] as Vector2) * (line["len"] as float)
		var width: float = line["width"] as float
		if _player_iframes <= 0.0 and _point_to_segment_distance(_player_pos, start_pos, end_pos) < PLAYER_R + width:
			if _damage_player(line["dmg"] as float, 0.45):
				return

func _point_to_segment_distance(point: Vector2, start_pos: Vector2, end_pos: Vector2) -> float:
	var seg: Vector2 = end_pos - start_pos
	var seg_len_sq: float = seg.length_squared()
	if seg_len_sq <= 0.001:
		return point.distance_to(start_pos)
	var t: float = clamp((point - start_pos).dot(seg) / seg_len_sq, 0.0, 1.0)
	return point.distance_to(start_pos + seg * t)

func _update_lava_pools(delta: float) -> void:
	for i in range(_lava_pools.size() - 1, -1, -1):
		var lp: Dictionary = _lava_pools[i]
		lp["life"]   = (lp["life"] as float) - delta
		if (lp["life"] as float) <= 0.0:
			_lava_pools.remove_at(i)
			continue
		lp["tick_t"] = (lp["tick_t"] as float) + delta
		if (lp["tick_t"] as float) >= 0.6:
			lp["tick_t"] = 0.0
			# Damage player if standing in lava
			if _player_iframes <= 0.0 and _player_pos.distance_to(lp["pos"] as Vector2) < PLAYER_R + (lp["r"] as float):
				if _damage_player(lp["dmg_per_tick"] as float, 0.4):
					return

func _xp_drop(enemy: Dictionary) -> int:
	var out: float = 9.0 + float(_wave) * 1.35
	out *= 1.0 + _ring_bonus("luck")
	var kind: String = str(enemy.get("kind", "normal"))
	var enemy_mult: float = 1.0
	if _is_boss_kind(kind):
		enemy_mult = XP_BOSS_ENEMY_MULT
	elif kind == "normal_tank":
		enemy_mult = XP_TANK_ENEMY_MULT
	elif kind == "normal_fast":
		enemy_mult = XP_FAST_ENEMY_MULT
	elif kind != "normal":
		enemy_mult = XP_SPECIAL_ENEMY_MULT
	if not str(enemy.get("mod", "")).is_empty():
		enemy_mult *= XP_AFFIX_ENEMY_MULT
	out *= enemy_mult
	return int(out)

func _gain_xp(amount: int) -> void:
	var xp_mult: float = 1.0 + _ring_bonus("xp_bonus")
	_xp += int(float(amount) * xp_mult)
	if _xp >= _xp_next:
		_xp -= _xp_next
		_level   += 1
		_apply_level_up_hp_growth()
		_xp_next  = int(40.0 * pow(float(_level), 1.40))
		_show_skill_select(false)

func _append_xp_orb(pos: Vector2, value: int) -> void:
	if _xp_orbs.size() < XP_ORB_MAX:
		_xp_orbs.append({"pos": pos, "val": value})
		return
	var merged_orb: Dictionary = _xp_orbs[-1]
	merged_orb["val"] = int(merged_orb.get("val", 0)) + value
	_xp_orbs[-1] = merged_orb

func _is_world_pos_visible(pos: Vector2, margin: float = 96.0) -> bool:
	return (
		pos.x >= _draw_world_rect.position.x - margin
		and pos.x <= _draw_world_rect.end.x + margin
		and pos.y >= _draw_world_rect.position.y - margin
		and pos.y <= _draw_world_rect.end.y + margin
	)

func _apply_level_up_hp_growth() -> void:
	var hp_gain: float = max(_player_base_max_hp * LEVEL_UP_HP_GAIN_PCT, LEVEL_UP_HP_GAIN_FLAT)
	_player_base_max_hp += hp_gain
	_player_max_hp += hp_gain
	_player_hp = min(_player_max_hp, _player_hp + hp_gain * LEVEL_UP_HEAL_GAIN_MULT)

# ═════════════════════════════════════════════════════════════════════════════
# DRAWING
# ═════════════════════════════════════════════════════════════════════════════

func _draw_adventure_objectives() -> void:
	var font := ThemeDB.fallback_font
	if _is_story_hazard_arena_active():
		var arena_half := _story_hazard_arena_half_size()
		var arena_rect := Rect2(_story_hazard_arena_center - arena_half, arena_half * 2.0)
		draw_rect(arena_rect, Color(0.96, 0.40, 0.12, 0.78), false, 8.0)
		draw_rect(arena_rect.grow(-10.0), Color(1.0, 0.76, 0.26, 0.34), false, 3.0)
	# The extraction enclosure is ground scenery. Draw it first so the Scout
	# and enemies remain visible inside its barricades.
	for background_prop in _adventure_props:
		if str(background_prop.get("kind", "")) != "c1_extraction":
			continue
		var extraction_pos: Vector2 = background_prop.get("pos", Vector2.ZERO) as Vector2
		if not _is_world_pos_visible(extraction_pos, 320.0):
			continue
		var extraction_size := Vector2(520.0, 520.0)
		if _chapter_one_extraction_tex != null:
			draw_texture_rect(_chapter_one_extraction_tex, Rect2(extraction_pos - extraction_size * 0.5, extraction_size), false)
		draw_arc(extraction_pos, 210.0 + sin(_elapsed * 4.0) * 5.0, 0, TAU, 48, Color(1.0, 0.78, 0.22, 0.88), 5.0)
	for prop in _adventure_props:
		var pos: Vector2 = prop.pos
		if not _is_world_pos_visible(pos, 340.0):
			continue
		var kind := String(prop.kind)
		match kind:
			"scout":
				if _objective_scout_tex != null: draw_texture_rect(_objective_scout_tex, Rect2(pos - Vector2(68, 68), Vector2(136, 136)), false)
			"shrine":
				if _objective_shrine_tex != null: draw_texture_rect(_objective_shrine_tex, Rect2(pos - Vector2(105, 105), Vector2(210, 210)), false)
			"nest":
				var shield_left := float(prop.get("shield_t", 0.0))
				draw_circle(pos, STORY_NEST_EFFECTIVE_RADIUS, Color(0.56, 0.24, 0.76, 0.06 if shield_left > 0.0 else 0.10))
				draw_arc(pos, STORY_NEST_EFFECTIVE_RADIUS, 0, TAU, 64, Color(0.58, 0.46, 0.68, 0.58) if shield_left > 0.0 else Color(0.84, 0.58, 1.0, 0.82), 5.0)
				if _objective_nest_tex != null: draw_texture_rect(_objective_nest_tex, Rect2(pos - Vector2(92, 92), Vector2(184, 184)), false)
				if shield_left > 0.0:
					draw_circle(pos, 104.0 + sin(_elapsed * 5.0) * 5.0, Color(0.54, 0.28, 0.94, 0.16))
					draw_arc(pos, 104.0, 0, TAU, 48, Color(0.78, 0.54, 1.0, 0.92), 6.0)
					draw_string(font, pos + Vector2(-90, -112), "Shielded %.1fs" % shield_left, HORIZONTAL_ALIGNMENT_CENTER, 180, 26, Color.WHITE)
			"hazard_emitter":
				var emitter_size := Vector2(210, 210)
				if _objective_hazard_tex != null: draw_texture_rect(_objective_hazard_tex, Rect2(pos - emitter_size * 0.5, emitter_size), false)
				draw_arc(pos, 118.0 + sin(_elapsed * 7.0) * 5.0, 0, TAU, 48, Color(1.0, 0.38, 0.10, 0.82), 5.0)
				if _chapter_one != null and _chapter_one.stage_number == 5 and _chapter_one.phase == "rotating_barrage" and _c1_phase_timer <= 5.0:
					draw_string(font, pos + Vector2(-110.0, -145.0), "OVERHEATING", HORIZONTAL_ALIGNMENT_CENTER, 220.0, 25, Color(1.0, 0.82, 0.18))
				if _chapter_one != null and _chapter_one.stage_number == 5 and _chapter_one.phase == "overheat_burst" and _chapter_one_overheat_burst_tex != null:
					var burst_size := Vector2(360.0, 360.0)
					draw_texture_rect(_chapter_one_overheat_burst_tex, Rect2(pos - burst_size * 0.5, burst_size), false)
			"c1_barricade":
				var barricade_size := Vector2(300.0, 230.0)
				if _chapter_one_barricade_tex != null: draw_texture_rect(_chapter_one_barricade_tex, Rect2(pos - barricade_size * 0.5, barricade_size), false)
			"c1_extraction":
				pass
			"c1_energy_spore":
				var spore_size := Vector2(92.0, 92.0) * (1.0 + sin(_elapsed * 5.0 + pos.x * 0.01) * 0.08)
				if _chapter_one_energy_spore_tex != null: draw_texture_rect(_chapter_one_energy_spore_tex, Rect2(pos - spore_size * 0.5, spore_size), false)
				draw_arc(pos, 52.0, 0, TAU, 32, Color(0.48, 1.0, 0.88, 0.82), 3.0)
			"c1_feeding_sac":
				var sac_size := Vector2(170.0, 170.0) * (1.0 + sin(_elapsed * 3.5 + pos.x * 0.01) * 0.05)
				if _chapter_one_feeding_sac_tex != null: draw_texture_rect(_chapter_one_feeding_sac_tex, Rect2(pos - sac_size * 0.5, sac_size), false)
				draw_arc(pos, 92.0, 0, TAU, 40, Color(1.0, 0.48, 0.16, 0.72), 4.0)
			"c1_gate":
				var gate_size := Vector2(250.0, 310.0)
				if _chapter_one_watchpath_exit_tex != null: draw_texture_rect(_chapter_one_watchpath_exit_tex, Rect2(pos - gate_size * 0.5, gate_size), false)
				draw_arc(pos, 132.0 + sin(_elapsed * 4.0) * 5.0, 0, TAU, 48, Color(1.0, 0.78, 0.22, 0.84), 5.0)
			"c1_track_marker":
				var tracks_size := Vector2(138.0, 138.0) * (1.0 + sin(_elapsed * 4.0 + pos.x * 0.01) * 0.04)
				if _chapter_one_animal_tracks_tex != null: draw_texture_rect(_chapter_one_animal_tracks_tex, Rect2(pos - tracks_size * 0.5, tracks_size), false)
			"key":
				var key_size := Vector2(112.0, 112.0) * (1.0 + sin(_elapsed * 5.0) * 0.06)
				if _chapter_one_watchpath_key_tex != null: draw_texture_rect(_chapter_one_watchpath_key_tex, Rect2(pos - key_size * 0.5, key_size), false)
				draw_arc(pos, 62.0, 0, TAU, 32, Color(1.0, 0.78, 0.18, 0.88), 4.0)
			"safe":
				draw_circle(pos, SAFE_INTERACTION_RADIUS, Color(1.0, 0.76, 0.18, 0.08))
				draw_arc(pos, SAFE_INTERACTION_RADIUS, 0, TAU, 64, Color(1.0, 0.76, 0.18, 0.72), 5.0)
				if _objective_safe_tex != null: draw_texture_rect(_objective_safe_tex, Rect2(pos - Vector2(105, 105), Vector2(210, 210)), false)
			"forge":
				var active := bool(prop.get("active", false))
				if not active:
					draw_circle(pos, FORGE_INTERACTION_RADIUS, Color(1.0, 0.40, 0.14, 0.08))
					draw_arc(pos, FORGE_INTERACTION_RADIUS, 0, TAU, 64, Color(1.0, 0.48, 0.18, 0.72), 5.0)
				if _objective_forge_tex != null: draw_texture_rect(_objective_forge_tex, Rect2(pos - Vector2(115, 115), Vector2(230, 230)), false)
			_:
				_draw_custom_story_prop(prop, font)
		if prop.has("hp") and float(prop.get("max_hp", 0.0)) > 1.0:
			var ratio := clampf(float(prop.hp) / float(prop.max_hp), 0.0, 1.0)
			draw_rect(Rect2(pos + Vector2(-55, 68), Vector2(110, 10)), Color(0.10,0.08,0.08,0.9), true)
			draw_rect(Rect2(pos + Vector2(-55, 68), Vector2(110 * ratio, 10)), Color(0.30,0.92,0.48), true)
		if kind == "forge" and bool(prop.get("active", false)):
			var charge_ratio := clampf(float(prop.get("charge", 0.0)) / float(prop.get("target_charge", 12.0)), 0.0, 1.0)
			draw_rect(Rect2(pos + Vector2(-55, 84), Vector2(110 * charge_ratio, 8)), Color(1.0,0.64,0.16), true)
		var interaction_radius := STORY_NEST_EFFECTIVE_RADIUS if kind == "nest" else (SAFE_INTERACTION_RADIUS if kind == "safe" else FORGE_INTERACTION_RADIUS)
		if pos.distance_to(_player_pos) < interaction_radius and kind in ["nest", "safe", "forge"]:
			var prompt := "Stay inside the effective area" if kind == "nest" else ("Activating forge" if kind == "forge" and not bool(prop.get("active", false)) else ("Defend the forge" if kind == "forge" else "Cracking safe"))
			draw_string(font, pos + Vector2(-130, -132 if kind == "nest" else -82), prompt, HORIZONTAL_ALIGNMENT_CENTER, 260, 26, Color.WHITE)
	if _chapter_two != null and _chapter_two.stage_number == 1 and _story_custom_carried == "flame_charge" and _custom_story_asset_tex.has("flame_charge"):
		var carried_size := Vector2(74.0, 74.0) * (1.0 + sin(_elapsed * 5.0) * 0.06)
		var carried_pos: Vector2 = _player_pos + Vector2(58.0, -74.0)
		draw_texture_rect(_custom_story_asset_tex["flame_charge"] as Texture2D, Rect2(carried_pos - carried_size * 0.5, carried_size), false)

func _draw_custom_story_prop(prop: Dictionary, font: Font) -> void:
	var kind := str(prop.get("kind", ""))
	if not _is_custom_story_prop(kind): return
	var pos: Vector2 = prop.pos
	var color := _custom_story_prop_color(kind)
	var pulse := 1.0 + sin(_elapsed * 4.0 + pos.x * 0.01) * 0.08
	if kind == "brazier" and bool(prop.get("active", false)):
		var warmth_color: Color = Color(0.38, 0.72, 1.0, 0.10) if bool(prop.get("suppressed", false)) else Color(1.0, 0.58, 0.16, 0.12)
		draw_circle(pos, 245.0, warmth_color)
		draw_arc(pos, 245.0, 0.0, TAU, 64, Color(warmth_color.r, warmth_color.g, warmth_color.b, 0.62), 4.0)
	var chapter_three_asset_id: String = _chapter_three_prop_asset_id(prop)
	var chapter_three_asset_size: float = 215.0 if kind in ["c3_web_nest", "c3_bile_vessel", "c3_wasp_hive"] else 175.0
	if not chapter_three_asset_id.is_empty() and _draw_story_asset_by_id(chapter_three_asset_id, pos, chapter_three_asset_size, pulse):
		var chapter_three_marker: String = _custom_story_prop_marker(prop)
		if not chapter_three_marker.is_empty():
			draw_string(font, pos + Vector2(-140, 8), chapter_three_marker, HORIZONTAL_ALIGNMENT_CENTER, 280, 24, Color.WHITE)
		return
	var chapter_two_asset_id: String = _chapter_two_prop_asset_id(prop)
	if not chapter_two_asset_id.is_empty() and _draw_story_asset_by_id(chapter_two_asset_id, pos, _chapter_two_prop_asset_size(kind), pulse):
		var chapter_two_marker := _custom_story_prop_marker(prop)
		if not chapter_two_marker.is_empty(): draw_string(font, pos + Vector2(-140, 8), chapter_two_marker, HORIZONTAL_ALIGNMENT_CENTER, 280, 24, Color.WHITE)
		return
	if kind in ["hiding_zone", "corrupted_pool"]:
		draw_circle(pos, 120.0, Color(color.r, color.g, color.b, 0.12))
		draw_arc(pos, 120.0, 0, TAU, 48, Color(color.r, color.g, color.b, 0.72), 4.0)
		_draw_custom_story_asset(kind, pos, pulse)
		if kind == "corrupted_pool" and prop.has("zone_pos") and _custom_story_asset_tex.has("antidote_vial"):
			var zone_pos: Vector2 = prop.get("zone_pos", pos) as Vector2
			var zone_size := Vector2(92.0, 92.0) * pulse
			draw_texture_rect(_custom_story_asset_tex["antidote_vial"] as Texture2D, Rect2(zone_pos - zone_size * 0.5, zone_size), false)
	elif kind == "sentry":
		if bool(prop.get("disabled", false)):
			_draw_custom_story_asset(kind, pos, pulse)
			return
		var facing: Vector2 = prop.get("facing", Vector2.RIGHT) as Vector2
		var sight_range: float = 410.0
		var left: Vector2 = pos + facing.rotated(-0.58) * sight_range
		var right: Vector2 = pos + facing.rotated(0.58) * sight_range
		draw_colored_polygon(PackedVector2Array([pos, left, right]), Color(1.0, 0.18, 0.12, 0.18))
		draw_line(pos, left, Color(1.0, 0.30, 0.20, 0.82), 4.0)
		draw_line(pos, right, Color(1.0, 0.30, 0.20, 0.82), 4.0)
		draw_arc(pos, sight_range, facing.angle() - 0.58, facing.angle() + 0.58, 28, Color(1.0, 0.30, 0.20, 0.82), 4.0)
		_draw_custom_story_asset(kind, pos, pulse)
	else:
		if not _draw_custom_story_asset(kind, pos, pulse):
			draw_circle(pos, 52.0 * pulse, Color(color.r, color.g, color.b, 0.22))
			draw_arc(pos, 52.0 * pulse, 0, TAU, 32, color, 6.0)
			draw_circle(pos, 28.0, Color(color.r, color.g, color.b, 0.82))
	var marker := _custom_story_prop_marker(prop)
	if not marker.is_empty(): draw_string(font, pos + Vector2(-140, 8), marker, HORIZONTAL_ALIGNMENT_CENTER, 280, 24, Color.WHITE)

func _load_custom_story_assets() -> void:
	var asset_ids := ["frozen_brazier", "ice_captive", "thaw_rune", "frost_mimic", "frost_colossus", "corrupted_pool", "plaguebeast", "venom_harvest", "antidote_vial", "antidote_cauldron", "ember_ore", "lava_valve", "rogue_golem", "lost_relic", "forge_regulator", "abyss_sentry", "liberated_soul", "mirror_portal", "eclipse_obelisk", "abyss_king"]
	for asset_id in asset_ids:
		var path := "res://assets/story/objectives/custom/%s.png" % asset_id
		if ResourceLoader.exists(path):
			_custom_story_asset_tex[asset_id] = load(path) as Texture2D
	var chapter_two_asset_ids := ["flame_charge", "flamekeeper", "brazier_suppression", "frozen_prison", "frost_captive", "frost_jailer", "suspect_chest", "armour_crystal", "frost_clue", "thaw_rune_correct", "thaw_rune_wrong"]
	for asset_id in chapter_two_asset_ids:
		var path := "res://assets/story/objectives/chapter2/%s.png" % asset_id
		if ResourceLoader.exists(path):
			_custom_story_asset_tex[asset_id] = load(path) as Texture2D
	var chapter_three_asset_ids := ["venom_spider", "venom_toad", "venom_wasp", "spider_habitat", "toad_habitat", "wasp_hive"]
	for asset_id in chapter_three_asset_ids:
		var path := "res://assets/story/objectives/chapter3/%s.png" % asset_id
		if ResourceLoader.exists(path):
			_custom_story_asset_tex[asset_id] = load(path) as Texture2D

func _chapter_two_prop_asset_id(prop: Dictionary) -> String:
	if _chapter_two == null:
		return ""
	var kind := str(prop.get("kind", ""))
	if kind == "released_soul":
		return "frozen_prison" if bool(prop.get("refrozen", false)) else "frost_captive"
	if kind == "thaw_rune":
		var feedback := str(prop.get("feedback", ""))
		if feedback == "correct": return "thaw_rune_correct"
		if feedback == "wrong": return "thaw_rune_wrong"
		return "thaw_rune"
	return str({
		"brazier":"frozen_brazier", "c2_brazier_suppression":"brazier_suppression",
		"ice_prison":"frozen_prison", "thaw_rune":"thaw_rune", "mimic_chest":"suspect_chest",
		"frost_clue":"frost_clue", "armour_crystal":"armour_crystal",
	}.get(kind, ""))

func _chapter_two_prop_asset_size(kind: String) -> float:
	return float({"ice_prison":210.0, "mimic_chest":170.0, "armour_crystal":180.0, "c2_brazier_suppression":170.0, "released_soul":135.0, "frost_clue":110.0}.get(kind, 150.0))

func _chapter_three_prop_asset_id(prop: Dictionary) -> String:
	var kind: String = str(prop.get("kind", ""))
	if kind == "c3_region":
		return str(["venom_spider", "venom_toad", "venom_wasp"][clampi(int(prop.get("region", 0)), 0, 2)])
	return str({"c3_web_nest":"spider_habitat", "c3_bile_vessel":"toad_habitat", "c3_wasp_hive":"wasp_hive"}.get(kind, ""))

func _draw_story_asset_by_id(asset_id: String, pos: Vector2, size: float, pulse: float = 1.0) -> bool:
	if not _custom_story_asset_tex.has(asset_id):
		return false
	var draw_size := Vector2(size, size) * pulse
	draw_texture_rect(_custom_story_asset_tex[asset_id] as Texture2D, Rect2(pos - draw_size * 0.5, draw_size), false)
	return true

func _custom_story_prop_asset_id(kind: String) -> String:
	return str({
		"brazier": "frozen_brazier", "ice_prison": "ice_captive", "thaw_rune": "thaw_rune",
		"mimic_chest": "frost_mimic", "armour_crystal": "frost_colossus",
		"corrupted_pool": "corrupted_pool", "tracker": "plaguebeast", "ingredient": "venom_harvest",
		"c3_cleansing_energy":"antidote_vial", "c3_corruption_node":"corrupted_pool", "c3_tracking_clue":"plaguebeast", "c3_region":"venom_harvest",
		"c3_web_nest":"venom_harvest", "c3_bile_vessel":"venom_harvest", "c3_wasp_hive":"venom_harvest",
		"c3_cleanse_station":"corrupted_pool", "c3_extraction":"venom_harvest", "c3_vial":"antidote_vial",
		"c3_route":"antidote_vial", "c3_cure_checkpoint":"antidote_vial", "c3_brew_ingredient":"venom_harvest",
		"infected_altar": "antidote_vial", "healing_fountain": "antidote_vial", "cure_checkpoint": "antidote_vial", "cauldron": "antidote_cauldron",
		"ember_ore": "ember_ore", "lava_valve": "lava_valve", "relic_chamber": "lost_relic",
		"relic_forge": "lost_relic", "regulator": "forge_regulator",
		"c4_ore_deposit":"ember_ore", "c4_ore_bag":"ember_ore", "c4_mining_cart":"lost_relic",
		"c4_cooling_vent":"lava_valve", "c4_lava_vent":"lava_valve", "c4_extraction":"lost_relic", "c4_forge_mechanism":"forge_regulator",
		"c4_route_node":"lava_valve", "c4_charge_wall":"lost_relic", "c4_tether":"forge_regulator", "sentry": "abyss_sentry",
		"hiding_zone":"mirror_portal", "citadel_gate": "mirror_portal", "abyss_portal": "mirror_portal", "mirror_portal": "mirror_portal",
		"security_switch":"forge_regulator", "spirit_safe_zone":"liberated_soul", "portal_seal":"eclipse_obelisk", "mirror_clue":"mirror_portal", "labyrinth_exit":"mirror_portal", "eclipse_seal":"abyss_king", "eclipse_ring":"eclipse_obelisk", "eclipse_shortcut":"forge_regulator", "eclipse_disruption":"forge_regulator", "crown_seal":"eclipse_obelisk", "final_threshold":"mirror_portal",
		"soul_chain": "liberated_soul", "released_soul": "liberated_soul",
		"eclipse_obelisk": "eclipse_obelisk", "ritual_anchor": "abyss_king", "abyss_crown": "abyss_king",
	}.get(kind, ""))

func _draw_custom_story_asset(kind: String, pos: Vector2, pulse: float = 1.0) -> bool:
	var asset_id := _custom_story_prop_asset_id(kind)
	if asset_id.is_empty() or not _custom_story_asset_tex.has(asset_id): return false
	var size := 150.0
	if kind in ["ice_prison", "corrupted_pool", "cauldron", "relic_chamber", "relic_forge", "mirror_portal", "eclipse_obelisk", "citadel_gate", "abyss_portal"]: size = 190.0
	if kind in ["released_soul", "soul_chain"]: size = 120.0
	var draw_size := Vector2(size, size) * pulse
	draw_texture_rect(_custom_story_asset_tex[asset_id] as Texture2D, Rect2(pos - draw_size * 0.5, draw_size), false)
	return true

func _custom_story_enemy_texture(story_tag: String) -> Texture2D:
	var asset_id := str({"c2_flamekeeper":"flamekeeper", "c2_brazier_suppressor":"brazier_suppression", "c2_colossus_summon":"frost_jailer", "frost_colossus":"frost_colossus", "plaguebeast":"plaguebeast", "c3_plague_sighting":"plaguebeast", "c3_plaguebeast_final":"plaguebeast", "c3_marked_spider":"venom_spider", "c3_spider_pack":"venom_spider", "c3_marked_toad":"venom_toad", "c3_toad_pack":"venom_toad", "c3_marked_wasp":"venom_wasp", "c3_wasp_pack":"venom_wasp", "rogue_golem":"rogue_golem", "c4_relic_guardian":"rogue_golem", "c5_portal_keeper":"abyss_sentry", "c5_mirror_guardian":"mirror_portal", "c5_eclipse_elite":"eclipse_obelisk", "abyss_king":"abyss_king"}.get(story_tag, ""))
	if story_tag.begins_with("c2_jailer"):
		asset_id = "frost_jailer"
	elif story_tag.begins_with("c4_golem_"):
		asset_id = "rogue_golem"
	return _custom_story_asset_tex.get(asset_id, null) as Texture2D

func _is_custom_story_prop(kind: String) -> bool:
	return kind in ["c1_barricade", "c1_feeding_sac", "c1_gate", "brazier", "c2_brazier_suppression", "ice_prison", "thaw_rune", "mimic_chest", "frost_clue", "armour_crystal", "corrupted_pool", "tracker", "infected_altar", "healing_fountain", "cure_checkpoint", "ingredient", "cauldron", "c3_cleansing_energy", "c3_corruption_node", "c3_tracking_clue", "c3_region", "c3_web_nest", "c3_bile_vessel", "c3_wasp_hive", "c3_cleanse_station", "c3_extraction", "c3_vial", "c3_route", "c3_cure_checkpoint", "c3_brew_ingredient", "ember_ore", "lava_valve", "relic_chamber", "relic_forge", "regulator", "c4_ore_deposit", "c4_ore_bag", "c4_mining_cart", "c4_cooling_vent", "c4_lava_vent", "c4_extraction", "c4_forge_mechanism", "c4_route_node", "c4_charge_wall", "c4_tether", "sentry", "hiding_zone", "citadel_gate", "abyss_portal", "soul_chain", "released_soul", "mirror_portal", "eclipse_obelisk", "ritual_anchor", "abyss_crown", "security_switch", "spirit_safe_zone", "portal_seal", "mirror_clue", "labyrinth_exit", "eclipse_seal", "eclipse_ring", "eclipse_shortcut", "eclipse_disruption", "crown_seal", "final_threshold"]

func _custom_story_prop_color(kind: String) -> Color:
	if kind == "c1_barricade": return Color(0.74, 0.48, 0.22)
	if kind == "c1_feeding_sac": return Color(0.82, 0.30, 0.54)
	if kind == "c1_gate": return Color(0.96, 0.78, 0.22)
	if kind in ["brazier", "ember_ore", "lava_valve", "regulator", "relic_forge"]: return Color(1.0, 0.42, 0.12)
	if kind in ["ice_prison", "thaw_rune", "armour_crystal"]: return Color(0.42, 0.86, 1.0)
	if kind in ["corrupted_pool", "ingredient", "cauldron", "infected_altar"]: return Color(0.46, 0.92, 0.30)
	if kind in ["sentry", "citadel_gate", "abyss_portal", "soul_chain", "released_soul", "mirror_portal", "eclipse_obelisk", "ritual_anchor", "abyss_crown"]: return Color(0.72, 0.38, 1.0)
	return Color(1.0, 0.78, 0.22)

func _custom_story_prop_marker(prop: Dictionary) -> String:
	var kind := str(prop.get("kind", ""))
	if kind == "brazier" and bool(prop.get("suppressed", false)): return "SUPPRESSED"
	if kind == "armour_crystal" and bool(prop.get("exposed", false)): return "EXPOSED"
	if kind == "released_soul" and bool(prop.get("refrozen", false)): return "REFROZEN"
	if kind == "released_soul" and float(prop.get("refreeze", 0.0)) > 1.0: return "%d%%" % roundi(float(prop.get("refreeze", 0.0)))
	if kind == "mimic_chest" and bool(prop.get("excluded", false)): return "FROST FOUND"
	if kind == "thaw_rune": return str(int(prop.get("rune", 0)) + 1)
	if kind == "regulator": return str(int(prop.get("regulator", 0)) + 1)
	if kind == "c4_ore_deposit":
		if bool(prop.get("heat_locked", false)): return "SEALED BY HEAT · USE A COOLING VENT"
		if float(prop.get("progress", 0.0)) > 0.0:
			var deposit_duration: float = float([3.0, 5.0, 4.0][clampi(int(prop.get("deposit_type", 0)), 0, 2)])
			return "MINING %d%%" % roundi(clampf(float(prop.get("progress", 0.0)) / deposit_duration, 0.0, 1.0) * 100.0)
		return str(["SAFE ORE", "RICH ORE", "UNSTABLE ORE"][clampi(int(prop.get("deposit_type", 0)), 0, 2)])
	if kind == "c4_ore_bag": return "DROPPED ORE"
	if kind == "c4_mining_cart": return "CART %d/12" % int(prop.get("loaded", 0))
	if kind == "c4_cooling_vent": return "COOLING VENT · %d" % int(prop.get("charges", 0))
	if kind == "c4_lava_vent": return "UNSTABLE LAVA VENT"
	if kind == "c4_extraction": return "CART EXTRACTION"
	if kind == "c4_forge_mechanism": return "JAMMED" if bool(prop.get("jammed", false)) else ("POWERED" if bool(prop.get("powered", false)) else "OFFLINE")
	if kind == "c4_route_node": return "ROUTE %d" % (int(prop.get("route", 0)) + 1)
	if kind == "c4_charge_wall": return "CHARGE WALL"
	if kind == "c4_tether": return "ACTIVE" if bool(prop.get("active", false)) else "HOLD TO ACTIVATE"
	if kind == "hiding_zone" and _story_custom_id == "silent_descent":
		if bool(prop.get("visited", false)):
			return "SAFE POINT %d · ACTIVATED" % (int(prop.get("section", 0)) + 1)
		var activation_progress: float = float(prop.get("activation_progress", 0.0))
		if activation_progress > 0.0:
			return "SAFE POINT %d · HOLD %ds" % [int(prop.get("section", 0)) + 1, ceili(10.0 - activation_progress)]
		return "SAFE POINT %d · HOLD 10s" % (int(prop.get("section", 0)) + 1)
	if kind == "mirror_portal": return str(prop.get("symbol", int(prop.get("portal", 0)) + 1))
	if kind == "sentry": return str(prop.get("state", "unaware")).to_upper()
	if kind == "security_switch": return "DISABLED" if bool(prop.get("disabled", false)) else "HOLD TO DISABLE"
	if kind == "spirit_safe_zone": return "SPIRIT SANCTUARY"
	if kind == "portal_seal": return "STABLE" if bool(prop.get("stable", false)) else "HOLD TO STABILIZE"
	if kind == "mirror_clue": return "CLUE INSCRIPTION"
	if kind == "labyrinth_exit": return "LABYRINTH EXIT"
	if kind == "eclipse_seal": return "CORRUPTION SEAL"
	if kind == "eclipse_ring": return "HOLD TO ALIGN"
	if kind == "eclipse_shortcut": return "SHORTCUT OPEN" if bool(prop.get("active", false)) else "HOLD TO OPEN SHORTCUT"
	if kind == "crown_seal": return "CROWN SEAL %s" % ("A" if int(prop.get("seal", 0)) == 0 else "B")
	if kind == "final_threshold": return "ESCAPE THRESHOLD"
	if kind == "ingredient": return str(int(prop.get("ingredient", 0)) + 1)
	if kind == "cure_checkpoint": return str(int(prop.get("checkpoint", 0)) + 1)
	if kind == "c3_cleansing_energy": return "+%d ENERGY" % int(prop.get("value", 2))
	if kind == "corrupted_pool" and _chapter_three != null and _chapter_three.stage_number == 1:
		var pool_index: int = int(prop.get("pool", 0))
		if _chapter_three.phase == "reclamation_surge":
			return "STABLE" if float(prop.get("stability", 100.0)) >= 35.0 else "STABILIZE"
		if bool(prop.get("purified", false)): return "PURIFIED"
		if pool_index == _chapter_three.count("pools_purified"): return "PURIFY HERE"
		return "LOCKED"
	if kind == "c3_tracking_clue": return "TRAIL %d" % (int(prop.get("route", 0)) + 1)
	if kind == "c3_region":
		var region: int = int(prop.get("region", 0))
		if _chapter_three != null and _chapter_three.count("selection_region") == region and _c3_action_timer > 0.0:
			return "SELECT %ds" % maxi(0, ceili(2.0 - _c3_action_timer))
		return str(["SPIDER", "TOAD", "WASP"][region])
	if kind in ["c3_web_nest", "c3_bile_vessel", "c3_wasp_hive"]:
		var lure_region: int = int(prop.get("region", 0))
		return "LURE %ds" % maxi(0, ceili(_c3_region_lure_duration(lure_region) - float(prop.get("progress", 0.0))))
	if kind == "c3_route":
		var route: int = int(prop.get("route", 0))
		if _chapter_three != null and _chapter_three.count("selection_route") == route and _c3_action_timer > 0.0:
			return "SELECT %ds" % maxi(0, ceili(2.5 - _c3_action_timer))
		return "SHORT" if route == 0 else "LONG"
	if kind == "c3_cure_checkpoint":
		if _chapter_three != null and _chapter_three.phase == "vial_delivery":
			var hold_duration: float = 5.0 if _chapter_three.count("route") == 0 else 4.0
			return "HOLD %ds" % maxi(0, ceili(hold_duration - float(prop.get("progress", 0.0))))
		return "CHECKPOINT %d" % (int(prop.get("checkpoint", 0)) + 1)
	if kind == "infected_altar" and _chapter_three != null and _chapter_three.stage_number == 4 and _chapter_three.phase == "infected_altar":
		return "PLACE VIAL %ds" % maxi(0, ceili(4.0 - float(prop.get("progress", 0.0))))
	if kind == "c3_brew_ingredient": return _ingredient_name(str(prop.get("ingredient", 0)))
	if kind == "cauldron" and _chapter_three != null and _chapter_three.stage_number == 5:
		if _story_custom_timer > 0.0 and not str(_story_custom_progress.get("brew_feedback", "")).is_empty():
			return "WRONG INGREDIENT" if str(_story_custom_progress.get("brew_feedback", "")).begins_with("WRONG") else "CORRECT"
		if _chapter_three.phase == "ingredient_collection":
			return "SUBMIT %s" % _ingredient_name(_story_custom_carried) if not _story_custom_carried.is_empty() else "CAULDRON"
		if _chapter_three.phase == "active_brewing":
			var heat: float = _chapter_three.meter("heat")
			if _chapter_three.meter("purity") < 35.0: return "RESTORE PURITY"
			if heat < 35.0: return "MOVE AWAY · HEAT UP"
			if heat > 82.0: return "STAND NEAR · COOL"
			return "BREWING"
	if kind == "ember_ore": return "+%d" % int(prop.get("value", 1))
	if kind == "mimic_chest" and bool(prop.get("real", false)) and sin(_elapsed * 5.0) > 0.78: return "?"
	return ""

func _draw_story_objective_indicators() -> void:
	if story_stage.is_empty() and dungeon_mode.is_empty():
		return
	for prop in _adventure_props:
		var kind := String(prop.get("kind", ""))
		if kind not in ["scout", "shrine", "nest", "key", "hazard_emitter", "c1_extraction", "c1_energy_spore", "c1_track_marker", "c1_gate", "safe", "forge"] and not _should_indicate_custom_prop(prop):
			continue
		if kind == "forge" and bool(prop.get("active", false)):
			continue
		var objective_pos: Vector2 = prop.pos
		var near_radius := STORY_NEST_EFFECTIVE_RADIUS if kind == "nest" else (SAFE_INTERACTION_RADIUS if kind == "safe" else (FORGE_INTERACTION_RADIUS if kind == "forge" else (150.0 if _is_custom_story_prop(kind) else 240.0)))
		if objective_pos.distance_to(_player_pos) < near_radius:
			continue
		var color := _story_objective_indicator_color(kind)
		var indicator_label: String = _story_objective_indicator_label(kind)
		if kind == "c3_brew_ingredient":
			indicator_label = _ingredient_name(str(prop.get("ingredient", 0)))
		_draw_player_direction_indicator(objective_pos, indicator_label, color, near_radius)
	for enemy in _enemies:
		var tag := str(enemy.get("story_tag", ""))
		var chapter_four_target: bool = tag.begins_with("c4_golem_") or tag.begins_with("c4_chamber_guardian_") or tag in ["c4_ore_thief", "c4_cart_blocker", "c4_relic_guardian", "c4_thunderforge_behemoth", "c4_forge_jammer"]
		if tag not in ["fleeing_key_carrier", "protected_key_carrier", "watchpath_captain", "frost_mimic", "frost_colossus", "plaguebeast", "c3_energy_carrier", "c3_plague_sighting", "c3_plaguebeast_final", "c3_marked_spider", "c3_marked_toad", "c3_marked_wasp", "c3_blight_tyrant", "rogue_golem", "relic_guardian", "abyss_king"] and not chapter_four_target: continue
		var label: String = str({"fleeing_key_carrier":"Fleeing Carrier", "protected_key_carrier":"Protected Carrier", "watchpath_captain":"Watchpath Captain", "frost_mimic":"Frost Mimic", "frost_colossus":"Frostbound Colossus", "plaguebeast":"Plaguebeast", "c3_energy_carrier":"Cleansing Energy Carrier", "c3_plague_sighting":"Plaguebeast Sighting", "c3_plaguebeast_final":"Plaguebeast", "c3_marked_spider":"Marked Spider", "c3_marked_toad":"Marked Toad", "c3_marked_wasp":"Marked Wasp", "c3_blight_tyrant":"Blight Vine Tyrant", "c4_ore_thief":"Ore Thief", "c4_cart_blocker":"Cart Obstruction", "c4_relic_guardian":"Relic Guardian", "c4_thunderforge_behemoth":"Thunderforge Behemoth", "c4_forge_jammer":"Forge Jammer", "rogue_golem":"Rogue Golem", "relic_guardian":"Chamber Guardian", "abyss_king":"Abyss King"}.get(tag, "Rogue Golem" if tag.begins_with("c4_golem_") else ("Chamber Guardian" if tag.begins_with("c4_chamber_guardian_") else "Target")))
		if tag.begins_with("c4_golem_") and _chapter_four != null and _chapter_four.flag("capture_ready"):
			label = "CAPTURABLE · Hold Nearby"
		_draw_player_direction_indicator(enemy.pos as Vector2, label, Color(1.0, 0.42, 0.18, 0.98), 240.0)

func _should_indicate_custom_prop(prop: Dictionary) -> bool:
	var kind := str(prop.get("kind", ""))
	if kind == "corrupted_pool" and _chapter_three != null and _chapter_three.stage_number == 1:
		return _chapter_three.phase == "reclamation_surge" or int(prop.get("pool", -1)) == _chapter_three.count("pools_purified")
	if kind == "hiding_zone" and _story_custom_id == "silent_descent":
		var reached: int = _chapter_five.count("checkpoints_reached") if _chapter_five != null else int(_story_custom_progress.get("safe_points", 0))
		return not bool(prop.get("visited", false)) and int(prop.get("section", -1)) == reached
	if kind == "citadel_gate" and _story_custom_id == "silent_descent":
		return (_chapter_five.count("checkpoints_reached") if _chapter_five != null else int(_story_custom_progress.get("safe_points", 0))) >= 3
	if kind in ["sentry", "hiding_zone", "healing_fountain", "abyss_portal", "frost_clue", "c4_lava_vent"]: return false
	if kind == "thaw_rune":
		if _chapter_two != null and _chapter_two.flag("rune_sequence_started"):
			return false
		var entered := int(_story_custom_progress.get("entered", 0))
		return entered < _story_custom_sequence.size() and int(prop.get("rune", -1)) == _story_custom_sequence[entered]
	if kind == "regulator":
		if _chapter_four != null and _chapter_four.stage_number == 5:
			var shutdown: int = _chapter_four.count("regulators_disabled")
			return shutdown < _chapter_four.sequence.size() and int(prop.get("regulator", -1)) == _chapter_four.sequence[shutdown]
		var entered := int(_story_custom_progress.get("entered", 0))
		return entered < _story_custom_sequence.size() and int(prop.get("regulator", -1)) == _story_custom_sequence[entered]
	if kind == "mirror_portal": return false
	if kind == "cure_checkpoint": return int(prop.get("checkpoint", -1)) == int(_story_custom_progress.get("checkpoints", 0))
	if kind == "infected_altar": return int(_story_custom_progress.get("checkpoints", 0)) >= 3
	if kind == "cauldron":
		if _chapter_three != null and _chapter_three.stage_number == 5:
			return _chapter_three.phase == "active_brewing" or not _story_custom_carried.is_empty() or _story_custom_timer > 0.0
		return not _story_custom_carried.is_empty()
	return _is_custom_story_prop(kind)

func _draw_player_direction_indicator(target_pos: Vector2, label: String, color: Color, near_radius: float) -> void:
	if _objective_arrow_tex == null or target_pos.distance_to(_player_pos) < near_radius:
		return
	var direction := _player_pos.direction_to(target_pos)
	if direction.is_zero_approx():
		return
	var pulse := 1.0 + sin(_elapsed * 5.0) * 0.08
	var arrow_pos := _player_pos + direction * 132.0
	var arrow_size := Vector2(76.0, 76.0) * pulse
	draw_set_transform(arrow_pos, direction.angle() + PI * 0.5, Vector2.ONE)
	draw_texture_rect(_objective_arrow_tex, Rect2(-arrow_size * 0.5, arrow_size), false, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_string(ThemeDB.fallback_font, arrow_pos + Vector2(-110, 58), label, HORIZONTAL_ALIGNMENT_CENTER, 220, 26, Color.WHITE)

func _story_objective_indicator_color(kind: String) -> Color:
	match kind:
		"scout": return Color(0.46, 1.0, 0.58, 0.98)
		"shrine": return Color(0.28, 0.90, 1.0, 0.98)
		"nest": return Color(0.88, 0.48, 1.0, 0.98)
		"hazard_emitter": return Color(1.0, 0.38, 0.10, 0.98)
		"c1_extraction": return Color(1.0, 0.78, 0.22, 0.98)
		"c1_energy_spore": return Color(0.42, 1.0, 0.88, 0.98)
		"c1_track_marker", "c1_gate": return Color(1.0, 0.78, 0.22, 0.98)
		"safe": return Color(1.0, 0.78, 0.16, 0.98)
		"forge": return Color(1.0, 0.42, 0.12, 0.98)
		_:
			var custom_color := _custom_story_prop_color(kind)
			return Color(custom_color.r, custom_color.g, custom_color.b, 0.98) if _is_custom_story_prop(kind) else Color(1.0, 0.84, 0.18, 0.98)

func _story_objective_indicator_label(kind: String) -> String:
	match kind:
		"scout": return "Scout"
		"shrine": return "Shrine"
		"nest": return "Enemy Nest"
		"hazard_emitter": return "Hazard"
		"c1_extraction": return "Extraction Point"
		"c1_energy_spore": return "Energy Spore"
		"c1_track_marker": return "Carrier Tracks"
		"c1_gate": return "Watchpath Exit"
		"c1_barricade": return "Scout Barricade"
		"c1_feeding_sac": return "Nest's Shield"
		"safe": return "Coin Safe"
		"forge": return "Forge"
		_: return _custom_story_indicator_label(kind) if _is_custom_story_prop(kind) else "Key"

func _custom_story_indicator_label(kind: String) -> String:
	var labels := {"brazier":"Frozen Brazier", "ice_prison":"Ice Prison", "thaw_rune":"Next Rune", "mimic_chest":"Chest", "armour_crystal":"Armour Crystal", "corrupted_pool":"Active Corrupted Pool", "tracker":"Plaguebeast", "c3_cleansing_energy":"Cleansing Energy", "c3_corruption_node":"Corruption Node", "c3_tracking_clue":"Tracking Clue", "c3_region":"Harvest Region", "c3_web_nest":"Web Nest", "c3_bile_vessel":"Bile Vessel", "c3_wasp_hive":"Wasp Hive", "c3_cleanse_station":"Cleansing Station", "c3_extraction":"Ingredient Extraction", "c3_vial":"Antidote Vial", "c3_route":"Route Choice", "c3_cure_checkpoint":"Cure Checkpoint", "c3_brew_ingredient":"Brew Ingredient", "infected_altar":"Infected Altar", "ingredient":"Ingredient", "cauldron":"Cauldron", "ember_ore":"Ember Ore", "lava_valve":"Lava Valve", "relic_chamber":"Relic Chamber", "relic_forge":"Central Forge", "regulator":"Next Regulator", "c4_ore_deposit":"Ember Ore Deposit", "c4_ore_bag":"Dropped Ember Ore", "c4_mining_cart":"Mining Cart", "c4_cooling_vent":"Cooling Vent", "c4_lava_vent":"Lava Vent", "c4_extraction":"Extraction", "c4_forge_mechanism":"Forge Mechanism", "c4_route_node":"Powered Route", "c4_charge_wall":"Charge Wall", "c4_tether":"Forge Tether", "hiding_zone":"Next Safe Point", "citadel_gate":"Inner Citadel", "soul_chain":"Soul Chain", "released_soul":"Released Soul", "mirror_portal":"Mirror Portal", "eclipse_obelisk":"Obelisk", "ritual_anchor":"Ritual Anchor", "abyss_crown":"Abyss Crown", "security_switch":"Security Switch", "spirit_safe_zone":"Spirit Sanctuary", "portal_seal":"Portal Stabilizer", "mirror_clue":"Clue Inscription", "labyrinth_exit":"Labyrinth Exit", "eclipse_seal":"Corruption Seal", "eclipse_ring":"Eclipse Rings", "eclipse_shortcut":"Route Shortcut", "crown_seal":"Crown Seal", "final_threshold":"Escape Threshold"}
	return str(labels.get(kind, "Objective"))

func _draw() -> void:
	var view_size: Vector2 = get_viewport_rect().size
	var draw_center: Vector2 = _camera.position if _camera != null else _player_pos
	_draw_world_rect = Rect2(draw_center - view_size * 0.5, view_size)
	_draw_bg()
	_draw_adventure_objectives()
	_draw_story_objective_indicators()

	# XP orbs
	for orb in _xp_orbs:
		var op: Vector2 = orb["pos"] as Vector2
		if not _is_world_pos_visible(op, 32.0):
			continue
		draw_circle(op, XP_ORB_R, Color(0.28, 0.88, 0.60, 0.9))
		draw_arc(op, XP_ORB_R + 2.0, 0.0, TAU, 16, Color(0.5, 1.0, 0.8, 0.5), 1.5)

	_draw_damage_popups()

	# Aura — level-scaled mud effect
	if _has_skill("aura"):
		var aura_sk: Dictionary = _get_skill("aura")
		var adef: Dictionary    = _slvl("aura", aura_sk["level"] as int)
		var ar: float  = adef["r"] as float
		var alv: int   = aura_sk["level"] as int
		# Base muddy fill (gets darker + more opaque at higher levels)
		draw_circle(_player_pos, ar, Color(0.38 + alv * 0.02, 0.25 + alv * 0.01, 0.10, 0.08 + alv * 0.025))
		# Mud blobs crawling around the ring edge (more blobs per level)
		var n_blobs: int = 10 + alv * 2
		for i in n_blobs:
			var base_ang: float   = float(i) / float(n_blobs) * TAU + _elapsed * (0.28 + alv * 0.04)
			var wobble: float     = sin(_elapsed * (2.6 + alv * 0.3) + float(i) * 0.95) * (12.0 + alv * 3.0)
			var blob_pos: Vector2 = _player_pos + Vector2(cos(base_ang), sin(base_ang)) * (ar + wobble)
			var bsize: float      = 4.5 + float(alv) * 1.2 + sin(_elapsed * 3.5 + float(i) * 1.3) * 2.0
			draw_circle(blob_pos, bsize, Color(0.48 + alv * 0.03, 0.30 + alv * 0.02, 0.10, 0.65 + alv * 0.05))
		# Inner slow-drifting bubbles (more at higher levels)
		var n_inner: int = 5 + alv * 2
		for i in n_inner:
			var ba: float     = float(i) / float(n_inner) * TAU + _elapsed * (0.4 + alv * 0.06) + float(i) * 0.44
			var bd: float     = ar * (0.20 + 0.50 * (float(i) / float(n_inner)))
			var bpos: Vector2 = _player_pos + Vector2(cos(ba), sin(ba)) * bd
			var b_a: float    = 0.25 + 0.20 * sin(_elapsed * (3.8 + alv * 0.4) + float(i) * 1.2)
			draw_circle(bpos, 3.5 + float(alv) * 0.5, Color(0.58 + alv * 0.04, 0.38, 0.12, b_a))
		# Level 3+: second outer ring of bigger chunks
		if alv >= 3:
			for i in 8:
				var oa: float     = float(i) / 8.0 * TAU + _elapsed * 0.18 + 0.4
				var od: float     = ar * 0.82
				var op: Vector2   = _player_pos + Vector2(cos(oa), sin(oa)) * od
				var ow: float     = sin(_elapsed * 2.2 + float(i) * 0.8) * 8.0
				draw_circle(op + Vector2(cos(oa), sin(oa)) * ow, 6.0 + float(alv - 2) * 1.5, Color(0.55, 0.32, 0.08, 0.55))
		# Level 5: bubbling geyser pulses
		if alv >= 5:
			for i in 5:
				var pa: float   = float(i) / 5.0 * TAU + _elapsed * 0.7
				var pd: float   = ar * (0.4 + 0.45 * fmod(_elapsed * 0.6 + float(i) * 0.3, 1.0))
				var pp: Vector2 = _player_pos + Vector2(cos(pa), sin(pa)) * pd
				draw_circle(pp, 7.0, Color(0.70, 0.45, 0.12, 0.50))
		# Outer chunky ring (thicker at higher level)
		draw_arc(_player_pos, ar, 0.0, TAU, 36, Color(0.62 + alv * 0.03, 0.40 + alv * 0.02, 0.14, 0.45 + alv * 0.06), 2.5 + float(alv) * 0.5)
	# Inner glow ring
		draw_arc(_player_pos, ar * 0.62, 0.0, TAU, 24, Color(0.52, 0.33, 0.11, 0.16 + alv * 0.03), 2.0)

# Hurricane aura — data-driven from skill_data.json with enhanced visuals
	if _has_skill("hurricane"):
		var hs_sk: Dictionary = _get_skill("hurricane")
		var hdef: Dictionary  = _slvl("hurricane", hs_sk["level"] as int)
		var hr: float = hdef["r"] as float
		var hlv: int  = hs_sk["level"] as int
		
		# Get color and animation specs from skill_data.json
		var h_color = SkillMgr.get_skill_color("hurricane") if SkillMgr else Color(0.6, 0.9, 1.0, 1.0)
		
		var h_rot_speed = 360.0
		var h_wobble = 0.5
		var h_glow = 1.0
		var h_specs = hs_sk.get("animation_specs", {})
		if h_specs.size() > 0:
			var h_values: Array = h_specs.values()
			if not h_values.is_empty():
				var first_spec = h_values[0]
				if first_spec is Dictionary:
					h_rot_speed = float(first_spec.get("rotation_speed", 360.0))
					h_wobble = float(first_spec.get("wobble_amplitude", 0.5))
					h_glow = float(first_spec.get("glow_intensity", 1.0))
		
		# Multiple concentric rings with varying speeds for depth
		for ring_layer in range(1, 4):
			var ring_alpha = (1.0 - float(ring_layer) / 4.0) * 0.4
			var ring_width = 3.5 - float(ring_layer) * 0.5
			var layer_rot = _elapsed * deg_to_rad(h_rot_speed) * (1.0 - float(ring_layer) * 0.2)
			var layer_r = hr * (0.4 + float(ring_layer) * 0.2)
			
			var points: PackedVector2Array = PackedVector2Array()
			for seg in range(0, 72):
				var angle = float(seg) / 72.0 * TAU + layer_rot
				var wobble_amt = sin(_elapsed * (2.0 + float(ring_layer)) + float(seg) * 0.1) * h_wobble * 5.0
				var pt = _player_pos + Vector2(cos(angle), sin(angle)) * (layer_r + wobble_amt)
				points.append(pt)
			
			var col = Color(h_color.r, h_color.g, h_color.b, ring_alpha * h_glow)
			draw_polyline(points, col, ring_width)
		
		# Draw several mini-tornados scattered in the area
		var n_tornados: int = 3 + hlv
		for i in n_tornados:
			var torbit_speed: float = 0.45 + float(i) * 0.12
			var torbit_ang: float   = float(i) * TAU / float(n_tornados) + _elapsed * torbit_speed
			var torbit_dist: float  = hr * (0.30 + 0.55 * float(i % 3) / 2.0)
			var tpos: Vector2       = _player_pos + Vector2(cos(torbit_ang), sin(torbit_ang)) * torbit_dist
			
			var tperiod: float  = 1.4 + float(i) * 0.3
			var tphase: float   = fmod(_elapsed + float(i) * tperiod * 0.6, tperiod) / tperiod
			
			var talpha: float
			if tphase < 0.3:
				talpha = tphase / 0.3
			elif tphase < 0.7:
				talpha = 1.0
			else:
				talpha = (1.0 - tphase) / 0.3
			talpha *= (0.55 + float(hlv) * 0.06) * h_glow  # Apply glow intensity
			
			var tscale: float = 8.0 + float(hlv) * 3.0 + tphase * 6.0
			var n_rings: int = 4 + hlv
			
			for r in n_rings:
				var rheight: float    = float(r) / float(n_rings)
				var ring_rx: float    = tscale * (1.0 - rheight * 0.75)
				var ring_ry: float    = ring_rx * 0.38
				var ring_y: float     = -rheight * tscale * 2.2
				var ring_rot: float   = _elapsed * deg_to_rad(h_rot_speed) * (1.0 + h_wobble) + float(r) * 0.9
				var ring_alpha: float = talpha * (0.35 + rheight * 0.45)
				var ring_col: Color   = Color(h_color.r, h_color.g, h_color.b, ring_alpha)
				
				var ellpts: PackedVector2Array = PackedVector2Array()
				var ell_segs: int = 14
				for s in ell_segs + 1:
					var sa: float = float(s) / float(ell_segs) * TAU + ring_rot
					var wobble_var = sin(_elapsed * (1.5 + h_wobble) + float(s) * 0.3) * h_wobble * 2.0
					var ex: float = (cos(sa) * ring_rx + wobble_var)
					var ey: float = (sin(sa) * ring_ry + wobble_var * 0.5)
					ellpts.append(tpos + Vector2(ex, ey + ring_y))
				draw_polyline(ellpts, ring_col, 1.5)
			
			draw_circle(tpos, tscale * 0.55 + sin(_elapsed * 6.0 + float(i)) * 2.0, Color(h_color.r, h_color.g, h_color.b, talpha * 0.30))

	# Knife Storm aura — data-driven with enhanced visual dynamics
	if _has_skill("knife_storm"):
		var ks_sk: Dictionary = _get_skill("knife_storm")
		var kdef: Dictionary  = _slvl("knife_storm", ks_sk["level"] as int)
		var kr: float = kdef["r"] as float
		var klv: int  = ks_sk["level"] as int
		
		# Get color and animation specs from skill_data.json
		var k_color = SkillMgr.get_skill_color("knife_storm") if SkillMgr else Color(0.7, 0.5, 1.0, 1.0)
		
		var k_rot_speed = 900.0
		var k_wobble = 0.8
		var k_glow = 1.0
		var k_specs = ks_sk.get("animation_specs", {})
		if k_specs.size() > 0:
			var k_values: Array = k_specs.values()
			if not k_values.is_empty():
				var first_spec = k_values[0]
				if first_spec is Dictionary:
					k_rot_speed = float(first_spec.get("rotation_speed", 900.0))
					k_wobble = float(first_spec.get("wobble_amplitude", 0.8))
					k_glow = float(first_spec.get("glow_intensity", 1.0))
		
		# Core spinning vortex - layered rings at different speeds
		for layer in range(1, 3):
			var layer_rot = _elapsed * deg_to_rad(k_rot_speed) * float(layer) * 0.6
			var layer_alpha = (1.0 - float(layer) * 0.3) * 0.3 * k_glow
			var n_blades = 6 + layer * 2
			for blade in range(n_blades):
				var blade_ang = float(blade) / float(n_blades) * TAU + layer_rot
				var blade_len = kr * (0.5 + float(layer) * 0.3)
				var blade_tip = _player_pos + Vector2(cos(blade_ang), sin(blade_ang)) * blade_len
				var blade_color = Color(k_color.r, k_color.g, k_color.b, layer_alpha)
				draw_circle(blade_tip, 3.0 + float(layer), blade_color)
		
		# Scattered cross slashes that flicker in and out
		var n_crosses: int = 5 + klv * 2
		for i in n_crosses:
			var seed_t: float  = _elapsed * 2.2 + float(i) * 1.618
			var life: float    = 0.5 + 0.5 * sin(seed_t * (1.3 + float(i) * 0.17))
			if life < 0.12:
				continue
			var alpha: float   = life * 0.88 * k_glow
			var angle: float   = float(i) * 2.399963 + _elapsed * (0.8 + float(i % 3) * 0.35)
			var dist: float    = kr * (0.25 + 0.70 * fmod(float(i) * 0.618 + _elapsed * 0.15 * k_wobble, 1.0))
			var cp: Vector2    = _player_pos + Vector2(cos(angle), sin(angle)) * dist
			var rot: float     = _elapsed * (deg_to_rad(k_rot_speed) * 0.5 + float(i % 4) * 0.6) + float(i) * 0.8
			var arm: float     = 10.0 + float(klv) * 1.8
			var col1: Color    = Color(k_color.r, k_color.g, k_color.b, alpha)
			var col2: Color    = Color(k_color.r, k_color.g, k_color.b, alpha * 0.70)
			
			var d1: Vector2 = Vector2(cos(rot), sin(rot)) * arm
			var d2: Vector2 = Vector2(cos(rot + PI * 0.5), sin(rot + PI * 0.5)) * arm
			draw_line(cp - d1, cp + d1, col1, 2.2)
			draw_line(cp - d2, cp + d2, col1, 2.2)
			
			var d3: Vector2 = Vector2(cos(rot + PI * 0.25), sin(rot + PI * 0.25)) * (arm * 0.65)
			var d4: Vector2 = Vector2(cos(rot + PI * 0.75), sin(rot + PI * 0.75)) * (arm * 0.65)
			draw_line(cp - d3, cp + d3, col2, 1.4)
			draw_line(cp - d4, cp + d4, col2, 1.4)
			
			# Enhanced glow center
			draw_circle(cp, 2.0 + life * 2.0, Color(1.0, 1.0, 1.0, alpha * 0.90))
			draw_circle(cp, 4.0 + life * 1.0, Color(k_color.r, k_color.g, k_color.b, alpha * 0.40))
		
		draw_arc(_player_pos, kr, 0.0, TAU, 24, Color(k_color.r, k_color.g, k_color.b, k_color.a * (0.2 + k_glow * 0.1) + float(klv) * 0.03), 1.8)

	# Wave rings — data-driven with enhanced visual effects
	for w in []:
		var lf: float    = (w["life"] as float) / (w["max_life"] as float)
		var wr: float    = w["r"] as float
		var wp: Vector2  = w["pos"] as Vector2
		var wkind: String = w.get("kind", "wave") as String
		
		# Belly bounce uses orange color
		if wkind == "belly_bounce":
			draw_circle(wp, wr, Color(1.0, 0.65, 0.15, lf * 0.18))
			draw_circle(wp, max(15.0, wr * 0.22), Color(1.0, 0.80, 0.20, lf * 0.65))
		else:
			draw_circle(wp, wr, Color(0.72, 0.78, 1.0, lf * 0.14))
			if wkind == "arc_lightning":
				draw_circle(wp, max(12.0, wr * 0.18), Color(1.0, 0.98, 0.50, lf * 0.78))
			if wkind == "crystal_prism":
				draw_circle(wp, max(10.0, wr * 0.15), Color(0.72, 0.96, 1.0, lf * 0.78))
		continue
		
		if wkind == "elec_wave":
			var elec_color = SkillMgr.get_skill_color("elec_wave") if SkillMgr else Color(1.0, 1.0, 0.2, 1.0)
			var ewlv: int = 1
			var ew_glow = 1.0
			if _has_skill("elec_wave"):
				var ew_sk = _get_skill("elec_wave")
				ewlv = ew_sk["level"] as int
				var ew_specs = ew_sk.get("animation_specs", {})
				if ew_specs.size() > 0:
					var ew_values: Array = ew_specs.values()
					if not ew_values.is_empty():
						var ew_spec = ew_values[0]
						if ew_spec is Dictionary and "glow_intensity" in ew_spec:
							ew_glow = float(ew_spec["glow_intensity"])
			
			# Multiple expanding arcs for layered effect
			for layer in range(1, 3):
				var layer_wr = wr - float(layer) * 6.0
				if layer_wr > 10.0:
					var layer_alpha = lf * (0.90 - float(layer) * 0.3) * ew_glow
					var layer_width = (5.0 + float(ewlv) * 0.6) * lf * (1.0 - float(layer) * 0.2)
					draw_arc(wp, layer_wr, 0.0, TAU, 72, Color(elec_color.r, elec_color.g, elec_color.b, layer_alpha), layer_width)
			
			var n_arcs: int = 6 + ewlv * 2
			for i in n_arcs:
				var ea: float    = float(i) / float(n_arcs) * TAU
				var emid: Vector2 = wp + Vector2(cos(ea + 0.12), sin(ea + 0.12)) * (wr + sin(float(i) * 1.9 + lf * 22.0) * 12.0)
				var eend: Vector2 = wp + Vector2(cos(ea + 0.22), sin(ea + 0.22)) * (wr + 22.0 * lf)
				var e_glow_mul = 1.0 + ew_glow * 0.2
				draw_line(wp + Vector2(cos(ea), sin(ea)) * (wr - 6.0), emid, Color(1.0 * e_glow_mul, 1.0 * e_glow_mul, 0.50, lf * 0.65), 1.8)
				draw_line(emid, eend, Color(0.85 * e_glow_mul, 0.95 * e_glow_mul, 0.20, lf * 0.40), 1.2)
		else:
			var wave_color = SkillMgr.get_skill_color("wave") if SkillMgr else Color(0.72, 0.46, 1.0, 1.0)
			var wlv: int = 1
			var w_glow = 1.0
			var w_wobble = 0.5
			if _has_skill("wave"):
				var w_sk = _get_skill("wave")
				wlv = w_sk["level"] as int
				var w_specs = w_sk.get("animation_specs", {})
				if w_specs.size() > 0:
					var w_values: Array = w_specs.values()
					if not w_values.is_empty():
						var w_spec = w_values[0]
						if w_spec is Dictionary:
							w_glow = float(w_spec.get("glow_intensity", 1.0))
							w_wobble = float(w_spec.get("wobble_amplitude", 0.5))
			if wkind == "mana_push":
				# Blue push ring — pure knockback visual
				draw_circle(wp, wr * 0.55, Color(0.25, 0.52, 1.0, lf * 0.16))
				draw_arc(wp, wr, 0.0, TAU, 64, Color(0.38, 0.68, 1.0, lf * 0.90), 4.8 * lf)
				draw_arc(wp, wr * 0.88, 0.0, TAU, 48, Color(0.72, 0.90, 1.0, lf * 0.40), 2.0 * lf)
				for pi in 16:
					var pa: float = float(pi) / 16.0 * TAU
					draw_circle(wp + Vector2(cos(pa), sin(pa)) * wr, 4.5 * lf, Color(0.55, 0.82, 1.0, lf * 0.82))
				continue
			if wkind == "mana_nova":
				# ── Nova burst: bright central flash + 12 radial energy beams ──────
				draw_circle(wp, 32.0 * lf, Color(0.72, 0.20, 1.0, lf * 0.92))
				draw_circle(wp, 19.0 * lf, Color(0.96, 0.84, 1.0, lf * 0.96))
				for beam in 12:
					var ba: float       = float(beam) / 12.0 * TAU
					var b_end: Vector2  = wp + Vector2(cos(ba), sin(ba)) * wr
					var b_thick: float  = (3.5 - float(beam % 4) * 0.5) * lf
					draw_line(wp, b_end, Color(0.60, 0.12, 1.0, lf * (0.84 - float(beam % 3) * 0.18)), b_thick)
					draw_circle(b_end, 6.0 * lf, Color(0.90, 0.76, 1.0, lf * 0.90))
					draw_circle(wp + Vector2(cos(ba), sin(ba)) * (wr * 0.52), 3.2 * lf, Color(0.78, 0.48, 1.0, lf * 0.70))
				for sp in 18:
					var spa: float = float(sp) / 18.0 * TAU + _elapsed * 2.8
					var spr: float = wr * 0.92 + sin(_elapsed * 7.0 + float(sp)) * 10.0
					draw_circle(wp + Vector2(cos(spa), sin(spa)) * spr, 3.2 * lf, Color(0.96, 0.90, 1.0, lf * 0.82))
			elif wkind == "blink_strike":
				for slash_i in 8:
					var slash_a: float = float(slash_i) / 8.0 * TAU + _elapsed * 0.6
					draw_arc(wp, wr * 0.55 + 40.0 * lf, slash_a, slash_a + 0.22, 14, Color(0.72, 0.32, 1.0, lf * 0.75), 4.0 * lf)
					draw_arc(wp, wr * 0.62 + 44.0 * lf, slash_a + 0.03, slash_a + 0.20, 12, Color(1.0, 0.88, 1.0, lf * 0.35), 1.4)
			elif wkind == "bog_trap":
				for bubble in 16:
					var ba: float = float(bubble) / 16.0 * TAU + _elapsed * 1.2
					var br: float = wr * 0.55 + sin(float(bubble) * 1.7 + lf * 8.0) * 14.0
					draw_circle(wp + Vector2(cos(ba), sin(ba)) * br, 4.5 * lf, Color(0.26, 0.20, 0.08, lf * 0.72))
			elif wkind == "soup_splash":
				for splash in 18:
					var sa2: float = float(splash) / 18.0 * TAU + _elapsed * 0.9
					var sr3: float = wr * 0.45 + sin(float(splash) * 1.2 + _elapsed * 3.0) * 18.0
					draw_circle(wp + Vector2(cos(sa2), sin(sa2)) * sr3, 4.0 * lf, Color(1.0, 0.64, 0.18, lf * 0.78))
					draw_circle(wp, wr * 0.20, Color(1.0, 0.90, 0.42, lf * 0.55))
			elif wkind == "belly_bounce":
				draw_arc(wp, wr + sin(_elapsed * 8.0) * 12.0, 0.0, TAU, 40, Color(0.94, 0.72, 0.46, lf * 0.75), 4.5 * lf)
			elif wkind == "arc_lightning":
				# ── Zigzag lightning bolts forking outward from the center ─────────
				draw_circle(wp, 22.0 * lf, Color(1.0, 0.98, 0.52, lf * 0.82))
				draw_circle(wp, 12.0 * lf, Color(1.0, 1.0, 0.90, lf * 0.96))
				for bolt in 8:
					var ba: float      = float(bolt) / 8.0 * TAU + _elapsed * 0.35
					var bdir: Vector2  = Vector2(cos(ba), sin(ba))
					var bperp: Vector2 = Vector2(-sin(ba), cos(ba))
					var pts: PackedVector2Array = PackedVector2Array()
					pts.append(wp)
					for seg in 6:
						var t: float      = float(seg + 1) / 6.0
						var jitter: float = sin(float(seg) * 2.9 + _elapsed * 26.0 + float(bolt)) * 22.0 * lf
						pts.append(wp + bdir * (wr * t) + bperp * jitter)
					draw_polyline(pts, Color(1.0, 0.98, 0.28, lf * (0.92 - float(bolt % 3) * 0.12)), (2.4 - float(bolt % 3) * 0.4) * lf)
					draw_polyline(pts, Color(1.0, 1.0, 0.92, lf * 0.42), 0.9)
					if pts.size() > 3:
						var fork_pos: Vector2 = pts[3]
						var fork_end: Vector2 = fork_pos + bdir.rotated(0.55) * (wr * 0.24)
						draw_line(fork_pos, fork_end, Color(0.96, 1.0, 0.44, lf * 0.72), 1.5 * lf)
				for i in 10:
					var pa2: float = float(i) / 10.0 * TAU + _elapsed * 3.2
					draw_circle(wp + Vector2(cos(pa2), sin(pa2)) * wr, 3.8 * lf, Color(1.0, 0.98, 0.56, lf * 0.84))
			elif wkind == "crystal_prism":
				# ── Spectrum light refraction — 7 colored beams like a prism ───────
				var spectrum: Array = [
					Color(1.0, 0.18, 0.18), Color(1.0, 0.58, 0.08), Color(1.0, 0.98, 0.18),
					Color(0.18, 0.90, 0.28), Color(0.18, 0.68, 1.0), Color(0.28, 0.18, 1.0), Color(0.72, 0.18, 1.0)
				]
				draw_circle(wp, 20.0 * lf, Color(1.0, 1.0, 1.0, lf * 0.72))
				draw_circle(wp, 11.0 * lf, Color(0.96, 0.98, 1.0, lf * 0.94))
				for si in 7:
					var sa3: float    = float(si) / 7.0 * TAU + 0.3
					var scol: Color   = spectrum[si] as Color
					var bdir: Vector2 = Vector2(cos(sa3), sin(sa3))
					var bperp_c: Vector2 = Vector2(-sin(sa3), cos(sa3))
					var b_end: Vector2  = wp + bdir * wr
					draw_line(wp + bdir * 14.0 * lf, b_end, Color(scol.r, scol.g, scol.b, lf * 0.90), 4.0 * lf)
					draw_line(wp + bdir * 14.0 * lf, b_end, Color(1.0, 1.0, 1.0, lf * 0.32), 1.2)
					var c_tip: Vector2 = b_end + bdir * 14.0 * lf
					draw_colored_polygon(PackedVector2Array([
						b_end - bperp_c * 6.0 * lf, b_end + bperp_c * 6.0 * lf, c_tip
					]), Color(scol.r, scol.g, scol.b, lf * 0.84))
				# Internal sparkle reflections
				for ri2 in 14:
					var ra2: float  = float(ri2) / 14.0 * TAU + _elapsed * 1.8
					var rr2: float  = wr * 0.38 + float(ri2 % 3) * wr * 0.12
					var sc2: Color  = (spectrum[ri2 % 7] as Color).lerp(Color(1.0, 1.0, 1.0), 0.4)
					draw_circle(wp + Vector2(cos(ra2), sin(ra2)) * rr2, 2.2 * lf, Color(sc2.r, sc2.g, sc2.b, lf * 0.74))

			# ── Base shockwave ring (skipped for wizard skills with custom visuals) ──
			var _no_base: bool = wkind in ["mana_nova", "arc_lightning", "crystal_prism"]

			# Core main wave arc with glow-based intensity
			if not _no_base:
				draw_arc(wp, wr, 0.0, TAU, 72, Color(wave_color.r, wave_color.g, wave_color.b, lf * 0.88 * w_glow), (4.5 + float(wlv) * 0.8) * lf)

			# Layered rings with wobble for depth
			var n_rings: int = min(wlv + 1, 5)
			for ri in n_rings:
				if _no_base: continue
				var ring_offset: float = float(ri + 1) * 15.0
				if wr > ring_offset:
					var ring_alpha: float = lf * (0.50 - float(ri) * 0.08) * w_glow
					var wobble_var = sin(_elapsed * (1.0 + w_wobble) + float(ri) * 0.5) * w_wobble * 3.0
					var wobble_wr = wr - ring_offset + wobble_var
					
					var ring_c: Color
					if ri == 0:   ring_c = Color(wave_color.r * 0.7, wave_color.g * 0.8, wave_color.b, ring_alpha)
					elif ri == 1: ring_c = Color(0.88, 0.94, 1.0, ring_alpha * 0.6)
					else:         ring_c = Color(wave_color.r * 0.9, wave_color.g * 0.6, wave_color.b, ring_alpha * 0.4)
					draw_arc(wp, wobble_wr, 0.0, TAU, 48 - ri * 6, ring_c, (3.0 - float(ri) * 0.4) * lf)

			# Particle foam with varied sizes
			var n_foam: int = 16 + wlv * 5
			for i in n_foam:
				if _no_base: continue
				var fa: float      = float(i) / float(n_foam) * TAU
				var foffset: float = sin(float(i) * 2.1 + lf * TAU + w_wobble) * (4.0 + float(wlv) * 1.5)
				var fpos: Vector2  = wp + Vector2(cos(fa), sin(fa)) * (wr + foffset)
				var foam_size = (2.0 + float(wlv) * 0.4) * lf * (0.7 + w_glow * 0.3)
				draw_circle(fpos, foam_size, Color(wave_color.r, wave_color.g, wave_color.b, lf * 0.75 * w_glow))

			# Enhanced lightning/energy traces at high level
			if wlv >= 4 and wr > 30.0 and not _no_base:
				for i in 10:
					var spa: float   = float(i) / 10.0 * TAU + lf * 0.5
					var sp1: Vector2 = wp + Vector2(cos(spa), sin(spa)) * (wr - 8.0)
					var sp2: Vector2 = sp1 + Vector2(cos(spa), sin(spa)) * (18.0 + float(wlv) * 4.0) * lf * (1.0 + w_wobble * 0.5)
					draw_line(sp1, sp2, Color(wave_color.r, wave_color.g, wave_color.b, lf * 0.55 * w_glow), 1.8)

	# Combo chain impacts (line-free)
	for arc in _combo_arcs:
		var lf_arc: float = (arc["life"] as float) / (arc["max_life"] as float)
		var a: Vector2 = arc["a"] as Vector2
		var b: Vector2 = arc["b"] as Vector2
		var col: Color = arc["col"] as Color
		draw_circle(a, 7.0 * lf_arc + 2.0, Color(col.r, col.g, col.b, col.a * lf_arc * 0.65))
		draw_circle(b, 9.0 * lf_arc + 3.0, Color(col.r, col.g, col.b, col.a * lf_arc * 0.85))

	# Arc lightning temporary zaps
	for az in _arc_zaps:
		var zlf: float = (az["life"] as float) / (az["max_life"] as float)
		var za: Vector2 = az["a"] as Vector2
		var zb: Vector2 = az["b"] as Vector2
		var zmid: Vector2 = (za + zb) * 0.5
		var dir_z: Vector2 = (zb - za).normalized()
		var nrm_z: Vector2 = Vector2(-dir_z.y, dir_z.x)
		var j1: Vector2 = za.lerp(zb, 0.28) + nrm_z * sin(_elapsed * 26.0 + za.x * 0.02) * 18.0
		var j2: Vector2 = za.lerp(zb, 0.62) - nrm_z * cos(_elapsed * 24.0 + zb.y * 0.02) * 14.0
		draw_polyline(PackedVector2Array([za, j1, j2, zb]), Color(1.0, 0.96, 0.58, 0.86 * zlf), 3.2)
		draw_polyline(PackedVector2Array([za, zmid, zb]), Color(1.0, 1.0, 0.92, 0.62 * zlf), 1.8)
		draw_circle(za, 6.0 * zlf + 2.0, Color(1.0, 0.96, 0.38, 0.90 * zlf))
		draw_circle(zmid, 8.0 * zlf + 3.0, Color(1.0, 1.0, 0.72, 0.85 * zlf))
		draw_circle(zb, 7.0 * zlf + 2.0, Color(1.0, 1.0, 0.90, 0.90 * zlf))

	# Prism traps and trap-arrow vine lines (line-free)
	for pt in []:
		var plf: float = (pt["life"] as float) / (pt["max_life"] as float)
		var ppts: Array = pt["pts"] as Array
		draw_colored_polygon(PackedVector2Array([ppts[0] as Vector2, ppts[1] as Vector2, ppts[2] as Vector2]), Color(0.46, 0.98, 1.0, 0.16 * plf))
		for i in 3:
			var a: Vector2 = ppts[i]
			draw_circle(a, 8.0, Color(0.70, 1.0, 1.0, 0.70 * plf))
	for gt in []:
		var glf: float = (gt["life"] as float) / (gt["max_life"] as float)
		var ga: Vector2 = gt["a"] as Vector2
		var gb: Vector2 = gt["b"] as Vector2
		for ti in 10:
			var t: float = float(ti) / 9.0
			var p: Vector2 = ga.lerp(gb, t)
			var wiggle: float = sin(_elapsed * 8.0 + float(ti)) * 6.0
			draw_circle(p + Vector2(0.0, wiggle), 2.0, Color(0.86, 1.0, 0.42, 0.70 * glf))
			draw_circle(p + Vector2(0.0, wiggle * 0.5) + Vector2(0.0, -8.0), 1.5, Color(0.62, 0.96, 0.34, 0.58 * glf))

	for vp in []:
		var vlf: float = (vp["life"] as float) / (vp["max_life"] as float)
		draw_circle(vp["pos"] as Vector2, vp["r"] as float, Color(0.18, 0.72, 0.20, 0.24 * vlf))
		draw_circle(vp["pos"] as Vector2, (vp["r"] as float) * 0.65, Color(0.36, 0.90, 0.36, 0.30 * vlf))

	for tm in []:
		var mlf: float = (tm["life"] as float) / (tm["max_life"] as float)
		var mp: Vector2 = tm["pos"] as Vector2
		draw_circle(mp + Vector2(0, 10), 16.0, Color(0.42, 0.26, 0.12, 0.92 * mlf))
		draw_circle(mp, 22.0, Color(0.48, 0.76, 0.24, 0.88 * mlf))
		draw_circle(mp, tm["r"] as float, Color(0.38, 0.88, 0.28, 0.10 * mlf))

	for bp in []:
		var blf: float = (bp["life"] as float) / (bp["max_life"] as float)
		var bpr: float = bp["r"] as float
		var bpp: Vector2 = bp["pos"] as Vector2
		draw_circle(bpp, bpr, Color(0.30, 0.23, 0.12, 0.34 * blf))
		draw_circle(bpp, bpr * 0.72, Color(0.44, 0.34, 0.18, 0.38 * blf))

	for cp in []:
		var clf: float = (cp["life"] as float) / (cp["max_life"] as float)
		var cpr: float = cp["r"] as float
		draw_circle(cp["pos"] as Vector2, cpr, Color(0.20, 0.26, 0.08, 0.28 * clf))
		draw_circle(cp["pos"] as Vector2, cpr * 0.70, Color(0.32, 0.46, 0.12, 0.30 * clf))

	# Hawk companions
	for h in _hawk_companions:
		var hp: Vector2 = h["pos"] as Vector2
		if not _is_world_pos_visible(hp, 80.0):
			continue
		draw_circle(hp, 10.0, Color(0.58, 0.38, 0.12, 0.94))
		draw_circle(hp + Vector2(9.0, -3.0), 5.0, Color(0.66, 0.44, 0.16, 0.95))
		draw_colored_polygon(PackedVector2Array([hp + Vector2(12.0, -2.0), hp + Vector2(20.0, -4.0), hp + Vector2(12.0, 1.0)]), Color(0.92, 0.76, 0.30, 0.95))
		draw_line(hp + Vector2(-2.0, -2.0), hp + Vector2(-16.0, -8.0 + sin(_elapsed * 12.0) * 3.0), Color(0.74, 0.58, 0.22, 0.92), 3.2)
		draw_line(hp + Vector2(-2.0, 2.0), hp + Vector2(-16.0, 8.0 - sin(_elapsed * 12.0) * 3.0), Color(0.74, 0.58, 0.22, 0.92), 3.2)

	# Shadow clones — persistent ghost entities
	for sc in _shadow_clones:
		var scp: Vector2   = sc["pos"] as Vector2
		if not _is_world_pos_visible(scp, 100.0):
			continue
		var sc_hp: float   = clamp((sc["hp"] as float) / max((sc["max_hp"] as float), 0.01), 0.0, 1.0)
		var sc_life: float = clamp((sc["life"] as float) / max((sc["max_life"] as float), 0.01), 0.0, 1.0)
		var sc_bob: float  = sin(_elapsed * 3.2 + scp.x * 0.01) * 5.0
		var sc_pulse: float = 0.55 + 0.45 * sin(_elapsed * 4.0)
		var scdp: Vector2  = scp + Vector2(0.0, sc_bob - 4.0)
		var is_assassin_clone: bool = _char_id == "capy_assassin" and _player_tex != null
		# Outer aura glow (only when not fading out)
		if sc_life > 0.3 and not is_assassin_clone:
			draw_circle(scdp, 46.0 * sc_pulse, Color(0.28, 0.08, 0.52, 0.16))
			draw_arc(scdp, 42.0, 0.0, TAU, 32, Color(0.54, 0.24, 0.92, 0.55 * sc_pulse), 2.8)
		if is_assassin_clone:
			draw_set_transform(scdp, 0.0, Vector2(float(sc.get("facing_x", 1) as int), 1.0))
			draw_texture_rect(_player_tex, Rect2(Vector2(-PLAYER_SPRITE_SIZE * 0.5, -PLAYER_SPRITE_SIZE * 0.5), Vector2(PLAYER_SPRITE_SIZE, PLAYER_SPRITE_SIZE)), false, Color(0.70, 0.42, 1.0, 0.72 * sc_life))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			# Ghost body silhouette (lower dark mass + smaller head)
			draw_circle(scdp, 28.0, Color(0.14, 0.06, 0.28, 0.76))
			draw_circle(scdp, 20.0, Color(0.32, 0.16, 0.54, 0.58))
			draw_circle(scdp + Vector2(0.0, -14.0), 14.0, Color(0.22, 0.10, 0.40, 0.72))
			draw_circle(scdp + Vector2(0.0, -14.0), 10.0, Color(0.38, 0.20, 0.60, 0.50))
		if not is_assassin_clone:
			# Glowing eyes
			var sc_fx: int = sc.get("facing_x", 1) as int
			var eye_ox: float = 4.5 * float(sc_fx)
			draw_circle(scdp + Vector2(eye_ox - 3.5, -16.0), 3.2, Color(0.68, 0.36, 1.0, 0.92))
			draw_circle(scdp + Vector2(eye_ox + 3.5, -16.0), 3.2, Color(0.68, 0.36, 1.0, 0.92))
			draw_circle(scdp + Vector2(eye_ox - 3.5, -16.0), 1.4, Color(1.0, 0.92, 1.0, 0.98))
			draw_circle(scdp + Vector2(eye_ox + 3.5, -16.0), 1.4, Color(1.0, 0.92, 1.0, 0.98))
			# Orbiting dark energy particles
			for p in 5:
				var pa: float = _elapsed * 3.8 + float(p) * TAU / 5.0
				var pr: float = 36.0 + sin(_elapsed * 2.0 + float(p)) * 5.0
				draw_circle(scdp + Vector2(cos(pa), sin(pa)) * pr, 4.2, Color(0.52, 0.20, 0.86, 0.80))
		# HP bar (shown only once damaged)
		if sc_hp < 0.99:
			var bar_w: float = 52.0
			var bar_x: float = scdp.x - bar_w * 0.5
			var bar_y: float = scdp.y + 38.0
			draw_rect(Rect2(bar_x, bar_y, bar_w, 5.0), Color(0.12, 0.06, 0.20, 0.82))
			draw_rect(Rect2(bar_x, bar_y, bar_w * sc_hp, 5.0), Color(0.60, 0.28, 0.92, 0.92))
		# Keep assassin clone fade clean (no extra fade circles).

	# Enemies
	for e in _enemies:
		var ep: Vector2    = e["pos"] as Vector2
		if not _is_world_pos_visible(ep, 180.0):
			continue
		var er: float      = (e["r"] as float) * ENEMY_DRAW_SCALE
		var ec: Color      = e["col"] as Color
		var ekind: String  = e.get("kind", "normal") as String
		var efrozen: bool  = (e.get("iframes", 0.0) as float) > 0.0 and _has_skill("ice_orb")
		var enraged: bool  = (e.get("alive_t", 0.0) as float) >= 8.0
		var marked: bool   = (e.get("tg_mark_t", 0.0) as float) > 0.0
		var poisoned: bool = (e.get("poison_t", 0.0) as float) > 0.0
		# Walk animation — normals bob; bosses stay planted
		var e_alive_t: float = e.get("alive_t", 0.0) as float
		var e_facing_x: int  = e.get("facing_x", 1) as int
		var e_is_boss: bool  = _is_boss_kind(ekind)
		var e_story_tex := _custom_story_enemy_texture(str(e.get("story_tag", "")))
		var e_walk: float    = e_alive_t * 9.0
		var e_bob: float     = 0.0 if e_is_boss else sin(e_walk) * 2.5
		var edp: Vector2     = ep + Vector2(0.0, e_bob)
		# Stubby legs behind body (normals without texture only)
		if not e_is_boss and not _enemy_tex.has(ekind) and e_story_tex == null:
			var e_leg_col: Color = ec.darkened(0.30)
			var e_leg_l: float   = sin(e_walk) * (er * 0.40)
			var e_leg_r: float   = sin(e_walk + PI) * (er * 0.40)
			draw_circle(edp + Vector2(-er * 0.38 * float(e_facing_x), er * 0.60 + e_leg_l), er * 0.27, e_leg_col)
			draw_circle(edp + Vector2( er * 0.38 * float(e_facing_x), er * 0.60 + e_leg_r), er * 0.27, e_leg_col)
		draw_circle(ep + Vector2(3, 5), er - 2.0, Color(0, 0, 0, 0.20))
		var draw_col: Color = Color(0.62, 0.82, 0.95) if efrozen else ec
		if enraged and not efrozen:
			draw_col = ec.lerp(Color(1.0, 0.18, 0.05), 0.55)
		# Draw PNG sprite when an imported enemy or boss image exists, otherwise fallback to shape art.
		var e_has_tex: bool = _enemy_tex.has(ekind) or e_story_tex != null
		if e_has_tex:
			var e_tex_size: float = er * 2.4
			var enemy_squash := 1.0 + sin(e_walk * 2.0) * 0.035 if not e_is_boss else 1.0
			var enemy_tilt := sin(e_walk) * 0.035 if not e_is_boss else 0.0
			draw_set_transform(edp, enemy_tilt * float(e_facing_x), Vector2(float(e_facing_x) / enemy_squash, enemy_squash))
			var enemy_modulate := Color(1, 1, 1, 0.55) if efrozen else Color.WHITE
			if e_story_tex != null:
				draw_texture_rect(e_story_tex, Rect2(Vector2(-e_tex_size * 0.65, -e_tex_size * 0.65), Vector2(e_tex_size * 1.3, e_tex_size * 1.3)), false, enemy_modulate)
			elif not e_is_boss and _enemy_walk_tex.has(ekind):
				var walk_tex := _enemy_walk_tex[ekind] as Texture2D
				var frame := posmod(int(floor(e_alive_t * (11.0 if ekind == "normal_fast" else 7.0))), 4)
				var source_size := walk_tex.get_size()
				var frame_width := source_size.x / 4.0
				var frame_y := maxf((source_size.y - frame_width) * 0.5, 0.0)
				draw_texture_rect_region(
					walk_tex,
					Rect2(Vector2(-e_tex_size * 0.5, -e_tex_size * 0.5), Vector2(e_tex_size, e_tex_size)),
					Rect2(Vector2(frame_width * float(frame), frame_y), Vector2(frame_width, minf(frame_width, source_size.y))),
					enemy_modulate
				)
			else:
				draw_texture_rect(
					_enemy_tex[ekind] as Texture2D,
					Rect2(Vector2(-e_tex_size * 0.5, -e_tex_size * 0.5), Vector2(e_tex_size, e_tex_size)),
					false,
					enemy_modulate
				)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_circle(edp, er, draw_col)
		if str(e.get("story_tag", "")) == "rogue_golem" and float(e.get("hp", 1.0)) / maxf(float(e.get("objective_max_hp", 1.0)), 1.0) <= 0.25:
			draw_circle(edp, er + 15.0, Color(0.24, 1.0, 0.52, 0.12))
			draw_arc(edp, er + 15.0, 0.0, TAU, 32, Color(0.32, 1.0, 0.58, 0.95), 5.0)
		if enraged and ekind in ["normal", "normal_tank", "normal_fast"]:
			# Red pulsing ring to warn player
			var pulse: float = 0.55 + 0.45 * sin(_elapsed * 8.0)
			draw_arc(edp, er + 4.0, 0.0, TAU, 20, Color(1.0, 0.10, 0.05, pulse), 2.5)
		if marked:
			draw_circle(edp, er + 9.0, Color(1.0, 0.96, 0.55, 0.20))
		if poisoned:
			draw_circle(edp, er + 4.0, Color(0.34, 1.0, 0.35, 0.14))
			draw_circle(edp, er + 6.0, Color(0.52, 1.0, 0.40, 0.12))
		var beetle_t: float = e.get("beetle_t", 0.0) as float
		if beetle_t > 0.0:
			var beetle_alpha: float = clamp(beetle_t / 3.0, 0.35, 1.0)
			draw_circle(edp, er + 8.0, Color(0.28, 0.90, 0.20, 0.10 * beetle_alpha))
			for beetle_i in 3:
				var orbit_phase: float = _elapsed * (6.0 + float(beetle_i) * 0.8) + float(beetle_i) * TAU / 3.0
				var orbit_radius: float = er * 0.58 + 6.0 + float(beetle_i) * 4.0
				var beetle_pos: Vector2 = edp + Vector2(cos(orbit_phase), sin(orbit_phase)) * orbit_radius + Vector2(0.0, -er * 0.12)
				var wing_flap: float = 0.6 + 0.4 * sin(_elapsed * 20.0 + float(beetle_i) * 1.7)
				draw_circle(beetle_pos, 4.6, Color(0.14, 0.30, 0.08, 0.92 * beetle_alpha))
				draw_circle(beetle_pos + Vector2(0.0, -1.8), 2.8, Color(0.42, 1.0, 0.24, 0.95 * beetle_alpha))
				draw_circle(beetle_pos + Vector2(-3.2 * wing_flap, -0.6), 1.8, Color(0.72, 1.0, 0.48, 0.72 * beetle_alpha))
				draw_circle(beetle_pos + Vector2(3.2 * wing_flap, -0.6), 1.8, Color(0.72, 1.0, 0.48, 0.72 * beetle_alpha))
				draw_arc(beetle_pos, 6.2, 0.0, TAU, 10, Color(0.68, 0.98, 0.30, 0.42 * beetle_alpha), 1.0)
		var trap_vine_t: float = e.get("trap_vine_t", 0.0) as float
		if trap_vine_t > 0.0:
			var vine_alpha: float = clamp(trap_vine_t / 2.5, 0.25, 1.0)
			for vine_i in 3:
				var va: float = _elapsed * 3.4 + float(vine_i) * TAU / 3.0
				var vp0: Vector2 = edp + Vector2(cos(va), sin(va)) * (er + 3.0)
				var vp1: Vector2 = edp + Vector2(cos(va + 0.9), sin(va + 0.9)) * (er + 3.0)
				draw_line(vp0, vp1, Color(0.56, 0.90, 0.34, 0.86 * vine_alpha), 2.3)
				var thorn: Vector2 = vp0.lerp(vp1, 0.5) + Vector2(-sin(va), cos(va)) * 4.0
				draw_circle(thorn, 1.6, Color(0.86, 1.0, 0.56, 0.90 * vine_alpha))
			for leg_i in 2:
				var leg_side: float = -1.0 if leg_i == 0 else 1.0
				var leg_base: Vector2 = edp + Vector2(leg_side * (er * 0.35), er * 0.55)
				var leg_end: Vector2 = leg_base + Vector2(leg_side * 14.0, 22.0)
				draw_line(leg_base, leg_end, Color(0.36, 0.78, 0.22, 0.82 * vine_alpha), 2.6)
				draw_circle(leg_end, 2.0, Color(0.80, 1.0, 0.58, 0.88 * vine_alpha))
		var bleeding: bool = (e.get("bleed_t", 0.0) as float) > 0.0
		if bleeding:
			var blt: float = clamp((e.get("bleed_t", 0.0) as float) / 4.0, 0.0, 1.0)
			# Red X mark above enemy
			var mx: float = edp.x
			var my: float = edp.y - er - 30.0
			draw_line(Vector2(mx - 12.0, my - 12.0), Vector2(mx + 12.0, my + 12.0), Color(0.90, 0.06, 0.16, blt * 0.96), 4.0)
			draw_line(Vector2(mx + 12.0, my - 12.0), Vector2(mx - 12.0, my + 12.0), Color(0.90, 0.06, 0.16, blt * 0.96), 4.0)
			# Drip drops
			for dri in 3:
				var dp: float  = fmod(_elapsed * 1.8 + float(dri) * 0.7, 1.0)
				var dx: float  = edp.x + (float(dri) - 1.0) * 7.0
				var dy: float  = my + 10.0 + dp * 18.0
				draw_circle(Vector2(dx, dy), (1.5 + (1.0 - dp) * 1.8) * blt, Color(0.86, 0.06, 0.14, blt * (1.0 - dp)))
		# Boss visual indicators
		match ekind:
			"abyss_gate_warden":
				# Cyan cracks/aura
				draw_arc(edp, er + 5.0, 0.0, TAU, 28, Color(0.20, 0.85, 0.95, 0.75), 3.0)
				for ti in 4:
					var tang: float = float(ti) / 4.0 * TAU + _elapsed * 2.8
					draw_circle(edp + Vector2(cos(tang), sin(tang)) * (er + 8.0), 4.5, Color(0.30, 0.92, 1.0, 0.65))
				_draw_boss_name(edp, er, "Abyss Gate Warden", Color(0.28, 0.90, 1.0))
			"prism_triarch":
				var shield_on: bool = e["shield_active"] as bool
				if shield_on:
					draw_arc(edp, er + 7.0, 0.0, TAU, 36, Color(0.90, 0.50, 1.0, 0.88), 4.5)
					draw_circle(edp, er + 7.0, Color(0.85, 0.45, 1.0, 0.16))
				else:
					draw_arc(edp, er + 5.0, 0.0, TAU, 30, Color(0.80, 0.30, 0.95, 0.70), 2.5)
				_draw_boss_name(edp, er, "Prism Triarch", Color(0.88, 0.50, 1.0))
			"blight_vine_tyrant":
				# Green toxic aura
				draw_arc(edp, er + 5.0, 0.0, TAU, 24, Color(0.30, 0.85, 0.25, 0.70), 2.8)
				for ti in 5:
					var tang: float = float(ti) / 5.0 * TAU + _elapsed * 3.2
					draw_circle(edp + Vector2(cos(tang), sin(tang)) * (er + 9.0), 5.0, Color(0.45, 0.95, 0.32, 0.68))
				_draw_boss_name(edp, er, "Blight Vine Tyrant", Color(0.40, 0.92, 0.30))
			"thunderforge_behemoth":
				# Yellow/gold electric aura
				draw_arc(edp, er + 6.0, 0.0, TAU, 32, Color(0.95, 0.75, 0.20, 0.80), 4.0)
				for ti in 6:
					var tang: float = float(ti) / 6.0 * TAU + _elapsed * 3.5
					draw_circle(edp + Vector2(cos(tang), sin(tang)) * (er + 11.0), 5.5, Color(1.0, 0.90, 0.30, 0.72))
				_draw_boss_name(edp, er, "Thunderforge Behemoth", Color(1.0, 0.85, 0.25))
			"teleporter_boss":
				# Purple/magenta teleport aura
				draw_arc(edp, er + 4.0, 0.0, TAU, 26, Color(0.85, 0.35, 0.95, 0.72), 2.8)
				for ti in 4:
					var tang: float = float(ti) / 4.0 * TAU + _elapsed * 4.2
					draw_circle(edp + Vector2(cos(tang), sin(tang)) * (er + 6.0), 3.5, Color(0.95, 0.50, 1.0, 0.60))
				_draw_boss_name(edp, er, "Teleporter Boss", Color(0.90, 0.50, 1.0))
			"shield_boss":
				# Blue shield indicator
				var shield_active: bool = e.get("shield_active", false) as bool
				if shield_active:
					draw_arc(edp, er + 8.0, 0.0, TAU, 40, Color(0.18, 0.72, 0.98, 0.95), 5.0)
					draw_circle(edp, er + 8.0, Color(0.28, 0.82, 1.0, 0.18))
				else:
					draw_arc(edp, er + 4.0, 0.0, TAU, 24, Color(0.18, 0.60, 0.88, 0.60), 2.0)
				_draw_boss_name(edp, er, "Shield Boss", Color(0.28, 0.85, 1.0))
			"shooter_boss":
				# Orange/fire aura with projectile indicators
				draw_arc(edp, er + 5.0, 0.0, TAU, 28, Color(1.0, 0.55, 0.10, 0.75), 3.2)
				for ti in 5:
					var tang: float = float(ti) / 5.0 * TAU + _elapsed * 3.8
					draw_circle(edp + Vector2(cos(tang), sin(tang)) * (er + 8.0), 4.0, Color(1.0, 0.68, 0.22, 0.68))
				_draw_boss_name(edp, er, "Shooter Boss", Color(1.0, 0.72, 0.25))
			"lava_boss":
				# Red fire aura
				draw_arc(edp, er + 5.0, 0.0, TAU, 24, Color(0.95, 0.22, 0.08, 0.78), 3.5)
				for ti in 5:
					var tang: float = float(ti) / 5.0 * TAU + _elapsed * 3.6
					draw_circle(edp + Vector2(cos(tang), sin(tang)) * (er + 7.0), 4.5, Color(1.0, 0.42, 0.12, 0.72))
				_draw_boss_name(edp, er, "Lava Boss", Color(1.0, 0.55, 0.20))
			_:
				# Eye (fallback for any future boss or unknown kind)
				if not e_has_tex:
					draw_circle(edp + Vector2(er * 0.28 * float(e_facing_x), -er * 0.22), er * 0.22, Color(1, 0.9, 0.8))
		var ehp: float  = e["hp"] as float
		var emhp: float = e["max_hp"] as float
		var bw: float = er * 2.6
		var bx: float = edp.x - bw * 0.5
		var by: float = edp.y - er - 18.0
		draw_rect(Rect2(bx, by, bw, 8), Color(0.15, 0.06, 0.06, 0.85))
		var bar_col: Color
		match ekind:
			"abyss_gate_warden":    bar_col = Color(0.28, 0.90, 1.0)
			"prism_triarch":        bar_col = Color(0.88, 0.50, 1.0)
			"blight_vine_tyrant":   bar_col = Color(0.40, 0.92, 0.30)
			"thunderforge_behemoth": bar_col = Color(1.0, 0.85, 0.25)
			"normal_tank":          bar_col = Color(0.88, 0.55, 0.12)
			"normal_fast":          bar_col = Color(0.18, 0.72, 0.98)
			_:                      bar_col = Color(0.88, 0.15, 0.15)
		draw_rect(Rect2(bx, by, bw * clamp(ehp / emhp, 0.0, 1.0), 8), bar_col)
		if poisoned:
			var pi_c: Vector2 = Vector2(edp.x, by - 10.0)
			draw_circle(pi_c, 6.0, Color(0.20, 0.78, 0.22, 0.95))
			draw_circle(pi_c + Vector2(-2.0, -1.5), 2.0, Color(0.80, 1.0, 0.80, 0.95))
			draw_circle(pi_c + Vector2(2.0, -1.5), 2.0, Color(0.80, 1.0, 0.80, 0.95))

	# Lava boss line warnings and eruptions
	for line in _lava_lines:
		var start_pos: Vector2 = line["start"] as Vector2
		var dir: Vector2 = line["dir"] as Vector2
		var end_pos: Vector2 = start_pos + dir * (line["len"] as float)
		var warn_left: float = line["warn_life"] as float
		var width: float = line["width"] as float
		if warn_left > 0.0:
			var pulse2: float = 0.50 + 0.35 * sin(_elapsed * 18.0)
			draw_line(start_pos, end_pos, Color(0.28, 0.10, 0.04, 0.88), width * 0.65)
			draw_line(start_pos, end_pos, Color(1.0, 0.18, 0.04, 0.40 + pulse2 * 0.35), 5.0)
			for ci in 9:
				var t: float = float(ci + 1) / 10.0
				var crack_pos: Vector2 = start_pos.lerp(end_pos, t) + Vector2(-dir.y, dir.x) * sin(float(ci) * 2.4 + _elapsed * 12.0) * 12.0
				draw_circle(crack_pos, 4.0 + pulse2 * 2.0, Color(1.0, 0.42, 0.08, 0.65))
		else:
			var erupt_life: float = clamp((line["life"] as float) / LAVA_LINE_ERUPT_TIME, 0.0, 1.0)
			draw_line(start_pos, end_pos, Color(0.95, 0.05, 0.01, erupt_life * 0.55), width * 1.8)
			draw_line(start_pos, end_pos, Color(1.0, 0.38, 0.02, erupt_life * 0.88), width)
			draw_line(start_pos, end_pos, Color(1.0, 0.90, 0.18, erupt_life * 0.92), width * 0.28)
			for fi in 12:
				var ft: float = float(fi) / 11.0
				var flame_pos: Vector2 = start_pos.lerp(end_pos, ft) + Vector2(-dir.y, dir.x) * sin(_elapsed * 18.0 + float(fi)) * width * 0.35
				draw_circle(flame_pos, 8.0 + sin(_elapsed * 20.0 + float(fi)) * 3.0, Color(1.0, 0.72, 0.12, erupt_life * 0.82))

	# Lava pools
	for lp in _lava_pools:
		var lpp: Vector2  = lp["pos"] as Vector2
		var lplf: float   = (lp["life"] as float) / (lp["max_life"] as float)
		var lpr: float    = lp["r"] as float
		var is_mortar_pool: bool = (lp.get("kind", "lava") as String) == "shooter_mortar"
		if is_mortar_pool:
			draw_circle(lpp, lpr * 1.2, Color(1.0, 0.05, 0.02, lplf * 0.30))
			draw_circle(lpp, lpr, Color(0.82, 0.04, 0.02, lplf * 0.55))
			draw_circle(lpp, lpr * 0.50, Color(1.0, 0.32, 0.10, lplf * 0.70))
		else:
			draw_circle(lpp, lpr * 1.2, Color(0.95, 0.18, 0.01, lplf * 0.35))
			draw_circle(lpp, lpr, Color(1.0, 0.35, 0.02, lplf * 0.60))
			draw_circle(lpp, lpr * 0.55, Color(1.0, 0.72, 0.10, lplf * 0.75))
		# Bubbling dots
		for li in 3:
			var ba: float = _elapsed * 3.0 + float(li) * TAU / 3.0
			var bubble_color: Color = Color(1.0, 0.48, 0.18, lplf * 0.78) if is_mortar_pool else Color(1.0, 0.90, 0.20, lplf * 0.80)
			draw_circle(lpp + Vector2(cos(ba), sin(ba)) * lpr * 0.5, 5.0, bubble_color)

	# Mortar / boss skill strike warnings
	for strike in _mortar_strikes:
		var target: Vector2 = strike["pos"] as Vector2
		var life_left: float = strike["life"] as float
		var max_life: float = strike["max_life"] as float
		var progress: float = clamp(1.0 - life_left / max_life, 0.0, 1.0)
		var radius: float = strike["r"] as float
		var warning_alpha: float = 0.35 + 0.35 * sin(_elapsed * 16.0)
		var strike_kind: String = strike.get("kind", "shooter") as String
		var warn_col: Color
		var arc_col: Color
		match strike_kind:
			"abyss_pulse":
				warn_col = Color(0.20, 0.85, 0.95, 0.14 + warning_alpha * 0.20)
				arc_col  = Color(0.28, 0.90, 1.0, 0.88)
			"blight_root":
				warn_col = Color(0.30, 0.85, 0.25, 0.14 + warning_alpha * 0.20)
				arc_col  = Color(0.40, 0.92, 0.30, 0.88)
			"lightning_strike":
				warn_col = Color(1.0, 0.85, 0.20, 0.14 + warning_alpha * 0.25)
				arc_col  = Color(1.0, 0.90, 0.30, 0.90)
			_:
				warn_col = Color(1.0, 0.05, 0.02, 0.14 + warning_alpha * 0.20)
				arc_col  = Color(1.0, 0.10, 0.04, 0.88)
		draw_circle(target, radius, warn_col)
		draw_arc(target, radius, 0.0, TAU, 36, arc_col, 3.0)
		draw_arc(target, radius * progress, 0.0, TAU, 28, arc_col.lightened(0.2), 2.0)
		# Only shooter-style strikes carry a launch point for the in-flight projectile visual
		if strike.has("launch"):
			var launch: Vector2 = strike["launch"] as Vector2
			var projectile_pos: Vector2 = launch.lerp(target, progress) + Vector2(0.0, -sin(progress * PI) * 220.0 - 35.0 * (1.0 - progress))
			draw_circle(projectile_pos, 11.0, Color(1.0, 0.18, 0.04, 0.88))
			draw_circle(projectile_pos, 6.0, Color(1.0, 0.78, 0.24, 0.95))

	# Boss projectiles
	for bproj in _boss_projs:
		var bpp: Vector2 = bproj["pos"] as Vector2
		var proj_kind: String = bproj.get("kind", "straight") as String
		var outer_col: Color = Color(1.0, 0.08, 0.02, 0.92) if proj_kind == "lava_reflect" else Color(1.0, 0.25, 0.05, 0.88) if proj_kind == "homing" else Color(1.0, 0.55, 0.05, 0.85)
		var projectile_alpha: float = _c1_projectile_flicker_alpha(bproj) if bool(bproj.get("phase_flicker", false)) else 1.0
		outer_col.a *= projectile_alpha
		
		if proj_kind == "prism_beam":
			draw_circle(bpp, 8.0, Color(0.85, 0.50, 1.0, 0.88))
			draw_circle(bpp, 4.0, Color(1.0, 0.85, 1.0, 0.95))
			draw_arc(bpp, 10.0, 0.0, TAU, 12, Color(0.70, 0.30, 1.0, 0.65), 1.5)
		elif proj_kind == "thorn":
			draw_circle(bpp, 9.0, Color(0.40, 0.85, 0.25, 0.85))
			draw_circle(bpp, 5.0, Color(0.70, 1.0, 0.40, 0.90))
			draw_arc(bpp, 11.0, 0.0, TAU, 14, Color(0.30, 0.70, 0.20, 0.60), 1.8)
		else:
			draw_circle(bpp, 12.0, outer_col)
			draw_circle(bpp, 7.0, Color(1.0, 0.90, 0.30, projectile_alpha))
			draw_arc(bpp, 14.0, 0.0, TAU, 16, Color(1.0, 0.35, 0.02, 0.55 * projectile_alpha), 2.0)
		
		if proj_kind == "lava_reflect":
			var target: Vector2 = bproj["target"] as Vector2
			draw_circle(target, bproj.get("explode_r", 58.0) as float, Color(1.0, 0.10, 0.02, 0.12 + 0.10 * sin(_elapsed * 16.0)))
			draw_arc(target, bproj.get("explode_r", 58.0) as float, 0.0, TAU, 28, Color(1.0, 0.22, 0.04, 0.72), 2.5)

	# Boss chains (Abyss Warden)
	for chain in _boss_chains:
		var boss_p: Vector2 = chain.get("boss_pos", Vector2.ZERO) as Vector2
		var direction: Vector2 = chain.get("direction", Vector2.RIGHT) as Vector2
		var length: float = chain.get("length", 120.0) as float
		var state: String = chain.get("state", "extend") as String
		var state_t: float = chain.get("state_t", 0.0) as float
		var current_length: float = length if state == "retract" else length * (state_t / 0.8)
		var end_pos: Vector2 = boss_p + direction * current_length
		var chain_col: Color = Color(0.30, 0.92, 1.0, 0.88) if chain.get("corrupted", false) else Color(0.50, 0.65, 1.0, 0.75)
		draw_line(boss_p, end_pos, chain_col, 4.0)
		draw_circle(end_pos, 6.0, Color(0.70, 1.0, 1.0, 0.95))

	# Prism zones (Prism Triarch)
	for zone in _prism_zones:
		var state: String = zone.get("state", "forming") as String
		if state == "forming":
			var nodes: Array = zone.get("nodes", []) as Array
			if nodes.size() >= 3:
				for i in nodes.size():
					var n1: Vector2 = nodes[i] as Vector2
					var n2: Vector2 = nodes[(i + 1) % nodes.size()] as Vector2
					draw_line(n1, n2, Color(0.85, 0.50, 1.0, 0.80), 3.0)
				var alpha: float = 0.20 + 0.15 * sin(_elapsed * 4.0)
				draw_circle(zone.get("boss_pos", Vector2.ZERO) as Vector2, 75.0, Color(0.70, 0.30, 1.0, alpha))
		elif state == "collapse":
			var state_t: float = zone.get("state_t", 0.0) as float
			var collapse_dur: float = zone.get("collapse_duration", 2.5) as float
			var progress: float = state_t / collapse_dur
			var boss_p: Vector2 = zone.get("boss_pos", Vector2.ZERO) as Vector2
			draw_circle(boss_p, 100.0 + progress * 150.0, Color(1.0, 0.20, 0.80, (1.0 - progress) * 0.60))
			draw_arc(boss_p, 100.0 + progress * 150.0, 0.0, TAU, 32, Color(0.85, 0.20, 1.0, (1.0 - progress) * 0.90), 3.0)

	# Venom pods (Blight Vine Tyrant)
	for pod in _venom_pods:
		var pp: Vector2 = pod["pos"] as Vector2
		var pulse: float = 0.8 + 0.2 * sin(_elapsed * 6.0)
		draw_circle(pp, 9.0 * pulse, Color(0.40, 0.95, 0.30, 0.85))
		draw_circle(pp, 5.0 * pulse, Color(0.70, 1.0, 0.45, 0.92))
		draw_arc(pp, 11.0 * pulse, 0.0, TAU, 12, Color(0.30, 0.80, 0.20, 0.70), 1.5)

	# Lightning markers (Thunderforge Behemoth)
	for marker in _lightning_markers:
		var mp: Vector2 = marker.get("pos", Vector2.ZERO) as Vector2
		var life_ratio: float = (marker["life"] as float) / (marker.get("max_life", 4.0) as float)
		var is_cataclysm: bool = marker.get("cataclysm", false)
		if is_cataclysm:
			var phase: int = marker.get("phase", 0) as int
			var phase_radius: float = 50.0 + float(phase) * 30.0
			var warning: float = 0.40 + 0.40 * sin(_elapsed * 12.0)
			draw_circle(mp, phase_radius, Color(1.0, 0.85, 0.20, 0.15 + warning * 0.20))
			draw_arc(mp, phase_radius, 0.0, TAU, 24, Color(1.0, 0.90, 0.30, 0.80), 2.5)
		else:
			draw_circle(mp, 8.0, Color(1.0, 0.85, 0.20, 0.90))
			draw_circle(mp, 4.0, Color(1.0, 1.0, 0.50, 0.95))
			draw_arc(mp, 10.0, 0.0, TAU, 16, Color(1.0, 0.70, 0.10, 0.70 * life_ratio), 1.5)

	# Thorn patches (Blight Vine Tyrant)
	for patch in _thorn_patches:
		var pp: Vector2 = patch.get("pos", Vector2.ZERO) as Vector2
		var pr: float = patch.get("r", 35.0) as float
		var life_ratio: float = (patch["life"] as float) / (patch.get("max_life", 3.0) as float)
		draw_circle(pp, pr, Color(0.40, 0.95, 0.30, 0.25 + 0.15 * sin(_elapsed * 5.0)))
		draw_arc(pp, pr, 0.0, TAU, 20, Color(0.30, 0.80, 0.20, 0.75 * life_ratio), 2.0)
		for ti in 5:
			var ta: float = float(ti) / 5.0 * TAU + _elapsed * 2.0
			draw_circle(pp + Vector2(cos(ta), sin(ta)) * pr * 0.7, 3.5, Color(0.70, 1.0, 0.40, 0.80))

	# Potions
	for p in _potions:
		var pp: Vector2 = p["pos"] as Vector2
		if not _is_world_pos_visible(pp, 60.0):
			continue
		var pulse: float = 0.82 + sin(_elapsed * 5.0) * 0.18
		draw_circle(pp, 14.0 * pulse, Color(0.15, 0.80, 0.25, 0.30))
		draw_circle(pp, 10.0 * pulse, Color(0.25, 0.95, 0.40))
		draw_circle(pp, 5.0 * pulse, Color(0.70, 1.0, 0.72, 0.90))
		draw_string(ThemeDB.fallback_font, pp + Vector2(-12, -24), "+HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.30, 1.0, 0.45))

	# Ring drops
	for rd in _ring_drops:
		var rp: Vector2 = rd["pos"] as Vector2
		if not _is_world_pos_visible(rp, 80.0):
			continue
		var rpulse: float = 0.80 + sin(_elapsed * 4.0) * 0.20
		draw_arc(rp, 14.0 * rpulse, 0.0, TAU, 24, Color(0.98, 0.82, 0.15, 0.90), 3.5)
		draw_arc(rp, 8.0 * rpulse, 0.0, TAU, 16, Color(1.0, 0.95, 0.55, 0.55), 2.0)
		draw_string(ThemeDB.fallback_font, rp + Vector2(-18, -32), "\u25c6 Ring", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1.0, 0.88, 0.25))

	# Artifact drops
	for ad in _artifact_drops:
		var ap: Vector2 = ad["pos"] as Vector2
		if not _is_world_pos_visible(ap, 80.0):
			continue
		var apulse: float = 0.80 + sin(_elapsed * 3.5) * 0.20
		draw_arc(ap, 14.0 * apulse, 0.0, TAU, 24, Color(0.98, 0.82, 0.15, 0.90), 3.5)
		draw_arc(ap, 8.0 * apulse, 0.0, TAU, 16, Color(1.0, 0.95, 0.55, 0.55), 2.0)
		var artifact_label_pos: Vector2 = Vector2(ap.x - 56.0, ap.y - 28.0)
		draw_string(ThemeDB.fallback_font, artifact_label_pos + Vector2(-24.0, 0.0), "\u25c6 Artifact", HORIZONTAL_ALIGNMENT_CENTER, 160.0, 26, Color(1.0, 0.88, 0.25))

	# AOE flashes (drawn after enemies for dramatic screen overlay)
	for fl in []:
		var flf: float    = (fl["life"] as float) / (fl["max_life"] as float)
		var fkind: String = fl["kind"] as String
		var fpos: Vector2 = fl.get("pos", _player_pos) as Vector2
		if fkind == "soup_splash":
			var cdir: Vector2 = fl.get("dir", Vector2(float(_player_facing_x), 0.0)) as Vector2
			var cr: float = fl.get("cone_r", 380.0) as float
			var ca: float = fl.get("cone_angle", deg_to_rad(20.0)) as float
			var p1: Vector2 = fpos
			var p2: Vector2 = fpos + cdir.rotated(-ca * 0.5) * cr
			var p3: Vector2 = fpos + cdir.rotated(ca * 0.5) * cr
			draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color(1.0, 0.66, 0.24, flf * 0.26))
			continue
		if fkind == "blizzard":
			draw_circle(_player_pos, 2400.0, Color(0.75, 0.92, 1.0, flf * 0.28))
			draw_arc(_player_pos, 1800.0, 0.0, TAU, 64, Color(0.55, 0.82, 1.0, flf * 0.45), 9.0 * flf)
			for i in 45:
				var sa: float   = float(i) / 45.0 * TAU + _elapsed * 0.4
				var sd: float   = 80.0 + float(i) * 38.0 + sin(_elapsed * 3.0 + float(i)) * 55.0
				var sp2: Vector2 = _player_pos + Vector2(cos(sa), sin(sa)) * sd
				draw_circle(sp2, 5.0 * flf, Color(0.90, 0.97, 1.0, flf * 0.80))
				for arm in 4:
					var aa: float    = float(arm) / 4.0 * TAU
					var aend: Vector2 = sp2 + Vector2(cos(aa), sin(aa)) * (9.0 * flf)
					draw_line(sp2, aend, Color(1.0, 1.0, 1.0, flf * 0.65), 1.5)
		elif fkind == "sky_fall":
			for i in 55:
				var ax: float     = _player_pos.x - 960.0 + float(i) * 35.0 + sin(float(i) * 0.7) * 25.0
				var progress: float = fmod((1.0 - flf) * 2.8 + float(i) * 0.025, 1.0)
				var ay_start: float = _player_pos.y - 1300.0 + progress * 3200.0
				var ay_end: float   = ay_start + 38.0
				var alpha: float    = flf * 0.72 * (1.0 - abs(progress - 0.5) * 1.6)
				if alpha > 0.05:
					draw_line(Vector2(ax, ay_start), Vector2(ax, ay_end), Color(0.30, 0.72, 0.20, alpha), 2.5)
					draw_circle(Vector2(ax, ay_end), 3.5 * flf, Color(0.22, 0.90, 0.25, alpha))
		elif fkind == "seven_slash":
			for si in 7:
				var slash_prog: float = clamp((1.0 - flf) * 4.0 - float(si) * 0.14, 0.0, 1.0)
				if slash_prog <= 0.0: continue
				var slash_a: float = -PI * 0.28 + float(si) * 0.07
				var base_y: float  = _player_pos.y - 1100.0 + float(si) * 340.0
				var base_x: float  = _player_pos.x - 1300.0 + float(si) * 55.0
				var s_start: Vector2 = Vector2(base_x, base_y)
				var s_end: Vector2   = s_start + Vector2(cos(slash_a), sin(slash_a)) * 2600.0 * slash_prog
				draw_line(s_start, s_end, Color(0.92, 0.18, 0.28, flf * 0.80), 7.0 * flf)
				draw_line(s_start, s_end, Color(1.0, 0.62, 0.68, flf * 0.40), 2.0)
		elif fkind == "swirl_tangerine":
			# Full-screen tangerine cyclone: spiral arms + screen wash + particles
			draw_circle(_player_pos, 2400.0, Color(1.0, 0.55, 0.05, flf * 0.20))
			var n_arms: int = 6
			for arm in n_arms:
				var arm_base_a: float = float(arm) / float(n_arms) * TAU + _elapsed * 3.5
				var pts: PackedVector2Array = PackedVector2Array()
				for seg in 14:
					var t: float    = float(seg) / 13.0
					var r: float    = t * 2200.0
					var a: float    = arm_base_a + t * TAU * 1.6
					pts.append(_player_pos + Vector2(cos(a), sin(a)) * r)
				if pts.size() > 1:
					draw_polyline(pts, Color(1.0, 0.55 + arm * 0.04, 0.05, flf * 0.75), (5.0 - float(arm) * 0.3) * flf)
					draw_polyline(pts, Color(1.0, 0.85, 0.40, flf * 0.35), 1.5 * flf)
			for i in 60:
				var pa: float   = float(i) / 60.0 * TAU + _elapsed * 2.2
				var pr: float   = (100.0 + float(i) * 32.0 + sin(_elapsed * 5.0 + float(i)) * 55.0) * (1.0 + (1.0 - flf) * 0.8)
				var pp2: Vector2 = _player_pos + Vector2(cos(pa), sin(pa)) * pr
				draw_circle(pp2, (6.0 + sin(float(i) * 0.9) * 3.0) * flf, Color(1.0, 0.60 + float(i % 3) * 0.12, 0.05, flf * 0.85))
			for ra in 3:
				var rr: float = 400.0 + float(ra) * 600.0
				draw_arc(_player_pos, rr, 0.0, TAU, 32, Color(1.0, 0.72, 0.10, flf * (0.55 - float(ra) * 0.12)), (6.0 - float(ra)) * flf)
		elif fkind == "time_warp":
			draw_circle(fpos, 300.0 * flf + 60.0, Color(0.46, 0.60, 1.0, flf * 0.18))
			for tick in 12:
				var ta: float = float(tick) / 12.0 * TAU + _elapsed * 0.9
				draw_arc(fpos, 180.0 + float(tick) * 6.0, ta, ta + 0.36, 10, Color(0.66, 0.84, 1.0, flf * 0.70), 2.0)
				draw_arc(fpos, 220.0 * flf + 30.0, 0.0, TAU, 36, Color(0.88, 0.94, 1.0, flf * 0.75), 3.0 * flf)
		elif fkind == "trap_arrow":
			for spike in 18:
				var sa: float = float(spike) / 18.0 * TAU + _elapsed * 1.0
				var outer: Vector2 = fpos + Vector2(cos(sa), sin(sa)) * (280.0 + float(spike) * 6.0)
				draw_arc(fpos, 210.0 + float(spike) * 4.0, sa, sa + 0.10, 10, Color(0.36, 0.72, 0.16, flf * 0.78), 2.4)
				draw_circle(outer, 4.0 * flf, Color(0.92, 0.96, 0.30, flf * 0.82))
		elif fkind == "blink_trail":
			var s_pos: Vector2 = fl.get("pos", _player_pos) as Vector2
			var e_pos: Vector2 = fl.get("end_pos", _player_pos) as Vector2
			draw_line(s_pos, e_pos, Color(0.42, 0.18, 0.90, flf * 0.78), 6.0 * flf)
			draw_line(s_pos, e_pos, Color(0.72, 0.52, 1.0, flf * 0.50), 2.0)
			draw_circle(e_pos, 28.0 * flf, Color(0.48, 0.22, 0.92, flf * 0.52))
			draw_arc(e_pos, 32.0 * flf, 0.0, TAU, 24, Color(0.66, 0.42, 1.0, flf * 0.88), 3.2 * flf)
			for sp3 in 6:
				var spa3: float = float(sp3) / 6.0 * TAU + _elapsed * 4.5
				draw_circle(e_pos + Vector2(cos(spa3), sin(spa3)) * (26.0 * flf), 3.0 * flf, Color(0.84, 0.68, 1.0, flf * 0.80))
		elif fkind == "smoke_bomb":
			draw_circle(fpos, 320.0 * flf + 50.0, Color(0.54, 0.52, 0.60, flf * 0.22))
			for cloud in 16:
				var ca: float = float(cloud) / 16.0 * TAU + _elapsed * 0.7
				draw_circle(fpos + Vector2(cos(ca), sin(ca)) * (110.0 + float(cloud) * 8.0), 10.0 * flf, Color(0.68, 0.66, 0.72, flf * 0.55))
				draw_circle(fpos + Vector2(cos(ca), sin(ca)) * (155.0 + float(cloud) * 8.0), 5.0 * flf, Color(0.84, 0.82, 0.90, flf * 0.55))
		elif fkind == "hawk_companion":
			draw_circle(fpos, 260.0 * flf, Color(1.0, 0.78, 0.28, flf * 0.25))
			for wing in 6:
				var wa: float = float(wing) / 6.0 * TAU + _elapsed * 4.0
				draw_arc(fpos, 110.0 + flf * 90.0, wa, wa + 0.22, 12, Color(0.82, 0.52, 0.12, flf * 0.80), 3.0)
		elif fkind == "shadow_clone":
			for sh in 7:
				var sa: float = float(sh) / 7.0 * TAU + _elapsed * 3.0
				draw_circle(fpos + Vector2(cos(sa), sin(sa)) * (120.0 + float(sh) * 8.0), 14.0 * flf, Color(0.24, 0.12, 0.42, flf * 0.35))
		elif fkind == "leech_vine":
			for vine in 8:
				var va: float = float(vine) / 8.0 * TAU + _elapsed * 1.8
				draw_arc(fpos, 140.0 + sin(_elapsed * 6.0 + float(vine)) * 25.0, va, va + 0.28, 12, Color(0.28, 0.68, 0.18, flf * 0.70), 2.4)
		elif fkind == "friendly_aura":
			draw_circle(fpos, 180.0 + sin(_elapsed * 5.0) * 18.0, Color(1.0, 0.82, 0.50, flf * 0.18))
			for heart in 5:
				var ha: float = float(heart) / 5.0 * TAU + _elapsed * 0.8
				draw_circle(fpos + Vector2(cos(ha), sin(ha)) * (120.0 + float(heart) * 12.0), 6.0 * flf, Color(1.0, 0.88, 0.64, flf * 0.85))
		elif fkind == "corruption_field":
			draw_circle(fpos, 320.0 * flf + 40.0, Color(0.18, 0.36, 0.06, flf * 0.24))
			for blob in 14:
				var ba: float = float(blob) / 14.0 * TAU + _elapsed * 1.4
				draw_circle(fpos + Vector2(cos(ba), sin(ba)) * (140.0 + sin(_elapsed * 4.0 + float(blob)) * 22.0), 5.0 * flf, Color(0.38, 0.82, 0.16, flf * 0.80))
		elif fkind == "venom_plague":
			draw_circle(fpos, 280.0 * flf + 30.0, Color(0.22, 0.88, 0.18, flf * 0.20))
			for spore in 10:
				var spa: float = float(spore) / 10.0 * TAU + _elapsed * 2.0
				draw_circle(fpos + Vector2(cos(spa), sin(spa)) * (110.0 + float(spore) * 8.0), 5.0 * flf, Color(0.76, 1.0, 0.36, flf * 0.82))
		elif fkind == "healing_feast":
			draw_circle(fpos, 220.0 * flf + 30.0, Color(1.0, 0.86, 0.42, flf * 0.18))
			for crumb in 8:
				var ca: float = float(crumb) / 8.0 * TAU + _elapsed * 1.6
				draw_circle(fpos + Vector2(cos(ca), sin(ca)) * (90.0 + float(crumb) * 10.0), 5.0 * flf, Color(1.0, 0.72, 0.24, flf * 0.80))
		elif fkind == "lucky_clover":
			draw_arc(fpos, 200.0 * flf + 20.0, 0.0, TAU, 28, Color(0.42, 1.0, 0.42, flf * 0.85), 3.0 * flf)
			for leaf in 4:
				var la: float = float(leaf) / 4.0 * TAU + _elapsed * 1.2
				draw_circle(fpos + Vector2(cos(la), sin(la)) * (110.0 + float(leaf) * 6.0), 10.0 * flf, Color(0.28, 0.88, 0.38, flf * 0.75))

		elif fkind == "meatball_barrage":
			draw_circle(fpos, 240.0 * flf + 80.0, Color(0.74, 0.48, 0.24, flf * 0.30))
			draw_arc(fpos, 180.0 + flf * 90.0, 0.0, TAU, 32, Color(0.90, 0.62, 0.32, flf * 0.70), 4.0)
			for mb in 12:
				var mba: float = float(mb) / 12.0 * TAU + _elapsed * 2.2
				var mbp: Vector2 = fpos + Vector2(cos(mba), sin(mba)) * (100.0 + flf * 140.0)
				draw_circle(mbp, 8.0, Color(0.96, 0.70, 0.34, flf * 0.85))
			draw_arc(fpos, 320.0 + flf * 140.0, 0.0, TAU, 48, Color(0.88, 0.60, 0.28, flf * 0.45), 2.0)
		elif fkind == "meatball_barrage":
			draw_circle(fpos, 240.0 * flf + 80.0, Color(0.74, 0.48, 0.24, flf * 0.30))
			draw_arc(fpos, 180.0 + flf * 90.0, 0.0, TAU, 32, Color(0.90, 0.62, 0.32, flf * 0.70), 4.0)
			for mb in 12:
				var mba: float = float(mb) / 12.0 * TAU + _elapsed * 2.2
				var mbp: Vector2 = fpos + Vector2(cos(mba), sin(mba)) * (100.0 + flf * 140.0)
				draw_circle(mbp, 8.0, Color(0.96, 0.70, 0.34, flf * 0.85))
			draw_arc(fpos, 320.0 + flf * 140.0, 0.0, TAU, 48, Color(0.88, 0.60, 0.28, flf * 0.45), 2.0)
		elif fkind == "master_kitchen":
			var from_pos: Vector2 = fl.get("from_pos", fpos) as Vector2
			var to_pos: Vector2 = fl.get("to_pos", fpos + (fl.get("dir", Vector2.RIGHT) as Vector2) * (fl.get("r", 240.0) as float)) as Vector2
			var t: float = clamp(1.0 - flf, 0.0, 1.0)
			var head: Vector2 = from_pos.lerp(to_pos, t)
			var dirk: Vector2 = (to_pos - from_pos).normalized()
			if dirk.length_squared() < 0.0001:
				dirk = Vector2.RIGHT
			var perp: Vector2 = Vector2(-dirk.y, dirk.x)
			var utensil: String = fl.get("utensil", "knife") as String
			var streak_col: Color = Color(1.0, 0.78, 0.34, flf * 0.64)
			if utensil == "knife":
				streak_col = Color(0.92, 0.95, 1.0, flf * 0.68)
			elif utensil == "spoon" or utensil == "soup" or utensil == "shoup":
				streak_col = Color(0.98, 0.88, 0.56, flf * 0.68)
			elif utensil == "spatula" or utensil == "board":
				streak_col = Color(0.80, 0.56, 0.28, flf * 0.68)
			elif utensil == "hat":
				streak_col = Color(0.98, 0.96, 0.86, flf * 0.68)
			elif utensil == "fork" or utensil == "grater":
				streak_col = Color(0.88, 0.92, 1.0, flf * 0.68)
			elif utensil == "hotdog" or utensil == "meatball" or utensil == "pizza":
				streak_col = Color(1.0, 0.60, 0.24, flf * 0.70)
			draw_line(head - dirk * 46.0 * flf, head, streak_col, 3.2)
			if utensil == "knife":
				draw_line(head - dirk * 18.0, head + dirk * 9.0, Color(0.88, 0.92, 0.98, flf * 0.94), 3.2)
				draw_line(head - dirk * 18.0 - perp * 3.0, head - dirk * 18.0 + perp * 3.0, Color(0.56, 0.34, 0.16, flf * 0.90), 2.2)
			elif utensil == "spoon" or utensil == "soup" or utensil == "shoup":
				draw_line(head - dirk * 20.0, head, Color(0.90, 0.90, 0.96, flf * 0.90), 2.6)
				draw_circle(head + dirk * 4.0, 6.0, Color(1.0, 0.78, 0.38, flf * 0.92))
			elif utensil == "spatula":
				draw_line(head - dirk * 24.0, head - dirk * 2.0, Color(0.64, 0.42, 0.20, flf * 0.90), 2.4)
				draw_colored_polygon(PackedVector2Array([head + perp * 7.0, head - perp * 7.0, head - dirk * 16.0 - perp * 7.0, head - dirk * 16.0 + perp * 7.0]), Color(0.82, 0.84, 0.90, flf * 0.90))
			elif utensil == "board":
				draw_colored_polygon(PackedVector2Array([head + dirk * 9.0 + perp * 8.0, head + dirk * 9.0 - perp * 8.0, head - dirk * 13.0 - perp * 8.0, head - dirk * 13.0 + perp * 8.0]), Color(0.74, 0.50, 0.28, flf * 0.92))
			elif utensil == "hat":
				draw_arc(head, 8.0, PI, TAU, 14, Color(1.0, 1.0, 1.0, flf * 0.92), 2.6)
				draw_line(head - perp * 10.0, head + perp * 10.0, Color(0.98, 0.92, 0.84, flf * 0.92), 2.2)
			elif utensil == "fork":
				draw_line(head - dirk * 24.0, head + dirk * 4.0, Color(0.90, 0.92, 0.98, flf * 0.92), 2.2)
				for pr in 3:
					var ofs: float = (float(pr) - 1.0) * 3.4
					draw_line(head + perp * ofs, head + dirk * 9.0 + perp * ofs, Color(0.90, 0.92, 0.98, flf * 0.92), 1.6)
			elif utensil == "grater":
				draw_colored_polygon(PackedVector2Array([head + dirk * 8.0 + perp * 7.0, head + dirk * 8.0 - perp * 7.0, head - dirk * 10.0 - perp * 7.0, head - dirk * 10.0 + perp * 7.0]), Color(0.78, 0.82, 0.90, flf * 0.90))
				for gh in 4:
					var ghp: Vector2 = head - dirk * (7.0 - float(gh) * 4.0)
					draw_circle(ghp + perp * 2.6, 1.2, Color(0.56, 0.62, 0.74, flf * 0.92))
					draw_circle(ghp - perp * 2.6, 1.2, Color(0.56, 0.62, 0.74, flf * 0.92))
			elif utensil == "whisk":
				draw_line(head - dirk * 24.0, head - dirk * 4.0, Color(0.72, 0.54, 0.28, flf * 0.90), 2.4)
				draw_arc(head + dirk * 1.0, 6.0, 0.0, TAU, 18, Color(0.92, 0.94, 1.0, flf * 0.90), 1.2)
				draw_arc(head + dirk * 1.0, 4.0, 0.0, TAU, 14, Color(0.92, 0.94, 1.0, flf * 0.90), 1.2)
			elif utensil == "hotdog":
				draw_colored_polygon(PackedVector2Array([head + dirk * 10.0 + perp * 5.0, head + dirk * 10.0 - perp * 5.0, head - dirk * 10.0 - perp * 5.0, head - dirk * 10.0 + perp * 5.0]), Color(0.96, 0.72, 0.36, flf * 0.90))
				draw_line(head - dirk * 9.0, head + dirk * 9.0, Color(0.84, 0.22, 0.16, flf * 0.95), 2.2)
			elif utensil == "meatball":
				draw_circle(head, 6.5, Color(0.66, 0.26, 0.16, flf * 0.94))
				draw_circle(head + dirk * 2.0, 2.0, Color(0.92, 0.68, 0.42, flf * 0.70))
			elif utensil == "pizza":
				draw_colored_polygon(PackedVector2Array([head + dirk * 10.0, head - dirk * 7.0 + perp * 7.0, head - dirk * 7.0 - perp * 7.0]), Color(1.0, 0.78, 0.38, flf * 0.92))
				draw_arc(head + dirk * 8.0, 4.2, -0.9, 0.9, 8, Color(0.86, 0.26, 0.16, flf * 0.95), 1.6)
			draw_circle(head, 2.2, Color(1.0, 0.96, 0.78, flf * 0.92))
		elif fkind == "phantom_hunt":
			for arw in 18:
				var pa: float = float(arw) / 18.0 * TAU + _elapsed * 2.1
				draw_arc(fpos, 240.0 + float(arw) * 10.0, pa, pa + 0.12, 10, Color(0.50, 0.94, 0.82, flf * 0.70), 2.0)
		elif fkind == "thousand_blades":
			# Swords radiating outward from center
			draw_circle(fpos, 52.0 * flf, Color(0.88, 0.06, 0.16, flf * 0.32))
			draw_circle(fpos, 28.0 * flf, Color(1.0, 0.62, 0.68, flf * 0.55))
			for sl in 14:
				var sa4: float    = float(sl) / 14.0 * TAU + _elapsed * 2.5
				var bdir: Vector2 = Vector2(cos(sa4), sin(sa4))
				var bperp: Vector2 = Vector2(-sin(sa4), cos(sa4))
				var b_base: float  = 46.0 + float(sl % 3) * 10.0
				var b_tip: float   = b_base + 88.0 * flf
				var guard_r: float = b_base + 11.0
				var handle_r: float = b_base - 13.0 * flf
				# Blade body
				draw_line(fpos + bdir * b_base, fpos + bdir * b_tip,
						Color(0.92, 0.10, 0.22, flf * 0.92), 3.5 * flf)
				draw_line(fpos + bdir * (b_base + 8.0), fpos + bdir * b_tip,
						Color(1.0, 0.72, 0.76, flf * 0.56), 1.2)
				# Crossguard
				draw_line(fpos + bdir * guard_r - bperp * 9.0 * flf,
						fpos + bdir * guard_r + bperp * 9.0 * flf,
						Color(0.82, 0.78, 0.90, flf * 0.90), 2.5 * flf)
				# Handle
				draw_line(fpos + bdir * handle_r, fpos + bdir * b_base,
						Color(0.36, 0.26, 0.16, flf * 0.84), 2.8 * flf)
				# Tip sparkle
				draw_circle(fpos + bdir * b_tip, 2.8 * flf, Color(1.0, 0.88, 0.90, flf * 0.92))
		elif fkind == "toxic_mushroom":
			draw_circle(fpos, 260.0 * flf + 40.0, Color(0.32, 0.70, 0.12, flf * 0.18))
			for puff in 18:
				var pa5: float = float(puff) / 18.0 * TAU + _elapsed * 0.8
				draw_circle(fpos + Vector2(cos(pa5), sin(pa5)) * (110.0 + float(puff) * 7.0), 6.0 * flf, Color(0.52, 0.98, 0.22, flf * 0.80))
		elif fkind == "chili_explosion":
			draw_circle(fpos, 340.0 * flf + 70.0, Color(1.0, 0.22, 0.05, flf * 0.26))
			for flame in 16:
				var fa: float = float(flame) / 16.0 * TAU + _elapsed * 2.4
				draw_circle(fpos + Vector2(cos(fa), sin(fa)) * (120.0 + float(flame) * 9.0), 5.0 * flf, Color(1.0, 0.62, 0.12, flf * 0.80))
		elif fkind == "meatball_barrage":
			draw_circle(fpos, 240.0 * flf + 80.0, Color(0.74, 0.48, 0.24, flf * 0.30))
			draw_arc(fpos, 180.0 + flf * 90.0, 0.0, TAU, 32, Color(0.90, 0.62, 0.32, flf * 0.70), 4.0)
			for mb in 12:
				var mba: float = float(mb) / 12.0 * TAU + _elapsed * 2.2
				var mbp: Vector2 = fpos + Vector2(cos(mba), sin(mba)) * (100.0 + flf * 140.0)
				draw_circle(mbp, 8.0, Color(0.96, 0.70, 0.34, flf * 0.85))
			draw_arc(fpos, 320.0 + flf * 140.0, 0.0, TAU, 48, Color(0.88, 0.60, 0.28, flf * 0.45), 2.0)
		elif fkind == "master_kitchen":
			draw_circle(fpos, 320.0 * flf + 50.0, Color(1.0, 0.64, 0.20, flf * 0.18))
			for utensil in 8:
				var ua: float = float(utensil) / 8.0 * TAU + _elapsed * 1.5
				draw_arc(fpos, 180.0 + float(utensil) * 10.0, ua, ua + 0.20, 12, Color(1.0, 0.78, 0.34, flf * 0.70), 2.4)
		elif fkind == "phantom_hunt":
			for arw in 18:
				var pa: float = float(arw) / 18.0 * TAU + _elapsed * 2.1
				draw_arc(fpos, 240.0 + float(arw) * 10.0, pa, pa + 0.12, 10, Color(0.50, 0.94, 0.82, flf * 0.70), 2.0)
		elif fkind == "thousand_blades":
			# Swords radiating outward from center (duplicate draw block — unified)
			draw_circle(fpos, 52.0 * flf, Color(0.88, 0.06, 0.16, flf * 0.32))
			draw_circle(fpos, 28.0 * flf, Color(1.0, 0.62, 0.68, flf * 0.55))
			for sl in 14:
				var sa4: float    = float(sl) / 14.0 * TAU + _elapsed * 2.5
				var bdir: Vector2 = Vector2(cos(sa4), sin(sa4))
				var bperp: Vector2 = Vector2(-sin(sa4), cos(sa4))
				var b_base: float  = 46.0 + float(sl % 3) * 10.0
				var b_tip: float   = b_base + 88.0 * flf
				var guard_r: float = b_base + 11.0
				var handle_r: float = b_base - 13.0 * flf
				draw_line(fpos + bdir * b_base, fpos + bdir * b_tip,
						Color(0.92, 0.10, 0.22, flf * 0.92), 3.5 * flf)
				draw_line(fpos + bdir * (b_base + 8.0), fpos + bdir * b_tip,
						Color(1.0, 0.72, 0.76, flf * 0.56), 1.2)
				draw_line(fpos + bdir * guard_r - bperp * 9.0 * flf,
						fpos + bdir * guard_r + bperp * 9.0 * flf,
						Color(0.82, 0.78, 0.90, flf * 0.90), 2.5 * flf)
				draw_line(fpos + bdir * handle_r, fpos + bdir * b_base,
						Color(0.36, 0.26, 0.16, flf * 0.84), 2.8 * flf)
				draw_circle(fpos + bdir * b_tip, 2.8 * flf, Color(1.0, 0.88, 0.90, flf * 0.92))
		elif fkind == "toxic_mushroom":
			draw_circle(fpos, 260.0 * flf + 40.0, Color(0.32, 0.70, 0.12, flf * 0.18))
			for puff in 18:
				var pa5: float = float(puff) / 18.0 * TAU + _elapsed * 0.8
				draw_circle(fpos + Vector2(cos(pa5), sin(pa5)) * (110.0 + float(puff) * 7.0), 6.0 * flf, Color(0.52, 0.98, 0.22, flf * 0.80))
		elif fkind == "chili_explosion":
			draw_circle(fpos, 340.0 * flf + 70.0, Color(1.0, 0.22, 0.05, flf * 0.26))
			for flame in 16:
				var fa: float = float(flame) / 16.0 * TAU + _elapsed * 2.4
				draw_circle(fpos + Vector2(cos(fa), sin(fa)) * (120.0 + float(flame) * 9.0), 5.0 * flf, Color(1.0, 0.62, 0.12, flf * 0.80))

	# ── Draw Capy Charge shadow rushes ────────────────────────────────────────
	for rush in []:
		var rush_pos: Vector2 = (rush["pos"] as Vector2)
		var rush_life: float = (rush["life"] as float) / (rush["max_life"] as float)
		var rush_alpha: float = rush_life * 0.85
		# Shadow capy body
		draw_circle(rush_pos, 32.0, Color(0.88, 0.70, 0.44, rush_alpha * 0.7))
		# Trail effect
		for trail_i in 3:
			var trail_offset: float = float(trail_i) * 40.0
			var trail_pos: Vector2 = rush_pos - (rush["dir"] as Vector2) * trail_offset
			draw_circle(trail_pos, 24.0 - trail_i * 6.0, Color(0.98, 0.82, 0.50, rush_alpha * 0.4))
		# Impact rings
		var ring_r: float = 60.0 + sin(_elapsed * 12.0) * 20.0
		draw_arc(rush_pos, ring_r, 0.0, TAU, 16, Color(0.76, 0.56, 0.28, rush_alpha * 0.6), 3.0)

	# ── Draw Stampede centipedes (realistic millipede creatures) ────────────────────────────────────
	for centipede in []:
		var cent_pos: Vector2 = (centipede["pos"] as Vector2)
		var cent_life: float = (centipede["life"] as float) / (centipede["max_life"] as float)
		var cent_alpha: float = cent_life * 0.90
		
		# Calculate movement direction
		var start_pos: Vector2 = centipede.get("start_pos", _player_pos) as Vector2
		var cent_dir: Vector2 = (cent_pos - start_pos).normalized()
		if cent_dir.length_squared() < 0.01:
			var spawn_angle: float = centipede.get("spawn_angle", 0.0) as float
			cent_dir = Vector2(cos(spawn_angle), sin(spawn_angle))
		
		# Draw body as thick, segmented creature (wide segments, not thin tail)
		var num_segments: int = 10
		var segment_spacing: float = 16.0
		var max_width: float = 28.0
		
		# Draw segments from back to front (so head appears on top)
		for seg in range(num_segments - 1, -1, -1):
			var seg_offset: float = float(seg) * segment_spacing
			var seg_pos: Vector2 = cent_pos - cent_dir * seg_offset
			
			# Segment gets smaller toward tail
			var seg_ratio: float = float(seg) / float(num_segments)
			var seg_alpha: float = cent_alpha * (0.9 - seg_ratio * 0.4)
			var seg_width: float = max_width * (1.0 - seg_ratio * 0.5)
			
			# Draw thick segment (main body)
			draw_circle(seg_pos, seg_width * 0.55, Color(0.85, 0.18, 0.12, seg_alpha))
			
			# Segment ridges for texture
			if seg % 2 == 0:
				draw_circle(seg_pos, seg_width * 0.35, Color(1.0, 0.25, 0.15, seg_alpha * 0.6))
			
			# Many legs - perpendicular to body, every segment
			var leg_count: int = 4
			for leg_i in range(leg_count):
				var leg_angle_offset: float = PI / float(leg_count + 1) * float(leg_i + 1)
				
				# Left side legs
				var leg_angle_l: float = cent_dir.angle() + PI/2.0 + leg_angle_offset
				var leg_length: float = 18.0 + float(leg_i) * 2.0
				var left_leg: Vector2 = seg_pos + Vector2(cos(leg_angle_l), sin(leg_angle_l)) * leg_length
				draw_line(seg_pos, left_leg, Color(0.80, 0.12, 0.08, seg_alpha * 0.8), 2.8)
				draw_circle(left_leg, 2.5, Color(0.95, 0.15, 0.10, seg_alpha * 0.9))
				
				# Right side legs  
				var leg_angle_r: float = cent_dir.angle() - PI/2.0 - leg_angle_offset
				var right_leg: Vector2 = seg_pos + Vector2(cos(leg_angle_r), sin(leg_angle_r)) * leg_length
				draw_line(seg_pos, right_leg, Color(0.80, 0.12, 0.08, seg_alpha * 0.8), 2.8)
				draw_circle(right_leg, 2.5, Color(0.95, 0.15, 0.10, seg_alpha * 0.9))
		
		# Head - large, rounded, distinctive
		draw_circle(cent_pos, 22.0, Color(1.0, 0.22, 0.16, cent_alpha))
		draw_circle(cent_pos, 20.0, Color(1.0, 0.28, 0.20, cent_alpha * 0.8))
		
		# Antennae
		var antenna_l: Vector2 = cent_pos + Vector2(cos(cent_dir.angle() + 0.3), sin(cent_dir.angle() + 0.3)) * 28.0
		var antenna_r: Vector2 = cent_pos + Vector2(cos(cent_dir.angle() - 0.3), sin(cent_dir.angle() - 0.3)) * 28.0
		draw_line(cent_pos, antenna_l, Color(0.90, 0.25, 0.15, cent_alpha * 0.7), 2.0)
		draw_line(cent_pos, antenna_r, Color(0.90, 0.25, 0.15, cent_alpha * 0.7), 2.0)
		draw_circle(antenna_l, 3.0, Color(1.0, 0.30, 0.20, cent_alpha * 0.8))
		draw_circle(antenna_r, 3.0, Color(1.0, 0.30, 0.20, cent_alpha * 0.8))
		
		# Eyes
		var eye_dist: float = 12.0
		var eye_side: float = 7.0
		var left_eye: Vector2 = cent_pos + Vector2(cos(cent_dir.angle()), sin(cent_dir.angle())) * eye_dist + Vector2(cos(cent_dir.angle() + PI/2.0), sin(cent_dir.angle() + PI/2.0)) * eye_side
		var right_eye: Vector2 = cent_pos + Vector2(cos(cent_dir.angle()), sin(cent_dir.angle())) * eye_dist - Vector2(cos(cent_dir.angle() + PI/2.0), sin(cent_dir.angle() + PI/2.0)) * eye_side
		draw_circle(left_eye, 3.5, Color(0.15, 0.15, 0.15, cent_alpha * 0.9))
		draw_circle(right_eye, 3.5, Color(0.15, 0.15, 0.15, cent_alpha * 0.9))

	# Legacy skill rendering is replaced by _draw_revamped_skill_effects().
	if false and _has_skill("orb"):
		var od: Dictionary = _slvl("orb", _get_skill("orb")["level"] as int)
		var n: int = od["orbs"] as int
		var orbit_r: float = _capy_orb_orbit_radius()
		var hit_r: float = _capy_orb_hit_radius()
		for i in n:
			var ang: float  = _orb_angle + float(i) * TAU / float(n)
			var op: Vector2 = _player_pos + Vector2(cos(ang), sin(ang)) * orbit_r
			draw_circle(op, hit_r, Color(0.98, 0.72, 0.08))
			draw_arc(op, hit_r, 0.0, TAU, 16, Color(1.0, 0.9, 0.4, 0.7), 2.0)

	# Fire trails — lingering flame on the ground (simplified for performance)
	for ft in []:
		var ftp: Vector2  = ft["pos"] as Vector2
		var ftlf: float   = (ft["life"] as float) / (ft["max_life"] as float)
		var ftr: float    = (ft["r"] as float) * (0.5 + ftlf * 0.5)
		draw_circle(ftp, ftr * 1.5, Color(1.0, 0.28, 0.02, ftlf * 0.22))
		draw_circle(ftp, ftr, Color(1.0, 0.52, 0.05, ftlf * 0.50))
		draw_circle(ftp, ftr * 0.42, Color(1.0, 0.90, 0.38, ftlf * 0.65))

	# Fireballs — projectile with flame tail
	for fb in []:
		var fbp: Vector2  = fb["pos"] as Vector2
		var fbv: Vector2  = (fb["vel"] as Vector2).normalized()
		var perp: Vector2 = Vector2(-fbv.y, fbv.x)
		var fblf: float   = clamp((fb["life"] as float) / 4.0, 0.0, 1.0)
		var is_plasma: bool = (fb.get("kind", "fireball") as String) == "inferno_plasma"
		if is_plasma:
			# Inferno Thunder orb: no trail, pure fire + thunder swirling core.
			var pulse: float = 0.86 + 0.14 * sin(_elapsed * 15.0 + fbp.x * 0.03)
			draw_circle(fbp, 17.0 * pulse, Color(0.28, 0.66, 1.0, 0.28 * fblf))
			draw_circle(fbp, 15.0 * pulse, Color(1.0, 0.34, 0.06, 0.36 * fblf))
			# Fire half
			draw_circle(fbp + Vector2(-3.2, 0.8), 11.0, Color(1.0, 0.42, 0.05, 0.86))
			draw_circle(fbp + Vector2(-5.0, 1.8), 7.0, Color(1.0, 0.82, 0.18, 0.88))
			# Thunder half
			draw_circle(fbp + Vector2(3.2, -0.8), 11.0, Color(0.24, 0.54, 1.0, 0.88))
			draw_circle(fbp + Vector2(5.0, -1.8), 7.0, Color(0.78, 0.88, 1.0, 0.92))
			# Lightning cracks inside orb
			for li in 3:
				var a0: float = _elapsed * 9.0 + float(li) * TAU / 3.0
				var p0: Vector2 = fbp + Vector2(cos(a0), sin(a0)) * 4.0
				var p1: Vector2 = fbp + Vector2(cos(a0 + 0.7), sin(a0 + 0.7)) * 10.5
				var p2: Vector2 = fbp + Vector2(cos(a0 + 1.2), sin(a0 + 1.2)) * 7.2
				draw_polyline(PackedVector2Array([p0, p1, p2]), Color(0.90, 0.98, 1.0, 0.94 * fblf), 2.0)
			# Fiery swirl rings
			draw_arc(fbp, 10.8, _elapsed * 2.8, _elapsed * 2.8 + PI * 1.18, 22, Color(1.0, 0.72, 0.20, 0.78 * fblf), 2.1)
			draw_arc(fbp, 9.2, _elapsed * 2.8 + PI, _elapsed * 2.8 + PI + PI * 0.98, 20, Color(0.62, 0.84, 1.0, 0.82 * fblf), 1.8)
			draw_circle(fbp, 4.6, Color(1.0, 0.96, 0.86, 0.98))
		else:
			# Flame tail — tapering behind the ball
			var tail_pts: PackedVector2Array = PackedVector2Array()
			for s in 10:
				var td: float    = float(s + 1) * 9.0
				var taper: float = float(10 - s) / 10.0
				var jitter: float = sin(float(s) * 1.9 + _elapsed * 25.0) * taper * 5.0
				tail_pts.append(fbp - fbv * td + perp * jitter)
			# Outer orange glow tail
			draw_polyline(tail_pts, Color(1.0, 0.35, 0.02, 0.40), 10.0)
			# Inner yellow core tail
			draw_polyline(tail_pts, Color(1.0, 0.80, 0.15, 0.65), 4.0)
			# Fireball head — glowing orb
			draw_circle(fbp, 12.0 + sin(_elapsed * 20.0) * 1.5, Color(1.0, 0.35, 0.02, 0.45))
			draw_circle(fbp, 9.0, Color(1.0, 0.55, 0.05))
			draw_circle(fbp, 5.0, Color(1.0, 0.92, 0.40, 0.95))
		# Spark flickers around head
		for sp in 4:
			var sa: float   = _elapsed * 14.0 + float(sp) * TAU / 4.0
			var sr: float   = 10.0 + sin(_elapsed * 18.0 + float(sp)) * 3.0
			var spos: Vector2 = fbp + Vector2(cos(sa), sin(sa)) * sr
			draw_circle(spos, 2.5, Color(1.0, 0.70, 0.10, 0.75))

	# Bolts — kind-aware draw
	for b in []:
		var bp: Vector2   = b["pos"] as Vector2
		var bv: Vector2   = (b["vel"] as Vector2).normalized()
		var perp: Vector2 = Vector2(-bv.y, bv.x)
		var bkind: String = b.get("kind", "bolt") as String
		if bkind == "arcane_missile":
			draw_arc(bp, 14.0, 0.0, TAU, 24, Color(0.68, 0.20, 1.0, 0.80), 2.2)
			draw_circle(bp, 7.0, Color(0.82, 0.40, 1.0, 0.88))
			for mi in 3:
				var ma: float = _elapsed * 12.0 + float(mi) * TAU / 3.0
				draw_circle(bp + Vector2(cos(ma), sin(ma)) * 8.0, 1.5, Color(0.90, 0.60, 1.0, 0.90))
		elif bkind == "ricochet_arrow":
			# Bomb-shaped ricochet arrow with fuse spark
			draw_circle(bp, 8.0, Color(0.12, 0.12, 0.12, 0.96))
			draw_circle(bp + Vector2(-2.0, -2.0), 2.0, Color(0.42, 0.42, 0.42, 0.80))
			var fuse_base: Vector2 = bp - bv * 6.0 + perp * 5.0
			var fuse_tip: Vector2 = fuse_base - bv * 7.0 + perp * 2.0
			draw_line(fuse_base, fuse_tip, Color(0.60, 0.45, 0.20, 0.95), 1.8)
			var spark_a: float = _elapsed * 18.0
			draw_circle(fuse_tip + Vector2(cos(spark_a), sin(spark_a)) * 1.8, 2.2, Color(1.0, 0.74, 0.22, 0.95))
			draw_circle(fuse_tip, 1.3, Color(1.0, 0.94, 0.62, 0.98))
			draw_arc(bp, 11.0, 0.0, TAU, 16, Color(0.95, 0.62, 0.18, 0.48), 1.4)
		elif bkind == "shadow_dagger":
			draw_circle(bp, 7.0, Color(0.24, 0.10, 0.42, 0.92))
			draw_arc(bp, 12.0, 0.0, TAU, 20, Color(0.66, 0.50, 1.0, 0.50), 1.8)
		elif bkind == "bleed_mark":
			draw_arc(bp, 12.0, 0.0, TAU, 16, Color(1.0, 0.40, 0.46, 0.76), 2.2)
			draw_circle(bp, 5.2, Color(1.0, 0.74, 0.78, 0.92))
		elif bkind == "poison_arrow":
			draw_arc(bp, 11.0, 0.0, TAU, 20, Color(0.42, 1.0, 0.22, 0.78), 1.8)
			draw_circle(bp, 5.5, Color(0.22, 0.82, 0.12, 0.95))
			for puff in 4:
				var pa: float = _elapsed * 11.0 + float(puff) * TAU / 4.0
				draw_circle(bp + Vector2(cos(pa), sin(pa)) * 8.5, 1.3, Color(0.76, 1.0, 0.34, 0.80))
		elif bkind == "plague_beetles":
			var beetle_phase: float = _elapsed * 10.0
			for beetle_i in 3:
				var bite: float = float(beetle_i) * TAU / 3.0 + beetle_phase
				var offset: Vector2 = Vector2(cos(bite), sin(bite)) * (5.0 + float(beetle_i) * 2.2)
				var beetle_pos: Vector2 = bp + offset
				var shell_col: Color = Color(0.22, 0.14, 0.05, 0.96)
				var toxin_col: Color = Color(0.42, 0.98, 0.24, 0.92)
				draw_circle(beetle_pos, 5.5, shell_col)
				draw_circle(beetle_pos + Vector2(0.0, -2.6), 3.0, toxin_col)
				draw_arc(beetle_pos, 7.0, 0.2, TAU - 0.2, 8, Color(0.68, 0.90, 0.18, 0.65), 1.2)
				for leg in 4:
					var la: float = bite + PI * 0.25 + float(leg) * 0.7
					var leg_a: Vector2 = beetle_pos + Vector2(cos(la), sin(la)) * 2.0
					var leg_b: Vector2 = beetle_pos + Vector2(cos(la), sin(la)) * 6.5
					draw_line(leg_a, leg_b, Color(0.30, 0.82, 0.24, 0.80), 1.0)
				draw_circle(beetle_pos + Vector2(0.0, -5.5), 1.2, Color(0.84, 1.0, 0.42, 0.9))
				draw_circle(beetle_pos + Vector2(-1.8, -4.8), 0.9, Color(0.84, 1.0, 0.42, 0.75))
		elif bkind == "flying_pan":
			draw_arc(bp, 12.0, 0.0, TAU, 18, Color(0.96, 0.84, 0.56, 0.80), 2.0)
			draw_circle(bp, 8.0, Color(0.78, 0.60, 0.40, 0.95))
			draw_arc(bp, 10.0, 0.0, TAU, 18, Color(0.96, 0.84, 0.56, 0.80), 2.0)
		elif bkind == "meatball_barrage":
			draw_circle(bp, 8.5, Color(0.62, 0.30, 0.12, 0.95))
			draw_circle(bp, 5.0, Color(0.95, 0.70, 0.36, 0.82))
		if bkind == "arrow" or bkind == "split_arrow":
			var arrow_len: float = 30.0
			var tail: Vector2 = bp - bv * arrow_len
			draw_line(tail, bp, Color(0.52, 0.38, 0.18, 0.75), 3.0)
			draw_line(tail, bp, Color(0.30, 0.66, 0.22, 0.85), 1.5)
			var aleft:  Vector2 = bp + perp * 5.5
			var aright: Vector2 = bp - perp * 5.5
			var atip:   Vector2 = bp + bv * 9.0
			draw_colored_polygon(PackedVector2Array([aleft, aright, atip]), Color(0.28, 0.72, 0.22))
			draw_line(tail, tail + perp * 7.0, Color(0.85, 0.80, 0.65, 0.65), 2.0)
			draw_line(tail, tail - perp * 7.0, Color(0.85, 0.80, 0.65, 0.65), 2.0)
		elif bkind == "star_knife":
			var spin_a: float = _elapsed * 9.0
			for pt in 4:
				var sa: float    = spin_a + float(pt) * TAU / 4.0
				var p1: Vector2 = bp + Vector2(cos(sa), sin(sa)) * (BOLT_R + 4.0)
				var p2: Vector2 = bp - Vector2(cos(sa), sin(sa)) * (BOLT_R - 2.0)
				draw_line(p1, p2, Color(0.88, 0.85, 0.98, 0.90), 2.5)
			draw_circle(bp, BOLT_R * 0.5, Color(0.70, 0.68, 0.82, 0.90))
		elif bkind == "divine_volley":
			draw_arc(bp, 12.0, 0.0, TAU, 18, Color(0.40, 0.90, 0.30, 0.70), 2.6)
			draw_circle(bp, 4.8, Color(0.98, 1.0, 0.80, 0.95))
			draw_circle(bp, 9.5, Color(0.88, 1.0, 0.58, 0.20))
			for glow_i in 3:
				var ga: float = _elapsed * 10.0 + float(glow_i) * TAU / 3.0
				draw_circle(bp + Vector2(cos(ga), sin(ga)) * 7.0, 1.7, Color(0.70, 1.0, 0.62, 0.75))
		elif bkind == "poison_arrow":
			for drip in 3:
				var da: float = _elapsed * 12.0 + float(drip) * TAU / 3.0
				draw_circle(bp + Vector2(cos(da), sin(da)) * 8.0, 1.6, Color(0.76, 1.0, 0.34, 0.78))
		elif bkind == "shadow_dagger":
			for st in 4:
				var sa: float = _elapsed * 14.0 + float(st) * TAU / 4.0
				draw_line(bp + Vector2(cos(sa), sin(sa)) * 4.0, bp + Vector2(cos(sa), sin(sa)) * 10.0, Color(0.46, 0.22, 0.86, 0.50), 1.2)
		elif bkind == "bleed_mark":
			for spill in 4:
				var spa: float = _elapsed * 9.0 + float(spill) * TAU / 4.0
				draw_circle(bp + Vector2(cos(spa), sin(spa)) * 9.0, 1.8, Color(0.86, 0.08, 0.18, 0.72))
		elif bkind == "flying_pan":
			draw_circle(bp + perp * 4.5, 2.5, Color(0.50, 0.34, 0.18, 0.90))
		elif bkind == "meatball_barrage":
			for sauce_i in 4:
				var sauce_a: float = _elapsed * 9.0 + float(sauce_i) * TAU / 4.0
				draw_circle(bp + Vector2(cos(sauce_a), sin(sauce_a)) * 7.5, 1.4, Color(0.88, 0.20, 0.10, 0.70))
		elif bkind == "hawk_feather":
			draw_line(bp - bv * 15.0, bp + bv * 8.0, Color(0.90, 0.84, 0.66, 0.92), 2.5)
			draw_line(bp - bv * 12.0 + perp * 6.0, bp + bv * 4.0, Color(0.96, 0.90, 0.74, 0.72), 1.4)
			draw_line(bp - bv * 12.0 - perp * 6.0, bp + bv * 4.0, Color(0.96, 0.90, 0.74, 0.72), 1.4)
			draw_circle(bp + bv * 8.0, 2.2, Color(1.0, 0.96, 0.88, 0.90))
		elif bkind == "phantom_hunt":
			# Brighter white phantom arrow with glow
			draw_line(bp - bv * 18.0, bp + bv * 12.0, Color(0.98, 0.98, 1.0, 0.95), 3.5)
			draw_line(bp - bv * 18.0, bp + bv * 12.0, Color(1.0, 1.0, 1.0, 0.85), 1.8)
			var ph_left: Vector2 = bp + perp * 6.0
			var ph_right: Vector2 = bp - perp * 6.0
			var ph_tip: Vector2 = bp + bv * 14.0
			draw_colored_polygon(PackedVector2Array([ph_left, ph_right, ph_tip]), Color(1.0, 1.0, 1.0, 0.98))
			draw_arc(bp, 12.0, 0.0, TAU, 20, Color(0.92, 0.96, 1.0, 0.48), 1.8)
			draw_circle(bp, 5.0, Color(1.0, 1.0, 1.0, 0.25))
		elif bkind == "phantom_homing":
			# White hunting orbs that chase enemies
			draw_circle(bp, 8.0, Color(1.0, 1.0, 1.0, 0.92))
			draw_circle(bp, 4.5, Color(1.0, 1.0, 1.0, 0.98))
			draw_arc(bp, 9.0, 0.0, TAU, 16, Color(0.85, 0.90, 1.0, 0.60), 1.2)
			for glow_i in 3:
				var ga: float = _elapsed * 12.0 + float(glow_i) * TAU / 3.0
				draw_circle(bp + Vector2(cos(ga), sin(ga)) * 6.0, 2.0, Color(0.95, 0.98, 1.0, 0.55))
		elif bkind == "trap_arrow":
			# Bigger green vine arrow
			draw_line(bp - bv * 20.0, bp + bv * 12.0, Color(0.25, 0.48, 0.10, 0.92), 4.0)
			draw_line(bp - bv * 20.0, bp + bv * 12.0, Color(0.68, 0.95, 0.28, 0.75), 1.8)
			var tv_left: Vector2 = bp + perp * 7.0
			var tv_right: Vector2 = bp - perp * 7.0
			var tv_tip: Vector2 = bp + bv * 15.0
			draw_colored_polygon(PackedVector2Array([tv_left, tv_right, tv_tip]), Color(0.58, 0.98, 0.32, 0.98))
			for thorn in 5:
				var ta: float = _elapsed * 7.0 + float(thorn) * TAU / 5.0
				draw_circle(bp + Vector2(cos(ta), sin(ta)) * 9.0, 1.8, Color(0.75, 1.0, 0.40, 0.72))
			draw_arc(bp, 11.0, 0.0, TAU, 16, Color(0.60, 0.92, 0.25, 0.45), 1.5)
		elif bkind.begins_with("tb_"):
			var tb_style: int = bkind.substr(3).to_int()
			match tb_style:
				0:  # slim dagger
					draw_line(bp + bv * 22.0, bp - bv * 8.0, Color(0.92, 0.10, 0.22, 0.92), 2.6)
					draw_line(bp + bv * 22.0, bp - bv * 8.0, Color(1.0, 0.72, 0.76, 0.56), 1.0)
					draw_circle(bp + bv * 22.0, 3.5, Color(1.0, 0.88, 0.90, 0.90))
				1:  # wide blade
					draw_colored_polygon(PackedVector2Array([
						bp + bv * 24.0, bp + perp * 6.5 - bv * 6.0, bp - perp * 6.5 - bv * 6.0
					]), Color(0.88, 0.10, 0.20, 0.88))
					draw_colored_polygon(PackedVector2Array([
						bp + bv * 24.0, bp + perp * 3.0, bp - perp * 3.0
					]), Color(1.0, 0.75, 0.78, 0.60))
				2:  # throwing star
					for pt in 4:
						var pa_s: float = _elapsed * 15.0 + float(pt) * TAU / 4.0
						draw_line(bp + Vector2(cos(pa_s), sin(pa_s)) * 8.0,
								  bp - Vector2(cos(pa_s), sin(pa_s)) * 8.0, Color(0.86, 0.12, 0.22, 0.90), 2.4)
					draw_circle(bp, 3.5, Color(1.0, 0.80, 0.82, 0.92))
				3:  # rapier + guard
					draw_line(bp + bv * 26.0, bp - bv * 10.0, Color(0.96, 0.18, 0.28, 0.90), 1.5)
					draw_line(bp - perp * 8.0 - bv * 2.0, bp + perp * 8.0 - bv * 2.0, Color(0.78, 0.72, 0.86, 0.82), 1.6)
					draw_circle(bp + bv * 26.0, 2.5, Color(1.0, 0.85, 0.88, 0.90))
		else:
			# Default: yellow lightning bolt
			var trail: PackedVector2Array = PackedVector2Array()
			trail.append(bp)
			for s in 8:
				var tp: Vector2   = bp - bv * float(s + 1) * 8.0
				var jitter: float = sin(float(s) * 2.3 + _elapsed * 38.0) * (5.0 + float(s) * 0.8)
				trail.append(tp + perp * jitter)
			draw_polyline(trail, Color(1.0, 0.72, 0.05, 0.45), 6.0)
			draw_polyline(trail, Color(1.0, 0.95, 0.60, 0.95), 2.0)
			var f1_root: Vector2 = bp - bv * 18.0
			var fork1: PackedVector2Array = PackedVector2Array()
			fork1.append(f1_root)
			fork1.append(f1_root + (bv + perp * 0.8).normalized() * 14.0)
			fork1.append(f1_root + (bv + perp * 0.8).normalized() * 26.0 + perp * 3.0)
			draw_polyline(fork1, Color(1.0, 0.88, 0.20, 0.60), 1.5)
			var f2_root: Vector2 = bp - bv * 30.0
			var fork2: PackedVector2Array = PackedVector2Array()
			fork2.append(f2_root)
			fork2.append(f2_root + (bv - perp * 0.6).normalized() * 12.0)
			fork2.append(f2_root + (bv - perp * 0.6).normalized() * 20.0 - perp * 4.0)
			draw_polyline(fork2, Color(1.0, 0.75, 0.05, 0.45), 1.2)
			draw_circle(bp, 4.5, Color(1.0, 1.0, 0.80, 0.90))

	# Ice Orbs
	for b in []:
		var bp: Vector2  = b["pos"] as Vector2
		var fr: float    = b["freeze_r"] as float
		var blv: int     = b["lvl"] as int
		var _lf: float   = clamp((b["life"] as float) / ICE_ORB_LIFE, 0.0, 1.0)
		draw_arc(bp, fr, 0.0, TAU, 36, Color(0.70, 0.92, 1.0, 0.18 + float(blv) * 0.04), 1.5)
		var n_shards: int = 5 + blv
		for i in n_shards:
			var sa: float    = float(i) / float(n_shards) * TAU + _elapsed * (1.8 + float(blv) * 0.3)
			var sr: float    = ICE_ORB_R + 5.0 + float(blv) * 1.5
			var sp: Vector2  = bp + Vector2(cos(sa), sin(sa)) * sr
			var sp2: Vector2 = bp + Vector2(cos(sa), sin(sa)) * (sr + 6.0 + float(blv) * 1.0)
			draw_line(sp, sp2, Color(0.85, 0.96, 1.0, 0.80), 2.0)
		draw_circle(bp, ICE_ORB_R + 4.0, Color(0.55, 0.88, 1.0, 0.30))
		draw_circle(bp, ICE_ORB_R, Color(0.30 - float(blv) * 0.03, 0.70 + float(blv) * 0.03, 1.0))
		draw_circle(bp, ICE_ORB_R * 0.45, Color(0.88, 0.97, 1.0, 0.90))

	# Pierce Arrows
	for b in []:
		var bp: Vector2   = b["pos"] as Vector2
		var bv: Vector2   = (b["vel"] as Vector2).normalized()
		var perp: Vector2 = Vector2(-bv.y, bv.x)
		var pb_kind: String = b.get("kind", "pierce_arrow") as String
		var tail: Vector2 = bp - bv * 34.0
		if pb_kind == "frozen_lance":
			draw_line(tail, bp, Color(0.62, 0.95, 1.0, 0.42), 9.5)
			draw_line(tail, bp, Color(0.90, 0.98, 1.0, 0.88), 3.0)
			var spear_base: Vector2 = bp - bv * 7.0
			var crystal_a: Vector2 = spear_base + perp * 7.0
			var crystal_b: Vector2 = spear_base - perp * 7.0
			var crystal_tip: Vector2 = bp + bv * 14.0
			draw_colored_polygon(PackedVector2Array([crystal_a, crystal_b, crystal_tip]), Color(0.84, 0.98, 1.0, 0.95))
			draw_arc(bp, 8.5, 0.0, TAU, 18, Color(0.70, 0.95, 1.0, 0.65), 1.6)
		else:
			draw_line(tail, bp, Color(0.28, 0.90, 0.55, 0.35), 9.0)
			draw_line(tail, bp, Color(0.28, 0.82, 0.48, 0.88), 2.5)
			var aleft:  Vector2 = bp + perp * 5.5
			var aright: Vector2 = bp - perp * 5.5
			var atip:   Vector2 = bp + bv * 10.0
			draw_colored_polygon(PackedVector2Array([aleft, aright, atip]), Color(0.22, 0.96, 0.60))

	# Boomerangs
	for b in []:
		var bp: Vector2 = b["pos"] as Vector2
		var spin_a: float = _elapsed * 9.0
		for pt in 5:
			var sa: float   = spin_a + float(pt) * TAU / 5.0
			var p1: Vector2 = bp + Vector2(cos(sa), sin(sa)) * (BOLT_R + 5.0)
			var p2: Vector2 = bp + Vector2(cos(sa + PI / 5.0), sin(sa + PI / 5.0)) * (BOLT_R * 0.35)
			draw_line(p1, p2, Color(0.96, 0.88, 0.24, 0.90), 2.5)
		draw_circle(bp, 5.0, Color(1.0, 0.95, 0.45, 0.82))
		draw_circle(bp, 3.0, Color(1.0, 1.0, 0.80, 0.90))

	_draw_revamped_skill_effects()

	# Player walk animation
	var p_is_moving: bool = _player_move_dir.length_squared() > 0.0
	var p_walk: float     = _elapsed * 11.0
	var p_bob: float      = sin(p_walk) * 3.0 if p_is_moving else 0.0
	var p_leg_l: float    = sin(p_walk) * 7.0 if p_is_moving else 0.0
	var p_leg_r: float    = sin(p_walk + PI) * 7.0 if p_is_moving else 0.0
	var pdp: Vector2      = _player_pos + Vector2(0.0, p_bob - _player_jump_vel_y * 0.5)  # Jump offset
	var p_draw_r: float = PLAYER_DRAW_R
	# Legs drawn behind body
	var p_leg_col: Color = _player_tint.darkened(0.28)
	draw_circle(pdp + Vector2(-12.0, p_draw_r * 0.52 + p_leg_l), 7.0, p_leg_col)
	draw_circle(pdp + Vector2( 12.0, p_draw_r * 0.52 + p_leg_r), 7.0, p_leg_col)
	# Shadow
	draw_circle(_player_pos + Vector2(4, 8), p_draw_r - 4.0, Color(0, 0, 0, 0.22))
	# Player — portrait sprite or fallback circles
	if _player_tex != null:
		var player_squash := 1.0 + sin(p_walk * 2.0) * 0.045 if p_is_moving else 1.0
		var player_tilt := sin(p_walk) * 0.04 if p_is_moving else 0.0
		draw_set_transform(pdp, player_tilt * float(_player_facing_x), Vector2(float(_player_facing_x) / player_squash, player_squash))
		if _player_walk_tex != null:
			var sheet_size := _player_walk_tex.get_size()
			var player_frame_count: int = 4
			var player_frame := posmod(int(floor(_elapsed * 8.0)), player_frame_count) if p_is_moving else 0
			var player_frame_width := sheet_size.x / float(player_frame_count)
			var player_frame_y := maxf((sheet_size.y - player_frame_width) * 0.5, 0.0)
			var player_frame_offset := Vector2.ZERO
			if _char_id == "capy_brown":
				var brown_frame_offsets: Array[float] = [-19.6, -0.4, -7.0, 20.4]
				player_frame_offset.x = brown_frame_offsets[player_frame]
			draw_texture_rect_region(
				_player_walk_tex,
				Rect2(Vector2(-PLAYER_SPRITE_SIZE * 0.5, -PLAYER_SPRITE_SIZE * 0.5) + player_frame_offset, Vector2(PLAYER_SPRITE_SIZE, PLAYER_SPRITE_SIZE)),
				Rect2(Vector2(player_frame_width * float(player_frame), player_frame_y), Vector2(player_frame_width, minf(player_frame_width, sheet_size.y)))
			)
		else:
			draw_texture_rect(_player_tex, Rect2(Vector2(-PLAYER_SPRITE_SIZE * 0.5, -PLAYER_SPRITE_SIZE * 0.5), Vector2(PLAYER_SPRITE_SIZE, PLAYER_SPRITE_SIZE)), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_circle(pdp, p_draw_r, _player_tint)
		draw_arc(pdp, p_draw_r, 0.0, TAU, 32, Color(1, 1, 1, 0.65), 3.0)
		# Eyes shifted toward facing direction
		var p_eye_ox: float = 6.0 * float(_player_facing_x)
		draw_circle(pdp + Vector2(p_eye_ox - 7.0, -8.0), 7.5, Color(1, 1, 1, 0.92))
		draw_circle(pdp + Vector2(p_eye_ox + 7.0, -8.0), 7.5, Color(1, 1, 1, 0.92))
		draw_circle(pdp + Vector2(p_eye_ox - 7.0, -8.0), 3.8, Color(0.1, 0.05, 0.0))
		draw_circle(pdp + Vector2(p_eye_ox + 7.0, -8.0), 3.8, Color(0.1, 0.05, 0.0))
	# Iframes flash
	if _player_iframes > 0.0 and fmod(_player_iframes, 0.12) > 0.06:
		draw_circle(pdp, p_draw_r + 6.0, Color(1.0, 1.0, 1.0, 0.35))
	if _is_ring_shield_active():
		var shield_pulse: float = 0.72 + sin(_elapsed * 18.0) * 0.18
		draw_circle(pdp, p_draw_r + 13.0, Color(0.30, 0.74, 1.0, 0.16 * shield_pulse))
		draw_arc(pdp, p_draw_r + 15.0, 0.0, TAU, 48, Color(0.54, 0.88, 1.0, 0.82 * shield_pulse), 4.0)
	# Idle-enrage warning: only when stand-still boost is active
	if _idle_enemy_speed_boost_active and not _enemies.is_empty():
		var warn_flash: float = 0.6 + 0.4 * sin(_elapsed * 6.0)
		var warn_line_1: String = "WARNING: ENEMIES ENRAGE AND MOVE FASTER"
		var warn_line_2: String = "IF YOU STAND STILL FOR MORE THAN 2 SECONDS"
		var warn_width: float = 1180.0
		var warn_font_size: int = 30
		var warn_pos_1: Vector2 = pdp + Vector2(-warn_width * 0.5, p_draw_r + 42.0)
		var warn_pos_2: Vector2 = warn_pos_1 + Vector2(0.0, 34.0)
		draw_string(ThemeDB.fallback_font, warn_pos_1, warn_line_1, HORIZONTAL_ALIGNMENT_CENTER, warn_width, warn_font_size, Color(0.0, 0.0, 0.0, 0.70 * warn_flash))
		draw_string(ThemeDB.fallback_font, warn_pos_1 + Vector2(0, -2), warn_line_1, HORIZONTAL_ALIGNMENT_CENTER, warn_width, warn_font_size, Color(1.0, 0.12, 0.08, 0.98 * warn_flash))
		draw_string(ThemeDB.fallback_font, warn_pos_2, warn_line_2, HORIZONTAL_ALIGNMENT_CENTER, warn_width, warn_font_size, Color(0.0, 0.0, 0.0, 0.70 * warn_flash))
		draw_string(ThemeDB.fallback_font, warn_pos_2 + Vector2(0, -2), warn_line_2, HORIZONTAL_ALIGNMENT_CENTER, warn_width, warn_font_size, Color(1.0, 0.12, 0.08, 0.98 * warn_flash))

	var overlay_room_id := _current_room().get("id", "lava") as String
	var overlay_view := get_viewport_rect().size
	var overlay_center := _story_hazard_arena_center if _is_story_hazard_arena_active() else _player_pos
	var overlay_rect := Rect2(overlay_center - overlay_view * 0.5, overlay_view)
	match overlay_room_id:
		"darkness": _draw_darkness_overlay(overlay_rect)
		"spike": _draw_spike_overlay(overlay_rect)
		"lava": _draw_lava_overlay(overlay_rect)
		"frozen": _draw_frozen_overlay(overlay_rect)
		"poison": _draw_poison_overlay(overlay_rect)

func _draw_revamped_skill_effects() -> void:
	_draw_revamped_persistent_skills()
	_draw_revamped_waves()
	_draw_revamped_projectiles()
	_draw_revamped_skill_zones()
	_draw_revamped_aoe()

func _draw_revamped_persistent_skills() -> void:
	if _has_skill("orb"):
		var orb_def := _slvl("orb", int(_get_skill("orb")["level"]))
		var orb_count := int(orb_def.get("orbs", 3))
		var orbit_radius := _capy_orb_orbit_radius()
		var orb_radius := _capy_orb_hit_radius()
		for orb_index in orb_count:
			var angle := _orb_angle + float(orb_index) * TAU / float(orb_count)
			var orb_pos := _player_pos + Vector2.from_angle(angle) * orbit_radius
			draw_circle(orb_pos, orb_radius * 1.55, Color(1.0, 0.58, 0.06, 0.14))
			draw_circle(orb_pos, orb_radius, Color(1.0, 0.68, 0.08, 0.96))
			draw_arc(orb_pos, orb_radius * 0.72, angle, angle + PI * 1.35, 18, Color(1.0, 0.94, 0.52, 0.95), 3.0)
			draw_circle(orb_pos - Vector2(orb_radius * 0.25, orb_radius * 0.28), orb_radius * 0.22, Color(1, 1, 0.88, 0.95))
	var fields: Array[Dictionary] = [
		{"id": "aura", "color": Color(0.66, 0.40, 0.14), "speed": 0.55},
		{"id": "hurricane", "color": Color(0.48, 0.90, 1.0), "speed": 2.2},
		{"id": "knife_storm", "color": Color(0.90, 0.46, 1.0), "speed": 4.2},
	]
	for field in fields:
		var sid := String(field["id"])
		if not _has_skill(sid):
			continue
		var skill := _get_skill(sid)
		var definition := _slvl(sid, int(skill["level"]))
		var radius := float(definition.get("r", 150.0))
		var color: Color = field["color"] as Color
		var speed := float(field["speed"])
		var pulse := 0.94 + sin(_elapsed * 3.0) * 0.035
		draw_circle(_player_pos, radius * pulse, Color(color.r, color.g, color.b, 0.055))
		for ring in 3:
			var rr := radius * (0.48 + float(ring) * 0.24)
			var start := _elapsed * speed * (-1.0 if ring % 2 else 1.0) + float(ring)
			for arc_index in 4:
				var a := start + float(arc_index) * TAU / 4.0
				draw_arc(_player_pos, rr, a, a + 0.62, 14, Color(color.r, color.g, color.b, 0.38 - float(ring) * 0.07), 3.6 - float(ring) * 0.6)
		for mote in 10:
			var angle := float(mote) / 10.0 * TAU + _elapsed * speed * 0.7
			var distance := radius * (0.35 + 0.55 * fmod(float(mote) * 0.618, 1.0))
			var pos := _player_pos + Vector2.from_angle(angle) * distance
			if sid == "knife_storm":
				var tangent := Vector2.from_angle(angle + PI * 0.5) * 11.0
				draw_line(pos - tangent, pos + tangent, Color(1.0, 0.82, 1.0, 0.78), 2.4)
			else:
				draw_circle(pos, 3.5 + sin(_elapsed * 5.0 + float(mote)) * 1.0, Color(color.r, color.g, color.b, 0.72))

func _draw_revamped_waves() -> void:
	for wave in _waves:
		var ratio := clampf(float(wave["life"]) / float(wave["max_life"]), 0.0, 1.0)
		var radius := float(wave["r"])
		var pos: Vector2 = wave["pos"] as Vector2
		if not _is_world_pos_visible(pos, radius + 40.0):
			continue
		var kind := String(wave.get("kind", "wave"))
		var color := _revamped_skill_color(kind)
		draw_circle(pos, radius * 0.94, Color(color.r, color.g, color.b, 0.07 * ratio))
		for ring in 3:
			var rr := maxf(radius - float(ring) * 13.0, 2.0)
			draw_arc(pos, rr, 0.0, TAU, 56, Color(color.r, color.g, color.b, ratio * (0.88 - float(ring) * 0.22)), maxf(1.0, (5.2 - float(ring)) * ratio))
		for ray in 12:
			var angle := float(ray) / 12.0 * TAU + _elapsed * 0.7
			var inner := pos + Vector2.from_angle(angle) * radius * 0.76
			var outer := pos + Vector2.from_angle(angle) * (radius + 14.0 * ratio)
			draw_line(inner, outer, Color(1.0, 1.0, 1.0, 0.42 * ratio), 1.5)
		if kind.contains("lightning") or kind.contains("thunder") or kind.contains("elec"):
			for arc_index in 8:
				var a := float(arc_index) * TAU / 8.0 + _elapsed * 4.0
				var mid := pos + Vector2.from_angle(a + 0.10) * radius * 0.82
				var tip := pos + Vector2.from_angle(a) * radius * 1.06
				draw_polyline(PackedVector2Array([pos + Vector2.from_angle(a) * radius * 0.58, mid, tip]), Color(1.0, 0.96, 0.42, 0.84 * ratio), 2.4)
		elif kind.contains("frozen") or kind.contains("ice"):
			for shard in 10:
				var a := float(shard) * TAU / 10.0
				var base := pos + Vector2.from_angle(a) * radius * 0.78
				draw_line(base, base + Vector2.from_angle(a) * 24.0 * ratio, Color(0.78, 0.97, 1.0, 0.88 * ratio), 3.0)
		elif kind in ["belly_bounce", "stampede"]:
			for dust in 9:
				var a := float(dust) * TAU / 9.0 + 0.2
				draw_circle(pos + Vector2.from_angle(a) * radius * 0.92, 5.0 + 7.0 * ratio, Color(0.72, 0.48, 0.20, 0.48 * ratio))
		elif kind.contains("toxic") or kind.contains("venom"):
			for bubble in 8:
				var a := float(bubble) * TAU / 8.0 + _elapsed
				draw_circle(pos + Vector2.from_angle(a) * radius * 0.72, 3.0 + float(bubble % 3), Color(0.56, 1.0, 0.24, 0.72 * ratio))

func _draw_revamped_projectiles() -> void:
	for projectile in _fireballs:
		var fire_kind := String(projectile.get("kind", "fireball"))
		_draw_energy_projectile(projectile, _revamped_skill_color(fire_kind), 15.0, "plasma" if fire_kind == "inferno_plasma" else "fire_orb")
	for projectile in _bolts:
		var kind := String(projectile.get("kind", "bolt"))
		var shape := _projectile_shape_for_kind(kind)
		_draw_energy_projectile(projectile, _revamped_skill_color(kind), _projectile_radius_for_shape(shape), shape)
	for projectile in _ice_orbs:
		_draw_energy_projectile(projectile, Color(0.52, 0.90, 1.0), 15.0, "ice_orb")
	for projectile in _pierce_arrows:
		var pierce_kind := String(projectile.get("kind", "pierce_arrow"))
		_draw_energy_projectile(projectile, _revamped_skill_color(pierce_kind), 10.0, "ice_spear" if pierce_kind == "frozen_lance" else "arrow")
	for projectile in _boomerangs:
		_draw_energy_projectile(projectile, Color(0.96, 0.74, 1.0), 14.0, "boomerang")
	for rush in _capy_charge_rushes:
		var pos: Vector2 = rush.get("pos", _player_pos) as Vector2
		if not _is_world_pos_visible(pos, 180.0):
			continue
		var direction: Vector2 = rush.get("dir", Vector2.RIGHT) as Vector2
		for echo in 6:
			var p := pos - direction * float(echo) * 24.0
			draw_circle(p, 22.0 - float(echo) * 2.5, Color(0.58, 0.28, 1.0, 0.34 - float(echo) * 0.045))
		draw_arc(pos, 31.0, -PI * 0.75, PI * 0.75, 20, Color(0.92, 0.74, 1.0, 0.90), 4.0)
	for stampede in _stampedes:
		var pos: Vector2 = stampede.get("pos", _player_pos) as Vector2
		if not _is_world_pos_visible(pos, 160.0):
			continue
		var direction := (pos - (stampede.get("start_pos", _player_pos) as Vector2)).normalized()
		if direction.length_squared() < 0.01: direction = Vector2.RIGHT
		for segment in 7:
			var p := pos - direction * float(segment) * 13.0
			var size := 13.0 - float(segment) * 0.8
			draw_circle(p, size + 4.0, Color(0.20, 0.10, 0.03, 0.42))
			draw_circle(p, size, Color(0.88 - float(segment) * 0.035, 0.56, 0.16, 0.92))
		draw_circle(pos, 15.0, Color(1.0, 0.76, 0.24, 0.98))

func _projectile_shape_for_kind(kind: String) -> String:
	if kind == "bolt" or kind.contains("lightning") or kind.contains("elec"): return "lightning"
	if kind in ["arrow", "split_arrow", "divine_volley", "poison_arrow", "trap_arrow", "phantom_hunt"]: return "arrow"
	if kind in ["star_knife", "shadow_dagger", "bleed_mark"] or kind.begins_with("tb_"): return "dagger"
	if kind == "arcane_missile": return "arcane_orb"
	if kind == "ricochet_arrow": return "bomb"
	if kind == "plague_beetles": return "beetles"
	if kind == "flying_pan": return "pan"
	if kind == "meatball_barrage": return "meatball"
	if kind == "chili_ember": return "fire_orb"
	if kind == "chili_explosion": return "chili"
	if kind == "leech_vine": return "vine"
	if kind == "hawk_feather": return "feather"
	if kind == "phantom_homing": return "spirit"
	if kind == "venom_plague": return "poison_orb"
	return "magic_dart"

func _projectile_radius_for_shape(shape: String) -> float:
	if shape in ["pan", "beetles", "chili"]: return 14.0
	if shape in ["bomb", "meatball", "arcane_orb", "poison_orb", "spirit"]: return 12.0
	return 10.0

func _draw_energy_projectile(projectile: Dictionary, color: Color, radius: float, shape: String) -> void:
	var pos: Vector2 = projectile.get("pos", Vector2.ZERO) as Vector2
	if not _is_world_pos_visible(pos, radius * 6.0):
		return
	var velocity: Vector2 = projectile.get("vel", Vector2.RIGHT) as Vector2
	var direction := velocity.normalized()
	if direction.length_squared() < 0.01: direction = Vector2.RIGHT
	if shape in ["lightning", "arcane_orb", "poison_orb", "spirit", "fire_orb", "plasma", "ice_orb", "ice_spear", "magic_dart"]:
		for trail in 6:
			var t := float(trail + 1) / 6.0
			var p := pos - direction * t * radius * 5.0
			draw_circle(p, radius * (1.0 - t) * 0.70, Color(color.r, color.g, color.b, (1.0 - t) * 0.42))
	match shape:
		"arrow":
			var side := Vector2(-direction.y, direction.x)
			var tip := pos + direction * radius * 2.2
			var shaft_end := pos - direction * radius * 1.8
			draw_line(shaft_end, tip - direction * radius * 0.35, Color(color.r, color.g, color.b, 0.98), 3.2)
			draw_colored_polygon(PackedVector2Array([tip, tip - direction * radius * 0.9 + side * radius * 0.55, tip - direction * radius * 0.9 - side * radius * 0.55]), Color(0.92, 1.0, 0.82, 0.98))
			draw_line(shaft_end, shaft_end + direction * radius * 0.7 + side * radius * 0.65, color, 2.5)
			draw_line(shaft_end, shaft_end + direction * radius * 0.7 - side * radius * 0.65, color, 2.5)
		"lightning":
			var side := Vector2(-direction.y, direction.x)
			var points := PackedVector2Array()
			for segment in 6:
				var along := float(segment) / 5.0
				var zig := (1.0 if segment % 2 == 0 else -1.0) * radius * 0.55
				points.append(pos - direction * radius * 2.0 + direction * radius * 4.0 * along + side * zig)
			draw_polyline(points, Color(color.r, color.g, color.b, 0.35), 8.0)
			draw_polyline(points, Color(1.0, 0.98, 0.62, 1.0), 3.0)
		"ice_orb":
			draw_circle(pos, radius * 1.75, Color(0.34, 0.78, 1.0, 0.16))
			draw_circle(pos, radius, Color(0.42, 0.84, 1.0, 0.92))
			draw_arc(pos, radius * 0.72, -_elapsed * 4.0, -_elapsed * 4.0 + PI * 1.45, 20, Color(0.90, 1.0, 1.0, 0.95), 3.0)
			for spike in 6:
				var spike_dir := Vector2.from_angle(float(spike) * TAU / 6.0 + _elapsed)
				draw_line(pos + spike_dir * radius * 0.8, pos + spike_dir * radius * 1.35, Color(0.72, 0.96, 1.0, 0.88), 2.0)
		"pan":
			var spin := _elapsed * 13.0 + pos.x * 0.01
			var pan_axis := Vector2.from_angle(spin)
			draw_circle(pos, radius * 1.02, Color(0.12, 0.10, 0.09, 0.98))
			draw_circle(pos, radius * 0.76, Color(0.48, 0.46, 0.44, 1.0))
			draw_arc(pos, radius * 0.66, 0.0, TAU, 20, Color(0.82, 0.78, 0.68, 0.95), 2.4)
			draw_line(pos + pan_axis * radius * 0.7, pos + pan_axis * radius * 2.25, Color(0.20, 0.16, 0.12, 1.0), 7.0)
			draw_line(pos + pan_axis * radius * 0.8, pos + pan_axis * radius * 2.15, Color(0.62, 0.46, 0.28, 0.95), 3.0)
			for echo in 2:
				draw_arc(pos, radius * (1.35 + float(echo) * 0.35), spin - 1.2, spin + 0.2, 12, Color(0.92, 0.78, 0.48, 0.34), 2.0)
		"meatball":
			draw_circle(pos, radius * 1.12, Color(0.36, 0.12, 0.05, 0.42))
			draw_circle(pos, radius, Color(0.56, 0.24, 0.10, 1.0))
			for spot in 5:
				var a := float(spot) * TAU / 5.0 + _elapsed * 2.0
				draw_circle(pos + Vector2.from_angle(a) * radius * 0.48, radius * 0.17, Color(0.92, 0.56, 0.20, 0.9))
			for drip in 3:
				var drip_pos := pos - direction * radius * (1.2 + float(drip) * 0.65) + Vector2(-direction.y, direction.x) * sin(_elapsed * 8.0 + float(drip)) * 4.0
				draw_circle(drip_pos, 2.5, Color(0.84, 0.12, 0.06, 0.75))
		"chili":
			var side := Vector2(-direction.y, direction.x)
			draw_colored_polygon(PackedVector2Array([pos + direction * radius * 1.6, pos - direction * radius * 1.2 + side * radius * 0.65, pos - direction * radius * 1.2 - side * radius * 0.65]), Color(0.94, 0.12, 0.05, 1.0))
			draw_line(pos - direction * radius, pos - direction * radius * 1.55 + side * radius * 0.25, Color(0.30, 0.74, 0.16, 1.0), 3.5)
		"dagger":
			var side := Vector2(-direction.y, direction.x)
			var tip := pos + direction * radius * 1.9
			var guard := pos - direction * radius * 0.65
			draw_colored_polygon(PackedVector2Array([tip, guard + side * radius * 0.34, guard - side * radius * 0.34]), Color(0.86, 0.90, 1.0, 1.0))
			draw_line(guard - side * radius * 0.68, guard + side * radius * 0.68, color, 3.5)
			draw_line(guard, pos - direction * radius * 1.35, Color(0.28, 0.16, 0.12, 1.0), 4.0)
		"bomb":
			draw_circle(pos, radius, Color(0.10, 0.10, 0.12, 1.0))
			draw_circle(pos - Vector2(radius * 0.28, radius * 0.30), radius * 0.20, Color(0.58, 0.58, 0.62, 0.85))
			var fuse_tip := pos - direction * radius * 1.2 + Vector2(-direction.y, direction.x) * radius * 0.75
			draw_line(pos - direction * radius * 0.55, fuse_tip, Color(0.58, 0.38, 0.16, 1.0), 2.0)
			draw_circle(fuse_tip, 3.2 + sin(_elapsed * 22.0), Color(1.0, 0.72, 0.12, 1.0))
		"vine":
			var side := Vector2(-direction.y, direction.x)
			var vine_points := PackedVector2Array()
			for segment in 7:
				var t := float(segment) / 6.0
				vine_points.append(pos - direction * radius * 3.0 + direction * radius * 5.0 * t + side * sin(t * TAU * 1.5 + _elapsed * 7.0) * radius * 0.42)
			draw_polyline(vine_points, Color(0.20, 0.56, 0.10, 1.0), 6.0)
			draw_polyline(vine_points, Color(0.54, 0.92, 0.22, 0.95), 2.2)
			for leaf in [2, 4]:
				draw_circle(vine_points[leaf], radius * 0.28, Color(0.38, 0.82, 0.18, 0.95))
		"feather":
			var side := Vector2(-direction.y, direction.x)
			draw_line(pos - direction * radius * 1.8, pos + direction * radius * 1.4, Color(0.96, 0.88, 0.66, 1.0), 2.5)
			for barb in 5:
				var t := float(barb) / 5.0
				var stem := pos - direction * radius * 1.35 + direction * radius * 2.2 * t
				draw_line(stem, stem - direction * radius * 0.45 + side * radius * (0.75 - t * 0.35), Color(0.92, 0.82, 0.60, 0.9), 2.0)
				draw_line(stem, stem - direction * radius * 0.45 - side * radius * (0.75 - t * 0.35), Color(0.92, 0.82, 0.60, 0.9), 2.0)
		"beetles":
			for beetle in 3:
				var a := _elapsed * 9.0 + float(beetle) * TAU / 3.0
				var bp := pos + Vector2.from_angle(a) * radius * 0.65
				draw_circle(bp, radius * 0.40, Color(0.16, 0.10, 0.04, 1.0))
				draw_arc(bp, radius * 0.42, 0.0, TAU, 10, Color(0.48, 0.94, 0.18, 0.9), 1.4)
		"arcane_orb", "poison_orb", "spirit", "fire_orb", "plasma":
			draw_circle(pos, radius * 1.65, Color(color.r, color.g, color.b, 0.18))
			draw_circle(pos, radius, Color(color.r, color.g, color.b, 0.96))
			draw_arc(pos, radius * 1.18, _elapsed * 6.0, _elapsed * 6.0 + PI * 1.4, 18, Color(1, 1, 1, 0.75), 2.2)
			if shape == "plasma":
				draw_line(pos - direction * radius, pos + direction * radius, Color(1.0, 0.72, 0.20, 0.92), 3.0)
		"ice_spear":
			var side := Vector2(-direction.y, direction.x)
			draw_colored_polygon(PackedVector2Array([pos + direction * radius * 2.4, pos - direction * radius * 1.5 + side * radius * 0.55, pos - direction * radius * 1.5 - side * radius * 0.55]), Color(0.66, 0.94, 1.0, 0.98))
			draw_line(pos - direction * radius, pos + direction * radius * 1.7, Color(0.94, 1.0, 1.0, 0.92), 2.4)
		"boomerang":
			var spin := _elapsed * 12.0
			var d1 := Vector2.from_angle(spin) * radius
			var d2 := Vector2.from_angle(spin + PI * 0.72) * radius
			draw_line(pos, pos + d1, Color(color.r, color.g, color.b, 1.0), 6.0)
			draw_line(pos, pos + d2, Color(color.r, color.g, color.b, 1.0), 6.0)
			draw_circle(pos, 3.0, Color(1, 1, 1, 0.9))
		"magic_dart":
			var side := Vector2(-direction.y, direction.x)
			draw_colored_polygon(PackedVector2Array([pos + direction * radius * 1.8, pos - direction * radius - side * radius * 0.55, pos - direction * radius + side * radius * 0.55]), Color(color.r, color.g, color.b, 0.96))
			draw_line(pos - direction * radius, pos + direction * radius * 1.25, Color(1, 1, 1, 0.82), 2.0)
		"blade":
			var spin := _elapsed * 12.0
			for blade in 4:
				var d := Vector2.from_angle(spin + float(blade) * PI * 0.5) * radius
				draw_line(pos, pos + d, Color(color.r, color.g, color.b, 0.92), 4.0)
		"crystal":
			var side := Vector2(-direction.y, direction.x)
			draw_colored_polygon(PackedVector2Array([pos + direction * radius * 1.4, pos + side * radius * 0.65, pos - direction * radius, pos - side * radius * 0.65]), Color(color.r, color.g, color.b, 0.92))
		_:
			draw_circle(pos, radius * 1.8, Color(color.r, color.g, color.b, 0.16))
			draw_circle(pos, radius, Color(color.r, color.g, color.b, 0.94))
	if shape in ["arcane_orb", "poison_orb", "spirit", "fire_orb", "plasma", "ice_orb", "ice_spear", "magic_dart"]:
		draw_circle(pos, radius * 0.34, Color(1, 1, 1, 0.92))

func _draw_revamped_skill_zones() -> void:
	for trail in _fire_trails:
		_draw_zone(trail, Color(1.0, 0.30, 0.04))
	for pool in _venom_pools:
		_draw_zone(pool, Color(0.34, 0.92, 0.20))
	for pool in _bog_pools:
		_draw_zone(pool, Color(0.62, 0.42, 0.16))
	for pool in _corruption_pools:
		_draw_zone(pool, Color(0.56, 0.20, 0.86))
	for zone in _time_warp_zones:
		_draw_zone(zone, Color(0.38, 0.68, 1.0))
	for zone in _smoke_clouds:
		_draw_zone(zone, Color(0.62, 0.58, 0.72))
	for mushroom in _toxic_mushrooms:
		var mushroom_pos: Vector2 = mushroom.get("pos", Vector2.ZERO) as Vector2
		if not _is_world_pos_visible(mushroom_pos, 60.0):
			continue
		var mushroom_alpha := clampf(float(mushroom.get("life", 1.0)) / float(mushroom.get("max_life", 1.0)), 0.0, 1.0)
		draw_circle(mushroom_pos, 30.0, Color(0.28, 0.92, 0.22, 0.12 * mushroom_alpha))
		draw_arc(mushroom_pos, 25.0, _elapsed, _elapsed + PI * 1.5, 18, Color(0.70, 1.0, 0.38, 0.74 * mushroom_alpha), 3.0)
		for spore in 5:
			var angle := float(spore) / 5.0 * TAU + _elapsed * 1.4
			draw_circle(mushroom_pos + Vector2.from_angle(angle) * 18.0, 3.0, Color(0.82, 1.0, 0.56, 0.78 * mushroom_alpha))
	for trap in _prism_traps:
		var points: Array = trap.get("pts", []) as Array
		if points.size() < 3: continue
		if not _is_world_pos_visible(points[0] as Vector2, 260.0):
			continue
		var alpha := clampf(float(trap.get("life", 1.0)) / float(trap.get("max_life", 1.0)), 0.0, 1.0)
		var polygon := PackedVector2Array([points[0] as Vector2, points[1] as Vector2, points[2] as Vector2])
		draw_colored_polygon(polygon, Color(0.42, 0.78, 1.0, 0.13 * alpha))
		draw_polyline(PackedVector2Array([polygon[0], polygon[1], polygon[2], polygon[0]]), Color(0.68, 0.94, 1.0, 0.82 * alpha), 3.0)
	for trap in _ground_traps:
		var a: Vector2 = trap.get("a", Vector2.ZERO) as Vector2
		var b: Vector2 = trap.get("b", Vector2.ZERO) as Vector2
		if not _is_world_pos_visible(a, a.distance_to(b) + 80.0):
			continue
		draw_line(a, b, Color(0.38, 0.90, 0.20, 0.25), 16.0)
		draw_line(a, b, Color(0.78, 1.0, 0.38, 0.82), 3.0)

func _draw_zone(zone: Dictionary, color: Color) -> void:
	var pos: Vector2 = zone.get("pos", Vector2.ZERO) as Vector2
	var radius := float(zone.get("r", 55.0))
	if not _is_world_pos_visible(pos, radius + 40.0):
		return
	var alpha := clampf(float(zone.get("life", 1.0)) / float(zone.get("max_life", zone.get("life", 1.0))), 0.0, 1.0)
	var pulse := 0.96 + sin(_elapsed * 4.0 + pos.x * 0.01) * 0.04
	draw_circle(pos, radius * pulse, Color(color.r, color.g, color.b, 0.12 * alpha))
	for ring in 3:
		draw_arc(pos, radius * (0.55 + float(ring) * 0.20), _elapsed * (0.7 + float(ring) * 0.2), _elapsed * (0.7 + float(ring) * 0.2) + PI * 1.3, 24, Color(color.r, color.g, color.b, (0.58 - float(ring) * 0.12) * alpha), 2.4)

func _draw_revamped_aoe() -> void:
	for flash in _aoe_flashes:
		var ratio := clampf(float(flash["life"]) / float(flash["max_life"]), 0.0, 1.0)
		var kind := String(flash.get("kind", "wave"))
		var pos: Vector2 = flash.get("pos", _player_pos) as Vector2
		var color := _revamped_skill_color(kind)
		var radius := lerpf(70.0, 720.0, 1.0 - ratio)
		if not _is_world_pos_visible(pos, radius + 60.0):
			continue
		draw_circle(pos, radius, Color(color.r, color.g, color.b, 0.075 * ratio))
		for ring in 4:
			var rr := radius * (0.42 + float(ring) * 0.18)
			var start := _elapsed * (1.4 + float(ring) * 0.25) + float(ring)
			for arc_index in 5:
				var a := start + float(arc_index) * TAU / 5.0
				draw_arc(pos, rr, a, a + 0.44, 12, Color(color.r, color.g, color.b, ratio * (0.62 - float(ring) * 0.09)), 4.0 - float(ring) * 0.55)
		for spark in 24:
			var angle := float(spark) / 24.0 * TAU + _elapsed * 0.8
			var distance := radius * (0.28 + 0.70 * fmod(float(spark) * 0.618, 1.0))
			draw_circle(pos + Vector2.from_angle(angle) * distance, 4.0 * ratio, Color(1, 1, 1, 0.72 * ratio))

func _revamped_skill_color(kind: String) -> Color:
	var key := kind.to_lower()
	if key.contains("ice") or key.contains("blizzard") or key.contains("frozen"): return Color(0.42, 0.86, 1.0)
	if key.contains("lightning") or key.contains("thunder") or key.contains("elec"): return Color(1.0, 0.90, 0.16)
	if key.contains("fire") or key.contains("inferno") or key.contains("chili"): return Color(1.0, 0.28, 0.05)
	if key.contains("poison") or key.contains("venom") or key.contains("bog"): return Color(0.42, 0.92, 0.18)
	if key.contains("shadow") or key.contains("blink") or key.contains("knife"): return Color(0.68, 0.30, 1.0)
	if key.contains("arrow") or key.contains("hawk"): return Color(0.42, 0.96, 0.50)
	if key.contains("heal") or key.contains("feast") or key.contains("aura"): return Color(1.0, 0.72, 0.28)
	return Color(0.50, 0.66, 1.0)

func _draw_bg() -> void:
	var view: Vector2 = get_viewport_rect().size
	var hw: float     = view.x * 0.5 + 128.0
	var hh: float     = view.y * 0.5 + 128.0
	var background_center := _story_hazard_arena_center if _is_story_hazard_arena_active() else _player_pos
	var cx: float     = background_center.x
	var cy: float     = background_center.y
	var room: Dictionary = _current_room()
	var room_id: String = room.get("id", "lava") as String
	var bg_view_rect: Rect2 = Rect2(cx - hw, cy - hh, hw * 2.0, hh * 2.0)
	var room_bg_tex: Texture2D = _room_bg_texture(room_id)
	if room_bg_tex != null:
		if _is_story_hazard_arena_active():
			_draw_room_bg(room_bg_tex, bg_view_rect)
		elif room_id == "darkness" or room_id == "spike" or room_id == "lava" or room_id == "frozen" or room_id == "poison":
			_draw_room_bg_tiled(room_bg_tex, bg_view_rect)
		else:
			_draw_room_bg(room_bg_tex, bg_view_rect)
	var room_color: Color = room.get("col", Color(0.14, 0.11, 0.08)) as Color
	var base_col: Color = Color(0.14, 0.11, 0.08).lerp(room_color, 0.12)
	if room_bg_tex != null:
		base_col = Color(0.10, 0.08, 0.06, 0.10)
	draw_rect(bg_view_rect, base_col)
	const TILE: float = 100.0
	if room_bg_tex == null:
		var xl: float = floor((cx - hw) / TILE) * TILE
		var yl: float = floor((cy - hh) / TILE) * TILE
		var x: float = xl
		while x <= cx + hw:
			draw_line(Vector2(x, cy - hh), Vector2(x, cy + hh), Color(room_color.r, room_color.g, room_color.b, 0.05), 1.0)
			x += TILE
		var y: float = yl
		while y <= cy + hh:
			draw_line(Vector2(cx - hw, y), Vector2(cx + hw, y), Color(room_color.r, room_color.g, room_color.b, 0.05), 1.0)
			y += TILE
	var pulse: float = 0.5 + 0.5 * sin(_room_elapsed * 3.0)
	if room_id == "spike":
		var spike_col: Color = Color(0.92, 0.18, 0.20, 0.12 + pulse * 0.18)
		var spike_r: float = 150.0 + pulse * 20.0
		for i in 8:
			var ang: float = float(i) / 8.0 * TAU + _room_elapsed * 1.4
			var p1: Vector2 = _player_pos + Vector2(cos(ang), sin(ang)) * (spike_r - 22.0)
			var p2: Vector2 = _player_pos + Vector2(cos(ang), sin(ang)) * spike_r
			draw_line(p1, p2, spike_col, 3.0)
	if (room.get("id", "lava") as String) == "darkness":
		pass  # darkness rings drawn at end of _draw instead

	# Enemy frozen trails
	for ft in _frozen_trails:
		var ftp: Vector2 = ft["pos"] as Vector2
		if abs(ftp.x - cx) > hw + 40.0 or abs(ftp.y - cy) > hh + 40.0:
			continue
		var fl: float    = clamp((ft["life"] as float) / (ft["max_life"] as float), 0.0, 1.0)
		draw_circle(ftp, 28.0, Color(0.45, 0.88, 1.0, 0.22 * fl))
		draw_arc(ftp, 28.0, 0.0, TAU, 20, Color(0.55, 0.92, 1.0, 0.65 * fl), 2.0)

	# Enemy burn trails
	for bt in _burn_trails:
		var btp: Vector2 = bt["pos"] as Vector2
		if abs(btp.x - cx) > hw + 40.0 or abs(btp.y - cy) > hh + 40.0:
			continue
		var bl: float    = clamp((bt["life"] as float) / (bt["max_life"] as float), 0.0, 1.0)
		var bpulse: float = 0.5 + 0.5 * sin(_elapsed * 8.0 + (btp.x + btp.y) * 0.05)
		draw_circle(btp, 26.0, Color(1.0, 0.30 + bpulse * 0.20, 0.0, 0.25 * bl))
		draw_arc(btp, 26.0, 0.0, TAU, 18, Color(1.0, 0.55, 0.05, 0.70 * bl), 2.5)

	# Time warp zones — drawn over most game objects
	for twz in []:
		var tzp: Vector2 = twz["pos"] as Vector2
		var tzr: float   = twz["r"] as float
		var tzlf: float  = clamp((twz["life"] as float) / (twz["max_life"] as float), 0.0, 1.0)
		draw_circle(tzp, tzr, Color(0.38, 0.60, 1.0, 0.12))
		draw_arc(tzp, tzr, 0.0, TAU, 48, Color(0.55, 0.78, 1.0, 0.68 * tzlf), 2.5)
		draw_arc(tzp, tzr * 0.72, 0.0, TAU, 36, Color(0.68, 0.88, 1.0, 0.32 * tzlf), 1.2)
		var n_clocks: int = 6
		for ck in n_clocks:
			var cka: float   = float(ck) / n_clocks * TAU + _elapsed * 0.4
			var ckp: Vector2 = tzp + Vector2(cos(cka), sin(cka)) * (tzr * 0.52)
			draw_circle(ckp, 8.0, Color(0.62, 0.84, 1.0, 0.50 * tzlf))
			draw_arc(ckp, 7.0, 0.0, TAU, 16, Color(0.28, 0.52, 0.90, 0.80 * tzlf), 1.0)
			var ha: float = _elapsed * 0.18 + float(ck)
			draw_line(ckp, ckp + Vector2(cos(ha), sin(ha)) * 5.0, Color(0.18, 0.38, 0.88, 0.90 * tzlf), 1.2)
			draw_line(ckp, ckp + Vector2(cos(ha * 12.0), sin(ha * 12.0)) * 3.5, Color(0.18, 0.38, 0.88, 0.80 * tzlf), 1.0)

	# Smoke clouds — drawn over dungeon tiles
	for smc in []:
		var smcp:   Vector2 = smc["pos"] as Vector2
		var smcr:   float   = smc["r"] as float
		var smclf:  float   = clamp((smc["life"] as float) / (smc["max_life"] as float), 0.0, 1.0)
		var smc_p:  float   = 0.72 + 0.28 * sin(_elapsed * 1.6 + smcp.x * 0.008)
		draw_circle(smcp, smcr * smc_p, Color(0.46, 0.44, 0.52, 0.38 * smclf))
		draw_circle(smcp, smcr * 0.68 * smc_p, Color(0.56, 0.54, 0.62, 0.52 * smclf))
		for sbump in 5:
			var sba: float = float(sbump) / 5.0 * TAU + _elapsed * 0.25 + smcp.y * 0.005
			draw_circle(smcp + Vector2(cos(sba), sin(sba)) * (smcr * 0.52), smcr * 0.38 * smc_p, Color(0.58, 0.56, 0.64, 0.32 * smclf))

	# Boss intermission props + arena frame
	var bi_state: String = _boss_intermission.get("state", "none") as String
	if bi_state == "await_choice" or bi_state == "await_ladder":
		var dp: Vector2 = _boss_intermission.get("door_pos", _player_pos) as Vector2
		var lp: Vector2 = _boss_intermission.get("ladder_pos", _player_pos) as Vector2
		_draw_player_direction_indicator(lp, "Next Level", Color.WHITE, PLAYER_R + 150.0)
		if bi_state == "await_choice":
			_draw_player_direction_indicator(dp, "Boss Portal", Color(0.82, 0.68, 1.0), PLAYER_R + 150.0)
		if bi_state == "await_choice":
			if _portal_icon_tex != null:
				var portal_scale: float = 1.0 + sin(_elapsed * 3.4) * 0.08
				var portal_size: Vector2 = Vector2(186.0, 186.0) * portal_scale
				draw_texture_rect(_portal_icon_tex, Rect2(dp - portal_size * 0.5, portal_size), false, Color(1.0, 1.0, 1.0, 0.98))
		if _next_level_icon_tex != null:
			var ladder_scale: float = 1.0 + sin(_elapsed * 3.0 + 0.7) * 0.06
			var ladder_size: Vector2 = Vector2(196.0, 196.0) * ladder_scale
			draw_texture_rect(_next_level_icon_tex, Rect2(lp - ladder_size * 0.5, ladder_size), false, Color(1.0, 1.0, 1.0, 0.98))
	if bi_state == "arena":
		var ac: Vector2 = _boss_intermission.get("arena_center", _player_pos) as Vector2
		var ah: Vector2 = _boss_intermission.get("arena_half", BOSS_ARENA_HALF) as Vector2
		draw_rect(Rect2(ac.x - ah.x, ac.y - ah.y, ah.x * 2.0, ah.y * 2.0), Color(0.08, 0.06, 0.10, 0.18), true)
		draw_rect(Rect2(ac.x - ah.x, ac.y - ah.y, ah.x * 2.0, ah.y * 2.0), Color(0.96, 0.70, 0.24, 0.88), false, 4.0)

func _room_bg_texture(room_id: String) -> Texture2D:
	match room_id:
		"lava":
			if _lava_room_tile_bg_tex != null:
				return _lava_room_tile_bg_tex
			return _lava_room_bg_tex
		"frozen":
			if _frozen_room_tile_bg_tex != null:
				return _frozen_room_tile_bg_tex
			return _frozen_room_bg_tex
		"poison":
			if _poison_room_tile_bg_tex != null:
				return _poison_room_tile_bg_tex
			return _poison_room_bg_tex
		"spike":
			if _spike_room_tile_bg_tex != null:
				return _spike_room_tile_bg_tex
			return _spike_room_bg_tex
		"darkness":
			return _darkness_room_bg_tex
		_:
			return null

func _draw_room_bg(bg_tex: Texture2D, view_rect: Rect2) -> void:
	if bg_tex == null:
		return

	var tex_w: float = float(bg_tex.get_width())
	var tex_h: float = float(bg_tex.get_height())
	if tex_w <= 4.0 or tex_h <= 4.0:
		draw_texture_rect(bg_tex, view_rect, false, Color(1.0, 1.0, 1.0, 0.95))
		return

	# Preserve original art composition by center-cropping to viewport aspect.
	var scale: float = max(view_rect.size.x / tex_w, view_rect.size.y / tex_h)
	var src_w: float = view_rect.size.x / scale
	var src_h: float = view_rect.size.y / scale
	var src_x: float = (tex_w - src_w) * 0.5
	var src_y: float = (tex_h - src_h) * 0.5
	var src_rect: Rect2 = Rect2(src_x, src_y, src_w, src_h)
	draw_texture_rect_region(bg_tex, view_rect, src_rect, Color(1.0, 1.0, 1.0, 0.95))

func _draw_room_bg_tiled(bg_tex: Texture2D, view_rect: Rect2) -> void:
	if bg_tex == null:
		return
	var tex_w: float = float(bg_tex.get_width())
	var tex_h: float = float(bg_tex.get_height())
	if tex_w <= 4.0 or tex_h <= 4.0:
		draw_texture_rect(bg_tex, view_rect, true, Color(1.0, 1.0, 1.0, 0.95))
		return
	var start_x: float = floor(view_rect.position.x / tex_w) * tex_w
	var start_y: float = floor(view_rect.position.y / tex_h) * tex_h
	var x: float = start_x
	while x < view_rect.end.x:
		var y: float = start_y
		while y < view_rect.end.y:
			draw_texture_rect(bg_tex, Rect2(x, y, tex_w, tex_h), false, Color(1.0, 1.0, 1.0, 0.95))
			y += tex_h
		x += tex_w

func _draw_darkness_overlay(view_rect: Rect2) -> void:
	if _darkness_room_overlay_tex == null:
		# Fallback: fully opaque darkness outside a small visible center.
		var vis_r: float = 150.0
		for s in 20:
			var t: float     = float(s) / 19.0
			var ring_r: float = vis_r + 55.0 + t * 820.0
			var ring_a: float = 0.65 + t * t * 0.35
			draw_arc(_player_pos, ring_r, 0.0, TAU, 40, Color(0.0, 0.0, 0.0, ring_a), 56.0)
		return

	var tex_w: float = float(_darkness_room_overlay_tex.get_width())
	var tex_h: float = float(_darkness_room_overlay_tex.get_height())
	if tex_w <= 4.0 or tex_h <= 4.0:
		draw_texture_rect(_darkness_room_overlay_tex, view_rect, false, Color(1.0, 1.0, 1.0, 1.0))
		return

	# Keep darkness mask stationary in screen-space so only the tile background moves.
	var scale: float = max(view_rect.size.x / tex_w, view_rect.size.y / tex_h)
	var src_w: float = view_rect.size.x / scale
	var src_h: float = view_rect.size.y / scale
	var src_x: float = (tex_w - src_w) * 0.5
	var src_y: float = (tex_h - src_h) * 0.5
	var src_rect: Rect2 = Rect2(src_x, src_y, src_w, src_h)
	draw_texture_rect_region(_darkness_room_overlay_tex, view_rect, src_rect, Color(1.0, 1.0, 1.0, 1.0))

func _draw_stationary_overlay(overlay_tex: Texture2D, view_rect: Rect2) -> void:
	if overlay_tex == null:
		return
	var tex_w: float = float(overlay_tex.get_width())
	var tex_h: float = float(overlay_tex.get_height())
	if tex_w <= 4.0 or tex_h <= 4.0:
		draw_texture_rect(overlay_tex, view_rect, false, Color(1.0, 1.0, 1.0, 1.0))
		return
	var scale: float = max(view_rect.size.x / tex_w, view_rect.size.y / tex_h)
	var src_w: float = view_rect.size.x / scale
	var src_h: float = view_rect.size.y / scale
	var src_x: float = (tex_w - src_w) * 0.5
	var src_y: float = (tex_h - src_h) * 0.5
	var src_rect: Rect2 = Rect2(src_x, src_y, src_w, src_h)
	draw_texture_rect_region(overlay_tex, view_rect, src_rect, Color(1.0, 1.0, 1.0, 1.0))

func _draw_lava_overlay(view_rect: Rect2) -> void:
	_draw_stationary_overlay(_lava_room_bg_tex, view_rect)

func _draw_frozen_overlay(view_rect: Rect2) -> void:
	_draw_stationary_overlay(_frozen_room_bg_tex, view_rect)

func _draw_poison_overlay(view_rect: Rect2) -> void:
	_draw_stationary_overlay(_poison_room_bg_tex, view_rect)

func _draw_spike_overlay(view_rect: Rect2) -> void:
	# Keep spike overlay stationary in screen-space so only the tile background moves.
	_draw_stationary_overlay(_spike_room_bg_tex, view_rect)

func _draw_boss_name(pos: Vector2, boss_r: float, boss_name: String, color: Color) -> void:
	var label_w: float = min(get_viewport_rect().size.x - 48.0, 620.0)
	var font_size: int = 28
	var baseline_y: float = pos.y - boss_r - 34.0
	var label_x: float = pos.x - label_w * 0.5
	draw_string(ThemeDB.fallback_font, Vector2(label_x + 2.0, baseline_y + 2.0), boss_name, HORIZONTAL_ALIGNMENT_CENTER, label_w, font_size, Color(0.0, 0.0, 0.0, 0.70))
	draw_string(ThemeDB.fallback_font, Vector2(label_x, baseline_y), boss_name, HORIZONTAL_ALIGNMENT_CENTER, label_w, font_size, color)

# ═════════════════════════════════════════════════════════════════════════════
# HUD
# ═════════════════════════════════════════════════════════════════════════════

func _build_hud() -> void:
	var view: Vector2 = get_viewport_rect().size
	var hud := CanvasLayer.new()
	add_child(hud)

	# HP bar
	var hp_bg := Panel.new()
	var hp_bg_s := StyleBoxFlat.new()
	hp_bg_s.bg_color = Color(0.14, 0.06, 0.06, 0.90)
	hp_bg_s.corner_radius_top_left = 12; hp_bg_s.corner_radius_top_right = 12
	hp_bg_s.corner_radius_bottom_right = 12; hp_bg_s.corner_radius_bottom_left = 12
	hp_bg.add_theme_stylebox_override("panel", hp_bg_s)
	hp_bg.position = Vector2(28, 40); hp_bg.size = Vector2(390, 40)
	hud.add_child(hp_bg)

	_hp_fill = Panel.new()
	var hp_fill_s := StyleBoxFlat.new()
	hp_fill_s.bg_color = Color(0.82, 0.12, 0.12)
	hp_fill_s.corner_radius_top_left = 10; hp_fill_s.corner_radius_top_right = 10
	hp_fill_s.corner_radius_bottom_right = 10; hp_fill_s.corner_radius_bottom_left = 10
	_hp_fill.add_theme_stylebox_override("panel", hp_fill_s)
	_hp_fill.position = Vector2(3, 3); _hp_fill.size = Vector2(384, 34)
	_hp_fill.custom_minimum_size = Vector2(0, 34)
	hp_bg.add_child(_hp_fill)

	var hp_lbl := Label.new()
	hp_lbl.text = "HP"
	hp_lbl.add_theme_font_size_override("font_size", 16)
	hp_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.85))
	hp_lbl.position = Vector2(10, 10); hp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bg.add_child(hp_lbl)

	# XP bar
	var xp_bg := Panel.new()
	var xp_bg_s := StyleBoxFlat.new()
	xp_bg_s.bg_color = Color(0.10, 0.08, 0.04, 0.90)
	xp_bg_s.corner_radius_top_left = 8; xp_bg_s.corner_radius_top_right = 8
	xp_bg_s.corner_radius_bottom_right = 8; xp_bg_s.corner_radius_bottom_left = 8
	xp_bg.add_theme_stylebox_override("panel", xp_bg_s)
	xp_bg.position = Vector2(28, 88); xp_bg.size = Vector2(390, 22)
	hud.add_child(xp_bg)

	_xp_fill = Panel.new()
	var xp_fill_s := StyleBoxFlat.new()
	xp_fill_s.bg_color = Color(0.92, 0.72, 0.10)
	xp_fill_s.corner_radius_top_left = 6; xp_fill_s.corner_radius_top_right = 6
	xp_fill_s.corner_radius_bottom_right = 6; xp_fill_s.corner_radius_bottom_left = 6
	_xp_fill.add_theme_stylebox_override("panel", xp_fill_s)
	_xp_fill.position = Vector2(2, 2); _xp_fill.size = Vector2(0, 18)
	_xp_fill.custom_minimum_size = Vector2(0, 18)
	xp_bg.add_child(_xp_fill)

	# Level label
	_level_lbl = Label.new()
	_level_lbl.text = "LV 1"
	_level_lbl.add_theme_font_size_override("font_size", 40)
	_level_lbl.add_theme_color_override("font_color", Color(0.98, 0.88, 0.50))
	_level_lbl.position = Vector2(436, 38)
	hud.add_child(_level_lbl)

	var info_chip_tex: Texture2D = load(HUD_LABEL_ICON_PATH) as Texture2D

	# Time/Kills/Wave chip
	_time_chip = TextureRect.new()
	_time_chip.texture = info_chip_tex
	_time_chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_time_chip.stretch_mode = TextureRect.STRETCH_SCALE
	_time_chip.position = Vector2(24, 120)
	_time_chip.size = Vector2(520, 58)
	hud.add_child(_time_chip)

	# Time and kills
	_time_lbl = Label.new()
	_time_lbl.text = "0:00   |   Kills: 0"
	_time_lbl.add_theme_font_size_override("font_size", 36)
	_time_lbl.add_theme_color_override("font_color", Color(0.90, 0.86, 0.76))
	_time_lbl.position = Vector2(52, 126); _time_lbl.size = Vector2(456, 44)
	hud.add_child(_time_lbl)

	# Wave label (hidden; merged into time chip)
	_wave_lbl = Label.new()
	_wave_lbl.visible = false
	hud.add_child(_wave_lbl)

	# Room detail chip
	_room_chip = TextureRect.new()
	_room_chip.texture = info_chip_tex
	_room_chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_room_chip.stretch_mode = TextureRect.STRETCH_SCALE
	_room_chip.position = Vector2(24, 186)
	_room_chip.size = Vector2(520, 58)
	hud.add_child(_room_chip)

	# Room info row
	_room_detail_lbl = Label.new()
	_room_detail_lbl.text = ""
	_room_detail_lbl.add_theme_font_size_override("font_size", 36)
	_room_detail_lbl.add_theme_color_override("font_color", Color(0.80, 0.76, 0.65))
	_room_detail_lbl.position = Vector2(56, 192); _room_detail_lbl.size = Vector2(456, 44)
	_room_detail_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	hud.add_child(_room_detail_lbl)

	# Keys chip
	_keys_chip = TextureRect.new()
	_keys_chip.texture = info_chip_tex
	_keys_chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_keys_chip.stretch_mode = TextureRect.STRETCH_SCALE
	_keys_chip.position = Vector2(24, 252)
	_keys_chip.size = Vector2(260, 58)
	hud.add_child(_keys_chip)

	# Keys row
	_kill_lbl = Label.new()
	_kill_lbl.text = "Keys: 0"
	_kill_lbl.add_theme_font_size_override("font_size", 36)
	_kill_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.36))
	_kill_lbl.position = Vector2(56, 258); _kill_lbl.size = Vector2(196, 44)
	hud.add_child(_kill_lbl)

	var bottom_left_y: float = view.y - 168.0

	# Room effect chip
	_room_effect_chip = TextureRect.new()
	_room_effect_chip.texture = info_chip_tex
	_room_effect_chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_room_effect_chip.stretch_mode = TextureRect.STRETCH_SCALE
	_room_effect_chip.position = Vector2(24, bottom_left_y)
	_room_effect_chip.size = Vector2(420, 58)
	hud.add_child(_room_effect_chip)

	_room_effect_lbl = Label.new()
	_room_effect_lbl.text = ""
	_room_effect_lbl.add_theme_font_size_override("font_size", 32)
	_room_effect_lbl.add_theme_color_override("font_color", Color(0.95, 0.84, 0.54))
	_room_effect_lbl.position = Vector2(56, bottom_left_y + 6.0)
	_room_effect_lbl.size = Vector2(356, 44)
	_room_effect_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	hud.add_child(_room_effect_lbl)

	# Floor affix chip
	_affix_chip = TextureRect.new()
	_affix_chip.texture = info_chip_tex
	_affix_chip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_affix_chip.stretch_mode = TextureRect.STRETCH_SCALE
	_affix_chip.position = Vector2(24, bottom_left_y + 66.0)
	_affix_chip.size = Vector2(view.x - 48.0, 98)
	hud.add_child(_affix_chip)

	# Enemy modifier summary
	_enemy_mod_lbl = Label.new()
	_enemy_mod_lbl.text = ""
	_enemy_mod_lbl.add_theme_font_size_override("font_size", 34)
	_enemy_mod_lbl.add_theme_color_override("font_color", Color(1.0, 0.58, 0.20))
	_enemy_mod_lbl.position = Vector2(56, bottom_left_y + 70.0); _enemy_mod_lbl.size = Vector2(view.x - 112.0, 88)
	_enemy_mod_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_enemy_mod_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_mod_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_enemy_mod_lbl.max_lines_visible = 3
	hud.add_child(_enemy_mod_lbl)

	# Learned skill cooldown icons — directly above the floor effect details.
	# Icons are grey immediately after casting, then reveal their colour from
	# top to bottom as the cooldown recovers.
	_skill_icon_scroll = ScrollContainer.new()
	_skill_icon_scroll.position = Vector2(24, bottom_left_y - 116.0)
	_skill_icon_scroll.size = Vector2(view.x - 48.0, 104.0)
	_skill_icon_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_skill_icon_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_skill_icon_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_skill_icon_scroll)

	_skill_icon_row = HBoxContainer.new()
	_skill_icon_row.add_theme_constant_override("separation", 10)
	_skill_icon_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_skill_icon_row.custom_minimum_size = Vector2(view.x - 48.0, 104.0)
	_skill_icon_row.visible = true
	_skill_icon_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skill_icon_scroll.add_child(_skill_icon_row)

	# Pause button (top-right corner)
	var pause_btn := Button.new()
	pause_btn.text = "II"
	pause_btn.add_theme_font_size_override("font_size", 42)
	pause_btn.position = Vector2(view.x - 112, 14)
	pause_btn.size     = Vector2(96, 96)
	pause_btn.focus_mode = Control.FOCUS_NONE
	var pause_s := StyleBoxFlat.new()
	pause_s.bg_color = Color(0.08, 0.06, 0.04, 0.78)
	pause_s.corner_radius_top_left    = 16
	pause_s.corner_radius_top_right   = 16
	pause_s.corner_radius_bottom_right = 16
	pause_s.corner_radius_bottom_left  = 16
	pause_btn.add_theme_stylebox_override("normal",  pause_s)
	pause_btn.add_theme_stylebox_override("hover",   pause_s)
	pause_btn.add_theme_stylebox_override("pressed", pause_s)
	pause_btn.add_theme_color_override("font_color", Color(0.95, 0.90, 0.75))
	pause_btn.pressed.connect(_show_pause_menu)
	hud.add_child(pause_btn)

	# Story objectives begin only when the player confirms they are prepared.
	var objective_layer := CanvasLayer.new(); objective_layer.layer = 30; add_child(objective_layer)
	_objective_start_btn = Button.new()
	_objective_start_btn.position = Vector2((view.x - 420.0) * 0.5, 330)
	_objective_start_btn.size = Vector2(420, 82)
	_objective_start_btn.visible = false
	_objective_start_btn.add_theme_font_size_override("font_size", 28)
	_objective_start_btn.add_theme_color_override("font_color", Color(0.10, 0.05, 0.0))
	_objective_start_btn.focus_mode = Control.FOCUS_NONE
	_objective_start_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var objective_normal := StyleBoxFlat.new(); objective_normal.bg_color = Color(0.98, 0.72, 0.08, 0.97); objective_normal.border_color = Color(0.72, 0.42, 0.0); objective_normal.set_border_width_all(3); objective_normal.corner_radius_top_left = 24; objective_normal.corner_radius_top_right = 24; objective_normal.corner_radius_bottom_left = 24; objective_normal.corner_radius_bottom_right = 24; objective_normal.shadow_color = Color(0, 0, 0, 0.42); objective_normal.shadow_size = 10; objective_normal.shadow_offset = Vector2(0, 4)
	var objective_hover := objective_normal.duplicate() as StyleBoxFlat; objective_hover.bg_color = Color(1.0, 0.82, 0.25)
	var objective_pressed := objective_normal.duplicate() as StyleBoxFlat; objective_pressed.bg_color = Color(0.80, 0.56, 0.03); objective_pressed.shadow_size = 4
	var objective_disabled := objective_normal.duplicate() as StyleBoxFlat; objective_disabled.bg_color = Color(0.18, 0.16, 0.12, 0.94); objective_disabled.border_color = Color(0.38, 0.34, 0.26); objective_disabled.shadow_size = 0
	_objective_start_btn.add_theme_stylebox_override("normal", objective_normal); _objective_start_btn.add_theme_stylebox_override("hover", objective_hover); _objective_start_btn.add_theme_stylebox_override("pressed", objective_pressed); _objective_start_btn.add_theme_stylebox_override("disabled", objective_disabled); _objective_start_btn.add_theme_color_override("font_disabled_color", Color(0.62, 0.58, 0.48)); _objective_start_btn.pressed.connect(_on_story_objective_start_pressed); objective_layer.add_child(_objective_start_btn)
	if is_story_test_run:
		var test_label := Label.new()
		test_label.text = "DEV TEST — C%dS%d\nProgress and rewards are not saved" % [int(story_stage.get("chapter", 0)), int(story_stage.get("chapter_stage", 0))]
		test_label.position = Vector2(22.0, 160.0)
		test_label.size = Vector2(430.0, 72.0)
		test_label.add_theme_font_size_override("font_size", 20)
		test_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.26, 0.96))
		test_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		test_label.add_theme_constant_override("outline_size", 5)
		test_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		objective_layer.add_child(test_label)
		_setup_story_debug_overlay(objective_layer)

	# Passive attributes panel (top-right, collapsible)
	var passive_w: float = clamp(view.x * 0.33, 320.0, 420.0)
	_passive_panel = PanelContainer.new()
	_passive_panel.custom_minimum_size = Vector2(passive_w, 0)
	_passive_panel.position = Vector2(view.x - passive_w - 46.0, 126)
	var pass_panel_style := StyleBoxFlat.new()
	pass_panel_style.bg_color = Color(0.06, 0.05, 0.04, 0.92)
	pass_panel_style.border_color = Color(0.78, 0.58, 0.22, 0.88)
	pass_panel_style.set_border_width_all(3)
	pass_panel_style.corner_radius_top_left = 14
	pass_panel_style.corner_radius_top_right = 14
	pass_panel_style.corner_radius_bottom_left = 14
	pass_panel_style.corner_radius_bottom_right = 14
	pass_panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	pass_panel_style.shadow_size = 12
	pass_panel_style.content_margin_left = 14
	pass_panel_style.content_margin_right = 14
	pass_panel_style.content_margin_top = 10
	pass_panel_style.content_margin_bottom = 10
	_passive_panel.add_theme_stylebox_override("panel", pass_panel_style)
	hud.add_child(_passive_panel)

	var pass_root := VBoxContainer.new()
	pass_root.add_theme_constant_override("separation", 8)
	_passive_panel.add_child(pass_root)

	var pass_header := HBoxContainer.new()
	pass_header.add_theme_constant_override("separation", 8)
	pass_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pass_header.custom_minimum_size = Vector2(0, 56)
	pass_header.mouse_filter = Control.MOUSE_FILTER_STOP
	pass_header.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pass_root.add_child(pass_header)

	var pass_title := Label.new()
	pass_title.text = "PASSIVE ATTRIBUTES"
	pass_title.add_theme_font_size_override("font_size", 30)
	pass_title.add_theme_color_override("font_color", Color(0.95, 0.76, 0.34))
	pass_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pass_title.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_passive_toggle_btn = Button.new()
	_passive_toggle_btn.text = "▾" if _passive_collapsed else "▴"
	_passive_toggle_btn.custom_minimum_size = Vector2(54, 38)
	_passive_toggle_btn.add_theme_font_size_override("font_size", 18)
	_passive_toggle_btn.focus_mode = Control.FOCUS_NONE
	_passive_toggle_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var tog_s := StyleBoxFlat.new()
	tog_s.bg_color = Color(0.18, 0.14, 0.08, 0.90)
	tog_s.corner_radius_top_left = 8
	tog_s.corner_radius_top_right = 8
	tog_s.corner_radius_bottom_left = 8
	tog_s.corner_radius_bottom_right = 8
	_passive_toggle_btn.add_theme_stylebox_override("normal", tog_s)
	_passive_toggle_btn.add_theme_stylebox_override("hover", tog_s)
	_passive_toggle_btn.add_theme_stylebox_override("pressed", tog_s)
	_passive_toggle_btn.add_theme_color_override("font_color", Color(0.96, 0.84, 0.50))
	_passive_toggle_btn.pressed.connect(_toggle_passive_panel)
	pass_header.add_child(_passive_toggle_btn)
	pass_header.add_child(pass_title)
	pass_header.gui_input.connect(func(event: InputEvent) -> void:
		# Handle touches directly on header row (child controls consume input first on mobile).
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				_toggle_passive_panel()
		elif event is InputEventScreenTouch:
			var touch := event as InputEventScreenTouch
			if touch.pressed:
				_toggle_passive_panel()
	)

	_passive_scroll = ScrollContainer.new()
	_passive_scroll.custom_minimum_size = Vector2(0, 260)
	_passive_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_passive_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_passive_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_passive_scroll.visible = not _passive_collapsed
	pass_root.add_child(_passive_scroll)

	_passive_list = VBoxContainer.new()
	_passive_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_passive_list.add_theme_constant_override("separation", 6)
	_passive_scroll.add_child(_passive_list)

	# Joystick visual
	_joy_vis = JoystickVisual.new()
	hud.add_child(_joy_vis)

func _setup_story_debug_overlay(layer: CanvasLayer) -> void:
	if not OS.is_debug_build() or not is_story_test_run:
		return
	var view := get_viewport_rect().size
	_story_debug_toggle = _pause_btn("Show Validator", Color(0.16, 0.20, 0.30, 0.94), Color.WHITE)
	_story_debug_toggle.position = Vector2(view.x - 260.0, 158.0)
	_story_debug_toggle.size = Vector2(230.0, 58.0)
	_story_debug_toggle.custom_minimum_size = Vector2.ZERO
	_story_debug_toggle.add_theme_font_size_override("font_size", 20)
	_story_debug_toggle.pressed.connect(func() -> void:
		_story_debug_overlay_visible = not _story_debug_overlay_visible
		_story_debug_overlay.visible = _story_debug_overlay_visible
		_story_debug_toggle.text = "Hide Validator" if _story_debug_overlay_visible else "Show Validator"
		_refresh_story_debug_overlay(true)
	)
	layer.add_child(_story_debug_toggle)
	_story_debug_overlay = PanelContainer.new()
	_story_debug_overlay.position = Vector2(view.x - 500.0, 228.0)
	_story_debug_overlay.size = Vector2(470.0, 580.0)
	_story_debug_overlay.visible = false
	var panel_style := StyleBoxFlat.new(); panel_style.bg_color = Color(0.015, 0.025, 0.045, 0.94); panel_style.border_color = Color(0.95, 0.68, 0.18, 0.90); panel_style.set_border_width_all(2); panel_style.set_corner_radius_all(18); panel_style.content_margin_left = 18; panel_style.content_margin_right = 18; panel_style.content_margin_top = 16; panel_style.content_margin_bottom = 16; _story_debug_overlay.add_theme_stylebox_override("panel", panel_style)
	layer.add_child(_story_debug_overlay)
	var debug_box := VBoxContainer.new(); debug_box.add_theme_constant_override("separation", 10); _story_debug_overlay.add_child(debug_box)
	_story_debug_label = Label.new()
	_story_debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_story_debug_label.add_theme_font_size_override("font_size", 21)
	_story_debug_label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.84))
	debug_box.add_child(_story_debug_label)
	var request_button := _pause_btn("Request Victory", Color(0.44, 0.20, 0.12, 0.96), Color.WHITE)
	request_button.custom_minimum_size = Vector2(0.0, 64.0)
	request_button.add_theme_font_size_override("font_size", 22)
	request_button.pressed.connect(func() -> void: _request_story_victory("debug_manual_request"))
	debug_box.add_child(request_button)
	_refresh_story_debug_overlay(true)

func _update_story_debug_overlay(delta: float) -> void:
	if _story_debug_overlay == null or not _story_debug_overlay_visible:
		return
	_story_debug_update_timer -= delta
	if _story_debug_update_timer <= 0.0:
		_story_debug_update_timer = 0.25
		_refresh_story_debug_overlay()

func _refresh_story_debug_overlay(force: bool = false) -> void:
	if _story_debug_label == null:
		return
	var state: Dictionary = _story_completion_state()
	var minutes: int = floori(_elapsed / 60.0)
	var seconds: int = floori(_elapsed) % 60
	var lines: Array[String] = [
		"DEV TEST — C%dS%d" % [int(story_stage.get("chapter", 0)), int(story_stage.get("chapter_stage", 0))],
		"Elapsed: %02d:%02d" % [minutes, seconds],
		"Phase: %s" % _story_debug_phase(),
		"",
	]
	var total: int = int(state.get("required_total", 0))
	if total > 1:
		lines.append("Primary: %d / %d" % [int(state.get("required_completed", 0)), total])
	else:
		lines.append("Primary complete: %s" % str(state.get("primary_complete", false)))
	if bool(state.get("staged_required", false)):
		lines.append("Generated: %d / %d" % [int(state.get("required_generated", 0)), total])
		lines.append("Pending objective: %s" % str(state.get("pending_spawn", false)))
		lines.append("Active objectives: %d" % int(state.get("required_active", 0)))
	var objective: String = str(story_stage.get("objective", ""))
	if objective in ["escort", "defend", "hazards"]:
		lines.append("Timer expired: %s" % str(state.get("timer_expired", false)))
	if objective == "escort":
		lines.append("Route complete: %s" % str(state.get("route_complete", false)))
	if objective in ["escort", "defend"]:
		lines.append("Target alive: %s" % str(state.get("target_alive", false)))
	if bool(state.get("finale_required", false)):
		lines.append("Finale required: true")
		lines.append("Finale complete: %s" % str(state.get("finale_complete", false)))
	if bool(state.get("boss_required", false)):
		lines.append("Boss required: true")
		lines.append("Boss defeated: %s" % str(state.get("boss_defeated", false)))
	lines.append("")
	lines.append("Last victory request:")
	lines.append(_story_last_victory_request)
	lines.append("")
	lines.append("Result:")
	lines.append(_story_last_victory_result)
	var text_value: String = "\n".join(lines)
	if force or text_value != _story_debug_signature:
		_story_debug_signature = text_value
		_story_debug_label.text = text_value

func _story_debug_phase() -> String:
	if _chapter_one != null and int(story_stage.get("chapter", 0)) == 1:
		return _chapter_one.phase
	if _chapter_two != null and int(story_stage.get("chapter", 0)) == 2:
		return _chapter_two.phase
	if _chapter_three != null and int(story_stage.get("chapter", 0)) == 3:
		return _chapter_three.phase
	if _chapter_four != null and int(story_stage.get("chapter", 0)) == 4:
		return _chapter_four.phase
	if _story_final_triggered and not _story_final_completed:
		return "final_assault"
	if _adventure_state == "story_boss":
		return "objective_boss"
	if _story_custom_id == "abyss_king":
		return "ritual_anchors" if _story_custom_phase == 1 else ("abyss_crown" if _story_custom_phase == 2 else "abyss_king")
	if _story_custom_id == "frost_mimic":
		return "mimic_battle" if _find_story_enemy("frost_mimic") >= 0 else "mimic_search"
	if _story_custom_id == "thaw_runes":
		return "sequence_reveal" if _story_custom_timer > 0.0 else "rune_activation"
	return _story_custom_id if not _story_custom_id.is_empty() else _adventure_state.trim_prefix("story_")

func _toggle_passive_panel() -> void:
	_passive_collapsed = not _passive_collapsed
	if _passive_scroll != null:
		_passive_scroll.visible = not _passive_collapsed
	if _passive_toggle_btn != null:
		_passive_toggle_btn.text = "▾" if _passive_collapsed else "▴"

func _show_pause_menu() -> void:
	if _game_over:
		return
	_paused = true
	var view: Vector2 = get_viewport_rect().size

	var layer := CanvasLayer.new()
	layer.name = "pause_menu"
	layer.layer = 90
	add_child(layer)

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.62)
	overlay.size  = view
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(overlay)

	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.12, 0.09, 0.06, 0.96)
	ps.corner_radius_top_left    = 28
	ps.corner_radius_top_right   = 28
	ps.corner_radius_bottom_right = 28
	ps.corner_radius_bottom_left  = 28
	ps.border_color = Color(0.72, 0.58, 0.28, 0.80)
	ps.set_border_width_all(3)
	ps.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	ps.shadow_size  = 18
	ps.content_margin_left   = 40
	ps.content_margin_right  = 40
	ps.content_margin_top    = 40
	ps.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", ps)
	var pw: float = 560.0
	panel.custom_minimum_size = Vector2(pw, 0)
	panel.position = Vector2((view.x - pw) * 0.5, view.y * 0.22)
	panel.z_index  = 1
	layer.add_child(panel)

	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if layer.get_node_or_null("ReturnToMenuConfirm") != null:
			return
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and not panel.get_global_rect().has_point(mb.global_position):
				layer.queue_free()
				_paused = false
		elif event is InputEventScreenTouch:
			var touch_event := event as InputEventScreenTouch
			if touch_event.pressed and not panel.get_global_rect().has_point(touch_event.global_position):
				layer.queue_free()
				_paused = false
	)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 22)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Paused"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.97, 0.90, 0.70))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Resume
	var resume_btn := _pause_btn("Resume", Color(0.20, 0.55, 0.22), Color(0.88, 0.98, 0.88))
	vbox.add_child(resume_btn)
	resume_btn.pressed.connect(func() -> void:
		layer.queue_free()
		_paused = false
	)

	# Settings
	var settings_btn := _pause_btn("Settings", Color(0.18, 0.22, 0.45), Color(0.85, 0.88, 1.0))
	vbox.add_child(settings_btn)
	settings_btn.pressed.connect(func() -> void:
		var SETTINGS_SCENE := load("res://scenes/Settings.tscn") as PackedScene
		if SETTINGS_SCENE == null:
			return
		var s: Node = SETTINGS_SCENE.instantiate()
		s.closed.connect(func() -> void: s.queue_free())
		s.logout_requested.connect(func() -> void:
			s.queue_free()
			layer.queue_free()
			match_ended.emit("lobby")
		)
		add_child(s)
		(s as CanvasLayer).layer = 100
	)

	# Return to Main Menu
	var menu_btn := _pause_btn("Return to Menu", Color(0.48, 0.18, 0.10), Color(1.0, 0.88, 0.82))
	vbox.add_child(menu_btn)
	menu_btn.pressed.connect(func() -> void:
		_show_return_to_menu_confirm(layer)
	)

func _show_return_to_menu_confirm(parent_layer: CanvasLayer) -> void:
	var view: Vector2 = get_viewport_rect().size
	var confirm := PanelContainer.new()
	confirm.name = "ReturnToMenuConfirm"
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.12, 0.07, 0.07, 0.98)
	cs.corner_radius_top_left = 18
	cs.corner_radius_top_right = 18
	cs.corner_radius_bottom_right = 18
	cs.corner_radius_bottom_left = 18
	cs.border_color = Color(0.88, 0.34, 0.24, 0.90)
	cs.set_border_width_all(2)
	cs.content_margin_left = 18
	cs.content_margin_right = 18
	cs.content_margin_top = 14
	cs.content_margin_bottom = 14
	confirm.add_theme_stylebox_override("panel", cs)
	confirm.custom_minimum_size = Vector2(min(view.x - 80.0, 700.0), 0.0)
	confirm.position = Vector2((view.x - confirm.custom_minimum_size.x) * 0.5, view.y * 0.34)
	confirm.z_index = 120
	parent_layer.add_child(confirm)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	confirm.add_child(root)

	var title := Label.new()
	title.text = "Return To Main Menu?"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.78))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var msg := Label.new()
	msg.text = "All uncollected ring drops, artifact drops, and current run progress will be lost if you quit now."
	msg.add_theme_font_size_override("font_size", 27)
	msg.add_theme_color_override("font_color", Color(0.94, 0.78, 0.70))
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	root.add_child(msg)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)

	var cancel_btn := _pause_btn("Cancel", Color(0.20, 0.20, 0.26), Color(0.94, 0.94, 0.98))
	cancel_btn.custom_minimum_size = Vector2(0, 72)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cancel_btn)

	var quit_btn := _pause_btn("Quit Run", Color(0.62, 0.18, 0.14), Color(1.0, 0.94, 0.90))
	quit_btn.custom_minimum_size = Vector2(0, 72)
	quit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(quit_btn)

	cancel_btn.pressed.connect(func() -> void:
		confirm.queue_free()
	)
	quit_btn.pressed.connect(func() -> void:
		parent_layer.queue_free()
		if is_story_test_run:
			_finish_story_test("story_test_exit")
		else:
			match_ended.emit("lobby")
	)

func _pause_btn(label: String, bg: Color, fg: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.add_theme_font_size_override("font_size", 38)
	btn.custom_minimum_size = Vector2(0, 88)
	btn.focus_mode = Control.FOCUS_NONE
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(26)
	s.border_color = bg.lightened(0.38)
	s.set_border_width_all(3)
	s.set_content_margin_all(10.0)
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 5)
	var sh := s.duplicate() as StyleBoxFlat
	sh.bg_color = bg.lightened(0.12)
	var sp := s.duplicate() as StyleBoxFlat
	sp.bg_color = bg.darkened(0.12)
	btn.add_theme_stylebox_override("normal",  s)
	btn.add_theme_stylebox_override("hover",   sh)
	btn.add_theme_stylebox_override("pressed", sp)
	btn.add_theme_color_override("font_color", fg)
	return btn

func _update_hud() -> void:
	_hp_fill.size = Vector2(384.0 * clamp(_player_hp / _player_max_hp, 0.0, 1.0), 34)
	_xp_fill.size = Vector2(386.0 * clamp(float(_xp) / float(_xp_next), 0.0, 1.0), 18)
	_level_lbl.text = "LV %d" % _level

	var room: Dictionary = _current_room()
	var room_name: String = room.get("name", "Room") as String
	var room_desc: String = room.get("desc", "") as String
	var room_short: String = room.get("short", room_desc) as String
	if room_name.length() > 18:
		room_name = room_name.substr(0, 15) + "..."

	var m: int = int(_elapsed) / 60
	var s: int = int(_elapsed) % 60
	_time_lbl.text = "%d:%02d   |   Kills: %d" % [m, s, _kills]
	_kill_lbl.text = "Keys: %d" % PurchaseStore.get_key_count(account_username)
	_fit_hud_chip(_time_chip, _time_lbl, 96.0, 740.0)
	_fit_hud_chip(_keys_chip, _kill_lbl, 160.0, 320.0)

	if _room_detail_lbl != null:
		_room_detail_lbl.add_theme_color_override("font_color", (room.get("col", Color(0.80, 0.76, 0.65)) as Color).lerp(Color(0.90, 0.86, 0.76), 0.4))
		_room_detail_lbl.text = ("Depth %d - %s" if not dungeon_mode.is_empty() else "Wave %d - %s") % [_wave, room_name]
		_fit_hud_chip(_room_chip, _room_detail_lbl, 220.0, 740.0)

	if _room_effect_lbl != null:
		_room_effect_lbl.add_theme_color_override("font_color", (room.get("col", Color(0.95, 0.84, 0.54)) as Color).lerp(Color(0.98, 0.90, 0.70), 0.25))
		_room_effect_lbl.text = room_short.strip_edges()
		_fit_hud_chip(_room_effect_chip, _room_effect_lbl, 240.0, 620.0)

	if _enemy_mod_lbl != null:
		var mode_objective: String = _mode_objective_text()
		if not mode_objective.is_empty():
			_enemy_mod_lbl.text = mode_objective
			_enemy_mod_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_enemy_mod_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_enemy_mod_lbl.position = Vector2(56.0, get_viewport_rect().size.y - 98.0)
			_enemy_mod_lbl.size = Vector2(get_viewport_rect().size.x - 112.0, 88.0)
			_affix_chip.position = Vector2(24.0, get_viewport_rect().size.y - 104.0)
			_affix_chip.size = Vector2(get_viewport_rect().size.x - 48.0, 98.0)
		elif _wave >= 10 and not _active_enemy_mod.is_empty():
			var affix_text: String = "Floor affix: %s" % _active_enemy_mod_name
			if affix_text.length() > 40:
				affix_text = affix_text.substr(0, 37) + "..."
			_enemy_mod_lbl.text = affix_text
		else:
			_enemy_mod_lbl.text = "Floor affix: none"
		if mode_objective.is_empty():
			_enemy_mod_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
			_enemy_mod_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_enemy_mod_lbl.position = Vector2(56.0, get_viewport_rect().size.y - 96.0)
			_enemy_mod_lbl.size.y = 44.0
			_affix_chip.position = Vector2(24.0, get_viewport_rect().size.y - 102.0)
			_affix_chip.size.y = 58.0
			_fit_hud_chip(_affix_chip, _enemy_mod_lbl, 260.0, get_viewport_rect().size.x - 48.0)

	_update_skill_cooldown_hud()
	_refresh_passive_panel()
	_update_story_objective_button()

func _on_story_objective_start_pressed() -> void:
	if _adventure_state == "story_chapter_one" and _chapter_one != null:
		_handle_chapter_one_action()
		_update_story_objective_button()
		return
	if _chapter_five != null and int(story_stage.get("chapter", 0)) == 5:
		if _chapter_five.stage_number == 1 and _chapter_five.phase == "route_selection":
			_show_c5_route_choice()
		elif _chapter_five.stage_number == 4:
			_begin_c5_eclipse_sync()
		_update_story_objective_button()
		return
	match _adventure_state:
		"story_escort_wait": _begin_story_escort()
		"story_defend_wait": _begin_story_defense()
		"story_nests": _spawn_story_nest()
	_update_story_objective_button()

func _update_story_objective_button() -> void:
	if _objective_start_btn == null:
		return
	_objective_start_btn.visible = false
	_objective_start_btn.disabled = false
	if _adventure_state == "story_chapter_one" and _chapter_one != null:
		match _chapter_one.stage_number:
			1:
				if not _chapter_one.flag("mission_started"):
					_objective_start_btn.text = "START ESCORT · FOLLOW / WAIT / HURRY"
					_objective_start_btn.visible = true
				elif _chapter_one.phase in ["first_route", "short_route", "long_route", "final_pursuit"]:
					_objective_start_btn.text = "SCOUT: %s · TAP TO CHANGE" % _c1_command.to_upper()
					_objective_start_btn.visible = true
			2:
				if not _chapter_one.flag("mission_started"):
					_objective_start_btn.text = "SUMMON MUSHROOM SHRINE"
					_objective_start_btn.visible = true
			3:
				if not _chapter_one.flag("mission_started"):
					_objective_start_btn.text = "TRACK THE SWARM NEST"
					_objective_start_btn.visible = true
			4:
				if not _chapter_one.flag("mission_started"):
					_objective_start_btn.text = "TRACK THE FIRST KEY CARRIER"
					_objective_start_btn.visible = true
		return
	if _chapter_five != null and int(story_stage.get("chapter", 0)) == 5:
		if _chapter_five.stage_number == 1 and _chapter_five.phase == "route_selection":
			_objective_start_btn.text = "CHOOSE INFILTRATION ROUTE"
			_objective_start_btn.visible = true
		elif _chapter_five.stage_number == 4 and _chapter_five.phase == "obelisk_preparation" and _chapter_five.flag("preparation_complete") and _chapter_five.flag("route_prepared"):
			for prop in _adventure_props:
				if str(prop.get("kind", "")) == "eclipse_obelisk" and int(prop.get("obelisk", -1)) == 0 and (prop.pos as Vector2).distance_to(_player_pos) <= 210.0:
					_objective_start_btn.text = "BEGIN ECLIPSE SYNCHRONIZATION"
					_objective_start_btn.visible = true
					break
		return
	match _adventure_state:
		"story_escort_wait":
			_objective_start_btn.text = "START SCOUT ESCORT"
			_objective_start_btn.visible = true
		"story_defend_wait":
			_objective_start_btn.text = "SUMMON SHRINE"
			_objective_start_btn.visible = true
		"story_nests":
			if _story_nests_destroyed < 3 and _find_adventure_prop("nest") < 0:
				_objective_start_btn.text = "SPAWN NEST %d OF 3" % (_story_nests_destroyed + 1)
				_objective_start_btn.visible = true

func _show_c5_route_choice() -> void:
	if _adventure_choice_layer != null or _chapter_five == null or _chapter_five.phase != "route_selection": return
	_paused = true
	var view: Vector2 = get_viewport_rect().size
	var layer := CanvasLayer.new()
	layer.layer = 135
	add_child(layer)
	_adventure_choice_layer = layer
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.01, 0.04, 0.90)
	shade.size = view
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(shade)
	var box := VBoxContainer.new()
	box.position = Vector2(65.0, view.y * 0.20)
	box.size = Vector2(view.x - 130.0, 650.0)
	box.add_theme_constant_override("separation", 18)
	layer.add_child(box)
	var title := Label.new()
	title.text = "CHOOSE INFILTRATION ROUTE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	box.add_child(title)
	var choices: Array[Dictionary] = [
		{"id":"shadow", "text":"SHADOW ROUTE\nLongest · More hiding zones · Fewer sentries"},
		{"id":"mechanism", "text":"MECHANISM ROUTE\nDisable security switches · Moderate distance"},
		{"id":"risk", "text":"RISK ROUTE\nFastest · Dense patrol coverage"},
	]
	for choice in choices:
		var button := _pause_btn(str(choice.text), Color(0.26, 0.18, 0.42), Color.WHITE)
		button.custom_minimum_size = Vector2(0.0, 122.0)
		button.add_theme_font_size_override("font_size", 30)
		button.pressed.connect(_select_c5_route.bind(str(choice.id)))
		box.add_child(button)

func _select_c5_route(route: String) -> void:
	if _adventure_choice_layer != null:
		_adventure_choice_layer.queue_free()
		_adventure_choice_layer = null
	_paused = false
	_begin_c5_infiltration(route)

func _handle_chapter_one_action() -> void:
	match _chapter_one.stage_number:
		1:
			if not _chapter_one.flag("mission_started"):
				_chapter_one.set_flag("mission_started")
				_story_route_waypoints = [_player_pos + Vector2(1400.0, -360.0), _player_pos + Vector2(4000.0, 420.0)]
				_story_route_index = 0
				_adventure_props.append({"kind":"scout", "pos":_player_pos + Vector2(-100.0, 20.0), "hp":520.0, "max_hp":520.0})
				_c1_enter_phase("first_route")
			elif _chapter_one.phase == "route_choice":
				_show_c1_route_choice()
			else:
				_c1_command = "wait" if _c1_command == "follow" else ("hurry" if _c1_command == "wait" else "follow")
				_story_log("Escort command: %s" % _c1_command)
		2:
			if not _chapter_one.flag("mission_started"):
				_chapter_one.set_flag("mission_started")
				_adventure_timer = 0.0
				_c1_enter_phase("energy_defence")
		3:
			if not _chapter_one.flag("mission_started"):
				_chapter_one.set_flag("mission_started")
				_spawn_c1_nest(1)
		4:
			if not _chapter_one.flag("mission_started"):
				_chapter_one.set_flag("mission_started")
				_begin_c1_key_hunt(1)

func _show_c1_route_choice() -> void:
	if _chapter_one == null or _chapter_one.phase != "route_choice" or _adventure_choice_layer != null:
		return
	_paused = true
	var view: Vector2 = get_viewport_rect().size
	var layer := CanvasLayer.new()
	layer.layer = 130
	add_child(layer)
	_adventure_choice_layer = layer
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.02, 0.84)
	shade.size = view
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(shade)
	var box := VBoxContainer.new()
	box.position = Vector2(56.0, view.y * 0.28)
	box.size = Vector2(view.x - 112.0, 370.0)
	box.add_theme_constant_override("separation", 18)
	layer.add_child(box)
	var title := Label.new()
	title.text = "CHOOSE THE SCOUT'S ROUTE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32))
	box.add_child(title)
	var short_route := _pause_btn("SHORT ROUTE\nFaster · More danger", Color(0.48, 0.24, 0.08), Color.WHITE)
	short_route.custom_minimum_size = Vector2(0.0, 112.0)
	short_route.add_theme_font_size_override("font_size", 30)
	short_route.pressed.connect(_choose_c1_route.bind("short"))
	box.add_child(short_route)
	var long_route := _pause_btn("LONG ROUTE\nSafer · More ground to cover", Color(0.16, 0.34, 0.24), Color.WHITE)
	long_route.custom_minimum_size = Vector2(0.0, 112.0)
	long_route.add_theme_font_size_override("font_size", 30)
	long_route.pressed.connect(_choose_c1_route.bind("long"))
	box.add_child(long_route)

func _choose_c1_route(route: String) -> void:
	if _chapter_one == null or _chapter_one.phase != "route_choice" or route not in ["short", "long"]:
		return
	_c1_route_choice = route
	if _adventure_choice_layer != null:
		_adventure_choice_layer.queue_free()
		_adventure_choice_layer = null
	_paused = false
	var scout_index: int = _find_adventure_prop("scout")
	var origin: Vector2 = _adventure_props[scout_index].pos as Vector2 if scout_index >= 0 else _player_pos
	_story_route_waypoints.clear()
	if route == "short":
		_story_route_waypoints.append(origin + Vector2(1800.0, -720.0))
		_story_route_waypoints.append(origin + Vector2(4200.0, 0.0))
	else:
		_story_route_waypoints.append(origin + Vector2(1200.0, 720.0))
		_story_route_waypoints.append(origin + Vector2(2800.0, 980.0))
		_story_route_waypoints.append(origin + Vector2(5200.0, 0.0))
	_story_route_index = 0
	_c1_enter_phase("%s_route" % route)
	_story_log("Route selected: %s" % route)

func _fit_hud_chip(chip: TextureRect, label: Label, min_width: float, max_width: float) -> void:
	if chip == null or label == null:
		return
	var text_width: float = label.get_combined_minimum_size().x
	var width: float = clampf(text_width + 64.0, min_width, max_width)
	chip.size.x = width
	label.size.x = max(width - 64.0, 0.0)

func _refresh_passive_panel() -> void:
	if _passive_list == null:
		return
	var rows: Array[Dictionary] = _passive_rows_for_hud()
	var sig_parts: Array[String] = []
	for row_any in rows:
		var row: Dictionary = row_any as Dictionary
		sig_parts.append("%s|%s" % [String(row.get("label", "")), String(row.get("value", ""))])
	var sig: String = "\n".join(sig_parts)
	if sig == _passive_signature:
		return
	_passive_signature = sig

	for c in _passive_list.get_children():
		c.queue_free()

	if rows.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No passive bonuses"
		empty_lbl.add_theme_font_size_override("font_size", 28)
		empty_lbl.add_theme_color_override("font_color", Color(0.74, 0.68, 0.58))
		_passive_list.add_child(empty_lbl)
		return

	for row_any in rows:
		var row: Dictionary = row_any as Dictionary
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_passive_list.add_child(line)

		var icon_lbl := Label.new()
		icon_lbl.text = String(row.get("icon", "✦"))
		icon_lbl.add_theme_font_size_override("font_size", 24)
		icon_lbl.add_theme_color_override("font_color", Color(0.94, 0.78, 0.34))
		icon_lbl.custom_minimum_size = Vector2(28, 0)
		line.add_child(icon_lbl)

		var label_lbl := Label.new()
		label_lbl.text = String(row.get("label", ""))
		label_lbl.add_theme_font_size_override("font_size", 26)
		label_lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.78))
		label_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_child(label_lbl)

		var value_lbl := Label.new()
		value_lbl.text = String(row.get("value", ""))
		value_lbl.add_theme_font_size_override("font_size", 24)
		value_lbl.add_theme_color_override("font_color", Color(0.98, 0.86, 0.48))
		value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_lbl.custom_minimum_size = Vector2(92, 0)
		value_lbl.size_flags_horizontal = Control.SIZE_SHRINK_END
		line.add_child(value_lbl)

func _passive_rows_for_hud() -> Array[Dictionary]:
	var totals: Dictionary = _ring_bonuses.duplicate(true)
	totals["skill_dmg"] = float(totals.get("skill_dmg", 0.0)) + _artifact_wheel_skill_dmg
	totals["move_speed_mul"] = float(totals.get("move_speed_mul", 0.0)) + _artifact_wheel_move_mul
	totals["skill_cd"] = float(totals.get("skill_cd", 0.0)) - _artifact_wheel_cd

	var order: Array[String] = [
		"projectile_spd", "skill_dmg", "skill_cd", "move_speed_mul", "pickup_radius",
		"crit_chance", "max_hp_pct", "xp_bonus", "luck", "ring_drop_rate", "projectile_homing"
	]
	var out: Array[Dictionary] = []
	for key in order:
		var v: float = float(totals.get(key, 0.0))
		if abs(v) < 0.0001:
			continue
		out.append({
			"icon": _passive_icon_for_key(key),
			"label": _passive_label_for_key(key),
			"value": _passive_value_for_key(key, v),
		})
	return out

func _passive_label_for_key(key: String) -> String:
	match key:
		"projectile_spd": return "Projectile Speed"
		"skill_dmg": return "Skill Damage"
		"skill_cd": return "Cooldown"
		"move_speed_mul": return "Move Speed"
		"pickup_radius": return "Pickup Radius"
		"crit_chance": return "Critical Chance"
		"max_hp_pct": return "Maximum Health"
		"xp_bonus": return "Experience Bonus"
		"luck": return "Luck"
		"ring_drop_rate": return "Ring Drop Rate"
		"projectile_homing": return "Projectile Homing"
		_: return key.replace("_", " ").capitalize()

func _passive_value_for_key(key: String, value: float) -> String:
	if key in ["projectile_spd", "skill_dmg", "skill_cd", "move_speed_mul", "pickup_radius", "crit_chance", "max_hp_pct", "xp_bonus", "luck", "ring_drop_rate", "projectile_homing"]:
		return "%+d%%" % int(round(value * 100.0))
	return "%+s" % String.num(value, 2)

func _passive_icon_for_key(key: String) -> String:
	match key:
		"projectile_spd": return "➤"
		"skill_dmg": return "✶"
		"skill_cd": return "⌛"
		"move_speed_mul": return "🦶"
		"pickup_radius": return "🧲"
		"crit_chance": return "✦"
		"max_hp_pct": return "❤"
		"xp_bonus": return "★"
		"luck": return "☘"
		"ring_drop_rate": return "◍"
		"projectile_homing": return "↺"
		_: return "✦"

func _update_skill_icons() -> void:
	if _skill_icon_row == null:
		return

	_skill_hud_widgets.clear()
	for c in _skill_icon_row.get_children():
		_skill_icon_row.remove_child(c)
		c.queue_free()

	for sk in _skills:
		var sid: String = sk["id"] as String
		if not SKILL_DEFS.has(sid):
			continue
		var lvl: int = sk["level"] as int
		var sdef: Dictionary = SKILL_DEFS[sid] as Dictionary
		var skill_col: Color = sdef["col"] as Color
		var tex: Texture2D = _skill_icon_texture(sid)

		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(96, 104)
		slot.size = Vector2(96, 104)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.tooltip_text = "%s — Level %d" % [String(sdef.get("name", sid)), lvl]

		var slot_style := StyleBoxFlat.new()
		slot_style.bg_color = Color(0.055, 0.045, 0.035, 0.94)
		slot_style.border_color = skill_col.darkened(0.22)
		slot_style.set_border_width_all(2)
		slot_style.corner_radius_top_left = 14
		slot_style.corner_radius_top_right = 14
		slot_style.corner_radius_bottom_left = 14
		slot_style.corner_radius_bottom_right = 14
		slot_style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
		slot_style.shadow_size = 7
		slot_style.shadow_offset = Vector2(0, 3)
		slot.add_theme_stylebox_override("panel", slot_style)
		_skill_icon_row.add_child(slot)

		var icon_frame := Panel.new()
		icon_frame.position = Vector2(7, 7)
		icon_frame.size = Vector2(82, 82)
		icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_frame.clip_contents = true
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = Color(0.03, 0.03, 0.03, 0.96)
		frame_style.border_color = Color(skill_col.r, skill_col.g, skill_col.b, 0.72)
		frame_style.set_border_width_all(2)
		frame_style.corner_radius_top_left = 10
		frame_style.corner_radius_top_right = 10
		frame_style.corner_radius_bottom_left = 10
		frame_style.corner_radius_bottom_right = 10
		icon_frame.add_theme_stylebox_override("panel", frame_style)
		slot.add_child(icon_frame)

		if tex != null:
			var grey_icon := TextureRect.new()
			grey_icon.texture = tex
			grey_icon.material = _skill_greyscale_icon_material()
			grey_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			grey_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			grey_icon.position = Vector2(4, 4)
			grey_icon.size = Vector2(74, 74)
			grey_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_frame.add_child(grey_icon)

			var reveal := Control.new()
			reveal.position = Vector2(4, 4)
			reveal.size = Vector2(74, 74)
			reveal.clip_contents = true
			reveal.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_frame.add_child(reveal)

			var colour_icon := TextureRect.new()
			colour_icon.texture = tex
			colour_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			colour_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			colour_icon.position = Vector2.ZERO
			colour_icon.size = Vector2(74, 74)
			colour_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			reveal.add_child(colour_icon)

			_skill_hud_widgets[sid] = {
				"reveal": reveal,
				"cooldown_label": null,
				"level_label": null,
				"slot": slot,
				"icon_height": 74.0,
			}
		else:
			var fallback := Label.new()
			fallback.text = _skill_icon_abbrev(sid)
			fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
			fallback.add_theme_font_size_override("font_size", 30)
			fallback.add_theme_color_override("font_color", skill_col)
			fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_frame.add_child(fallback)
			_skill_hud_widgets[sid] = {
				"reveal": null,
				"cooldown_label": null,
				"level_label": null,
				"slot": slot,
				"icon_height": 74.0,
			}

		var cooldown_lbl := Label.new()
		cooldown_lbl.text = ""
		cooldown_lbl.position = Vector2(5, 27)
		cooldown_lbl.size = Vector2(86, 34)
		cooldown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cooldown_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cooldown_lbl.add_theme_font_size_override("font_size", 23)
		cooldown_lbl.add_theme_color_override("font_color", Color.WHITE)
		cooldown_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		cooldown_lbl.add_theme_constant_override("outline_size", 6)
		cooldown_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(cooldown_lbl)

		var level_lbl := Label.new()
		level_lbl.text = "Lv%d" % lvl
		level_lbl.position = Vector2(44, 78)
		level_lbl.size = Vector2(46, 22)
		level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		level_lbl.add_theme_font_size_override("font_size", 15)
		level_lbl.add_theme_color_override("font_color", Color(1.0, 0.93, 0.72))
		level_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		level_lbl.add_theme_constant_override("outline_size", 4)
		level_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(level_lbl)

		var widget: Dictionary = _skill_hud_widgets[sid] as Dictionary
		widget["cooldown_label"] = cooldown_lbl
		widget["level_label"] = level_lbl
		_skill_hud_widgets[sid] = widget

	_update_skill_cooldown_hud()

func _update_skill_cooldown_hud() -> void:
	if _skill_hud_widgets.is_empty():
		return

	for sk in _skills:
		var sid: String = sk["id"] as String
		if not _skill_hud_widgets.has(sid):
			continue
		var widget: Dictionary = _skill_hud_widgets[sid] as Dictionary
		var reveal: Control = widget.get("reveal", null) as Control
		var cooldown_lbl: Label = widget.get("cooldown_label", null) as Label
		var level_lbl: Label = widget.get("level_label", null) as Label
		var slot: Panel = widget.get("slot", null) as Panel
		var icon_height: float = float(widget.get("icon_height", 74.0))
		var lvl: int = int(sk.get("level", 1))
		var total_cd: float = _skill_cooldown_total_for_hud(sk)
		var remaining: float = max(float(sk.get("timer", 0.0)), 0.0)

		# Hawk Companion stays fully coloured while the summoned hawk is active;
		# its grey cooldown begins only after the active duration ends.
		var is_temporarily_active: bool = sid == "hawk_companion" and float(sk.get("active_t", 0.0)) > 0.0
		var progress: float = 1.0
		if total_cd > 0.0 and not is_temporarily_active:
			var safe_total: float = max(max(total_cd, remaining), 0.001)
			progress = clamp(1.0 - remaining / safe_total, 0.0, 1.0)

		if reveal != null:
			reveal.size.y = icon_height * progress

		if cooldown_lbl != null:
			if is_temporarily_active:
				cooldown_lbl.text = "ACTIVE"
				cooldown_lbl.add_theme_font_size_override("font_size", 16)
			elif total_cd > 0.0 and remaining > 0.05:
				cooldown_lbl.text = "%.1fs" % remaining
				cooldown_lbl.add_theme_font_size_override("font_size", 23)
			else:
				cooldown_lbl.text = ""

		if level_lbl != null:
			level_lbl.text = "★" if not String(sk.get("evolution", "")).is_empty() else "Lv%d" % lvl

		if slot != null and SKILL_DEFS.has(sid):
			var sdef: Dictionary = SKILL_DEFS[sid] as Dictionary
			var name: String = String(sdef.get("name", sid))
			var evolution := _skill_evolution_definition(sid)
			if not evolution.is_empty():
				name = String(evolution.get("name", name))
			if total_cd > 0.0:
				slot.tooltip_text = "%s — Level %d — Cooldown %.1fs" % [name, lvl, total_cd]
			else:
				slot.tooltip_text = "%s — Level %d — Always active" % [name, lvl]

func _skill_cooldown_total_for_hud(sk: Dictionary) -> float:
	var sid: String = String(sk.get("id", ""))
	var lvl: int = int(sk.get("level", 1))
	if sid.is_empty() or not SKILL_DEFS.has(sid):
		return 0.0

	# These two skills use custom cooldown formulas in _update_skills().
	if sid == "fireball":
		return _apply_skill_cooldown_bonus(1.2 - float(lvl) * 0.12)
	if sid == "shadow_clone":
		return max(4.0, 10.0 - float(lvl) * 1.2)

	var sdef: Dictionary = SKILL_DEFS[sid] as Dictionary
	var levels: Array = sdef.get("lvl", []) as Array
	if levels.is_empty():
		return 0.0
	var idx: int = clampi(lvl - 1, 0, levels.size() - 1)
	var level_data: Dictionary = levels[idx] as Dictionary
	if not level_data.has("cd"):
		return 0.0
	return _apply_skill_cooldown_bonus(float(level_data["cd"]))

func _skill_greyscale_icon_material() -> ShaderMaterial:
	if _skill_greyscale_material != null:
		return _skill_greyscale_material
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float grey = dot(tex.rgb, vec3(0.2126, 0.7152, 0.0722));
	COLOR = vec4(vec3(grey * 0.62), tex.a * 0.92);
}
"""
	_skill_greyscale_material = ShaderMaterial.new()
	_skill_greyscale_material.shader = shader
	return _skill_greyscale_material

func _skill_icon_path_candidates(sid: String) -> Array[String]:
	var out: Array[String] = ["res://assets/skills/%s.png" % sid]
	if sid == "time_warp":
		out.append("res://assets/skills/time_wrap.png")
	return out

func _skill_icon_texture(sid: String) -> Texture2D:
	if _skill_icon_cache.has(sid):
		return _skill_icon_cache[sid] as Texture2D
	for path in _skill_icon_path_candidates(sid):
		if ResourceLoader.exists(path):
			var tex: Texture2D = load(path) as Texture2D
			if tex != null:
				var cropped: Texture2D = _crop_transparent_skill_icon(tex)
				_skill_icon_cache[sid] = cropped
				return cropped
	return null

func _crop_transparent_skill_icon(tex: Texture2D) -> Texture2D:
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return tex
	var min_x: int = img.get_width()
	var min_y: int = img.get_height()
	var max_x: int = -1
	var max_y: int = -1
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if img.get_pixel(x, y).a <= 0.02:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < 0 or max_y < 0:
		return tex
	if min_x == 0 and min_y == 0 and max_x == img.get_width() - 1 and max_y == img.get_height() - 1:
		return tex
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
	return atlas

func _skill_icon_abbrev(sid: String) -> String:
	if not SKILL_DEFS.has(sid):
		return "?"
	var name: String = String((SKILL_DEFS[sid] as Dictionary).get("name", sid)).strip_edges()
	if name.is_empty():
		return "?"
	var words: PackedStringArray = name.split(" ", false)
	var out: String = ""
	for word in words:
		if word.is_empty():
			continue
		out += word.substr(0, 1).to_upper()
		if out.length() >= 2:
			break
	if out.is_empty():
		out = name.substr(0, 1).to_upper()
	return out

func _make_skill_card_icon(sid: String, icon_color: Color, size: float, is_ulti: bool = false, is_combo: bool = false) -> Control:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.06, 0.96).lerp(icon_color, 0.16 if not is_ulti else 0.24)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.set_border_width_all(3 if is_ulti else 2)
	style.border_color = Color(1.0, 0.82, 0.18) if is_ulti else (Color(0.46, 0.98, 0.90) if is_combo else icon_color)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(size, size)
	panel.size = Vector2(size, size)
	panel.clip_contents = true
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tex: Texture2D = _skill_icon_texture(sid)
	if tex != null:
		var inset: float = max(6.0, floor(size * 0.08))
		var icon := TextureRect.new()
		icon.texture = tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.position = Vector2(inset, inset)
		icon.size = Vector2(size - inset * 2.0, size - inset * 2.0)
		panel.add_child(icon)
		return panel

	var glow := ColorRect.new()
	glow.color = Color(icon_color.r, icon_color.g, icon_color.b, 0.18)
	glow.position = Vector2(10, 10)
	glow.size = Vector2(size - 20.0, size - 20.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(glow)

	var label := Label.new()
	label.text = _skill_icon_abbrev(sid)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 34 if not is_ulti else 38)
	label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88) if is_ulti else Color(0.96, 0.93, 0.86))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)

	return panel

# ═════════════════════════════════════════════════════════════════════════════
# SKILL SELECT UI
# ═════════════════════════════════════════════════════════════════════════════

func _show_skill_select(is_initial: bool, _is_reroll: bool = false) -> void:
	if not _is_reroll:
		_skill_reroll_used = false
	_paused = true
	var choices: Array[Dictionary] = _build_skill_choices()
	var view: Vector2 = get_viewport_rect().size
	var layer := CanvasLayer.new()
	add_child(layer)

	# Dark overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	overlay.size  = view
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(overlay)

	# Title
	var title := Label.new()
	title.text = "Choose a Bonus Skill!" if is_initial else "Level Up! Pick a Skill"
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color(0.98, 0.88, 0.50))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, view.y * 0.14); title.size = Vector2(view.x, 65)
	layer.add_child(title)

	# Level label (during level-up)
	if not is_initial:
		var lv_lbl := Label.new()
		lv_lbl.text = "Now Level %d" % _level
		lv_lbl.add_theme_font_size_override("font_size", 28)
		lv_lbl.add_theme_color_override("font_color", Color(0.72, 0.66, 0.50))
		lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lv_lbl.position = Vector2(0, view.y * 0.14 + 58); lv_lbl.size = Vector2(view.x, 36)
		layer.add_child(lv_lbl)

	# 3 skill cards
	var card_w: float = view.x - 80.0
	var card_h: float = 242.0
	var gap: float    = 18.0
	var card_count: int = mini(choices.size(), 3)
	var total_h: float = float(card_count) * card_h + float(max(card_count - 1, 0)) * gap
	var start_y: float = (view.y - total_h) * 0.5

	for i in card_count:
		var ch: Dictionary  = choices[i]
		var sid: String     = ch["id"] as String
		var new_lvl: int    = ch["lvl"] as int
		var is_up: bool     = (ch["type"] as String) == "upgrade"
		var evolution_id: String = String(ch.get("evolution", ""))
		var is_evolution := not evolution_id.is_empty()
		var is_ulti: bool   = ch.get("is_ulti", false) as bool
		var is_combo: bool  = ch.get("is_combo", false) as bool
		var sdef: Dictionary = SKILL_DEFS[sid] as Dictionary
		var levels: Array    = sdef["lvl"] as Array
		var level_index := clampi(new_lvl - 1, 0, maxi(levels.size() - 1, 0))
		var ldata: Dictionary = (levels[level_index] as Dictionary) if not levels.is_empty() else {"note": String(sdef.get("short", "Skill upgrade"))}
		var scol: Color       = sdef["col"] as Color
		if is_evolution:
			ldata = {"note": String(ch.get("note", "Choose this evolution"))}
			scol = ch.get("color", scol) as Color
		# Golden override for ulti cards
		if is_ulti: scol = Color(1.0, 0.78, 0.08)

		var card := Button.new()
		card.custom_minimum_size = Vector2(card_w, card_h)
		card.size     = Vector2(card_w, card_h)
		card.position = Vector2(40, start_y + float(i) * (card_h + gap))
		card.text     = ""
		card.focus_mode = Control.FOCUS_NONE

		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.14, 0.10, 0.02, 0.97) if is_ulti else Color(0.11, 0.09, 0.07, 0.96)
		bg.corner_radius_top_left = 20; bg.corner_radius_top_right = 20
		bg.corner_radius_bottom_right = 20; bg.corner_radius_bottom_left = 20
		bg.set_border_width_all(3); bg.border_color = scol.darkened(0.05)
		bg.shadow_color = Color(scol.r, scol.g, scol.b, 0.38 if is_ulti else 0.28); bg.shadow_size = 16 if is_ulti else 12; bg.shadow_offset = Vector2(0, 4)
		card.add_theme_stylebox_override("normal", bg)
		var hov := StyleBoxFlat.new()
		hov.bg_color = Color(0.20, 0.14, 0.02, 0.98) if is_ulti else Color(0.18, 0.14, 0.10, 0.98)
		hov.corner_radius_top_left = 20; hov.corner_radius_top_right = 20
		hov.corner_radius_bottom_right = 20; hov.corner_radius_bottom_left = 20
		hov.set_border_width_all(4); hov.border_color = scol
		hov.shadow_color = Color(scol.r, scol.g, scol.b, 0.55 if is_ulti else 0.45); hov.shadow_size = 22 if is_ulti else 18; hov.shadow_offset = Vector2(0, 4)
		card.add_theme_stylebox_override("hover", hov)

		# Badge
		var badge := Label.new()
		if is_ulti:
			badge.text = "✦ ULTIMATE SKILL"
			badge.add_theme_color_override("font_color", Color(1.0, 0.82, 0.08))
		elif is_combo:
			badge.text = "COMBINATION"
			badge.add_theme_color_override("font_color", Color(0.46, 0.98, 0.90))
		elif is_evolution:
			badge.text = "✦ SKILL EVOLUTION"
			badge.add_theme_color_override("font_color", Color(1.0, 0.82, 0.22))
		elif is_up:
			badge.text = "UPGRADE"
			badge.add_theme_color_override("font_color", Color(0.90, 0.72, 0.20))
		else:
			badge.text = "NEW"
			badge.add_theme_color_override("font_color", Color(0.32, 0.95, 0.55))
		badge.add_theme_font_size_override("font_size", 15 if not is_ulti else 17)
		badge.position = Vector2(202, 16); badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(badge)

		var skill_icon := _make_skill_card_icon(sid, scol, 164.0, is_ulti, is_combo)
		skill_icon.position = Vector2(22, 40)
		card.add_child(skill_icon)

		if is_ulti:
			var unlock_lbl := Label.new()
			unlock_lbl.text = "Unlocked: 2 skills mastered"
			unlock_lbl.add_theme_font_size_override("font_size", 13)
			unlock_lbl.add_theme_color_override("font_color", Color(0.82, 0.68, 0.24, 0.80))
			unlock_lbl.position = Vector2(card_w - 240, 14); unlock_lbl.size = Vector2(228, 20)
			unlock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			unlock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(unlock_lbl)

		# Name
		var nm := Label.new()
		nm.text = String(ch.get("name", sdef["name"]))
		nm.add_theme_font_size_override("font_size", 40)
		nm.add_theme_color_override("font_color", scol)
		nm.position = Vector2(202, 46); nm.size = Vector2(card_w - 320, 54)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(nm)

		# Level
		var lv := Label.new()
		lv.text = "EVOLVED" if is_evolution else "Level %d" % new_lvl
		lv.add_theme_font_size_override("font_size", 21)
		lv.add_theme_color_override("font_color", Color(0.60, 0.55, 0.42))
		lv.position = Vector2(card_w - 144, 54); lv.size = Vector2(128, 32)
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lv)

		# Description
		var desc := Label.new()
		desc.text = ldata["note"] as String
		desc.add_theme_font_size_override("font_size", 30)
		desc.add_theme_color_override("font_color", Color(0.82, 0.76, 0.65))
		desc.position = Vector2(202, 112); desc.size = Vector2(card_w - 224, 106)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(desc)

		var cap_sid: String = sid
		var cap_lvl: int    = new_lvl
		var cap_evolution: String = evolution_id
		var cap_lay: Node   = layer
		card.pressed.connect(func() -> void:
			_pick_skill(cap_sid, cap_lvl, cap_evolution)
			cap_lay.queue_free()
			_paused = false
		)
		layer.add_child(card)

	# ── Watch Ad to Reroll button ─────────────────────────────────────────────
	var reroll_y: float = start_y + float(card_count) * card_h + float(max(card_count - 1, 0)) * gap + 20.0
	var reroll_btn := Button.new()
	reroll_btn.custom_minimum_size = Vector2(card_w, 62)
	reroll_btn.size     = Vector2(card_w, 62)
	reroll_btn.position = Vector2(40, reroll_y)
	reroll_btn.focus_mode = Control.FOCUS_NONE

	if _skill_reroll_used:
		reroll_btn.text = "Reroll used for this level-up"
		reroll_btn.disabled = true
		var ds := StyleBoxFlat.new()
		ds.bg_color = Color(0.16, 0.16, 0.16, 0.55)
		ds.corner_radius_top_left = 18; ds.corner_radius_top_right = 18
		ds.corner_radius_bottom_right = 18; ds.corner_radius_bottom_left = 18
		ds.set_border_width_all(2); ds.border_color = Color(0.35, 0.35, 0.35, 0.5)
		reroll_btn.add_theme_stylebox_override("disabled", ds)
		reroll_btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.45, 0.45))
		reroll_btn.add_theme_font_size_override("font_size", 24)
	else:
		reroll_btn.text = "Watch Ad to Reroll Skills"
		reroll_btn.add_theme_font_size_override("font_size", 26)
		reroll_btn.add_theme_color_override("font_color", Color(0.12, 0.08, 0.02))
		var ns := StyleBoxFlat.new()
		ns.bg_color = Color(0.95, 0.78, 0.15, 0.95)
		ns.corner_radius_top_left = 18; ns.corner_radius_top_right = 18
		ns.corner_radius_bottom_right = 18; ns.corner_radius_bottom_left = 18
		ns.set_border_width_all(2); ns.border_color = Color(1.0, 0.92, 0.38)
		ns.shadow_color = Color(0.95, 0.78, 0.15, 0.40); ns.shadow_size = 10; ns.shadow_offset = Vector2(0, 3)
		reroll_btn.add_theme_stylebox_override("normal", ns)
		var hs := StyleBoxFlat.new()
		hs.bg_color = Color(1.0, 0.88, 0.28, 1.0)
		hs.corner_radius_top_left = 18; hs.corner_radius_top_right = 18
		hs.corner_radius_bottom_right = 18; hs.corner_radius_bottom_left = 18
		hs.set_border_width_all(3); hs.border_color = Color(1.0, 0.96, 0.55)
		hs.shadow_color = Color(1.0, 0.88, 0.28, 0.55); hs.shadow_size = 14; hs.shadow_offset = Vector2(0, 3)
		reroll_btn.add_theme_stylebox_override("hover", hs)

		var cap_is_initial: bool = is_initial
		var cap_layer: Node = layer
		reroll_btn.pressed.connect(func() -> void:
			if _ad_manager == null:
				reroll_btn.text = "Ad unavailable — tap to retry"
				return

			reroll_btn.disabled = true
			reroll_btn.text = "Loading ad..."
			var ad_state := {"done": false}

			_ad_manager.rewarded_ad_completed.connect(
				func() -> void:
					if bool(ad_state.get("done", false)):
						return
					ad_state["done"] = true
					_skill_reroll_used = true
					if is_instance_valid(cap_layer):
						cap_layer.queue_free()
					_show_skill_select(cap_is_initial, true),
				CONNECT_ONE_SHOT
			)
			_ad_manager.rewarded_ad_skipped.connect(
				func() -> void:
					if bool(ad_state.get("done", false)):
						return
					ad_state["done"] = true
					if is_instance_valid(reroll_btn):
						reroll_btn.disabled = false
						reroll_btn.text = "Watch Ad to Reroll Skills",
				CONNECT_ONE_SHOT
			)
			if _ad_manager.has_signal("rewarded_ad_unavailable"):
				_ad_manager.rewarded_ad_unavailable.connect(
					func() -> void:
						if bool(ad_state.get("done", false)):
							return
						ad_state["done"] = true
						if is_instance_valid(reroll_btn):
							reroll_btn.disabled = false
							reroll_btn.text = "Ad unavailable — tap to retry",
					CONNECT_ONE_SHOT
				)

			_ad_manager.show_rewarded_ad()

			# Defensive fallback for SDK/device paths that never invoke a callback.
			get_tree().create_timer(15.0).timeout.connect(func() -> void:
				if bool(ad_state.get("done", false)):
					return
				ad_state["done"] = true
				if is_instance_valid(reroll_btn):
					reroll_btn.disabled = false
					reroll_btn.text = "Ad timed out — tap to retry"
			)
		)
	layer.add_child(reroll_btn)

func _build_skill_choices() -> Array[Dictionary]:
	# ── Determine which skills this character can use ─────────────────────────
	var allowed: Array = (CHAR_SKILLS.get(_char_id, null) as Array) if CHAR_SKILLS.has(_char_id) else (CHAR_SKILLS["_default"] as Array)
	var ulti_sid: String = ULTI_SKILLS.get(_char_id, "") as String
	var evolution_choices := _build_evolution_choices()
	if not evolution_choices.is_empty():
		return evolution_choices

	# ── Check ulti unlock: any 2 ATTACK skills (not regen/magnet/ulti) at max level ──
	if not _ulti_unlocked and not ulti_sid.is_empty():
		const SUPPORT_SKILLS: Array[String] = ["regen", "magnet"]
		var maxed: int = 0
		for sk in _skills:
			var sk_sid: String   = sk["id"] as String
			if sk_sid == ulti_sid: continue
			if SUPPORT_SKILLS.has(sk_sid): continue
			var sk_def: Dictionary = SKILL_DEFS[sk_sid] as Dictionary
			if (sk["level"] as int) >= (sk_def["max_lvl"] as int):
				maxed += 1
		if maxed >= 2:
			_ulti_unlocked = true

	# ── Build candidate pool ──────────────────────────────────────────────────
	var opts: Array[Dictionary] = []

	# Upgradeable acquired skills
	for sk in _skills:
		var sid: String      = sk["id"] as String
		if _is_skill_locked(sid):
			continue
		var cur_lvl: int     = sk["level"] as int
		var sdef: Dictionary = SKILL_DEFS[sid] as Dictionary
		# Don't offer ulti upgrades in this pool; handled separately below
		if sid == ulti_sid: continue
		if cur_lvl < (sdef["max_lvl"] as int):
			opts.append({"type": "upgrade", "id": sid, "lvl": cur_lvl + 1})

	# New skills from this character's allowed pool (cap at 8 total skills)
	if _skills.size() < 8:
		for sid_raw in allowed:
			var sid: String = sid_raw as String
			if _is_skill_locked(sid):
				continue
			# Ulti handled separately — skip in normal pool until offered once
			if sid == ulti_sid and (not _ulti_unlocked or not _ulti_offered): continue
			if not _has_skill(sid) and SKILL_DEFS.has(sid):
				opts.append({"type": "new", "id": sid, "lvl": 1})

	# Combo skills when both ingredient skills are currently owned.
	var combo_opts: Array[Dictionary] = _build_combo_choices()

	# Also allow upgrading the ulti if already acquired and not max
	if not ulti_sid.is_empty() and _has_skill(ulti_sid):
		var ucur: int        = _get_skill(ulti_sid)["level"] as int
		var udef: Dictionary = SKILL_DEFS[ulti_sid] as Dictionary
		if ucur < (udef["max_lvl"] as int):
			opts.append({"type": "upgrade", "id": ulti_sid, "lvl": ucur + 1, "is_ulti": true})

	opts.shuffle()

	var result: Array[Dictionary] = []

	# ── Force ulti as first choice on its first appearance ───────────────────
	if _ulti_unlocked and not _ulti_offered and not ulti_sid.is_empty() and not _has_skill(ulti_sid):
		result.append({"type": "new", "id": ulti_sid, "lvl": 1, "is_ulti": true})
		_ulti_offered = true

	# Ensure at least one combination option is surfaced when available.
	if not combo_opts.is_empty() and result.size() < 3:
		result.append(combo_opts[0])

	# Fill remaining slots from shuffled pool (skip duplicating ulti if forced)
	for o in opts:
		if result.size() >= 3: break
		var already_picked: bool = false
		for r in result:
			if (r["id"] as String) == (o["id"] as String):
				already_picked = true
				break
		if already_picked:
			continue
		if (o["id"] as String) == ulti_sid and result.size() > 0 and (result[0]["id"] as String) == ulti_sid:
			continue
		result.append(o)

	while result.size() < 3:
		var regen_lvl: int = ((_get_skill("regen")["level"] as int) + 1) if _has_skill("regen") else 1
		result.append({"type": "upgrade", "id": "regen", "lvl": mini(regen_lvl, 3)})

	return result

func _pick_skill(sid: String, lvl: int, evolution: String = "") -> void:
	_play_skill_sfx("skill_pick", -8.0, 1.0 + float(lvl - 1) * 0.04, 0.08)
	if _is_combo_skill(sid):
		_consume_combo_requirements(sid)
	if _has_skill(sid):
		_get_skill(sid)["level"] = lvl
		if not evolution.is_empty():
			_get_skill(sid)["evolution"] = evolution
	else:
		var sk: Dictionary = {"id": sid, "level": 1, "timer": 0.0}
		_skills.append(sk)
	_update_skill_icons()

func _build_evolution_choices() -> Array[Dictionary]:
	for skill in _skills:
		var sid := String(skill.get("id", ""))
		if not SKILL_DEFS.has(sid) or not String(skill.get("evolution", "")).is_empty():
			continue
		if int(skill.get("level", 1)) < int((SKILL_DEFS[sid] as Dictionary).get("max_lvl", 1)):
			continue
		var choices: Array[Dictionary] = []
		for evolution_any in _evolution_options_for_skill(sid):
			var evolution := evolution_any as Dictionary
			choices.append({
				"type": "evolution",
				"id": sid,
				"lvl": int(skill.get("level", 1)),
				"evolution": String(evolution.get("id", "")),
				"name": String(evolution.get("name", "Evolution")),
				"note": String(evolution.get("note", "")),
				"color": evolution.get("color", Color.WHITE),
			})
		return choices
	return []

func _evolution_options_for_skill(sid: String) -> Array[Dictionary]:
	if SKILL_EVOLUTIONS.has(sid):
		var bespoke: Array[Dictionary] = []
		for option_any in (SKILL_EVOLUTIONS[sid] as Array):
			bespoke.append((option_any as Dictionary).duplicate(true))
		return bespoke
	var sdef := SKILL_DEFS.get(sid, {}) as Dictionary
	var levels := sdef.get("lvl", []) as Array
	if levels.is_empty():
		return []
	var peak := levels[levels.size() - 1] as Dictionary
	var force_mods: Dictionary = {}
	var flow_mods: Dictionary = {}
	for stat in ["dmg", "dps", "hps", "chain_dmg", "explode_dmg", "pulse_dmg", "pool_dps", "poison_dps", "ember_dps", "emp_dmg"]:
		if peak.has(stat): force_mods[stat + "_mul"] = 1.55
	for stat in ["r", "freeze_r", "explode_r", "pulse_r", "pool_r", "fog_r", "chain_r", "spread_r", "rng", "len"]:
		if peak.has(stat): force_mods[stat + "_mul"] = 1.30
	for stat in ["n", "orbs", "shots", "spawn_n", "ember_n", "splits", "pierce", "bounces", "max_targets", "chains"]:
		if peak.has(stat): flow_mods[stat + "_add"] = 1
	for stat in ["life", "dur", "hold", "mark_t", "poison_t", "sink_t"]:
		if peak.has(stat): flow_mods[stat + "_mul"] = 1.35
	if peak.has("cd"): flow_mods["cd_mul"] = 0.78
	if peak.has("spd"): flow_mods["spd_mul"] = 1.25
	if peak.has("slow"): flow_mods["slow_add"] = 0.12
	# Passive skills may have only one scalable axis. Keep both branches useful.
	if force_mods.is_empty():
		for stat in peak.keys():
			if peak[stat] is int:
				force_mods[String(stat) + "_add"] = maxi(1, int(round(float(peak[stat]) * 0.45)))
				break
			if peak[stat] is float:
				force_mods[String(stat) + "_mul"] = 1.45
				break
	if flow_mods.is_empty():
		for stat in peak.keys():
			if peak[stat] is int:
				flow_mods[String(stat) + "_add"] = 1
				break
			if peak[stat] is float:
				flow_mods[String(stat) + "_mul"] = 1.25
				break
	var base_name := String(sdef.get("name", sid))
	var base_color: Color = sdef.get("col", Color(0.62, 0.78, 1.0)) as Color
	return [
		{"id": sid + "_ascendant", "name": "Ascendant " + base_name, "note": _evolution_note(force_mods, "Power and area greatly increased"), "color": base_color.lightened(0.18), "mods": force_mods},
		{"id": sid + "_overdrive", "name": base_name + " Overdrive", "note": _evolution_note(flow_mods, "Faster, longer and more numerous effects"), "color": base_color.lerp(Color(0.72, 0.48, 1.0), 0.28), "mods": flow_mods},
	]

func _evolution_note(mods: Dictionary, fallback: String) -> String:
	var parts: Array[String] = []
	if mods.has("cd_mul"): parts.append("faster recharge")
	if mods.has("spd_mul"): parts.append("faster projectiles")
	for key_any in mods:
		var key := String(key_any)
		if key.ends_with("_add"):
			parts.append("more %s" % key.trim_suffix("_add").replace("_", " "))
		elif key.ends_with("_mul") and key not in ["cd_mul", "spd_mul"]:
			parts.append("stronger %s" % key.trim_suffix("_mul").replace("_", " "))
		if parts.size() >= 3: break
	return fallback if parts.is_empty() else ", ".join(parts).capitalize()

func _build_combo_choices() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var allowed: Array = (CHAR_SKILLS.get(_char_id, null) as Array) if CHAR_SKILLS.has(_char_id) else (CHAR_SKILLS["_default"] as Array)
	for combo_sid_variant in COMBO_RECIPES:
		var combo_sid: String = combo_sid_variant as String
		if _has_skill(combo_sid):
			continue
		if not SKILL_DEFS.has(combo_sid):
			continue
		var recipe: Dictionary = COMBO_RECIPES[combo_sid] as Dictionary
		var needs: Array = recipe.get("needs", []) as Array
		var ok: bool = true
		for need_variant in needs:
			var need_sid: String = need_variant as String
			if not allowed.has(need_sid) or _is_skill_locked(need_sid) or not _has_skill(need_sid):
				ok = false
				break
		if ok:
			out.append({"type": "combo", "id": combo_sid, "lvl": 1, "is_combo": true})
	out.shuffle()
	return out

func _is_combo_skill(sid: String) -> bool:
	return COMBO_RECIPES.has(sid)

func _is_skill_locked(sid: String) -> bool:
	return _combo_locked_skills.get(sid, false) as bool

func _remove_skill(sid: String) -> void:
	for i in range(_skills.size() - 1, -1, -1):
		if (_skills[i]["id"] as String) == sid:
			_skills.remove_at(i)

func _consume_combo_requirements(combo_sid: String) -> void:
	if not COMBO_RECIPES.has(combo_sid):
		return
	var recipe: Dictionary = COMBO_RECIPES[combo_sid] as Dictionary
	for need_variant in recipe.get("needs", []) as Array:
		var need_sid: String = need_variant as String
		_remove_skill(need_sid)
		_combo_locked_skills[need_sid] = true

# ═════════════════════════════════════════════════════════════════════════════
# GAME OVER
# ═════════════════════════════════════════════════════════════════════════════

func _try_drop_dungeon_key(ep: Vector2, enemy_kind: String) -> void:
	if account_username.is_empty() or is_story_test_run:
		return
	if not PurchaseStore.is_key_drop_available(account_username):
		return
	if _run_key_dropped:
		return
	var chance: float = 0.10 if enemy_kind == "arena_boss" else 0.05
	if randf() > chance:
		return
	PurchaseStore.add_keys(account_username, 1)
	_run_key_dropped = true
	_show_key_drop_banner(ep)

func _show_key_drop_banner(_pos: Vector2) -> void:
	var view: Vector2 = get_viewport_rect().size
	var layer := CanvasLayer.new()
	add_child(layer)
	var lbl := Label.new()
	lbl.text = "Key Dropped! +1"
	lbl.add_theme_font_size_override("font_size", 46)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.26))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(0, view.y * 0.24)
	lbl.size = Vector2(view.x, 64)
	layer.add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.35)
	tw.tween_callback(layer.queue_free)

func _handle_player_death() -> void:
	_player_hp = 0.0
	if not _ring_revive_used and _ring_bonus("revive_once") > 0.0:
		_do_ring_revive()
		return
	_on_death()

func _do_ring_revive() -> void:
	_ring_revive_used = true
	_game_over = false
	_paused = false
	_player_hp = _player_max_hp * (_ring_bonus("revive_hp_pct") if _ring_bonus("revive_hp_pct") > 0.0 else 0.55)
	_player_iframes = 3.0
	_show_revive_banner()
	queue_redraw()

func _show_revive_banner() -> void:
	var view: Vector2 = get_viewport_rect().size
	var layer := CanvasLayer.new()
	add_child(layer)
	var lbl := Label.new()
	lbl.text = "Second Chance!"
	lbl.add_theme_font_size_override("font_size", 54)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.72, 0.18))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(0, view.y * 0.28)
	lbl.size = Vector2(view.x, 70)
	layer.add_child(lbl)
	var tween := create_tween()
	tween.tween_interval(0.75)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.35)
	tween.tween_callback(layer.queue_free)

func _on_death() -> void:
	if not story_stage.is_empty() and _story_telemetry != null:
		_story_telemetry.player_death()
		var failure_reason: String = _story_custom_failure if not _story_custom_failure.is_empty() else "player_defeated"
		_story_telemetry.failure(failure_reason)
	_game_over = true
	_paused    = true
	_ring_drops.clear()
	queue_redraw()
	if is_story_test_run:
		if _story_telemetry != null:
			_story_telemetry.log_event("Test stage failed")
		_show_story_test_result(false)
		return
	if _run_key_dropped:
		PurchaseStore.start_key_drop_cooldown(account_username)

	if not _loss_recorded and not account_username.is_empty() and selected_player_character != null:
		_loss_recorded = true
		if not story_stage.is_empty():
			_progression_reward = {}
			ProgressionStore.record_mission_event(account_username, "enemy_kills", _kills)
		elif dungeon_mode.is_empty():
			_progression_reward = ProgressionStore.record_run(account_username, String(selected_player_character.id), _kills, _elapsed, _wave)
		else:
			var recovered_coins := floori(float(_coin_carried) * 0.40) if dungeon_mode == "coin_burrow" else -1
			_progression_reward = ProgressionStore.record_dungeon_run(account_username, dungeon_mode, _dungeon_depth_cleared, recovered_coins)
			ProgressionStore.record_mission_event(account_username, "enemy_kills", _kills)
			if dungeon_mode == "forgecore":
				var materials := int(_progression_reward.get("materials", 0))
				if _forge_modifier == "rich_vein": materials = ceili(float(materials) * 1.5)
				_progression_reward["materials"] = materials
				StoryStore.add_materials(account_username, materials)
		StatsStore.record_match_detail(
			account_username,
			String(selected_player_character.id),
			_kills,
			_elapsed,
			RingStore.get_equipped_rings(account_username, String(selected_player_character.id)),
			ArtifactStore.get_equipped_artifacts(account_username, String(selected_player_character.id)),
			_wave
		)
		StatsStore.record_match(
			account_username,
			String(selected_player_character.id),
			StatsStore.OUTCOME_LOSS,
			0, _elapsed, 0, _kills
		)
		var cloud_id: String = account_cloud_id if not account_cloud_id.is_empty() else account_username
		var char_id: String = String(selected_player_character.id)
		var latest_match: Dictionary = {
			"character": char_id,
			"kills": _kills,
			"survive_seconds": _elapsed,
			"wave": _wave,
			"ts": int(Time.get_unix_time_from_system()),
			"rings": RingStore.get_equipped_rings(account_username, char_id),
			"artifacts": ArtifactStore.get_equipped_artifacts(account_username, char_id),
		}
		LeaderboardClient.submit_stats(self, cloud_id, account_display_name, account_username, latest_match)

	var view: Vector2 = get_viewport_rect().size
	var layer := CanvasLayer.new()
	layer.name = "death_screen"
	add_child(layer)

	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.80); ov.size = view
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(ov)

	var title := Label.new()
	title.text = "Knocked Out!"
	title.add_theme_font_size_override("font_size", 68)
	title.add_theme_color_override("font_color", Color(0.90, 0.20, 0.20))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, view.y * 0.18); title.size = Vector2(view.x, 90)
	layer.add_child(title)

	var m: int = int(_elapsed) / 60
	var s: int = int(_elapsed) % 60
	var stats := Label.new()
	var reward_line := ""
	if not story_stage.is_empty(): reward_line = _story_custom_failure if not _story_custom_failure.is_empty() else "Story stage not cleared."
	elif not dungeon_mode.is_empty(): reward_line = "Depth %d reached  ·  +%d Camp Coins  ·  +%d upgrade materials" % [int(_progression_reward.get("depth", _wave)), int(_progression_reward.get("coins", 0)), int(_progression_reward.get("materials", 0))]
	else: reward_line = "+%d camp coins  ·  +%d XP  ·  Mastery Lv.%d" % [int(_progression_reward.get("coins", 0)), int(_progression_reward.get("xp", 0)), int(_progression_reward.get("mastery_level", 1))]
	stats.text = "Survived  %d:%02d\nLevel %d  ·  %d kills\n%s%s" % [m, s, _level, _kills, reward_line, "" if not dungeon_mode.is_empty() or not story_stage.is_empty() else "\nNext: %s" % String(_progression_reward.get("next_unlock", "Keep exploring the dungeon"))]
	stats.add_theme_font_size_override("font_size", 38)
	stats.add_theme_color_override("font_color", Color(0.88, 0.82, 0.68))
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.position = Vector2(0, view.y * 0.33); stats.size = Vector2(view.x, 220)
	layer.add_child(stats)

	var has_ring_rewards: bool = not _rings_obtained.is_empty()
	var has_artifact_reward: bool = not _boss_artifact_results.is_empty()
	if has_ring_rewards:
		title.position = Vector2(0, view.y * 0.13)
		stats.position = Vector2(0, view.y * 0.28)
		_add_death_ring_rewards(layer, view, view.y * 0.42)
	if has_artifact_reward:
		title.position = Vector2(0, view.y * 0.13)
		stats.position = Vector2(0, view.y * 0.28)
		var art_y: float = view.y * (0.56 if has_ring_rewards else 0.42)
		_add_death_artifact_reward(layer, view, art_y)

	# ── Revive button (watch ad to revive, available if not already used) ───────────
	if not _ad_revive_used and dungeon_mode.is_empty() and _story_custom_failure.is_empty():
		var revive_btn := Button.new()
		revive_btn.text = "📺  Watch Ad to Revive"
		revive_btn.add_theme_font_size_override("font_size", 34)
		revive_btn.custom_minimum_size = Vector2(440, 88)
		revive_btn.size = Vector2(440, 88)
		var revive_y: float = view.y * (0.78 if has_ring_rewards and has_artifact_reward else 0.70 if has_ring_rewards or has_artifact_reward else 0.56)
		revive_btn.position = Vector2((view.x - 440) * 0.5, revive_y)
		revive_btn.focus_mode = Control.FOCUS_NONE
		var rs := StyleBoxFlat.new()
		rs.bg_color = Color(0.10, 0.34, 0.10, 0.95)
		rs.corner_radius_top_left = 28; rs.corner_radius_top_right = 28
		rs.corner_radius_bottom_right = 28; rs.corner_radius_bottom_left = 28
		rs.set_border_width_all(3); rs.border_color = Color(0.28, 0.88, 0.28, 0.90)
		rs.shadow_color = Color(0.10, 0.60, 0.10, 0.45); rs.shadow_size = 12; rs.shadow_offset = Vector2(0, 4)
		revive_btn.add_theme_stylebox_override("normal", rs)
		var rh := StyleBoxFlat.new()
		rh.bg_color = Color(0.14, 0.46, 0.14, 0.98)
		rh.corner_radius_top_left = 28; rh.corner_radius_top_right = 28
		rh.corner_radius_bottom_right = 28; rh.corner_radius_bottom_left = 28
		rh.set_border_width_all(3); rh.border_color = Color(0.40, 1.00, 0.40)
		revive_btn.add_theme_stylebox_override("hover", rh)
		var revive_status := Label.new()
		revive_status.text = ""
		revive_status.add_theme_font_size_override("font_size", 20)
		revive_status.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
		revive_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		revive_status.position = Vector2(0, revive_y - 30)
		revive_status.size = Vector2(view.x, 26)
		layer.add_child(revive_status)
		var cap_layer: Node = layer
		revive_btn.pressed.connect(func() -> void:
			_start_revive_ad(cap_layer, revive_btn, revive_status)
		)
		layer.add_child(revive_btn)

		var once_lbl := Label.new()
		once_lbl.text = "(one ad revive per run)"
		once_lbl.add_theme_font_size_override("font_size", 18)
		once_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.50))
		once_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		once_lbl.position = Vector2(0, revive_y + 92); once_lbl.size = Vector2(view.x, 28)
		layer.add_child(once_lbl)

	var back_y: float = view.y * (0.90 if has_ring_rewards and has_artifact_reward else 0.82 if has_ring_rewards or has_artifact_reward else 0.74)
	if _ad_revive_used:
		back_y -= 0.12 * view.y
	if not dungeon_mode.is_empty():
		var replay := _pause_btn("Replay Depth %d" % _wave, Color(0.52, 0.28, 0.08), Color.WHITE)
		replay.position = Vector2((view.x - 420) * 0.5, back_y - 108.0)
		replay.size = Vector2(420, 84)
		replay.pressed.connect(func() -> void: match_ended.emit("rematch"))
		layer.add_child(replay)
	var back := Button.new()
	back.text = "Back to Story Map" if not story_stage.is_empty() else ("Extract to Camp" if not dungeon_mode.is_empty() else "Back to Lobby")
	back.add_theme_font_size_override("font_size", 36)
	back.custom_minimum_size = Vector2(420, 84)
	back.size = Vector2(420, 84)
	back.position = Vector2((view.x - 420) * 0.5, back_y)
	back.focus_mode = Control.FOCUS_NONE
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.14, 0.14, 0.22, 0.92)
	bs.corner_radius_top_left = 28; bs.corner_radius_top_right = 28
	bs.corner_radius_bottom_right = 28; bs.corner_radius_bottom_left = 28
	bs.set_border_width_all(2); bs.border_color = Color(0.55, 0.55, 0.75, 0.75)
	bs.shadow_color = Color(0, 0, 0, 0.38); bs.shadow_size = 7; bs.shadow_offset = Vector2(0, 3)
	back.add_theme_stylebox_override("normal", bs)
	var bh := bs.duplicate() as StyleBoxFlat
	bh.bg_color = Color(0.19, 0.19, 0.30, 0.96)
	bh.border_color = Color(0.70, 0.70, 0.92, 0.90)
	bh.shadow_color = Color(0, 0, 0, 0.45)
	bh.shadow_size = 9
	var bp := bs.duplicate() as StyleBoxFlat
	bp.bg_color = Color(0.11, 0.11, 0.18, 0.98)
	bp.border_color = Color(0.46, 0.46, 0.68, 0.88)
	back.add_theme_stylebox_override("hover", bh)
	back.add_theme_stylebox_override("pressed", bp)
	back.pressed.connect(func() -> void: match_ended.emit("story" if not story_stage.is_empty() else ("dungeon" if not dungeon_mode.is_empty() else "lobby")))
	layer.add_child(back)

func _show_story_victory() -> void:
	if not _story_victory_validated:
		_request_story_victory("unvalidated_show_story_victory_call")
		return
	_game_over = true
	_paused = true
	if is_story_test_run:
		if _story_telemetry != null:
			_story_telemetry.log_event("Test stage completed")
		_show_story_test_result(true)
		return
	var result := StoryStore.record_clear(account_username, str(story_stage.get("id", "")), {"elapsed":_elapsed, "kills":_kills, "level":_level})
	ProgressionStore.record_mission_event(account_username, "story_clears")
	ProgressionStore.record_mission_event(account_username, "enemy_kills", _kills)
	var view := get_viewport_rect().size
	var layer := CanvasLayer.new(); layer.layer = 120; add_child(layer)
	var shade := ColorRect.new(); shade.color = Color(0.02, 0.04, 0.06, 0.94); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; layer.add_child(shade)
	var title := Label.new(); title.text = "STAGE CLEARED!"; title.position = Vector2(0, view.y * 0.20); title.size = Vector2(view.x, 90); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 64); title.add_theme_color_override("font_color", Color("ffd66b")); layer.add_child(title)
	var body := Label.new(); body.position = Vector2(60, view.y * 0.33); body.size = Vector2(view.x - 120, 360); body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; body.add_theme_font_size_override("font_size", 30)
	var reward_message := "+%d camp coins  ·  +%d upgrade materials" % [int(result.get("coins", 0)), int(result.get("materials", 0))]
	if not bool(result.get("first_clear", false)):
		reward_message = "Replay reward (30%%)\n%s" % reward_message
	if int(story_stage.get("chapter_stage", 0)) == 5 and bool(result.get("first_clear", false)):
		reward_message += "\nChapter reward chest is ready on the map!"
	body.text = "%s\n\n%s" % [String(story_stage.get("story", "The road ahead is open.")), reward_message]; layer.add_child(body)
	var back := Button.new(); back.text = "Return to Story Map"; back.position = Vector2((view.x - 460) * 0.5, view.y * 0.72); back.size = Vector2(460, 92); back.add_theme_font_size_override("font_size", 32); back.pressed.connect(func(): match_ended.emit("story_clear")); layer.add_child(back)

func _show_story_test_result(success: bool) -> void:
	var view := get_viewport_rect().size
	var layer := CanvasLayer.new(); layer.layer = 180; add_child(layer)
	var shade := ColorRect.new(); shade.color = Color(0.01, 0.02, 0.03, 0.96); shade.size = view; shade.mouse_filter = Control.MOUSE_FILTER_STOP; layer.add_child(shade)
	var title := Label.new(); title.text = "TEST STAGE COMPLETE" if success else "TEST STAGE FAILED"; title.position = Vector2(40.0, view.y * 0.18); title.size = Vector2(view.x - 80.0, 90.0); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 54); title.add_theme_color_override("font_color", Color("ffd66b") if success else Color("ff806e")); layer.add_child(title)
	var stage_label := Label.new(); stage_label.text = "C%dS%d\nProgress and rewards were not saved" % [int(story_stage.get("chapter", 0)), int(story_stage.get("chapter_stage", 0))]; stage_label.position = Vector2(60.0, view.y * 0.31); stage_label.size = Vector2(view.x - 120.0, 120.0); stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; stage_label.add_theme_font_size_override("font_size", 28); layer.add_child(stage_label)
	var buttons := VBoxContainer.new(); buttons.position = Vector2(90.0, view.y * 0.48); buttons.size = Vector2(view.x - 180.0, 310.0); buttons.add_theme_constant_override("separation", 18); layer.add_child(buttons)
	var retry := _pause_btn("Retry Stage", Color(0.46, 0.30, 0.08), Color.WHITE); retry.custom_minimum_size = Vector2(0.0, 84.0); retry.pressed.connect(_finish_story_test.bind("story_test_retry")); buttons.add_child(retry)
	var choose := _pause_btn("Choose Another Stage", Color(0.24, 0.28, 0.46), Color.WHITE); choose.custom_minimum_size = Vector2(0.0, 84.0); choose.pressed.connect(_finish_story_test.bind("story_test_choose")); buttons.add_child(choose)
	var exit := _pause_btn("Return to Story Menu", Color(0.20, 0.32, 0.34), Color.WHITE); exit.custom_minimum_size = Vector2(0.0, 84.0); exit.pressed.connect(_finish_story_test.bind("story_test_exit")); buttons.add_child(exit)

func _finish_story_test(action: String) -> void:
	if _story_telemetry != null:
		if action == "story_test_retry":
			_story_telemetry.retry("test_stage")
	match_ended.emit(action)

func _add_death_ring_rewards(layer: Node, view: Vector2, y: float) -> void:
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.08, 0.13, 0.96)
	ps.corner_radius_top_left = 18
	ps.corner_radius_top_right = 18
	ps.corner_radius_bottom_right = 18
	ps.corner_radius_bottom_left = 18
	ps.set_border_width_all(3)
	ps.border_color = Color(0.90, 0.72, 0.22, 0.85)
	ps.content_margin_left = 18
	ps.content_margin_right = 18
	ps.content_margin_top = 14
	ps.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", ps)
	var pw: float = min(view.x - 80.0, 600.0)
	panel.position = Vector2((view.x - pw) * 0.5, y)
	panel.custom_minimum_size = Vector2(pw, 0)
	layer.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	var title := Label.new()
	title.text = "Rings Found"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.28))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var max_rows: int = min(_rings_obtained.size(), 3)
	for i in max_rows:
		var ring: Dictionary = _rings_obtained[i] as Dictionary
		root.add_child(_make_death_ring_row(ring))
	if _rings_obtained.size() > max_rows:
		var more := Label.new()
		more.text = "+%d more in stash" % (_rings_obtained.size() - max_rows)
		more.add_theme_font_size_override("font_size", 30)
		more.add_theme_color_override("font_color", Color(0.72, 0.68, 0.78))
		more.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(more)

func _add_death_artifact_reward(layer: Node, view: Vector2, y: float) -> void:
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.08, 0.13, 0.96)
	ps.corner_radius_top_left = 18
	ps.corner_radius_top_right = 18
	ps.corner_radius_bottom_right = 18
	ps.corner_radius_bottom_left = 18
	ps.set_border_width_all(3)
	ps.border_color = Color(0.74, 0.66, 0.92, 0.85)
	ps.content_margin_left = 18
	ps.content_margin_right = 18
	ps.content_margin_top = 14
	ps.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", ps)
	var pw: float = min(view.x - 80.0, 600.0)
	panel.position = Vector2((view.x - pw) * 0.5, y)
	panel.custom_minimum_size = Vector2(pw, 0)
	layer.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	var title := Label.new()
	title.text = "Artifacts Found"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.84, 0.78, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var max_rows: int = min(_boss_artifact_results.size(), 3)
	for i in max_rows:
		var reward: Dictionary = _boss_artifact_results[i] as Dictionary
		var reward_art: Dictionary = reward.get("artifact", {}) as Dictionary
		var duplicated: bool = reward.get("duplicated", false) as bool
		if not reward_art.is_empty():
			root.add_child(_make_death_artifact_row(reward_art, duplicated))

	var duplicate_count: int = 0
	for reward_any in _boss_artifact_results:
		if typeof(reward_any) != TYPE_DICTIONARY:
			continue
		if bool((reward_any as Dictionary).get("duplicated", false)):
			duplicate_count += 1

	if _boss_artifact_results.size() > max_rows:
		var more := Label.new()
		more.text = "+%d more in stash" % (_boss_artifact_results.size() - max_rows)
		more.add_theme_font_size_override("font_size", 30)
		more.add_theme_color_override("font_color", Color(0.72, 0.68, 0.78))
		more.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(more)

	if duplicate_count > 0:
		var dup := Label.new()
		dup.text = "%d duplicated artifact%s - key refunded to stash" % [
			duplicate_count,
			"s" if duplicate_count != 1 else "",
		]
		dup.add_theme_font_size_override("font_size", 24)
		dup.add_theme_color_override("font_color", Color(0.70, 0.70, 0.74))
		dup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dup.autowrap_mode = TextServer.AUTOWRAP_WORD
		root.add_child(dup)

func _make_death_artifact_row(artifact: Dictionary, duplicated: bool) -> Control:
	var rarity: String = artifact.get("rarity", "rare") as String
	var rarity_color: Color = ArtifactStore.RARITY_COLORS.get(rarity, Color(0.80, 0.80, 0.80)) as Color
	var row := Button.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.10).lerp(rarity_color, 0.24)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.set_border_width_all(2)
	style.border_color = rarity_color
	row.add_theme_stylebox_override("normal", style)
	row.add_theme_stylebox_override("hover", style)
	row.add_theme_stylebox_override("pressed", style)
	row.custom_minimum_size = Vector2(0, 108)
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.focus_mode = Control.FOCUS_NONE
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.icon = ArtifactStore.artifact_icon(artifact)
	row.expand_icon = true
	row.add_theme_constant_override("icon_max_width", 56)
	row.clip_text = true
	row.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	row.text = "[%s]  %s%s" % [
		rarity.to_upper(),
		artifact.get("name", "Artifact") as String,
		"",
	]
	row.add_theme_font_size_override("font_size", 30)
	row.add_theme_color_override("font_color", Color(0.68, 0.68, 0.70) if duplicated else rarity_color)
	if duplicated:
		row.modulate = Color(0.66, 0.66, 0.66, 1.0)
	return row

func _make_death_ring_row(ring: Dictionary) -> Control:
	var rarity: String = ring.get("rarity", "rare") as String
	var rarity_color: Color = _ring_rarity_color(rarity)
	var row := Button.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.10).lerp(rarity_color, 0.24)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.set_border_width_all(2)
	style.border_color = rarity_color
	row.add_theme_stylebox_override("normal", style)
	row.add_theme_stylebox_override("hover", style)
	row.add_theme_stylebox_override("pressed", style)
	row.custom_minimum_size = Vector2(0, 108)
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.focus_mode = Control.FOCUS_NONE
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.icon = RingStore.ring_icon(ring)
	row.expand_icon = true
	row.add_theme_constant_override("icon_max_width", 56)
	row.clip_text = true
	row.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	row.text = "[%s]  %s  T%d  (%s)" % [
		rarity.to_upper(),
		ring.get("name", "Ring") as String,
		int(ring.get("tier", 1)),
		_format_ring_bonus(ring),
	]
	row.add_theme_font_size_override("font_size", 30)
	row.add_theme_color_override("font_color", rarity_color)
	return row

func _ring_rarity_color(rarity: String) -> Color:
	return RingStore.RARITY_COLORS.get(rarity, Color(0.80, 0.80, 0.80)) as Color

func _format_ring_bonus(ring: Dictionary) -> String:
	var attr: String = ring.get("attr", "") as String
	var value: float = float(ring.get("value", 0.0))
	if attr == "revive_once":
		return "revive once per gameplay"
	if attr == "timed_shield":
		return "1s shield every 10s"
	if attr in ["potion_drop_rate", "xp_bonus", "ring_drop_rate", "skill_dmg", "skill_cd", "aoe_radius", "projectile_spd", "crit_chance", "boss_dmg"]:
		return "+%d%% %s" % [int(round(value * 100.0)), attr]
	if attr == "regen":
		return "+%.1f HP/s" % value
	return "+%.0f %s" % [value, attr]

func _start_revive_ad(death_layer: Node, revive_btn: Button = null, status_lbl: Label = null) -> void:
	if _ad_manager == null:
		if status_lbl != null and is_instance_valid(status_lbl):
			status_lbl.text = "Ad system unavailable."
		if revive_btn != null and is_instance_valid(revive_btn):
			revive_btn.disabled = false
			if revive_btn.text.is_empty():
				revive_btn.text = "📺  Watch Ad to Revive"
		return

	if revive_btn != null and is_instance_valid(revive_btn):
		revive_btn.disabled = true
		revive_btn.text = "Loading ad..."
	if status_lbl != null and is_instance_valid(status_lbl):
		status_lbl.text = "Please wait..."

	var ad_state := {"done": false}
	_ad_manager.rewarded_ad_completed.connect(func() -> void:
		if bool(ad_state.get("done", false)):
			return
		ad_state["done"] = true
		_do_revive(death_layer)
	, CONNECT_ONE_SHOT)
	_ad_manager.rewarded_ad_skipped.connect(func() -> void:
		if bool(ad_state.get("done", false)):
			return
		ad_state["done"] = true
		if revive_btn != null and is_instance_valid(revive_btn):
			revive_btn.disabled = false
			revive_btn.text = "📺  Watch Ad to Revive"
		if status_lbl != null and is_instance_valid(status_lbl):
			status_lbl.text = "Ad closed before completion. Try again."
	, CONNECT_ONE_SHOT)
	if _ad_manager.has_signal("rewarded_ad_unavailable"):
		_ad_manager.rewarded_ad_unavailable.connect(func() -> void:
			if bool(ad_state.get("done", false)):
				return
			ad_state["done"] = true
			if revive_btn != null and is_instance_valid(revive_btn):
				revive_btn.disabled = false
				revive_btn.text = "📺  Watch Ad to Revive"
			if status_lbl != null and is_instance_valid(status_lbl):
				status_lbl.text = "No ad available right now. Please try again shortly."
		, CONNECT_ONE_SHOT)
	_ad_manager.show_rewarded_ad()

	# Some SDK/device failure paths never call callbacks; avoid a dead button.
	get_tree().create_timer(15.0).timeout.connect(func() -> void:
		if bool(ad_state.get("done", false)):
			return
		ad_state["done"] = true
		if revive_btn != null and is_instance_valid(revive_btn):
			revive_btn.disabled = false
			revive_btn.text = "📺  Watch Ad to Revive"
		if status_lbl != null and is_instance_valid(status_lbl):
			status_lbl.text = "Ad request timed out. Please try again."
	)

func _do_revive(death_layer: Node) -> void:
	_ad_revive_used = true
	_game_over   = false
	_paused      = false
	# Restore player to 40% HP
	_player_hp      = _player_max_hp * 0.40
	_player_iframes = 2.5   # brief invincibility frames on revive
	# Remove the death screen
	death_layer.queue_free()
	queue_redraw()

# ═════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═════════════════════════════════════════════════════════════════════════════

func _has_skill(sid: String) -> bool:
	for s in _skills:
		if (s["id"] as String) == sid:
			return true
	return false

func _get_skill(sid: String) -> Dictionary:
	for s in _skills:
		if (s["id"] as String) == sid:
			return s
	return {}

func _ring_bonus(attr: String) -> float:
	return float(_ring_bonuses.get(attr, 0.0))

func _apply_skill_damage_bonus(value: float) -> float:
	return value * (1.0 + _ring_bonus("skill_dmg") + _artifact_wheel_skill_dmg) * _room_skill_dmg_multiplier()

func _apply_skill_cooldown_bonus(value: float) -> float:
	var base_cd: float = value
	if is_nan(base_cd) or is_inf(base_cd):
		base_cd = 0.12
	base_cd = max(base_cd, 0.0)

	var cooldown_multiplier: float = 1.0 - _ring_bonus("skill_cd") + _artifact_wheel_cd
	if is_nan(cooldown_multiplier) or is_inf(cooldown_multiplier):
		cooldown_multiplier = 1.0
	# Clamp to prevent extreme/overflowing cooldown outcomes from stacked modifiers.
	cooldown_multiplier = clampf(cooldown_multiplier, 0.08, 8.0)

	var cooled: float = base_cd * cooldown_multiplier
	if is_nan(cooled) or is_inf(cooled):
		return 0.12
	return clampf(cooled, 0.12, 120.0)

func _apply_radius_bonus(value: float) -> float:
	return value * (1.0 + _ring_bonus("aoe_radius"))

func _apply_projectile_speed_bonus(value: float) -> float:
	return value * (1.0 + _ring_bonus("projectile_spd"))

func _apply_mystery_box_chaos() -> void:
	var mods: Array[Dictionary] = [
		{"key": "skill_dmg", "pos": 0.12, "neg": -0.10},
		{"key": "max_hp_pct", "pos": 0.12, "neg": -0.10},
		{"key": "move_speed_mul", "pos": 0.10, "neg": -0.10},
		{"key": "xp_bonus", "pos": 0.15, "neg": -0.10},
	]
	var pool: Array = mods.duplicate()
	pool.shuffle()
	for i in min(2, pool.size()):
		var m: Dictionary = pool[i] as Dictionary
		var sign_val: float = (m["pos"] as float) if randf() < 0.5 else (m["neg"] as float)
		var k: String = m["key"] as String
		_ring_bonuses[k] = float(_ring_bonuses.get(k, 0.0)) + sign_val

func _update_artifact_runtime(delta: float) -> void:
	if _ring_bonus("chaos_wheel") > 0.0:
		if _artifact_wheel_left > 0.0:
			_artifact_wheel_left -= delta
			if _artifact_wheel_left <= 0.0:
				_artifact_wheel_skill_dmg = 0.0
				_artifact_wheel_move_mul = 0.0
				_artifact_wheel_cd = 0.0
		_artifact_wheel_t += delta
		if _artifact_wheel_t >= max(_ring_bonus("wheel_interval"), 50.0):
			_artifact_wheel_t = 0.0
			_artifact_wheel_left = max(_ring_bonus("wheel_duration"), 12.0)
			_artifact_wheel_skill_dmg = 0.0
			_artifact_wheel_move_mul = 0.0
			_artifact_wheel_cd = 0.0
			match randi() % 6:
				0:
					_artifact_wheel_skill_dmg = 0.12
				1:
					_artifact_wheel_skill_dmg = -0.08
				2:
					_artifact_wheel_move_mul = 0.15
				3:
					_artifact_wheel_move_mul = -0.12
				4:
					_artifact_wheel_cd = -0.10
				_:
					_artifact_wheel_cd = 0.10
	if _ring_bonus("regen_pulse_pct") > 0.0 and _ring_bonus("regen_pulse_interval") > 0.0:
		_artifact_regen_pulse_t -= delta
		if _artifact_regen_pulse_t <= 0.0:
			_artifact_regen_pulse_t = _ring_bonus("regen_pulse_interval")
			_player_hp = min(_player_max_hp, _player_hp + _player_max_hp * _ring_bonus("regen_pulse_pct"))
	if _ring_bonus("blink_interval") > 0.0:
		_artifact_blink_t -= delta
		if _artifact_blink_t <= 0.0:
			_artifact_blink_t = _ring_bonus("blink_interval")
			var dir: Vector2 = _player_move_dir
			if dir.length_squared() < 0.01:
				dir = Vector2(float(_player_facing_x), 0.0)
			_player_pos += dir.normalized() * max(_ring_bonus("blink_dist"), 170.0)
			_player_iframes = max(_player_iframes, max(_ring_bonus("blink_iframes"), 0.5))

func _capy_orb_orbit_radius() -> float:
	return _apply_radius_bonus(ORB_ORBIT_R + 56.0)

func _capy_orb_hit_radius() -> float:
	return _apply_radius_bonus(ORB_R)

func _slvl(sid: String, lvl: int) -> Dictionary:
	if not SKILL_DEFS.has(sid):
		push_warning("Match: missing skill definition for '%s'" % sid)
		return {}
	var sdef: Dictionary = SKILL_DEFS[sid] as Dictionary
	var levels: Array = sdef.get("lvl", []) as Array
	if levels.is_empty():
		push_warning("Match: skill '%s' has no level data" % sid)
		return {}
	var safe_level := clampi(lvl - 1, 0, levels.size() - 1)
	var out: Dictionary = (levels[safe_level] as Dictionary).duplicate(true)
	var evolution := _skill_evolution_definition(sid)
	if not evolution.is_empty():
		var mods: Dictionary = evolution.get("mods", {}) as Dictionary
		for key_any in mods:
			var key := String(key_any)
			if key.ends_with("_mul"):
				var stat := key.trim_suffix("_mul")
				if out.has(stat): out[stat] = float(out[stat]) * float(mods[key])
			elif key.ends_with("_add"):
				var stat := key.trim_suffix("_add")
				if out.has(stat):
					if typeof(out[stat]) == TYPE_INT:
						out[stat] = int(out[stat]) + int(mods[key])
					else:
						out[stat] = float(out[stat]) + float(mods[key])
	if out.has("n") and _ring_bonus("proj_dup_chance") > 0.0 and randf() < _ring_bonus("proj_dup_chance"):
		out["n"] = int(out["n"] as int) + 1
	if out.has("dmg"):
		out["dmg"] = _apply_skill_damage_bonus(float(out["dmg"]))
		if out.has("spd"):
			out["dmg"] = float(out["dmg"]) * (1.0 + _ring_bonus("projectile_dmg"))
		if sid == "ice_orb" or sid == "ice_storm":
			out["dmg"] = float(out["dmg"]) * (1.0 + _ring_bonus("ice_dmg"))
		if sid == "arc_lightning" or sid == "thunder_god_pulse" or sid == "plasma_overdrive":
			out["dmg"] = float(out["dmg"]) * (1.0 + _ring_bonus("lightning_dmg"))
	if out.has("dps"):
		out["dps"] = _apply_skill_damage_bonus(float(out["dps"]))
	if out.has("cd"):
		out["cd"] = _apply_skill_cooldown_bonus(float(out["cd"]))
	if out.has("r"):
		out["r"] = _apply_radius_bonus(float(out["r"]))
	if out.has("freeze_r"):
		out["freeze_r"] = _apply_radius_bonus(float(out["freeze_r"]))
	if out.has("slow") and (sid == "ice_orb" or sid == "ice_storm"):
		out["slow"] = min(float(out["slow"]) * (1.0 + _ring_bonus("freeze_duration") * 0.5), 0.99)
	elif out.has("slow"):
		out["slow"] = clampf(float(out["slow"]), 0.0, 0.95)
	if out.has("spd"):
		out["spd"] = _apply_projectile_speed_bonus(float(out["spd"]))
	if out.has("chains"):
		out["chains"] = int(out["chains"] as int) + int(round(_ring_bonus("lightning_chain")))
	if out.has("chain_dmg"):
		out["chain_dmg"] = float(out["chain_dmg"]) * (1.0 + _ring_bonus("lightning_dmg"))
	return out

func _skill_evolution_definition(sid: String) -> Dictionary:
	if not _has_skill(sid) or not SKILL_DEFS.has(sid):
		return {}
	var evolution_id := String(_get_skill(sid).get("evolution", ""))
	if evolution_id.is_empty():
		return {}
	var cache_key := "%s:%s" % [sid, evolution_id]
	if _evolution_definition_cache.has(cache_key):
		return _evolution_definition_cache[cache_key] as Dictionary
	for evolution_any in _evolution_options_for_skill(sid):
		var evolution := evolution_any as Dictionary
		if String(evolution.get("id", "")) == evolution_id:
			_evolution_definition_cache[cache_key] = evolution
			return evolution
	return {}
