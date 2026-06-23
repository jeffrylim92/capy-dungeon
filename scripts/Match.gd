extends Node2D

## Vampire Survivors-style roguelite.
## Move to survive, skills auto-cast, kill monsters, level up, pick new skills.

signal match_ended(next_action: String)

# ─── Public (set by Main before adding to tree) ───────────────────────────────
var selected_player_character: CharacterData = null
var account_username: String = ""
var account_display_name: String = ""

# ─── Tuning constants ─────────────────────────────────────────────────────────
const PLAYER_R:    float = 34.0
const PLAYER_DRAW_R: float = 48.0
const PLAYER_SPRITE_SIZE: float = 124.0
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
const ROOM_SPAN_WAVES: int = 3
const ROOM_ROUTE: Array = [
	{"id": "lava", "name": "Lava Rooms", "short": "Damage over time", "col": Color(1.0, 0.42, 0.12), "desc": "The ground burns — take periodic fire damage while standing still."},
	{"id": "frozen", "name": "Frozen Floors", "short": "Sliding movement", "col": Color(0.52, 0.84, 1.0), "desc": "Icy surface causes momentum — movement feels slippery and hard to stop."},
	{"id": "poison", "name": "Poison Swamps", "short": "-10% skill damage", "col": Color(0.34, 0.82, 0.34), "desc": "Toxic fumes weaken attacks — all skill damage reduced by 10%."},
	{"id": "spike", "name": "Spike Corridors", "short": "HP regen suppressed", "col": Color(0.92, 0.18, 0.20), "desc": "Jagged spikes disrupt recovery — HP regeneration is fully suppressed."},
	{"id": "darkness", "name": "Darkness Zones", "short": "Reduced vision", "col": Color(0.58, 0.42, 0.92), "desc": "Darkness closes in — vision range is drastically reduced."},
]

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
			{"dmg": 520.0, "cd": 20.0, "slow": 0.92, "note": "Screen-wide ice storm"},
			{"dmg": 880.0, "cd": 18.0, "slow": 0.95, "note": "+damage, colder"},
			{"dmg": 1400.0, "cd": 15.0, "slow": 0.98, "note": "ABSOLUTE ZERO"},
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
			{"r": 180.0, "slow": 0.55, "cd": 22.0, "life": 8.0, "note": "Slow zone — no damage"},
			{"r": 240.0, "slow": 0.72, "cd": 19.0, "life": 11.0, "note": "Wider, stronger slow"},
			{"r": 310.0, "slow": 0.88, "cd": 16.0, "life": 14.0, "note": "TIME FREEZE ZONE"},
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
		"name": "Ricochet Arrow", "short": "Bouncing arrows",
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
			{"r": 160.0, "slow": 0.20, "cd": 7.5, "life": 3.2, "note": "Small mud pool"},
			{"r": 190.0, "slow": 0.30, "cd": 7.0, "life": 3.6, "note": "Larger, slower"},
			{"r": 225.0, "slow": 0.40, "cd": 6.5, "life": 4.0, "note": "Deeper swamp"},
			{"r": 265.0, "slow": 0.52, "cd": 6.0, "life": 4.4, "note": "Heavy slow"},
			{"r": 310.0, "slow": 0.65, "cd": 5.5, "life": 5.0, "note": "MAX bog snare"},
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
			{"n": 2, "r": 62.0, "dps": 16.0, "cd": 8.0, "sink_t": 3.0, "note": "2 trap patches"},
			{"n": 2, "r": 70.0, "dps": 22.0, "cd": 7.5, "sink_t": 3.0, "note": "Bigger patch"},
			{"n": 3, "r": 78.0, "dps": 29.0, "cd": 7.0, "sink_t": 3.0, "note": "3 trap patches"},
			{"n": 3, "r": 86.0, "dps": 38.0, "cd": 6.5, "sink_t": 3.0, "note": "Stronger sink"},
			{"n": 4, "r": 94.0, "dps": 48.0, "cd": 6.0, "sink_t": 3.0, "note": "MAX sinking field"},
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
			{"r": 210.0, "dmg": 36.0, "cd": 8.5, "n": 6, "note": "Short utensil burst"},
			{"r": 250.0, "dmg": 46.0, "cd": 7.8, "n": 7, "note": "Larger burst"},
			{"r": 295.0, "dmg": 58.0, "cd": 7.2, "n": 8, "note": "More utensils"},
			{"r": 340.0, "dmg": 72.0, "cd": 6.8, "n": 9, "note": "Wider and stronger"},
			{"r": 390.0, "dmg": 88.0, "cd": 6.2, "n": 11, "note": "MAX kitchen storm"},
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
		"name": "Friendly Aura", "short": "Good vibes damage nearby enemies",
		"col": Color(1.0, 0.82, 0.50), "max_lvl": 5,
		"lvl": [
			{"r": 145.0, "dps": 12.0, "note": "The power of friendship hurts"},
			{"r": 175.0, "dps": 18.0, "note": "+range & damage"},
			{"r": 206.0, "dps": 25.0, "note": "+range & damage"},
			{"r": 238.0, "dps": 34.0, "note": "+range & damage"},
			{"r": 274.0, "dps": 46.0, "note": "BEST FRIEND FOREVER — MAX"},
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
			{"n": 2, "dmg": 28.0, "cd": 8.0, "spd": 500.0, "chain_dmg": 12.0, "chains": 2, "emp_r": 95.0, "emp_dmg": 18.0, "note": "Plasma balls chain lightning and EMP"},
			{"n": 2, "dmg": 38.0, "cd": 7.5, "spd": 560.0, "chain_dmg": 16.0, "chains": 2, "emp_r": 110.0, "emp_dmg": 24.0, "note": "+damage and faster cycle"},
			{"n": 3, "dmg": 50.0, "cd": 7.0, "spd": 620.0, "chain_dmg": 22.0, "chains": 3, "emp_r": 122.0, "emp_dmg": 32.0, "note": "3 plasma balls, stronger chains"},
			{"n": 3, "dmg": 62.0, "cd": 6.4, "spd": 700.0, "chain_dmg": 28.0, "chains": 3, "emp_r": 136.0, "emp_dmg": 40.0, "note": "Heavy EMP bursts"},
			{"n": 4, "dmg": 78.0, "cd": 5.8, "spd": 780.0, "chain_dmg": 36.0, "chains": 4, "emp_r": 152.0, "emp_dmg": 52.0, "note": "MAX: storm of plasma and lightning"},
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
var _player_speed:   float   = 360.0
var _player_iframes: float   = 0.0
var _player_tint:    Color   = Color(0.62, 0.46, 0.30)
var _player_tex:     Texture2D = null
var _player_facing_x: int     = 1  # 1 = right, -1 = left
var _player_move_dir: Vector2 = Vector2.ZERO
var _enemy_tex:       Dictionary = {}  # kind -> Texture2D

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
const BOSS_TYPES:     Array = ["teleporter_boss", "shield_boss", "shooter_boss", "lava_boss"]
var _boss_bag:        Array = []

# ─── Map / room modifiers ───────────────────────────────────────────────────
var _room_index: int = 0
var _room_elapsed: float = 0.0
var _room_lava_tick_t: float = 0.0
var _room_spike_tick_t: float = 0.0
var _room_slide_velocity: Vector2 = Vector2.ZERO
var _stand_still_t: float = 0.0
var _idle_enemy_speed_boost_active: bool = false

# ─── Enemy modifier system (post wave 10) ───────────────────────────────────
const ENEMY_MOD_POOL: Array = ["fast", "giant", "armored", "explosive", "frozen_trail", "burn_trail"]
var _active_enemy_mod: String = ""
var _active_enemy_mod_name: String = ""
var _active_enemy_mod_desc: String = ""
var _frozen_trails: Array[Dictionary] = []
var _burn_trails:   Array[Dictionary] = []

# ─── Potions  {pos,life} ─────────────────────────────────────────────────────
var _potions: Array[Dictionary] = []

# ─── Ring drops  {pos,life,ring} ─────────────────────────────────────────────
var _ring_drops: Array[Dictionary] = []
var _rings_obtained: Array[Dictionary] = []
var _boss_artifact_result: Dictionary = {}

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
var _skill_icon_row: HBoxContainer
var _joy_vis:        JoystickVisual
var _room_detail_lbl: Label
var _enemy_mod_lbl:   Label

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

# ─── Ads ──────────────────────────────────────────────────────────────────────
var _ad_manager: AdManager = null
var _sound: SoundManager = null
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
	SettingsStore.apply(get_tree())
	_sound = SoundManager.new()
	add_child(_sound)
	var view: Vector2 = get_viewport_rect().size
	_joy_zone = Rect2(0.0, view.y * 0.55, view.x, view.y * 0.45)

	if selected_player_character != null:
		_player_max_hp = float(selected_player_character.max_hp)
		_player_hp     = _player_max_hp
		_player_speed  = 300.0 + float(selected_player_character.attack - 7) * 12.0
		_player_tint   = selected_player_character.tint
		_char_id = String(selected_player_character.id)
		# Auto-grant character's starting skill
		var base_sid: String = selected_player_character.base_skill
		if not base_sid.is_empty() and SKILL_DEFS.has(base_sid):
			_skills.append({"id": base_sid, "level": 1, "timer": 0.0})
		# Load portrait texture via ResourceLoader (works on Android + desktop)
		var tex_path: String = "res://assets/characters/" + String(selected_player_character.id) + ".png"
		if ResourceLoader.exists(tex_path):
			_player_tex = load(tex_path) as Texture2D

	# ── Apply ring bonuses ────────────────────────────────────────────────
	if not account_username.is_empty() and not _char_id.is_empty():
		var bonuses: Dictionary = RingStore.get_bonuses(account_username, _char_id)
		var artifact_bonuses: Dictionary = ArtifactStore.get_bonuses(account_username, _char_id)
		for k in artifact_bonuses.keys():
			bonuses[k] = float(bonuses.get(k, 0.0)) + float(artifact_bonuses[k])
		_ring_bonuses = bonuses
		if bonuses.has("max_hp"):
			_player_max_hp += float(bonuses["max_hp"])
			_player_hp      = _player_max_hp
		if bonuses.has("max_hp_pct"):
			_player_max_hp *= 1.0 + float(bonuses["max_hp_pct"])
			_player_hp = _player_max_hp
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
	_show_skill_select(true)
	# Kick off wave 1 after a short delay
	_wave        = 0
	_wave_state  = "between"
	_between_t   = 2.0  # 2s grace period before first wave
	_boss_wave_locked = false
	_sync_room_state(true)

	# Load enemy textures
	var _enemy_tex_map: Dictionary = {
		"normal":      "res://assets/enemies/enemy_normal.png",
		"normal_tank": "res://assets/enemies/enemy_tank.png",
		"normal_fast": "res://assets/enemies/enemy_fast.png",
		"teleporter_boss": "res://assets/bosses/boss_teleporter.png",
		"shield_boss":     "res://assets/bosses/boss_shield.png",
		"shooter_boss":    "res://assets/bosses/boss_shooter.png",
		"lava_boss":       "res://assets/bosses/boss_lava.png",
	}
	for ek in _enemy_tex_map:
		var ep2: String = _enemy_tex_map[ek]
		if ResourceLoader.exists(ep2):
			_enemy_tex[ek] = load(ep2) as Texture2D

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
			_touch_cur    = te.position
			_joy_vis.origin      = te.position
			_joy_vis.knob        = te.position
			_joy_vis.visible_joy = true
			_joy_vis.queue_redraw()
		elif not te.pressed and te.index == _touch_id:
			_touch_id     = -1
			_touch_origin = Vector2.ZERO
			_touch_cur    = Vector2.ZERO
			_joy_vis.visible_joy = false
			_joy_vis.queue_redraw()
	elif event is InputEventScreenDrag:
		var de: InputEventScreenDrag = event as InputEventScreenDrag
		if de.index == _touch_id:
			_touch_cur = de.position
			var diff: Vector2    = de.position - _touch_origin
			var clamped: Vector2 = diff.limit_length(80.0)
			_joy_vis.knob = _touch_origin + clamped
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
	_sync_room_state()
	_update_boss_intermission(delta)
	_update_artifact_runtime(delta)
	_player_iframes    = max(0.0, _player_iframes - delta)
	var _pmove: Vector2 = _get_move_dir()
	_player_move_dir    = _pmove
	_update_idle_enemy_boost(delta, _pmove)
	_apply_room_movement(delta, _pmove)
	if _pmove.x > 0.01:    _player_facing_x = 1
	elif _pmove.x < -0.01: _player_facing_x = -1
	_camera.position    = _player_pos
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
	_update_xp_orbs(delta)
	_update_potions(delta)
	_update_ring_drops(delta)
	_update_boss_projs(delta)
	_update_mortar_strikes(delta)
	_update_lava_lines(delta)
	_update_lava_pools(delta)
	_update_spawner(delta)
	queue_redraw()
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
	if _stand_still_t >= 2.0:
		_idle_enemy_speed_boost_active = true

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
	return int(floor(float(wave_slot) / float(ROOM_SPAN_WAVES))) % ROOM_ROUTE.size()

func _current_room() -> Dictionary:
	return ROOM_ROUTE[_room_index] as Dictionary

func _apply_room_movement(delta: float, move_dir: Vector2) -> void:
	var room_type: String = _current_room().get("id", "lava") as String
	var move_mul: float = 1.0 + _artifact_wheel_move_mul
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
	if _is_ring_shield_active():
		_player_iframes = max(_player_iframes, min(iframe_time, 0.25))
		return false
	_player_hp -= amount * (1.0 + _ring_bonus("damage_taken_mul"))
	_player_iframes = iframe_time
	if _player_hp <= 0.0:
		_handle_player_death()
		return true
	return false

# ═════════════════════════════════════════════════════════════════════════════
# SKILL UPDATES
# ═════════════════════════════════════════════════════════════════════════════

func _play_skill_sfx(cue: String, volume_db: float = -6.0, pitch_scale: float = 1.0, min_interval: float = 0.05) -> void:
	if _sound == null:
		return
	var next_allowed: float = float(_sfx_next_allowed.get(cue, -1.0))
	if _elapsed < next_allowed:
		return
	_sfx_next_allowed[cue] = _elapsed + min_interval
	_sound.play(cue, volume_db, pitch_scale)

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
			var tick: float      = (adef["dps"] as float) * 0.5
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
			var htick: float = (hdef["dps"] as float) * 0.5
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
			var ktick: float = (kdef["dps"] as float) * 0.5
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
			var aura_tick: float = (tldef["dps"] as float) * 0.5
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
				var _na_tick: float = (_na_def["dps"] as float) * 0.5
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

	# ── Screen AOE skills ──────────────────────────────────────────────────
	for aoe_sid in ["blizzard", "sky_fall", "seven_slash", "swirl_tangerine", "capy_charge", "stampede"]:
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
			if checked.has(j):
				continue
			var d: float = _player_pos.distance_to(_enemies[j]["pos"] as Vector2)
			if d < best:
				best = d
				best_j = j
		if best_j < 0:
			break
		checked.append(best_j)
		var dir: Vector2 = ((_enemies[best_j]["pos"] as Vector2) - _player_pos).normalized()
		_bolts.append({"pos": _player_pos, "vel": dir * spd, "dmg": shot_dmg, "life": BOLT_LIFE, "kind": kind, "base_spd": spd})

func _trigger_wave_kind(r: float, dmg: float, kind: String = "wave") -> void:
	_play_skill_sfx("skill_elec_wave" if kind == "elec_wave" else "skill_wave", -5.0, 1.0, 0.2)
	var vp: Rect2 = get_viewport_rect()
	for i in range(_enemies.size() - 1, -1, -1):
		var ep: Vector2 = _enemies[i]["pos"] as Vector2
		var sp: Vector2 = ep - _camera.position + vp.size * 0.5
		if not vp.grow(60.0).has_point(sp): continue
		if ep.distance_to(_player_pos) <= r:
			_hit_enemy(i, dmg)
	_waves.append({"pos": _player_pos, "r": 0.0, "max_r": r, "life": 0.55, "max_life": 0.55, "kind": kind})

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
	if (boss["special_timer"] as float) < 2.7:
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
# ENTITY UPDATES
# ═════════════════════════════════════════════════════════════════════════════

func _update_enemies(delta: float) -> void:
	for i in range(_enemies.size() - 1, -1, -1):
		var e: Dictionary = _enemies[i]
		if (e["iframes"] as float) > 0.0:
			e["iframes"] = (e["iframes"] as float) - delta
		e["tg_mark_t"] = max((e.get("tg_mark_t", 0.0) as float) - delta, 0.0)
		e["poison_t"]  = max((e.get("poison_t",  0.0) as float) - delta, 0.0)
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
		e["alive_t"] = (e["alive_t"] as float) + delta
		if not (e.get("speed_boosted", false) as bool) and (e["alive_t"] as float) >= ENEMY_SURVIVE_SPEEDUP_SEC:
			e["speed_boosted"] = true
			e["base_spd"] = (e["base_spd"] as float) * ENEMY_SURVIVE_SPEEDUP_MULT
			e["spd"] = (e["spd"] as float) * ENEMY_SURVIVE_SPEEDUP_MULT
		var ep: Vector2 = e["pos"] as Vector2
		var ekind: String = e.get("kind", "normal") as String
		var _emove_dir: Vector2 = (_player_pos - ep).normalized()
		var move_speed: float = e["spd"] as float
		if _idle_enemy_speed_boost_active:
			var ep_screen: Vector2 = ep - _camera.position + get_viewport_rect().size * 0.5
			if get_viewport_rect().grow(40.0).has_point(ep_screen):
				move_speed *= 1.35
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
		if _player_iframes <= 0.0:
			if (_enemies[i]["pos"] as Vector2).distance_to(_player_pos) < PLAYER_R + (e["r"] as float):
				if _has_skill("meatball_barrage"):
					var mb_lvl: int = _get_skill("meatball_barrage").get("level", 1) as int
					var mb_def: Dictionary = _slvl("meatball_barrage", mb_lvl)
					_hit_enemy(i, (e["dmg"] as float) * (mb_def.get("reflect", 0.05) as float))
					if i >= _enemies.size():
						continue
				if _damage_player(e["dmg"] as float, IFRAMES_SEC):
					return

		# ── Boss special behaviors ──────────────────────────────────
		if ekind == "teleporter_boss":
			e["special_timer"] = (e["special_timer"] as float) + delta
			if (e["special_timer"] as float) >= 3.5:
				e["special_timer"] = 0.0
				# Teleport 60% closer to player (shorten distance)
				var cur_p: Vector2 = e["pos"] as Vector2
				var to_player: Vector2 = _player_pos - cur_p
				var dist: float = to_player.length()
				if dist > 120.0:  # only teleport if far enough away
					e["pos"] = cur_p + to_player * 0.60
		elif ekind == "shield_boss":
			e["special_timer"] = (e["special_timer"] as float) + delta
			var st: float = e["special_timer"] as float
			# Cycle: 6s vulnerable, 2.5s shielded
			var cycle: float = fmod(st, 8.5)
			e["shield_active"] = cycle >= 6.0
		elif ekind == "shooter_boss":
			e["special_timer"] = (e["special_timer"] as float) + delta
			if (e["special_timer"] as float) >= 2.2:
				e["special_timer"] = -randf_range(0.15, 0.85)
				_fire_shooter_boss_pattern(e)
		elif ekind == "lava_boss":
			_update_lava_boss_special(e, delta)

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
				var hit_ok: bool = _hit_enemy_with_result(rj, b["dmg"] as float)
				if hit_ok and bounces_left > 0 and has_next_target:
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
					for _k in split_n:
						var tidx: int = _nearest_enemy_index(ppos, 520.0)
						if tidx < 0:
							break
						var vdir: Vector2 = ((_enemies[tidx]["pos"] as Vector2) - ppos).normalized()
						_bolts.append({
							"pos": ppos,
							"vel": vdir * 980.0,
							"dmg": pbase * split_pct,
							"life": 1.2,
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
				_hit_enemy(j, b["dmg"] as float)
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
		clone_dmg = (_slvl("shadow_clone", _get_skill("shadow_clone")["level"] as int)["dps"] as float) * 2.0 * 0.14
	for i in range(_shadow_clones.size() - 1, -1, -1):
		var c: Dictionary = _shadow_clones[i]
		c["life"] = (c["life"] as float) - delta
		if (c["life"] as float) <= 0.0 or (c["hp"] as float) <= 0.0:
			_shadow_clones.remove_at(i)
			continue
		var cpos: Vector2 = c["pos"] as Vector2
		# Enemies that touch the clone deal damage to it
		for j in range(_enemies.size() - 1, -1, -1):
			if j >= _enemies.size(): continue
			if cpos.distance_to(_enemies[j]["pos"] as Vector2) < 30.0 + (_enemies[j]["r"] as float):
				c["hp"] = (c["hp"] as float) - (_enemies[j]["dmg"] as float) * delta * 2.0
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
	var dir: Vector2 = _player_move_dir
	if dir.length_squared() < 0.01:
		dir = Vector2(float(_player_facing_x), 0.0)
	dir = dir.normalized()
	var start_pos: Vector2 = _player_pos
	var end_pos:   Vector2 = _player_pos + dir * dash_r
	var blink_dmg: float   = dmg * TARGET_SKILL_DAMAGE_MULT
	for i in range(_enemies.size() - 1, -1, -1):
		var ep: Vector2 = _enemies[i]["pos"] as Vector2
		if _point_to_segment_dist(ep, start_pos, end_pos) < 46.0 + (_enemies[i]["r"] as float):
			_hit_enemy(i, blink_dmg)
	_player_pos            = end_pos
	_camera.position       = end_pos
	_player_iframes        = max(_player_iframes, 0.5)
	_aoe_flashes.append({"life": 0.45, "max_life": 0.45, "kind": "blink_trail",
		"pos": start_pos, "end_pos": end_pos})

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
				_hit_enemy(ei, (p["dps"] as float) * 0.5)

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
					_hit_enemy(ei, (m["dps"] as float) * 0.7)

func _spawn_bog_pool(def: Dictionary) -> void:
	var ang: float = randf() * TAU
	var dist: float = randf_range(140.0, 340.0)
	_bog_pools.append({
		"pos": _player_pos + Vector2(cos(ang), sin(ang)) * dist,
		"r": def.get("r", 160.0) as float,
		"slow": def.get("slow", 0.2) as float,
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
		for ei in range(_enemies.size() - 1, -1, -1):
			if (_enemies[ei]["pos"] as Vector2).distance_to(p["pos"] as Vector2) <= (p["r"] as float) + (_enemies[ei]["r"] as float):
				_enemies[ei]["tw_slow_t"] = max(_enemies[ei].get("tw_slow_t", 0.0) as float, 0.25)
				_enemies[ei]["spd"] = max((_enemies[ei]["base_spd"] as float) * (1.0 - (p["slow"] as float)), 8.0)

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
			"life": 4.0,
			"max_life": 4.0,
			"enemy_idx": -1,
			"tick_t": 0.0,
		})

func _update_corruption_pools(delta: float) -> void:
	for i in range(_corruption_pools.size() - 1, -1, -1):
		var p: Dictionary = _corruption_pools[i]
		p["life"] = (p["life"] as float) - delta
		if (p["life"] as float) <= 0.0:
			_corruption_pools.remove_at(i)
			continue
		var idx: int = p.get("enemy_idx", -1) as int
		if idx < 0:
			for ei in range(_enemies.size() - 1, -1, -1):
				if (_enemies[ei]["pos"] as Vector2).distance_to(p["pos"] as Vector2) <= (p["r"] as float) + (_enemies[ei]["r"] as float):
					p["enemy_idx"] = ei
					_enemies[ei]["corr_sink_t"] = p["sink_t"] as float
					break
		else:
			if idx >= _enemies.size():
				p["enemy_idx"] = -1
				continue
			p["tick_t"] = (p["tick_t"] as float) + delta
			if (p["tick_t"] as float) >= 0.5:
				p["tick_t"] = 0.0
				_hit_enemy(idx, (p["dps"] as float) * 0.5)
			if idx < _enemies.size():
				_enemies[idx]["trap_t"] = max(_enemies[idx].get("trap_t", 0.0) as float, 0.12)
				_enemies[idx]["corr_sink_t"] = max((_enemies[idx].get("corr_sink_t", 0.0) as float) - delta, 0.0)
				if (_enemies[idx].get("corr_sink_t", 0.0) as float) <= 0.0:
					p["enemy_idx"] = -1

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
	var n: int = def.get("n", 6) as int
	for i in n:
		var a: float = float(i) / float(max(n, 1)) * TAU + randf_range(-0.18, 0.18)
		_kitchen_queue.append({
			"delay": float(i) * 0.08,
			"dir": Vector2(cos(a), sin(a)),
			"r": def.get("r", 210.0) as float,
			"dmg": def.get("dmg", 36.0) as float,
		})

func _update_kitchen_queue(delta: float) -> void:
	for i in range(_kitchen_queue.size() - 1, -1, -1):
		var q: Dictionary = _kitchen_queue[i]
		q["delay"] = (q["delay"] as float) - delta
		if (q["delay"] as float) > 0.0:
			continue
		var dir: Vector2 = q["dir"] as Vector2
		var radius: float = q["r"] as float
		var tip: Vector2 = _player_pos + dir * radius
		for ei in range(_enemies.size() - 1, -1, -1):
			if _point_to_segment_dist(_enemies[ei]["pos"] as Vector2, _player_pos, tip) <= 22.0 + (_enemies[ei]["r"] as float):
				_hit_enemy(ei, q["dmg"] as float)
		_aoe_flashes.append({"life": 0.25, "max_life": 0.25, "kind": "master_kitchen", "pos": _player_pos, "dir": dir, "r": radius})
		_kitchen_queue.remove_at(i)

func _fire_phantom_hunt(def: Dictionary) -> void:
	var n: int = def.get("n", 3) as int
	var shot_dmg: float = def.get("dmg", 70.0) as float * PROJECTILE_SKILL_DAMAGE_MULT
	var spd: float = def.get("spd", 960.0) as float
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
			"life": 1.4,
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
	title.text = "Proceed to Next Wave?"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.76))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var msg := Label.new()
	msg.text = "Use the ladder to advance to the next wave?"
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
	var btype: String = _next_boss_type()
	var data: Dictionary = _make_enemy_data(btype, ws * 1.45)
	_spawn_enemy_from(data)

func _on_arena_boss_cleared() -> void:
	_boss_intermission["state"] = "none"
	var reward: Dictionary = _award_random_artifact()
	_boss_artifact_result = reward
	if reward.get("duplicated", false) as bool and _boss_key_spent_this_run > 0:
		PurchaseStore.add_keys(account_username, 1)
		_boss_key_spent_this_run -= 1
	_wave += 1
	_start_wave(_wave)

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
		if (a as Dictionary).get("name", "") as String == target_name:
			return true
	var equipped_all: Dictionary = ArtifactStore.load_equipped(account_username)
	for char_id in equipped_all.keys():
		var slots: Dictionary = equipped_all[char_id] as Dictionary
		for slot in 2:
			var item = slots.get("slot_%d" % slot, null)
			if item != null and (item as Dictionary).get("name", "") as String == target_name:
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
	var start_idx: int = marked[0] as int
	var start_dist: float = INF
	for idx_variant in marked:
		var idx: int = idx_variant as int
		if idx >= _enemies.size():
			continue
		var d: float = (_enemies[idx]["pos"] as Vector2).distance_to(_player_pos)
		if d < start_dist:
			start_dist = d
			start_idx = idx
	if start_idx >= _enemies.size():
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
				_hit_enemy(j, dmg * delta)
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
					_hit_enemy(j, fb["dmg"] as float)
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
					_hit_enemy(j, ft["dmg_per_tick"] as float)

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
				_hit_enemy(j, b["dmg"] as float)
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
				_wave_spawn_t += 0.38  # interval between spawns in a wave
		"waiting":
			# Next wave starts after 5 s max, or immediately when all enemies cleared
			_between_t -= delta
			if _enemies.is_empty() or _between_t <= 0.0:
				_wave_state = "between"
				_between_t  = BETWEEN_DELAY

func _start_wave(w: int) -> void:
	_wave_state    = "spawning"
	_wave_spawn_t  = 0.0
	_wave_spawn_q.clear()
	_between_t     = 5.0   # max seconds before next wave forces regardless
	var ws: float  = 1.0 + float(w - 1) * 0.18

	# After wave 10 pick one random enemy modifier per wave.
	if w >= 10:
		_pick_enemy_floor_mod()
	else:
		_active_enemy_mod = ""
		_active_enemy_mod_name = ""
		_active_enemy_mod_desc = ""

	# Boss wave every 4th, drawn from a shuffled bag so all 4 appear once per cycle.
	if w % 4 == 0:
		var btype: String = _next_boss_type()
		# Every 8th wave: full-strength boss; every 4th (not 8th): 65% strength
		var boss_ws: float = ws if (w % 8 == 0) else ws * 0.65
		_wave_spawn_q.append(_make_enemy_data(btype, boss_ws))
		_boss_wave_locked = true
	else:
		_boss_wave_locked = false
		var base_count: int = mini(40 + w * 8, MAX_ENEMIES)  # 48 wave 1 → 150 cap at wave 14
		for _i in base_count:
			# Randomly pick one of 3 normal subtypes
			var roll: float = randf()
			if roll < 0.30:
				_wave_spawn_q.append(_make_enemy_data("normal_tank", ws))
			elif roll < 0.60:
				_wave_spawn_q.append(_make_enemy_data("normal_fast", ws))
			else:
				_wave_spawn_q.append(_make_enemy_data("normal", ws))

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
			return "Enemies leave icy trails that slow you down if you run over them."
		"burn_trail":
			return "Enemies leave burning trails that hurt you if you run over them."
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
		_boss_bag = BOSS_TYPES.duplicate()
		_boss_bag.shuffle()
	return _boss_bag.pop_back() as String

func _make_enemy_data(kind: String, ws: float) -> Dictionary:
	match kind:
		"teleporter_boss":
			return {
				"kind": "teleporter_boss",
				"hp_mult": 14.0 * ws, "spd_fixed": 130.0, "dmg_mult": 1.5 * ws,
				"r": 62.0, "col": Color(0.55, 0.10, 0.82)
			}
		"shield_boss":
			return {
				"kind": "shield_boss",
				"hp_mult": 30.0 * ws, "spd_fixed": 75.0, "dmg_mult": 2.0 * ws,
				"r": 78.0, "col": Color(0.20, 0.55, 0.90)
			}
		"shooter_boss":
			return {
				"kind": "shooter_boss",
				"hp_mult": 20.0 * ws, "spd_fixed": 60.0, "dmg_mult": 1.2 * ws,
				"r": 68.0, "col": Color(0.85, 0.55, 0.05)
			}
		"lava_boss":
			return {
				"kind": "lava_boss",
				"hp_mult": 35.0 * ws, "spd_fixed": 50.0, "dmg_mult": 1.8 * ws,
				"r": 88.0, "col": Color(0.90, 0.25, 0.02)
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
	var base_hp: float  = (18.0 + float(_level) * 5.0) * (data["hp_mult"] as float)
	base_hp *= 1.0 + _ring_bonus("enemy_hp_mul")
	var base_spd: float
	if data.has("spd_fixed"):
		base_spd = data["spd_fixed"] as float
	else:
		var wave_bonus: float = float(_wave) * 2.5
		base_spd = (randf_range(72.0, 105.0) + wave_bonus) * (data["spd_mult"] as float)
	var base_dmg: float = (4.5 + float(_level) * 1.0) * (data["dmg_mult"] as float)
	var base_r: float   = data["r"] as float
	var base_col: Color = data["col"] as Color

	# Apply the current floor affix to non-boss enemies.
	var assigned_mod: String = ""
	var ekind_spawn: String = data["kind"] as String
	if _wave >= 10 and not _active_enemy_mod.is_empty() and not ekind_spawn.ends_with("_boss"):
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

func _hit_enemy(idx: int, dmg: float) -> void:
	if idx < 0 or idx >= _enemies.size():
		return
	var e: Dictionary = _enemies[idx]
	var ekind: String = e.get("kind", "normal") as String
	# Shielded bosses absorb hits; the lava boss also reflects explosive fireballs.
	if (e["shield_active"] as bool):
		if ekind == "lava_boss":
			_reflect_lava_shield(e)
		return
	# Apply crit from ring bonus
	var final_dmg: float = dmg
	if (e.get("bleed_t", 0.0) as float) > 0.0:
		final_dmg *= 1.0 + (e.get("bleed_bonus", 0.25) as float)
	if ekind.ends_with("_boss"):
		final_dmg *= 1.0 + _ring_bonus("boss_dmg")
	var crit_chance: float = _ring_bonus("crit_chance")
	if crit_chance > 0.0 and randf() < crit_chance:
		final_dmg *= 1.8 + _ring_bonus("crit_dmg")
	if _ring_bonus("lifesteal") > 0.0:
		_player_hp = min(_player_max_hp, _player_hp + final_dmg * _ring_bonus("lifesteal"))
	e["hp"]      = (e["hp"] as float) - final_dmg
	e["iframes"] = ENEMY_HIT_IF
	if (e["hp"] as float) <= 0.0:
		var ep: Vector2   = e["pos"] as Vector2
		_xp_orbs.append({"pos": ep, "val": _xp_drop()})
		_kills += 1
		var is_boss: bool = ekind.ends_with("_boss")
		# Potion drop: 25% base + ring bonus, from any boss
		var potion_rate: float = 0.25 + _ring_bonus("potion_drop_rate")
		if is_boss and randf() < potion_rate:
			_potions.append({"pos": ep + Vector2(randf_range(-20, 20), randf_range(-20, 20)), "life": 15.0})
		if is_boss:
			_boss_keys += 1
			_try_drop_dungeon_key(ep, ekind)
		# Ring drop: boosted chance from any boss.
		var ring_rate: float = 0.15 + _ring_bonus("ring_drop_rate")
		if is_boss and randf() < ring_rate:
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
				"state": "await_choice",
				"door_pos": _player_pos + Vector2(420.0, 26.0),
				"ladder_pos": _player_pos + Vector2(-420.0, 26.0),
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
			for _fi in 4:
				var off: Vector2 = Vector2(randf_range(-22, 22), randf_range(-22, 22))
				_frozen_trails.append({"pos": ep + off, "life": 3.0, "max_life": 3.0})
		elif death_mod == "burn_trail":
			for _bi in 5:
				var off: Vector2 = Vector2(randf_range(-28, 28), randf_range(-28, 28))
				_burn_trails.append({"pos": ep + off, "life": 3.0, "max_life": 3.0,
					"dmg_per_tick": 2.5 + float(_wave) * 0.1, "tick_t": 0.0})

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
	# Emit trails from living mod enemies
	for e in _enemies:
		var emod: String = e.get("mod", "") as String
		if emod == "frozen_trail":
			e["trail_t"] = (e.get("trail_t", 0.0) as float) + delta
			if (e["trail_t"] as float) >= 0.22:
				e["trail_t"] = 0.0
				_frozen_trails.append({"pos": e["pos"] as Vector2, "life": 3.0, "max_life": 3.0})
		elif emod == "burn_trail":
			e["trail_t"] = (e.get("trail_t", 0.0) as float) + delta
			if (e["trail_t"] as float) >= 0.18:
				e["trail_t"] = 0.0
				_burn_trails.append({
					"pos": e["pos"] as Vector2,
					"life": 3.0, "max_life": 3.0,
					"dmg_per_tick": 2.5 + float(_wave) * 0.1,
					"tick_t": 0.0,
				})
	# Tick frozen trails (slow player if overlapping)
	for i in range(_frozen_trails.size() - 1, -1, -1):
		var ft: Dictionary = _frozen_trails[i]
		ft["life"] = (ft["life"] as float) - delta
		if (ft["life"] as float) <= 0.0:
			_frozen_trails.remove_at(i)
			continue
		if _player_pos.distance_to(ft["pos"] as Vector2) < 32.0:
			# Slow the slide/movement by clamping velocity toward zero faster
			_room_slide_velocity = _room_slide_velocity.move_toward(Vector2.ZERO, 980.0 * delta)
			_player_pos -= (_player_pos - (ft["pos"] as Vector2)).normalized() * 44.0 * delta
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
			RingStore.add_ring_to_stash(account_username, ring)
			_rings_obtained.append(ring)
			_ring_drops.remove_at(i)

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
		if _player_iframes <= 0.0 and bpp.distance_to(_player_pos) < PLAYER_R + 12.0:
			if _damage_player(bp["dmg"] as float, IFRAMES_SEC):
				return
			_boss_projs.remove_at(i)

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

func _xp_drop() -> int:
	var out: float = 9.0 + float(_wave) * 1.35
	out *= 1.0 + _ring_bonus("luck")
	return int(out)

func _gain_xp(amount: int) -> void:
	var xp_mult: float = 1.0 + _ring_bonus("xp_bonus")
	_xp += int(float(amount) * xp_mult)
	if _xp >= _xp_next:
		_xp -= _xp_next
		_level   += 1
		_xp_next  = int(40.0 * pow(float(_level), 1.40))
		_show_skill_select(false)

# ═════════════════════════════════════════════════════════════════════════════
# DRAWING
# ═════════════════════════════════════════════════════════════════════════════

func _draw() -> void:
	_draw_bg()

	# XP orbs
	for orb in _xp_orbs:
		var op: Vector2 = orb["pos"] as Vector2
		draw_circle(op, XP_ORB_R, Color(0.28, 0.88, 0.60, 0.9))
		draw_arc(op, XP_ORB_R + 2.0, 0.0, TAU, 16, Color(0.5, 1.0, 0.8, 0.5), 1.5)

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
			var first_spec = h_specs.values()[0]
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
			var first_spec = k_specs.values()[0]
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
	for w in _waves:
		var lf: float    = (w["life"] as float) / (w["max_life"] as float)
		var wr: float    = w["r"] as float
		var wp: Vector2  = w["pos"] as Vector2
		var wkind: String = w.get("kind", "wave") as String
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
					var ew_spec = ew_specs.values()[0]
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
					var w_spec = w_specs.values()[0]
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
	for pt in _prism_traps:
		var plf: float = (pt["life"] as float) / (pt["max_life"] as float)
		var ppts: Array = pt["pts"] as Array
		draw_colored_polygon(PackedVector2Array([ppts[0] as Vector2, ppts[1] as Vector2, ppts[2] as Vector2]), Color(0.46, 0.98, 1.0, 0.16 * plf))
		for i in 3:
			var a: Vector2 = ppts[i]
			draw_circle(a, 8.0, Color(0.70, 1.0, 1.0, 0.70 * plf))
	for gt in _ground_traps:
		var glf: float = (gt["life"] as float) / (gt["max_life"] as float)
		var ga: Vector2 = gt["a"] as Vector2
		var gb: Vector2 = gt["b"] as Vector2
		for ti in 10:
			var t: float = float(ti) / 9.0
			var p: Vector2 = ga.lerp(gb, t)
			var wiggle: float = sin(_elapsed * 8.0 + float(ti)) * 6.0
			draw_circle(p + Vector2(0.0, wiggle), 2.0, Color(0.86, 1.0, 0.42, 0.70 * glf))
			draw_circle(p + Vector2(0.0, wiggle * 0.5) + Vector2(0.0, -8.0), 1.5, Color(0.62, 0.96, 0.34, 0.58 * glf))

	for vp in _venom_pools:
		var vlf: float = (vp["life"] as float) / (vp["max_life"] as float)
		draw_circle(vp["pos"] as Vector2, vp["r"] as float, Color(0.18, 0.72, 0.20, 0.24 * vlf))
		draw_circle(vp["pos"] as Vector2, (vp["r"] as float) * 0.65, Color(0.36, 0.90, 0.36, 0.30 * vlf))

	for tm in _toxic_mushrooms:
		var mlf: float = (tm["life"] as float) / (tm["max_life"] as float)
		var mp: Vector2 = tm["pos"] as Vector2
		draw_circle(mp + Vector2(0, 10), 16.0, Color(0.42, 0.26, 0.12, 0.92 * mlf))
		draw_circle(mp, 22.0, Color(0.48, 0.76, 0.24, 0.88 * mlf))
		draw_circle(mp, tm["r"] as float, Color(0.38, 0.88, 0.28, 0.10 * mlf))

	for bp in _bog_pools:
		var blf: float = (bp["life"] as float) / (bp["max_life"] as float)
		var bpr: float = bp["r"] as float
		var bpp: Vector2 = bp["pos"] as Vector2
		draw_circle(bpp, bpr, Color(0.30, 0.23, 0.12, 0.34 * blf))
		draw_circle(bpp, bpr * 0.72, Color(0.44, 0.34, 0.18, 0.38 * blf))

	for cp in _corruption_pools:
		var clf: float = (cp["life"] as float) / (cp["max_life"] as float)
		var cpr: float = cp["r"] as float
		draw_circle(cp["pos"] as Vector2, cpr, Color(0.20, 0.26, 0.08, 0.28 * clf))
		draw_circle(cp["pos"] as Vector2, cpr * 0.70, Color(0.32, 0.46, 0.12, 0.30 * clf))

	# Hawk companions
	for h in _hawk_companions:
		var hp: Vector2 = h["pos"] as Vector2
		draw_circle(hp, 10.0, Color(0.58, 0.38, 0.12, 0.94))
		draw_circle(hp + Vector2(9.0, -3.0), 5.0, Color(0.66, 0.44, 0.16, 0.95))
		draw_colored_polygon(PackedVector2Array([hp + Vector2(12.0, -2.0), hp + Vector2(20.0, -4.0), hp + Vector2(12.0, 1.0)]), Color(0.92, 0.76, 0.30, 0.95))
		draw_line(hp + Vector2(-2.0, -2.0), hp + Vector2(-16.0, -8.0 + sin(_elapsed * 12.0) * 3.0), Color(0.74, 0.58, 0.22, 0.92), 3.2)
		draw_line(hp + Vector2(-2.0, 2.0), hp + Vector2(-16.0, 8.0 - sin(_elapsed * 12.0) * 3.0), Color(0.74, 0.58, 0.22, 0.92), 3.2)

	# Shadow clones — persistent ghost entities
	for sc in _shadow_clones:
		var scp: Vector2   = sc["pos"] as Vector2
		var sc_hp: float   = clamp((sc["hp"] as float) / max((sc["max_hp"] as float), 0.01), 0.0, 1.0)
		var sc_life: float = clamp((sc["life"] as float) / max((sc["max_life"] as float), 0.01), 0.0, 1.0)
		var sc_bob: float  = sin(_elapsed * 3.2 + scp.x * 0.01) * 5.0
		var sc_pulse: float = 0.55 + 0.45 * sin(_elapsed * 4.0)
		var scdp: Vector2  = scp + Vector2(0.0, sc_bob - 4.0)
		# Outer aura glow (only when not fading out)
		if sc_life > 0.3:
			draw_circle(scdp, 46.0 * sc_pulse, Color(0.28, 0.08, 0.52, 0.16))
			draw_arc(scdp, 42.0, 0.0, TAU, 32, Color(0.54, 0.24, 0.92, 0.55 * sc_pulse), 2.8)
		if _char_id == "capy_assassin" and _player_tex != null:
			draw_set_transform(scdp, 0.0, Vector2(float(sc.get("facing_x", 1) as int), 1.0))
			draw_texture_rect(_player_tex, Rect2(Vector2(-PLAYER_SPRITE_SIZE * 0.5, -PLAYER_SPRITE_SIZE * 0.5), Vector2(PLAYER_SPRITE_SIZE, PLAYER_SPRITE_SIZE)), false, Color(0.70, 0.42, 1.0, 0.72 * sc_life))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			# Ghost body silhouette (lower dark mass + smaller head)
			draw_circle(scdp, 28.0, Color(0.14, 0.06, 0.28, 0.76))
			draw_circle(scdp, 20.0, Color(0.32, 0.16, 0.54, 0.58))
			draw_circle(scdp + Vector2(0.0, -14.0), 14.0, Color(0.22, 0.10, 0.40, 0.72))
			draw_circle(scdp + Vector2(0.0, -14.0), 10.0, Color(0.38, 0.20, 0.60, 0.50))
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
		# Fade-out flicker when nearly expired
		if sc_life < 0.25:
			draw_circle(scdp, 32.0, Color(0.28, 0.08, 0.48, (0.25 - sc_life) / 0.25 * 0.50))

	# Enemies
	for e in _enemies:
		var ep: Vector2    = e["pos"] as Vector2
		var er: float      = (e["r"] as float) * ENEMY_DRAW_SCALE
		var ec: Color      = e["col"] as Color
		var ekind: String  = e.get("kind", "normal") as String
		var efrozen: bool  = (e["iframes"] as float) > 0.0 and _has_skill("ice_orb")
		var enraged: bool  = (e["alive_t"] as float) >= 8.0
		var marked: bool   = (e.get("tg_mark_t", 0.0) as float) > 0.0
		var poisoned: bool = (e.get("poison_t", 0.0) as float) > 0.0
		# Walk animation — normals bob; bosses stay planted
		var e_alive_t: float = e["alive_t"] as float
		var e_facing_x: int  = e.get("facing_x", 1) as int
		var e_is_boss: bool  = ekind.ends_with("_boss")
		var e_walk: float    = e_alive_t * 9.0
		var e_bob: float     = 0.0 if e_is_boss else sin(e_walk) * 2.5
		var edp: Vector2     = ep + Vector2(0.0, e_bob)
		# Stubby legs behind body (normals without texture only)
		if not e_is_boss and not _enemy_tex.has(ekind):
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
		var e_has_tex: bool = _enemy_tex.has(ekind)
		if e_has_tex:
			var e_tex_size: float = er * 2.4
			draw_set_transform(edp, 0.0, Vector2(float(e_facing_x), 1.0))
			draw_texture_rect(
				_enemy_tex[ekind] as Texture2D,
				Rect2(Vector2(-e_tex_size * 0.5, -e_tex_size * 0.5), Vector2(e_tex_size, e_tex_size)),
				false,
				Color(1, 1, 1, 0.55) if efrozen else Color.WHITE
			)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_circle(edp, er, draw_col)
		if enraged and ekind in ["normal", "normal_tank", "normal_fast"]:
			# Red pulsing ring to warn player
			var pulse: float = 0.55 + 0.45 * sin(_elapsed * 8.0)
			draw_arc(edp, er + 4.0, 0.0, TAU, 20, Color(1.0, 0.10, 0.05, pulse), 2.5)
		if marked:
			draw_circle(edp, er + 9.0, Color(1.0, 0.96, 0.55, 0.20))
		if poisoned:
			draw_circle(edp, er + 4.0, Color(0.34, 1.0, 0.35, 0.14))
			draw_circle(edp, er + 6.0, Color(0.52, 1.0, 0.40, 0.12))
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
			"teleporter_boss":
				# Purple trail arcs (teleport aura)
				draw_arc(edp, er + 5.0, 0.0, TAU, 24, Color(0.70, 0.15, 1.0, 0.75), 3.0)
				var ta: float = _elapsed * 4.0
				for ti in 3:
					var tang: float = ta + float(ti) * TAU / 3.0
					draw_circle(edp + Vector2(cos(tang), sin(tang)) * (er + 10.0), 5.0, Color(0.80, 0.30, 1.0, 0.70))
				_draw_boss_name(edp, er, "Xylar the Rift Walker", Color(0.82, 0.48, 1.0))
			"shield_boss":
				var shield_on: bool = e["shield_active"] as bool
				if shield_on:
					draw_arc(edp, er + 8.0, 0.0, TAU, 32, Color(0.90, 0.90, 1.0, 0.90), 5.0)
					draw_circle(edp, er + 8.0, Color(0.80, 0.88, 1.0, 0.18))
				else:
					draw_arc(edp, er + 5.0, 0.0, TAU, 24, Color(0.20, 0.55, 0.95, 0.65), 2.5)
				_draw_boss_name(edp, er, "Zoran the Unbreakable Sentinel", Color(0.64, 0.86, 1.0))
			"shooter_boss":
				# Orange aim lines toward player
				draw_arc(edp, er + 5.0, 0.0, TAU, 24, Color(1.0, 0.60, 0.05, 0.70), 2.5)
				var aim_dir: Vector2 = (_player_pos - edp).normalized()
				draw_line(edp, edp + aim_dir * (er + 20.0), Color(1.0, 0.50, 0.02, 0.55), 2.5)
				_draw_boss_name(edp, er, "Raze the Scatter-Shot Overlord", Color(1.0, 0.66, 0.16))
			"lava_boss":
				var lava_state: String = e.get("lava_state", "idle") as String
				if lava_state == "charge":
					draw_circle(edp, er + 20.0, Color(1.0, 0.04, 0.01, 0.22 + 0.08 * sin(_elapsed * 24.0)))
					draw_arc(edp, er + 14.0, 0.0, TAU, 32, Color(1.0, 0.06, 0.02, 0.96), 6.0)
				elif lava_state == "shield":
					draw_circle(edp, er + 14.0, Color(0.34, 0.16, 0.08, 0.38))
					draw_arc(edp, er + 14.0, 0.0, TAU, 36, Color(0.45, 0.23, 0.10, 0.96), 8.0)
					for si in 9:
						var sa2: float = float(si) / 9.0 * TAU + _elapsed * 0.35
						draw_circle(edp + Vector2(cos(sa2), sin(sa2)) * (er + 14.0), 7.0, Color(1.0, 0.32, 0.04, 0.86))
				else:
					draw_arc(edp, er + 6.0, 0.0, TAU, 28, Color(1.0, 0.20, 0.02, 0.80), 4.0)
				var la: float = _elapsed * 2.5
				for li in 4:
					var lang: float = la + float(li) * TAU / 4.0
					draw_circle(edp + Vector2(cos(lang), sin(lang)) * (er + 12.0), 6.0, Color(1.0, 0.40, 0.02, 0.75))
				_draw_boss_name(edp, er, "Ignis the Magma Titan", Color(1.0, 0.34, 0.08))
			_:
				# Eye (fallback for any future boss or unknown kind)
				if not e_has_tex:
					draw_circle(edp + Vector2(er * 0.28 * float(e_facing_x), -er * 0.22), er * 0.22, Color(1, 0.9, 0.8))
		var ehp: float  = e["hp"] as float
		var emhp: float = e["max_hp"] as float
		var bw: float = er * 2.6
		var bx: float = edp.x - bw * 0.5
		var by: float = edp.y - er - 12.0
		draw_rect(Rect2(bx, by, bw, 6), Color(0.15, 0.06, 0.06, 0.85))
		var bar_col: Color
		match ekind:
			"teleporter_boss": bar_col = Color(0.70, 0.25, 1.0)
			"shield_boss":     bar_col = Color(0.35, 0.65, 1.0)
			"shooter_boss":    bar_col = Color(1.0, 0.55, 0.05)
			"lava_boss":       bar_col = Color(1.0, 0.22, 0.02)
			"normal_tank":     bar_col = Color(0.88, 0.55, 0.12)
			"normal_fast":     bar_col = Color(0.18, 0.72, 0.98)
			_:                 bar_col = Color(0.88, 0.15, 0.15)
		draw_rect(Rect2(bx, by, bw * clamp(ehp / emhp, 0.0, 1.0), 6), bar_col)
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

	# Shooter boss mortar warnings
	for strike in _mortar_strikes:
		var target: Vector2 = strike["pos"] as Vector2
		var launch: Vector2 = strike["launch"] as Vector2
		var life_left: float = strike["life"] as float
		var max_life: float = strike["max_life"] as float
		var progress: float = clamp(1.0 - life_left / max_life, 0.0, 1.0)
		var radius: float = strike["r"] as float
		var warning_alpha: float = 0.35 + 0.35 * sin(_elapsed * 16.0)
		draw_circle(target, radius, Color(1.0, 0.05, 0.02, 0.14 + warning_alpha * 0.20))
		draw_arc(target, radius, 0.0, TAU, 36, Color(1.0, 0.10, 0.04, 0.88), 3.0)
		draw_arc(target, radius * progress, 0.0, TAU, 28, Color(1.0, 0.55, 0.14, 0.90), 2.0)
		var projectile_pos: Vector2 = launch.lerp(target, progress) + Vector2(0.0, -sin(progress * PI) * 220.0 - 35.0 * (1.0 - progress))
		draw_circle(projectile_pos, 11.0, Color(1.0, 0.18, 0.04, 0.88))
		draw_circle(projectile_pos, 6.0, Color(1.0, 0.78, 0.24, 0.95))

	# Boss projectiles
	for bproj in _boss_projs:
		var bpp: Vector2 = bproj["pos"] as Vector2
		var proj_kind: String = bproj.get("kind", "straight") as String
		var outer_col: Color = Color(1.0, 0.08, 0.02, 0.92) if proj_kind == "lava_reflect" else Color(1.0, 0.25, 0.05, 0.88) if proj_kind == "homing" else Color(1.0, 0.55, 0.05, 0.85)
		draw_circle(bpp, 12.0, outer_col)
		draw_circle(bpp, 7.0, Color(1.0, 0.90, 0.30))
		draw_arc(bpp, 14.0, 0.0, TAU, 16, Color(1.0, 0.35, 0.02, 0.55), 2.0)
		if proj_kind == "lava_reflect":
			var target: Vector2 = bproj["target"] as Vector2
			draw_circle(target, bproj.get("explode_r", 58.0) as float, Color(1.0, 0.10, 0.02, 0.12 + 0.10 * sin(_elapsed * 16.0)))
			draw_arc(target, bproj.get("explode_r", 58.0) as float, 0.0, TAU, 28, Color(1.0, 0.22, 0.04, 0.72), 2.5)

	# Potions
	for p in _potions:
		var pp: Vector2 = p["pos"] as Vector2
		var pulse: float = 0.82 + sin(_elapsed * 5.0) * 0.18
		draw_circle(pp, 14.0 * pulse, Color(0.15, 0.80, 0.25, 0.30))
		draw_circle(pp, 10.0 * pulse, Color(0.25, 0.95, 0.40))
		draw_circle(pp, 5.0 * pulse, Color(0.70, 1.0, 0.72, 0.90))
		draw_string(ThemeDB.fallback_font, pp + Vector2(-8, -18), "+HP", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.30, 1.0, 0.45))

	# Ring drops
	for rd in _ring_drops:
		var rp: Vector2 = rd["pos"] as Vector2
		var ring: Dictionary = rd["ring"] as Dictionary
		var rpulse: float = 0.80 + sin(_elapsed * 4.0) * 0.20
		draw_arc(rp, 14.0 * rpulse, 0.0, TAU, 24, Color(0.98, 0.82, 0.15, 0.90), 3.5)
		draw_arc(rp, 8.0 * rpulse, 0.0, TAU, 16, Color(1.0, 0.95, 0.55, 0.55), 2.0)
		draw_string(ThemeDB.fallback_font, rp + Vector2(-10, -22), "\u25c6 Ring", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.88, 0.25))

	# AOE flashes (drawn after enemies for dramatic screen overlay)
	for fl in _aoe_flashes:
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
		draw_circle(fpos, 120.0 + 180.0 * flf, Color(0.85, 0.85, 0.95, flf * 0.16))
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
		elif fkind == "capy_charge":
			for dash in 9:
				var da: float = float(dash) / 9.0 * TAU + _elapsed * 1.0
				draw_arc(fpos, 220.0 + float(dash) * 6.0, da, da + 0.14, 12, Color(0.76, 0.56, 0.28, flf * 0.55), 3.2)
		elif fkind == "stampede":
			draw_circle(fpos, 280.0 * flf + 60.0, Color(0.42, 0.26, 0.12, flf * 0.18))
			for hoof in 10:
				var hoa: float = float(hoof) / 10.0 * TAU + _elapsed * 0.75
				draw_arc(fpos, 250.0 + float(hoof) * 4.0, hoa, hoa + 0.10, 10, Color(0.58, 0.34, 0.16, flf * 0.65), 4.0)
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

	# Orbs
	if _has_skill("orb"):
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
	for ft in _fire_trails:
		var ftp: Vector2  = ft["pos"] as Vector2
		var ftlf: float   = (ft["life"] as float) / (ft["max_life"] as float)
		var ftr: float    = (ft["r"] as float) * (0.5 + ftlf * 0.5)
		draw_circle(ftp, ftr * 1.5, Color(1.0, 0.28, 0.02, ftlf * 0.22))
		draw_circle(ftp, ftr, Color(1.0, 0.52, 0.05, ftlf * 0.50))
		draw_circle(ftp, ftr * 0.42, Color(1.0, 0.90, 0.38, ftlf * 0.65))

	# Fireballs — projectile with flame tail
	for fb in _fireballs:
		var fbp: Vector2  = fb["pos"] as Vector2
		var fbv: Vector2  = (fb["vel"] as Vector2).normalized()
		var perp: Vector2 = Vector2(-fbv.y, fbv.x)
		var fblf: float   = clamp((fb["life"] as float) / 4.0, 0.0, 1.0)
		var is_plasma: bool = (fb.get("kind", "fireball") as String) == "inferno_plasma"
		# Flame tail — tapering behind the ball
		var tail_pts: PackedVector2Array = PackedVector2Array()
		for s in 10:
			var td: float    = float(s + 1) * 9.0
			var taper: float = float(10 - s) / 10.0
			var jitter: float = sin(float(s) * 1.9 + _elapsed * 25.0) * taper * 5.0
			tail_pts.append(fbp - fbv * td + perp * jitter)
		if is_plasma:
			draw_polyline(tail_pts, Color(0.42, 0.96, 1.0, 0.42), 10.0)
			draw_polyline(tail_pts, Color(1.0, 0.90, 0.30, 0.70), 4.0)
			draw_circle(fbp, 12.0 + sin(_elapsed * 24.0) * 1.8, Color(0.45, 1.0, 1.0, 0.46))
			draw_circle(fbp, 9.0, Color(1.0, 0.92, 0.32))
			draw_circle(fbp, 5.0, Color(0.95, 1.0, 1.0, 0.96))
		else:
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
	for b in _bolts:
		var bp: Vector2   = b["pos"] as Vector2
		var bv: Vector2   = (b["vel"] as Vector2).normalized()
		var perp: Vector2 = Vector2(-bv.y, bv.x)
		var bkind: String = b.get("kind", "bolt") as String
		if bkind == "arcane_missile":
			draw_arc(bp, 14.0, 0.0, TAU, 24, Color(0.46, 0.12, 0.92, 0.65), 2.2)
			draw_circle(bp, 7.0, Color(0.90, 0.70, 1.0, 0.78))
			for mi in 3:
				var ma: float = _elapsed * 12.0 + float(mi) * TAU / 3.0
				draw_circle(bp + Vector2(cos(ma), sin(ma)) * 8.0, 1.5, Color(0.96, 0.88, 1.0, 0.78))
		elif bkind == "ricochet_arrow":
			var arrow_len_r: float = 30.0
			var tail_r: Vector2 = bp - bv * arrow_len_r
			draw_line(tail_r, bp, Color(0.08, 0.08, 0.08, 0.86), 3.0)
			draw_line(tail_r, bp, Color(0.26, 0.26, 0.26, 0.78), 1.5)
			var rleft: Vector2 = bp + perp * 5.5
			var rright: Vector2 = bp - perp * 5.5
			var rtip: Vector2 = bp + bv * 9.0
			draw_colored_polygon(PackedVector2Array([rleft, rright, rtip]), Color(0.08, 0.08, 0.08, 0.98))
			draw_line(tail_r, tail_r + perp * 7.0, Color(0.22, 0.22, 0.22, 0.68), 2.0)
			draw_line(tail_r, tail_r - perp * 7.0, Color(0.22, 0.22, 0.22, 0.68), 2.0)
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
			draw_line(bp - bv * 17.0, bp + bv * 10.0, Color(0.94, 0.94, 0.98, 0.92), 3.0)
			draw_line(bp - bv * 17.0, bp + bv * 10.0, Color(1.0, 1.0, 1.0, 0.72), 1.4)
			var ph_left: Vector2 = bp + perp * 5.0
			var ph_right: Vector2 = bp - perp * 5.0
			var ph_tip: Vector2 = bp + bv * 12.0
			draw_colored_polygon(PackedVector2Array([ph_left, ph_right, ph_tip]), Color(1.0, 1.0, 1.0, 0.96))
			draw_arc(bp, 10.0, 0.0, TAU, 18, Color(0.88, 0.92, 1.0, 0.38), 1.4)
		elif bkind == "trap_arrow":
			draw_line(bp - bv * 16.0, bp + bv * 10.0, Color(0.30, 0.42, 0.18, 0.88), 3.2)
			draw_line(bp - bv * 16.0, bp + bv * 10.0, Color(0.64, 0.88, 0.24, 0.68), 1.4)
			var tv_left: Vector2 = bp + perp * 5.0
			var tv_right: Vector2 = bp - perp * 5.0
			var tv_tip: Vector2 = bp + bv * 12.0
			draw_colored_polygon(PackedVector2Array([tv_left, tv_right, tv_tip]), Color(0.52, 0.96, 0.26, 0.96))
			for thorn in 4:
				var ta: float = _elapsed * 8.0 + float(thorn) * TAU / 4.0
				draw_circle(bp + Vector2(cos(ta), sin(ta)) * 7.0, 1.2, Color(0.70, 1.0, 0.34, 0.66))
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
	for b in _ice_orbs:
		var bp: Vector2  = b["pos"] as Vector2
		var fr: float    = b["freeze_r"] as float
		var blv: int     = b["lvl"] as int
		var lf: float    = clamp((b["life"] as float) / ICE_ORB_LIFE, 0.0, 1.0)
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
	for b in _pierce_arrows:
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
	for b in _boomerangs:
		var bp: Vector2 = b["pos"] as Vector2
		var spin_a: float = _elapsed * 9.0
		for pt in 5:
			var sa: float   = spin_a + float(pt) * TAU / 5.0
			var p1: Vector2 = bp + Vector2(cos(sa), sin(sa)) * (BOLT_R + 5.0)
			var p2: Vector2 = bp + Vector2(cos(sa + PI / 5.0), sin(sa + PI / 5.0)) * (BOLT_R * 0.35)
			draw_line(p1, p2, Color(0.96, 0.88, 0.24, 0.90), 2.5)
		draw_circle(bp, 5.0, Color(1.0, 0.95, 0.45, 0.82))
		draw_circle(bp, 3.0, Color(1.0, 1.0, 0.80, 0.90))

	# Player walk animation
	var p_is_moving: bool = _player_move_dir.length_squared() > 0.0
	var p_walk: float     = _elapsed * 11.0
	var p_bob: float      = sin(p_walk) * 3.0 if p_is_moving else 0.0
	var p_leg_l: float    = sin(p_walk) * 7.0 if p_is_moving else 0.0
	var p_leg_r: float    = sin(p_walk + PI) * 7.0 if p_is_moving else 0.0
	var pdp: Vector2      = _player_pos + Vector2(0.0, p_bob)
	var p_draw_r: float = PLAYER_DRAW_R
	# Legs drawn behind body
	var p_leg_col: Color = _player_tint.darkened(0.28)
	draw_circle(pdp + Vector2(-12.0, p_draw_r * 0.52 + p_leg_l), 7.0, p_leg_col)
	draw_circle(pdp + Vector2( 12.0, p_draw_r * 0.52 + p_leg_r), 7.0, p_leg_col)
	# Shadow
	draw_circle(_player_pos + Vector2(4, 8), p_draw_r - 4.0, Color(0, 0, 0, 0.22))
	# Player — portrait sprite or fallback circles
	if _player_tex != null:
		draw_set_transform(pdp, 0.0, Vector2(float(_player_facing_x), 1.0))
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

