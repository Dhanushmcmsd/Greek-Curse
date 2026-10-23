# Technical plan — Severed: Trials of Olympus

Stage 01 plan for the locked local 1v1 MVP. Later stages follow this document and `docs/DECISIONS.md`. Full-game counts in the GDD and Build Requirements are expansion targets.

## Tool versions

Pinned from commands run on 2026-10-24. No other version is accepted for implementation until this file and `PROJECT_STATUS.md` are updated together.

| Tool | Pinned value | Evidence |
|---|---|---|
| Godot | 4.7.2.stable.official.ed1daf0bf | `D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --version` |
| Blender | 5.2.3 LTS, hash e13b728c6880, built 2026-10-22 | `D:\blender\blender.exe --version` and `bpy.app.version_string` |
| Python (tooling) | 3.14.5 at `C:\Users\Admin\AppData\Local\Programs\Python\Python314\python.exe` | `python3 -c` in stage 00 |
| Git | 2.54.0.windows.1 | `git --version` in stage 00. The project is not a repository yet. Stage 02 runs `git init`. |

Godot 4.0.stable (`D:\Godot_v4.0-stable_win64.exe\...`) was run and rejected. D-001 requires >= 4.3. The official Windows download page, fetched 2026-10-24, lists 4.7.2 stable (18 August 2026). Godot 4.8 was listed as a beta, so it is not the pin. https://www.blender.org/download/lts/ on the same date lists Blender 5.2 LTS, last updated to 5.2.3 on 22 October 2026. Blender's bundled Python is 3.13 (`python313.dll`). Asset scripts run inside Blender, not under system Python 3.14.

`import bmesh` succeeded. `bpy.ops.export_scene.gltf` exists. No mesh was exported in this stage. Export templates for 4.7.2 are not installed (`%APPDATA%\Godot\export_templates` is empty). Stage 23 needs them. They were not installed here.

Headless Godot printed `GODOT_SMOKE_OK`. Background Blender printed `BPY_VERSION=5.2.3 LTS` and `BMESH_OK=bmesh`.

## Module map

Dependency direction is one way. A module may use the layer on its left, never the layer on its right.

`core` ← `sim` ← `presentation` / `ui` / `ai` / `input`

`persistence` and `progression` read and write core data and sim snapshots only. They do not import scenes, nodes, or the renderer.

| Module | Owns | Must not own |
|---|---|---|
| core | Integer math, seeded PRNG, state hash, JSON load and validate | Combat rules, nodes, files besides the loader |
| sim | Fighters, hit and hurt boxes, limbs, body state, stamina, hazards, round flow | Rendering, input devices, save files |
| input | Keyboard, gamepad, remap, buffer. Emits `SimInput` for one tick | Damage math |
| ai | Reads a sim snapshot. Emits `SimInput` only | Direct state edits, randomness outside the sim PRNG |
| presentation | Skeleton poses, stump visibility, camera, pooled flat quads, chunks, audio playback | Combat outcomes |
| ui | HUD, menus, Obol screen, settings widgets | Sim rules |
| persistence | Local save, Chronicle record, retire archive | Network, server checks |
| progression | Unlock offers, Obol trade, Career ladder data | Match simulation |

Godot nodes are a shell. The sim advances from a function call with a tick index, two `SimInput` values, and the previous state. Tests call that function with no window.

## Data flow per tick

1. Sample devices or the AI. Build one `SimInput` per fighter (moves, block, dodge). Buffering stays in the input layer and resolves to that struct before the tick.
2. Copy the previous sim state. Advance one 60 Hz tick. Order inside the tick is fixed and written down in stage 06: timers, movement, attacks, hit detection, limb and sever, hazards, meters, round check.
3. Hash the resulting state. Tests compare the hash to a golden replay.
4. Presentation and UI read the new snapshot. They interpolate between snapshots for drawing. They never write health, limbs, or positions back into the sim.
5. At match end, progression turns the final snapshot into offers, Chronicle rows, and a save. That work is outside the tick.

Cosmetic debris (chunks, quad stains) may use Godot nodes after the sim has already decided the event. Debris does not affect hit detection.

## Determinism

D-004 is the rule.

- Tick rate is 60. One second is 60 ticks. Durations in D-023 are already converted (90 s = 5400 ticks, 1.5 s = 90 ticks, 0.5 s = 30 ticks, 6 s = 360 ticks, 0.7 s = 42 ticks).
- Positions, sizes, and damage are integers. 1 unit = 1 millimetre. The sim does not use `float`, Godot physics, `Time`, `randf`, or frame delta.
- Division states the rounding rule at the call site. The default is round-half away from zero, implemented once in core and used everywhere.
- The PRNG is an integer generator with an explicit seed stored in the match state. Hazard rolls and offer rolls use that generator, not a hidden one.
- A pure-sim check, added in stage 03, fails the build if sim scripts reference Godot physics, wall-clock time, or floats.
- Rollback, snapshots for netcode, and input replay over the network are deferred (D-016). Local state hash and input replay are in the test harness.

