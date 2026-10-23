# Stage 03 handoff — Core Architecture And Coding Rules

Stage result: **COMPLETE**. Integer helpers, seeded RNG, FNV-1a hashing, the JSON loader, and the sim purity check are in the tree and covered by tests. No combat, UI, or art was added. Bash launchers were not executed.

## Changed files

- Added `docs/ARCHITECTURE.md`.
- Added `src/core/fx.gd`, `sim_rng.gd`, `state_hash.gd`, `data_loader.gd`, `result.gd`.
- Added `src/sim/sim_constants.gd` (`TICKS_PER_SECOND` and `MILLIMETRES_PER_METRE` only).
- Added `tools/validate/check_sim_purity.py` and `tools/validate/test_sim_purity.py`.
- Hooked `check_sim()` into `tools/validate/validate_all.py`. The script inserts the repo root on `sys.path` so `python tools/validate/validate_all.py` can import the package.
- Added `tests/unit/test_fx.gd`, `test_sim_rng.gd`, `test_state_hash.gd`, `test_data_loader.gd`, and `tests/assets/malformed.json`.
- `tools/run_tests.ps1` and `tools/run_tests.sh` now discover `tools/validate/test_*.py`. The shell launcher was not run.
- Appended typing, signals, `Result`, log categories, the data recipe, and commit style to `docs/CONVENTIONS.md`.
- Recorded the 2026-10-24 owner approvals of D-003 and D-009 in `docs/DECISIONS.md` section D. Locked decision text was not rewritten.
- Updated `docs/CHANGELOG.md`, `PROJECT_STATUS.md`, and this handoff.

## Commands actually run

- `powershell -NoProfile -File tools/check_all.ps1` before the `ENet` prefix fix: Godot summary `25 passed, 0 failed, 0 skipped`. Python unittest failed one case: `test_each_forbidden_token_fails` did not flag `ENetMultiplayerPeer` because `\bENet\b` required a word boundary after `ENet`. Exit 1. The pattern is now `\bENet` (and the same prefix form for `WebSocket`, `RigidBody`, and `CharacterBody`).
- `python -m unittest discover -s tools/validate -p "test_*.py"` after that fix: 7 tests, OK.
- `python tools/validate/validate_all.py` with a temporary `var _purity_probe = randf()` on line 7 of `src/sim/sim_constants.gd`: exit 1, message `src\sim\sim_constants.gd:7: forbidden randf`. That line was removed. The file again contains only the two integer constants.
- `powershell -NoProfile -File tools/check_all.ps1` after the revert: Godot `25 passed, 0 failed, 0 skipped`; Python `7 tests` OK; `validate_all: PASS`; two Godot `--check-only` runs; `status_check.py` absent (stage 04); `check_all: PASS`; exit 0. Godot printed `4.7.2.stable.official.ed1daf0bf`.

`tools/run_tests.sh` and `tools/check_all.sh` were not executed (B-005).

## Test results

| Check | Result |
|---|---|
| Godot unit tests | PASS. 25 passed, 0 failed, 0 skipped. Includes Fx, SimRng golden seed 1, StateHash golden stream `[1, 2, 3]`, DataLoader, and the stage 02 smoke tests. |
| Python validator and purity tests | PASS. 7 tests. |
| `validate_all.py` on the clean tree | PASS. |
| Temporary `randf()` in `src/sim/sim_constants.gd` | PASS. Checker exit 1 with `forbidden randf`. The probe was removed before the green `check_all`. |
| `tools/check_all.ps1` | PASS. Exit 0. |
| `tools/run_tests.sh` and `tools/check_all.sh` | UNVERIFIED. Not run. |
| `gdformat` / `gdlint` | Not run. `gdtoolkit` is not installed (B-004). |
| Windowed play, screenshots, Blender render | UNVERIFIED. Not launched. |
| Export templates | Absent (B-003). Not required for this stage. |

Golden values the Godot tests asserted:

- xorshift32 seed 1, first value `270369`, twentieth value `4283899417`.
- FNV-1a 64 of little-endian int bytes for `[1, 2, 3]`: low `1577918213`, high `3660315426`.

## Purity allow comments

`# sim-purity-ok: <reason>` skips one line. No file under `src/sim/` uses that comment. The mechanism is covered by `test_allow_comment_suppresses_the_line` in `tools/validate/test_sim_purity.py`.

## Acceptance criteria

1. **PASS.** `docs/ARCHITECTURE.md` and the stage 03 section of `docs/CONVENTIONS.md` match the code: `SimWorld.step` is described and not implemented; `SimConstants` has no combat rules.
2. **PASS.** Fx, SimRng, StateHash, Result, and DataLoader have headless unit tests, including the golden RNG sequence and golden hash.
3. **PASS.** `check_all.ps1` runs the purity checker through `validate_all.py`. A temporary `randf()` failed that check, then was removed.
4. **PASS.** The green `check_all.ps1` is the suite recorded above. The stage commit includes these files. Bash `check_all.sh` remains UNVERIFIED.

## Known bugs and blockers

| ID | Status | Notes |
|---|---|---|
| B-003 | OPEN | Export templates for 4.7.2 are still absent. Stage 23. |
| B-004 | OPEN | `gdtoolkit` is not installed. |
| B-005 | OPEN | Bash launchers are unverified. `run_tests.sh` now has the same unittest discover command as the PowerShell launcher, and that shell file was not executed. |

## Decisions made

The owner approved D-003 and D-009 on 2026-10-24. The approval is recorded in `docs/DECISIONS.md` section D. The locked rows were not edited. No new decision number was added. The game stays 2.5D on one lane, with the five regrown limbs on the shared skeleton and sockets.

## Owner action

Install Godot 4.7.2 export templates before stage 23. Do not open the project with Godot 4.0. More limbs, or sidestep movement, need a new approval.

## Next prompt to execute

`04_PROGRESS_TRACKER_AND_HANDOFF_PROTOCOL.md`
