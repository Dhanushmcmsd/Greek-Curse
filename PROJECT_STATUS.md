# PROJECT_STATUS.md - Severed: Trials of Olympus

> Single source of truth. Cursor updates this file at the end of **every** stage (use `tools/status/update_status.py` once stage 04 exists). If a session is interrupted, open the project and paste `RESUME_PROMPT.md`.
> Status values: NOT_STARTED, IN_PROGRESS, COMPLETE, PARTIAL, BLOCKED.

## Environment
- OS / shell: Windows 10 Pro 10.0.19045, PowerShell 5.1.19041.6456. WMI caption: Microsoft Windows 10 Pro.
- GODOT_BIN (path, version): PINNED `D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` — `4.7.2.stable.official.ed1daf0bf` (`--version`, exit 0, 2026-10-24). The parent path is a directory. GUI sibling `Godot_v4.7.2-stable_win64.exe` was not the process that printed the version. Godot 4.0 at `D:\Godot_v4.0-stable_win64.exe\Godot_v4.0-stable_win64_console.exe` remains installed and is not the pin. Official Windows page the same date lists 4.7.2 stable (18 August 2026).
- BLENDER_BIN (path, version): PINNED `D:\blender\blender.exe` — Blender 5.2.3 LTS, build 2026-10-22, hash e13b728c6880, branch blender-v5.2-release. `bpy.app.version_string` printed `5.2.3 LTS`. `import bmesh` printed `BMESH_OK=bmesh`. `bpy.ops.export_scene.gltf` exists (`GLTF_EXPORT=True`). No mesh was exported. https://www.blender.org/download/lts/ on 2026-10-24 lists 5.2 LTS updated to 5.2.3 on 22 October 2026.
- PYTHON_BIN (path, version): `C:\Users\Admin\AppData\Local\Programs\Python\Python314\python.exe` — Python 3.14.5 (tags/v3.14.5:5607950, MSC v.1944 64 bit AMD64). `python`, `py -3`, and `python3` all printed 3.14.5. `python3` is invoked through `C:\Users\Admin\AppData\Local\Microsoft\WindowsApps\python3.exe`; `sys.executable` is the Python 3.14.5 path above.
- Git version / repo state: git version 2.54.0.windows.1 (`D:\Git\cmd\git.exe`). Repository initialised in stage 02. See the session log for the commit. No Git LFS.
- Godot export templates installed for pinned version: no. `%APPDATA%\Godot\export_templates` has 0 files. `4.7.2.stable` is absent. Not installed (B-003).
- Capabilities: can_run_godot_windowed=unknown, can_render_screenshots=unknown, can_run_blender_render=unknown. One primary display is present (1600x900). Headless Godot 4.7.2 and background Blender both ran. Windowed Godot, screenshots, and a Blender render were not run. Disk free this session: C: 8,034,889,728 bytes at the templates listing; D: 191.09 GB; E: 195.87 GB (D/E from earlier WMI the same night).
- Renderer chosen: Compatibility (D-039). Godot 4.7 decal docs say Decal nodes are Forward+ and Mobile only. Blood uses pooled flat quads.
- Dev machine specs (for performance notes): AMD Ryzen 5 5600X, 6 cores / 12 threads. WMI `TotalPhysicalMemory` 17103278080 bytes (~15.9 GiB). GPU: NVIDIA GeForce GTX 1650, WMI `AdapterRAM` 4293918720 bytes (~4.0 GB; WMI VRAM figures are often inaccurate).

## Current Stage
- Stage: 03 (COMPLETE)
- Started / last updated: 2026-10-24

