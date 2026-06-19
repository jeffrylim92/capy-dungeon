# Skill System Integration Test Guide

## Quick Start - Testing Updated Skills

### Prerequisites
- Godot 4.x with capy-dungeon project open
- skill_data.json updated with ChatGPT specs (15 skills)
- SkillEffectManager.gd, SkillManager.gd, Match.gd updated

### Test Sequence

#### 1. **Startup Verification** (Console Messages)
When you start the game, look for these messages in the Output console:
```
✓ Loaded 15 skills from skill_data.json
[SkillMgr] ✓ Skill data loaded - 15 skills ready
✓ Skill system ready with 15 skills loaded!
```

#### 2. **Test Common Skills** (Use in Gameplay)
Start a run and pick the **Common** skill class. Trigger these skills and verify:

- **Capy Orb** (`orb`)
  - Expected: 3 golden orbiting particles around player
  - Color: Golden [1.0, 0.84, 0.29, 1.0]
  - Glow intensity: 1.2
  - Console log: `✓ Created particle system for skill: Capy Orb`
  - Visual: Orbits at 180°/sec, trails behind each orb

- **Capy Bolt** (`bolt`) 
  - Expected: Lightning projectiles with yellow-cyan particles
  - Color: Yellow [1.0, 0.94, 0.29, 1.0] + cyan secondary [0.34, 0.78, 1.0]
  - Fires toward nearest enemy
  - Console log: `✓ Created particle system for skill: Capy Bolt`

- **Ice Orb** (`ice_orb`)
  - Expected: Icy blue projectiles with crystalline particles
  - Freezes/slows enemies on impact
  - Visual: Cool blue color with glow

#### 3. **Test Wizard Skills**
Pick the **Wizard** class and trigger:

- **Fireball** (`fireball`)
  - Expected: Orange-red projectiles with glow
  - Console: `✓ Created particle system for skill: Fireball`
  - Should fire toward enemies

- **Hurricane** (`wave`)
  - Expected: Spinning air aura around player
  - Console: `✓ Created particle system for skill: Hurricane`
  - Damages enemies within radius

- **Blizzard** (`blizzard`) - AOE Ultimate
  - Expected: Large screen shake + blue particle explosion
  - Triggers: `[Match] ✓ Triggered skill effect: Blizzard`
  - Visual: Freeze effect on all visible enemies

- **Elec Shockwave** (`elec_wave`)
  - Expected: Yellow-blue lightning wave
  - Radiates outward from player

#### 4. **Test Archer Skills**
Pick the **Archer** class and trigger:

- **Arrow Shot** (`arrow`)
  - Expected: Projectiles with trail particles
  - Console: `✓ Created particle system for skill: Arrow Shot`

- **Split Arrow** (`split_arrow`)
  - Expected: Multiple projectiles spawning

- **Pierce Arrow** (`pierce_arrow`)
  - Expected: Projectiles that pierce through enemies

- **Sky Fall** (`sky_fall`) - AOE Ultimate
  - Expected: Screen shake + falling meteor particles
  - Triggers: `[Match] ✓ Triggered skill effect: Sky Fall`

#### 5. **Advanced Testing**

**Check Particle Colors Match JSON:**
```gdscript
# Open Godot script console and run:
var skill = SkillMgr.get_skill("Capy Orb")
print("Capy Orb color: ", skill.get("base_color_rgba"))  # Should print [1.0, 0.84, 0.29, 1.0]
```

**Verify State Structure:**
```gdscript
# In console:
var skill = SkillMgr.get_skill("Blizzard")
print("States available: ", skill.get("states", {}).keys())  # Should show ["spawn", "charge", "release", etc.]
```

**Check Particle Count:**
```gdscript
# For any skill:
var states = skill.get("states", {})
if states.size() > 0:
    var first_state = states.values()[0]
    print("Particles in first state: ", first_state.get("particles"))
```

### Troubleshooting

#### No Particles Showing
- [ ] Check console for errors like `Skill not found: Capy Orb`
- [ ] Verify skill_data.json uses `skill_name` field (not `skill_id`)
- [ ] Check if SkillEffectManager is loading JSON correctly: `print(SkillMgr.skill_manager._skill_data.keys())`
- [ ] Verify Match.gd is calling `_get_json_skill_name()` correctly

#### Wrong Color
- [ ] Check JSON `base_color_rgba` field is in correct format: [R, G, B, A] with values 0.0-1.0
- [ ] Verify glow_intensity is being read: `var skill = SkillMgr.get_skill("name"); print(skill.get("glow_intensity"))`

#### Crash on Skill Cast
- [ ] Check if skill name mapping in `_get_json_skill_name()` is complete
- [ ] Verify JSON parsing errors: open DevTools console for parse errors
- [ ] Ensure skill_data.json is valid JSON: use online JSON validator

#### Animation Not Playing
- [ ] Check SetupSkillAnimations.gd created animation library
- [ ] Verify AnimationPlayer exists in Match scene

### Success Criteria

✅ **All 15 skills render with particle effects from JSON specs**
✅ **Colors match JSON `base_color_rgba` values**
✅ **Glow intensity applied correctly**
✅ **Rotation speed and wobble from JSON visible in particle motion**
✅ **No console errors about missing skills**
✅ **Console shows `✓ Created particle system` for each skill triggered**

### Next Steps (After Testing)

1. **If test passes**: Provide feedback on visual quality, request additional prompts for remaining 5 skills
2. **If test fails**: Check troubleshooting section above, verify JSON structure, review console errors
3. **Ready for remaining skills**: Star Knife, Knife Storm, Boomerang Star, 7 Slash, Swirl Tangerine

---

## File Structure Reference

```
res://data/
  skill_data.json          ← 15 updated skills with ChatGPT specs
res://scripts/
  SkillEffectManager.gd    ← Reads JSON, creates particles
  SkillManager.gd          ← Global API (SkillMgr)
  SetupSkillAnimations.gd  ← Creates animation library
  Match.gd                 ← Main game scene, uses _get_json_skill_name()
```
