# Capy Dungeon Skill Asset Generation Prompts

This document contains AI-friendly prompts for generating skill assets (particles, effects, animations) for Godot integration. Each prompt is designed to produce cohesive visual effects that match the skill's theme and color scheme.

---

## Common Skills (All Characters)

### 🟡 Capy Orb
**Color**: `Color(0.98, 0.72, 0.08)` (Golden Yellow)

**Description**: Orbiting damage balls circling the player with high impact

**Texture/Particle Prompt**:
> Generate a golden-yellow glowing orb particle effect for a dungeon game. The orb should be round, smooth, and emit warm light. Include a subtle trailing glow and sparkle effect as it moves through the air. The orb should appear solid yet ethereal, with a bright yellow core surrounded by a softer golden halo. Size: 32x32 pixels, alpha channel, seamless tileable texture with glow. Art style: pixel art meets particle effect.

**Animation Timeline**:
- Entrance: 0.2s fade-in with scale-up
- Loop: Orbiting path with 1-2s cycle time
- Impact: 0.3s expand + fade flash effect

---

### ⚡ Capy Bolt
**Color**: `Color(1.0, 0.88, 0.10)` (Bright Yellow)

**Description**: Auto-targeting lightning projectiles

**Texture/Particle Prompt**:
> Create a high-voltage lightning bolt projectile for a game. The bolt should be bright yellow with electric effects. Include jagged lightning trails and crackling energy around the edges. The bolt tapers from thick at the base to thin at the tip. Add subtle electric arc effects and particle sparks. Dimensions: 16x64 pixels (portrait), alpha channel. The effect should suggest motion and high energy. Art style: pixel art with electric glow effects.

**Animation Timeline**:
- Fire: 0.1s charge glow
- Travel: 0.15s fast arc with trail
- Impact: 0.2s explosion with electric sparks radiating outward

---

### ❄️ Ice Orb
**Color**: `Color(0.60, 0.90, 1.0)` (Cyan Blue)

**Description**: Straight-line freeze orbs that slow enemies

**Texture/Particle Prompt**:
> Design a cyan ice orb projectile with a frosted glass appearance. The orb should have visible icicles radiating outward and a crystalline interior pattern. Include a frosty mist effect around it and icy sparkles. The colors should range from light cyan to deeper blue. Add subtle snowflake particles trailing behind. Dimensions: 28x28 pixels, alpha channel, smooth gradients. Style: crystalline and elegant with cold atmosphere.

**Animation Timeline**:
- Spawn: 0.15s grow with frost particles
- Travel: Straight line movement with trailing mist
- Freeze Zone: 0.4s radius circle with icy shimmer effect

---

### 🟤 Mud Aura
**Color**: `Color(0.52, 0.36, 0.18)` (Deep Brown)

**Description**: Continuous damage aura around the player

**Texture/Particle Prompt**:
> Create a muddy brown protective aura particle effect. The aura should feel earthy and grounded with swirling mud patterns. Include organic flowing shapes, swirling particles, and a slight gravitational feel pulling inward. Colors: browns, tans, and dark earth tones. Add occasional small rock or dirt particle sparkles. Dimensions: 256x256 pixels (radial gradient), alpha channel. Style: organic, fluid, natural earth magic.

**Animation Timeline**:
- Idle: Slow rotating swirl animation (3-4s cycle)
- Hit: Brief color intensification and pulse outward
- Duration: Continuous while skill is active

---

### 💜 Squeal Wave
**Color**: `Color(0.72, 0.46, 1.0)` (Purple)

**Description**: Periodic shockwave projectile

**Texture/Particle Prompt**:
> Generate a purple shockwave ring effect expanding outward. The wave should look like ripples in water but with magical purple energy. Include concentric rings that fade with distance, with bright centers fading to transparent edges. Add small purple sparkle particles along the wave front. Dimensions: 512x512 pixels (radial), alpha channel for transparency gradient. Style: magical energy blast, ethereal and powerful.

**Animation Timeline**:
- Spawn: 0.05s appear at player position
- Expand: 1.0s radial expansion at constant speed
- Fade: 0.3s fade-out at edges while expanding

---

### ❤️ Capy Calm (Regen)
**Color**: `Color(0.90, 0.32, 0.42)` (Rose Red)

**Description**: HP regeneration passive buff

