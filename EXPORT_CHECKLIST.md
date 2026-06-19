# 🎮 EXPORT CHECKLIST - Ready To Play & Build

Complete these steps before pressing Play or exporting the game.

---

## 🔴 CRITICAL (Must Do)

- [ ] **Add SkillMgr to project.godot autoload**
  - Open: `res://project.godot` 
  - Find `[autoload]` section (or create it)
  - Add: `SkillMgr="*res://scripts/SkillManager.gd"`
  - **How to verify**: Restart Godot, check Output for "[SkillMgr] ✓ Skill data loaded"

- [ ] **Add skill system initialization to Match._ready()**
  - Open: `scripts/Match.gd` (line ~403)
  - At end of _ready() function, add:
    ```gdscript
    await _ready_skill_system_init()  # or inline the code
    ```
  - **How to verify**: Press Play, check Output for "✓ Skill system fully initialized!"

- [ ] **Verify all required script files exist**
  - `res://scripts/SkillManager.gd` ✓
  - `res://scripts/SetupSkillAnimations.gd` ✓
  - `res://scripts/SkillEffectManager.gd` ✓
  - `res://data/skill_data.json` ✓
  - **How to verify**: Check FileSystem panel in Godot

---

## 🟡 HIGH (Highly Recommended)

- [ ] **Verify player scene has AnimationPlayer node**
  - Open: Your player/Match scene in editor
  - Look for node named: `AnimationPlayer`
  - If missing: Add → AnimationPlayer (will be created by code if missing)
  - **How to verify**: Expand player node tree, see AnimationPlayer child

- [ ] **Check asset folders exist and have placeholders**
  - `res://textures/effects/` - contains 20 PNG files for particles
  - `res://sfx/skills/` - contains ~41 WAV files for sound effects
  - **How to verify**: Open FileSystem, browse folders

- [ ] **Run console test**
  - Press Play in editor
  - Check Output for: 
    - ✓ "Created 72 animations"
    - ✓ "20 skills loaded"
    - ✓ "Skill system fully initialized"
  - Press TEST KEYS (1, 2, 3) to verify skills cast
  - **How to verify**: Watch AnimationPlayer panel, see animations playing

---

## 🟢 GOOD TO HAVE (Nice-to-Have)

- [ ] **Add skill testing input handlers (optional)**
  - Add test key handlers to Match._input() for rapid testing
  - Example: KEY_1 → "orb", KEY_2 → "fireball", KEY_3 → "blizzard"
  - **How to verify**: Play and press keys, skills activate

- [ ] **Replace placeholder assets with real art/audio**
  - Replace PNG files in `textures/effects/` with real particle sprites
  - Replace WAV files in `sfx/skills/` with real sound effects
  - Update paths in skill_data.json if file structure changes
  - **How to verify**: Game sounds real, particles look good

- [ ] **Customize skill timings/properties**
  - Edit: `data/skill_data.json`
  - Adjust: animation_states, timings, colors, particle textures
  - See: `ANIMATIONS_REFERENCE.md` for all 72 animation names
  - **How to verify**: Animations play with new timings

- [ ] **Set up character-specific skill pools**
  - Modify Match._skills list based on character selection
  - Different characters can have different starting skills
  - **How to verify**: Switching character shows different skills

---

## 📋 PRE-EXPORT VALIDATION

Before exporting, run this checklist:

**Code Validation:**
```
✓ SkillManager.gd has load_skill_data() working
✓ SetupSkillAnimations.gd creates 72 animations
✓ SkillEffectManager.gd plays animations/particles/sounds
✓ Match.gd calls _ready_skill_system_init()
```

**File Validation:**
```
✓ skill_data.json exists and is valid JSON
✓ project.godot has [autoload] with SkillMgr entry
✓ All 20 texture PNG files in textures/effects/
✓ All ~41 sound WAV files in sfx/skills/
```

