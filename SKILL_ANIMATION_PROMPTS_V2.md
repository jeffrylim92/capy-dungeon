# BRILLIANT Skill Animation Prompts v2 - Fresh Creative Direction

These prompts are designed for STUNNING, never-before-seen visual effects. Not ports of old code—pure creative brilliance.

---

## COMMON SKILLS

### Capy Orb (Enhanced)
```
You are a brilliant VFX animator creating a premium roguelite game.
Design STUNNING animation specs for "Capy Orb" - orbiting protective shields with mystical energy.

CREATIVE VISION:
- THREE golden orbs that ORBIT the player in a perfect triangle formation
- Each orb trails SHIMMERING STARDUST that forms geometric patterns
- As orbs orbit, they leave EPHEMERAL STAR TRAILS that fade slowly
- Collision: orbs PULSE and emit a PRISMATIC NOVA burst

ANIMATION STATES:
1. Spawn (0.6s): Orbs materialize with SPIRAL ZOOM-IN effect, trailing golden sparks
2. Idle Orbit (2.5s loop): 180°/sec rotation, varying heights (3D parallax effect), sine-wave wobble
3. Idle Particles: 1 stardust particle/sec per orb, leaving ETHEREAL TRAILS
4. On Enemy Hit: Orb flares + SHOCKWAVE ripple + 40 burst particles + brief slowdown
5. Impact Shimmer (0.25s): Color shift cyan→white→gold, 0.2s screen shake

SPECIFICATIONS:
- Orbit radius: 85px (grows slightly at higher levels)
- Particle trails: 12 per orbit cycle, 0.8s fade
- Impact particles: 40 (star-shaped bursts)
- Glow intensity: 1.2 (increases with level)
- Wobble: Sine wave 8px amplitude, slight Z-axis rotation for 3D feel
- Color: Golden [1.0, 0.84, 0.29, 1.0] with brightness variance
- Audio: sparkle_trail.wav (quiet loop), orb_impact_chime.wav (on hit)

OUTPUT FORMAT: JSON with detailed state specs, particle counts, and timing.
```

### Capy Bolt (Reborn)
```
You are designing ELECTRIFYING visuals for a premium game.
Create AWE-INSPIRING specs for "Capy Bolt" - precision electrical strikes with Tesla coil energy.

CREATIVE VISION:
- Bolts that CRACKLE with electrical energy, leaving ionized AIR TRAILS
- Between cast and impact: BRANCHING LIGHTNING TENDRILS search for targets
- Impact: EXPLOSION of electrical sparks + EMP shockwave + brief screen GLITCH effect
- Multiple bolts create INTERFERENCE PATTERNS with arcing electricity between them

ANIMATION STATES:
1. Charge (0.25s): Coil-up animation, crackling sound, particle buildup (pulsing circles)
2. Release (0.15s): BOLT LAUNCH with COMPRESSED WAVE effect, 0.15s screen shake
3. Flight (1.0s): Continuous branching tendrils, traveling sparks, 0.8x screen brightness
4. Target Tracking: Bolts curve toward target with ELECTRIC LASSO animation
5. Impact (0.3s): STAR BURST of 60+ particles, 0.12s camera shake, brief CHROMATIC ABERRATION

SPECIFICATIONS:
- Charge particles: 25 per charge cycle, spiral pattern
- Flight sparks: 12/sec, branching tendrils from bolt center
- Impact burst: 60 particles (mixed sizes), spreading in star pattern
- Glow intensity: 1.5 (very bright)
- Screen shake: 0.15s on impact, 0.1s medium intensity
- Color: Bright Yellow [1.0, 0.94, 0.29] with electric blue arcs
- Speed: 480px/sec with smooth homing curve
- Audio: tesla_coil_charge.wav (charge loop), bolt_launch.wav (release), thunder_crack.wav (impact)

OUTPUT FORMAT: JSON with state-by-state breakdown.
```

### Ice Orb (Crystalline)
```
You are creating MESMERIZING frozen vistas for gameplay.
Design specs for "Ice Orb" - crystalline projectiles that SHATTER on impact with ICICLE showers.

CREATIVE VISION:
- Smooth translucent ICE ORB that ROTATES and refracts light
- Subtle FROST PARTICLE TRAILS behind projectile (snowflake-like)
- Impact: SHATTERS into 50+ icicle shards + ICE CRYSTAL BLOOM + freezing aura
- Frozen enemies surrounded by SWIRLING SNOWFLAKES that pulse with cold energy

ANIMATION STATES:
1. Spawn (0.3s): Ice crystal materializes with EXPANSION SHIMMER effect
2. Travel (1.5s): Steady rotation (180°/sec), frost trail particles, subtle pulse glow
3. Impact Shatter (0.4s): Sphere breaks apart, icicles spray outward + inward spiral
4. Freeze Aura (0.8s): Enemies surrounded by rotating snowflake particles, icy blue glow
5. Dissipate (0.6s): Remaining ice particles fade with SPARKLE effects

SPECIFICATIONS:
- Rotation speed: 200°/sec
- Frost trail: 4 particles/sec, 0.5s fade
- Impact icicles: 50 shards (varied sizes, mix inward/outward trajectories)
- Freeze particles: 30/sec around frozen enemies, rotating slow circles
- Glow intensity: 1.1 (cool, calm feel)
- Color: Cyan Blue [0.3, 0.8, 1.0] with white frost accents
- Freeze duration: 1.5s
- Audio: ice_crystal_travel.wav (loop), shatter_explosion.wav (impact), freeze_aura.wav (freeze loop)

OUTPUT FORMAT: JSON with particle specs and freeze mechanics.
```

