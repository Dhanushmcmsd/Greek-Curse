# PROJECT_STATUS.md - Severed: Trials of Olympus

> Single source of truth. Cursor updates this file at the end of **every** stage (use `tools/status/update_status.py` once stage 04 exists). If a session is interrupted, open the project and paste `RESUME_PROMPT.md`.

> Status values: NOT_STARTED, IN_PROGRESS, COMPLETE, PARTIAL, BLOCKED.

## Environment

- OS / shell: Windows 10 Pro 10.0.19045, PowerShell 5.1.19041.6456. WMI caption: Microsoft Windows 10 Pro.

- GODOT_BIN (path, version): PINNED `D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` — `4.7.2.stable.official.ed1daf0bf` (`--version`, exit 0, 2026-10-24). The parent path is a directory. GUI sibling `Godot_v4.7.2-stable_win64.exe` was not the process that printed the version. Godot 4.0 at `D:\Godot_v4.0-stable_win64.exe\Godot_v4.0-stable_win64_console.exe` remains installed and is not the pin. Official Windows page the same date lists 4.7.2 stable (18 August 2026).

- BLENDER_BIN (path, version): PINNED `D:\blender\blender.exe` — Blender 5.2.3 LTS, build 2026-10-22, hash e13b728c6880, branch blender-v5.2-release. `bpy.app.version_string` printed `5.2.3 LTS`. `import bmesh` printed `BMESH_OK=bmesh`. `bpy.ops.export_scene.gltf` exists (`GLTF_EXPORT=True`). No mesh was exported. https://www.blender.org/download/lts/ on 2026-10-24 lists 5.2 LTS updated to 5.2.3 on 22 October 2026.

- PYTHON_BIN (path, version): `C:\Users\Admin\AppData\Local\Programs\Python\Python314\python.exe` — Python 3.14.5 (tags/v3.14.5:5607950, MSC v.1944 64 bit AMD64). `python`, `py -3`, and `python3` all printed 3.14.5. `python3` is invoked through `C:\Users\Admin\AppData\Local\Microsoft\WindowsApps\python3.exe`; `sys.executable` is the Python 3.14.5 path above.

- Git version / repo state: git version 2.54.0.windows.1 (`D:\Git\cmd\git.exe`). Repository initialised in stage 02. See the session log for the commit. No Git LFS.

- Godot export templates installed for pinned version: yes. `%APPDATA%\Godot\export_templates\4.7.2.stable\version.txt` reads `4.7.2.stable`. That folder has 35 files, including `windows_release_x86_64.exe`. A throwaway project at `D:\godot_template_cache\probe` exported with `--export-release "Windows Desktop"` and exit 0 (`probe.exe` 109,127,680 bytes). That probe is outside this repo. The game itself has not been exported.

- Capabilities: can_run_godot_windowed=yes, can_render_screenshots=yes, can_run_blender_render=yes. One primary display is present (1600x900). On 2026-10-24 the pinned console Godot opened a Compatibility window, printed `OpenGL API 3.3.0 NVIDIA 621.01`, exited 0, and wrote `docs/playtest/screenshots/a_prototype.png`. That still was inspected. Gameplay controls were not played. Blender Workbench previews were rendered and inspected during stages 11–13. Disk free this session: C: 8,034,889,728 bytes at the templates listing; D: 191.09 GB; E: 195.87 GB (D/E from earlier WMI the same night).

- Renderer chosen: Compatibility (D-039). Godot 4.7 decal docs say Decal nodes are Forward+ and Mobile only. Blood uses pooled flat quads.

- Dev machine specs (for performance notes): AMD Ryzen 5 5600X, 6 cores / 12 threads. WMI `TotalPhysicalMemory` 17103278080 bytes (~15.9 GiB). GPU: NVIDIA GeForce GTX 1650, WMI `AdapterRAM` 4293918720 bytes (~4.0 GB; WMI VRAM figures are often inaccurate).

## Current Stage

- Stage: 16 (COMPLETE)

- Started / last updated: 2026-10-24

## Stage Table

