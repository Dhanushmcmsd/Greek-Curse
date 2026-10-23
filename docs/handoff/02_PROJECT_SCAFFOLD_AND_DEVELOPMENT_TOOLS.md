# Stage 02 handoff — Project Scaffold And Development Tools

Stage result: **COMPLETE**. The Godot 4.7.2 project imports headless, `tools/check_all.ps1` exits 0, and a deliberate failing assertion exits 1. No gameplay was written. Bash launchers were not executed on this Windows machine.

## Read-only audit before the scaffold

| Check | Result | Evidence |
|---|---|---|
| Godot 4.7.2 executable and version | PASS | `D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --version` printed `4.7.2.stable.official.ed1daf0bf`, exit 0. The parent path is a directory. |
| Blender executable and version | PASS | `D:\blender\blender.exe --version` printed `Blender 5.2.3 LTS`, hash `e13b728c6880`, exit 0. |
| `project.godot` before this stage | PASS | `E:\zeus balls\project.godot` did not exist. No scripts, export presets, or Blender generators existed. |
| References to Godot 4.0 in project code | PASS | Before the scaffold, 4.0 appeared only in docs that say not to use it. After the scaffold, `tools/run_tests.ps1`, `tools/check_all.ps1`, `tools/run_tests.sh`, and `tools/check_all.sh` mention `Godot_v4.0` only to refuse that path. `project.godot` does not point at it. |
| Minimal project opens on 4.7.2 | PASS | A temporary project under `%TEMP%\severed_godot472_open` imported with exit 0. `--script` printed `PROJECT_OPEN_OK` and `Severed Open Check`, exit 0. The first `.tscn` had a UTF-8 BOM and a parse error; rewriting it without a BOM reimported with no parse error. That temp folder is outside the game project. |
| Blender asset scripts | PASS | None exist. Nothing was generated or overwritten. |

## Changed files

- Created `project.godot`, `scenes/boot/boot.tscn`, `src/core/log.gd`, the test runner, validators, PowerShell and bash launchers, `VERSION`, changelog, known issues, asset ledger, conventions, `.gitignore`, `.gitattributes`, and the empty module folders.
- `tools/`, `docs/`, and `Severed_Cursor_Prompt_Pack/` have `.gdignore` so Godot does not import them.
- Updated `PROJECT_STATUS.md` and this handoff.
- Did not modify the prompt pack contents. Did not install gdtoolkit or export templates.

## Commands actually run

- Godot 4.7.2 `--version` and Blender `--version` (audit).
- Temp project `--import` and `--script` (audit). `python -m pip show gdtoolkit` reported the package was not found.
- `powershell -NoProfile -File tools/run_tests.ps1` after the log parse fix: 4 passed, 0 failed, then 3 Python unittest tests OK. Exit 0. Godot printed `4.7.2.stable.official.ed1daf0bf`.
- Same command with a temporary `assert_true(false, "deliberate")`: `FAIL test_smoke.test_deliberate_failure`, summary `4 passed, 1 failed`, `DELIBERATE_EXIT:1`. The assertion was removed.
- `powershell -NoProfile -File tools/check_all.ps1`: Godot suite 4 passed, unittest OK, `validate_all: PASS`, two `--check-only` runs, `status_check.py` absent (stage 04), `check_all: PASS`, exit 0.
- `build/test_results.json` exists and records 4 passed.

The first Godot import failed to compile `log.gd` (`Cannot infer the type of "level_name"`). The autoload was missing and the runner still printed PASS because the script error aborted the assertion. The type is now an explicit string, and the runner returns failure if the Log autoload node is missing. The re-run shows real ERROR and INFO lines from Log and then PASS.

## Test results

| Check | Result |
|---|---|
| Headless import and smoke tests | PASS. 4 passed, 0 failed. |
| Python `unittest` for the validator | PASS. 3 tests. |
| `validate_all.py` | PASS. |
| Deliberate failure | PASS. Exit 1 and the failure name were printed. The bad assertion is gone. |
| `tools/check_all.ps1` | PASS. Exit 0. |
| `tools/run_tests.sh` and `tools/check_all.sh` | UNVERIFIED. Not run. This machine used PowerShell. |
| `gdformat` / `gdlint` | Not run. `gdtoolkit` is not installed. |
| Windowed play, screenshots, Blender render | UNVERIFIED. Not launched. |

## Acceptance criteria

1. **PASS.** `project.godot` imports with Godot 4.7.2 headless. After the log fix, import reports no script error.
2. **PASS.** `tools/check_all.ps1` exits 0. A failing assertion makes `tools/run_tests.ps1` exit 1.
3. **PASS.** Folders match the module map in `docs/TECHNICAL_PLAN.md`: `src/{core,sim,presentation,ui,ai,input,persistence,progression}`, `scenes/{boot,ui,match,menus,debug}`, `data/` plus schema and content dirs, `assets/{fighters,arenas,audio,ui}`, `tests/{unit,assets,golden}`, `tools/{validate,status,sim,build}`. The pack never listed a second tree. `.gdignore` is on `tools/`, `docs/`, and the prompt pack.
4. **PASS.** Log autoload writes timestamped lines and `error_count` increases only on ERROR. The smoke tests read that counter.
5. **PASS.** `docs/CHANGELOG.md`, `docs/KNOWN_ISSUES.md`, `docs/ASSET_LEDGER.md`, and `docs/CONVENTIONS.md` exist. `VERSION` is `0.0.1-dev`.

## Known bugs and blockers

| ID | Status | Notes |
|---|---|---|
| B-003 | OPEN | Export templates for 4.7.2 are still absent. Stage 23. |
| B-004 | OPEN | `gdtoolkit` is not installed. Not required for this stage. |
| B-005 | OPEN | Bash launchers are unverified on Windows. |

## Decisions made

None. Renderer stays Compatibility (D-039). No locked decision was edited.

## Owner action

Before stage 05, reply **approved** or send a change for D-003 and D-009. Install Godot 4.7.2 export templates before stage 23. Do not open the project with Godot 4.0.

## Next prompt to execute

`03_CORE_ARCHITECTURE_AND_CODING_RULES.md`
