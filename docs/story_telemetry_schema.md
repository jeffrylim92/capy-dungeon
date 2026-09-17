# Story Gameplay Telemetry Schema

## Scope and transport

Schema version 1 is a bounded, event-driven balancing feed for Story attempts. `StoryTelemetry` retains at most 128 events in memory and can forward them through an optional `Callable` sink. The project does not configure a gameplay analytics provider, network upload, or disk writer, so records are local to the active attempt and discarded with it.

No account name, cloud ID, display name, email, device identifier, position trail, input stream, chat, or advertising identifier is collected. DEV test and Boss Practice use separate contexts and do not affect Story progression. This system reports observations only; it never changes difficulty, rewards, enemy stats, or stage rules.

## Event envelope

Every retained event has the same envelope:

| Field | Type | Meaning |
|---|---|---|
| `event_name` | String | Stable semantic event ID |
| `timestamp` | int | Unix time in milliseconds |
| `run_id` | String | Unique attempt ID; a retry starts a new ID |
| `run_context` | String | `story`, `story_dev_test`, or `boss_practice` |
| `stage_id` | String | Existing stable ID, for example `ch4_5` |
| `chapter_id` | String | Existing chapter ID, for example `ch4` |
| `difficulty` | String | Stable lowercase difficulty ID |
| `mutator_ids` | Array[String] | Sorted, unique stable IDs |
| `event_data` | Dictionary | Bounded event-specific fields |

Event data is limited to 24 fields, arrays to 24 items, nesting to four levels, strings to 240 characters, and finite numeric values. Active duration comes from Match's `_elapsed`, matching Run Recap timing and excluding paused gameplay.

## Event catalog

| Event | Trigger | Key fields | Context |
|---|---|---|---|
| `story_stage_started` | Attempt instance starts | schema version, build, challenge score | all |
| `story_stage_completed` | Validated terminal success | active time, stage metrics, aggregate summary, Run History ID | all |
| `story_stage_failed` | Terminal defeat/objective failure | reason, death source or `unknown`, aggregates | all |
| `story_stage_abandoned` | Active attempt exits from pause/menu | reason, active time, partial metrics | all |
| `story_stage_retried` | Result retry selected | reason, previous run ID | DEV/practice; future Story retry UI |
| `story_phase_entered` | Authored phase transition | phase ID, phase index | all |
| `story_phase_completed` | Authored phase ends | phase ID, duration, next phase | all |
| `story_objective_started` | Required objective instance appears | objective ID, compact counters | all |
| `story_objective_completed` | Required objective resolves | objective ID, compact counters | all |
| `story_objective_failed` | Recoverable or terminal objective error | objective ID, reason, recoverable | all |
| `story_objective_recovered` | Authored recovery succeeds | recovery ID, recovery index | all |
| `story_objective_retried` | In-stage objective reset | reason | all |
| `story_mistake` | Semantic wrong choice/action | mistake ID, count, mechanic fields | all |
| `story_player_defeated` | Player reaches terminal health | phase, death index, reliable source or `unknown` | all |
| `story_mastery_failed` | Mastery objective becomes ineligible | stable objective ID, reason | Story/DEV |
| `story_mastery_result` | Victory evaluates all mastery | earned IDs, failed IDs/reasons, eligibility | Story/DEV |
| `story_mastery_persisted` | Clear merge finishes | newly earned IDs, persistence flag | Story/DEV |
| `story_mutator_triggered` | A selected runtime mutator first activates | mutator ID | all |
| `story_build_updated` | Compact capability tiers change | non-empty tiers and scores | all |
| `story_enemy_role_pressure` | A role first uses a key mechanic | role ID, mechanic ID; total count is in terminal summary | all |
| `story_boss_spawned` | Authored boss enters encounter | boss ID, phase | all |
| `story_boss_mechanic` | Signature phase/mechanic resolves | boss ID, mechanic ID, compact mechanic fields | all |
| `story_boss_defeated` | Authored boss dies | boss ID, phase | all |
| `story_victory_requested` | Gameplay requests a clear | reason, phase; deduplicated | all |
| `story_victory_rejected` | Validator blocks premature clear | reason, phase, compact snapshot; deduplicated | all |
| `story_victory_accepted` | Validator accepts clear | reason, phase | all |
| `story_protected_damage_rejected` | A protected boss/objective floor rejects damage | target, reason; first event plus aggregate count | all |

