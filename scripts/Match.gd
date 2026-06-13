extends Node2D

## Vampire Survivors-style roguelite.
## Move to survive, skills auto-cast, kill monsters, level up, pick new skills.

signal match_ended(next_action: String)

# ─── Public (set by Main before adding to tree) ───────────────────────────────
var selected_player_character: CharacterData = null
var account_username: String = ""

# ─── Tuning constants ─────────────────────────────────────────────────────────
const PLAYER_R:    float = 26.0
const IFRAMES_SEC: float = 0.55
const ORB_ORBIT_R: float = 72.0
const ORB_R:       float = 14.0
const ORB_SPD:     float = 2.2
const BOLT_R:      float = 8.0
const BOLT_LIFE:   float = 3.5
const ICE_ORB_R:   float = 11.0
const ICE_ORB_LIFE: float = 5.0
const XP_ORB_R:    float = 9.0
const XP_COLLECT_R: float = 80.0
const ENEMY_HIT_IF: float = 0.28

# ─── Skill definitions ────────────────────────────────────────────────────────
const SKILL_DEFS: Dictionary = {
	"orb": {
		"name": "Capy Orb", "short": "Orbiting damage balls",
		"col": Color(0.98, 0.72, 0.08), "max_lvl": 5,
		"lvl": [
			{"orbs": 3, "dmg": 12.0, "note": "3 orbiting balls"},
			{"orbs": 3, "dmg": 18.0, "note": "+damage"},
			{"orbs": 4, "dmg": 24.0, "note": "4 balls, +damage"},
			{"orbs": 4, "dmg": 32.0, "note": "+damage"},
			{"orbs": 5, "dmg": 42.0, "note": "5 balls — MAX POWER"},
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
			{"n": 1, "dmg": 42.0, "cd": 2.8, "spd": 320.0, "freeze_r": 90.0,  "slow": 0.70, "note": "Freezing orb, slows enemies"},
			{"n": 1, "dmg": 62.0, "cd": 2.6, "spd": 340.0, "freeze_r": 110.0, "slow": 0.75, "note": "+freeze radius"},
			{"n": 2, "dmg": 86.0, "cd": 2.4, "spd": 360.0, "freeze_r": 130.0, "slow": 0.80, "note": "2 orbs"},
			{"n": 2, "dmg": 114.0, "cd": 2.2, "spd": 380.0, "freeze_r": 155.0, "slow": 0.85, "note": "Bigger freeze zone"},
			{"n": 3, "dmg": 150.0, "cd": 2.0, "spd": 420.0, "freeze_r": 190.0, "slow": 0.92, "note": "3 orbs — MAX FREEZE"},
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
}

# ─── Character skill pools (per character ID, falls back to _default) ─────────
const CHAR_SKILLS: Dictionary = {
	"_default":      ["orb", "bolt", "ice_orb", "wave", "aura", "regen", "magnet"],
	"capy_brown":    ["orb", "bolt", "ice_orb", "wave", "regen", "magnet", "swirl_tangerine"],
	"capy_wizard":   ["fireball", "elec_wave", "hurricane", "blizzard", "regen", "magnet"],
	"capy_archer":   ["arrow", "split_arrow", "pierce_arrow", "sky_fall", "regen", "magnet"],
	"capy_assassin": ["star_knife", "knife_storm", "boomerang", "seven_slash", "regen", "magnet"],
}

# ─── Ultimate skill per character (empty string = no ulti) ────────────────────
const ULTI_SKILLS: Dictionary = {
	"capy_brown":    "swirl_tangerine",
	"capy_wizard":   "blizzard",
	"capy_archer":   "sky_fall",
	"capy_assassin": "seven_slash",
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

# ─── Potions  {pos,life} ─────────────────────────────────────────────────────
var _potions: Array[Dictionary] = []

# ─── Ring drops  {pos,life,ring} ─────────────────────────────────────────────
var _ring_drops: Array[Dictionary] = []

# ─── Boss projectiles  {pos,vel,dmg,life} ────────────────────────────────
var _boss_projs: Array[Dictionary] = []

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

# ─── Touch input ──────────────────────────────────────────────────────────────
var _touch_id:     int     = -1
var _touch_origin: Vector2 = Vector2.ZERO
var _touch_cur:    Vector2 = Vector2.ZERO
var _joy_zone:     Rect2

# ─── State flags ──────────────────────────────────────────────────────────────
var _paused:    bool = false
var _game_over: bool = false
var _revive_used: bool = false   # true once the player has used the ad revive

# ─── Ads ──────────────────────────────────────────────────────────────────────
var _ad_manager: AdManager = null

# ─── Character / ulti tracking ────────────────────────────────────────────────
var _char_id:       String = ""
var _ulti_unlocked: bool   = false
var _ulti_offered:  bool   = false

# ─── Ring bonuses (applied at match start) ───────────────────────────────────
var _ring_bonuses:  Dictionary = {}

# ═════════════════════════════════════════════════════════════════════════════
# SETUP
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	SettingsStore.apply(get_tree())
	var view: Vector2 = get_viewport_rect().size
	_joy_zone = Rect2(0.0, view.y * 0.55, view.x * 0.5, view.y * 0.45)

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
		# Load portrait texture — use Image pipeline to preserve alpha channel
		var tex_path: String = "res://assets/characters/" + String(selected_player_character.id) + ".png"
		if ResourceLoader.exists(tex_path):
			var img: Image = Image.new()
			img.load(ProjectSettings.globalize_path(tex_path))
			if not img.is_empty():
				if not img.detect_alpha() == Image.ALPHA_NONE:
					img.convert(Image.FORMAT_RGBA8)
				else:
					img.convert(Image.FORMAT_RGBA8)
				_player_tex = ImageTexture.create_from_image(img)

	# ── Apply ring bonuses ────────────────────────────────────────────────
	if not account_username.is_empty() and not _char_id.is_empty():
		var bonuses: Dictionary = RingStore.get_bonuses(account_username, _char_id)
		if bonuses.has("max_hp"):
			_player_max_hp += float(bonuses["max_hp"])
			_player_hp      = _player_max_hp
		if bonuses.has("move_speed"):
			_player_speed += float(bonuses["move_speed"])
		# Store bonuses for in-game use (damage, CD, etc.)
		_ring_bonuses = bonuses

	_camera = Camera2D.new()
	_camera.position = _player_pos
	add_child(_camera)

	_build_hud()
	_show_skill_select(true)
	# Kick off wave 1 after a short delay
	_wave        = 0
	_wave_state  = "between"
	_between_t   = 2.0  # 2s grace period before first wave

	# Load enemy textures
	var _enemy_tex_map: Dictionary = {
		"normal":      "res://assets/enemies/enemy_normal.png",
		"normal_tank": "res://assets/enemies/enemy_tank.png",
		"normal_fast": "res://assets/enemies/enemy_fast.png",
	}
	for ek in _enemy_tex_map:
		var ep2: String = _enemy_tex_map[ek]
		if ResourceLoader.exists(ep2):
			var eimg: Image = Image.new()
			eimg.load(ProjectSettings.globalize_path(ep2))
			if not eimg.is_empty():
				eimg.convert(Image.FORMAT_RGBA8)
				_enemy_tex[ek] = ImageTexture.create_from_image(eimg)

	# Initialise ad manager
	_ad_manager = AdManager.new()
	add_child(_ad_manager)

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
	_player_iframes    = max(0.0, _player_iframes - delta)
	var _pmove: Vector2 = _get_move_dir()
	_player_move_dir    = _pmove
	_player_pos        += _pmove * _player_speed * delta
	if _pmove.x > 0.01:    _player_facing_x = 1
	elif _pmove.x < -0.01: _player_facing_x = -1
	_camera.position    = _player_pos
	_update_skills(delta)
	_check_orb_hits()
	_update_enemies(delta)
	_update_bolts(delta)
	_update_ice_orbs(delta)
	_update_fireballs(delta)
	_update_fire_trails(delta)
	_update_pierce_arrows(delta)
	_update_boomerangs(delta)
	_update_aoe_flashes(delta)
	_update_waves(delta)
	_update_xp_orbs(delta)
	_update_potions(delta)
	_update_ring_drops(delta)
	_update_boss_projs(delta)
	_update_lava_pools(delta)
	_update_spawner(delta)
	queue_redraw()
	_update_hud()

# ═════════════════════════════════════════════════════════════════════════════
# SKILL UPDATES
# ═════════════════════════════════════════════════════════════════════════════

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
			fs["timer"] = 1.2 - float(fs["level"] as int) * 0.12  # 1.2s → 0.6s at L5
			_fire_fireball(fdef["orbs"] as int, fdef["dmg"] as float, 480.0)

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
			var adef: Dictionary = _slvl("aura", as_["level"] as int)
			var ar: float        = adef["r"] as float
			var tick: float      = (adef["dps"] as float) * 0.5
			for i in range(_enemies.size() - 1, -1, -1):
				var ep: Vector2 = _enemies[i]["pos"] as Vector2
				if ep.distance_to(_player_pos) <= ar + (_enemies[i]["r"] as float):
					_enemies[i]["hp"] = (_enemies[i]["hp"] as float) - tick
					if (_enemies[i]["hp"] as float) <= 0.0:
						_xp_orbs.append({"pos": ep, "val": _xp_drop()})
						_kills += 1
						_enemies.remove_at(i)

	# ── Regen ─────────────────────────────────────────────────────────────
	var regen_rate: float = float(_ring_bonuses.get("regen", 0.0))
	if _has_skill("regen"):
		var rdef: Dictionary = _slvl("regen", _get_skill("regen")["level"] as int)
		regen_rate += rdef["hps"] as float
	if regen_rate > 0.0:
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
			var hdef: Dictionary = _slvl("hurricane", hs["level"] as int)
			var hr: float = hdef["r"] as float
			var htick: float = (hdef["dps"] as float) * 0.5
			for i in range(_enemies.size() - 1, -1, -1):
				var ep: Vector2 = _enemies[i]["pos"] as Vector2
				if ep.distance_to(_player_pos) <= hr + (_enemies[i]["r"] as float):
					_enemies[i]["hp"] = (_enemies[i]["hp"] as float) - htick
					if (_enemies[i]["hp"] as float) <= 0.0:
						_xp_orbs.append({"pos": ep, "val": _xp_drop()})
						_kills += 1
						_enemies.remove_at(i)

	# ── Knife Storm (aura-type) ─────────────────────────────────────────────
	if _has_skill("knife_storm"):
		var ks: Dictionary = _get_skill("knife_storm")
		if not ks.has("aura_t"): ks["aura_t"] = 0.0
		ks["aura_t"] = (ks["aura_t"] as float) - delta
		if (ks["aura_t"] as float) <= 0.0:
			ks["aura_t"] = 0.5
			var kdef: Dictionary = _slvl("knife_storm", ks["level"] as int)
			var kr: float = kdef["r"] as float
			var ktick: float = (kdef["dps"] as float) * 0.5
			for i in range(_enemies.size() - 1, -1, -1):
				var ep: Vector2 = _enemies[i]["pos"] as Vector2
				if ep.distance_to(_player_pos) <= kr + (_enemies[i]["r"] as float):
					_enemies[i]["hp"] = (_enemies[i]["hp"] as float) - ktick
					if (_enemies[i]["hp"] as float) <= 0.0:
						_xp_orbs.append({"pos": ep, "val": _xp_drop()})
						_kills += 1
						_enemies.remove_at(i)

	# ── Electric Wave ─────────────────────────────────────────────────────
	if _has_skill("elec_wave"):
		var ew: Dictionary = _get_skill("elec_wave")
		ew["timer"] = (ew["timer"] as float) - delta
		if (ew["timer"] as float) <= 0.0:
			var ewdef: Dictionary = _slvl("elec_wave", ew["level"] as int)
			ew["timer"] = ewdef["cd"] as float
			_trigger_wave_kind(ewdef["r"] as float, ewdef["dmg"] as float, "elec_wave")

	# ── Screen AOE skills (blizzard / sky_fall / seven_slash) ──────────────
	for aoe_sid in ["blizzard", "sky_fall", "seven_slash", "swirl_tangerine"]:
		if _has_skill(aoe_sid):
			var ao: Dictionary = _get_skill(aoe_sid)
			ao["timer"] = (ao["timer"] as float) - delta
			if (ao["timer"] as float) <= 0.0:
				var aodef: Dictionary = _slvl(aoe_sid, ao["level"] as int)
				ao["timer"] = aodef["cd"] as float
				var slow_val: float = aodef.get("slow", 0.0) as float
				_trigger_aoe(aoe_sid, aodef["dmg"] as float, slow_val)
func _check_orb_hits() -> void:
	if _has_skill("orb"):
		var orb_def: Dictionary = _slvl("orb", _get_skill("orb")["level"] as int)
		var n: int     = orb_def["orbs"] as int
		var dmg: float = orb_def["dmg"] as float
		for i in n:
			var ang: float  = _orb_angle + float(i) * TAU / float(n)
			var op: Vector2 = _player_pos + Vector2(cos(ang), sin(ang)) * ORB_ORBIT_R
			for j in range(_enemies.size() - 1, -1, -1):
				if (_enemies[j]["iframes"] as float) > 0.0:
					continue
				if op.distance_to(_enemies[j]["pos"] as Vector2) < ORB_R + (_enemies[j]["r"] as float):
					_hit_enemy(j, dmg)
					break

func _fire_bolts(n: int, dmg: float, spd: float, kind: String = "bolt") -> void:
	if _enemies.is_empty():
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
		if best_j < 0:
			break
		checked.append(best_j)
		var dir: Vector2 = ((_enemies[best_j]["pos"] as Vector2) - _player_pos).normalized()
		_bolts.append({"pos": _player_pos, "vel": dir * spd, "dmg": dmg, "life": BOLT_LIFE, "kind": kind})

func _trigger_wave_kind(r: float, dmg: float, kind: String = "wave") -> void:
	var vp: Rect2 = get_viewport_rect()
	for i in range(_enemies.size() - 1, -1, -1):
		var ep: Vector2 = _enemies[i]["pos"] as Vector2
		var sp: Vector2 = ep - _camera.position + vp.size * 0.5
		if not vp.grow(60.0).has_point(sp): continue
		if ep.distance_to(_player_pos) <= r:
			_hit_enemy(i, dmg)
	_waves.append({"pos": _player_pos, "r": 0.0, "max_r": r, "life": 0.55, "max_life": 0.55, "kind": kind})

func _trigger_aoe(kind: String, dmg: float, slow: float) -> void:
	var vp: Rect2 = get_viewport_rect()
	for i in range(_enemies.size() - 1, -1, -1):
		var ep: Vector2 = (_enemies[i]["pos"] as Vector2)
		var sp: Vector2 = ep - _camera.position + vp.size * 0.5
		if not vp.grow(40.0).has_point(sp): continue
		_hit_enemy(i, dmg)
		if slow > 0.0 and i < _enemies.size():
			_enemies[i]["spd"] = max((_enemies[i]["spd"] as float) * (1.0 - slow), 8.0)
	_aoe_flashes.append({"life": 1.4, "max_life": 1.4, "kind": kind})

# ═════════════════════════════════════════════════════════════════════════════
# ENTITY UPDATES
# ═════════════════════════════════════════════════════════════════════════════

func _update_enemies(delta: float) -> void:
	for i in range(_enemies.size() - 1, -1, -1):
		var e: Dictionary = _enemies[i]
		if (e["iframes"] as float) > 0.0:
			e["iframes"] = (e["iframes"] as float) - delta
		# Enrage: after 8 s alive, normal enemies sprint at 1.8× base speed (bosses excluded)
		var ekind_upd: String = e.get("kind", "normal") as String
		var is_boss_kind: bool = ekind_upd.ends_with("_boss")
		e["alive_t"] = (e["alive_t"] as float) + delta
		if not is_boss_kind and (e["alive_t"] as float) >= 8.0:
			e["spd"] = (e["base_spd"] as float) * 1.8
		var ep: Vector2 = e["pos"] as Vector2
		var _emove_dir: Vector2 = (_player_pos - ep).normalized()
		e["pos"] = ep + _emove_dir * (e["spd"] as float) * delta
		if abs(_emove_dir.x) > 0.05:
			e["facing_x"] = 1 if _emove_dir.x > 0.0 else -1
		if _player_iframes <= 0.0:
			if (_enemies[i]["pos"] as Vector2).distance_to(_player_pos) < PLAYER_R + (e["r"] as float):
				_player_hp      -= e["dmg"] as float
				_player_iframes  = IFRAMES_SEC
				if _player_hp <= 0.0:
					_player_hp = 0.0
					_on_death()
					return

		# ── Boss special behaviors ──────────────────────────────────
		var ekind: String = e.get("kind", "normal") as String
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
				e["special_timer"] = 0.0
				var dir: Vector2 = (_player_pos - (e["pos"] as Vector2)).normalized()
				_boss_projs.append({"pos": e["pos"] as Vector2, "vel": dir * 260.0,
					"dmg": e["dmg"] as float * 0.8, "life": 4.5})
		elif ekind == "lava_boss":
			e["special_timer"] = (e["special_timer"] as float) + delta
			if (e["special_timer"] as float) >= 3.0:
				e["special_timer"] = 0.0
				var lp: Vector2 = e["pos"] as Vector2 + Vector2(randf_range(-60, 60), randf_range(-60, 60))
				_lava_pools.append({"pos": lp, "r": 44.0, "life": 6.0, "max_life": 6.0,
					"dmg_per_tick": (e["dmg"] as float) * 0.4, "tick_t": 0.0})

func _update_bolts(delta: float) -> void:
	var vp: Rect2 = get_viewport_rect()
	for i in range(_bolts.size() - 1, -1, -1):
		var b: Dictionary = _bolts[i]
		b["pos"]  = (b["pos"] as Vector2) + (b["vel"] as Vector2) * delta
		b["life"] = (b["life"] as float) - delta
		var bp: Vector2 = b["pos"] as Vector2
		var sp: Vector2 = bp - _camera.position + vp.size * 0.5
		if (b["life"] as float) <= 0.0 or not vp.grow(30.0).has_point(sp):
			_bolts.remove_at(i)
			continue
		var hit: bool = false
		for j in range(_enemies.size() - 1, -1, -1):
			if bp.distance_to(_enemies[j]["pos"] as Vector2) < BOLT_R + (_enemies[j]["r"] as float):
				_hit_enemy(j, b["dmg"] as float)
				hit = true
				break
		if hit:
			_bolts.remove_at(i)

func _update_waves(delta: float) -> void:
	for i in range(_waves.size() - 1, -1, -1):
		var w: Dictionary = _waves[i]
		var expand: float = (w["max_r"] as float) / (w["max_life"] as float) * delta
		w["r"]    = (w["r"] as float) + expand
		w["life"] = (w["life"] as float) - delta
		if (w["life"] as float) <= 0.0:
			_waves.remove_at(i)

func _fire_ice_orbs(n: int, dmg: float, spd: float, freeze_r: float, slow: float, lvl: int) -> void:
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
		_ice_orbs.append({"pos": _player_pos, "vel": dir * spd, "dmg": dmg,
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
					_enemies[j]["spd"] = max((_enemies[j]["spd"] as float) * (1.0 - slow * delta), 8.0)

func _fire_split_arrows(n: int, dmg: float, spd: float, spread: float) -> void:
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
		_bolts.append({"pos": _player_pos, "vel": dir * spd, "dmg": dmg, "life": BOLT_LIFE, "kind": "split_arrow"})

func _fire_pierce_arrows(n: int, dmg: float, spd: float) -> void:
	if _enemies.is_empty():
		for i in n:
			var dir: Vector2 = Vector2(1, 0).rotated(_orb_angle + float(i) / float(n) * TAU)
			_pierce_arrows.append({"pos": _player_pos, "vel": dir * spd, "dmg": dmg, "life": ICE_ORB_LIFE})
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
		_pierce_arrows.append({"pos": _player_pos, "vel": dir * spd, "dmg": dmg, "life": ICE_ORB_LIFE})

func _fire_boomerangs(n: int, dmg: float, spd: float) -> void:
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
				"dmg": dmg, "life": life_dur, "max_life": life_dur, "returning": false})

func _fire_fireball(n: int, dmg: float, spd: float) -> void:
	if _enemies.is_empty():
		# No enemies — spread in evenly spaced directions
		for i in n:
			var dir: Vector2 = Vector2(1, 0).rotated(float(i) / float(n) * TAU)
			_fireballs.append({"pos": _player_pos, "vel": dir * spd,
				"dmg": dmg, "trail_dmg": dmg * 0.18, "life": 4.0})
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
				"dmg": dmg, "trail_dmg": dmg * 0.18, "life": 4.0})
		else:
			var dir: Vector2 = Vector2(1, 0).rotated(float(_i) / float(n) * TAU)
			_fireballs.append({"pos": _player_pos, "vel": dir * spd,
				"dmg": dmg, "trail_dmg": dmg * 0.18, "life": 4.0})

func _update_fireballs(delta: float) -> void:
	var vp: Rect2 = get_viewport_rect()
	# Advance fireballs, spawn trail segments, check direct hit
	for i in range(_fireballs.size() - 1, -1, -1):
		var fb: Dictionary = _fireballs[i]
		var old_pos: Vector2 = fb["pos"] as Vector2
		fb["pos"]  = old_pos + (fb["vel"] as Vector2) * delta
		fb["life"] = (fb["life"] as float) - delta
		var fbp: Vector2 = fb["pos"] as Vector2
		var sp: Vector2  = fbp - _camera.position + vp.size * 0.5
		if (fb["life"] as float) <= 0.0 or not vp.grow(30.0).has_point(sp):
			_fireballs.remove_at(i)
			continue
		# Spawn a trail segment every ~50 px — fewer segments for performance
		if not fb.has("trail_acc"): fb["trail_acc"] = 0.0
		fb["trail_acc"] = (fb["trail_acc"] as float) + (fb["vel"] as Vector2).length() * delta
		if (fb["trail_acc"] as float) >= 50.0 and _fire_trails.size() < 40:
			fb["trail_acc"] = 0.0
			_fire_trails.append({
				"pos": old_pos,
				"life": 1.8, "max_life": 1.8,
				"dmg_per_tick": fb["trail_dmg"] as float,
				"tick_t": 0.0,
				"r": 16.0
			})
		# Direct hit check
		for j in range(_enemies.size() - 1, -1, -1):
			if (_enemies[j]["iframes"] as float) > 0.0: continue
			if fbp.distance_to(_enemies[j]["pos"] as Vector2) < 10.0 + (_enemies[j]["r"] as float):
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
		b["pos"]  = (b["pos"] as Vector2) + (b["vel"] as Vector2) * delta
		b["life"] = (b["life"] as float) - delta
		var bp: Vector2 = b["pos"] as Vector2
		var sp: Vector2 = bp - _camera.position + vp.size * 0.5
		if (b["life"] as float) <= 0.0 or not vp.grow(30.0).has_point(sp):
			_pierce_arrows.remove_at(i)
			continue
		for j in range(_enemies.size() - 1, -1, -1):
			if (_enemies[j]["iframes"] as float) > 0.0: continue
			if bp.distance_to(_enemies[j]["pos"] as Vector2) < BOLT_R + (_enemies[j]["r"] as float):
				_hit_enemy(j, b["dmg"] as float)

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
	if _has_skill("magnet"):
		cr = (_slvl("magnet", _get_skill("magnet")["level"] as int))["rng"] as float
	for i in range(_xp_orbs.size() - 1, -1, -1):
		var orb: Dictionary = _xp_orbs[i]
		var op: Vector2     = orb["pos"] as Vector2
		var d: float        = op.distance_to(_player_pos)
		if d < cr:
			orb["pos"] = op.move_toward(_player_pos, 320.0 * delta)
		if d < 20.0:
			_gain_xp(orb["val"] as int)
			_xp_orbs.remove_at(i)

const MAX_ENEMIES: int = 150

# ─────────────────────────────────────────────────────────────────────────────
# WAVE SYSTEM
# ─────────────────────────────────────────────────────────────────────────────

func _update_spawner(delta: float) -> void:
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

	# Boss wave every 5th — cycle through all 4 boss types in order
	if w % 5 == 0:
		var boss_types := ["teleporter_boss", "shield_boss", "shooter_boss", "lava_boss"]
		var boss_idx: int = (w / 5 - 1) % boss_types.size()
		var btype: String = boss_types[boss_idx]
		# Every 10th wave: full-strength boss; every 5th (not 10th): 65% strength
		var boss_ws: float = ws if (w % 10 == 0) else ws * 0.65
		_wave_spawn_q.append(_make_enemy_data(btype, boss_ws))
		# Pack of normals grows with wave
		var pack: int = mini(12 + w / 2, 40)
		for _i in pack:
			_wave_spawn_q.append(_make_enemy_data("normal", ws))
	else:
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

func _make_enemy_data(kind: String, ws: float) -> Dictionary:
	match kind:
		"teleporter_boss":
			return {
				"kind": "teleporter_boss",
				"hp_mult": 14.0 * ws, "spd_fixed": 130.0, "dmg_mult": 1.5 * ws,
				"r": 36.0, "col": Color(0.55, 0.10, 0.82)
			}
		"shield_boss":
			return {
				"kind": "shield_boss",
				"hp_mult": 30.0 * ws, "spd_fixed": 75.0, "dmg_mult": 2.0 * ws,
				"r": 46.0, "col": Color(0.20, 0.55, 0.90)
			}
		"shooter_boss":
			return {
				"kind": "shooter_boss",
				"hp_mult": 20.0 * ws, "spd_fixed": 60.0, "dmg_mult": 1.2 * ws,
				"r": 40.0, "col": Color(0.85, 0.55, 0.05)
			}
		"lava_boss":
			return {
				"kind": "lava_boss",
				"hp_mult": 35.0 * ws, "spd_fixed": 50.0, "dmg_mult": 1.8 * ws,
				"r": 52.0, "col": Color(0.90, 0.25, 0.02)
			}
		# ── Normal subtypes ───────────────────────────────────────────────────
		"normal_tank":  # Slow, bulky, high damage
			return {
				"kind": "normal_tank",
				"hp_mult": ws * 2.8, "spd_mult": 0.52, "dmg_mult": ws * 1.6,
				"r": randf_range(22.0, 28.0),
				"col": Color.from_hsv(0.06, 0.85, 0.45 + randf() * 0.15)  # dark orange-brown
			}
		"normal_fast":  # Fast, fragile, low damage
			return {
				"kind": "normal_fast",
				"hp_mult": ws * 0.45, "spd_mult": 1.70, "dmg_mult": ws * 0.65,
				"r": randf_range(10.0, 15.0),
				"col": Color.from_hsv(0.55, 0.70, 0.80 + randf() * 0.20)  # bright cyan-blue
			}
		_:  # normal — balanced
			return {
				"kind": "normal",
				"hp_mult": ws, "spd_mult": 1.0, "dmg_mult": ws,
				"r": randf_range(16.0, 22.0),
				"col": Color.from_hsv(randf_range(0.0, 0.12), 0.8, 0.35 + randf() * 0.2)
			}

func _spawn_enemy_from(data: Dictionary) -> void:
	var view: Vector2 = get_viewport_rect().size
	var sr: float     = max(view.x, view.y) * 0.62 + 60.0
	var angle: float  = randf() * TAU
	var pos: Vector2  = _player_pos + Vector2(cos(angle), sin(angle)) * sr
	var base_hp: float  = (18.0 + float(_level) * 5.0) * (data["hp_mult"] as float)
	# Bosses use a fixed absolute speed; normals scale gently with wave
	var base_spd: float
	if data.has("spd_fixed"):
		base_spd = data["spd_fixed"] as float
	else:
		var wave_bonus: float = float(_wave) * 2.5   # +2.5 px/s per wave (gentle)
		base_spd = (randf_range(72.0, 105.0) + wave_bonus) * (data["spd_mult"] as float)
	var base_dmg: float = (4.5 + float(_level) * 1.0) * (data["dmg_mult"] as float)
	_enemies.append({
		"pos": pos, "hp": base_hp, "max_hp": base_hp,
		"spd": base_spd, "base_spd": base_spd, "r": data["r"] as float,
		"dmg": base_dmg, "col": data["col"] as Color,
		"iframes": 0.0, "kind": data["kind"] as String,
		"alive_t": 0.0, "facing_x": 1,
		"special_timer": 0.0, "shield_active": false
	})

func _hit_enemy(idx: int, dmg: float) -> void:
	if idx < 0 or idx >= _enemies.size():
		return
	var e: Dictionary = _enemies[idx]
	# Shield boss is immune while shield is active
	if (e["shield_active"] as bool):
		return
	# Apply crit from ring bonus
	var final_dmg: float = dmg
	var crit_chance: float = float(_ring_bonuses.get("crit_chance", 0.0))
	if crit_chance > 0.0 and randf() < crit_chance:
		final_dmg *= 1.8
	e["hp"]      = (e["hp"] as float) - final_dmg
	e["iframes"] = ENEMY_HIT_IF
	if (e["hp"] as float) <= 0.0:
		var ep: Vector2   = e["pos"] as Vector2
		var ekind: String = e.get("kind", "normal") as String
		_xp_orbs.append({"pos": ep, "val": _xp_drop()})
		_kills += 1
		var is_boss: bool = ekind.ends_with("_boss")
		# Potion drop: 10% base + ring bonus, from any boss
		var potion_rate: float = 0.10 + float(_ring_bonuses.get("potion_drop_rate", 0.0))
		if is_boss and randf() < potion_rate:
			_potions.append({"pos": ep + Vector2(randf_range(-20, 20), randf_range(-20, 20)), "life": 15.0})
		# Ring drop: 15% base + ring bonus, only heavy bosses (shooter/lava/shield)
		var ring_rate: float = 0.15 + float(_ring_bonuses.get("ring_drop_rate", 0.0))
		if ekind in ["shield_boss", "shooter_boss", "lava_boss"] and randf() < ring_rate:
			var ring: Dictionary = RingStore.roll_ring()
			_ring_drops.append({"pos": ep + Vector2(randf_range(-30, 30), randf_range(-30, 30)), "life": 20.0, "ring": ring})
		_enemies.remove_at(idx)

func _update_potions(delta: float) -> void:
	for i in range(_potions.size() - 1, -1, -1):
		var p: Dictionary = _potions[i]
		p["life"] = (p["life"] as float) - delta
		if (p["life"] as float) <= 0.0:
			_potions.remove_at(i)
			continue
		if (_player_pos.distance_to(p["pos"] as Vector2)) < 28.0:
			# Heal 25% of max HP
			_player_hp = min(_player_hp + _player_max_hp * 0.25, _player_max_hp)
			_potions.remove_at(i)

func _update_ring_drops(delta: float) -> void:
	for i in range(_ring_drops.size() - 1, -1, -1):
		var rd: Dictionary = _ring_drops[i]
		rd["life"] = (rd["life"] as float) - delta
		if (rd["life"] as float) <= 0.0:
			_ring_drops.remove_at(i)
			continue
		if (_player_pos.distance_to(rd["pos"] as Vector2)) < 32.0:
			RingStore.add_ring_to_stash(account_username, rd["ring"] as Dictionary)
			_ring_drops.remove_at(i)

func _update_boss_projs(delta: float) -> void:
	var vp: Rect2 = get_viewport_rect()
	for i in range(_boss_projs.size() - 1, -1, -1):
		var bp: Dictionary = _boss_projs[i]
		bp["pos"]  = (bp["pos"] as Vector2) + (bp["vel"] as Vector2) * delta
		bp["life"] = (bp["life"] as float) - delta
		var bpp: Vector2 = bp["pos"] as Vector2
		var sp: Vector2  = bpp - _camera.position + vp.size * 0.5
		if (bp["life"] as float) <= 0.0 or not vp.grow(40.0).has_point(sp):
			_boss_projs.remove_at(i)
			continue
		# Damage player if they touch it
		if _player_iframes <= 0.0 and bpp.distance_to(_player_pos) < PLAYER_R + 12.0:
			_player_hp      -= bp["dmg"] as float
			_player_iframes  = IFRAMES_SEC
			if _player_hp <= 0.0:
				_player_hp = 0.0
				_on_death()
				return
			_boss_projs.remove_at(i)

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
				_player_hp      -= lp["dmg_per_tick"] as float
				_player_iframes  = 0.4
				if _player_hp <= 0.0:
					_player_hp = 0.0
					_on_death()
					return

func _xp_drop() -> int:
	return 4 + _wave

func _gain_xp(amount: int) -> void:
	var xp_mult: float = 1.0 + float(_ring_bonuses.get("xp_bonus", 0.0))
	_xp += int(float(amount) * xp_mult)
	if _xp >= _xp_next:
		_xp -= _xp_next
		_level   += 1
		_xp_next  = int(50.0 * pow(float(_level), 1.65))
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

	# Hurricane aura — small tornados forming and disappearing
	if _has_skill("hurricane"):
		var hs_sk: Dictionary = _get_skill("hurricane")
		var hdef: Dictionary  = _slvl("hurricane", hs_sk["level"] as int)
		var hr: float = hdef["r"] as float
		var hlv: int  = hs_sk["level"] as int
		# Faint boundary ring
		draw_arc(_player_pos, hr, 0.0, TAU, 48, Color(0.60, 0.88, 0.96, 0.18 + float(hlv) * 0.03), 2.0)
		# Draw several mini-tornados scattered in the area
		var n_tornados: int = 3 + hlv
		for i in n_tornados:
			# Each tornado has its own slow orbit + life cycle (form → peak → fade)
			var torbit_speed: float = 0.45 + float(i) * 0.12
			var torbit_ang: float   = float(i) * TAU / float(n_tornados) + _elapsed * torbit_speed
			var torbit_dist: float  = hr * (0.30 + 0.55 * float(i % 3) / 2.0)
			var tpos: Vector2       = _player_pos + Vector2(cos(torbit_ang), sin(torbit_ang)) * torbit_dist
			# Life pulse: each tornado phases in/out on its own period
			var tperiod: float  = 1.4 + float(i) * 0.3
			var tphase: float   = fmod(_elapsed + float(i) * tperiod * 0.6, tperiod) / tperiod
			# Alpha: fade in for first 30%, full for middle 40%, fade out last 30%
			var talpha: float
			if tphase < 0.3:
				talpha = tphase / 0.3
			elif tphase < 0.7:
				talpha = 1.0
			else:
				talpha = (1.0 - tphase) / 0.3
			talpha *= (0.55 + float(hlv) * 0.06)
			# Tornado scale grows with life
			var tscale: float = 8.0 + float(hlv) * 3.0 + tphase * 6.0
			# Draw tornado as stacked ellipse-arcs narrowing toward top (3 rings)
			var n_rings: int = 4 + hlv
			for r in n_rings:
				var rheight: float    = float(r) / float(n_rings)
				var ring_rx: float    = tscale * (1.0 - rheight * 0.75)  # narrows toward top
				var ring_ry: float    = ring_rx * 0.38
				var ring_y: float     = -rheight * tscale * 2.2           # stacked upward
				var ring_rot: float   = _elapsed * (3.5 + float(hlv) * 0.5) + float(r) * 0.9
				var ring_alpha: float = talpha * (0.35 + rheight * 0.45)
				var ring_col: Color   = Color(0.72, 0.94, 0.99, ring_alpha)
				# Approximate an ellipse arc as polyline
				var ellpts: PackedVector2Array = PackedVector2Array()
				var ell_segs: int = 14
				for s in ell_segs + 1:
					var sa: float = float(s) / float(ell_segs) * TAU + ring_rot
					var ex: float = cos(sa) * ring_rx
					var ey: float = sin(sa) * ring_ry
					# Rotate ex/ey slightly with ring_rot for spin feel
					ellpts.append(tpos + Vector2(ex, ey + ring_y))
				draw_polyline(ellpts, ring_col, 1.5)
			# Dusty base swirl at the bottom
			draw_circle(tpos, tscale * 0.55 + sin(_elapsed * 6.0 + float(i)) * 2.0, Color(0.80, 0.96, 1.0, talpha * 0.30))

	# Knife Storm aura — spinning blades
	if _has_skill("knife_storm"):
		var ks_sk: Dictionary = _get_skill("knife_storm")
		var kdef: Dictionary  = _slvl("knife_storm", ks_sk["level"] as int)
		var kr: float = kdef["r"] as float
		var klv: int  = ks_sk["level"] as int
		# Scattered cross slashes that flicker in and out
		var n_crosses: int = 5 + klv * 2
		for i in n_crosses:
			var seed_t: float  = _elapsed * 2.2 + float(i) * 1.618
			# Each cross has an independent life cycle (appear/fade) driven by sin
			var life: float    = 0.5 + 0.5 * sin(seed_t * (1.3 + float(i) * 0.17))
			if life < 0.12:
				continue  # invisible this frame — gives flicker effect
			var alpha: float   = life * 0.88
			# Random position within the aura radius, unique per cross per cycle
			var angle: float   = float(i) * 2.399963 + _elapsed * (0.8 + float(i % 3) * 0.35)
			var dist: float    = kr * (0.25 + 0.70 * fmod(float(i) * 0.618 + _elapsed * 0.15, 1.0))
			var cp: Vector2    = _player_pos + Vector2(cos(angle), sin(angle)) * dist
			# Rotation of the cross itself
			var rot: float     = _elapsed * (1.4 + float(i % 4) * 0.6) + float(i) * 0.8
			var arm: float     = 10.0 + float(klv) * 1.8
			var col1: Color    = Color(0.86, 0.82, 0.98, alpha)
			var col2: Color    = Color(1.0, 0.95, 1.0, alpha * 0.70)
			# Draw X (two diagonal lines)
			var d1: Vector2 = Vector2(cos(rot), sin(rot)) * arm
			var d2: Vector2 = Vector2(cos(rot + PI * 0.5), sin(rot + PI * 0.5)) * arm
			draw_line(cp - d1, cp + d1, col1, 2.2)
			draw_line(cp - d2, cp + d2, col1, 2.2)
			# Second thinner cross rotated 45° for a star shape
			var d3: Vector2 = Vector2(cos(rot + PI * 0.25), sin(rot + PI * 0.25)) * (arm * 0.65)
			var d4: Vector2 = Vector2(cos(rot + PI * 0.75), sin(rot + PI * 0.75)) * (arm * 0.65)
			draw_line(cp - d3, cp + d3, col2, 1.4)
			draw_line(cp - d4, cp + d4, col2, 1.4)
			# Bright centre dot
			draw_circle(cp, 2.0 + life * 2.0, Color(1.0, 1.0, 1.0, alpha * 0.90))
		draw_arc(_player_pos, kr, 0.0, TAU, 24, Color(0.78, 0.74, 0.88, 0.14 + float(klv) * 0.03), 1.8)

	# Wave rings — kind-aware
	for w in _waves:
		var lf: float    = (w["life"] as float) / (w["max_life"] as float)
		var wr: float    = w["r"] as float
		var wp: Vector2  = w["pos"] as Vector2
		var wkind: String = w.get("kind", "wave") as String
		if wkind == "elec_wave":
			var ewlv: int = 1
			if _has_skill("elec_wave"): ewlv = _get_skill("elec_wave")["level"] as int
			draw_arc(wp, wr, 0.0, TAU, 72, Color(0.92, 0.98, 0.18, lf * 0.90), (5.0 + float(ewlv) * 0.6) * lf)
			if wr > 14.0:
				draw_arc(wp, wr - 12.0, 0.0, TAU, 56, Color(1.0, 1.0, 0.65, lf * 0.50), 3.0 * lf)
			var n_arcs: int = 6 + ewlv * 2
			for i in n_arcs:
				var ea: float    = float(i) / float(n_arcs) * TAU
				var emid: Vector2 = wp + Vector2(cos(ea + 0.12), sin(ea + 0.12)) * (wr + sin(float(i) * 1.9 + lf * 22.0) * 12.0)
				var eend: Vector2 = wp + Vector2(cos(ea + 0.22), sin(ea + 0.22)) * (wr + 22.0 * lf)
				draw_line(wp + Vector2(cos(ea), sin(ea)) * (wr - 6.0), emid, Color(1.0, 1.0, 0.50, lf * 0.65), 1.8)
				draw_line(emid, eend, Color(0.85, 0.95, 0.20, lf * 0.40), 1.2)
		else:
			var wlv: int = 1
			if _has_skill("wave"): wlv = _get_skill("wave")["level"] as int
			draw_arc(wp, wr, 0.0, TAU, 72, Color(0.72, 0.46, 1.0, lf * 0.88), (4.5 + float(wlv) * 0.8) * lf)
			var n_rings: int = min(wlv + 1, 5)
			for ri in n_rings:
				var ring_offset: float = float(ri + 1) * 15.0
				if wr > ring_offset:
					var ring_alpha: float = lf * (0.50 - float(ri) * 0.08)
					var ring_c: Color
					if ri == 0:   ring_c = Color(0.50, 0.72, 1.0, ring_alpha)
					elif ri == 1: ring_c = Color(0.88, 0.94, 1.0, ring_alpha * 0.6)
					else:         ring_c = Color(0.80, 0.55, 1.0, ring_alpha * 0.4)
					draw_arc(wp, wr - ring_offset, 0.0, TAU, 48 - ri * 6, ring_c, (3.0 - float(ri) * 0.4) * lf)
			var n_foam: int = 16 + wlv * 5
			for i in n_foam:
				var fa: float      = float(i) / float(n_foam) * TAU
				var foffset: float = sin(float(i) * 2.1 + lf * TAU) * (4.0 + float(wlv) * 1.5)
				var fpos: Vector2  = wp + Vector2(cos(fa), sin(fa)) * (wr + foffset)
				draw_circle(fpos, (2.0 + float(wlv) * 0.4) * lf, Color(0.92, 0.96, 1.0, lf * 0.75))
			if wlv >= 4 and wr > 30.0:
				for i in 10:
					var spa: float   = float(i) / 10.0 * TAU + lf * 0.5
					var sp1: Vector2 = wp + Vector2(cos(spa), sin(spa)) * (wr - 8.0)
					var sp2: Vector2 = sp1 + Vector2(cos(spa), sin(spa)) * (18.0 + float(wlv) * 4.0) * lf
					draw_line(sp1, sp2, Color(0.78, 0.92, 1.0, lf * 0.55), 1.8)

	# Enemies
	for e in _enemies:
		var ep: Vector2    = e["pos"] as Vector2
		var er: float      = e["r"] as float
		var ec: Color      = e["col"] as Color
		var ekind: String  = e.get("kind", "normal") as String
		var efrozen: bool  = (e["iframes"] as float) > 0.0 and _has_skill("ice_orb")
		var enraged: bool  = (e["alive_t"] as float) >= 8.0
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
		# Draw PNG sprite for normal enemy types, fallback circle for bosses
		var e_has_tex: bool = not e_is_boss and _enemy_tex.has(ekind)
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
			draw_arc(edp, er + 4.0, 0.0, TAU, 20, Color(1.0, 0.10, 0.05, pulse), 2.5)		# Boss visual indicators
		match ekind:
			"teleporter_boss":
				# Purple trail arcs (teleport aura)
				draw_arc(edp, er + 5.0, 0.0, TAU, 24, Color(0.70, 0.15, 1.0, 0.75), 3.0)
				var ta: float = _elapsed * 4.0
				for ti in 3:
					var tang: float = ta + float(ti) * TAU / 3.0
					draw_circle(edp + Vector2(cos(tang), sin(tang)) * (er + 10.0), 5.0, Color(0.80, 0.30, 1.0, 0.70))
				draw_string(ThemeDB.fallback_font, edp + Vector2(-18, -er - 18), "WARP", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.75, 0.35, 1.0))
			"shield_boss":
				var shield_on: bool = e["shield_active"] as bool
				if shield_on:
					draw_arc(edp, er + 8.0, 0.0, TAU, 32, Color(0.90, 0.90, 1.0, 0.90), 5.0)
					draw_circle(edp, er + 8.0, Color(0.80, 0.88, 1.0, 0.18))
					draw_string(ThemeDB.fallback_font, edp + Vector2(-22, -er - 22), "SHIELD", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 0.92, 1.0))
				else:
					draw_arc(edp, er + 5.0, 0.0, TAU, 24, Color(0.20, 0.55, 0.95, 0.65), 2.5)
					draw_string(ThemeDB.fallback_font, edp + Vector2(-20, -er - 18), "GUARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.30, 0.65, 1.0))
			"shooter_boss":
				# Orange aim lines toward player
				draw_arc(edp, er + 5.0, 0.0, TAU, 24, Color(1.0, 0.60, 0.05, 0.70), 2.5)
				var aim_dir: Vector2 = (_player_pos - edp).normalized()
				draw_line(edp, edp + aim_dir * (er + 20.0), Color(1.0, 0.50, 0.02, 0.55), 2.5)
				draw_string(ThemeDB.fallback_font, edp + Vector2(-20, -er - 18), "SHOOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.60, 0.10))
			"lava_boss":
				draw_arc(edp, er + 6.0, 0.0, TAU, 28, Color(1.0, 0.20, 0.02, 0.80), 4.0)
				var la: float = _elapsed * 2.5
				for li in 4:
					var lang: float = la + float(li) * TAU / 4.0
					draw_circle(edp + Vector2(cos(lang), sin(lang)) * (er + 12.0), 6.0, Color(1.0, 0.40, 0.02, 0.75))
				draw_string(ThemeDB.fallback_font, edp + Vector2(-16, -er - 22), "LAVA", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.22, 0.02))
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

	# Lava pools
	for lp in _lava_pools:
		var lpp: Vector2  = lp["pos"] as Vector2
		var lplf: float   = (lp["life"] as float) / (lp["max_life"] as float)
		var lpr: float    = lp["r"] as float
		draw_circle(lpp, lpr * 1.2, Color(0.95, 0.18, 0.01, lplf * 0.35))
		draw_circle(lpp, lpr, Color(1.0, 0.35, 0.02, lplf * 0.60))
		draw_circle(lpp, lpr * 0.55, Color(1.0, 0.72, 0.10, lplf * 0.75))
		# Bubbling dots
		for li in 3:
			var ba: float = _elapsed * 3.0 + float(li) * TAU / 3.0
			draw_circle(lpp + Vector2(cos(ba), sin(ba)) * lpr * 0.5, 5.0, Color(1.0, 0.90, 0.20, lplf * 0.80))

	# Boss projectiles
	for bproj in _boss_projs:
		var bpp: Vector2 = bproj["pos"] as Vector2
		draw_circle(bpp, 12.0, Color(1.0, 0.55, 0.05, 0.85))
		draw_circle(bpp, 7.0, Color(1.0, 0.90, 0.30))
		draw_arc(bpp, 14.0, 0.0, TAU, 16, Color(1.0, 0.35, 0.02, 0.55), 2.0)

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

	# Orbs
	if _has_skill("orb"):
		var od: Dictionary = _slvl("orb", _get_skill("orb")["level"] as int)
		var n: int = od["orbs"] as int
		for i in n:
			var ang: float  = _orb_angle + float(i) * TAU / float(n)
			var op: Vector2 = _player_pos + Vector2(cos(ang), sin(ang)) * ORB_ORBIT_R
			draw_circle(op, ORB_R, Color(0.98, 0.72, 0.08))
			draw_arc(op, ORB_R, 0.0, TAU, 16, Color(1.0, 0.9, 0.4, 0.7), 2.0)

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
	for b in _bolts:
		var bp: Vector2   = b["pos"] as Vector2
		var bv: Vector2   = (b["vel"] as Vector2).normalized()
		var perp: Vector2 = Vector2(-bv.y, bv.x)
		var bkind: String = b.get("kind", "bolt") as String
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
		var tail: Vector2 = bp - bv * 34.0
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
	# Legs drawn behind body
	var p_leg_col: Color = _player_tint.darkened(0.28)
	draw_circle(pdp + Vector2(-9.0, PLAYER_R * 0.52 + p_leg_l), 5.5, p_leg_col)
	draw_circle(pdp + Vector2( 9.0, PLAYER_R * 0.52 + p_leg_r), 5.5, p_leg_col)
	# Shadow
	draw_circle(_player_pos + Vector2(3, 6), PLAYER_R - 3.0, Color(0, 0, 0, 0.20))
	# Player — portrait sprite or fallback circles
	const SPRITE_SIZE: float = 72.0
	if _player_tex != null:
		draw_set_transform(pdp, 0.0, Vector2(float(_player_facing_x), 1.0))
		draw_texture_rect(_player_tex, Rect2(Vector2(-SPRITE_SIZE * 0.5, -SPRITE_SIZE * 0.5), Vector2(SPRITE_SIZE, SPRITE_SIZE)), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_circle(pdp, PLAYER_R, _player_tint)
		draw_arc(pdp, PLAYER_R, 0.0, TAU, 32, Color(1, 1, 1, 0.65), 3.0)
		# Eyes shifted toward facing direction
		var p_eye_ox: float = 4.5 * float(_player_facing_x)
		draw_circle(pdp + Vector2(p_eye_ox - 5.0, -6.0), 6.0, Color(1, 1, 1, 0.92))
		draw_circle(pdp + Vector2(p_eye_ox + 5.0, -6.0), 6.0, Color(1, 1, 1, 0.92))
		draw_circle(pdp + Vector2(p_eye_ox - 5.0, -6.0), 3.0, Color(0.1, 0.05, 0.0))
		draw_circle(pdp + Vector2(p_eye_ox + 5.0, -6.0), 3.0, Color(0.1, 0.05, 0.0))
	# Iframes flash
	if _player_iframes > 0.0 and fmod(_player_iframes, 0.12) > 0.06:
		draw_circle(pdp, PLAYER_R + 5.0, Color(1.0, 1.0, 1.0, 0.35))

func _draw_bg() -> void:
	var view: Vector2 = get_viewport_rect().size
	var hw: float     = view.x * 0.5 + 128.0
	var hh: float     = view.y * 0.5 + 128.0
	var cx: float     = _player_pos.x
	var cy: float     = _player_pos.y
	draw_rect(Rect2(cx - hw, cy - hh, hw * 2.0, hh * 2.0), Color(0.14, 0.11, 0.08))
	const TILE: float = 100.0
	var xl: float = floor((cx - hw) / TILE) * TILE
	var yl: float = floor((cy - hh) / TILE) * TILE
	var x: float = xl
	while x <= cx + hw:
		draw_line(Vector2(x, cy - hh), Vector2(x, cy + hh), Color(0.38, 0.30, 0.20, 0.07), 1.0)
		x += TILE
	var y: float = yl
	while y <= cy + hh:
		draw_line(Vector2(cx - hw, y), Vector2(cx + hw, y), Color(0.38, 0.30, 0.20, 0.07), 1.0)
		y += TILE

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
	_level_lbl.add_theme_font_size_override("font_size", 30)
	_level_lbl.add_theme_color_override("font_color", Color(0.98, 0.88, 0.50))
	_level_lbl.position = Vector2(370, 42)
	hud.add_child(_level_lbl)

	# Time (top-right)
	_time_lbl = Label.new()
	_time_lbl.text = "0:00"
	_time_lbl.add_theme_font_size_override("font_size", 28)
	_time_lbl.add_theme_color_override("font_color", Color(0.90, 0.86, 0.76))
	_time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_time_lbl.position = Vector2(view.x - 170, 44); _time_lbl.size = Vector2(142, 40)
	hud.add_child(_time_lbl)

	# Kill count
	_kill_lbl = Label.new()
	_kill_lbl.text = "Kills: 0"
	_kill_lbl.add_theme_font_size_override("font_size", 20)
	_kill_lbl.add_theme_color_override("font_color", Color(0.75, 0.70, 0.60))
	_kill_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_kill_lbl.position = Vector2(view.x - 170, 82); _kill_lbl.size = Vector2(142, 28)
	hud.add_child(_kill_lbl)

	_wave_lbl = Label.new()
	_wave_lbl.text = "Wave 1"
	_wave_lbl.add_theme_font_size_override("font_size", 22)
	_wave_lbl.add_theme_color_override("font_color", Color(1.0, 0.80, 0.20))
	_wave_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_wave_lbl.position = Vector2(view.x - 170, 112); _wave_lbl.size = Vector2(142, 28)
	hud.add_child(_wave_lbl)

	# Skill icons row (bottom)
	_skill_icon_row = HBoxContainer.new()
	_skill_icon_row.add_theme_constant_override("separation", 10)
	_skill_icon_row.position = Vector2(28, view.y - 108)
	_skill_icon_row.size     = Vector2(view.x - 56, 88)
	hud.add_child(_skill_icon_row)

	# Joystick visual
	_joy_vis = JoystickVisual.new()
	hud.add_child(_joy_vis)

func _update_hud() -> void:
	_hp_fill.size = Vector2(324.0 * clamp(_player_hp / _player_max_hp, 0.0, 1.0), 26)
	_xp_fill.size = Vector2(326.0 * clamp(float(_xp) / float(_xp_next), 0.0, 1.0), 14)
	_level_lbl.text = "LV %d" % _level
	var m: int = int(_elapsed) / 60
	var s: int = int(_elapsed) % 60
	_time_lbl.text = "%d:%02d" % [m, s]
	_kill_lbl.text = "Kills: %d" % _kills
	if _wave_lbl != null:
		match _wave_state:
			"between":
				_wave_lbl.text = "Wave %d — Next: %.0fs" % [_wave, _between_t]
			"waiting":
				_wave_lbl.text = "Wave %d — Clear!" % _wave
			_:
				_wave_lbl.text = "Wave %d" % _wave

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
		pill.custom_minimum_size = Vector2(112, 60)
		var nl := Label.new()
		nl.text = sdef["name"] as String
		nl.add_theme_font_size_override("font_size", 14)
		nl.add_theme_color_override("font_color", sdef["col"] as Color)
		nl.position = Vector2(8, 6); nl.size = Vector2(96, 22)
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill.add_child(nl)
		var ll := Label.new()
		ll.text = "Lv %d" % lvl
		ll.add_theme_font_size_override("font_size", 13)
		ll.add_theme_color_override("font_color", Color(0.70, 0.65, 0.52))
		ll.position = Vector2(8, 32); ll.size = Vector2(96, 20)
		ll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill.add_child(ll)
		_skill_icon_row.add_child(pill)

# ═════════════════════════════════════════════════════════════════════════════
# SKILL SELECT UI
# ═════════════════════════════════════════════════════════════════════════════

func _show_skill_select(is_initial: bool) -> void:
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
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.98, 0.88, 0.50))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, view.y * 0.14); title.size = Vector2(view.x, 65)
	layer.add_child(title)

	# Level label (during level-up)
	if not is_initial:
		var lv_lbl := Label.new()
		lv_lbl.text = "Now Level %d" % _level
		lv_lbl.add_theme_font_size_override("font_size", 24)
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
		nm.add_theme_font_size_override("font_size", 34)
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
		desc.add_theme_font_size_override("font_size", 22)
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
			# Ulti handled separately — skip in normal pool until offered once
			if sid == ulti_sid and (not _ulti_unlocked or not _ulti_offered): continue
			if not _has_skill(sid) and SKILL_DEFS.has(sid):
				opts.append({"type": "new", "id": sid, "lvl": 1})

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

	# Fill remaining slots from shuffled pool (skip duplicating ulti if forced)
	for o in opts:
		if result.size() >= 3: break
		if (o["id"] as String) == ulti_sid and result.size() > 0 and (result[0]["id"] as String) == ulti_sid:
			continue
		result.append(o)

	while result.size() < 3:
		var regen_lvl: int = ((_get_skill("regen")["level"] as int) + 1) if _has_skill("regen") else 1
		result.append({"type": "upgrade", "id": "regen", "lvl": mini(regen_lvl, 3)})

	return result