| ID | Stage | Status | Last updated | Handoff file |
|---|---|---|---|---|
| 00 | Readme And Execution Guide | COMPLETE | 2026-10-24 | docs/handoff/00_README_AND_EXECUTION_GUIDE.md |
| 01 | Project Audit And Technical Plan | COMPLETE | 2026-10-24 | docs/handoff/01_PROJECT_AUDIT_AND_TECHNICAL_PLAN.md |
| 02 | Project Scaffold And Development Tools | COMPLETE | 2026-10-24 | docs/handoff/02_PROJECT_SCAFFOLD_AND_DEVELOPMENT_TOOLS.md |
| 03 | Core Architecture And Coding Rules | COMPLETE | 2026-10-24 | docs/handoff/03_CORE_ARCHITECTURE_AND_CODING_RULES.md |
| 04 | Progress Tracker And Handoff Protocol | COMPLETE | 2026-10-24 | docs/handoff/04_PROGRESS_TRACKER_AND_HANDOFF_PROTOCOL.md |
| 05 | First Playable Prototype | COMPLETE | 2026-10-24 | docs/handoff/05_FIRST_PLAYABLE_PROTOTYPE.md |
| 06 | Combat Simulation And Hit Detection | COMPLETE | 2026-10-24 | docs/handoff/06_COMBAT_SIMULATION_AND_HIT_DETECTION.md |
| 07 | Limb Integrity Severing And Stump Caps | COMPLETE | 2026-10-24 | docs/handoff/07_LIMB_INTEGRITY_SEVERING_AND_STUMP_CAPS.md |
| 08 | Body State Movement And Input | COMPLETE | 2026-10-24 | docs/handoff/08_BODY_STATE_MOVEMENT_AND_INPUT.md |
| 09 | Fighter Ai And Local 1V1 | COMPLETE | 2026-10-24 | docs/handoff/09_FIGHTER_AI_AND_LOCAL_1V1.md |
| 10 | Combat Ui Feedback And Round Flow | COMPLETE | 2026-10-24 | docs/handoff/10_COMBAT_UI_FEEDBACK_AND_ROUND_FLOW.md |
| 11 | Blender Python Asset Pipeline | COMPLETE | 2026-10-24 | docs/handoff/11_BLENDER_PYTHON_ASSET_PIPELINE.md |
| 12 | Shared Skeleton Modular Fighters And Sockets | COMPLETE | 2026-10-24 | docs/handoff/12_SHARED_SKELETON_MODULAR_FIGHTERS_AND_SOCKETS.md |
| 13 | Regrown Limbs And Attachment Validation | COMPLETE | 2026-10-24 | docs/handoff/13_REGROWN_LIMBS_AND_ATTACHMENT_VALIDATION.md |
| 14 | Animation And Code Driven Motion | COMPLETE | 2026-10-24 | docs/handoff/14_ANIMATION_AND_CODE_DRIVEN_MOTION.md |
| 15 | Arenas Lighting Camera And Vfx | COMPLETE | 2026-10-24 | docs/handoff/15_ARENAS_LIGHTING_CAMERA_AND_VFX.md |
| 16 | Audio Ui And Accessibility | COMPLETE | 2026-10-24 | docs/handoff/16_AUDIO_UI_AND_ACCESSIBILITY.md |
| M0 | Mixamo Fighter Assets And Animation Overhaul | IN_PROGRESS | 2026-10-25 | docs/handoff/M0_STEP2_MODELS.md |
| 17 | Data Driven Abilities And Balancing | NOT_STARTED | | |
| 18 | Fighter Roster And Mvp Content | NOT_STARTED | | |
| 19 | Match Results Progression And Saves | NOT_STARTED | | |
| 20 | Main Menu Settings And Game Flow | NOT_STARTED | | |
| 21 | Automated Tests And Regression Suite | NOT_STARTED | | |
| 22 | Performance Bug Fixing And Polish | NOT_STARTED | | |
| 22B | Legal Copyright And Storefront Review | NOT_STARTED | | |
| 23 | Build Export And Release Checklist | NOT_STARTED | | |
| 24 | Final Acceptance Audit And Handover | NOT_STARTED | | |
| 25 | Post Mvp Online And Content Expansion Plan | NOT_STARTED | | |

## Completed Features
- Stage 14: phase-locked procedural animation, body-state poses, floor correction, bone-following replacements and animation lab; fixes to Checkpoint B gameplay, facing and visible match controls. 768 state and 832 attack cases validated.

- Stages 07–13: limb integrity/severing, all 16 body states, local AI, accessible HUD/round flow, reproducible Blender pipeline, shared rigs, five regrown limbs and 40 attachment cases. Four original fighter models and three test arenas were introduced early at owner request.

- Stage 00 onboarding files are in the project root and were re-checked on 2026-10-24. This historical onboarding entry predates implementation.

- Stage 04 tracker tools check headings, stage order, handoff files, and the next prompt. No combat.

- Stage 05 greybox local 1v1: two capsules, fixed-lane sim, health, timer, best of three, restart, and F1 debug. The owner replied Pass on 2026-10-24.

- Stage 06 combat core: per-zone hits, block, stamina, dodge, grab, combos, hit-stop, and replay hashes. No severing.

## Files and Systems Changed

- 00: confirmed existing byte copies of `RESUME_PROMPT.md`, `docs/DECISIONS.md`, `docs/source/GDD_extracted.txt`, `docs/source/BUILD_REQUIREMENTS_extracted.txt`, and both revised PDFs in `docs/source/`. Copied the read-only pack to `Severed_Cursor_Prompt_Pack/` (the D: pack was the opened source and was not modified). Wrote `docs/handoff/00_README_AND_EXECUTION_GUIDE.md`. Rewrote this tracker so it matches commands run in this session. No game code, Godot project, or Blender script was created.

