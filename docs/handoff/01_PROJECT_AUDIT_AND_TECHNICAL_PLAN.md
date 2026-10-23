# Stage 01 handoff — Project Audit And Technical Plan

Stage result: **COMPLETE**. Godot 4.7.2.stable and Blender 5.2.3 LTS are pinned from commands run in this session. The technical plan is written. No game code and no Godot project were created.

An earlier pass the same night found Godot 4.0.stable and stopped BLOCKED. The 4.7.2 console binary clears that block. Godot 4.0 remains on disk and is not the pin.

## Changed files

- Rewrote this handoff (the previous copy said BLOCKED).
- Updated `PROJECT_STATUS.md`.
- Updated `docs/DECISIONS.md` with D-035 through D-039 and C-19 through C-25. No LOCKED row was edited.
- Created `docs/TECHNICAL_PLAN.md`.
- Did not modify `Severed_Cursor_Prompt_Pack/`.
- Smoke script stayed in `%TEMP%\severed_godot472_smoke\smoke.gd`, outside the project.

## Commands actually run

Console binary:

`D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`

The path `D:\Godot_v4.7.2-stable_win64.exe` is a directory. The GUI exe sits beside the console exe. `--version` was run on the console exe only.

```
4.7.2.stable.official.ed1daf0bf
```

Exit 0.

Headless `--script` on the temp smoke file:

```
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

GODOT_SMOKE_OK
```

Exit 0.

`D:\blender\blender.exe --version` printed `Blender 5.2.3 LTS`, build date 2026-10-22, hash `e13b728c6880`, branch `blender-v5.2-release`. Exit 0.

`D:\blender\blender.exe --background --python-expr` printed `BPY_VERSION=5.2.3 LTS` and, in a second run, `BMESH_OK=bmesh` and `GLTF_EXPORT=True`. Exit 0. No mesh was exported.

`%APPDATA%\Godot\export_templates` contains 0 files. `4.7.2.stable` does not exist. Templates were not installed. That listing reported 8,034,889,728 bytes free on C:.

Heading check on the plan:

```
## Tool versions
## Module map
## Data flow per tick
## Determinism
## Asset pipeline
## Test strategy
## Risk register
## Milestone map
## Performance budget
## Manual tasks
## Renderer
```

Pages read on 2026-10-24:

- https://godotengine.org/download/windows/ — 4.7.2 stable, 18 August 2026. 4.8 was a beta on the archive page.
- https://www.blender.org/download/lts/ — Blender 5.2 LTS, last updated to 5.2.3 on 22 October 2026.
- https://docs.godotengine.org/en/4.7/tutorials/3d/using_decals.html — Decals are Forward+ and Mobile only, not Compatibility.
- https://docs.godotengine.org/en/4.7/tutorials/3d/3d_rendering_limitations.html — Compatibility has the lowest color precision of the three methods.

Disk and display figures from earlier commands this same night: D: 191.09 GB free, E: 195.87 GB free, one 1600×900 display, GeForce GTX 1650. They were not re-measured after the 4.7.2 run.

## Test results

| Check | Result |
|---|---|
| Godot 4.7.2 `--version` | PASS. `4.7.2.stable.official.ed1daf0bf`. Meets >= 4.3. |
| Godot headless smoke | PASS. `GODOT_SMOKE_OK`, exit 0. |
| Blender version, `bpy`, `bmesh`, glTF operator | PASS. `5.2.3 LTS`. |
| Export templates for 4.7.2 | Not installed. |
| Windowed Godot, screenshots, Blender render | UNVERIFIED. Not launched. A display and a GPU are present. |
| Plan headings | PASS. All task-6 sections are present, plus Renderer. |
| Game tests | None exist. |

## Acceptance criteria

1. **PASS.** Godot `4.7.2.stable.official.ed1daf0bf` and Blender `5.2.3 LTS` are pinned from command output.
2. **PASS.** Headless Godot and background Blender both exited 0 with the output above.
3. **PASS.** Renderer is Compatibility. Source: Godot 4.7 "Using decals", quoted in `docs/TECHNICAL_PLAN.md` and D-039.
4. **PASS.** `docs/TECHNICAL_PLAN.md` has the required sections. New decisions D-035, D-036, D-038, and D-039 are DEFAULT. D-037 is PROPOSED. No LOCKED row was changed.
5. **PASS as a record.** `can_run_godot_windowed`, `can_render_screenshots`, and `can_run_blender_render` are unknown because those actions were not run. The unknown values are written in `PROJECT_STATUS.md`.

## Known bugs and blockers

| ID | Severity | Description | Status |
|---|---|---|---|
| B-001 | Was a version gate | Godot 4.0 was rejected. 4.7.2 is pinned. | CLOSED |
| B-002 | Was a missing Blender install | Blender 5.2.3 LTS verified. | CLOSED |
| B-003 | Blocks packaged export in stage 23 | Export templates for 4.7.2 are not installed. | OPEN |

B-003 does not block stages 02–22.

## Decisions made

- D-035 DEFAULT. Integrity that hits 0 outside a combo stays Cracked. Sever only during the combo window.
- D-036 DEFAULT. Both-arms headbutt, shoulder charge, and bite are sim moves in the pose library.
- D-037 PROPOSED. Do not call generated audio CC0. D-017 was not rewritten.
- D-038 DEFAULT. Stamina is in the MVP. Costs wait for stage 06 data.
- D-039 DEFAULT. Compatibility renderer. Flat quads, no Decal nodes.

C-19 through C-25 record the stage 00 tensions against those decisions. D-003, D-009, and D-032 are still waiting on the owner.

## Owner action

Before stage 05, reply **approved** or send a change for D-003 (2.5D lane, no sidestep) and D-009 (the five regrown limbs).

Before stage 07, say if you want the other sever sentence instead of D-035 (a limb at 0 outside a combo severs on the next hit). Silence keeps D-035.

Before stage 16 publishes audio claims, accept or reject D-037.

Before stage 23, install the standard Godot 4.7.2 export templates, not the .NET set. C: has about 7.5 GB free, and templates normally land in `%APPDATA%\Godot\export_templates`. They were not installed in this stage.

## Next prompt to execute

`02_PROJECT_SCAFFOLD_AND_DEVELOPMENT_TOOLS.md`