**Texture/Particle Prompt**:
> Create a soothing rose-red healing particle effect. Small gentle particles should float upward with a calming motion. Include soft glows and a nurturing energy feel. Add subtle heart or cross symbols that fade away. Colors: rose red, pink, warm white. The effect should convey healing and recovery. Dimensions: 16x16 pixels per particle, alpha channel. Style: warm, gentle, magical healing vibes.

**Animation Timeline**:
- Spawn: Random gentle rise (0.8-1.2s) with fade
- Frequency: Every 0.5s one particle spawns per active stack

---

### 🧲 XP Magnet
**Color**: `Color(0.28, 0.88, 0.60)` (Teal Green)

**Description**: Attracts XP orbs from further away

**Texture/Particle Prompt**:
> Design a teal-green attraction field effect. Create a series of concentric circles with arrows pointing inward toward the player. Include glowing lines and particles that curve toward the center. The effect should feel magnetic and attractive. Add sparkle particles moving along the attraction lines. Dimensions: 200x200 pixels, alpha channel. Colors: teal and green with bright highlights. Style: magical attraction, magnetism visualization.

**Animation Timeline**:
- Pulse: 0.6s breathing animation (expand/contract)
- Particle Flow: Continuous inward-flowing particles along radii
- Intensity: Increases when XP orbs are nearby

---

## Wizard Skills

### 🔥 Fireball
**Color**: `Color(1.0, 0.48, 0.05)` (Orange)

**Description**: Orbiting fire orbs dealing burst damage

**Texture/Particle Prompt**:
> Generate a blazing fireball particle effect in orange and red tones. The fireball should have a bright yellow core surrounded by orange flames. Include flickering fire animations and small embers flying outward. Add a subtle heat shimmer around the edges. Dimensions: 40x40 pixels, alpha channel with smooth gradients. The effect should radiate heat and power. Style: intense flame, magical fire.

**Animation Timeline**:
- Orbit: Circular path around player with 1-2s cycle
- Flicker: Random subtle size variations (flame flicker)
- Impact: 0.4s exploding fire burst with ember particles

---

### ⚡ Elec Shockwave
**Color**: `Color(0.88, 0.98, 0.18)` (Electric Yellow)

**Description**: Electric pulse shockwave

**Texture/Particle Prompt**:
> Create a jagged electric shockwave in bright yellow with blue highlights. The wave should have broken, zigzag edges suggesting electricity. Include crackling effects and branching lightning tendrils. Add electric spark particles that jump outward. Dimensions: 512x512 pixels (radial), alpha channel. Colors: bright yellow, electric blue, white hot core. Style: high voltage, chaotic energy, powerful electromagnetic blast.

**Animation Timeline**:
- Charge: 0.3s glow intensification
- Release: 0.5s rapid radial expansion with crackling
- Decay: 0.3s fade with electric sparks lingering

---

### 💨 Hurricane
**Color**: `Color(0.58, 0.88, 0.96)` (Light Blue)

**Description**: Whirling wind aura damage effect

**Texture/Particle Prompt**:
> Design a swirling blue wind aura with a tornado feel. Create spiral patterns in light blue and cyan. Include swirling particles, wind lines, and a vortex appearance. Add small debris particles caught in the whirl. Dimensions: 256x256 pixels (radial), alpha channel. The effect should feel cyclonic and powerful. Style: natural disaster, wind magic, swirling energy.

**Animation Timeline**:
- Idle: Continuous slow rotation (4s cycle)
- Hit: Brief speed increase and color flare
- Duration: Active while skill maintains

---

### ❄️ Blizzard
**Color**: `Color(0.78, 0.94, 1.0)` (Pale Cyan)

**Description**: Whole-screen ice storm effect

**Texture/Particle Prompt**:
> Create a massive blizzard particle sheet with pale cyan snowflakes and ice shards. Include large and small snowflakes falling, icicle formations, and freezing effects. The effect should fill the screen with cold wind streaks and frozen crystal bursts. Colors: pale cyan, white, icy blue. Add frosted glass textures and sparkling ice effects. Dimensions: 512x512 pixels tileable, alpha channel. Style: extreme cold, winter storm, absolute zero magic.

**Animation Timeline**:
- Warmup: 0.5s intensifying snow and wind
- Peak: 2s full screen blizzard with max particle density
- Fade: 1s snow settling and fading away

---

## Archer Skills

### 🏹 Arrow Shot
**Color**: `Color(0.45, 0.78, 0.25)` (Forest Green)

**Description**: Fast piercing arrows

