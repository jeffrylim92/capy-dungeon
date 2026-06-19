# Individual Skill Animation Prompts for ChatGPT

Use one prompt per skill. Feed each to ChatGPT to generate detailed animation specifications for your Godot game.

---

## COMMON SKILLS

### Capy Orb
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Capy Orb" skill.

SKILL DETAILS:
- Name: Capy Orb
- Type: Orbiting projectile (3-5 orbs orbit the player)
- Color: Golden Yellow [1.0, 0.84, 0.29, 1.0]
- Timings: Spawn 0.5s | Orbit 2.0s (loop) | Impact 0.25s
- Orbit radius: 72 pixels, Orbit count: 3 orbs
- Particle counts: Spawn 20 | Orbit spawn rate 5/sec | Impact 30
- Rotation speed: 180°/sec
- Glow pulsing: 0.8 to 1.0
- Screen shake on impact: 0.05
- Texture: 64x64 Additive blend
- Audio: orb_spawn.wav, orb_impact.wav
```

### Capy Bolt
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Capy Bolt" skill.

SKILL DETAILS:
- Name: Capy Bolt
- Type: Auto-targeting projectile (1-3 bolts per shot)
- Color: Bright Yellow [1.0, 0.94, 0.29, 1.0] with electrical effects
- Timings: Charge 0.18s | Fire 0.1s | Travel 0.8s | Impact 0.2s
- Charge glow: 0 to 1.0, particle count: 15
- Fire burst: 10 particles
- Travel spawn rate: 8/sec, spark frequency: 0.05s
- Impact burst: 25 particles, screen shake: 0.08
- Speed: 400 px/sec, Radius: 8 px, Homing: True
- Texture: 48x48 Additive
- Audio: bolt_cast.wav (charge & fire), bolt_impact.wav
```

### Ice Orb
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Ice Orb" skill.

SKILL DETAILS:
- Name: Ice Orb
- Type: Straight-line projectile (1-3 orbs) that freezes enemies
- Color: Cyan Blue [0.3, 0.8, 1.0, 1.0]
- Timings: Spawn 0.25s | Travel 1.2s | Freeze 0.8s | Impact 0.15s
- Spawn: 12 particles, glow cyan
- Travel: 6 particles/sec, frost trail enabled (icy blue)
- Freeze zone radius: 80px, particle burst: 40, shimmer: high
- Impact burst: 20 particles
- Speed: 350 px/sec, Radius: 11 px
- Freeze duration: 1.5 sec
- Texture: 56x56 Additive
- Audio: ice_spawn.wav (cast & freeze), ice_impact.wav
```

### Mud Aura
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Mud Aura" skill.

SKILL DETAILS:
- Name: Mud Aura
- Type: Continuous damage aura around player
- Color: Deep Brown [0.4, 0.25, 0.1, 1.0]
- Timings: Idle 1.5s (loop) | Pulse 0.8s (loop) | Damage 0.3s
- Idle: 45°/sec rotation, 3 particles/sec, glow 0.6
- Pulse: 15px amplitude, 8 particles/pulse
- Damage: 15 particles, screen shake 0.03
- Aura radius: 60px, Pulse frequency: 1.25 Hz
- Texture: 64x64 Normal blend
- Audio: mud_activate.wav (loop), mud_splash.wav (damage)
```

### Squeal Wave
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Squeal Wave" skill.

SKILL DETAILS:
- Name: Squeal Wave
- Type: Expanding shockwave projectile
- Color: Purple [0.7, 0.3, 0.8, 1.0]
- Timings: Charge 0.35s | Release 0.15s | Expand 1.8s | Dissipate 0.6s
- Charge glow: 0.4 to 1.0, 20 particles
- Release: 15 particles, screen shake 0.1
- Expand: 5 particles/sec, 8 rings, ring width 8px, speed 200px/sec
- Dissipate alpha: 1.0 to 0.0, 10 particles
- Max radius: 500px
- Texture: 512x512 Additive
- Audio: wave_release.wav (charge), wave_expand.wav (release)
```

### Capy Calm (Regen)
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Capy Calm" skill (HP Regeneration).

SKILL DETAILS:
- Name: Capy Calm
- Type: Passive continuous regeneration
- Color: Healing Pink [1.0, 0.5, 0.7, 1.0]
- Timings: Tick 0.08s | Float 1.0s | Absorb 0.3s
- Tick: 1 particle per tick, frequency 0.5s
- Float: upward 40px, 180° rotation, alpha 1.0 to 0.0, size scale 1.0
- Absorb: 8 particles, glow flash enabled
- Lifetime: 1.0 sec, HP per tick: 5
- Texture: 32x32 Additive
- Audio: heal_tick.wav
```

### XP Magnet
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "XP Magnet" skill.

