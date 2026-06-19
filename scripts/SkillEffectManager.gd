extends Node
## SkillEffectManager - Manages loading and playing skill effect assets in Godot
## Loads skill definitions from res://data/skill_data.json and wires them to animations/particles

class_name SkillEffectManager

var _skill_data: Dictionary = {}  # skill_name -> skill_config (NEW: uses skill_name as key)
var _skill_particles: Dictionary = {}  # skill_name -> GPUParticles2D reference
var _loaded: bool = false

var skills: Dictionary:
	get:
		return _skill_data

func _ready() -> void:
	load_skill_data()


func load_skill_data() -> bool:
	"""Load skill definitions from JSON file (NEW: supports skill_name format)"""
	var file_path = "res://data/skill_data.json"
	
	var json_text = FileAccess.get_file_as_string(file_path)
	if json_text.is_empty():
		push_error("Skill data file not found: %s" % file_path)
		return false
	
	var json_data = JSON.parse_string(json_text)
	if not json_data:
		push_error("Failed to parse skill_data.json")
		return false
	
	# Handle both formats: array of skills or dict with "skills" key
	if json_data is Array:
		# If it's an array, convert to dict keyed by skill_name (NEW)
		for skill in json_data:
			if "skill_name" in skill:
				_skill_data[skill["skill_name"]] = skill
			elif "skill_id" in skill:
				# Fallback for old format
				_skill_data[skill["skill_id"]] = skill
	elif json_data is Dictionary:
		if "skills" in json_data:
			# Nested format: flatten it
			for category in json_data["skills"]:
				for skill_id in json_data["skills"][category]:
					_skill_data[skill_id] = json_data["skills"][category][skill_id]
		else:
			# Direct dict of skills
			_skill_data = json_data
	
	_loaded = true
	print("✓ Loaded %d skills from skill_data.json" % _skill_data.size())
	return true


func get_skill(skill_name: String) -> Dictionary:
	"""Get the complete skill configuration (NEW: expects skill_name)"""
	return _skill_data.get(skill_name, {})


func cast_skill(skill_name: String, caster_node: Node2D) -> bool:
	"""Cast a skill with full animation/particle playback (NEW: uses skill_name, handles new JSON format)"""
	var skill = get_skill(skill_name)
	if skill.is_empty():
		push_error("Unknown skill: %s" % skill_name)
		return false
	
	# Play first animation state if defined (NEW: handles nested "states" structure)
	if "states" in skill:
		var states = skill["states"] as Dictionary
		# Try "spawn" first, then use first available state
		var first_state_key = ""
		if "spawn" in states:
			first_state_key = "spawn"
		elif states.size() > 0:
			first_state_key = states.keys()[0]
		
		if not first_state_key.is_empty():
			play_animation(caster_node, skill_name)  # Play first state animation
			print("[SkillMgr] ▶ Playing state: %s for skill: %s" % [first_state_key, skill_name])
	
	# Start particles if defined (NEW: extracts from states)
	play_particles(caster_node, skill_name, skill)
	
	# Play sound effects (NEW: looks in states.spawn.audio)
	if "states" in skill and "spawn" in skill["states"]:
		var spawn_state = skill["states"]["spawn"]
		if "audio" in spawn_state and "sfx" in spawn_state["audio"]:
			play_sound(spawn_state["audio"]["sfx"], spawn_state["audio"].get("volume", 0.75))
	
	return true


func play_animation(caster_node: Node2D, animation_name: String) -> void:
	"""Play an animation on the caster"""
	if not caster_node:
		push_warning("play_animation: caster_node is null")
		return
	
	if caster_node.has_node("AnimationPlayer"):
		var anim_player = caster_node.get_node("AnimationPlayer")
		if anim_player and anim_player is AnimationPlayer:
			if anim_player.has_animation(animation_name):
				anim_player.play(animation_name)
				print("[SkillMgr] ✓ Played animation: %s" % animation_name)
			else:
				var available = []
				var lib = anim_player.get_animation_library("")
				if lib:
					available = lib.get_animation_list()
				push_warning("Animation '%s' not found in AnimationPlayer. Available: %s" % [animation_name, available])
		else:
			push_warning("AnimationPlayer node exists but is not AnimationPlayer type")
	else:
		push_warning("caster_node doesn't have AnimationPlayer child node")


