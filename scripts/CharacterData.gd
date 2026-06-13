class_name CharacterData
extends Resource

## Data-only definition of a capybara character.
## Drop a new .tres file into res://resources/characters/ to add a character —
## no code changes required.

@export var id: StringName = &""
@export var display_name: String = "Capy"
@export var tint: Color = Color(0.85, 0.7, 0.5)
@export var max_hp: float = 100.0

## Combat stats. attack scales outgoing combo damage, defense reduces incoming.
## Both use 10 as the baseline (1.0× multiplier).
@export var attack: int = 10
@export var defense: int = 10

## Finisher: a bonus burst dealt when the player's combo first reaches
## `finisher_threshold`. Set `finisher_damage = 0` to disable.
@export var finisher_name: String = "Big Splash"
@export var finisher_threshold: int = 10
@export var finisher_damage: float = 15.0

## Roguelite: the skill id this character automatically starts with.
## Must match a key in Match.SKILL_DEFS (e.g. "bolt", "orb", "wave", "aura").
## Leave empty for no starting skill (player picks from scratch).
@export var base_skill: String = ""
