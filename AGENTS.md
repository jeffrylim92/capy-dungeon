# Capy Dungeon instructions

## Project

- Godot 4.7 mobile game using GDScript.
- Main gameplay logic is primarily in `scripts/Match.gd`.
- Android and iOS are supported.

## Working rules

- Make changes directly in the current repository.
- Prefer minimal, targeted changes.
- Follow the existing code style and UI patterns.
- Search for existing implementations before adding new systems.
- Do not duplicate existing functions, signals, timers, or UI controls.
- Do not alter unrelated gameplay behavior.
- Do not commit or push unless explicitly requested.

## Files to avoid

Do not modify or expose:

- `keystores/`
- `secrets/`
- `.env*`
- signing credentials
- OAuth credentials

Do not commit:

- `.godot/`
- `build/`
- `android/build/`
- APK, AAB, PCK, or generated Xcode output
- `.orig`, `.bak`, or temporary backup files

## Validation

After changes:

- Check for GDScript parse errors.
- Run the smallest relevant validation available.
- Run `git diff --check`.
- Review `git diff`.
- Report only changed files, validation results, and unresolved issues.

## Response style

- Do not explain obvious code.
- Do not repeat the task.
- Keep the final response under 10 bullets.
- Include exact manual test steps only when needed.