## Asset pipeline

Blender 5.2.3 LTS scripts are the source of truth. The committed `.glb` is the generated output (D-026). No Git LFS.

1. Data files describe a fighter or arena: height, weight, muscle, palette, socket names, hazard ids.
2. A Python script using `bpy` and `bmesh` builds a mesh, a shared armature, rigid weights, and hidden `STUMP_*` caps.
3. The script exports glTF 2.0 binary (`.glb`) through `bpy.ops.export_scene.gltf`.
4. Godot imports the `.glb`. Import settings are committed. Materials stay unshaded or simple albedo so Compatibility can draw them.
5. A validator checks names, triangle count (<= 5000 including costume, C-13), socket bones, and that every stump cap exists.

Animation clips are not exported (D-013). The pose library is JSON applied to the imported skeleton at runtime. Regrown limbs are separate `.glb` pieces parented to the same socket bones (stage 13).

Stage 11 proves the loop with one tiny mesh before any fighter is generated.

## Test strategy

| Layer | When | What "pass" means |
|---|---|---|
| core | Stage 03 | Integer division, PRNG stream, and hash are stable across two processes. |
| sim | Stages 05–10, 17 | Headless runner feeds scripted `SimInput`. Golden hashes match. Limb, combo, cap, and stamina cases are explicit. |
| content | Stages 12–13, 18 | 4 fighters × 5 regrown limbs × valid sockets attach. Names and budgets validate. |
| presentation | Stages 14–16 | Pose library covers required states. Settings round-trip. No sim import from visual scripts. |
| persistence | Stage 19 | Save, reload, and a corrupt-save case. |
| flow | Stage 20 | Menu paths exist for Career, Fresh Body, Versus, Practice. Human checkpoint C is still required. |
| release | Stages 21–23 | One command runs the fast suite. Exported build smoke test is separate and waits on templates. |

The runner is custom GDScript plus Python `unittest` for tools (D-005). No GUT. A test that was not executed is UNVERIFIED. Failing tests are fixed, not deleted.

## Risk register

| # | Risk | Mitigation |
|---|---|---|
| 1 | A later session launches Godot 4.0 from `D:\Godot_v4.0-stable_win64.exe` | `GODOT_BIN` is the 4.7.2 console exe. Stage 02 scripts call that path. |
| 2 | Export templates are missing, so stage 23 cannot export | Recorded. Install the 4.7.2 standard templates before stage 23. Do not install the .NET set. |
| 3 | A float, physics body, or wall-clock read enters the sim | Stage 03 purity check and golden replays. |
| 4 | Owner rejects D-035 and the sever rule changes after stage 07 | D-035 is DEFAULT and flagged. Override before stage 07. |
| 5 | Generated fighters fail the look check at checkpoint B | Generators stay data-driven. Checkpoint B returns a looks list. Scripts, not hand-edits, are the fix. |
| 6 | Code-driven poses are unreadable in motion | Stage 14 keeps attacks on fixed tick windows. Checkpoint A and C judge readability. |
| 7 | Compatibility banding or missing Vulkan effects | Chosen on purpose (D-039). Flat quads and vertex colours. No Decal nodes. |
| 8 | C: has about 7.5 GB free and Godot user data lives there | Editor and Blender stay on D:. Template install must be checked for disk space first. |
| 9 | Linux export cannot be executed on this Windows machine | Stage 23 builds the Linux package and marks the run UNVERIFIED unless a Linux runner appears. |
| 10 | Deferred modes (online, Death Match, 4-player) leak in as stubs | Scope guard on every stage. D-016 script check from stage 03. |

## Milestone map

