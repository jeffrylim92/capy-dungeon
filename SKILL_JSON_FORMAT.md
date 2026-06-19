## JSON Structure for res://data/skill_data.json
## 
## This shows the expected format for individual skill objects.
## You can use either Array or Dict format - the manager handles both.

# ============================================================================
# OPTION 1: ARRAY OF SKILL OBJECTS (Simplest for paste-in)
# ============================================================================

[
  {
    "skill_id": "fireball",
    "name": "Fireball",
    "short": "Orbiting fire orbs",
    "type": "orbit_projectile",
    "character": "capy_wizard",
    "character_specific": true,
    "is_ultimate": false,
    "color": [1.0, 0.48, 0.05, 1.0],
    "color_name": "Orange",
    
    "animation_states": {
      "spawn": "fireball_spawn",
      "orbit": "fireball_orbit",
      "impact": "fireball_impact"
    },
    
    "timings": {
      "spawn": 0.15,
      "orbit_cycle": 1.2,
      "impact": 0.4
    },
    
    "effect_scene": "res://effects/FireballEffect.tscn",
    "particle_texture": "res://textures/effects/fireball.png",
    
    "sound_effects": {
      "cast": "res://sfx/skills/fireball_cast.wav",
      "impact": "res://sfx/skills/fireball_hit.wav"
    },
    
    "specifications": {
      "format": "PNG with alpha",
      "dimensions": "40x40 pixels",
      "particle_count_suggestion": 70,
      "blend_mode": "Add"
    },
    
    "texture_prompt": "Generate a blazing fireball particle effect in orange and red tones..."
  },
  
  {
    "skill_id": "blizzard",
    "name": "Blizzard",
    "short": "Whole-screen ice storm",
    "type": "screen_effect",
    "character": "capy_wizard",
    "character_specific": true,
    "is_ultimate": true,
    "color": [0.78, 0.94, 1.0, 1.0],
    "color_name": "Pale Cyan",
    
    "animation_states": {
      "charge": "blizzard_charge",
      "release": "blizzard_release",
      "peak": "blizzard_peak",
      "dissipate": "blizzard_dissipate"
    },
    
    "timings": {
      "charge": 0.5,
      "release": 0.5,
      "peak": 2.0,
      "dissipate": 1.0
    },
    
    "effect_scene": "res://effects/BlizzardEffect.tscn",
    "particle_texture": "res://textures/effects/blizzard.png",
    
    "sound_effects": {
      "cast": "res://sfx/skills/blizzard_cast.wav",
      "loop": "res://sfx/skills/blizzard_loop.wav",
      "impact": "res://sfx/skills/blizzard_end.wav"
    },
    
    "specifications": {
      "format": "PNG with alpha",
      "dimensions": "512x512 pixels",
      "particle_count_suggestion": 150,
      "blend_mode": "Alpha"
    },
    
    "texture_prompt": "Create a massive blizzard particle sheet..."
  }
]


# ============================================================================
# OPTION 2: DICT WITH ALL SKILLS (Structured by category)
# ============================================================================

{
  "skills": {
    "common": {
      "orb": {
        "skill_id": "orb",
        "name": "Capy Orb",
        ...
      },
      "bolt": {
        "skill_id": "bolt",
        "name": "Capy Bolt",
        ...
      }
    },
    "wizard": {
      "fireball": {
        "skill_id": "fireball",
        ...
      },
      "blizzard": {
        "skill_id": "blizzard",
        ...
      }
    }
  },
  "character_skill_mapping": {
    "capy_wizard": ["fireball", "elec_wave", "hurricane", "blizzard", "regen", "magnet"],
    "capy_archer": ["arrow", "split_arrow", "pierce_arrow", "sky_fall", "regen", "magnet"]
  },
  "ultimate_skills": {
    "capy_wizard": "blizzard",
    "capy_archer": "sky_fall"
  }
}


# ============================================================================
# SKILL OBJECT FIELDS (Complete Reference)
# ============================================================================

{
  # Required
  "skill_id": "string",              # Unique identifier (use in code)
  "name": "string",                  # Display name
  
  # Recommended
  "short": "string",                 # Short description
  "type": "string",                  # orbit_projectile | projectile | aura | screen_effect
  "character": "string",             # capy_wizard | capy_archer | capy_assassin | capy_brown
  "character_specific": true,        # true if only for specific character
  "is_ultimate": false,              # true for ultimate skills
  
  # Visuals
  "color": [1.0, 0.48, 0.05, 1.0], # RGBA array
  "color_name": "string",            # Human-readable color
  
  # Animation
  "animation_states": {
    "spawn": "string",               # AnimationPlayer animation name
    "orbit": "string",
    "impact": "string",
    "idle": "string"
  },
  
  "timings": {
    "spawn": 0.15,                   # Duration in seconds
    "orbit_cycle": 1.2,
    "impact": 0.4,
    "charge": 0.5
  },
  
  # Assets
  "effect_scene": "res://path/to/effect.tscn",    # PackedScene for effect
  "particle_texture": "res://path/to/texture.png", # Texture for particles
  
  # Audio
  "sound_effects": {
    "cast": "res://sfx/cast.wav",
    "impact": "res://sfx/impact.wav",
    "loop": "res://sfx/loop.wav"
  },
  
  # Technical
  "specifications": {
    "format": "PNG with alpha",
    "dimensions": "40x40 pixels",
    "particle_count_suggestion": 70,
    "blend_mode": "Add" | "Alpha" | "Multiply"
  },
  
  # Generation
  "texture_prompt": "string",        # AI prompt for generating the texture
  "animation_timeline": {            # From ChatGPT, describes animation breakdown
    "spawn": "...",
    "orbit": "...",
    "impact": "..."
  }
}


# ============================================================================
# USAGE IN GODOT
# ============================================================================

# Load and use:
var manager = SkillEffectManager.new()
manager.load_skill_data()

# Get a skill
var skill = manager.get_skill("fireball")

# Cast a skill with animation/particles
manager.cast_skill("fireball", self)

# Get skill color
var color = manager.get_skill_color("fireball")

# List skills for character
var wizard_skills = manager.get_skills_for_character("capy_wizard")

# Check if ultimate
if manager.is_ultimate_skill("blizzard"):
    print("This is an ultimate!")


# ============================================================================
# POSTING TO res://data/skill_data.json
# ============================================================================

# 1. Create res://data/ folder in your project
# 2. Create skill_data.json file
# 3. Paste the Array or Dict format above
# 4. Fill in your animation names (from AnimationPlayer)
# 5. Point to your texture/effect/sound paths
# 6. Save and reload Godot