## Stage Table
| ID | Stage | Status | Last updated | Handoff file |
|---|---|---|---|---|
| 00 | Readme And Execution Guide | COMPLETE | 2026-10-24 | docs/handoff/00_README_AND_EXECUTION_GUIDE.md |
| 01 | Project Audit And Technical Plan | COMPLETE | 2026-10-24 | docs/handoff/01_PROJECT_AUDIT_AND_TECHNICAL_PLAN.md |
| 02 | Project Scaffold And Development Tools | COMPLETE | 2026-10-24 | docs/handoff/02_PROJECT_SCAFFOLD_AND_DEVELOPMENT_TOOLS.md |
| 03 | Core Architecture And Coding Rules | COMPLETE | 2026-10-24 | docs/handoff/03_CORE_ARCHITECTURE_AND_CODING_RULES.md |
| 04 | Progress Tracker And Handoff Protocol | NOT_STARTED | | |
| 05 | First Playable Prototype | NOT_STARTED | | |
| 06 | Combat Simulation And Hit Detection | NOT_STARTED | | |
| 07 | Limb Integrity Severing And Stump Caps | NOT_STARTED | | |
| 08 | Body State Movement And Input | NOT_STARTED | | |
| 09 | Fighter Ai And Local 1V1 | NOT_STARTED | | |
| 10 | Combat Ui Feedback And Round Flow | NOT_STARTED | | |
| 11 | Blender Python Asset Pipeline | NOT_STARTED | | |
| 12 | Shared Skeleton Modular Fighters And Sockets | NOT_STARTED | | |
| 13 | Regrown Limbs And Attachment Validation | NOT_STARTED | | |
| 14 | Animation And Code Driven Motion | NOT_STARTED | | |
| 15 | Arenas Lighting Camera And Vfx | NOT_STARTED | | |
| 16 | Audio Ui And Accessibility | NOT_STARTED | | |
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
- Stage 00 onboarding files are in the project root and were re-checked on 2026-10-24. No game feature has been built or run.

## Files and Systems Changed
- 00: confirmed existing byte copies of `RESUME_PROMPT.md`, `docs/DECISIONS.md`, `docs/source/GDD_extracted.txt`, `docs/source/BUILD_REQUIREMENTS_extracted.txt`, and both revised PDFs in `docs/source/`. Copied the read-only pack to `Severed_Cursor_Prompt_Pack/` (the D: pack was the opened source and was not modified). Wrote `docs/handoff/00_README_AND_EXECUTION_GUIDE.md`. Rewrote this tracker so it matches commands run in this session. No game code, Godot project, or Blender script was created.
- 01: pinned Godot 4.7.2.stable.official.ed1daf0bf and Blender 5.2.3 LTS after running them. Wrote `docs/TECHNICAL_PLAN.md`. Appended D-035–D-039 and C-19–C-25 in `docs/DECISIONS.md`. Chose Compatibility. No game code or Godot project was created.
- 02: created the Godot 4.7.2 Compatibility project, log autoload, headless test runner, Python validator, and launchers. Launchers refuse Godot 4.0. No gameplay.
- 03: added the integer toolkit, seeded RNG, FNV-1a hash, JSON `Result` loader, architecture note, and sim purity check. `SimConstants` has the tick rate and millimetre scale only. No combat.

## Tests (latest run)
- Date / command: 2026-10-24. `powershell -NoProfile -File tools/check_all.ps1` using `D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`. Godot suite: 25 passed, 0 failed, 0 skipped. `python -m unittest discover -s tools/validate -p "test_*.py"`: 7 tests, OK. `validate_all.py`: PASS. `--check-only` on `tests/run_all.gd` and `src/core/log.gd` ran. Exit 0.
- Passed / failed / skipped: check_all PASS. An earlier run the same night failed one Python case because `\bENet\b` missed `ENetMultiplayerPeer`; the pattern is now a prefix. A temporary `randf()` in `src/sim/sim_constants.gd` made `validate_all.py` exit 1 (`forbidden randf`) and was removed before the green run. The stage 02 deliberate assertion failure is historical and is not in the tree.
- Fast suite / full suite: fast suite is `tools/check_all.ps1`. Full regression suite is stage 21.
- Notes (UNVERIFIED items): bash launchers were not run (B-005). `gdtoolkit` is absent (B-004). Windowed Godot, screenshots, and a Blender render were not run. Export templates are absent (B-003). A real glTF file was not exported.

## Known Bugs and Blockers
| ID | Severity | Description | Stage found | Status |
|---|---|---|---|---|
| B-001 | Closed: Godot version gate | 4.0 was rejected. Pinned binary is 4.7.2.stable.official.ed1daf0bf. | 01 | CLOSED |
| B-002 | Closed: Blender is present | `D:\blender\blender.exe` is Blender 5.2.3 LTS and imports `bpy` and `bmesh`. | 00 | CLOSED |
| B-003 | Blocks stage 23 export | Godot 4.7.2 export templates are not installed. `%APPDATA%\Godot\export_templates` is empty. | 01 | OPEN |
| B-004 | Lint tools absent | `gdtoolkit` is not installed. Godot `--check-only` is the script check. | 02 | OPEN |
| B-005 | Bash launchers unverified | `tools/run_tests.sh` and `tools/check_all.sh` were not executed. PowerShell launchers were. | 02 | OPEN |

