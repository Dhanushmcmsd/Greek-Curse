# Conventions

Pinned tools: Godot `4.7.2.stable.official.ed1daf0bf` at `D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`, Blender `5.2.3 LTS` at `D:\blender\blender.exe`. Do not launch `D:\Godot_v4.0-stable_win64.exe`.

Renderer: Compatibility (`gl_compatibility`). No Decal nodes. Blood uses pooled flat quads later.

## Canonical rules

- Engine: Godot 4.x, GDScript only. Blender LTS with Python (`bpy` / `bmesh`). No third-party addons unless a recorded decision approves one.
- Simulation: fixed 60 Hz, integer millimetres, seeded PRNG. No Godot physics, wall clock, or floats in combat rules. Rendering is side-on 2.5D.
- MVP: local 1v1, 4 fighters, 3 arenas, 21 abilities, 5 regrown limbs.
- Shared skeleton and socket severing. Hide the whole limb group and show a stump cap. Code-driven poses. Dedicated motion only for hop, crawl, and torso.
- Data-driven fighter, ability, limb, arena, balance, and AI files. Generated `.glb` files are committed. Scripts stay authoritative. No Git LFS.
- Tests must actually run. The prompt pack stays read-only.
- Deferred features are not stubs. Stop at owner checkpoints.

## Layout

`src/` follows the module map in `docs/TECHNICAL_PLAN.md`: `core`, `sim`, `presentation`, `ui`, `ai`, `input`, `persistence`, `progression`.

`scenes/` holds Godot scenes. `data/` holds JSON. `data/schema/` holds the matching `*.schema.json` files. `assets/` will hold generated `.glb` and audio. `tests/` holds the headless suite. `tools/` is ignored by the Godot importer (`.gdignore`).

## Version notes

- `gdtoolkit` is not installed. Do not treat formatting as a required check until it is added on purpose.
- Bash launchers exist for Linux and macOS and are unverified here.
- Logging may use the wall clock. Combat rules may not.
- Input actions are added in stage 08. This project has no default InputMap entries.

## Typing

Public functions and variables in `src/` have type hints. `int` is the combat number. `float` stays out of `src/sim/`. JSON integer fields are converted in `DataLoader` before sim code reads them.

## Signals

Signals are for presentation and UI. Sim code returns a `Result` or writes events from `step`. It does not emit Godot signals to report a hit.

## Errors

`Result.success` and `Result.failure` carry `ok`, `value`, and `error`. Callers check `ok`. They do not crash the process on bad data. `DataLoader` also writes an ERROR log with the resource path and the field path.

## Logging categories

Use a short category string: `data`, `sim`, `input`, `ai`, `ui`, `save`. ERROR increments `Log.error_count`. INFO and WARN do not.

## Adding content

1. Add `data/<area>/<name>.json`.
2. Add `data/schema/<area>/<name>.schema.json` using `type`, `required`, `properties`, `enum`, `minimum`, `maximum`, and `items`.
3. Add a headless test that loads the file and checks one invariant.
4. Run `tools/check_all.ps1`.

## Commits

One sentence on why the change exists, then a second sentence only if the first would hide a constraint. Do not amend published commits. Do not commit `.godot/` or `build/`.

## Owner approvals recorded with stage 03

D-003 stays 2.5D: one combat lane, no sidestep into the background. D-009 stays the five regrown limbs on the shared skeleton and sockets. More limbs need a new owner approval.