SKILL DETAILS:
- Name: XP Magnet
- Type: Passive attraction aura for XP orbs
- Color: Teal Green [0.2, 0.9, 0.6, 1.0]
- Timings: Idle 1.2s (loop) | Activate 0.4s | Attract 0.6s
- Idle: 20px pulse amplitude, 30°/sec, 3 rings, glow 0.4 to 0.7
- Activate: 100px/sec expansion, 12 particles
- Attract: 8 particles/sec, curve strength 40px, target player center
- Base radius: 80px, Max radius: 150px, Activation radius: 200px
- Pulse frequency: 0.83 Hz
- Texture: 48x48 Additive
- Audio: magnet_activate.wav (loop)
```

---

## WIZARD SKILLS

### Fireball
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Fireball" skill (Wizard).

SKILL DETAILS:
- Name: Fireball
- Type: Orbiting projectile (2-4 fireballs)
- Color: Orange with Red Flames [1.0, 0.33, 0.0, 1.0]
- Timings: Spawn 0.35s | Orbit 1.4s (loop) | Flicker 0.5s | Impact 0.32s
- Spawn: scale 0.3 to 1.0, 25 particles, glow orange-red
- Orbit: 130°/sec, 85px radius, 2 fireballs, 5px wobble, 4 particles/sec, flame pulsing
- Flicker: 8 flickers/sec, 6 particles/sec
- Impact: 35 particles, screen shake 0.12, fire ring enabled, damage 40
- Texture: 64x64 Additive
- Audio: fireball_spawn.wav (cast & loop), fireball_explosion.wav (impact)
```

### Elec Shockwave
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Elec Shockwave" skill (Wizard).

SKILL DETAILS:
- Name: Elec Shockwave
- Type: Expanding electrical pulse
- Color: Electric Yellow with Blue Arcs [1.0, 1.0, 0.2, 1.0]
- Timings: Charge 0.25s | Release 0.1s | Expand 1.5s | Crackle 0.4s
- Charge glow: 0.5 to 1.0, 25 particles
- Release: 20 particles, screen flash, shake 0.15
- Expand: 250px/sec, 6 particles/sec, jagged ring width 6px
- Crackle: 4 frequency, 6 lightning bolts, 15 particles
- Max radius: 450px, Strike count: 6
- Texture: 512x512 Additive
- Audio: elec_discharge.wav (charge), elec_impact.wav (expand)
```

### Hurricane
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Hurricane" skill (Wizard).

SKILL DETAILS:
- Name: Hurricane
- Type: Continuous spinning aura
- Color: Light Blue [0.6, 0.9, 1.0, 1.0]
- Timings: Activate 0.4s | Spin 0.8s (loop) | Intense 1.5s | Dissipate 0.6s
- Activate: 80px/sec expansion, 20 particles
- Spin: 360°/sec, 7 particles/sec, high wind
- Intense: 450°/sec, 10 particles/sec, 150 knockback force
- Dissipate: 180°/sec, alpha 1.0 to 0.0, 8 particles
- Aura radius: 90px, Knockback radius: 100px, Max duration: 5.0s
- Texture: 128x128 Normal
- Audio: hurricane_activate.wav (loop), hurricane_loop.wav (intense)
```

### Blizzard
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Blizzard" skill (Wizard ULTIMATE).

SKILL DETAILS:
- Name: Blizzard
- Type: Screen-wide ice storm (ULTIMATE)
- Color: Pale Cyan [0.5, 0.9, 1.0, 1.0]
- Timings: Charge 0.5s | Release 0.25s | Peak 2.0s | Dissipate 1.0s
- Charge glow: 0.3 to 1.0, 40 particles, freeze start
- Release: 100 particles, screen flash, shake 0.2
- Peak: 50 particles/sec, 20 large + 80 small snowflakes, icicles 0.5/sec, 50% slow
- Dissipate: 10 particles/sec, final 5 particles
- Damage radius: 1600px, Covers screen, Slow 2.0s
- Duration: 3.75s, Cooldown: 20s
- Texture: 256x256 Normal
- Audio: blizzard_cast.wav (charge), blizzard_loop.wav (peak), blizzard_end.wav
```

---

## ARCHER SKILLS

### Arrow Shot
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Arrow Shot" skill (Archer).

SKILL DETAILS:
- Name: Arrow Shot
- Type: Fast projectile (1-3 arrows per shot)
- Color: Forest Green [0.2, 0.6, 0.2, 1.0]
- Timings: Draw 0.12s | Fire 0.08s | Travel 0.7s | Impact 0.18s
- Draw: scale 0.8 to 1.0, glow 0.6 to 0.8
- Fire: 8 particles, shake 0.05
- Travel: 720° rotation, trail green glow, 4 particles/sec
- Impact: 12 particles, pierce visual enabled
- Speed: 500 px/sec, Radius: 6px, Pierces: True
- Texture: 32x48 Normal
- Audio: arrow_fire.wav (draw & fire), arrow_impact.wav
```