### Mud Aura (Primordial)
```
You are crafting PRIMAL, ELEMENTAL effects for an ancient magic system.
Create "Mud Aura" specs - toxic earthen miasma that CORRUPTS enemies with POISON.

CREATIVE VISION:
- Swirling MUD VORTEX around player with NOXIOUS GAS CLOUDS
- Enemies in range: PURPLE CORRUPTION spreading across their form
- Aura PULSATES with sickly green glow, occasional TOXIC BUBBLE eruptions
- Particles FLOAT upward then drift away like toxic fumes

ANIMATION STATES:
1. Idle Swirl (1.5s loop): Mud particles orbit, 60°/sec, bobbing up/down
2. Pulse Burst (0.8s): Every 1.2s, sudden expansion + 20 poison particles + glow flash
3. Damage Tick (0.2s): Small particle burst at enemy location + brief purple flash
4. Corruption Spread (varies): Purple aura spreads across enemy sprite (shader effect hint)
5. Deactivate (0.4s): Mud settles, particles disperse upward

SPECIFICATIONS:
- Aura radius: 70px (grows +15px per level)
- Swirl speed: 70°/sec base, increases with level
- Idle particles: 6/sec swirling
- Pulse particles: 20 per pulse (green toxic color)
- Damage particles: 8 per tick, purple explosion
- Glow intensity: 0.9 (sickly, not bright)
- Wobble: ±10px amplitude, smooth sine wave
- Color: Deep Brown [0.4, 0.25, 0.1] + toxic green [0.3, 0.8, 0.2]
- Audio: swamp_loop.wav (ambient loop), poison_burst.wav (pulse), corruption_tick.wav (damage)

OUTPUT FORMAT: JSON with aura mechanics and corruption effects.
```

### Squeal Wave (Sonic Fury)
```
You are designing DEVASTATING shockwave effects that VISUALLY SCREAM power.
Create "Squeal Wave" - expanding sonic blast that DISTORTS space and SHATTERS.

CREATIVE VISION:
- EXPANDING CIRCULAR RINGS that WARP and DISTORT the screen behind them
- Purple energy rings with JAGGED EDGES that look VIOLENT and CHAOTIC
- Particles SPIN AWAY at high velocity, leaving TRAILING LIGHT
- Secondary RIPPLE WAVES that propagate after main wave passes
- Enemies knocked back with VISUAL IMPACT feedback

ANIMATION STATES:
1. Charge (0.4s): Building pressure, rings forming at center, particle buildup (circles spiraling inward)
2. Release (0.2s): EXPLOSIVE LAUNCH, screen shake 0.2s, initial ring expands rapidly
3. Expand (2.0s): 3 concentric rings at different speeds, each with 8 jagged edges
4. Dissipate (0.7s): Rings fade + secondary ripples shoot outward, final particles scatter
5. Impact Zone: Enemies in range get knocked back with WOBBLE camera effect

SPECIFICATIONS:
- Ring expansion: 280px/sec (main), 200px/sec (secondary), 150px/sec (tertiary)
- Ring width: 6px + jagged spikes (8px extensions)
- Jagged edges: 16 spikes per ring, rotating 45°/sec offset from ring
- Particle burst: 60 initial + 30/sec during expand phase
- Glow intensity: 1.4 (very bright, energetic)
- Knockback: 150 force units from wave center
- Screen shake: 0.2s release, 0.1s per impact, 0.15s medium
- Color: Purple [0.7, 0.3, 0.8] with bright magenta accents
- Audio: sonic_charge_loop.wav (charge), sonic_release_burst.wav (release), wave_expand_whoosh.wav (expand)

OUTPUT FORMAT: JSON with ring mechanics, distortion layers, and impact feedback.
```

### Capy Calm (Healing Light)
```
You are animating WARMTH, COMFORT, and RESTORATION magic.
Design "Capy Calm" - soothing regeneration aura that HEALS with LOVING LIGHT.

CREATIVE VISION:
- SOFT GLOWING PARTICLES that float upward from player
- Each tick: HEART-SHAPED or STAR-SHAPED particles rise gently with WARM trails
- Particles CONVERGE toward player when HP is low (visual "hungry" effect)
- Gentle PULSING GLOW around player, BREATHING in/out rhythm
- Enemies cannot enter the SAFE ZONE without taking aura damage

ANIMATION STATES:
1. Idle (1.0s loop): Gentle upward float particles, soft pink glow breathing (1.5s cycle)
2. Tick Heal (0.08s): Particle burst at player + brief glow flash + chime audio
3. Low HP Attract (when HP < 30%): Particles accelerate toward player in arcs
4. Enemy Proximity (0.3s): Aura flares + defensive particles move outward as barrier
5. Fade Out (0.5s): Particles slow and drift away

SPECIFICATIONS:
- Idle particles: 2/sec, rising 40px/sec upward
- Particle lifetime: 1.2s (rise then fade)
- Tick particles: 8 per heal tick, HEART SHAPE (or star)
- Low HP mode: Particle speed 2.0x normal, acceleration toward player
- Glow intensity: 0.8 (soft, calming)
- Breathing pulse: 0.3s expand + 0.3s contract, ±15% radius
- Aura radius: 65px base
- Color: Healing Pink [1.0, 0.5, 0.7] with white shimmer core
- Audio: healing_chime.wav (tick), soft_pulse_loop.wav (ambient breathing), danger_barrier.wav (enemy proximity)

OUTPUT FORMAT: JSON with healing tick mechanics and breathing pulse cycle.
```

