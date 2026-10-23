# Stage 00: Readme And Execution Guide

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Project onboarding engineer and release manager. You read the pack, place the reference material in the workspace, and confirm you understand the rules. You write **no game code** in this stage.

## 2. Context
The workspace may be empty or may contain early files. The Severed Cursor Prompt Pack folder has been copied into the project root by the owner. No stage has been executed.

## 3. Objective
Install the pack into the workspace correctly, make the two source documents readable to you, create the initial tracker, and prove you understand the execution order, the locked MVP, and the rules that apply to every later stage.

## 4. Prerequisites
1. None. This is the first prompt.
2. Owner has copied the whole `Severed_Cursor_Prompt_Pack/` folder (including `reference/`, `PROJECT_STATUS.md`, `DECISIONS.md`, `MANUAL_CHECKPOINTS.md`, `PROMPT_INDEX.md`, `RESUME_PROMPT.md`) into the project root and opened that folder in Cursor.

## 5. Workspace inspection
1. List the workspace root (`ls -la`) and run `git status` if a repository exists. Note any existing files; do not move or delete them.
2. Read every file in `Severed_Cursor_Prompt_Pack/` that is not a numbered prompt: `README.md`, `PROMPT_INDEX.md`, `DECISIONS.md`, `MANUAL_CHECKPOINTS.md`, `PROJECT_STATUS.md`, `RESUME_PROMPT.md`.
3. Read `Severed_Cursor_Prompt_Pack/reference/GDD_extracted.txt` and `BUILD_REQUIREMENTS_extracted.txt` completely (these are text extractions of the revised GDD and Build Requirements PDFs; if the original PDFs are present in the workspace, note their paths).
4. Skim the headings of prompts 01-25 to understand the dependency chain.

## 6. Implementation tasks
1. Create `docs/` and `docs/handoff/`, `docs/source/`. Copy `Severed_Cursor_Prompt_Pack/DECISIONS.md` to `docs/DECISIONS.md` and `Severed_Cursor_Prompt_Pack/PROJECT_STATUS.md` to `PROJECT_STATUS.md` and `Severed_Cursor_Prompt_Pack/RESUME_PROMPT.md` to `RESUME_PROMPT.md` (only if those targets do not already exist; if they exist, diff and merge without losing content). Copy the reference text files into `docs/source/` (and the PDFs too if present).
2. Fill the *Environment* block at the top of `PROJECT_STATUS.md` with what you can detect right now (OS, shell, `git --version`, `python3 --version`, whether `godot` / `blender` are on PATH and their `--version`). Mark each missing tool as MISSING; do not install anything in this stage.
3. Write `docs/handoff/00_README_AND_EXECUTION_GUIDE.md` containing: (a) a one-paragraph summary of the game in your own words, (b) the locked MVP list, (c) the deferred list, (d) the execution order from `PROMPT_INDEX.md`, (e) the four human checkpoints and when they occur, (f) any apparent contradiction you notice between the two source documents and `DECISIONS.md` that is **not** already listed in `DECISIONS.md` (list it; do not silently resolve it).
4. If the owner's environment is missing Godot 4, Blender, Git or Python 3, produce a short, exact install-instruction list (official download pages; prefer package managers; verify versions after install) in the handoff and mark the Owner Action in `PROJECT_STATUS.md`.
5. Set stage 00 to COMPLETE in `PROJECT_STATUS.md` and set the next action to prompt 01.

## 7. Technical constraints
1. No game code, no Godot project creation, no Blender scripts in this stage.
2. Do not modify files inside `Severed_Cursor_Prompt_Pack/` (treat it as read-only).
3. Do not install software without owner approval; if a package manager install is possible, ask once, listing exactly what will be installed.

## 8. Files and outputs
1. `PROJECT_STATUS.md`, `RESUME_PROMPT.md` (root)
2. `docs/DECISIONS.md`, `docs/source/*`
3. `docs/handoff/00_README_AND_EXECUTION_GUIDE.md`

## 9. Automated tests
1. No game tests exist yet. Verification is by file-existence and content checks performed by you (see section 10).

## 10. Execution and verification
1. Run `ls` on each created path and show the output.
2. Run `git status` (if a repo exists) and show that no unrelated files changed.
3. Re-read `PROJECT_STATUS.md` and confirm the Environment block, stage table and next action are filled in.

## 11. Acceptance criteria
1. `PROJECT_STATUS.md`, `RESUME_PROMPT.md`, `docs/DECISIONS.md` and `docs/source/` reference texts exist in the workspace.
2. Handoff file contains the MVP list, deferred list, order, and checkpoint list in your own words and is consistent with `DECISIONS.md`.
3. Missing tools (if any) are listed with exact owner instructions.
4. No game code was written.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/00_README_AND_EXECUTION_GUIDE.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. Do not create the Godot project (stage 02).
2. Do not perform the audit/technical plan (stage 01).
3. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.

