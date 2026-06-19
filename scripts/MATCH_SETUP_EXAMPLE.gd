## Add this to your Match.gd or player script setup
## This initializes all skill animations automatically

extends Node2D
# class_name Match  # Uncomment if not already defined

var skill_manager: SkillEffectManager
var animation_player: AnimationPlayer

func _ready() -> void:
	# Find or create AnimationPlayer
	animation_player = $AnimationPlayer  # Adjust path if different
	if animation_player == null:
		animation_player = AnimationPlayer.new()
		add_child(animation_player)
	
	# Auto-generate all skill animations from JSON
	print("Setting up skill animations...")
	if SetupSkillAnimations.setup_all_animations(animation_player):
		print("✓ All animations ready!")
	else:
		print("✗ Failed to setup animations")
	
	# Load skill manager
	skill_manager = SkillEffectManager.new()
	if skill_manager.load_skill_data():
		print("✓ Skill data loaded!")
		# DEBUG: Print all loaded skills
		var test_skill = skill_manager.get_skill("fireball")
		if not test_skill.is_empty():
			print("✓ Fireball skill loaded: ", test_skill)
	else:
		print("✗ Failed to load skill data")

func _input(event: InputEvent) -> void:
	# Example: Cast skill on key press
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				skill_manager.cast_skill("orb", self)
			KEY_2:
				skill_manager.cast_skill("bolt", self)
			KEY_3:
				skill_manager.cast_skill("fireball", self)
			KEY_F:
				skill_manager.cast_skill("blizzard", self)
			KEY_U:
				skill_manager.cast_skill("swirl_tangerine", self)

# Usage in your existing skill system
func cast_active_skill(skill_id: String) -> void:
	"""Cast a skill with full effects"""
	skill_manager.cast_skill(skill_id, self)

func get_skill_color(skill_id: String) -> Color:
	"""Get skill color for UI"""
	return skill_manager.get_skill_color(skill_id)