### XP Magnet (Gravitational Pull)
```
You are designing POWERFUL ATTRACTION EFFECTS that MAGNETIZE the screen.
Create "XP Magnet" - powerful vacuum that PULLS resources with GRAVITATIONAL FORCE.

CREATIVE VISION:
- PULSING RINGS that CONTRACT inward, attracting particles visually
- CENTER VORTEX that SPINS and GLOWS with TEAL ENERGY
- When active: XP orbs CURVE toward player on SPIRAL PATHS
- Ring intensity INCREASES when many orbs are nearby (feedback)
- PARTICLE TORNADO effect in center that CONSUMES particles

ANIMATION STATES:
1. Idle (1.2s loop): 3 concentric rings pulse in/out, 30°/sec rotation, 4 particles/sec spiral inward
2. Activation Pulse (0.4s): Rings expand rapidly, center FLARES, 15 burst particles
3. Active Pull (duration): Rings spin faster (60°/sec), particles accelerate toward center
4. High Density (when many XPs near): Rings glow brighter, tornado effect intensifies
5. Fade (0.3s): Rings slow and fade, particles disperse

SPECIFICATIONS:
- Idle rings: 3 at 35px, 65px, 95px radius
- Pulse amplitude: ±12px inward/outward
- Ring rotation: 30°/sec idle, 60°/sec active, up to 100°/sec max density
- Spiral particles: 4/sec idle, 12/sec when active
- Particle velocity: 100px/sec spiral inward
- Center vortex: Small rotating core (1.5s full rotation)
- Glow intensity: 0.7 idle, 1.2 active, 1.5 max density
- Pull radius: Base 120px, expands to 200px when active
- Color: Teal Green [0.2, 0.9, 0.6] with white core
- Audio: magnet_idle_hum.wav (subtle loop), magnet_activate_pulse.wav (activation), pull_vacuum_loop.wav (active)

OUTPUT FORMAT: JSON with attraction mechanics and ring dynamics.
```

---

## WIZARD SKILLS

### Fireball (Infernal Comet)
```
You are creating APOCALYPTIC FIRE MAGIC with DEVASTATING visual impact.
Design "Fireball" specs - BLAZING meteors that IGNITE the screen with HELLFIRE.

CREATIVE VISION:
- 2-4 GLOWING FIREBALLS that ORBIT in ELLIPTICAL PATHS (not circles—MORE DYNAMIC)
- Each fireball leaves TRAILS OF EMBERS and SMOKE CLOUDS that linger
- Collision: MASSIVE EXPLOSION with MUSHROOM CLOUD effect, FIRE RINGS, HEAT DISTORTION
- Secondary projectiles: burning embers scatter and CURVE back (boomerang effect)
- Screen FLASHES white on impact (intensity based on level)

ANIMATION STATES:
1. Spawn (0.5s): Fireball materializes with EXPANSION FLARE, orbit path establishes
2. Orbit (1.8s loop): ELLIPTICAL path (not circular), 150°/sec rotation, varying speed
3. Ember Trail (continuous): 3 embers/sec, 0.6s fade, CURVED downward trails
4. Smoke Puffs: 1 smoke per 0.3s, drifts upward slowly
5. Impact Explosion (0.5s): Fireball shatters into 80 particles, HEAT WAVE distortion, RING BLAST

SPECIFICATIONS:
- Orbit count: 2-4 fireballs (level dependent)
- Orbit path: Elliptical 90px × 60px
- Orbit speed: 180°/sec base + 30°/sec per level
- Ember count: 3/sec per fireball
- Impact particles: 80 (mixed debris + fire)
- Explosion rings: 3 expanding fire rings at 400px/sec
- Heat distortion: Wavy screen effect 0.3s duration
- Screen flash: White 0.8 opacity, 0.1s duration
- Glow intensity: 1.3 (very bright)
- Color: Orange [1.0, 0.33, 0.0] with red flames [1.0, 0.1, 0.0]
- Audio: fireball_orbit_loop.wav (quiet), fireball_impact_explosion.wav, heat_wave.wav

OUTPUT FORMAT: JSON with elliptical orbit paths and explosion mechanics.
```

### Elec Shockwave (Tesla Tempest)
```
You are crafting ELECTRIFYING effects that make the SCREEN CRACKLE with ENERGY.
Create "Elec Shockwave" - DEVASTATING electrical pulse with CHAIN LIGHTNING.

CREATIVE VISION:
- Expanding JAGGED electrical rings that CRACKLE and BRANCH outward
- BRANCHING LIGHTNING BOLTS shoot from player toward enemies in ring
- Screen FLICKERS with CHROMATIC ABERRATION (red/cyan shift)
- Enemies hit: PARALYSIS effect (visual stutter animation)
- CHAIN REACTIONS: each hit enemy releases secondary electrical tendrils

ANIMATION STATES:
1. Charge (0.3s): Coil-up, crackling buildup, 30 spiral particles inward, screen darkens slightly
2. Release (0.15s): EXPLOSIVE discharge, 0.2s screen shake, all screen flickers
3. Ring Expand (1.8s): 4 expanding jagged rings, 350px/sec each with staggered timing
4. Lightning Branch (0.4s staggered): 6-8 bolts shoot toward enemies, BRANCHING tendril effects
5. Chain Hit (0.2s per hit): Secondary shockwave from hit enemy, 0.1s flicker

SPECIFICATIONS:
- Charge particles: 30 spiral inward, pulsing acceleration
- Ring count: 4 expanding simultaneously at slightly different speeds
- Ring width: 5px + 6px jagged spikes (12 per ring)
- Lightning bolts: 6-8 branches at 500px/sec, seeking enemies
- Branch particles: 2 bolts create 20-30 particle trail
- Screen flicker: 6 flickers per 0.2s (fast, intense)
- Chromatic aberration: Red/cyan shift ±4px
- Paralysis stutter: 0.1s freeze animation on hit enemies
- Chain radius: 80px from each hit (recursion 1 level deep)
- Glow intensity: 1.6 (VERY bright)
- Color: Electric Yellow [1.0, 1.0, 0.2] + bright cyan arcs
- Audio: tesla_coil_charge_loop.wav (charge), discharge_burst.wav (release), chain_lightning.wav (chain)

OUTPUT FORMAT: JSON with branching mechanics and screen distortion specs.
```

