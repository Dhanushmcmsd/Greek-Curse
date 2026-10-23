# Stage 01: Project Audit And Technical Plan

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Senior game director and technical lead. You audit the workspace and source documents and produce a verified technical plan. You write no game code.

## 2. Context
Stage 00 is COMPLETE. The workspace contains the tracker, decisions file and reference text. No Godot project exists unless the owner started one.

## 3. Objective
Verify the toolchain by actually running it, pin versions, confirm or conservatively amend the decisions in `docs/DECISIONS.md`, and write `docs/TECHNICAL_PLAN.md` that every later stage can rely on.

## 4. Prerequisites
1. Stage 00 COMPLETE.

## 5. Workspace inspection
1. `PROJECT_STATUS.md`, `docs/DECISIONS.md`, `docs/handoff/00_*.md`.
2. Run and record: `git --version`, `python3 --version`, `$GODOT_BIN --version` (or `godot --version`), `$BLENDER_BIN --version` (or `blender --version`). Find executables via PATH and common install locations for the owner's OS.
3. Existing project files: `project.godot`, `*.gd`, `*.tscn`, `*.blend`, `*.py`, anything under `assets/`.
4. Both reference texts: re-scan GDD sections 5-7, 13-14, 17, Production Addendum, and Build Requirements sections 2, 4, 9 and the Revised MVP Build Plan.

## 6. Implementation tasks
1. Detect Godot and Blender executables. Record absolute paths in `PROJECT_STATUS.md` (`GODOT_BIN`, `BLENDER_BIN`, `PYTHON_BIN`). Pin the exact Godot 4.x stable version and Blender version found (require Godot >= 4.3 and Blender LTS >= 4.2; if older or missing, report as BLOCKED with install steps). If network access is available, check the official download pages to confirm these are current stable releases and record the check date; otherwise record 'not checked'.
2. Prove headless operation: run Godot headless with `--version` and a trivial `--script` that prints and quits; run Blender in `--background` with `--python-expr "import bpy; print(bpy.app.version_string)"`. Record real output. Check whether Godot export templates for the pinned version are installed (look in the user data templates directory) and record yes/no; do not install.
3. Check available disk space and whether the machine has a display/GPU (affects screenshot and render verification). Record the capabilities: `can_run_godot_windowed`, `can_render_screenshots`, `can_run_blender_render`.
4. Review `docs/DECISIONS.md` against the source documents. For each decision confirm it is feasible with the pinned versions. Do **not** reverse a locked MVP decision. If something is infeasible, propose the most conservative amendment as a new `D-xxx` entry marked `PROPOSED` and flag it for the owner in `PROJECT_STATUS.md`.
5. Identify additional contradictions, missing technical decisions and unrealistic requirements not already in DECISIONS.md and append them with resolutions (conservative, MVP-preserving).
6. Write `docs/TECHNICAL_PLAN.md`: tool versions; module map and dependency direction (core <- sim <- presentation/ui/ai/input; persistence/progression depend on core/sim data only); data flow per tick; the fixed-point/determinism strategy; asset pipeline overview (Blender scripts -> `.glb` -> Godot import); test strategy per layer; risk register (top 10 risks with mitigation); milestone map to prompts 02-24; performance budget assumptions; list of every manual task and the checkpoint it belongs to.
7. Choose and document the renderer: Compatibility vs Forward+ (default to Compatibility if it supports the features the plan needs on the pinned Godot version, because the GDD targets mid-range integrated graphics; verify feature support from the installed version's documentation; record findings, including whether Decal nodes are supported - flat quad splats are the fallback).
8. Update `PROJECT_STATUS.md`: stage 01 status, pinned versions, capabilities, risks, next action = prompt 02.

## 7. Technical constraints
1. No game code. No project scaffolding (stage 02).
2. Every version number in the plan must come from a command you actually ran, or be labelled 'unverified'.
3. Do not recommend paid tools or online services.
4. Keep the plan under ~600 lines; it must be a usable reference, not an essay.

## 8. Files and outputs
1. `docs/TECHNICAL_PLAN.md`
2. Updated `docs/DECISIONS.md`, `PROJECT_STATUS.md`
3. `docs/handoff/01_PROJECT_AUDIT_AND_TECHNICAL_PLAN.md`

## 9. Automated tests
1. None yet. Verification is by recorded command output.

## 10. Execution and verification
1. Run each version command and paste output into the handoff.
2. Run the Godot headless smoke script and the Blender background smoke command; show real output.
3. Confirm `docs/TECHNICAL_PLAN.md` has every section listed in task 6 (use `grep -n '^## '`).

## 11. Acceptance criteria
1. Godot and Blender versions are pinned from real command output (or the stage is BLOCKED with exact install steps).
2. Headless Godot and background Blender both executed successfully (or the failure is recorded with cause).
3. Renderer choice documented with the reasoning and verification source.
4. `docs/TECHNICAL_PLAN.md` complete; DECISIONS.md amendments (if any) flagged PROPOSED and no locked decision silently changed.
5. Capabilities (windowed/screenshot/render) recorded.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/01_PROJECT_AUDIT_AND_TECHNICAL_PLAN.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No Godot project creation.
2. Do not start any implementation, even 'quick spikes'.
3. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
