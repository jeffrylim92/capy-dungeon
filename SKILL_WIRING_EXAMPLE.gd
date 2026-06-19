## Example: How to wire skills with animations in your Match.gd
## Add these methods to your Match scene to cast skills with effects

extends Node2D

@onready var skill_manager: SkillEffectManager = SkillEffectManager.new()

func _ready() -> void:
	skill_manager.load_skill_data()
	# Print available skills for debugging
	skill_manager.print_skill_report()


## Example 1: Simple skill cast by ID
func cast_skill(skill_id: String) -> bool:
	"""Cast any skill with automatic animation/particle playback"""
	return skill_manager.cast_skill(skill_id, self)


## Example 2: Get skill info before casting
func describe_skill(skill_id: String) -> void:
	"""Print skill details"""
	var skill = skill_manager.get_skill(skill_id)
	if skill.is_empty():
		print("Skill not found: %s" % skill_id)
		return
	
	print("Casting: %s" % skill.get("name", "Unknown"))
	print("Color: %s" % skill.get("color_name", ""))
	print("Type: %s" % skill.get("type", "Unknown"))


## Example 3: Get skill color for UI display
func get_skill_ui_color(skill_id: String) -> Color:
	"""Get the skill's associated color for UI"""
	return skill_manager.get_skill_color(skill_id)


## Example 4: List all skills for a character
func get_character_skills(character_id: String) -> Array:
	"""Get all available skills for a character"""
	return skill_manager.get_skills_for_character(character_id)


## Example 5: Get ultimate skill
func get_character_ultimate(character_id: String) -> String:
	"""Get the ultimate skill for a character"""
	return skill_manager.get_ultimate_skill(character_id)


## Example 6: Check if skill is ultimate
func is_skill_ultimate(skill_id: String) -> bool:
	"""Check if a skill has ultimate status"""
	return skill_manager.is_ultimate_skill(skill_id)


## Example 7: Get animation timing for skill
func get_skill_cast_time(skill_id: String) -> float:
	"""Get total cast time from timings"""
	var timings = skill_manager.get_skill_timings(skill_id)
	var spawn_time = timings.get("spawn", 0.0)
	var duration = timings.get("duration", 0.0)
	return spawn_time + duration


## Example 8: Play animation without full cast (if you need custom control)
func play_skill_animation(skill_id: String, animation_state: String) -> void:
	"""Play specific animation state for a skill"""
	var anim_name = skill_manager.get_animation_state(skill_id, animation_state)
	if anim_name:
		skill_manager.play_animation(self, anim_name)


## INTEGRATION WITH YOUR EXISTING MATCH CODE
## Add this to your Match._physics_process or wherever skills are cast:

func handle_skill_casting(skill_id: String) -> void:
	"""Complete skill casting workflow"""
	# Validate skill exists
	var skill = skill_manager.get_skill(skill_id)
	if skill.is_empty():
		push_error("Unknown skill: %s" % skill_id)
		return
	
	# Get skill info for logging/debugging
	var skill_name = skill.get("name", "Unknown")
	var skill_color = skill_manager.get_skill_color(skill_id)
	
	print("Casting %s" % skill_name)
	
	# Cast skill (handles animation, particles, sounds)
	skill_manager.cast_skill(skill_id, self)
	
	# Optional: Customize based on skill type
	var skill_type = skill.get("type", "")
	match skill_type:
		"orbit_projectile":
			handle_orbit_projectile_spawn(skill_id)
		"expanding_projectile":
			handle_expanding_projectile_spawn(skill_id)
		"continuous_aura":
			handle_aura_spawn(skill_id)
		_:
			pass


func handle_orbit_projectile_spawn(skill_id: String) -> void:
	"""Custom handling for orbiting skills like Fireball, Capy Orb"""
	# Your existing orbit spawning logic
	pass


func handle_expanding_projectile_spawn(skill_id: String) -> void:
	"""Custom handling for expanding projectiles like Squeal Wave"""
	# Your existing wave spawning logic
	pass


func handle_aura_spawn(skill_id: String) -> void:
	"""Custom handling for auras like Mud Aura, Hurricane"""
	# Your existing aura spawning logic
	pass
