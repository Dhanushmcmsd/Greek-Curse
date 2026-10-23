# Stage 02: Project Scaffold And Development Tools

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Build/tooling engineer for Godot 4 projects.

## 2. Context
Stages 00-01 COMPLETE. Tool versions are pinned in `PROJECT_STATUS.md`. No Godot project exists yet (or only an empty one).

## 3. Objective
Create the Godot project skeleton, folder structure, Git configuration, and the one-command test/validation tooling that every later stage will use, proven with a passing smoke test.

## 4. Prerequisites
1. Stage 01 COMPLETE (pinned Godot and Blender, renderer decision, capabilities recorded).

## 5. Workspace inspection
1. `PROJECT_STATUS.md` (pinned versions, paths, renderer decision), `docs/TECHNICAL_PLAN.md`, `docs/DECISIONS.md`.
2. `git status`, existing `.gitignore`, `project.godot` if present (never overwrite an existing project without diffing).
3. Canonical layout in `00_README_AND_EXECUTION_GUIDE.md` Appendix A.

## 6. Implementation tasks
1. Initialise Git if not already a repository; make an initial commit of the docs and pack. Add `.gitignore` (Godot `.godot/`, `build/`, Blender `*.blend1`, `__pycache__/`, OS junk, `*.tmp`) and `.gitattributes` (LF normalisation, binary markers for `.glb`, `.png`, `.wav`, `.ogg`). **Do not use Git LFS** (D-026); generated `.glb` outputs are small and are committed.
2. Create `project.godot` for the pinned Godot version: project name `Severed: Trials of Olympus`, main scene placeholder, chosen renderer, 60 physics ticks per second, window size 1280x720 resizable, stretch mode `canvas_items`/`keep`, VSync on, and default InputMap actions are NOT created yet (stage 08). Create the folder tree from the canonical layout with `.gdignore`/`.gitkeep` as appropriate (`tools/`, `docs/`, `Severed_Cursor_Prompt_Pack/` must not be imported as game assets: add `.gdignore` files where needed).
3. Create `src/core/log.gd` (autoload `Log`): levels DEBUG/INFO/WARN/ERROR, timestamps, categories, and an in-memory ring buffer plus a file sink under `user://logs/`; ERROR lines also increment a counter the test runner can read.
4. Create the headless test framework with **no third-party dependency**: `tests/run_all.gd` (extends `SceneTree`) that discovers `tests/**/test_*.gd`, runs every `func test_*()` method, supports assertion helpers (`assert_eq`, `assert_true`, `assert_false`, `assert_near` for presentation-only code, `assert_raises_error_logged`), per-suite filtering with `-- --suite <name>`, a final summary, non-zero exit code on any failure, and a machine-readable `build/test_results.json`. Put helpers in `tests/test_base.gd` (class `TestBase`).
5. Add a smoke test `tests/unit/test_smoke.gd` (asserts Log works, test runner runs, project settings tick rate == 60).
6. Create `tools/run_tests.sh` and `tools/run_tests.ps1` that read `GODOT_BIN` (fall back to PATH/`PROJECT_STATUS.md`), run `--import` once if needed, then the Godot suite, and then the Python static checks. Create `tools/check_all.sh`/`.ps1` that runs the above plus `tools/validate/validate_all.py`, `tools/status/status_check.py` (once it exists) and prints a one-screen summary with a non-zero exit on failure.
7. Create `tools/validate/validate_all.py` as an extensible runner that imports validator modules from `tools/validate/` (JSON syntax check of everything under `data/`; JSON-schema-like shape checks driven by `data/schema/*.json` using only the Python standard library - write a tiny validator supporting `type`, `required`, `properties`, `enum`, `minimum`, `maximum`, `items`; reports file+path of each error). Add a trivial schema+data fixture under `tests/assets/` and a Python self-test (`tools/validate/test_validators.py` runnable with `python3 -m unittest`).
8. If `pip install gdtoolkit` works offline-safely and with no cost, add `gdformat`/`gdlint` configuration and a `tools/lint.sh`; if it cannot be installed, document the omission and rely on Godot's parser errors (`--check-only`). Never block the stage on linting.
9. Create `VERSION` (`0.0.1-dev`), `docs/CHANGELOG.md`, `docs/KNOWN_ISSUES.md`, `docs/ASSET_LEDGER.md` (table header: id, kind, path, author/tool, creation method, source files, date, license/terms, edits, notes), and `docs/CONVENTIONS.md` (copy canonical conventions and record version-specific notes).
10. Run the whole toolchain once and fix problems. Commit.

## 7. Technical constraints
1. GDScript only (no C#, no GDExtension). No third-party addons.
2. All scripts must work on Windows (PowerShell) and Linux/macOS (bash) - write both launchers; test the one for the owner's OS and mark the other `UNVERIFIED`.
3. Tests must be runnable without a display (`--headless`).
4. Do not write gameplay code.

## 8. Files and outputs
1. `project.godot`, `.gitignore`, `.gitattributes`, `VERSION`
2. `src/core/log.gd`
3. `tests/run_all.gd`, `tests/test_base.gd`, `tests/unit/test_smoke.gd`
4. `tools/run_tests.*`, `tools/check_all.*`, `tools/validate/validate_all.py`, `tools/validate/test_validators.py`, `data/schema/` seed
5. `docs/CHANGELOG.md`, `KNOWN_ISSUES.md`, `ASSET_LEDGER.md`, `CONVENTIONS.md`

## 9. Automated tests
1. `test_smoke.gd` as above.
2. Deliberate-failure check: temporarily add a failing assertion, confirm `tools/run_tests` exits non-zero and reports it, then remove it (show the evidence).
3. Python validator self-tests (unittest).

## 10. Execution and verification
1. `"$GODOT_BIN" --headless --path . --import` exits 0.
2. `tools/run_tests.sh` (or `.ps1`) exits 0 and prints the summary; confirm `build/test_results.json` exists.
3. `tools/check_all.sh` exits 0.
4. Run the deliberate-failure check and show non-zero exit.
5. `git log --oneline` shows commits; `git status` clean.

## 11. Acceptance criteria
1. Project opens/imports headlessly with no errors.
2. One command runs all tests and static checks and fails correctly on a failing test.
3. Folder layout matches the canonical layout exactly.
4. Log autoload works and ERROR count is exposed to tests.
5. Ledger, changelog, known-issues and conventions files exist.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/02_PROJECT_SCAFFOLD_AND_DEVELOPMENT_TOOLS.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No gameplay, no simulation code (stage 03/05).
2. No Blender scripts (stage 11).
3. No third-party addons or Git LFS.
4. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
