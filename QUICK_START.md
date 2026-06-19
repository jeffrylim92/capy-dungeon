# Quick Start: Skill System Setup

## 3-Step Setup (5 minutes)

### Step 1: Ensure Files Are in Place
```
res://data/skill_data.json          ✓ (Already created)
res://scripts/SkillEffectManager.gd ✓ (Already exists)
res://scripts/SetupSkillAnimations.gd ✓ (Just created)
```

### Step 2: Add AnimationPlayer to Your Player Scene
In your Match.gd scene:
1. Open your player scene in Godot editor
2. Add a new `AnimationPlayer` node as child (Name: `AnimationPlayer`)
3. Attach your sprite/character to the same node or parent

### Step 3: Call Setup in Your Script
Update your Match.gd `_ready()` function:

```gdscript
extends Node2D

var skill_manager: SkillEffectManager
var animation_player: AnimationPlayer

func _ready() -> void:
    # Get or create AnimationPlayer
    animation_player = $AnimationPlayer
    
    # Auto-generate all 72 skill animations
    print("Creating skill animations...")
    SetupSkillAnimations.setup_all_animations(animation_player)
    
    # Load skill data
    skill_manager = SkillEffectManager.new()
    skill_manager.load_skill_data()
    
    print("✓ Ready! Press 1-3 for skills, F for ultimate")

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_1:
            skill_manager.cast_skill("fireball", self)
        elif event.keycode == KEY_2:
            skill_manager.cast_skill("blizzard", self)
        elif event.keycode == KEY_3:
            skill_manager.cast_skill("swirl_tangerine", self)
```

---

## What Just Happened?

✅ **JSON File Updated** → `skill_data.json` has all 20 skills with proper structure

✅ **72 Animations Created** → When you run `_ready()`, all animation names are auto-generated:
- `orb_spawn`, `orb_orbit`, `orb_impact`
- `bolt_charge`, `bolt_fire`, `bolt_travel`, `bolt_impact`
- `fireball_spawn`, `fireball_orbit`, `fireball_flicker`, `fireball_impact`
- ... and 60+ more (see ANIMATIONS_REFERENCE.md)

✅ **Skill Manager Ready** → `SkillEffectManager.gd` can now:
- Load animations by name
- Play particle effects with correct colors
- Play sound effects
- Handle all skill casting

---

## Test It

1. **Attach the script** with the `_ready()` code above
2. **Press Play** in Godot editor
3. **Press 1, 2, 3** - Watch skills cast!
4. **Check Godot console** - Should see ✓ messages

---

## Customize Animations Later

Once setup is done, you can:

1. **Open AnimationPlayer** in editor
2. **Find any animation** (e.g., `fireball_spawn`)
3. **Edit keyframes:**
   - Add sprite rotation
   - Add scale keyframes
   - Add opacity changes
   - Add shader effects

The timings are preserved from skill_data.json, so animations stay synchronized with skills.

---

## If Something Goes Wrong

**"Animation not found" error?**
- ✓ Make sure `_ready()` calls `SetupSkillAnimations.setup_all_animations()`
- ✓ Check console for any ✗ messages

**"skill_data.json not found"?**
- ✓ Verify file is at: `res://data/skill_data.json`
- ✓ Run setup again

**No sound playing?**
- ✓ Check `res://sfx/` folder exists with sound files
- ✓ Or create dummy placeholder files

---

## Next: Art Assets

After animations work, you'll need:

```
res://textures/effects/           (Particle textures)
  orb_particles.png
  bolt_particles.png
  fireball_particles.png
  ... (one per skill)

res://sfx/skills/                 (Sound effects)
  orb_spawn.wav
  bolt_impact.wav
  fireball_explosion.wav
  ... (one per sound)
```

For now, you can use placeholder PNGs/WAVs and it will still work!

---

## File Reference

- **SetupSkillAnimations.gd** — Auto-generates animations from JSON
- **MATCH_SETUP_EXAMPLE.gd** — Copy/paste into your Match.gd
- **ANIMATIONS_REFERENCE.md** — Complete list of all 72 animations
- **skill_data.json** — All 20 skills with metadata
- **SkillEffectManager.gd** — Core API for casting skills