func _draw_bg() -> void:
	var view: Vector2 = get_viewport_rect().size
	var hw: float     = view.x * 0.5 + 128.0
	var hh: float     = view.y * 0.5 + 128.0
	var cx: float     = _player_pos.x
	var cy: float     = _player_pos.y
	var room: Dictionary = _current_room()
	var room_color: Color = room.get("col", Color(0.14, 0.11, 0.08)) as Color
	var base_col: Color = Color(0.14, 0.11, 0.08).lerp(room_color, 0.12)
	draw_rect(Rect2(cx - hw, cy - hh, hw * 2.0, hh * 2.0), base_col)
	const TILE: float = 100.0
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
	var room_id: String = room.get("id", "lava") as String
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
		var fl: float    = clamp((ft["life"] as float) / (ft["max_life"] as float), 0.0, 1.0)
		draw_circle(ftp, 28.0, Color(0.45, 0.88, 1.0, 0.22 * fl))
		draw_arc(ftp, 28.0, 0.0, TAU, 20, Color(0.55, 0.92, 1.0, 0.65 * fl), 2.0)

	# Enemy burn trails
	for bt in _burn_trails:
		var btp: Vector2 = bt["pos"] as Vector2
		var bl: float    = clamp((bt["life"] as float) / (bt["max_life"] as float), 0.0, 1.0)
		var bpulse: float = 0.5 + 0.5 * sin(_elapsed * 8.0 + (btp.x + btp.y) * 0.05)
		draw_circle(btp, 26.0, Color(1.0, 0.30 + bpulse * 0.20, 0.0, 0.25 * bl))
		draw_arc(btp, 26.0, 0.0, TAU, 18, Color(1.0, 0.55, 0.05, 0.70 * bl), 2.5)

	# Time warp zones — drawn over most game objects
	for twz in _time_warp_zones:
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
	for smc in _smoke_clouds:
		var smcp:   Vector2 = smc["pos"] as Vector2
		var smcr:   float   = smc["r"] as float
		var smclf:  float   = clamp((smc["life"] as float) / (smc["max_life"] as float), 0.0, 1.0)
		var smc_p:  float   = 0.72 + 0.28 * sin(_elapsed * 1.6 + smcp.x * 0.008)
		draw_circle(smcp, smcr * smc_p, Color(0.46, 0.44, 0.52, 0.38 * smclf))
		draw_circle(smcp, smcr * 0.68 * smc_p, Color(0.56, 0.54, 0.62, 0.52 * smclf))
		for sbump in 5:
			var sba: float = float(sbump) / 5.0 * TAU + _elapsed * 0.25 + smcp.y * 0.005
			draw_circle(smcp + Vector2(cos(sba), sin(sba)) * (smcr * 0.52), smcr * 0.38 * smc_p, Color(0.58, 0.56, 0.64, 0.32 * smclf))

	# Darkness rings drawn OVER everything (only in darkness rooms)
	if (_current_room().get("id", "lava") as String) == "darkness":
		var vis_r: float = 150.0
		for s in 20:
			var t: float     = float(s) / 19.0
			var ring_r: float = vis_r + 55.0 + t * 820.0
			var ring_a: float = 0.65 + t * t * 0.35
			draw_arc(_player_pos, ring_r, 0.0, TAU, 40, Color(0.0, 0.0, 0.0, ring_a), 56.0)

	# Boss intermission props + arena frame
	var bi_state: String = _boss_intermission.get("state", "none") as String
	if bi_state == "await_choice":
		var dp: Vector2 = _boss_intermission.get("door_pos", _player_pos) as Vector2
		var lp: Vector2 = _boss_intermission.get("ladder_pos", _player_pos) as Vector2
		var view_rect: Rect2 = get_viewport_rect()
		# Off-screen portal indicator
		if not view_rect.has_point(dp):
			var to_portal: Vector2 = (dp - _player_pos).normalized()
			var edge_pos: Vector2 = _player_pos + to_portal * 250.0
			edge_pos = Vector2(clamp(edge_pos.x, 0.0, view_rect.size.x), clamp(edge_pos.y, 0.0, view_rect.size.y))
			draw_circle(edge_pos, 18.0, Color(0.78, 0.52, 1.0, 0.88))
			draw_circle(edge_pos + Vector2(0.0, -6.0), 12.0, Color(0.98, 0.86, 0.36, 0.90))
		# Off-screen ladder indicator
		if not view_rect.has_point(lp):
			var to_ladder: Vector2 = (lp - _player_pos).normalized()
			var edge_pos: Vector2 = _player_pos + to_ladder * 250.0
			edge_pos = Vector2(clamp(edge_pos.x, 0.0, view_rect.size.x), clamp(edge_pos.y, 0.0, view_rect.size.y))
			draw_line(edge_pos + Vector2(-40.0, -50.0), edge_pos + Vector2(-40.0, 50.0), Color(0.64, 0.50, 0.28, 0.85), 18.0)
			draw_line(edge_pos + Vector2(40.0, -50.0), edge_pos + Vector2(40.0, 50.0), Color(0.64, 0.50, 0.28, 0.85), 18.0)
			draw_line(edge_pos + Vector2(-35.0, -45.0), edge_pos + Vector2(35.0, -45.0), Color(0.78, 0.62, 0.36, 0.88), 12.0)
			draw_line(edge_pos + Vector2(-35.0, 0.0), edge_pos + Vector2(35.0, 0.0), Color(0.78, 0.62, 0.36, 0.88), 12.0)
			draw_line(edge_pos + Vector2(-35.0, 45.0), edge_pos + Vector2(35.0, 45.0), Color(0.78, 0.62, 0.36, 0.88), 12.0)
		var pr1: float = 180.0 + sin(_elapsed * 3.8) * 15.0
		var pr2: float = 120.0 + cos(_elapsed * 4.6) * 10.0
		draw_circle(dp, pr1, Color(0.42, 0.18, 0.76, 0.34))
		draw_arc(dp, pr1, 0.0, TAU, 32, Color(0.78, 0.52, 1.0, 0.92), 4.0)
		draw_arc(dp, pr2, 0.0, TAU, 28, Color(0.48, 0.90, 1.0, 0.84), 3.0)
		for pi in 9:
			var pa: float = float(pi) / 9.0 * TAU + _elapsed * 1.6
			draw_circle(dp + Vector2(cos(pa), sin(pa)) * (pr2 - 20.0), 16.0, Color(0.90, 0.76, 1.0, 0.74))
		# Key emblem on portal
		draw_circle(dp + Vector2(0.0, -6.0), 16.0, Color(0.98, 0.86, 0.36, 0.92))
		draw_circle(dp + Vector2(0.0, -6.0), 8.0, Color(0.46, 0.20, 0.06, 0.96))
		draw_rect(Rect2(dp + Vector2(8.0, -10.0), Vector2(20.0, 8.0)), Color(0.98, 0.86, 0.36, 0.92), true)
		draw_rect(Rect2(dp + Vector2(21.0, -10.0), Vector2(4.0, 14.0)), Color(0.98, 0.86, 0.36, 0.92), true)
		draw_rect(Rect2(dp + Vector2(24.0, -2.0), Vector2(4.0, 6.0)), Color(0.98, 0.86, 0.36, 0.92), true)
		draw_line(Vector2(lp.x - 70.0, lp.y - 170.0), Vector2(lp.x - 70.0, lp.y + 120.0), Color(0.64, 0.50, 0.28, 0.95), 20.0)
		draw_line(Vector2(lp.x + 70.0, lp.y - 170.0), Vector2(lp.x + 70.0, lp.y + 120.0), Color(0.64, 0.50, 0.28, 0.95), 20.0)
		for r in 6:
			var ry: float = lp.y - 140.0 + float(r) * 50.0
			draw_line(Vector2(lp.x - 60.0, ry), Vector2(lp.x + 60.0, ry), Color(0.78, 0.62, 0.36, 0.90), 12.0)
	if bi_state == "arena":
		var ac: Vector2 = _boss_intermission.get("arena_center", _player_pos) as Vector2
		var ah: Vector2 = _boss_intermission.get("arena_half", BOSS_ARENA_HALF) as Vector2
		draw_rect(Rect2(ac.x - ah.x, ac.y - ah.y, ah.x * 2.0, ah.y * 2.0), Color(0.08, 0.06, 0.10, 0.18), true)
		draw_rect(Rect2(ac.x - ah.x, ac.y - ah.y, ah.x * 2.0, ah.y * 2.0), Color(0.96, 0.70, 0.24, 0.88), false, 4.0)

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
	hp_bg.position = Vector2(28, 44); hp_bg.size = Vector2(330, 32)
	hud.add_child(hp_bg)

	_hp_fill = Panel.new()
	var hp_fill_s := StyleBoxFlat.new()
	hp_fill_s.bg_color = Color(0.82, 0.12, 0.12)
	hp_fill_s.corner_radius_top_left = 10; hp_fill_s.corner_radius_top_right = 10
	hp_fill_s.corner_radius_bottom_right = 10; hp_fill_s.corner_radius_bottom_left = 10
	_hp_fill.add_theme_stylebox_override("panel", hp_fill_s)
	_hp_fill.position = Vector2(3, 3); _hp_fill.size = Vector2(324, 26)
	_hp_fill.custom_minimum_size = Vector2(0, 26)
	hp_bg.add_child(_hp_fill)

	var hp_lbl := Label.new()
	hp_lbl.text = "HP"
	hp_lbl.add_theme_font_size_override("font_size", 13)
	hp_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.85))
	hp_lbl.position = Vector2(7, 7); hp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bg.add_child(hp_lbl)

	# XP bar
	var xp_bg := Panel.new()
	var xp_bg_s := StyleBoxFlat.new()
	xp_bg_s.bg_color = Color(0.10, 0.08, 0.04, 0.90)
	xp_bg_s.corner_radius_top_left = 8; xp_bg_s.corner_radius_top_right = 8
	xp_bg_s.corner_radius_bottom_right = 8; xp_bg_s.corner_radius_bottom_left = 8
	xp_bg.add_theme_stylebox_override("panel", xp_bg_s)
	xp_bg.position = Vector2(28, 82); xp_bg.size = Vector2(330, 18)
	hud.add_child(xp_bg)

	_xp_fill = Panel.new()
	var xp_fill_s := StyleBoxFlat.new()
	xp_fill_s.bg_color = Color(0.92, 0.72, 0.10)
	xp_fill_s.corner_radius_top_left = 6; xp_fill_s.corner_radius_top_right = 6
	xp_fill_s.corner_radius_bottom_right = 6; xp_fill_s.corner_radius_bottom_left = 6
	_xp_fill.add_theme_stylebox_override("panel", xp_fill_s)
	_xp_fill.position = Vector2(2, 2); _xp_fill.size = Vector2(0, 14)
	_xp_fill.custom_minimum_size = Vector2(0, 14)
	xp_bg.add_child(_xp_fill)

	# Level label
	_level_lbl = Label.new()
	_level_lbl.text = "LV 1"
	_level_lbl.add_theme_font_size_override("font_size", 34)
	_level_lbl.add_theme_color_override("font_color", Color(0.98, 0.88, 0.50))
	_level_lbl.position = Vector2(370, 42)
	hud.add_child(_level_lbl)

	# Time  — below XP bar
	_time_lbl = Label.new()
	_time_lbl.text = "0:00"
	_time_lbl.add_theme_font_size_override("font_size", 34)
	_time_lbl.add_theme_color_override("font_color", Color(0.90, 0.86, 0.76))
	_time_lbl.position = Vector2(28, 106); _time_lbl.size = Vector2(720, 44)
	hud.add_child(_time_lbl)

	# Kill count  — same row, right-aligned
	_kill_lbl = Label.new()
	_kill_lbl.text = "Kills: 0"
	_kill_lbl.add_theme_font_size_override("font_size", 34)
	_kill_lbl.add_theme_color_override("font_color", Color(0.75, 0.70, 0.60))
	_kill_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_kill_lbl.position = Vector2(28, 106); _kill_lbl.size = Vector2(720, 44)
	hud.add_child(_kill_lbl)

	# Wave label  — second sub-row
	_wave_lbl = Label.new()
	_wave_lbl.text = "Wave 1"
	_wave_lbl.add_theme_font_size_override("font_size", 34)
	_wave_lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.20))
	_wave_lbl.position = Vector2(28, 148); _wave_lbl.size = Vector2(980, 44)
	hud.add_child(_wave_lbl)

	# Room effect detail  — third sub-row
	_room_detail_lbl = Label.new()
	_room_detail_lbl.text = ""
	_room_detail_lbl.add_theme_font_size_override("font_size", 24)
	_room_detail_lbl.add_theme_color_override("font_color", Color(0.80, 0.76, 0.65))
	_room_detail_lbl.position = Vector2(28, 192); _room_detail_lbl.size = Vector2(1220, 66)
	_room_detail_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_child(_room_detail_lbl)

	# Enemy modifier summary  — fourth sub-row
	_enemy_mod_lbl = Label.new()
	_enemy_mod_lbl.text = ""
	_enemy_mod_lbl.add_theme_font_size_override("font_size", 23)
	_enemy_mod_lbl.add_theme_color_override("font_color", Color(1.0, 0.58, 0.20))
	_enemy_mod_lbl.position = Vector2(28, 250); _enemy_mod_lbl.size = Vector2(1260, 56)
	_enemy_mod_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_child(_enemy_mod_lbl)

	# Skill icons row (bottom) — hidden during gameplay
	_skill_icon_row = HBoxContainer.new()
	_skill_icon_row.add_theme_constant_override("separation", 10)
	_skill_icon_row.position = Vector2(28, view.y - 108)
	_skill_icon_row.size     = Vector2(view.x - 56, 88)
	_skill_icon_row.visible = false
	hud.add_child(_skill_icon_row)

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

	# Joystick visual
	_joy_vis = JoystickVisual.new()
	hud.add_child(_joy_vis)

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
	s.corner_radius_top_left    = 18
	s.corner_radius_top_right   = 18
	s.corner_radius_bottom_right = 18
	s.corner_radius_bottom_left  = 18
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
	_hp_fill.size = Vector2(324.0 * clamp(_player_hp / _player_max_hp, 0.0, 1.0), 26)
	_xp_fill.size = Vector2(326.0 * clamp(float(_xp) / float(_xp_next), 0.0, 1.0), 14)
	_level_lbl.text = "LV %d" % _level
	var m: int = int(_elapsed) / 60
	var s: int = int(_elapsed) % 60
	_time_lbl.text = "%d:%02d  |  Kills: %d" % [m, s, _kills]
	_kill_lbl.text = ""  # merged into time label

	var room: Dictionary = _current_room()
	var room_name: String = room.get("name", "Room") as String
	var room_desc: String = room.get("desc", "") as String
	var room_pulse: float = 0.72 + 0.28 * sin(_room_elapsed * 4.0)
	var room_color: Color = (room.get("col", Color(1.0, 1.0, 1.0)) as Color).lerp(Color(1.0, 1.0, 1.0), room_pulse)

	if _wave_lbl != null:
		_wave_lbl.add_theme_color_override("font_color", room_color)
		match _wave_state:
			"between":
				_wave_lbl.text = "Wave %d — %s — Next: %.0fs" % [_wave, room_name, _between_t]
			"waiting":
				_wave_lbl.text = "Wave %d — %s — Clear!" % [_wave, room_name]
			_:
				_wave_lbl.text = "Wave %d — %s" % [_wave, room_name]

	if _room_detail_lbl != null:
		_room_detail_lbl.add_theme_color_override("font_color", (room.get("col", Color(0.80, 0.76, 0.65)) as Color).lerp(Color(0.90, 0.86, 0.76), 0.4))
		_room_detail_lbl.text = "%s\nStash Keys: %d" % [room_desc, PurchaseStore.get_key_count(account_username)]

	if _enemy_mod_lbl != null:
		_enemy_mod_lbl.position.y = _room_detail_lbl.position.y + 130.0
		if _wave >= 10 and not _active_enemy_mod.is_empty():
			_enemy_mod_lbl.text = "Floor affix: %s - %s" % [_active_enemy_mod_name, _active_enemy_mod_desc]
		else:
			_enemy_mod_lbl.text = "Floor affix: none"