- 01: pinned Godot 4.7.2.stable.official.ed1daf0bf and Blender 5.2.3 LTS after running them. Wrote `docs/TECHNICAL_PLAN.md`. Appended D-035–D-039 and C-19–C-25 in `docs/DECISIONS.md`. Chose Compatibility. No game code or Godot project was created.

- 02: created the Godot 4.7.2 Compatibility project, log autoload, headless test runner, Python validator, and launchers. Launchers refuse Godot 4.0. No gameplay.

- 03: added the integer toolkit, seeded RNG, FNV-1a hash, JSON `Result` loader, architecture note, and sim purity check. `SimConstants` has the tick rate and millimetre scale only. No combat.

- 04: added `tools/status/status_check.py`, `update_status.py`, `dependencies.json`, handoff template and index, and `docs/PROCESS.md`. Installed Godot 4.7.2 export templates. Ran `gdtoolkit` 4.5.0 and the bash launchers. No gameplay.

- 05: added the fixed-tick match sim, Theron and Atalanta data, three starter moves, the greybox scene, and `docs/playtest/CHECKPOINT_A.md`. Main scene is `scenes/match/match_prototype.tscn`. No limbs, no Blender, no extra abilities.

- 06: split the combat sim, added limb hurtboxes, block, stamina, dodge, grab, combo records, hit-stop, and replay checks. Golden hash regenerated because the hashed state grew. No severing.

## Tests (latest run)

- 103 Godot tests, 0 failed/skipped; 23 replay fixtures. Full tools/check_all.ps1 with asset regeneration, Python validators, status tests, gdlint and gdformat. Logs build/check14_final.log.

- 400 AI matches completed without stalls/invariant failures in stage 09; difficulty gaps remain provisional.

- 40 compatible replacement attachments validated in Python and Godot. Asset builds reproducible by manifest byte comparison. Four roster models, three arenas, five replacement models generated and window previews inspected.

- Checkpoint B defects corrected; owner requested stage 14 continuation. Retest pending for feel/style. Full game export remains stage 23. Root certificate-store warning is environmental; no networking used.

## Known Bugs and Blockers

| ID | Severity | Description | Stage found | Status |
|---|---|---|---|---|
| B-001 | Closed: Godot version gate | 4.0 was rejected. Pinned binary is 4.7.2.stable.official.ed1daf0bf. | 01 | CLOSED |
| B-002 | Closed: Blender is present | `D:\blender\blender.exe` is Blender 5.2.3 LTS and imports `bpy` and `bmesh`. | 00 | CLOSED |
| B-003 | Export templates | `4.7.2.stable` is installed. A throwaway export exited 0. The game export remains stage 23. | 01 | CLOSED |
| B-004 | gdtoolkit | `gdformat` and `gdlint` 4.5.0 run. After the style fixes, both exited 0 on `src` and `tests`. | 02 | CLOSED |
| B-005 | Bash launchers | `D:\Git\bin\bash.exe tools/check_all.sh` exited 0 and invoked `tools/run_tests.sh`. | 02 | CLOSED |

## Decisions Made

- Stage 01 added D-035 (DEFAULT, sever rule), D-036 (DEFAULT, both-arms moves), D-037 (PROPOSED, no CC0 claim), D-038 (DEFAULT, stamina), and D-039 (DEFAULT, Compatibility renderer). Rows C-19 through C-25 record the resolutions. No LOCKED row was edited.

- 2026-10-24: the owner approved D-003 (2.5D lane, no sidestep) and D-009 (five regrown limbs, shared skeleton and sockets, no extra limbs without a new approval). The record is section D of `docs/DECISIONS.md`. Locked wording was not rewritten.

- Reference `docs/DECISIONS.md`. Locked MVP and D-001 through D-034 stand as written. D-032 and D-037 remain PROPOSED.

- 2026-10-24 stage 05: speed curve millimetres per tick `[0, 6, 10, 14, 20, 26]`, power percent `[0, 70, 85, 100, 115, 130]`. A tied timeout replays once, then one `range_i(0, 2)` awards the round. Jab knockback is 0. These live in data files. No locked row was rewritten. D-003 lane and D-009 limbs were not expanded.

- 2026-10-24 stage 06: block keep 30 percent, limb chip 25 percent, limb main 50 percent, head main 125 percent, toughness percents `[0, 80, 90, 100, 115, 140]`, stamina regen 1, stagger 20 ticks, buffer 6 ticks. Recorded in `data/balance/combat.json` and `docs/COMBAT_RULES.md`. No locked row was rewritten.

## Deferred / Proposed Work