### Hurricane (Vortex Maelstrom)
```
You are designing CHAOTIC WIND MAGIC that DOMINATES the screen with SPINNING FURY.
Create "Hurricane" specs - MASSIVE spinning vortex that SHREDS and THROWS enemies.

CREATIVE VISION:
- HUGE TORNADO vortex that ROTATES at BLINDING SPEED
- Concentric SPIRAL RINGS that COMPRESS inward then EXPLODE outward (breathing effect)
- Wind PARTICLE TRAILS that SPIRAL upward in chaotic spirals
- Enemies CAUGHT in tornado: brief LEVITATION effect + SPIN animation
- Secondary MINI-TORNADOS orbit the main vortex like satellites

ANIMATION STATES:
1. Activate (0.5s): Vortex materializes with EXPANSION SHOCKWAVE, initial ring setup
2. Spin Intense (2.0s loop): MULTIPLE LAYERS spinning at different speeds, rings breathing (compress/expand)
3. Mini-Tornado Orbit (continuous): 3-4 smaller tornados orbit main vortex, 180°/sec
4. Wind Particles (continuous): 8 particles/sec in chaotic upward spirals
5. Dissipate (0.7s): Vortex slows, rings fade, particles disperse

SPECIFICATIONS:
- Main vortex rotation: 540°/sec (VERY FAST)
- Ring count: 5 concentric rings at 25px spacing
- Breathing cycle: 0.8s expand + 0.8s contract (±8px amplitude)
- Mini-tornado count: 3-4, orbit at 180°/sec around main vortex at 60px radius
- Wind particles: 8/sec, spiral paths (not straight), upward drift 60px/sec
- Knockback force: 180 units from center
- Levitation duration: 0.4s (visual lift + slow rotation)
- Screen shake: 0.15s medium intensity (continuous during active)
- Glow intensity: 1.4 (intense, dynamic)
- Color: Light Blue [0.6, 0.9, 1.0] with white center core
- Audio: tornado_spin_intense.wav (loud loop), wind_whoosh.wav (particles), levitation_effect.wav (enemy caught)

OUTPUT FORMAT: JSON with multi-layer vortex mechanics and breathing cycle.
```

### Blizzard (Eternal Winter)
```
You are creating APOCALYPTIC ICE MAGIC that FREEZES the WORLD in place.
Design "Blizzard" specs - SCREEN-COVERING ice storm with TOTAL FROZEN LANDSCAPE.

CREATIVE VISION:
- MASSIVE snowflake particles filling screen (20+ large snowflakes visible at once)
- ICICLE RAIN that falls from top, accumulating effect (visual buildup)
- Frozen enemies: ICE CRYSTAL SHELLS form around them with SHIMMER effect
- Background DARKENS and COOLS (blue tint overlay)
- OCCASIONAL MASSIVE ICICLES (100px+) fall and create SHOCKWAVE impact

ANIMATION STATES:
1. Charge (0.6s): Sky darkens, first snowflakes appear, buildup particles spiral down
2. Release (0.3s): EXPLOSION of snowflakes, 0.3s screen shake, temperature PLUMMETS (visual effect)
3. Peak Storm (2.5s): Continuous snowfall, icicle rain intensifies, enemies freeze, world tinted blue
4. Large Icicle Phase: Every 0.5s a massive icicle falls, creates IMPACT shockwave
5. Dissipate (0.8s): Snowfall slows, particles settle, blue tint fades, frozen enemies begin to thaw

SPECIFICATIONS:
- Large snowflakes: 25-30 visible, 40px size, drifting down + slight side-to-side
- Small snowflakes: 100+, 10px size, faster fall (layered parallax)
- Snowfall speed: 120px/sec large, 200px/sec small
- Icicle rain: 15 icicles/sec during peak, 30px-80px size, varied speed
- Large icicles: 1 per 0.6s, 100-150px size, creates 0.2s screen shake on impact
- Impact shockwaves: 3 expanding rings per large icicle, 300px/sec
- Freeze effect: 30 crystal particles around frozen enemy, rotating
- Blue tint overlay: 0.4 opacity, gradually fades
- Glow intensity: 1.2 (cool, icy feel)
- Slow effect: 50% enemy speed during blizzard
- Color: Pale Cyan [0.5, 0.9, 1.0] with white ice accents
- Audio: blizzard_wind_loop.wav (intense), snowfall_cascade.wav (continuous), icicle_impact.wav (impact), freeze_crystallize.wav (freeze)

OUTPUT FORMAT: JSON with multi-layer snowfall, icicle mechanics, and environmental effects.
```

---

## ARCHER SKILLS