func _update_skill_icons() -> void:
	for c in _skill_icon_row.get_children():
		c.queue_free()
	for sk in _skills:
		var sid: String      = sk["id"] as String
		var lvl: int         = sk["level"] as int
		var sdef: Dictionary = SKILL_DEFS[sid] as Dictionary
		var pill := Panel.new()
		var ps := StyleBoxFlat.new()
		ps.bg_color = Color(0.10, 0.08, 0.06, 0.90)
		ps.corner_radius_top_left = 10; ps.corner_radius_top_right = 10
		ps.corner_radius_bottom_right = 10; ps.corner_radius_bottom_left = 10
		ps.set_border_width_all(2)
		ps.border_color = (sdef["col"] as Color).darkened(0.15)
		pill.add_theme_stylebox_override("panel", ps)
		pill.custom_minimum_size = Vector2(196, 104)
		var nl := Label.new()
		nl.text = sdef["name"] as String
		nl.add_theme_font_size_override("font_size", 22)
		nl.add_theme_color_override("font_color", sdef["col"] as Color)
		nl.position = Vector2(12, 10); nl.size = Vector2(172, 40)
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill.add_child(nl)
		var ll := Label.new()
		ll.text = "Lv %d" % lvl
		ll.add_theme_font_size_override("font_size", 20)
		ll.add_theme_color_override("font_color", Color(0.70, 0.65, 0.52))
		ll.position = Vector2(12, 56); ll.size = Vector2(172, 34)
		ll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill.add_child(ll)
		_skill_icon_row.add_child(pill)

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
	var card_h: float = 172.0
	var gap: float    = 18.0
	var total_h: float = 3.0 * card_h + 2.0 * gap
	var start_y: float = (view.y - total_h) * 0.5

	for i in 3:
		var ch: Dictionary  = choices[i]
		var sid: String     = ch["id"] as String
		var new_lvl: int    = ch["lvl"] as int
		var is_up: bool     = (ch["type"] as String) == "upgrade"
		var is_ulti: bool   = ch.get("is_ulti", false) as bool
		var is_combo: bool  = ch.get("is_combo", false) as bool
		var sdef: Dictionary = SKILL_DEFS[sid] as Dictionary
		var levels: Array    = sdef["lvl"] as Array
		var ldata: Dictionary = levels[new_lvl - 1] as Dictionary
		var scol: Color       = sdef["col"] as Color
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
		elif is_up:
			badge.text = "UPGRADE"
			badge.add_theme_color_override("font_color", Color(0.90, 0.72, 0.20))
		else:
			badge.text = "NEW"
			badge.add_theme_color_override("font_color", Color(0.32, 0.95, 0.55))
		badge.add_theme_font_size_override("font_size", 15 if not is_ulti else 17)
		badge.position = Vector2(16, 12); badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(badge)

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
		nm.text = sdef["name"] as String
		nm.add_theme_font_size_override("font_size", 38)
		nm.add_theme_color_override("font_color", scol)
		nm.position = Vector2(16, 36); nm.size = Vector2(card_w - 120, 46)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(nm)

		# Level
		var lv := Label.new()
		lv.text = "Level %d" % new_lvl
		lv.add_theme_font_size_override("font_size", 18)
		lv.add_theme_color_override("font_color", Color(0.60, 0.55, 0.42))
		lv.position = Vector2(card_w - 116, 42); lv.size = Vector2(100, 28)
		lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lv)

		# Description
		var desc := Label.new()
		desc.text = ldata["note"] as String
		desc.add_theme_font_size_override("font_size", 26)
		desc.add_theme_color_override("font_color", Color(0.82, 0.76, 0.65))
		desc.position = Vector2(16, 90); desc.size = Vector2(card_w - 32, 72)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(desc)

		var cap_sid: String = sid
		var cap_lvl: int    = new_lvl
		var cap_lay: Node   = layer
		card.pressed.connect(func() -> void:
			_pick_skill(cap_sid, cap_lvl)
			cap_lay.queue_free()
			_paused = false
		)
		layer.add_child(card)

	# ── Watch Ad to Reroll button ─────────────────────────────────────────────
	var reroll_y: float = start_y + 3.0 * (card_h + gap) + 20.0
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
			reroll_btn.disabled = true
			reroll_btn.text = "Loading ad..."
			_ad_manager.rewarded_ad_completed.connect(
				func() -> void:
					_skill_reroll_used = true
					cap_layer.queue_free()
					_show_skill_select(cap_is_initial, true),
				CONNECT_ONE_SHOT
			)
			_ad_manager.rewarded_ad_skipped.connect(
				func() -> void:
					reroll_btn.disabled = false
					reroll_btn.text = "Watch Ad to Reroll Skills",
				CONNECT_ONE_SHOT
			)
			_ad_manager.show_rewarded_ad()
		)
	layer.add_child(reroll_btn)