Routine hits, damage numbers, enemy positions, frames, normal spawns, controller ticks, and repeated protected hits are not emitted. Enemy spawns, deaths, role casts, mistakes, rejected damage, and damage sources are accumulated into the terminal summary.

## Stage coverage

Each stage contributes at most three to five authored state metrics in addition to shared outcome, timing, build, damage, mastery, mutator, role, and difficulty fields.

| Stage | Primary metric | Mistake/failure metric | Choice/mechanic metric |
|---|---|---|---|
| `ch1_1` | Escort route completion | Scout survival | command and route |
| `ch1_2` | Defence timer completion | Shrine survival | growth resolution |
| `ch1_3` | Required objectives completed | optional supplies lost | foreman resolution |
| `ch1_4` | Keys delivered | key recovery pressure | gate crossing |
| `ch1_5` | Barrage phases | boss defeat gate | finale completion |
| `ch2_1` | Braziers lit | cold exposure | active brazier stability |
| `ch2_2` | Captives extracted | captives refrozen | prisons destroyed |
| `ch2_3` | Runes completed | wrong rune | sequence completion |
| `ch2_4` | Mimic defeated | wrong chests | clues/tablets inspected |
| `ch2_5` | Armour transitions | cold exposure | crystals broken |
| `ch3_1` | Pools purified | corruption pressure | nodes resolved |
| `ch3_2` | Tracking phases | wrong routes | correct routes |
| `ch3_3` | Regions completed | contamination | case extraction |
| `ch3_4` | Vial delivery | integrity/retries | route selected |
| `ch3_5` | Brew and boss completion | heat pressure | final purity |
| `ch4_1` | Ore delivered | ore stolen/heat | extraction reached |
| `ch4_2` | Stabilization | mandatory jam | mechanisms/route |
| `ch4_3` | Golems captured | invalid capture pressure | channel state |
| `ch4_4` | Relic components | guardian defeat | relic choice |
| `ch4_5` | Regulators disabled | heat/protected floor | shutdown phases |
| `ch5_1` | Final threshold | alert/lockdowns | infiltration route |
| `ch5_2` | Spirits saved and portal sealed | spirits lost | seal stability |
| `ch5_3` | Rooms completed | wrong mirrors | labyrinth choices |
| `ch5_4` | Synchronization success | sync failures | route preparation |
| `ch5_5` | Ritual and boss completion | protected ritual pressure | anchors/crown/desperation |

## Aggregate terminal payload

Terminal events include phase counts and duration, deaths, objective failures and recoveries, semantic mistake counts, optional supplies lost, Story enemy count and peak active count, enemy role encounters and pressure counts, protected-damage rejection counts, final compact build, mastery IDs, the stage allowlist above, and a compact Run Recap summary. The recap summary contains final level, kills, top three damage sources, total/boss/taken damage, healing, revives, and attribution coverage.

Death source remains `unknown` unless a future damage path supplies a reliable stable source ID. UI text is never parsed to infer a death source.

## Validation sequences

`tests/story_telemetry_test.gd` covers the common start/phase/objective/mistake/recovery/mastery/complete sequence, envelope validation, canonical mutators, all 25 stage definitions, C4S5 shutdown failure, C5S5 anchors/crown/desperation, DEV/practice isolation, abandon, rate limits, 20 unique retry attempts, and buffer saturation. Run it with:

```sh
Godot --headless --path . --script res://tests/story_telemetry_test.gd
```
