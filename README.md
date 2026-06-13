# Capy Dungeon

Mobile tap-combo PvP battler starring capybaras. 60-second matches, big juicy combos, cute finishers.

## Status

Phase 1 scaffold — playable single-player prototype vs a dummy AI opponent. Placeholder art (colored rectangles). All UI is built in code so you can iterate on `Match.gd` without touching scene files.

## Requirements

- **Godot 4.3+** (mobile renderer, GDScript). Download: https://godotengine.org/download
- macOS / Windows / Linux for editing. Exports: iOS + Android.

## Project layout

```
capy-dungeon/
├── project.godot          # Engine config (portrait, 1080x1920, mobile renderer)
├── icon.svg
├── scenes/
│   ├── Main.tscn          # Entry point — flow controller (Select → Match)
│   ├── CharacterSelect.tscn
│   ├── Match.tscn         # Root game scene (script builds the rest)
│   ├── Capybara.tscn      # Character placeholder
│   └── Fruit.tscn         # Falling tappable fruit
├── scripts/
│   ├── Main.gd            # Top-level flow: Select → Match → rematch
│   ├── CharacterSelect.gd # Pick-a-capy screen
│   ├── Match.gd           # Orchestrator: HUD, AI, win/lose
│   ├── ComboSystem.gd     # Pure combo logic (testable, engine-agnostic)
│   ├── TargetSequence.gd  # Queue of upcoming required fruits
│   ├── FruitSpawner.gd    # Spawns fruit on ramping timer
│   ├── Fruit.gd           # Falling Area2D, emits tapped/missed
│   ├── Capybara.gd        # HP holder + hit flash, accepts CharacterData
│   ├── CharacterData.gd   # Resource: id, hp, tint, finisher
│   └── CharacterLoader.gd # Scans resources/characters/ at runtime
├── resources/
│   └── characters/        # Drop new *.tres files here to add capybaras
│       ├── capy_brown.tres
│       ├── capy_chef.tres
│       └── capy_zoomer.tres
├── tests/
│   ├── test_combo_system.gd
│   ├── test_target_sequence.gd
│   └── test_character_loader.gd
└── assets/
    ├── sprites/           # (drop capybara art here later)
    ├── sfx/
    └── fonts/
```

## Run it

1. Open Godot 4 → **Import** → select `capy-dungeon/project.godot`
2. Press **F5** (or the play button). Pick `Main.tscn` if prompted.
3. **Mouse-click** falling fruit to tap. AI deals tick damage every 1.2s. Match ends at 60s or 0 HP.

## Run on your phone

In Godot: **Project → Remote Debug → One-Click Deploy**. Plug in your Android device (USB debugging on). iOS needs an export template + Xcode signing.

## Run the tests (headless)

```sh
cd capy-dungeon
godot --headless --script tests/test_combo_system.gd
```

## Tuning knobs

| Where | Constant | Effect |
|---|---|---|
| [scripts/Match.gd](scripts/Match.gd) | `MATCH_DURATION_SEC` | Round length |
| [scripts/Match.gd](scripts/Match.gd) | `AI_TICK_SEC`, `AI_DAMAGE_PER_TICK` | Opponent pressure |
| [scripts/Match.gd](scripts/Match.gd) | `TARGET_LOOKAHEAD` | How many upcoming fruits the player can see |
| [scripts/ComboSystem.gd](scripts/ComboSystem.gd) | `BASE_DAMAGE`, `MILESTONES` | Damage curve & finisher thresholds |
| [scripts/FruitSpawner.gd](scripts/FruitSpawner.gd) | `spawn_interval`, `min_spawn_interval`, `ramp_per_spawn` | Difficulty ramp |

## Adding a new character

1. Duplicate any file under [resources/characters/](resources/characters/), e.g. `capy_brown.tres`
2. Rename it (`capy_ninja.tres`) and edit fields in a text editor — or open in Godot's inspector
3. Restart the game; `CharacterLoader` discovers it automatically. The combo milestone matching the character's `finisher_threshold` triggers their named finisher with a banner.

Fields:

| Field | Notes |
|---|---|
| `id` | Unique StringName, e.g. `&"capy_ninja"` |
| `display_name` | Shown above the character |
| `tint` | Placeholder body color |
| `max_hp` | Total HP for the round |
| `finisher_name` | Banner text on trigger |
| `finisher_threshold` | Fires the finisher every N combo hits (10 = at 10, 20, 30…). Any positive int. |
| `finisher_damage` | Bonus damage dealt to opponent each time the finisher fires; 0 disables |

## Sound effects

Drop `.wav`, `.ogg`, or `.mp3` files into [assets/sfx/](assets/sfx/) with these names. Missing cues are silently skipped, so the game runs fine without any of them.

| Cue file | Plays when |
|---|---|
| `tap` | Correct fruit tapped (pitch randomised) |
| `wrong` | Wrong fruit tapped |
| `milestone` | Combo milestone reached (pitch rises per tier) |
| `finisher` | Character finisher fires |
| `victory` | Round won |
| `defeat` | Round lost |

## Next steps

- [ ] Replace `ColorRect` placeholders with capybara sprites + animations
- [ ] Background music + ambient hot-spring SFX
- [ ] Async PvP: record player input, play back as "ghost opponent"
- [ ] Real-time multiplayer (Nakama / Colyseus / PlayFab)
- [ ] Meta layer: profile, unlocks, leaderboards
