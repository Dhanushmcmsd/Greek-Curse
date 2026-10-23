# Stage 00 handoff — Readme And Execution Guide

Stage result: **COMPLETE**. No game code, Godot project, or Blender script was created. Stage 01 was not started.

## (a) Game summary

*Severed: Trials of Olympus* is a free, low-poly Greek-myth fighting game in which a fighter's body is the save file. Players fight in short best-of-three rounds, damage individual limbs with deliberate combos, and can lose an arm or a leg. A broker named Obol trades an unlocked ability for a strange replacement limb. The long-term design is an online persistent career. The locked first version is local only: a deterministic side-view fight on one shared generated skeleton, with a small roster, a small move list, and no purchases.

## (b) Locked MVP

From `docs/DECISIONS.md` (D-001 through D-034). These numbers override the older full-game counts.

- Godot 4.x, GDScript only. Blender LTS generates `.glb` files through Python. No third-party addons unless a later decision records owner approval.
- Local play only: Career, Fresh Body, Local Versus, and Practice. One living Career fighter, unlock offers, Obol trades, a basic Chronicle, local saves, and a minimal Retire action.
- 4 fighters: Theron the Bulwark, Atalanta, Pyrrhus "Stub", Sibyl.
- 3 arenas: Mount Olympus (lightning), Athens Colosseum (sand hides decals; D-007 says no sim hazard), Tartarus Pits (lava vents).
- 21 abilities. Starter kit: Jab of Hermes, Cyclops Smash, Pegasus Kick.
- 5 regrown limbs: Rubber Chicken Arm, Cyclops Giant Hand, Crab Claw Arm, Marble Statue Leg, Hermes Sandal Leg.
- Combat is a fixed 60 Hz simulation in integer millimetres, with a seeded PRNG. No Godot physics, wall clock, or floats in the rules. Rendering is side-on 2.5D. There is no sidestep in the MVP.
- Severing removes a whole limb at the shoulder or hip and shows a stump cap. The head cannot be severed. Dedicated motion is specified for hop, crawl, and Torso Mode. Other motion is a code-driven pose library.
- Generated `.glb`, audio, and icons are committed. Scripts stay authoritative. No Git LFS. The game stays free.

## (c) Deferred

Not stubs and not prerequisites: online rollback, matchmaking, ranked play, and a server-checked Chronicle; 4-player brawl; co-op bosses; spectator; the other 6 fighters; the other 5 arenas; the other 29 abilities; the other 5 regrown limbs; Death Match; Thunder Strike cinematic; Last Stand; Execution; Legacy; Hall of the Fallen; cosmetic and title unlocks; Chronicle share card; emote wheel and taunts; voice acting; one-handed layouts; modding; code signing; store submission. Prompt 25 is an optional plan and starts only if the owner asks.

## (d) Execution order

One prompt per Cursor Agent chat, and only after the previous row is COMPLETE with evidence. Stop at the human checkpoints.

| # | File | After it |
|---|---|---|
| 00 | `00_README_AND_EXECUTION_GUIDE.md` | |
| 01 | `01_PROJECT_AUDIT_AND_TECHNICAL_PLAN.md` | |
| 02 | `02_PROJECT_SCAFFOLD_AND_DEVELOPMENT_TOOLS.md` | |
| 03 | `03_CORE_ARCHITECTURE_AND_CODING_RULES.md` | |
| 04 | `04_PROGRESS_TRACKER_AND_HANDOFF_PROTOCOL.md` | |
| 05 | `05_FIRST_PLAYABLE_PROTOTYPE.md` | Checkpoint A |
| 06 | `06_COMBAT_SIMULATION_AND_HIT_DETECTION.md` | |
| 07 | `07_LIMB_INTEGRITY_SEVERING_AND_STUMP_CAPS.md` | |
| 08 | `08_BODY_STATE_MOVEMENT_AND_INPUT.md` | |
| 09 | `09_FIGHTER_AI_AND_LOCAL_1V1.md` | |
| 10 | `10_COMBAT_UI_FEEDBACK_AND_ROUND_FLOW.md` | |
| 11 | `11_BLENDER_PYTHON_ASSET_PIPELINE.md` | |
| 12 | `12_SHARED_SKELETON_MODULAR_FIGHTERS_AND_SOCKETS.md` | |
| 13 | `13_REGROWN_LIMBS_AND_ATTACHMENT_VALIDATION.md` | Checkpoint B |
| 14 | `14_ANIMATION_AND_CODE_DRIVEN_MOTION.md` | |
| 15 | `15_ARENAS_LIGHTING_CAMERA_AND_VFX.md` | |
| 16 | `16_AUDIO_UI_AND_ACCESSIBILITY.md` | |
| 17 | `17_DATA_DRIVEN_ABILITIES_AND_BALANCING.md` | |
| 18 | `18_FIGHTER_ROSTER_AND_MVP_CONTENT.md` | |
| 19 | `19_MATCH_RESULTS_PROGRESSION_AND_SAVES.md` | |
| 20 | `20_MAIN_MENU_SETTINGS_AND_GAME_FLOW.md` | Checkpoint C |
| 21 | `21_AUTOMATED_TESTS_AND_REGRESSION_SUITE.md` | |
| 22 | `22_PERFORMANCE_BUG_FIXING_AND_POLISH.md` | |
| 22B | `22B_LEGAL_COPYRIGHT_AND_STOREFRONT_REVIEW.md` | Legal/store owner items |
| 23 | `23_BUILD_EXPORT_AND_RELEASE_CHECKLIST.md` | Checkpoint D |
| 24 | `24_FINAL_ACCEPTANCE_AUDIT_AND_HANDOVER.md` | Final approval |
| 25 | `25_POST_MVP_ONLINE_AND_CONTENT_EXPANSION_PLAN.md` | Optional; owner request only |