### Arrow Shot (Piercing Light)
```
You are designing PRECISE, POWERFUL archery magic with STUNNING VISUAL CLARITY.
Create "Arrow Shot" specs - GLEAMING arrows that PIERCE with RADIANT LIGHT.

CREATIVE VISION:
- Single GLOWING ARROW with TRAILING LIGHT RIBBON behind it
- Arrow ROTATES to match trajectory, POINTS directly at target
- GOLDEN LIGHT TRAIL follows arrow path, fading behind it
- Impact: Arrow EXPLODES into RADIANT LIGHT BURST + GREEN LIGHT WAVES
- PIERCE EFFECT: Light shoots through enemies in a LINE of impact markers

ANIMATION STATES:
1. Draw (0.15s): Arrow materializes at player, scales up 0.3→1.0, glow builds
2. Release (0.1s): Arrow launches with SHOCKWAVE particle burst, brief camera shake
3. Flight (0.9s): Arrow rotates to match trajectory, light trail follows (0.2s fade)
4. Pre-Impact (0.1s): Arrow GLOWS brighter as target approaches
5. Impact (0.25s): Arrow shatters + 40 radiant burst particles + light waves + pierce line effect

SPECIFICATIONS:
- Arrow rotation: Aligns to trajectory angle perfectly (3D billboard effect)
- Light trail: 6 particles/sec, 0.2s fade, golden glow
- Flight speed: 520px/sec
- Impact particles: 40 radiant bursts (star-shaped, outward spreading)
- Light waves: 3 concentric waves at 400px/sec (like ripples)
- Pierce line: 2-4 enemies in line each get small impact marker (bright flash)
- Glow intensity: 1.3 (very bright and radiant)
- Screen shake: 0.08s light shake on impact
- Color: Forest Green [0.2, 0.6, 0.2] with golden light accents
- Audio: arrow_draw_tension.wav (draw), arrow_release_twang.wav (release), arrow_flight_whistle.wav (flight), radiant_impact.wav (impact)

OUTPUT FORMAT: JSON with trajectory alignment and pierce mechanics.
```

### Split Arrow (Fan Barrage)
```
You are crafting EXPLOSIVE ARROW PATTERNS that FILL the SCREEN with PROJECTILES.
Design "Split Arrow" specs - FAN-SPREAD arrows that CREATE VISUAL SPECTACLE.

CREATIVE VISION:
- 5-7 ARROWS spread in FAN PATTERN (60° spread)
- Each arrow TRAILS LIGHT with slightly DIFFERENT COLORS (color variance)
- Arrows CURVE slightly as they fly (not perfectly straight—MORE ORGANIC)
- Impact: Each arrow creates SMALL EXPLOSION, secondary particles spread radially
- VISUAL FEEDBACK: arrows create a LIGHT SHOW of intersecting trails

ANIMATION STATES:
1. Release (0.15s): 5-7 arrows spread simultaneously in fan pattern, 0.1s shake
2. Flight (1.0s): Arrows spread further apart (fan opens), each trails light (0.3s fade)
3. Curved Paths: Each arrow curves slightly based on angle (organic ballistics)
4. Pre-Impact: Arrows glow brighter approaching targets
5. Staggered Impact (0.15s spread): Each arrow impacts separately, 20 particles per arrow

SPECIFICATIONS:
- Arrow count: 5 base, +1 per level (up to 7)
- Spread angle: 60° total (30° each side of center)
- Arrow speed: 480px/sec each (parallel trajectories)
- Curve amount: 5-15px side deflection over flight (organic feel)
- Trail color variance: Green base + color shifts per arrow (lime, forest, teal variants)
- Trail particles: 4/sec per arrow, 0.3s fade
- Impact particles: 20 per arrow (smaller bursts than single arrow)
- Stagger: 0.03s delay between arrow impacts
- Glow intensity: 1.2 per arrow (compound effect is bright)
- Screen shake: 0.08s on first impact, 0.04s for others
- Color: Lime Green [0.4, 0.8, 0.3] with variance per arrow
- Audio: multi_arrow_draw.wav (draw, layered), arrows_release_burst.wav (release), arrow_flight_cluster.wav (flight), multiple_impacts.wav (staggered)

OUTPUT FORMAT: JSON with fan spread geometry and staggered impact mechanics.
```

### Pierce Arrow (Crystalline Spear)
```
You are designing PENETRATING ICY MAGIC with TRANSCENDENT BEAUTY.
Create "Pierce Arrow" specs - CRYSTALLINE projectile that PIERCES ALL and SHATTERS on impact.

CREATIVE VISION:
- Single MASSIVE GLOWING ARROW made of ICE CRYSTALS
- Arrow REFRACTS LIGHT creating PRISMATIC LENS FLARE
- Travels in STRAIGHT LINE piercing MULTIPLE ENEMIES
- Each enemy pierced: CYAN LIGHT TRAIL left behind
- Impact/Exit: SHATTERING CRYSTAL BURST from both ends

ANIMATION STATES:
1. Charge (0.12s): Arrow charges with cyan energy, crystalline texture forms, 20 particles spiral
2. Release (0.1s): Arrow launches with SONIC BOOM effect, 0.15s screen shake
3. Flight (1.2s): Arrow travels straight, REFRACTIVE LENS FLARE trails behind, particles stream
4. Pierce Hit (per enemy): Brief glow flash at impact point + cyan trail left at enemy
5. Exit Impact (0.3s): Arrow exits screen/hits boundary, MASSIVE shattering burst

SPECIFICATIONS:
- Arrow size: Large (50px length visualization)
- Flight speed: 560px/sec (fastest)
- Lens flare: 4-6 lens artifacts, trailing behind arrow
- Lens flare particles: 8/sec, 0.4s fade
- Pierce count: All enemies in line (no limit)
- Per-pierce effect: Cyan flash + 5 particle sparkles at impact point
- Exit burst: 80 crystal shards + 5 expanding crystal waves
- Crystal wave speed: 450px/sec
- Glow intensity: 1.5 (VERY bright, prismatic)
- Screen shake: 0.15s release, 0.08s per enemy pierced (cumulative)
- Color: Teal [0.2, 1.0, 0.8] with cyan highlights + white lens flare
- Audio: ice_crystal_charge_hum.wav (charge), sonic_boom_release.wav (release), piercing_whoosh.wav (flight), crystal_shatter_exit.wav (exit)

OUTPUT FORMAT: JSON with pierce-through mechanics and refractive lens effects.
```