func _build_skill_choices() -> Array[Dictionary]:
	# ── Determine which skills this character can use ─────────────────────────
	var allowed: Array = (CHAR_SKILLS.get(_char_id, null) as Array) if CHAR_SKILLS.has(_char_id) else (CHAR_SKILLS["_default"] as Array)
	var ulti_sid: String = ULTI_SKILLS.get(_char_id, "") as String

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

func _pick_skill(sid: String, lvl: int) -> void:
	_play_skill_sfx("skill_pick", -8.0, 1.0 + float(lvl - 1) * 0.04, 0.08)
	if _is_combo_skill(sid):
		_consume_combo_requirements(sid)
	if _has_skill(sid):
		_get_skill(sid)["level"] = lvl
	else:
		var sk: Dictionary = {"id": sid, "level": 1, "timer": 0.0}
		_skills.append(sk)
	_update_skill_icons()

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
	if account_username.is_empty():
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
	_game_over = true
	_paused    = true
	_ring_drops.clear()
	queue_redraw()
	if _run_key_dropped:
		PurchaseStore.start_key_drop_cooldown(account_username)

	if not _loss_recorded and not account_username.is_empty() and selected_player_character != null:
		_loss_recorded = true
		StatsStore.record_match_detail(
			account_username,
			String(selected_player_character.id),
			_kills,
			_elapsed,
			RingStore.get_equipped_rings(account_username, String(selected_player_character.id)),
			ArtifactStore.get_equipped_artifacts(account_username, String(selected_player_character.id))
		)
		StatsStore.record_match(
			account_username,
			String(selected_player_character.id),
			StatsStore.OUTCOME_LOSS,
			0, _elapsed, 0, _kills
		)
		LeaderboardClient.submit_stats(self, account_username, account_display_name)

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
	stats.text = "Survived  %d:%02d\nLevel %d  ·  %d kills\nNext key drop: %s" % [m, s, _level, _kills, PurchaseStore.get_key_drop_remaining_text(account_username)]
	stats.add_theme_font_size_override("font_size", 38)
	stats.add_theme_color_override("font_color", Color(0.88, 0.82, 0.68))
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.position = Vector2(0, view.y * 0.36); stats.size = Vector2(view.x, 150)
	layer.add_child(stats)

	var has_ring_rewards: bool = not _rings_obtained.is_empty()
	var has_artifact_reward: bool = not _boss_artifact_result.is_empty()
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
	if not _ad_revive_used:
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
		var cap_layer: Node = layer
		revive_btn.pressed.connect(func() -> void:
			_start_revive_ad(cap_layer)
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
	var back := Button.new()
	back.text = "Back to Lobby"
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
	back.pressed.connect(func() -> void: match_ended.emit("lobby"))
	layer.add_child(back)

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
		more.add_theme_font_size_override("font_size", 60)
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
	title.text = "Boss Artifact"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.84, 0.78, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var reward_art: Dictionary = _boss_artifact_result.get("artifact", {}) as Dictionary
	var duplicated: bool = _boss_artifact_result.get("duplicated", false) as bool
	if not reward_art.is_empty():
		root.add_child(_make_death_artifact_row(reward_art, duplicated))
	if duplicated:
		var dup := Label.new()
		dup.text = "Duplicated artifact - key refunded to stash"
		dup.add_theme_font_size_override("font_size", 60)
		dup.add_theme_color_override("font_color", Color(0.70, 0.70, 0.74))
		dup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	row.custom_minimum_size = Vector2(0, 174)
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.focus_mode = Control.FOCUS_NONE
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.text = "[%s]  %s%s" % [
		rarity.to_upper(),
		artifact.get("name", "Artifact") as String,
		"  (Duplicated)" if duplicated else "",
	]
	row.add_theme_font_size_override("font_size", 66)
	row.add_theme_color_override("font_color", Color(0.68, 0.68, 0.70) if duplicated else rarity_color)
	if duplicated:
		row.modulate = Color(0.66, 0.66, 0.66, 1.0)
	return row

func _make_death_ring_row(ring: Dictionary) -> Control:
	var rarity: String = ring.get("rarity", "common") as String
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
	row.custom_minimum_size = Vector2(0, 174)
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.focus_mode = Control.FOCUS_NONE
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.icon = RingStore.ring_icon(ring)
	row.expand_icon = true
	row.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	row.text = "[%s]  %s  T%d  (%s)" % [
		rarity.to_upper(),
		ring.get("name", "Ring") as String,
		int(ring.get("tier", 1)),
		_format_ring_bonus(ring),
	]
	row.add_theme_font_size_override("font_size", 66)
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

func _start_revive_ad(death_layer: Node) -> void:
	_ad_manager.rewarded_ad_completed.connect(
		func() -> void: _do_revive(death_layer), CONNECT_ONE_SHOT
	)
	_ad_manager.rewarded_ad_skipped.connect(
		func() -> void: pass,   # player closed ad early — no revive, screen stays
		CONNECT_ONE_SHOT
	)
	_ad_manager.show_rewarded_ad()

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
	return max(value * (1.0 - _ring_bonus("skill_cd") + _artifact_wheel_cd), 0.12)

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
	return _apply_radius_bonus(ORB_ORBIT_R)

func _capy_orb_hit_radius() -> float:
	return _apply_radius_bonus(ORB_R)

func _slvl(sid: String, lvl: int) -> Dictionary:
	var sdef: Dictionary = SKILL_DEFS[sid] as Dictionary
	var levels: Array    = sdef["lvl"] as Array
	var out: Dictionary = (levels[lvl - 1] as Dictionary).duplicate(true)
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
	if out.has("spd"):
		out["spd"] = _apply_projectile_speed_bonus(float(out["spd"]))
	if out.has("chains"):
		out["chains"] = int(out["chains"] as int) + int(round(_ring_bonus("lightning_chain")))
	if out.has("chain_dmg"):
		out["chain_dmg"] = float(out["chain_dmg"]) * (1.0 + _ring_bonus("lightning_dmg"))
	return out