## Decisions Made
- Stage 01 added D-035 (DEFAULT, sever rule), D-036 (DEFAULT, both-arms moves), D-037 (PROPOSED, no CC0 claim), D-038 (DEFAULT, stamina), and D-039 (DEFAULT, Compatibility renderer). Rows C-19 through C-25 record the resolutions. No LOCKED row was edited.
- 2026-10-24: the owner approved D-003 (2.5D lane, no sidestep) and D-009 (five regrown limbs, shared skeleton and sockets, no extra limbs without a new approval). The record is section D of `docs/DECISIONS.md`. Locked wording was not rewritten.
- Reference `docs/DECISIONS.md`. Locked MVP and D-001 through D-034 stand as written. D-032 and D-037 remain PROPOSED.

## Deferred / Proposed Work
- Deferred per scope: see `docs/DECISIONS.md` section C.
- Proposed (needs owner decision): D-032 Career quit rule. D-037 audio wording (do not call generated audio CC0). D-035 is the working sever rule and can be overridden before stage 07.

## Owner Actions and Checkpoints
| Item | When | Status | Evidence returned |
|---|---|---|---|
| Pre-flight installs and approvals | before 00 | PENDING | 2026-10-24: Git 2.54.0.windows.1, Python 3.14.5, Godot 4.7.2.stable.official.ed1daf0bf, and Blender 5.2.3 LTS are verified. D-003 and D-009 were approved the same date. Export templates are not installed (B-003), so this row stays pending. |
| Checkpoint A | after 05 | PENDING | |
| Checkpoint B | after 13 | PENDING | |
| Checkpoint C | after 20 | PENDING | |
| Legal/store owner-only items | after 22B | PENDING | |
| Checkpoint D | after 23 | PENDING | |
| Final release approval | after 24 | PENDING | |

## Next Recommended Action
Open a new Cursor Agent chat and run prompt `04_PROGRESS_TRACKER_AND_HANDOFF_PROTOCOL.md`. Keep using the pinned Godot 4.7.2 console executable. Install Godot 4.7.2 export templates before stage 23. Do not add limbs or sidestep movement without a new approval.

## Next Prompt Filename
04_PROGRESS_TRACKER_AND_HANDOFF_PROTOCOL.md

## Session Log
| Date | Stage | Summary | Result |
|---|---|---|---|
| 2026-10-24 | 00 | Re-checked an early tracker draft that claimed COMPLETE before the handoff and pack copy existed. Hashes of the existing docs matched the D: pack. Copied the pack into the project root, recorded the toolchain from commands run this session, and wrote the stage 00 handoff. No game code. | COMPLETE |
| 2026-10-24 | 01 | Ran the owner-supplied Godot 4.0 console binary and Blender 5.2.3 LTS. Headless Godot and background Blender both exited 0. Rejected Godot 4.0 under D-001. Did not pin versions, choose a renderer, or write the technical plan. | BLOCKED |
| 2026-10-24 | 01 | Pinned Godot 4.7.2.stable.official.ed1daf0bf and Blender 5.2.3 LTS. Headless smoke printed GODOT_SMOKE_OK. Wrote the technical plan, chose Compatibility, and recorded D-035 through D-039. | COMPLETE |
| 2026-10-24 | 02 | Audited the 4.7.2 and Blender binaries, confirmed no project and no 4.0 project references, then added the scaffold. check_all.ps1 exited 0. A deliberate failing assertion exited 1 and was removed. | COMPLETE |
| 2026-10-24 | 03 | Added the integer toolkit, RNG, hash, data loader, and sim purity check. The first purity test missed `ENetMultiplayerPeer`; the prefix pattern fixed it. A temporary `randf()` failed validation and was removed. The later `check_all.ps1` exited 0 (25 Godot tests, 7 Python tests). Owner approvals for D-003 and D-009 were recorded. | COMPLETE |