### Split Arrow
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Split Arrow" skill (Archer).

SKILL DETAILS:
- Name: Split Arrow
- Type: Fan spread projectile (3-7 arrows per shot)
- Color: Lime Green [0.4, 0.8, 0.3, 1.0]
- Timings: Fire 0.1s | Spread 0.15s | Travel 0.8s | Impact 0.2s
- Fire: 15 particles, shake 0.08
- Spread: 60° angle, 200px/sec separation, 5 arrows
- Travel: 720° per arrow, trail enabled, 3 particles/sec per arrow
- Impact: 10 particles, staggered impacts
- Speed: 450px/sec, Pierces: False
- Texture: 32x48 Normal
- Audio: split_arrow_fire.wav (fire), arrow_impact.wav (impacts)
```

### Pierce Arrow
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Pierce Arrow" skill (Archer).

SKILL DETAILS:
- Name: Pierce Arrow
- Type: Heavy piercing projectile (1-3 arrows)
- Color: Teal with Cyan Glow [0.2, 1.0, 0.8, 1.0]
- Timings: Charge 0.1s | Fire 0.08s | Travel 0.9s | Pierce 0.15s | Impact 0.12s
- Charge glow: 0.3 to 1.0, 10 particles, cyan energy
- Fire: 12 particles, shake 0.06
- Travel: cyan energy trail, glow 1.0, sparkles enabled, 5 particles/sec
- Pierce: 8 particles, sparkle effect
- Impact: 6 particles
- Speed: 520px/sec, Pierces all: True, Damage 1.4x
- Texture: 36x52 Additive
- Audio: pierce_arrow_fire.wav (charge), pierce_arrow_impact.wav
```

### Sky Fall
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Sky Fall" skill (Archer ULTIMATE).

SKILL DETAILS:
- Name: Sky Fall
- Type: Screen-wide arrow rain (ULTIMATE)
- Color: Deep Green [0.1, 0.5, 0.2, 1.0]
- Timings: Appear 0.3s | Rain 2.0s | Land 0.2s | Dissipate 0.5s
- Appear: 30 particles/sec, spawn top-to-full-width
- Rain: 20 visible arrows, 25 arrows/sec, 30% velocity randomness, 15° angle variance, acceleration down
- Land: 10 particles, impact marks, shake 0.15
- Dissipate: 5 particles, alpha 1.0 to 0.0
- Total arrows: 50, Speed range: 300-600px/sec
- Damage radius: 1600px, Covers screen
- Duration: 2.7s, Cooldown: 20s
- Texture: 256x256 Normal
- Audio: sky_fall_start.wav (appear), arrow_rain_loop.wav (rain), arrow_impact.wav (land)
```

---

## ASSASSIN SKILLS

### Star Knife
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Star Knife" skill (Assassin).

SKILL DETAILS:
- Name: Star Knife
- Type: Spinning projectile (1-3 star knives)
- Color: Purple-Gray Metallic [0.5, 0.3, 0.6, 1.0]
- Timings: Launch 0.12s | Spin 0.25s (loop) | Trail 0.8s | Impact 0.2s
- Launch: 8 particles, scale 0.5 to 1.0
- Spin: 1440°/sec, high sparkle
- Trail: purple-gray enabled, 5 particles/sec, metallic shine
- Impact: 15 particles, shake 0.08, sound enabled
- Speed: 480px/sec, Radius: 12px
- RPM: 1440, Damage: 35
- Texture: 52x52 Normal
- Audio: star_knife_throw.wav (launch), star_knife_impact.wav (impact)
```

### Knife Storm
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Knife Storm" skill (Assassin).