func play_particles(caster_node: Node2D, skill_name: String, skill: Dictionary) -> void:
	"""Setup and play particle effects from NEW JSON format (nested states structure)"""
	if not skill or skill.is_empty():
		return
	
	# Extract particle data from first state (NEW: reads from states.spawn or first available state)
	var particle_data = null
	var state_duration = 1.0
	
	if "states" in skill:
		var states = skill["states"] as Dictionary
		var first_state_key = ""
		
		# Get first state (prefer spawn)
		if "spawn" in states:
			first_state_key = "spawn"
		elif states.size() > 0:
			first_state_key = states.keys()[0]
		
		if not first_state_key.is_empty():
			var first_state = states[first_state_key] as Dictionary
			particle_data = first_state.get("particles", {})
			state_duration = float(first_state.get("duration_sec", 1.0))
	
	# Get skill-level color and properties (NEW: from base_color_rgba at skill level)
	var color = Color.WHITE
	if "base_color_rgba" in skill:
		var color_array = skill["base_color_rgba"]
		if color_array is Array and color_array.size() >= 4:
			color = Color(float(color_array[0]), float(color_array[1]), float(color_array[2]), float(color_array[3]))
	
	var glow_intensity = float(skill.get("glow_intensity", 1.0))
	var rotation_speed = float(skill.get("rotation_speed_deg_per_sec", 180.0))
	
	# Create particles if not already cached
	if not skill_name in _skill_particles:
		var particles = GPUParticles2D.new()
		
		# Create particle process material (data-driven from JSON)
		var material = ParticleProcessMaterial.new()
		
		# Color with glow intensity boost (NEW: applies glow_intensity from JSON)
		var glowing_color = Color(
			clamp(color.r + glow_intensity * 0.2, 0.0, 1.0),
			clamp(color.g + glow_intensity * 0.2, 0.0, 1.0),
			clamp(color.b + glow_intensity * 0.2, 0.0, 1.0),
			color.a
		)
		material.color = glowing_color
		
		# Particle count from state specs (NEW: reads particle counts from states)
		var particle_count = 50
		if particle_data is Dictionary:
			# Try common particle count fields from new JSON format
			if "count" in particle_data:
				particle_count = int(particle_data["count"])
			elif "particle_count" in particle_data:
				particle_count = int(particle_data["particle_count"])
			elif "golden_sparks" in particle_data:
				particle_count = int(particle_data["golden_sparks"])
			elif "impact_burst_count" in particle_data:
				particle_count = int(particle_data["impact_burst_count"])
		
		particles.amount = particle_count
		particles.lifetime = state_duration
		
		# Rotation speed from skill level (convert °/sec to rad/sec) (NEW: from rotation_speed_deg_per_sec)
		var rot_speed_rad_per_sec = deg_to_rad(rotation_speed)
		material.angular_velocity_min = rot_speed_rad_per_sec * 0.7
		material.angular_velocity_max = rot_speed_rad_per_sec * 1.3
		
		# Wobble amplitude (NEW: reads from animation_specs if available)
		var wobble_amplitude = 0.5
		if "wobble" in skill and particle_data is Dictionary:
			if "amplitude_px" in skill["wobble"]:
				wobble_amplitude = float(skill["wobble"]["amplitude_px"]) / 100.0
		
		material.radial_accel_min = wobble_amplitude * 50
		material.radial_accel_max = wobble_amplitude * 200
		material.tangential_accel_min = wobble_amplitude * 50
		material.tangential_accel_max = wobble_amplitude * 200
		
		# Scale variation
		material.scale_min = 0.6
		material.scale_max = 1.4
		
		# Velocity spread for natural chaos
		material.velocity_pivot = Vector3(0, 0, 0)
		material.initial_velocity_min = 50
		material.initial_velocity_max = 150
		
		# Set material and add to scene
		particles.process_material = material
		caster_node.add_child(particles)
		_skill_particles[skill_name] = particles
		
		print("[SkillMgr] ✓ Created particle system for skill: %s (count: %d, color: %s, glow: %.1f)" % [skill_name, particle_count, color, glow_intensity])
	
	# Play particles
	var particles = _skill_particles[skill_name]
	particles.restart()
	particles.emitting = true


func play_sound(sound_path: String, volume: float = 0.75) -> void:
	"""Play a sound effect (NEW: supports volume parameter)"""
	if ResourceLoader.exists(sound_path):
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = load(sound_path)
		# Convert linear volume (0.0-1.0) to dB: 20 * log10(volume)
		if volume > 0.0:
			audio_player.volume_db = 20.0 * log(volume) / log(10.0)
		else:
			audio_player.volume_db = -80.0  # Mute
		add_child(audio_player)
		audio_player.play()
		await audio_player.finished
		audio_player.queue_free()
	else:
		push_warning("Sound file not found: %s" % sound_path)


func count_skills() -> int:
	"""Count total loaded skills"""
	return _skill_data.size()


func get_skill_state(skill_name: String, state_name: String) -> Dictionary:
	"""Get a specific animation state for a skill (NEW: reads from states)"""
	var skill = get_skill(skill_name)
	if "states" in skill:
		return skill["states"].get(state_name, {})
	return {}


func list_skills() -> Array:
	"""List all loaded skill names"""
	return _skill_data.keys()