**Texture/Particle Prompt**:
> Generate a sleek green arrow projectile. The arrow should be sharp and pointed with fletching details. Include a subtle wind trail behind it. Add a slight glow indicating its speed. Dimensions: 12x48 pixels (tall portrait), alpha channel. Colors: forest green with lighter highlights on the edges. The arrow should look piercing and fast. Style: archer weapon, dynamic motion lines.

**Animation Timeline**:
- Spawn: 0.05s fade-in
- Travel: Straight line with rotation matching direction
- Trail: Fading line following path for 0.3s
- Impact: 0.2s pierce spark effect

---

### ➡️ Split Arrow
**Color**: `Color(0.55, 0.86, 0.30)` (Lime Green)

**Description**: Fan of arrows spreading outward

**Texture/Particle Prompt**:
> Design a bright lime-green arrow projectile that fans out. Create a single arrow shape with a fan burst pattern radiating outward. Include light streaks showing the spread pattern and velocity. Dimensions: 10x40 pixels per arrow in fan, alpha channel. Colors: lime green with bright highlights. Add subtle sparkle particles in the spread pattern. Style: splitting projectile, directional burst.

**Animation Timeline**:
- Fan Spread: 0.15s arrows fan out from center point
- Travel: Each arrow moves independently in its direction
- Trail: Green light trails following each arrow

---

### 🗡️ Pierce Arrow
**Color**: `Color(0.28, 0.90, 0.55)` (Teal)

**Description**: Arrows that pierce through all enemies

**Texture/Particle Prompt**:
> Create a sharp teal-colored piercing arrow. The arrow should look heavy and penetrating with a glowing teal aura. Include a trailing energy effect and small sparkles showing its power. Dimensions: 14x52 pixels, alpha channel. Colors: teal with bright cyan highlights and energy glow. The effect should convey power and penetration. Style: magical piercing weapon, energy-infused projectile.

**Animation Timeline**:
- Spawn: 0.1s charge glow
- Travel: Straight motion with teal energy trail
- Pierce: Small burst effect on each enemy hit (no stop)

---

### 🌧️ Sky Fall
**Color**: `Color(0.22, 0.72, 0.18)` (Deep Green)

**Description**: Rain of arrows covering the whole screen

**Texture/Particle Prompt**:
> Generate a torrential rain of deep-green arrows falling from above. Create a dense particle effect with arrows falling at various angles and speeds (slightly randomized). Include wind streaks and motion trails. Add impact effects on the ground. Dimensions: 512x512 pixels for the effect area, alpha channel. Colors: deep green with darker shadows on arrows. Style: arrow storm, rain of projectiles, overwhelming barrage.

**Animation Timeline**:
- Appear: 0.3s arrows spawning from top
- Rain: 2s continuous rain at max density
- Impact: 0.2s hit effects on ground contact
- Fade: 0.5s arrows disappearing and fading away

---

## Assassin Skills

### ⭐ Star Knife
**Color**: `Color(0.72, 0.70, 0.82)` (Purple-Gray)

**Description**: Spinning star blade projectiles

**Texture/Particle Prompt**:
> Create a sharp spinning star/ninja star shape in purple-gray tones. The star should have 5-6 points with a metallic sheen. Include spinning animation indicators and sharp highlights. Add small sparkles trailing behind. Dimensions: 32x32 pixels (square), alpha channel. Colors: purple-gray with silver/white highlights and shadows. The effect should feel sharp and deadly. Style: ninja weapon, spinning projectile, martial arts.

**Animation Timeline**:
- Spawn: 0.05s appear with rotation
- Travel: Straight line with continuous fast rotation
- Trail: Purple-gray sparkle trail following path
- Impact: 0.15s sharp bounce effect

---

### 🌪️ Knife Storm
**Color**: `Color(0.78, 0.74, 0.88)` (Lavender)

**Description**: Spinning blade aura around player

**Texture/Particle Prompt**:
> Design a violent spinning blade aura in lavender and purple. Create a circular storm of knife shapes rotating rapidly. Include sharp velocity lines and sparks flying outward. Add occasional larger blade silhouettes mixed with particles. Dimensions: 256x256 pixels (radial), alpha channel. Colors: lavender, purple with white sparks and shadows. The effect should feel dangerous and sharp. Style: blade vortex, martial tempest, deadly aura.

**Animation Timeline**:
- Spin: Fast continuous rotation (1.5s per cycle)
- Particle: Constant outward spark generation
- Hit: Brief intensity spike when dealing damage

---

