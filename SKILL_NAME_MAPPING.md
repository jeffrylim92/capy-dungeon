# Skill Name Mapping: Old IDs → New JSON Names

## Updated Skills (15 total) - Ready for Testing

### Common Skills (7/7)
| Old ID | New Name | Status |
|--------|----------|--------|
| `"orb"` | `"Capy Orb"` | ✅ Updated in JSON |
| `"bolt"` | `"Capy Bolt"` | ✅ Updated in JSON |
| `"ice_orb"` | `"Ice Orb"` | ✅ Updated in JSON |
| `"mud_aura"` | `"Mud Aura"` | ✅ Updated in JSON |
| `"squeal_wave"` | `"Squeal Wave"` | ✅ Updated in JSON |
| `"calm"` | `"Capy Calm"` | ✅ Updated in JSON |
| `"xp_bonus"` | `"XP Magnet"` | ✅ Updated in JSON |

### Wizard Skills (4/4)
| Old ID | New Name | Status |
|--------|----------|--------|
| `"fireball"` | `"Fireball"` | ✅ Updated in JSON |
| `"elec_wave"` | `"Elec Shockwave"` | ✅ Updated in JSON |
| `"wave"` | `"Hurricane"` | ✅ Updated in JSON |
| `"blizzard"` | `"Blizzard"` | ✅ Updated in JSON |

### Archer Skills (4/4)
| Old ID | New Name | Status |
|--------|----------|--------|
| `"arrow"` | `"Arrow Shot"` | ✅ Updated in JSON |
| `"split_arrow"` | `"Split Arrow"` | ✅ Updated in JSON |
| `"pierce_arrow"` | `"Pierce Arrow"` | ✅ Updated in JSON |
| `"sky_fall"` | `"Sky Fall"` | ✅ Updated in JSON |

---

## Pending Skills (5 total) - Awaiting ChatGPT Prompts

### Special Skills
| Old ID | New Name | Status | Notes |
|--------|----------|--------|-------|
| `"swirl_tangerine"` | `"Swirl Tangerine"` | ⏳ Pending | Ultimate skill |
| `"capy_brown"` | `"Capy Brown"` | ⏳ Pending | Defensive ability |

### Assassin Skills (not in updated JSON yet)
| Old ID | New Name | Status | Notes |
|--------|----------|--------|-------|
| `"star_knife"` | `"Star Knife"` | ⏳ Pending | Homing projectile |
| `"knife_storm"` | `"Knife Storm"` | ⏳ Pending | Aura skill |
| `"boomerang"` | `"Boomerang Star"` | ⏳ Pending | Returning projectile |
| `"seven_slash"` | `"7 Slash"` | ⏳ Pending | AOE ultimate |

---

## Implementation Notes

1. **SkillEffectManager.gd**: Updated to use `skill_name` parameter and read from nested `states` structure
2. **SkillManager.gd**: Updated to call proper get_skill(skill_name) and handle `base_color_rgba` from JSON
3. **Match.gd**: Needs mapping in `_trigger_aoe()` and other skill calls to use new names for updated skills
4. **Forward compatibility**: Old code will gracefully fail when looking up pending skills that don't exist in JSON yet

## How to Test

1. Run the game in Godot
2. Trigger any of the 15 updated skills
3. Verify particles display with correct colors from JSON specs
4. Check console for "✓ Created particle system" messages
5. When remaining 5 skills are added via ChatGPT, update this mapping and re-run tests