---
## Appendix A - Canonical conventions (referenced by every prompt)

- Engine: Godot 4.x, GDScript only; Blender LTS with Python (`bpy`/`bmesh`); no third-party addons unless the owner approves a recorded decision.
- Simulation: fixed 60 Hz; integer millimetres; seeded PRNG; no Godot physics, wall clock, or floats in combat rules. Rendering is side-on 2.5D.
- MVP: local 1v1; 4 fighters (Theron, Atalanta, Pyrrhus, Sibyl); 3 arenas (Mount Olympus, Athens Colosseum, Tartarus Pits); 21 abilities; 5 regrown limbs.
- Shared skeleton and socket-based severing; hide whole limb groups and show stump caps. Code-driven pose library; dedicated hop, crawl, and torso-only motion only.
- Data-driven fighter, ability, limb, arena, balance, and AI configuration. Generated `.glb` outputs are committed; scripts remain authoritative. No Git LFS.
- Tests must actually run; report command and result. Never claim an unexecuted check passed. Keep the prompt pack read-only.
- Deferred features are not stubs or prerequisites. Stop at owner checkpoints.


## Appendix B - Execution order and rules in one place

Run prompts strictly in this order, one per Cursor Agent session (new chat per stage is recommended). Each stage requires the previous stages to be COMPLETE in `PROJECT_STATUS.md`:

0. `00_README_AND_EXECUTION_GUIDE.md`
1. `01_PROJECT_AUDIT_AND_TECHNICAL_PLAN.md`
2. `02_PROJECT_SCAFFOLD_AND_DEVELOPMENT_TOOLS.md`
3. `03_CORE_ARCHITECTURE_AND_CODING_RULES.md`
4. `04_PROGRESS_TRACKER_AND_HANDOFF_PROTOCOL.md`
5. `05_FIRST_PLAYABLE_PROTOTYPE.md`
6. `06_COMBAT_SIMULATION_AND_HIT_DETECTION.md`
7. `07_LIMB_INTEGRITY_SEVERING_AND_STUMP_CAPS.md`
8. `08_BODY_STATE_MOVEMENT_AND_INPUT.md`
9. `09_FIGHTER_AI_AND_LOCAL_1V1.md`
10. `10_COMBAT_UI_FEEDBACK_AND_ROUND_FLOW.md`
11. `11_BLENDER_PYTHON_ASSET_PIPELINE.md`
12. `12_SHARED_SKELETON_MODULAR_FIGHTERS_AND_SOCKETS.md`
13. `13_REGROWN_LIMBS_AND_ATTACHMENT_VALIDATION.md`
14. `14_ANIMATION_AND_CODE_DRIVEN_MOTION.md`
15. `15_ARENAS_LIGHTING_CAMERA_AND_VFX.md`
16. `16_AUDIO_UI_AND_ACCESSIBILITY.md`
17. `17_DATA_DRIVEN_ABILITIES_AND_BALANCING.md`
18. `18_FIGHTER_ROSTER_AND_MVP_CONTENT.md`
19. `19_MATCH_RESULTS_PROGRESSION_AND_SAVES.md`
20. `20_MAIN_MENU_SETTINGS_AND_GAME_FLOW.md`
21. `21_AUTOMATED_TESTS_AND_REGRESSION_SUITE.md`
22. `22_PERFORMANCE_BUG_FIXING_AND_POLISH.md`
23. `22B_LEGAL_COPYRIGHT_AND_STOREFRONT_REVIEW.md`
24. `23_BUILD_EXPORT_AND_RELEASE_CHECKLIST.md`
25. `24_FINAL_ACCEPTANCE_AUDIT_AND_HANDOVER.md`
26. `25_POST_MVP_ONLINE_AND_CONTENT_EXPANSION_PLAN.md`

Human checkpoints: **A** after 05, **B** after 13, **C** after 20, **D** after 23, final approval after 24. See `MANUAL_CHECKPOINTS.md`.

Numeric order is the correct implementation order (no reordering is needed). Note that 05 builds a thin but real simulation vertical slice with greybox visuals; 06-08 deepen it; 11-13 replace greybox with generated art; 17 completes the ability set; 19-20 build progression and flow. Prompt `22B` is an addition to the requested file list (legal/storefront review) and runs between 22 and 23. Prompt 25 is optional and starts only on explicit owner request.

## Appendix C - Reading list for this stage's confirmation

When you finish, your handoff must restate in your own words: the locked MVP numbers (4 fighters, 3 arenas, 21 abilities, 5 regrown limbs), the deferred list, the stage loop, the checkpoint schedule, and the three most important rules from section 0. If you cannot, re-read the pack.