| Prompt | Delivers |
|---|---|
| 02 | Godot project, git, test command, validators. Smoke test passes. |
| 03 | Core module, integer toolkit, RNG, hash, data loader, sim purity check. |
| 04 | Status tools and handoff checks. |
| 05 | Greybox local 1v1 with a real 60 Hz sim. Checkpoint A. |
| 06 | Hit detection, block, stamina, dodge, grab, meters, determinism harness. |
| 07 | Limb states, sever credit, caps, Desperate Fury. Uses D-035. |
| 08 | Body-state movement, including hop, crawl, torso, and both-arms moves (D-036). Input map. |
| 09 | AI that emits `SimInput`. Local match slots. Soak harness. |
| 10 | HUD, round flow, feedback, pause, results stub. |
| 11 | Blender script framework and one imported test `.glb`. |
| 12 | Shared skeleton and the four fighters. |
| 13 | Five regrown limbs and the attachment matrix. Checkpoint B. |
| 14 | Pose library. No Blender clips. |
| 15 | Three arenas, telegraphed hazards, camera, quad stains, chunk cap. |
| 16 | Settings, generated audio, captions, accessibility. No CC0 claim (D-037). |
| 17 | All 21 abilities and the balance harness. |
| 18 | Roster stats, Career ladder of 6, content matrix. |
| 19 | Results, offers, Obol, Chronicle, local saves, minimal Retire. |
| 20 | Full menu flow. Checkpoint C. |
| 21 | Regression suite brought together. |
| 22 | Performance pass and bug burn-down inside the budget below. |
| 22B | Legal and storefront record. Owner-only items stay with the owner. |
| 23 | Windows export and a Linux package. Checkpoint D. |
| 24 | Final audit and handover. |

Prompt 25 is not in this map. It starts only if the owner asks after 24.

## Performance budget

Assumptions, not measurements. No FPS was captured in stage 01.

- Sim rate is 60 ticks per second regardless of render frame rate.
- GDD target: 60 render frames per second on mid-range integrated graphics at 1080p. This machine is a Ryzen 5 5600X, 17,103,278,080 bytes of RAM, GeForce GTX 1650, and a 1600×900 display. The discrete GPU is stronger than the stated target. Stage 22 measures frame time on this machine and says so.
- Fighters: at most 5000 triangles including costume.
- Blood and arena stains: a fixed pool of flat quads. Starting assumption for stage 15 is 32 active quads and 16 gore chunks. Stage 15 records the real pool size. No Decal nodes.
- Lights per arena stay few: one directional light plus a small number of hazard lights. Compatibility has a tight real-time light budget.
- Draw the fight from a side camera with a tight near and far plane so the depth buffer does not fight (4.7 rendering-limitations page).

## Manual tasks

| Task | Checkpoint | Who |
|---|---|---|
| Approve or override D-003 (2.5D, no sidestep) and D-009 (the five limbs) | Before stage 05 | Owner |
| Override D-035 sever rule, if the next-hit sentence should win | Before stage 07 | Owner |
| Accept or reject D-037 (do not call audio CC0) | Before stage 16 writes public audio claims; required at 22B | Owner |
| D-032 Career quit rule | Stage 20 writes the dialog; still PROPOSED | Owner |
| Play the greybox and judge feel | A, after 05 | Owner |
| Severing, body states, five limbs on Theron and Pyrrhus, looks list | B, after 13 | Owner |
| Full local loop, settings, audio taste, fun notes | C, after 20 | Owner |
| Licence, disclosure answers, store accounts, rating forms | After 22B | Owner |
| Install Godot 4.7.2 standard export templates (not .NET) | Before 23 | Owner, or approve an install |
| Play the packaged build, note FPS and any unsigned-binary warning | D, after 23 | Owner |
| Go / no-go | Final approval, after 24 | Owner |

## Renderer

**Choice: Compatibility** (D-039, confirming D-028).

The GDD targets mid-range integrated graphics. Compatibility is the Godot 4 method aimed at that hardware. The plan needs a side-on 3D camera, glTF meshes, a skeleton, unshaded or simple materials, CPU-side particles or flat sprites, a SubViewport for Obol's bust (D-030), and UI. Those do not require Forward+.

Decal nodes are not available. The Godot 4.7 page "Using decals", read 2026-10-24, says: "Decals are only supported in the Forward+ and Mobile renderers, not the Compatibility renderer." It names Sprite3D as the alternative for projecting onto mostly flat surfaces. https://docs.godotengine.org/en/4.7/tutorials/3d/using_decals.html

Blood, scorch, and sand stains are pooled flat quads. Athens sand hiding stains is a presentation fade of those quads, not a sim hazard (C-19). The 4.7 "3D rendering limitations" page notes lower color precision in Compatibility and recommends baked noise or a simple shader if gradients band. Flat colours and vertex colours avoid that problem. https://docs.godotengine.org/en/4.7/tutorials/3d/3d_rendering_limitations.html

Forward+ was not chosen. It would enable Decal nodes and would raise the GPU requirement above the GDD target. The dev GTX 1650 could run it. The target machine is the integrated-graphics case, so the project default is Compatibility.

Stage 02 sets `renderer/rendering_method` to `gl_compatibility` and does not add a Decal node.
