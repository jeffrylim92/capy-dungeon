# INTEGRATION GUIDE - Add This to Match.gd

## Step 1: Add Global Autoload

**File: project.godot**

Add these lines to the `[autoload]` section:

```
SkillMgr="*res://scripts/SkillManager.gd"
```

If `[autoload]` section doesn't exist, create it before `[editor_plugins]`.

---

## Step 2: Add Skill System Initialization to Match._ready()

Find the existing `func _ready() -> void:` in `scripts/Match.gd` (around line 403).

**Add this code at the END of the _ready() function, before the closing `}`:**

```gdscript
	# ── Skill System Setup ────────────────────────────────────────────────────
	print("[Match] Initializing skill system...")
	
	# Get or create AnimationPlayer
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player == null:
		anim_player = AnimationPlayer.new()
		add_child(anim_player)
		print("[Match] Created new AnimationPlayer")
	
	# Auto-generate all skill animations from JSON
	SetupSkillAnimations.setup_all_animations(anim_player)
	
	# Wait for SkillMgr autoload to initialize
	await SkillMgr.tree_entered
	while not SkillMgr.is_ready:
		await get_tree().process_frame
	
	print("[Match] ✓ Skill system ready - %d animations, %d skills" % [
		anim_player.get_animation_list().size(),
		len(SkillMgr.list_all_skills())
	])
```

---

## Step 3: Add Skill Casting in _input() (Optional Test Keys)

Find the existing `func _input(event: InputEvent) -> void:` in Match.gd (around line 469).

Add at the beginning to test skills with number keys:

```gdscript
	# ── Debug: Test skill casting with number keys ────────────────────────────
	if event is InputEventKey and event.pressed:
		var match event.keycode:
			KEY_1:
				SkillMgr.cast_skill("orb", self)
				get_tree().set_input_as_handled()
			KEY_2:
				SkillMgr.cast_skill("fireball", self)
				get_tree().set_input_as_handled()
			KEY_3:
				SkillMgr.cast_skill("blizzard", self)
				get_tree().set_input_as_handled()
			KEY_U:
				SkillMgr.cast_skill("swirl_tangerine", self)
				get_tree().set_input_as_handled()
```

---

## Files Created For You

✓ **SkillManager.gd** - Global autoload singleton
✓ **SetupSkillAnimations.gd** - Auto-generator for 72 animations
✓ **SkillEffectManager.gd** - Core skill casting system
✓ **skill_data.json** - All 20 skills with metadata
✓ **textures/effects/*** - 20 placeholder particle PNGs
✓ **sfx/skills/*** - 41 placeholder sound WAVs
✓ **ANIMATIONS_REFERENCE.md** - List of all 72 animation names

---

## Testing

After integration, press Play and try:

```
[1] Capy Orb
[2] Fireball
[3] Blizzard (Ultimate)
[U] Swirl Tangerine (Ultimate)
```

You should see:
- Animation names logged
- Skill names printed
- Visual effects playing
- Sound effects (silent placeholders for now)

---

## Troubleshooting

**"SkillMgr not defined"?**
- ✓ Make sure autoload is set up in project.godot `[autoload]` section
- ✓ Reload project after editing project.godot

**"AnimationPlayer errors"?**
- ✓ Make sure your player scene has an AnimationPlayer node (or it will be created)
- ✓ Check animation names in Output: should show "Created 72 animations"

**No skills loading?**
- ✓ Check console for errors about skill_data.json
- ✓ Verify file exists at: res://data/skill_data.json
- ✓ Run: `python3 -c "import json; json.load(open('/Users/weilim9/capy-dungeon/data/skill_data.json'))"`

---

## Complete Checklist For Export

Before exporting your game:

- [ ] **project.godot** has `[autoload]` with SkillMgr
- [ ] **scripts/SkillManager.gd** exists
- [ ] **scripts/SetupSkillAnimations.gd** exists
- [ ] **scripts/SkillEffectManager.gd** exists
- [ ] **data/skill_data.json** exists and is valid JSON
- [ ] **textures/effects/*** folder has particle PNGs
- [ ] **sfx/skills/*** folder has sound WAVs
- [ ] Match._ready() calls SetupSkillAnimations and waits for SkillMgr
- [ ] AnimationPlayer node exists in player scene
- [ ] Game runs without JSON/autoload errors

Then export to Android/iOS/Desktop normally!