- Deferred per scope: see `docs/DECISIONS.md` section C.

- Proposed (needs owner decision): D-032 Career quit rule. D-037 audio wording (do not call generated audio CC0). D-040 supersedes D-035 for pending next-hit severance.

## Owner Actions and Checkpoints

| Item | When | Status | Evidence returned |
|---|---|---|---|
| Pre-flight installs and approvals | before 00 | DONE | 2026-10-24: Git 2.54.0.windows.1, Python 3.14.5, Godot 4.7.2.stable.official.ed1daf0bf, and Blender 5.2.3 LTS are verified. D-003 and D-009 were approved. Export templates `4.7.2.stable` are installed (B-003 closed). |
| Checkpoint A | after 05 | PASS | 2026-10-24: owner replied Pass after playing the prototype (local commit 16cfe6b). |
| Checkpoint B | after 13 | FIXES IMPLEMENTED; RETEST | Owner reported limb damage/facing/UI issues and explicitly authorized stage 14. Corrected with gameplay regressions and window evidence; no unconditional owner PASS claimed. |
| Checkpoint C | after 20 | PENDING | |
| Legal/store owner-only items | after 22B | PENDING | |
| Checkpoint D | after 23 | PENDING | |
| Final release approval | after 24 | PENDING | |

## Next Recommended Action
Retest corrected main match (tools/playtest_checkpoint_b.ps1 -Main): facing, normal limb damage/severing, New match and Replacement limbs buttons. Stage 16 is COMPLETE. Next implementation step is A0 Animation Replacement and Stage 17.

## Next Prompt Filename

17_DATA_DRIVEN_ABILITIES_AND_BALANCING.md
## Session Log

| Date | Stage | Summary | Result |
|---|---|---|---|
| 2026-10-24 | 00 | Re-checked an early tracker draft that claimed COMPLETE before the handoff and pack copy existed. Hashes of the existing docs matched the D: pack. Copied the pack into the project root, recorded the toolchain from commands run this session, and wrote the stage 00 handoff. No game code. | COMPLETE |
| 2026-10-24 | 01 | Ran the owner-supplied Godot 4.0 console binary and Blender 5.2.3 LTS. Headless Godot and background Blender both exited 0. Rejected Godot 4.0 under D-001. Did not pin versions, choose a renderer, or write the technical plan. | BLOCKED |
| 2026-10-24 | 01 | Pinned Godot 4.7.2.stable.official.ed1daf0bf and Blender 5.2.3 LTS. Headless smoke printed GODOT_SMOKE_OK. Wrote the technical plan, chose Compatibility, and recorded D-035 through D-039. | COMPLETE |
| 2026-10-24 | 02 | Audited the 4.7.2 and Blender binaries, confirmed no project and no 4.0 project references, then added the scaffold. check_all.ps1 exited 0. A deliberate failing assertion exited 1 and was removed. | COMPLETE |
| 2026-10-24 | 03 | Added the integer toolkit, RNG, hash, data loader, and sim purity check. The first purity test missed `ENetMultiplayerPeer`; the prefix pattern fixed it. A temporary `randf()` failed validation and was removed. The later `check_all.ps1` exited 0 (25 Godot tests, 7 Python tests). Owner approvals for D-003 and D-009 were recorded. | COMPLETE |
| 2026-10-24 | 04 | Added the tracker checker and closed B-003, B-004, and B-005. | COMPLETE |
| 2026-10-24 | 05 | Greybox local 1v1 prototype. Godot 35 passed, scripted hash matched, and one windowed still was saved. Checkpoint A is still pending. | COMPLETE |
| 2026-10-24 | 05 | Owner replied Pass for Checkpoint A after the first play test. Restored the explicit 60 Hz physics tick the editor had removed. | COMPLETE |
| 2026-10-24 | 06 | Combat core added. Godot 49 passed. Replay matched. Fuzz reported 0 crashes over 480000 ticks. | COMPLETE |
| 2026-10-24 | 07 | Stage 07 complete: 65 Godot tests and full check_all passed; early four-fighter three-arena art generated and window inspected. | COMPLETE |
| 2026-10-24 | 08 | Stage 08 complete: all 16 body masks move and hit; 73 tests and 18 replays pass. | COMPLETE |
| 2026-10-24 | 09 | Stage 09: 400 complete AI matches, no failures, 200 comparisons per difficulty step; early art pipeline improved while soak ran. | COMPLETE |

| 2026-10-24 | 10–13 | HUD, reproducible pipeline, shared rigs and five regrown limbs complete. 93 tests, 23 replays and 40 attachment cases pass. Checkpoint B awaits owner testing. | COMPLETE |
| 2026-10-24 | 14 | Fixed reported Checkpoint B defects and completed stage 14 at owner request. 103 tests, full pose matrices and corrected 64-match soak pass; retest requested. | COMPLETE |
