extends Node
## Manages GPU particle systems for skills based on skill_data.json specifications

class_name SkillParticleManager

# Particle systems keyed by skill_id
var _particle_systems: Dictionary = {}

func _ready() -> void:
	pass

## Create or update particle system for a skill based on JSON specs
func create_particles(skill_id: String, skill_data: Dictionary, position: Vector2, parent: Node) -> GPUParticles2D:
	"""
	Create a GPU particle system from skill_data.json animation_specs
	
	Reads from skill_data:
	- color: [R, G, B, A] for particle color
	- animation_specs: Contains particle_count, particle_spawn_rate, duration, rotation_speed
	"""
	
	# Reuse existing particle system or create new
	var particles: GPUParticles2D
	
	if _particle_systems.has(skill_id) and _particle_systems[skill_id] != null:
		particles = _particle_systems[skill_id]
		particles.position = position
		particles.restart()
	else:
		particles = GPUParticles2D.new()
		particles.position = position
		parent.add_child(particles)
		_particle_systems[skill_id] = particles
	
	# Configure particle system from skill_data
	var material = ParticleProcessMaterial.new()
	particles.process_material = material
	
	# Get color from skill_data
	var skill_color = Color.WHITE
	if skill_data.has("color"):
		var color_array = skill_data["color"]
		if color_array is Array:
			skill_color = Color(color_array[0], color_array[1], color_array[2], color_array[3])
	
	material.color = skill_color
	
	# Configure from animation_specs
	if skill_data.has("animation_specs") and skill_data["animation_specs"] is Dictionary:
		var specs = skill_data["animation_specs"]
		
		# Get first animation state specs (spawn/activate/charge)
		var first_state_spec = null
		if specs.size() > 0:
			first_state_spec = specs.values()[0]
		
		if first_state_spec:
			# Duration/Lifetime
			var duration = first_state_spec.get("duration", 1.0)
			material.lifetime = duration
			
			# Particle count
			var particle_count = first_state_spec.get("particle_count", 50)
			particles.amount = int(particle_count)
			
			# Rotation speed (°/sec → rad/sec)
			var rotation_speed = first_state_spec.get("rotation_speed", 180.0)
			material.angular_velocity_min = deg_to_rad(rotation_speed)
			material.angular_velocity_max = deg_to_rad(rotation_speed)
			
			# Wobble/spread
			var wobble = first_state_spec.get("wobble_amplitude", 0.0)
			if wobble > 0:
				material.spread = wobble * 0.1
	
	# Enable and start
	particles.emitting = true
	
	return particles

## Spawn particles at position with duration
func spawn_skill_effect(skill_id: String, skill_data: Dictionary, position: Vector2, duration: float = 1.0) -> GPUParticles2D:
	"""Quick particle spawn for skill effects"""
	
	# Create temporary particle node
	var particles = GPUParticles2D.new()
	particles.position = position
	get_tree().root.add_child(particles)
	
	var material = ParticleProcessMaterial.new()
	particles.process_material = material
	
	# Color
	var skill_color = Color.WHITE
	if skill_data.has("color"):
		var color_array = skill_data["color"]
		if color_array is Array:
			skill_color = Color(color_array[0], color_array[1], color_array[2], color_array[3])
	
	material.color = skill_color
	material.lifetime = duration
	particles.amount = 50
	particles.emitting = true
	
	# Auto-cleanup after duration
	await get_tree().create_timer(duration + 0.5).timeout
	particles.queue_free()
	
	return particles

## Remove particle system for skill
func remove_particles(skill_id: String) -> void:
	if _particle_systems.has(skill_id) and _particle_systems[skill_id] != null:
		_particle_systems[skill_id].queue_free()
		_particle_systems.erase(skill_id)

## Clear all particle systems
func clear_all() -> void:
	for particles in _particle_systems.values():
		if particles != null:
			particles.queue_free()
	_particle_systems.clear()
