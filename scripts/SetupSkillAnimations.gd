extends Node
## Helper script to auto-generate AnimationPlayer animations from skill_data.json
## Run this ONCE to set up all skill animations
## Usage: Call setup_all_animations() from your player setup code

class_name SetupSkillAnimations

static func setup_all_animations(animation_player: AnimationPlayer) -> bool:
	"""
	Auto-generates all skill animations from skill_data.json
	Creates animations with proper timings and basic keyframes
	"""
	var skill_data = load_skill_data()
	if skill_data.is_empty():
		return false
	
	# Get all unique animation names from skill data
	var animations_to_create = {}
	
	for skill in skill_data:
		if "animation_states" in skill:
			for state_name: String in skill["animation_states"]:
				var anim_name = skill["animation_states"][state_name]
				
				# Get duration from timings
				var duration = 0.5  # Default
				if "timings" in skill and state_name in skill["timings"]:
					duration = skill["timings"][state_name]
				
				animations_to_create[anim_name] = duration
	
	# Create all animations
	for anim_name: String in animations_to_create:
		var duration = animations_to_create[anim_name]
		create_animation(animation_player, anim_name, duration)
	
	print("✓ Created %d animations" % animations_to_create.size())
	return true

static func create_animation(animation_player: AnimationPlayer, anim_name: String, duration: float) -> void:
	"""Create a single animation with fade keyframes as placeholder"""
	var anim = Animation.new()
	anim.length = duration
	
	# Add modulate track (alpha fade) - simple placeholder
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, NodePath("modulate"))
	
	# Keyframe at start: full opacity
	anim.track_insert_key(track_idx, 0.0, Color.WHITE)
	# Keyframe at end: full opacity (will be replaced with actual animation in AnimationPlayer)
	anim.track_insert_key(track_idx, duration, Color.WHITE)
	
	# Add animation to library (Godot 4.x requires AnimationLibrary)
	var lib = animation_player.get_animation_library("")
	if lib == null:
		lib = AnimationLibrary.new()
		animation_player.add_animation_library("", lib)
	
	if lib.has_animation(anim_name):
		lib.remove_animation(anim_name)
	
	lib.add_animation(anim_name, anim)

static func load_skill_data() -> Array:
	"""Load skill data from JSON file"""
	var path = "res://data/skill_data.json"
	
	var json_text = FileAccess.get_file_as_string(path)
	if json_text.is_empty():
		print("✗ skill_data.json not found at: %s" % path)
		return []
	
	var data = JSON.parse_string(json_text)
	if data == null:
		print("✗ JSON parse error in skill_data.json")
		return []
	
	if data is Array:
		return data
	elif data is Dictionary:
		# Handle dict format - convert to array
		var arr = []
		for key in data:
			if data[key] is Dictionary:
				arr.append(data[key])
		return arr
	
	return []

static func print_all_animations(skill_data: Array) -> void:
	"""Debug: Print all animation names that will be created"""
	var anims = {}
	
	for skill in skill_data:
		if "animation_states" in skill:
			for state in skill["animation_states"]:
				var anim_name = skill["animation_states"][state]
				if not anim_name in anims:
					anims[anim_name] = 0
				anims[anim_name] += 1
	
	print("\n=== All Animation Names to Create ===")
	var anim_list = anims.keys()
	anim_list.sort()
	for anim_name in anim_list:
		print("  - %s" % anim_name)
	print("Total: %d unique animations\n" % anims.size())
