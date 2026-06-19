# Animation Setup Reference

## Auto-Generated Animations from skill_data.json

This document lists all 72 animations that will be created automatically by `SetupSkillAnimations.gd`.

### COMMON SKILLS (7 skills = 22 animations)

#### Capy Orb
- `orb_spawn` (0.5s)
- `orb_orbit` (2.0s) 
- `orb_impact` (0.25s)

#### Capy Bolt
- `bolt_charge` (0.18s)
- `bolt_fire` (0.1s)
- `bolt_travel` (0.25s)
- `bolt_impact` (0.28s)

#### Ice Orb
- `ice_orb_spawn` (0.22s)
- `ice_orb_travel` (0.35s)
- `ice_orb_freeze` (3.0s)
- `ice_orb_impact` (0.28s)

#### Mud Aura
- `mud_activate` (0.45s)
- `mud_idle` (1.2s)
- `mud_pulse` (0.28s)
- `mud_deactivate` (0.35s)

#### Squeal Wave
- `wave_charge` (0.35s)
- `wave_release` (0.12s)
- `wave_expand` (1.2s)
- `wave_dissipate` (0.35s)

#### Capy Calm (Regen)
- `regen_tick` (0.35s)
- `regen_idle` (0.5s)

#### XP Magnet
- `magnet_idle` (1.6s)
- `magnet_activate` (0.35s)
- `magnet_attract` (0.6s)

---

### WIZARD SKILLS (4 skills = 20 animations)

#### Fireball
- `fireball_spawn` (0.35s)
- `fireball_orbit` (1.4s)
- `fireball_flicker` (0.5s)
- `fireball_impact` (0.32s)

#### Elec Shockwave
- `elec_charge` (0.4s)
- `elec_release` (0.12s)
- `elec_expand` (1.0s)
- `elec_crackle` (1.0s)
- `elec_dissipate` (0.35s)

#### Hurricane
- `hurricane_activate` (0.45s)
- `hurricane_rotate` (1.0s)
- `hurricane_damage` (0.25s)
- `hurricane_dissipate` (0.5s)

#### Blizzard (ULTIMATE)
- `blizzard_charge` (0.5s)
- `blizzard_release` (0.25s)
- `blizzard_peak` (2.0s)
- `blizzard_dissipate` (1.0s)

---

### ARCHER SKILLS (4 skills = 18 animations)

#### Arrow Shot
- `arrow_draw` (0.18s)
- `arrow_fire` (0.08s)
- `arrow_travel` (0.4s)
- `arrow_impact` (0.16s)

#### Split Arrow
- `split_arrow_fire` (0.1s)
- `split_arrow_spread` (0.15s)
- `split_arrow_travel` (0.45s)
- `split_arrow_impact` (0.16s)

#### Pierce Arrow
- `pierce_arrow_charge` (0.1s)
- `pierce_arrow_fire` (0.08s)
- `pierce_arrow_travel` (0.5s)
- `pierce_arrow_pierce` (0.14s)

#### Sky Fall (ULTIMATE)
- `sky_fall_appear` (0.3s)
- `sky_fall_rain` (2.0s)
- `sky_fall_impact` (0.2s)
- `sky_fall_dissipate` (0.5s)

---

### ASSASSIN SKILLS (4 skills = 16 animations)

#### Star Knife
- `star_knife_launch` (0.12s)
- `star_knife_rotate` (0.25s)
- `star_knife_travel` (0.45s)
- `star_knife_impact` (0.18s)

#### Knife Storm
- `knife_storm_activate` (0.4s)
- `knife_storm_rotate` (1.5s)
- `knife_storm_damage` (0.22s)
- `knife_storm_deactivate` (0.45s)

#### Boomerang Star
- `boomerang_launch` (0.16s)
- `boomerang_outbound` (0.65s)
- `boomerang_return` (0.42s)
- `boomerang_catch` (0.18s)

#### 7 Slash (ULTIMATE)
- `seven_slash_prepare` (0.2s)
- `seven_slash_slash` (0.6s)
- `seven_slash_shockwave` (0.4s)
- `seven_slash_impact` (0.12s)

---

### SPECIAL SKILLS (1 skill = 5 animations)

#### Swirl Tangerine (Brown Capy ULTIMATE)
- `tangerine_charge` (0.5s)
- `tangerine_release` (0.25s)
- `tangerine_vortex` (3.0s)
- `tangerine_peak` (1.5s)
- `tangerine_dissipate` (1.0s)

---

## TOTAL: 72 Unique Animations

All animations are auto-generated with:
- ✓ Correct names from skill_data.json
- ✓ Correct durations from timings
- ✓ Placeholder keyframes (you can customize later)
- ✓ Ready for SkillEffectManager to play

## How to Use

1. **Run setup once:**
   ```gdscript
   SetupSkillAnimations.setup_all_animations($AnimationPlayer)
   ```

2. **Then cast skills:**
   ```gdscript
   skill_manager.cast_skill("fireball", self)  # Plays all animations + particles + sounds
   ```

3. **Customize animations:**
   - Open AnimationPlayer in Godot editor
   - All 72 animation names will be there
   - Edit each animation's keyframes as needed
   - Timings are locked to match skill specs

## Testing

Keyboard shortcuts:
- `1` → Capy Orb
- `2` → Capy Bolt
- `3` → Fireball
- `F` → Blizzard (Ultimate)
- `U` → Swirl Tangerine (Ultimate)

(See MATCH_SETUP_EXAMPLE.gd for key mappings)
