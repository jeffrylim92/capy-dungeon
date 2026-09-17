class_name StoryBossPresentation
extends RefCounted

const CRYSTAL_SYSTEMS: Array[String] = ["FROST BEAM", "GROUND FREEZE", "ARMOUR REGENERATION"]
const REGULATOR_SYSTEMS: Array[String] = ["HAMMER ARRAY", "REGENERATION CORE", "ARC COIL", "HEAT PULSE"]
const ANCHOR_NAMES: Dictionary = {
	"dominion": "DOMINION · SUMMONS",
	"ruin": "RUIN · CORRUPTION",
	"reflection": "REFLECTION · PROJECTILES",
}

static func brew_quality(purity: float) -> String:
	if purity >= 80.0:
		return "PURE"
	if purity >= 55.0:
		return "STABLE"
	return "VOLATILE"

static func crystal_system(index: int) -> String:
	return CRYSTAL_SYSTEMS[clampi(index, 0, CRYSTAL_SYSTEMS.size() - 1)]

static func regulator_system(index: int) -> String:
	return REGULATOR_SYSTEMS[clampi(index, 0, REGULATOR_SYSTEMS.size() - 1)]

static func anchor_name(anchor_type: String) -> String:
	return str(ANCHOR_NAMES.get(anchor_type, "RITUAL ANCHOR"))

static func profile(stage_id: String, state: Dictionary) -> Dictionary:
	match stage_id:
		"ch1_5":
			return _profile("CRESTKEEPER", "ARENA EMITTER", _crestkeeper_status(state), Color(1.0, 0.48, 0.16))
		"ch2_5":
			var crystals_broken := int(state.get("crystals_broken", 0))
			var colossus_status := "CORE EXPOSED" if crystals_broken >= 3 else "%s · ARMOUR %d/3" % [crystal_system(crystals_broken), 3 - crystals_broken]
			return _profile("FROSTBOUND COLOSSUS", "ARMOUR PHASE" if crystals_broken < 3 else "TRUE CORE", colossus_status, Color(0.42, 0.86, 1.0))
		"ch3_5":
			var quality := brew_quality(float(state.get("purity", 0.0)))
			var quality_effect := "CORRUPTION WEAKENED" if quality == "PURE" else ("REGENERATION SUPPRESSED" if quality == "STABLE" else "CORRUPTION RESISTING")
			return _profile("BLIGHT VINE TYRANT", "THE LIVING MIRE", "ANTIDOTE %s · %s" % [quality, quality_effect], Color(0.40, 0.92, 0.30))
		"ch4_5":
			var disabled := int(state.get("regulators_disabled", 0))
			return _profile("THUNDERFORGE BEHEMOTH", "FORGE SHUTDOWN" if disabled < 4 else "POWER CORE EXPOSED", "SYSTEMS ACTIVE %d/4" % maxi(0, 4 - disabled), Color(1.0, 0.72, 0.18))
		"ch5_5":
			return _profile("ABYSS KING", _abyss_phase(str(state.get("phase", "ritual_anchors"))), _abyss_status(state), Color(0.76, 0.40, 1.0))
	return {}

static func _profile(name: String, phase: String, status: String, accent: Color) -> Dictionary:
	return {"name":name, "phase":phase, "status":status, "accent":accent}

static func _crestkeeper_status(state: Dictionary) -> String:
	var phase := str(state.get("phase", "radial_barrage"))
	if phase == "crestkeeper_boss":
		return "EMITTER DESTROYED · BOSS EXPOSED"
	if phase == "overheat_burst":
		return "CENTRAL EMITTER OVERLOAD"
	return "%s · BANKS %d/3" % [phase.replace("_", " ").to_upper(), maxi(0, 3 - int(state.get("barrage_phases_completed", 0)))]

static func _abyss_phase(phase: String) -> String:
	if phase == "ritual_anchors": return "RITUAL"
	if phase == "abyss_crown": return "ABYSS CROWN"
	if phase == "desperation": return "DESPERATION"
	return "THE KING"

static func _abyss_status(state: Dictionary) -> String:
	var phase := str(state.get("phase", "ritual_anchors"))
	if phase == "ritual_anchors":
		return "RITUAL SHIELD · ANCHORS %d/3" % maxi(0, 3 - int(state.get("anchors_destroyed", 0)))
	if phase == "abyss_crown":
		return "%s · SECTIONS %d/4" % ["CROWN VULNERABLE" if bool(state.get("crown_vulnerable", false)) else "ACTIVATE BOTH SEALS", maxi(0, 4 - int(state.get("crown_sections_broken", 0)))]
	if phase == "desperation":
		return "FINAL EXECUTION"
	return "RITUAL PROTECTION BROKEN"
