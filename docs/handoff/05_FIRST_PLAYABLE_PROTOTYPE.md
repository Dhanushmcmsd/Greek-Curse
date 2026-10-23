# Stage 05 handoff — First Playable Prototype

## Stage result

COMPLETE. The owner replied Pass on 2026-10-24, so stage 06 may start. The playtest also rewrote `project.godot` and dropped the explicit 60 Hz physics tick; that line was restored.

## Changed files

- Sim: `src/sim/sim_input.gd`, `sim_fighter.gd`, `sim_world.gd`, `sim_event.gd`, `proto_script.gd`. `sim_constants.gd` was already present and was not given combat numbers.
- Presentation: `src/presentation/match_controller.gd`, `fighter_view.gd`, `arena_greybox.gd`, `src/ui/hud_prototype.gd`, `src/debug/debug_overlay.gd`, `scenes/match/match_prototype.tscn`.
- Data: fighter, move, balance, rules, and input JSON, plus their schemas. `src/core/data_loader.gd` and `tools/validate/validate_all.py` accept one shared schema for every file in `fighters/` and `moves/`.
- Tests: `tests/proto_fixture.gd`, `tests/unit/test_proto_movement.gd`, `test_proto_attack.gd`, `test_proto_rounds.gd`, `test_proto_determinism.gd`, `tests/golden/proto_match_01.json`.
- `tools/sim/run_scripted_match.gd`. Removed `tools/.gdignore` so Godot can load that script. The runner loads the fixture with `load()` because a direct script dependency compiles before the `Log` autoload exists.
- `project.godot` main scene is the prototype scene.
- `docs/playtest/CHECKPOINT_A.md` and `docs/playtest/screenshots/a_prototype.png`.

## Commands actually run

- Pinned console Godot `--headless --path "E:\zeus balls" --import`, then `--script res://tests/run_all.gd`. The full suite printed `Summary: 35 passed, 0 failed, 0 skipped` and exited 0.
- The same Godot `--script res://tools/sim/run_scripted_match.gd` printed `FINAL_HASH=2183744980119554273`, `WINS=2,0`, `TICKS=2040`, `PHASE=1`, and exited 0.
- `D:\Git\bin\bash.exe tools/check_all.sh` exited 0 on the final tree, including the camera fix and unshaded fighter materials. Godot 35 passed, 0 failed. Validator unittest 7 OK. Status unittest 12 OK. `gdlint` printed `Success: no problems found`. `gdformat --check` reported 29 files unchanged. `validate_all: PASS`. `status_check: PASS`. `check_all: PASS`.
- An earlier `check_all.sh` exited 1. `test_project_sim_passes` reported `src/sim/sim_world.gd:3: forbidden float literal` because the comment contained `2.5`. The comment was reworded. No purity allow-list comment was added.
- Windowed console Godot, without `--headless`, with `-- --autoplay --shot=E:\zeus balls\docs\playtest\screenshots\a_prototype.png`: the first launch exited 0 and printed `ERROR: Node not inside tree` from `Camera3D.look_at` before the camera was in the tree. The camera is now added first. The relaunch exited 0, printed `OpenGL API 3.3.0 NVIDIA 621.01 - Compatibility`, and printed no `ERROR` line. A later relaunch after unshaded fighter materials also exited 0 with no `ERROR` line.

## Test results

| Check | Result |
|---|---|
| Godot unit tests | PASS. 35 passed, 0 failed, 0 skipped. |
| Scripted match hash | PASS. `2183744980119554273`, wins 2 and 0, tick 2040. Matches `tests/golden/proto_match_01.json`. |
| Python validator tests | PASS. 7 tests, inside `check_all.sh`. |
| Python status tests | PASS. 12 tests, inside `check_all.sh`. |
| `gdlint` and `gdformat --check` | PASS. Final `check_all.sh` included the camera and material edits. |
| `validate_all.py` | PASS. |
| Sim purity | PASS. Zero allow-list comments. |
| `tools/check_all.sh` | PASS. Exit 0 on the final tree. |
| Windowed launch and one still | PASS for "the process starts and the frame saves". The still was inspected. Gameplay feel was not played. |
| Owner Checkpoint A | PASS. The owner replied Pass on 2026-10-24 after the playtest commit `16cfe6b`. |

## Acceptance criteria

1. **PASS for the headless match. UNVERIFIED for playing the scene.** The scripted match completes. The window opens and one inspected frame shows two capsules, bars, timer, and round text. Controls were not pressed by a person.
2. **PASS.** Golden hash matches. Purity check passed with no allow comments.
3. **PASS in the inspected frame for the HUD text and bars.** R restart was not pressed in the window.
4. **UNVERIFIED.** F1 was not pressed. The overlay is in the scene and covered by code review only.
5. **PASS.** `docs/playtest/CHECKPOINT_A.md` has the Windows launch, controls, expected results, and the bug-report template.

## Known bugs and blockers

| ID | Status | Notes |
|---|---|---|
| Checkpoint A | PENDING | Owner must play and reply PASS or a bug report. |
| — | Limitation | No limb damage, severing, blocking damage, stamina spend, grabs, combos, or extra abilities. Block is a flag. Dodge and up do nothing. |
| — | Limitation | Player 2 block and dodge have gamepad buttons and no keyboard key. |
| — | Limitation | Jab knockback is 0 so the golden log can stay in range. Smash and kick still knock back. |
| — | Limitation | Greybox capsules only. No animation was watched. The still is one scripted frame. |

## Decisions made

- D-003 stays in force: the fight is a fixed lane. Positions are x and y. Depth is not simulated.
- D-009 was not expanded. This stage has no limbs.
- Speed curve, index 0 through 5: 0, 6, 10, 14, 20, 26 millimetres per tick. Power curve: 0, 70, 85, 100, 115, 130 percent. Theron speed 2 is 10 mm/tick and power 5 is 130 percent. Atalanta speed 5 is 26 mm/tick and power 2 is 85 percent.
- A tied timeout is replayed once (`draw_replays` is 1). The next tie calls `SimRng.range_i(0, 2)` once and that fighter takes the round.
- These numbers live in `data/`. They are not new locked decision rows.

## Owner action

Play Checkpoint A using `docs/playtest/CHECKPOINT_A.md`. Reply PASS or a bug report. Do not ask for stage 06 until that reply.

## Next prompt to execute

`06_COMBAT_SIMULATION_AND_HIT_DETECTION.md`

Only after Checkpoint A is approved. This session stops here.