SKILL DETAILS:
- Name: Knife Storm
- Type: Spinning blade aura
- Color: Lavender with Purple Accents [0.7, 0.5, 1.0, 1.0]
- Timings: Activate 0.3s | Spin 0.4s (loop) | Damage 0.15s | Deactivate 0.4s
- Activate: 20 particles, 50px/sec expansion
- Spin: 900°/sec, 6 blades, 8 particles/sec, high velocity lines
- Damage burst: 12 particles, brightness flash, shake 0.06
- Deactivate: 180°/sec, alpha 1.0 to 0.0, 10 particles
- Radius: 70px, Max duration: 6.0s
- Texture: 96x96 Normal
- Audio: knife_storm_activate.wav (activate), knife_storm_loop.wav (loop)
```

### Boomerang Star
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Boomerang Star" skill (Assassin).

SKILL DETAILS:
- Name: Boomerang Star
- Type: Returning projectile (1-3 boomerang stars)
- Color: Golden Yellow Metallic [1.0, 0.84, 0.0, 1.0]
- Timings: Launch 0.1s | Outbound 0.6s | Peak 0.3s | Return 0.7s | Catch 0.2s
- Launch: 10 particles, scale 0.6 to 1.0
- Outbound: golden trail, 360° rotation, 120px arc height
- Peak: glow 1.0, 5 particles, pause visual
- Return: brighter trail, 1.3x speed, 720° rotation
- Catch: 8 particles, glow flash, chime
- Speed outbound: 400px/sec, return: 520px/sec
- Arc height: 120px, Max distance: 300px
- Damage: 30 per hit, Hits twice: True
- Texture: 56x56 Additive
- Audio: boomerang_throw.wav (launch), boomerang_return.wav (return), boomerang_catch.wav (catch)
```

### 7 Slash
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "7 Slash" skill (Assassin ULTIMATE).

SKILL DETAILS:
- Name: 7 Slash
- Type: Screen-wide slash combo (ULTIMATE)
- Color: Dark Red with Crimson Energy [0.8, 0.1, 0.1, 1.0]
- Timings: Prepare 0.2s | Slash 0.6s | Shockwave 0.4s | Impact 0.3s
- Prepare: fade enabled (0 to 0.3), 30 particles, danger sound
- Slash: 7 slashes at 0.085s interval, 0.15s expand/fade per slash, varied angles, crimson, shake 0.08/slash, 12 particles/slash
- Shockwave: 7 rings, 300px/sec, width 4px, crimson energy
- Impact: flash 0.5, shake 0.2, 50 particles
- Damage: 45 per slash, Damage radius: 1600px
- Duration: 1.5s, Cooldown: 25s, Covers screen
- Texture: 256x256 Additive
- Audio: seven_slash_start.wav (prepare), blade_slash.wav (slash), seven_slash_impact.wav (impact)
```

---

## SPECIAL SKILLS

### Swirl Tangerine (Special ULTIMATE)
```
You are a game animation designer for a Vampire Survivors-style roguelite game.
Generate detailed animation specifications for the "Swirl Tangerine" skill (Special ULTIMATE).

SKILL DETAILS:
- Name: Swirl Tangerine
- Type: Screen-wide energy cyclone (ULTIMATE)
- Color theme: Tangerine Orange [1.0, 0.55, 0.0, 1.0]
- Mechanic: Massive energy vortex covering entire screen, devastating damage
- Character: Special (Brown Capy)

ANIMATION STATES & TIMING:
1. Charge: 0.5s energy gathers, glow intensifies (0.2 to 1.0), spin-up begins (0 to 360 rotation)
2. Release: 0.3s sudden vortex appears, screen flash and shake (0.25), spiral expansion
3. Vortex: 3.0s main effect at full power, swirling motion, 540° rotation speed
4. Peak: 1.5s maximum damage zone, maximum intensity glow, 720° rotation speed, brightest
5. Dissipate: 1.0s spiral fade as energy disperses, alpha fade (1.0 to 0.0)

SPECIFICATIONS:
- Spiral rings: 5 concentric circles
- Spiral direction: Inward then outward
- Particle spawn rates: Charge (50), Release (80), Vortex (40), Peak (60), Dissipate (30)
- Screen coverage: Full screen (256x256 texture, covers entire viewport)
- Rotation mechanics: Charge 360°, Vortex 540°/sec, Peak 720°/sec
- Enemy knockback: 200 force units from vortex center
- Total duration: 5.8 seconds
- Cooldown: 30 seconds

VISUAL EFFECTS:
- Tangerine energy color with magical aura
- Powerful glow with intensity scaling
- Particle density: Very high
- Screen shake timing: Release (0.25), Peak (0.1)
- Final shimmer effect on dissipation

SOUND DESIGN:
- Charge: Magical charge-up (tangerine_cast.wav)
- Release: Vortex roar (tangerine_vortex.wav)
- Peak: Energy shimmer loop (tangerine_vortex.wav)
- End: Finale sound sting (tangerine_end.wav)

Format as JSON with animation states and timing values suitable for Godot implementation.
Include specific rotation speeds (540°, 720°), spiral ring count (5), and particle densities.
```

---

## USAGE

Feed each prompt individually to ChatGPT and request:
- Detailed JSON animation specifications
- Timing values in seconds
- Particle count suggestions
- Sound effects descriptions
- Visual effect breakdowns
- Frame-by-frame animation guidance

Example prompt usage:
```
[Copy one of the above prompts]
[Paste into ChatGPT chat]
[ChatGPT will generate detailed animation specs as JSON]
```
