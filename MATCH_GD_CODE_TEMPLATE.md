extends Node2D

# ─── ADD THIS SECTION AT THE TOP OF MATCH.GD (after class_name if present) ───
# Global reference for easy access (alternative to accessing via SkillMgr)
var skill_system: SkillEffectManager = null
var animation_player: AnimationPlayer = null

# ─── THEN, IN THE _ready() FUNCTION, ADD THIS AT THE END (before final }) ───

## PASTE THIS CODE AT THE END OF Match._ready():

func _ready_skill_system_init() -> void:
	"""Initialize skill system - call this from _ready()"""
	print("\n" + "="*60)
	print("INITIALIZING SKILL SYSTEM")
	print("="*60)
	
	# Get or create AnimationPlayer
	animation_player = get_node_or_null("AnimationPlayer")
	if animation_player == null:
		animation_player = AnimationPlayer.new()
		add_child(animation_player)
		print("[Match] Created new AnimationPlayer node")
	else:
		print("[Match] ✓ Found existing AnimationPlayer")
	
	# Auto-generate all 72 skill animations from skill_data.json
	print("[Match] Generating animations...")
	if not SetupSkillAnimations.setup_all_animations(animation_player):
		print("[Match] ✗ Animation setup failed!")
		return
	
	print("[Match] ✓ %d animations created" % animation_player.get_animation_list().size())
	
	# Wait for global SkillMgr autoload to initialize
	print("[Match] Waiting for SkillMgr autoload...")
	while not SkillMgr.is_ready:
		await get_tree().process_frame
	
	skill_system = SkillMgr.skill_manager  # Cache reference
	
	var loaded_skills = SkillMgr.list_all_skills()
	print("[Match] ✓ %d skills loaded from skill_data.json" % len(loaded_skills))
	print("[Match] ✓ Skill system fully initialized!")
	print("="*60 + "\n")

## TO USE IN ACTUAL Match._ready():
## In the existing _ready() function, add this line at the very end:
##    await _ready_skill_system_init()

# ─── EXAMPLE: How to call a skill from anywhere in Match ───

func example_cast_skill_test() -> void:
	"""Example showing how to cast skills"""
	SkillMgr.cast_skill("orb", self)
	SkillMgr.cast_skill("fireball", self)
	SkillMgr.cast_skill("blizzard", self)  # Ultimate

# ─── OPTIONAL: Add test input keys to _input() ───
## Add this to existing _input(event: InputEvent) function:

func _input_skill_tests(event: InputEvent) -> void:
	"""Optional: Test skill casting with keyboard"""
	if not (event is InputEventKey and event.pressed):
		return
	
	if not SkillMgr.is_ready:
		return
	
	# Don't intercept if game is paused or menu is open
	# (adjust conditions based on your game state)
	
	match event.keycode:
		KEY_1:
			SkillMgr.cast_skill("orb", self)
			get_tree().set_input_as_handled()
		KEY_2:
			SkillMgr.cast_skill("fireball", self)
			get_tree().set_input_as_handled()
		KEY_3:
			SkillMgr.cast_skill("blizzard", self)  # ULTIMATE
			get_tree().set_input_as_handled()
		KEY_Q:
			SkillMgr.cast_skill("ice_orb", self)
			get_tree().set_input_as_handled()
		KEY_U:
			SkillMgr.cast_skill("swirl_tangerine", self)  # ULTIMATE
			get_tree().set_input_as_handled()
		_:
			pass

# ─── FULL LIST OF 20 SKILLS FOR REFERENCE ───

## Available skill IDs (for SkillMgr.cast_skill()):
##
## COMMON (All characters):
##   "orb", "bolt", "ice_orb", "mud_aura", "wave", "regen", "magnet"
##
## WIZARD:
##   "fireball", "elec_wave", "hurricane", "blizzard" (ULTIMATE)
##
## ARCHER:
##   "arrow", "split_arrow", "pierce_arrow", "sky_fall" (ULTIMATE)
##
## ASSASSIN:
##   "star_knife", "knife_storm", "boomerang", "seven_slash" (ULTIMATE)
##
## SPECIAL:
##   "swirl_tangerine" (ULTIMATE - Brown Capy)
##
## Usage Examples:
##   SkillMgr.cast_skill("orb", self)
##   SkillMgr.cast_skill("blizzard", self)  # Ultimate - screen-wide AoE
##   SkillMgr.get_skill("fireball")  # Get skill metadata
##   SkillMgr.get_skill_color("sky_fall")  # Get color for UI
##   SkillMgr.list_all_skills()  # List all skills

# ─── PROJECT.GODOT AUTOLOAD ENTRY ───
##
## Make sure project.godot has this in [autoload] section:
##
## [autoload]
## SkillMgr="*res://scripts/SkillManager.gd"
##
## If no [autoload] section exists, add it after other sections.
