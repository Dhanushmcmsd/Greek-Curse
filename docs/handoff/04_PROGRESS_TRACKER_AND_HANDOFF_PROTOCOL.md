# Stage 04 handoff — Progress Tracker And Handoff Protocol

Stage result: **COMPLETE**. The tracker is checked by `tools/status/status_check.py`. B-003, B-004, and B-005 are closed. No gameplay was added. Stage 05 was not started.

## Changed files

- Added `tools/status/status_check.py`, `update_status.py`, `dependencies.json`, `test_status.py`, and `__init__.py`.
- Added `docs/handoff/_TEMPLATE.md`, `docs/handoff/INDEX.md`, and `docs/PROCESS.md`.
- Updated `PROJECT_STATUS.md`, `RESUME_PROMPT.md`, `docs/KNOWN_ISSUES.md`, and `docs/CHANGELOG.md`.
- `tools/run_tests.ps1` and `tools/run_tests.sh` also run the status tests, `gdlint`, and `gdformat --check`. `tools/check_all.sh` uses `python3` or `python`.
- GDScript style fixes so `gdtoolkit` 4.5.0 exits 0: `class_name` before `extends`, line wraps, and one return in `DataLoader._type_ok`.
- Did not modify the prompt pack. Did not add an export preset to this game.

## Commands actually run

- `python -m pip show gdtoolkit` printed version 4.5.0. It was already installed. `gdlint src tests` first exited 1 with 13 findings. After the style fixes, `gdlint src tests` printed `Success: no problems found` and `gdformat --check src tests` printed `14 files would be left unchanged`.
- `curl.exe -L` downloaded `Godot_v4.7.2-stable_export_templates.tpz` to `D:\godot_template_cache`. Exit 0. Size 1,281,349,702 bytes, matching the HTTP `Content-Length`. `templates/version.txt` inside the archive is `4.7.2.stable`.
- Copied the 35 template files to `%APPDATA%\Godot\export_templates\4.7.2.stable`. `robocopy` returned 1, which means files were copied.
- Pinned Godot `--export-release "Windows Desktop"` on `D:\godot_template_cache\probe` (not this repo) exited 0 and wrote `probe.exe` of 109,127,680 bytes.
- `D:\Git\bin\bash.exe tools/check_all.sh` exited 0. It ran `tools/run_tests.sh`. Godot printed `4.7.2.stable.official.ed1daf0bf` and `Summary: 25 passed, 0 failed, 0 skipped`. Validator unittest: 7 OK. Status unittest: 12 OK. `validate_all: PASS`. `status_check: PASS`. `check_all: PASS`.
- `python -m unittest discover -s tools/status -p "test_*.py"` was also run on its own earlier: 12 tests, OK.
- The Next Prompt Filename line was temporarily set to `99_NOT_A_REAL_PROMPT.md`. `python tools/status/status_check.py` exited 1 and printed `next prompt does not exist: Severed_Cursor_Prompt_Pack/99_NOT_A_REAL_PROMPT.md`. `update_status.py next 05_FIRST_PLAYABLE_PROTOTYPE.md` restored it, and `status_check.py` then printed PASS.
- After stage 04 was marked COMPLETE, `D:\Git\bin\bash.exe tools/check_all.sh` was run again. Exit 0. Godot again printed 25 passed, 0 failed. Status tests 12 OK. `status_check: PASS`.

## Test results

| Check | Result |
|---|---|
| Godot unit tests | PASS. 25 passed, 0 failed, 0 skipped. |
| Python validator tests | PASS. 7 tests. |
| Python status tests | PASS. 12 tests. |
| `gdlint` and `gdformat --check` | PASS after the style fixes. The first `gdlint` run failed with 13 findings. |
| `validate_all.py` | PASS. |
| `status_check.py` on the pre-update tracker | PASS, during the bash `check_all`. |
| `tools/check_all.sh` | PASS. Exit 0, including a second run after stage 04 was marked COMPLETE. |
| Deliberate missing next prompt | PASS. `status_check.py` exited 1, then the filename was restored. |
| Throwaway export | PASS. Exit 0. This is not a game build. |
| Windowed Godot, screenshots, Blender render, glTF file | UNVERIFIED. Not run. |

## Acceptance criteria

1. **PASS.** `status_check.py` checks the required headings, the status vocabulary, `dependencies.json` copied from `PROMPT_INDEX.md`, a handoff file for every COMPLETE stage, and that the next prompt exists in `Severed_Cursor_Prompt_Pack/`.
2. **PASS.** Dry run of `RESUME_PROMPT.md`: read `PROJECT_STATUS.md` (stage 04 COMPLETE, next file `05_FIRST_PLAYABLE_PROTOTYPE.md`), run `status_check.py`, skip `INDEX.md` and `_TEMPLATE.md`, read this handoff, see that no stage is IN_PROGRESS, PARTIAL, or BLOCKED, and open prompt 05. Do not open prompt 05 in the session that finishes 04.
3. **PASS.** The stage table shows 00 through 04 COMPLETE and 05 onward NOT_STARTED. Handoff files exist for 00 through 04.

## Known bugs and blockers

| ID | Status | Notes |
|---|---|---|
| B-003 | CLOSED | Templates for 4.7.2 are installed. Game export is still stage 23. |
| B-004 | CLOSED | `gdtoolkit` 4.5.0 runs clean on `src` and `tests`. |
| B-005 | CLOSED | Git Bash ran `check_all.sh` and, through it, `run_tests.sh`. |

Windowed play, screenshots, and a Blender render are still UNVERIFIED. They are not blockers for stage 05's headless work.

## Decisions made

No new decision number. Locked rows were not edited. D-003 and D-009 stay approved as recorded in stage 03.

## Owner action

Play Checkpoint A when stage 05 says to stop. Do not add limbs or sidestep movement without a new approval.

## Next prompt to execute

`05_FIRST_PLAYABLE_PROTOTYPE.md`
