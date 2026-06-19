extends Node
## Global singleton for skill management
## Auto-load this as "SkillMgr" in Project Settings > Autoload
## Updated to support NEW skill_data.json format with skill_name instead of skill_id

var skill_manager: SkillEffectManager
var is_ready: bool = false

func _ready() -> void:
	print("[SkillMgr] Initializing global skill manager...")
	skill_manager = SkillEffectManager.new()
	
	if skill_manager.load_skill_data():
		var skill_count = skill_manager._skill_data.size() if skill_manager._skill_data else 0
		print("[SkillMgr] ✓ Skill data loaded - %d skills ready" % skill_count)
		is_ready = true
	else:
		print("[SkillMgr] ✗ Failed to load skill data")
		is_ready = false

func cast_skill(skill_name: String, caster: Node2D) -> bool:
	"""Cast a skill by name (NEW: uses skill_name instead of skill_id)"""
	if not is_ready:
		print("[SkillMgr] ✗ Skill manager not ready")
		return false
	
	if not skill_manager.get_skill(skill_name):
		print("[SkillMgr] ✗ Skill not found: %s (available: %s)" % [skill_name, skill_manager.list_skills()])
		return false
	
	return skill_manager.cast_skill(skill_name, caster)

func get_skill(skill_name: String) -> Dictionary:
	"""Get skill data (NEW: uses skill_name)"""
	return skill_manager.get_skill(skill_name) if is_ready else {}

func get_skill_color(skill_name: String) -> Color:
	"""Get skill color from base_color_rgba (NEW: uses skill_name)"""
	if not is_ready:
		return Color.WHITE
	
	var skill = get_skill(skill_name)
	if "base_color_rgba" in skill:
		var color_array = skill["base_color_rgba"]
		if color_array is Array and color_array.size() >= 3:
			return Color(float(color_array[0]), float(color_array[1]), float(color_array[2]), 
						float(color_array[3]) if color_array.size() > 3 else 1.0)
	
	return Color.WHITE

func list_all_skills() -> Array:
	"""Debug: List all loaded skill names (NEW: returns names instead of full objects)"""
	if is_ready and skill_manager._skill_data:
		return skill_manager.list_skills()
	return []

func get_skill_state(skill_name: String, state_name: String) -> Dictionary:
	"""Get a specific state from a skill (NEW: works with nested states)"""
	if not is_ready:
		return {}
	
	return skill_manager.get_skill_state(skill_name, state_name)