Numeric order is the implementation order. Stage 05 is a real simulation with greybox art. Stages 06–08 deepen combat. Stages 11–13 replace greybox art. Stage 17 completes the 21 abilities. Stages 19–20 add progression and menus. `22B` sits between 22 and 23.

## (e) Human checkpoints

From `MANUAL_CHECKPOINTS.md`.

- **A, after 05.** Launch the greybox. Confirm two fighters, health, timer, movement, light/heavy/kick, a finished best-of-three, and restart. Judge whether controls feel immediate and the fight is readable. Return PASS or a bug report.
- **B, after 13.** Sever a limb through Bruised, Cracked, and Severed. Confirm one hit does not sever a healthy limb and a normal match takes at most two limbs. Try one arm, both arms, one leg, both legs, and torso mode. Attach all 5 regrown limbs to Theron and Pyrrhus. Return PASS or a bug report plus a looks list.
- **C, after 20.** Play the full local loop: age gate, all 4 fighters, all 3 arenas with hazards, Career save/continue, Fresh Body, Local Versus, Practice, and settings persistence. Judge placeholder audio and whether several matches are fun. Return PASS or bug and balance notes.
- **D, after 23.** Test the packaged build, not the editor, ideally on a machine without Godot or Blender. Check first launch, saves, a corrupt-save test, FPS, and the release notes. Return PASS or a bug report plus performance notes.

Also stop for the owner-only legal and store items after 22B, and for final go/no-go after 24. Publishing is the owner's action.

## (f) Unlisted tensions

These are not in `DECISIONS.md` section B. They are recorded here and were not resolved.

1. **Athens hazard.** The GDD arena table says the Athens crowd throws weapons when hype rises. The Build Requirements unique-asset row lists crowd-thrown spear, sword, and amphora. D-007 says Athens has no sim hazard and that sand only hides decals. Section B does not record that conflict. C-12 is a different issue (Custom Match versus an arena-select hazard toggle).
2. **Round length.** GDD section 3.3 says a round is 45 to 90 seconds. GDD section 5.2 and D-023 lock 90 seconds (5400 ticks). Section B does not mention the range.
3. **Cracked versus the next-hit sever.** The GDD state table says Cracked is 25% to 1% integrity and that the limb cannot be used, and that Severed is 0% during a Severance Combo. GDD section 7.3 also says that if integrity hits 0 outside a combo, the limb becomes Cracked and severs on the next hit. Those passages disagree. D-023 locks combo timing and the two-limb cap. It does not choose the non-combo zero rule.
4. **Tallest test body.** Build Requirements section 4 says to test animation on Argos (2.20 m) and Pyrrhus (1.55 m). Argos is not one of the four locked fighters. The tallest locked fighter is Theron at 2.05 m. C-08 covers socket tests against 10 fighters, not this height pair.
5. **Both-arms attacks.** The GDD missing-limb table gives a fighter with both arms gone a headbutt, a shoulder charge, and a bite. The Build Requirements body-state set says the same. D-013 budgets dedicated motion only for hop, crawl, and Torso Mode. C-02 covers Rigify and the 60–80 clip estimate, not these three attacks.
6. **Audio rights wording.** D-017 calls self-generated audio "CC0-equivalent". The GDD only says royalty-free or self-composed. `NOTES_MISSING_OR_REVIEW.md` item 5 says not to treat procedural audio as CC0. Section B does not record that wording gap. C-15 only says the 14–16 track and voice plan is unrealistic.
7. **Stamina is unspecified, not contradicted.** GDD section 5.2 and Build Requirements section 9 describe a stamina bar. No decision locks its numbers, and section C does not defer it. Left for stage 01 to flag. Not resolved here.

