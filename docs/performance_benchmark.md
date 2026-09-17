# Performance benchmark

Use a debug build for comparisons. Keep the renderer, window resolution, quality,
save/loadout, and device identical between runs. Discard the first run, capture at
least 30 seconds per phase, and report medians plus the worst sustained five-second
window. The DEV Validator overlay updates four times per second and includes FPS,
process/physics time, draw calls, enemies, player/boss projectiles, VFX, and damage
labels.

## Headless CPU microbenchmark

Run from the repository root:

```sh
/Users/wei-ye.lim/Downloads/Godot.app/Contents/MacOS/Godot \
  --headless --rendering-method gl_compatibility --rendering-driver opengl3 \
  --audio-driver Dummy --path . --script res://tests/performance_benchmark_test.gd
```

The test takes seven samples and prints the median script time per simulated frame.
It is deterministic by entity/effect count, but it is not a substitute for GPU or
thermal profiling on a phone.

| Scenario | Synthetic workload |
| --- | --- |
| A — Normal combat | 24 role-enabled enemies for 240 frames |
| B — Dense combat | 96 role-enabled enemies for 240 frames |
| C — Extreme build | 18 mixed hit/critical/AOE VFX requests per frame for 180 frames |
| D — C1S5 projectile stress | 320 projectile dictionaries for 180 frames; intentionally above the live role-projectile cap |
| E — Combined stress | 96 role-enabled enemies plus the projectile and VFX update loops for 180 frames |

## Device scenarios

Open Story, then the debug DEV Stage Selector. Use the same character, ring loadout,
Player Effects level, Damage Numbers mode, and frame-rate cap for both captures.

| Scenario | Stage / mode | Difficulty | Mutators | DEV build profile |
| --- | --- | --- | --- | --- |
| A | C2S1 | Normal | None | Current |
| B | C5S2 | Nightmare | Elite Hunt, Aggressive Enemies, Relentless | Projectile + AOE-heavy |
| C | Survival dense wave | Current run difficulty | N/A | Record and reuse a projectile + AOE + chain + DOT + companion skill list |
| D | C1S5 | Normal, then Nightmare | None | Projectile + AOE-heavy |
| C4S5 | C4S5 | Nightmare | Aggressive Enemies, Corrupted Ground, Pressure Wave | Projectile + AOE-heavy |
| E | C5S5 | Nightmare | Elite Hunt, Aggressive Enemies, Relentless | Projectile + AOE-heavy |

The DEV build profile describes Story capability/synergy and does not grant skills.
For a true dense player-build comparison, record the acquired skill IDs and levels
and reproduce that loadout before comparing captures.

For C1S5, capture every barrage and verify the safe lane remains readable. For C4S5,
capture regulator transitions and confirm old forge effects clear. For C5S5, capture
Anchor, Crown, final, and desperation transitions. Repeat Boss Practice retry ten
times and record the overlay's object/node counts and static-memory monitor after
each attempt; investigate any monotonic increase after the scene settles.

On Android, pair the overlay with the Godot remote profiler and Android Studio CPU,
memory, and energy profilers. Record device model, SoC/GPU, Android version, build
type, renderer, temperature state, and whether the run used 30 or 60 FPS.