### Sky Fall (Arrow Apocalypse)
```
You are creating APOCALYPTIC RAIN OF ARROWS - DEVASTATING visual deluge.
Design "Sky Fall" specs - SCREEN-COVERING arrow bombardment with ENVIRONMENTAL IMPACT.

CREATIVE VISION:
- 50+ ARROWS falling from sky in COORDINATED PATTERNS (not random—PURPOSEFUL)
- Arrows fall in WAVES (visual rhythm), creating VISUAL PATTERNS
- Each impact: SMALL EXPLOSION + DUST CLOUD + IMPACT MARK that PERSISTS
- Screen FLOODS with arrows in arc patterns, creating LIGHT SHOW
- Ground ACCUMULATES arrow impact marks (visual persistence)

ANIMATION STATES:
1. Appear (0.4s): Sky DARKENS, arrows materialize top-to-bottom, 30 arrows/sec appear
2. Arrow Fall (2.5s): 50 total arrows fall at 400px/sec, arranged in WVE PATTERNS
3. Continuous Rain: Every 0.3s a NEW WAVE of 10-15 arrows (layered falling)
4. Impact Rain (staggered): Arrows hit ground over 1.5s, each creates DUST + MARK
5. Dissipate (0.6s): Remaining arrows clear, impact marks fade

SPECIFICATIONS:
- Total arrows: 50-60 (level dependent)
- Visible arrows at once: 15-20
- Fall speed: 380px/sec (varied: 300-450px/sec per arrow for organic feel)
- Wave pattern: Arrows arranged in ARCS/CIRCLES as they fall (not random chaos)
- Waves: 5 waves spaced 0.5s apart
- Impact explosion: 12 particles per arrow, spreading outward
- Dust clouds: 2-3 dust puffs per impact, 0.8s fade + upward drift
- Impact marks: Ground texture change (visual decal), 3s persistence
- Arrows per impact mark area: 2-3 arrows stick in ground visually
- Screen coverage: Eventually fills 70-80% of screen area
- Glow intensity: 1.1 (moderate, world-filling)
- Color: Deep Green [0.1, 0.5, 0.2] with brown impact marks
- Audio: arrows_appear_whistle.wav (appear), arrow_rain_loop.wav (fall), ground_impact_multi.wav (impacts, layered), dust_cloud.wav (dust)

OUTPUT FORMAT: JSON with wave pattern geometry and environmental persistence.
```

---

## ASSASSIN SKILLS

### Star Knife (Spinning Death)
```
You are designing LETHAL, GRACEFUL spinning blade effects with MESMERIZING MOTION.
Create "Star Knife" specs - PRECISE spinning star projectile with METALLIC SHEEN.

CREATIVE VISION:
- Single 6-pointed STAR KNIFE that SPINS at HYPNOTIC SPEED
- METALLIC SHINE reflects light dynamically, creating GLINT FLASHES
- Trails PARTICLE VORTEX behind it (spiraling trails)
- Impact: Star EMBEDS in surface, radiates shockwave + METALLIC SHATTER
- RICOCHET effect: Can bounce off hard surfaces (visual feedback)

ANIMATION STATES:
1. Launch (0.15s): Star materializes, initial spin acceleration, 8 launch particles
2. Flight (1.0s): Star spins at 1440°/sec, METALLIC GLINTS every 0.1s, particle vortex trails
3. Ricochet (optional): If hits hard surface, bounce animation + secondary spiral
4. Impact (0.3s): Star embeds with SHOCKWAVE, 35 particles radiate, metallic shatter sound
5. Embed Persist: Star briefly remains embedded (0.5s) before fading

SPECIFICATIONS:
- Spin speed: 1440°/sec (4 rotations/sec—VERY FAST)
- Metallic glints: Flash every 0.08s, bright white brief flare
- Glint count: 4-6 glints visible in rotation
- Particle vortex: 5 particles/sec in SPIRAL trails (0.4s fade)
- Flight speed: 520px/sec
- Impact particles: 35 metallic bursts (sharp, angled trajectories)
- Shockwave: 2 expanding waves at 350px/sec
- Ricochet bounce: 0.7x speed after bounce, changed angle
- Embed visual: Star graphic rotates in place (0.5s before fade)
- Glow intensity: 1.2 (metallic shine)
- Screen shake: 0.08s on impact
- Color: Purple-Gray [0.5, 0.3, 0.6] with white metallic accents
- Audio: star_knife_spin_whoosh.wav (flight, Doppler effect), metallic_glint.wav (glints), impact_embed.wav (impact), ricochet_bounce.wav (bounce)

OUTPUT FORMAT: JSON with spin mechanics, glint system, and ricochet physics.
```