**Editor Validation:**
```
✓ Press Play → No console errors
✓ Check Output → "[SkillMgr] ✓ Skill data loaded"
✓ Press test key (1) → Skill casts and animation plays
✓ Check AnimationPlayer → Shows playing animation
```

**Scene Validation:**
```
✓ Player scene has AnimationPlayer node
✓ Match script exists and is attached to player
✓ No missing node references in script
```

---

## 🚀 EXPORTING YOUR GAME

### Android Export

1. Install Android SDK and configure in Godot
2. Create APK in Project → Export Project
3. Choose Android platform
4. Set package name and permissions
5. Build and test on device

### iOS Export

1. macOS only - requires Apple Developer account
2. Configure signing certificates in export settings
3. Project → Export Project → iOS
4. Use Xcode to build and deploy to device

### Desktop Export (Windows/Linux/macOS)

1. Project → Export Project
2. Choose platform (Windows, Linux, or macOS)
3. Build executable
4. Copy to distribution folder
5. Test on clean machine

### HTML5 Export

1. Project → Export Project → Web
2. Requires .zip file of project
3. Deploy to web server
4. Open in browser

---

## 🐛 TROUBLESHOOTING

**Problem: "SkillMgr not defined" error**
- ✓ Make sure autoload line is in project.godot
- ✓ Check file path: `*res://scripts/SkillManager.gd` (with asterisk)
- ✓ Reload Godot project

**Problem: "AnimationPlayer not found" error**
- ✓ Verify player scene has AnimationPlayer node
- ✓ Code will auto-create one if missing, but better to have it manually
- ✓ Node must be direct child of player node

**Problem: "skill_data.json not found"**
- ✓ Check file path: `res://data/skill_data.json`
- ✓ Verify file exists (not in OS file system, but showing in Godot FileSystem)
- ✓ Run JSON validation: `python3 -c "import json; json.load(open('data/skill_data.json'))"`

**Problem: Skills don't play animations**
- ✓ Check SetupSkillAnimations.setup_all_animations() was called
- ✓ Verify output shows "Created 72 animations"
- ✓ Check AnimationPlayer node exists
- ✓ Verify animation names match: "{skill_id}_{state}"

**Problem: No sounds play**
- ✓ Check sfx/skills/ folder has WAV files
- ✓ Verify audio output enabled in your device
- ✓ Check SkillEffectManager.play_sound() is being called
- ✓ Try with system volume not muted

**Problem: Game crashes on export**
- ✓ Check export settings have all required permissions
- ✓ Verify all asset paths use `res://` prefix
- ✓ Test file access: try reading a simple file from res://data/
- ✓ Check console for specific error messages

---

## 📞 SUPPORT RESOURCES

**Documentation Files:**
- `QUICK_START.md` - 3-step setup overview
- `ANIMATIONS_REFERENCE.md` - All 72 animation names and timings
- `INTEGRATION_GUIDE.md` - Detailed integration instructions
- `MATCH_GD_CODE_TEMPLATE.md` - Exact code snippets to copy-paste

**Godot References:**
- Godot Docs: https://docs.godotengine.org/
- AnimationPlayer: https://docs.godotengine.org/en/4.1/classes/class_animationplayer.html
- Autoload: https://docs.godotengine.org/en/4.1/tutorials/misc/autoload_globals/intro.html

**Project Files:**
- All scripts: `res://scripts/`
- Skill data: `res://data/skill_data.json`
- Assets: `res://textures/effects/`, `res://sfx/skills/`

---

## ✅ YOU'RE READY!

Once this checklist is complete:

1. **Press Play in Godot Editor** to test
2. **Press test keys** (1, 2, 3) to verify skills work
3. **Export the game** for your target platform
4. **Test the exported build** on actual device
5. **Celebrate!** 🎉 Your skill system is live

Questions? Check the documentation files or review SkillManager.gd and SkillEffectManager.gd for API details.
