# Combat animation update

Follow-up fixes and current playtest instructions are in [COMBAT_PLAYTEST.md](COMBAT_PLAYTEST.md).
In particular, the later update corrects the countdown-based defender clock and adds
source reactions, body-clearance constraints, and fighter-specific signature combos.

Open `E:/zeus balls/project.godot` in Godot 4.7.2 and run the main scene.
The executable used for validation is
`D:/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`.

## Changes

- Fixed the extra closing parenthesis in FighterRig and the missing hand-separation
  and cloth functions that prevented presentation scripts from compiling.
- Baked all 23 Dorian — the Spotlight attacks from the supplied JohnnyCage PSA exports.
  Calibrated strike windows against the retargeted hands/feet. Special kicks use
  foot contact, even though their gameplay category is `special`.
- Added 15 baked stance, guard, and block-impact animations across the five fighters,
  using JohnnyCage and Baraka motion and distinct stance choices/proportions.
- Added Dorian's missing reaction mappings. Hit reactions seek simulation age,
  restart on repeated hits, and hold during hitstop.
- Kept joint translations at target rest offsets. Hand separation adjusts the
  supporting arm rather than stretching wrist bones. Guard constraints run after
  transition blending; authored Johnny attacks preserve their original arm motion.
- Corrected Dorian's right-kick selection and mesh-height metadata.

## Validation and limits

- Godot editor import: no script errors.
- New Johnny/roster animation regression suite: 4 passed.
- Fighter-style suite: 4 passed after the transition constraint fix.
- Character-fit suite: 5 passed after correcting Dorian's recorded mesh height.
- Combat presentation suite: 4 passed.
- Rendered and inspected Johnny punch, front kick, Shadow Kick, and roster stances/guards.
- The broad run reported 178 passes and 5 failures before the final fixes. Two
  failures were subsequently fixed and their focused suites passed. Remaining:
  non-Johnny Shadow Kick fallback reach, prototype replay final hash, and the
  corresponding prototype deterministic golden hash. Golden files were not changed.
- Johnny still uses the project's existing Kachujin placeholder mesh, not an
  extracted MK12 Johnny likeness. No new character mesh was fabricated.
- Sampled poses and joint offsets were checked; these checks do not prove absence
  of mesh interpenetration in every possible combat/limb combination.

## Rebuild

Runtime needs only the committed project assets, not the external source folder.
Source paths and SHA-256 hashes are recorded in `data/animation/*source_manifest.json`.
To regenerate intermediates and baked assets from the same exports:

1. `python tools/anim/extract_combat_sources.py`
2. Run Godot headlessly with `--path . --script res://tools/anim/retarget_exported_motion.gd -- johnny`.
3. Run the same tool with `-- states`.
4. Run `res://tools/anim/calibrate_exported_contacts.gd -- johnny`.

The extraction script accepts `--source-root` pointing to a relocated `Char` folder.
Screenshots are in `build/export_dorian_*.png` and `build/style_*_idle.png` /
`build/style_*_block.png`. Capture scripts are in `tools/capture_dorian.gd` and
`tools/capture_combat_stances.gd`.