### Knife Storm (Whirlwind Massacre)
```
You are designing CHAOTIC MELEE MAGIC that SHREDS enemies with SPINNING FURY.
Create "Knife Storm" specs - MASSIVE spinning blade aura with VIOLENT ENERGY.

CREATIVE VISION:
- 6-8 SPINNING BLADES orbiting player in TIGHT VORTEX
- Blades ACCELERATE in WAVES (fast then slow, creating RHYTHM)
- When enemy enters: BLADES TARGET and CHASE enemy before returning
- Trails GLOWING SLASH MARKS that linger briefly (VIOLENCE feedback)
- Player briefly INVULNERABLE during storm (visual aura protection)

ANIMATION STATES:
1. Activate (0.4s): Blades materialize and SPIRAL INTO ORBIT, 25 particles spiral inward
2. Active Spin (6.0s): Blades orbit at varying speeds, periodic acceleration BURSTS
3. Acceleration Wave (every 1.0s): Blades suddenly spin FASTER for 0.3s (visual feedback)
4. Enemy Target (0.5s): Nearest enemy targeted, blades CHASE before returning
5. Deactivate (0.5s): Blades SPIRAL OUTWARD and fade, final particle burst

SPECIFICATIONS:
- Blade count: 6-8 (level dependent)
- Orbit radius: 75px
- Base spin speed: 900°/sec (continuous)
- Acceleration bursts: +300°/sec for 0.3s every 1.0s
- Acceleration wave particles: 12 particles per burst
- Targeting: Locks onto closest enemy within 150px
- Chase distance: Blades pursue target up to 100px away, return after
- Chase speed boost: 1.5x normal rotation speed
- Slash marks: 3 lingering slashes per enemy hit, 0.4s fade
- Invulnerability: 20% damage reduction during active
- Particle count: 8/sec continuous orbit trails
- Glow intensity: 1.4 (intense, active, dangerous looking)
- Screen shake: 0.06s light shake per acceleration burst
- Color: Lavender [0.7, 0.5, 1.0] with bright purple blade highlights
- Audio: knife_storm_spin_intense.wav (continuous, Doppler effect), acceleration_burst.wav (bursts), blade_whoosh.wav (flight), enemy_target_lock.wav (targeting)

OUTPUT FORMAT: JSON with orbital mechanics, targeting system, and acceleration waves.
```

### Boomerang Star (Returning Comet)
```
You are designing SATISFYING RETURN-TRAJECTORY magic with TRIUMPHANT VISUAL ARC.
Create "Boomerang Star" specs - GOLDEN projectile that RETURNS to player with ARC PHYSICS.

CREATIVE VISION:
- Single GOLDEN STAR that LAUNCHES in ARC toward target
- GOLDEN TRAIL follows outbound path, BRIGHTER on return
- Mid-flight: Star GLOWS BRIGHTLY at arc peak (moment of triumph)
- Return path: Curves back to player in DRAMATIC ARC with ACCELERATION
- CATCH animation: Player catches with PARTICLE EXPLOSION + CHIME

ANIMATION STATES:
1. Launch (0.12s): Star scales 0.5→1.0, golden glow builds, 10 launch particles
2. Outbound Arc (0.8s): Star follows parabolic arc, golden trail (0.3s fade), arc height increases
3. Arc Peak (0.3s): Moment at apex, star GLOWS MAXIMUM brightness, brief pause effect
4. Return Arc (1.0s): Star curves back toward player, trail BRIGHTENS, acceleration increases
5. Catch (0.25s): Star reaches player, PARTICLE BURST around player + CHIME audio + brief glow flash

SPECIFICATIONS:
- Launch speed: 450px/sec outbound
- Arc height: 150px (impressive arc)
- Outbound trail: 5 particles/sec, golden glow (0.3s fade)
- Return trail: 8 particles/sec, BRIGHTER golden (0.2s fade)
- Return speed: 600px/sec (accelerating—faster on return)
- Peak glow: 1.8x brightness at apex (MAXIMUM)
- Peak duration: 0.3s pause at arc apex
- Catch particles: 40 particles radiating from player
- Catch glow flash: Brief white flash + 0.15s medium screen shake
- Multi-hit: Hits enemies twice if trajectory passes through multiple (outbound + return)
- Glow intensity: 1.2 base, 1.8 at peak
- Color: Golden Yellow [1.0, 0.84, 0.0] with bright white peak glow
- Audio: boomerang_launch_whistle.wav (launch), boomerang_arc_loop.wav (flight), arc_peak_chime.wav (peak), boomerang_return_accelerate.wav (return), catch_triumph.wav (catch)

OUTPUT FORMAT: JSON with parabolic arc physics and catch mechanics.
```