### 🪃 Boomerang Star
**Color**: `Color(0.92, 0.84, 0.28)` (Golden Yellow)

**Description**: Returning star projectile that hits twice

**Texture/Particle Prompt**:
> Generate a golden star-shaped boomerang projectile. The star should have a polished metallic look with golden highlights. Include a curved trajectory indicator and trail effect. Add sparkles suggesting magical return property. Dimensions: 28x28 pixels, alpha channel. Colors: golden yellow with bronze shadows and bright white highlights. The effect should suggest movement and return. Style: magical boomerang, returning weapon.

**Animation Timeline**:
- Outbound: Arc trajectory away from player with trail
- Arc Peak: 0.3s pause at furthest point
- Return: Arc trajectory back to player with faster motion
- Hit: 0.2s impact effect each time (out and return)

---

### 🌪️ 7 Slash
**Color**: `Color(0.82, 0.24, 0.36)` (Dark Red)

**Description**: Seven screen-wide slashes

**Texture/Particle Prompt**:
> Create a devastating 7-slash effect with dark red energy. Design 7 diagonal slash lines crossing the screen with dark red and crimson colors. Include impact effects at each slash and trailing energy. Add small shockwave rings at intersection points. Dimensions: 512x512 pixels per slash line, alpha channel. Colors: dark red, crimson, black shadows with bright red highlights. Style: devastating finishing move, screen-clearing attack.

**Animation Timeline**:
- Preparation: 0.2s darkening and tension
- Slashes: 7 rapid slashes over 0.6s (staggered ~85ms apart)
- Each Slash: 0.15s expand and fade
- Shockwaves: 0.4s emanating rings from impacts

---

## Special Skills (Character-Specific)

### 🌀 Swirl Tangerine (Brown Capy Ultimate)
**Color**: `Color(1.0, 0.55, 0.05)` (Tangerine Orange)

**Description**: Tangerine energy cyclone wiping the whole screen

**Texture/Particle Prompt**:
> Generate a massive tangerine-orange energy cyclone covering the entire screen. Create swirling vortex patterns with concentric circles and spiraling energy. Include bright tangerine cores with darker orange shadows. Add small energy particles and sparkles caught in the vortex. Dimensions: 1024x1024 pixels, alpha channel, radial pattern. The effect should feel ultimate-level powerful. Style: elemental ultimate, devastating energy storm, game-winning move.

**Animation Timeline**:
- Charge: 0.5s glow and spin-up
- Vortex: 3s main cyclone effect at full power
- Peak: 1.5s maximum damage radius
- Dissipate: 1s spiral fade and energy dispersal

---

## Asset Generation Guidelines

### Texture Specifications
- **Format**: PNG with alpha channel (transparency)
- **Backgrounds**: All should be transparent (#00000000)
- **Quality**: 32-bit RGBA minimum
- **Resolution**: As specified in prompts (usually 32-512px depending on effect size)
- **Scaling**: Should scale nicely 0.5x to 2x in Godot

### Animation Integration
1. **Particle Systems**: Use Godot's GPUParticles2D or CPUParticles2D
2. **Sprites**: Use AnimatedSprite2D with frame duration matching timeline
3. **Trails**: Enable trail rendering in particle systems where needed
4. **Blending**: Use Add or Blend mode for glowing effects

### Color Tuning
- Each skill's color is provided as a Godot Color object
- Use these as modulation colors in Godot for consistency
- Allow colors to be desaturated slightly for "off" states

### Performance Tips
- Limit particle count: 50-100 per active skill
- Use sprite atlases for multiple frame animations
- Pool and reuse particle systems
- Cache textures in ResourceLoader

---

## Usage Example in Godot

```gdscript
# Example: Playing Capy Orb effect
@onready var orb_particles = GPUParticles2D.new()

func cast_orb_skill():
    orb_particles.emitting = true
    orb_particles.modulate = Color(0.98, 0.72, 0.08)  # Golden Yellow
    orb_particles.global_position = global_position
    # Particles will follow the orbit path defined in animation
```

---

## Next Steps for Asset Creation

1. **Generate Base Textures**: Use these prompts with an image generation AI (DALL-E, Midjourney, Stable Diffusion, etc.)
2. **Extract Frames**: Convert animations to sprite sheets
3. **Import to Godot**: Place in `res://assets/effects/`
4. **Create Particle Systems**: Set up GPUParticles2D nodes with the textures
5. **Wire to Skills**: Connect particle system playback to skill activation code

---

*Last Updated: 2026-06-19*