func _pick_skill(sid: String, lvl: int) -> void:
	if _has_skill(sid):
		_get_skill(sid)["level"] = lvl
	else:
		var sk: Dictionary = {"id": sid, "level": 1, "timer": 0.0}
		_skills.append(sk)
	_update_skill_icons()

# ═════════════════════════════════════════════════════════════════════════════
# GAME OVER
# ═════════════════════════════════════════════════════════════════════════════

func _on_death() -> void:
	_game_over = true
	_paused    = true
	queue_redraw()

	# Record loss only when death is final (not revived)
	if not _revive_used and not account_username.is_empty() and selected_player_character != null:
		StatsStore.record_match(
			account_username,
			String(selected_player_character.id),
			StatsStore.OUTCOME_LOSS,
			0, _elapsed, 0, _kills
		)

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
	stats.text = "Survived  %d:%02d\nLevel %d  ·  %d kills" % [m, s, _level, _kills]
	stats.add_theme_font_size_override("font_size", 34)
	stats.add_theme_color_override("font_color", Color(0.88, 0.82, 0.68))
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.position = Vector2(0, view.y * 0.36); stats.size = Vector2(view.x, 110)
	layer.add_child(stats)

	# ── Revive button (only available once per gameplay, ad-gated) ───────────
	if not _revive_used:
		var revive_btn := Button.new()
		revive_btn.text = "📺  Watch Ad to Revive"
		revive_btn.add_theme_font_size_override("font_size", 30)
		revive_btn.custom_minimum_size = Vector2(440, 88)
		revive_btn.size = Vector2(440, 88)
		revive_btn.position = Vector2((view.x - 440) * 0.5, view.y * 0.56)
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
		once_lbl.text = "(one revive per run)"
		once_lbl.add_theme_font_size_override("font_size", 18)
		once_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.50))
		once_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		once_lbl.position = Vector2(0, view.y * 0.56 + 92); once_lbl.size = Vector2(view.x, 28)
		layer.add_child(once_lbl)

	var back_y: float = view.y * 0.74 if not _revive_used else view.y * 0.62
	var back := Button.new()
	back.text = "← Back to Lobby"
	back.add_theme_font_size_override("font_size", 32)
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
	_revive_used = true
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

func _slvl(sid: String, lvl: int) -> Dictionary:
	var sdef: Dictionary = SKILL_DEFS[sid] as Dictionary
	var levels: Array    = sdef["lvl"] as Array
	return levels[lvl - 1] as Dictionary