### 7 Slash (Ninja Fury)
```
You are crafting DEVASTATING MELEE COMBO effects with RAPID STRIKE FEEDBACK.
Design "7 Slash" specs - SCREEN-FILLING 7-hit combo with VISUAL SLASH EXPLOSION.

CREATIVE VISION:
- SEVEN MASSIVE SLASH ARCS that appear in RAPID SUCCESSION
- Each slash: VIOLENTLY expanding arc, followed by SHOCKWAVE
- Slashes arranged in VARIED ANGLES (360° coverage, overlapping)
- SCREEN FLASHES bright red on each slash (danger/impact feedback)
- MASSIVE FINAL EXPLOSION where all slashes CONVERGE at screen center

ANIMATION STATES:
1. Prepare (0.25s): Player GLOWS red ominously, danger particles spiral inward
2. Slash 1-6 (0.1s each): Individual slashes appear, arc from center outward, SHOCKWAVE follows
3. Slash 7 (0.15s): FINAL SLASH appears with TRIPLE intensity (3 overlapping slashes)
4. Convergence (0.2s): All shockwaves CONVERGE at center, MASSIVE explosion
5. Impact Aftermath (0.3s): Screen flashes, enemies knocked back, final particle burst

SPECIFICATIONS:
- Slash count: 7 slashes over 0.75s (at 0.1s intervals, last at 0.15s)
- Slash angle spacing: 51° apart (covering ~360°)
- Slash expansion speed: 450px/sec outward
- Slash arc width: 60px
- Slash glow: Bright crimson red, 1.6 intensity
- Screen flash: Red overlay, 0.5 opacity, 0.08s per slash
- Shockwave: 1 expanding ring per slash at 380px/sec, 4px width
- Final slash: 3 overlapping slashes at different rotations (TRIPLED visual impact)
- Convergence shockwaves: All 7 rings meet at center, MASSIVE burst
- Final burst particles: 100+ particles radiating from center, mixed velocities
- Knockback force: 200 units from screen center (POWERFUL)
- Screen shake: 0.08s per slash, 0.2s intense on convergence
- Damage radius: Full screen coverage (1600px)
- Color: Dark Red [0.8, 0.1, 0.1] with bright crimson accents
- Audio: slash_preparation.wav (prepare), rapid_slash_combo.wav (slashes, accelerating), shockwave_impact.wav (shockwaves), convergence_explosion.wav (convergence), enemy_knockback.wav (knockback)

OUTPUT FORMAT: JSON with multi-slash choreography and convergence mechanics.
```

---

## SPECIAL SKILLS

### Swirl Tangerine (Orange Apocalypse)
```
You are designing THE MOST VISUALLY STUNNING ultimate ability - WORLD-ENDING POWER.
Create "Swirl Tangerine" specs - SCREEN-DOMINATING energy cyclone that RESHAPES REALITY.

CREATIVE VISION:
- MASSIVE SPIRALING VORTEX covering ENTIRE SCREEN
- 5 CONCENTRIC SPIRAL RINGS rotating at DIFFERENT speeds (layered chaos)
- PARTICLE TORNADO that CONSUMES screen space (100+ particles visible)
- Screen WARPS and DISTORTS around vortex (reality bending effect)
- SECONDARY VORTICES orbit the main vortex like satellites
- Final CONVERGENCE: Energy spirals inward, explodes outward

ANIMATION STATES:
1. Charge (0.7s): Screen darkens to orange tint, vortex forms from center outward, 60 spiral particles inward
2. Release (0.4s): MASSIVE SHOCKWAVE bursts from center, 0.3s intense screen shake, screen flickers
3. Peak Vortex (3.5s): Main vortex at full power, layered rings spin, satellite vortices orbit, particle tornado
4. Intensity Wave (1.5s): Vortex suddenly accelerates, rings glow brighter, secondary burst of particles
5. Convergence (1.2s): All rings compress inward, particles ACCELERATE toward center, final EXPLOSION outward

SPECIFICATIONS:
- Ring count: 5 concentric at 80px, 160px, 240px, 320px, 400px radius
- Ring 1 spin: 540°/sec
- Ring 2 spin: 400°/sec (opposite direction)
- Ring 3 spin: 600°/sec (same as ring 1)
- Ring 4 spin: 350°/sec (opposite)
- Ring 5 spin: 720°/sec (FASTEST, opposite)
- Ring width: 8px + jagged spikes (20px extensions)
- Spike count: 24 per ring (VERY dense)
- Satellite vortices: 4 smaller vortices orbiting at 180°/sec, 200px radius
- Satellite ring count: 2 per vortex, 20px spacing
- Particle tornado: 15 particles/sec continuous, spiraling upward in helix
- Particle velocity: 100px/sec spiral + 80px/sec upward
- Screen distortion: WAVE distortion ±8px amplitude, time-varying
- Screen warp: Concentric radial warp toward vortex center (lens effect)
- Convergence: All particles accelerate to center at 2.0x speed over 0.6s
- Convergence explosion: 150+ particles radiate outward at high velocity (500px/sec)
- Orange tint overlay: Gradually brighten 0→0.6 opacity during charge/peak
- Glow intensity: 1.8 base, 2.2 at peak intensity wave (MAXIMUM BRIGHT)
- Knockback force: 250 units from center (DEVASTATING)
- Screen shake: 0.2s initial release, 0.1s continuous light shake during peak, 0.3s intense during convergence
- Color: Tangerine Orange [1.0, 0.55, 0.0] with bright golden highlights + white core
- Audio: tangerine_charge_buildup.wav (charge, crescendo), vortex_roar_release.wav (release), vortex_spin_loop.wav (peak, intense), vortex_intensity_wave.wav (intensity wave), convergence_final.wav (convergence), apocalypse_explosion.wav (final explosion)

OUTPUT FORMAT: JSON with multi-layer spiral mechanics, satellite vortex orbits, screen distortion systems, and convergence dynamics.
```

---

## SUBMISSION INSTRUCTIONS

For each skill prompt above:
1. Feed to ChatGPT individually
2. Request: **Detailed JSON animation specifications**
3. Ask for: State-by-state breakdown, exact particle counts, timing values, all specs from creative vision
4. Expect: Complete JSON ready for Godot 4.x implementation with all values specified

These prompts prioritize **VISUAL BRILLIANCE** over mechanical port-overs. Each effect should be STUNNING and MEMORABLE.