## Rules this stage is carrying forward

1. The revised GDD, the revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` are the source of truth. The locked MVP overrides older full-game scope.
2. A check counts only if it was actually run. Anything that could not be run is UNVERIFIED, with the reason.
3. `Severed_Cursor_Prompt_Pack/` stays read-only. Tests are not weakened or deleted to force a pass.

The stage loop is: inspect, implement, run the checks, fix failures, verify the acceptance criteria, update the tracker, and write the handoff. One stage per chat. Do not start a stage whose prerequisite is not COMPLETE.

## Changed files

- Created `docs/handoff/00_README_AND_EXECUTION_GUIDE.md`.
- Updated `PROJECT_STATUS.md` at the project root so the environment block, stage table, and next action match this session.
- Copied the pack to `E:\zeus balls\Severed_Cursor_Prompt_Pack\` (39 files, robocopy exit 1, which means "files copied"). The copy was required because D-027 puts the pack in the project root, and the folder had only been opened as a second workspace at `D:\Severed_Cursor_Prompt_Pack\Severed_Cursor_Prompt_Pack`. The D: original was not modified.
- Left in place, after SHA256 match against the pack: `RESUME_PROMPT.md`, `docs/DECISIONS.md`, `docs/source/GDD_extracted.txt`, `docs/source/BUILD_REQUIREMENTS_extracted.txt`, `docs/source/Severed_Trials_of_Olympus_GDD_Revised.pdf`, `docs/source/Severed_Trials_of_Olympus_Build_Requirements_Revised.pdf`.

An earlier tracker draft had already marked stage 00 COMPLETE and had described a handoff file and a pack copy that were not on disk. This session re-checked the tree and finished those two outputs before marking COMPLETE.

## Commands actually run

Working directory for project commands: `E:\zeus balls`.

- `cmd /c dir /a` on the project root. Result: `docs\`, `PROJECT_STATUS.md`, `RESUME_PROMPT.md`. Not a listing of game code.
- `cmd /c dir /s /a` on `docs`. Result: `DECISIONS.md`, empty `docs\handoff\`, and four files in `docs\source\` (two extracts, two PDFs).
- `cmd /c dir /a` on `D:\Severed_Cursor_Prompt_Pack\Severed_Cursor_Prompt_Pack`. Result: prompts 00–25, `22B`, control files, `reference\`, and both revised PDFs.
- `git --version` → `git version 2.54.0.windows.1`.
- `git status --short --branch` in `E:\zeus balls` → exit 128, `fatal: not a git repository (or any of the parent directories): .git`.
- `python --version`, `py -3 --version`, `python3 --version` → all `Python 3.14.5`.
- `python3 -c "import sys; print(sys.executable); print(sys.version)"` → `C:\Users\Admin\AppData\Local\Programs\Python\Python314\python.exe`, tags/v3.14.5:5607950, MSC v.1944 64 bit AMD64.
- `Get-Command` for `python`, `py`, `python3`, `git`. `godot` and `blender` were absent.
- `godot --version` → `CommandNotFoundException`.
- `blender --version` → `CommandNotFoundException`.
- `where.exe godot` and `where.exe blender` → not found.
- Uninstall-registry search for DisplayName matching Godot or Blender → no entries.
- Depth-4 search for `godot*.exe` and `blender.exe` under `C:\Program Files`, `C:\Program Files (x86)`, and `%LOCALAPPDATA%\Programs` → no files. Top-level directory names on `D:\` and `E:\` did not match Godot or Blender. A full-disk recursive search was not run.
- `winget --version` → `v1.29.380`.
- `winget search Godot` and `winget search Blender` → IDs recorded in the owner action below. Search was run on 2026-10-24. Official download pages were not fetched in this stage.
- WMI: OS caption `Microsoft Windows 10 Pro`; PowerShell `5.1.19041.6456`; CPU `AMD Ryzen 5 5600X`, 6 cores / 12 threads; `Win32_ComputerSystem.TotalPhysicalMemory` = 17103278080 bytes; GPU `NVIDIA GeForce GTX 1650`, `AdapterRAM` = 4293918720 bytes. WMI video-memory figures are often wrong.
- SHA256 of the six existing control/source files against the D: pack → all MATCH. Hashes are in the test section.
- `robocopy` of the pack into `E:\zeus balls\Severed_Cursor_Prompt_Pack` → 39 files copied, exit 1.
- SHA256 of copied `00_README_AND_EXECUTION_GUIDE.md` against the D: original → MATCH `91C77AF949CCD5B50AA48D781FCA6EC10B797A6177166E6AC147760C0006233F`.
- SHA256 of D: `DECISIONS.md` after the copy → still `FC7450B0D67D70C9BCEECC480AAED56B27A85686DC6342589E4DBC3A8B297D64` (source unchanged).

## Test results

No game tests exist. Verification is file existence, hash equality, directory listings, and the command output above.

| Check | Result |
|---|---|
| Root tracker, resume prompt, decisions, source texts, source PDFs | PASS, present and hashes match the pack |
| Pack installed at project-root `Severed_Cursor_Prompt_Pack\` | PASS, 39 files, sample hash matches, D: original unchanged |
| Handoff contains MVP, deferred list, order, checkpoints, unlisted tensions | PASS, this file |
| Game code absent | PASS, no `project.godot`, `.gd`, `.tscn`, `.blend`, or game `.py` was created |
| Godot version | UNVERIFIED — `godot` is not on PATH and was not found in the locations searched |
| Blender version | UNVERIFIED — `blender` is not on PATH and was not found in the locations searched |
| Export templates, windowed Godot, screenshots, Blender render | UNVERIFIED — both tools are missing |
| Git history | UNVERIFIED — there is no repository. `git init` belongs to stage 02 and was not run |

## Acceptance criteria

1. **PASS.** `PROJECT_STATUS.md`, `RESUME_PROMPT.md`, `docs/DECISIONS.md`, and `docs/source/` reference texts exist. Both revised PDFs are in `docs/source/` as well. The pack copy is in the project root.
2. **PASS.** This handoff restates the MVP, the deferred list, the order, and the checkpoints in the words above, and it follows `docs/DECISIONS.md`.
3. **PASS.** Godot 4 and Blender LTS are missing. Exact owner instructions are below. Git 2.54.0.windows.1 and Python 3.14.5 are present.
4. **PASS.** No game code was written.

## Known bugs and blockers

| ID | Severity | Description | Status |
|---|---|---|---|
| B-001 | Blocks stage 01 toolchain pinning | Godot 4 is not installed. | OPEN |
| B-002 | Blocks art-generation stages, and stage 01 Blender checks | Blender LTS is not installed. | OPEN |

Stage 00 itself does not need either tool. Prompt 01 says to mark that stage BLOCKED if they are still missing.

## Decisions made

No new `D-0xx`. `docs/DECISIONS.md` was already a byte copy of the pack and was not edited. The tensions in section (f) were not resolved. D-003 and D-009 remain locked with the owner's pre-flight override still open. D-032 remains PROPOSED.

## Owner action

Nothing was installed.

**Install request (asked once).** Approve these two commands, or install from the official pages and reply with the executable paths.

Godot 4 standard build, not the Mono build (D-001 is GDScript only):

- Official page: https://godotengine.org/download/windows/
- Package that winget reported on 2026-10-24: `GodotEngine.GodotEngine` version `4.7.2`
- Command, not yet run:

```
winget install --id GodotEngine.GodotEngine --version 4.7.2 --exact --source winget
```

Do not install `GodotEngine.GodotEngine.Mono`.

Blender LTS 4.2 or newer (D-002). Prefer the 4.5 LTS package. Winget also lists `BlenderFoundation.Blender` 5.2.3, which is not labeled LTS, and `BlenderFoundation.Blender.LTS.4.2` 4.2.16.

- Official LTS page: https://www.blender.org/download/lts/
- Package that winget reported on 2026-10-24: `BlenderFoundation.Blender.LTS.4.5` version `4.5.10`
- Command, not yet run:

```
winget install --id BlenderFoundation.Blender.LTS.4.5 --version 4.5.10 --exact --source winget
```

After either install, run `godot --version` and `blender --version`. If the executables are not on PATH, send the full paths. Blender scripts use Blender's bundled Python. The installed system Python 3.14.5 is the tooling interpreter and is not a substitute for `bpy`.

**Design reply, before stage 05, not required to close stage 00.** Reply "approved" or state the change you want for D-003 (2.5D lane combat, no sidestep) and D-009 (the five regrown limbs).

Git and Python 3 are already installed. No action for those.

## Next prompt to execute

`01_PROJECT_AUDIT_AND_TECHNICAL_PLAN.md`

Open it in a new Cursor Agent chat. If Godot and Blender are still missing, stage 01 should stop BLOCKED instead of pinning versions from memory.
