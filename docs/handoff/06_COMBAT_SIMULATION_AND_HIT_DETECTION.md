# Stage 06 handoff — Combat Simulation And Hit Detection

## Stage result

COMPLETE. Checkpoint A was recorded as PASS before this stage. The combat core is in the same fixed-lane sim. Severing was not added.

## Changed files

- Split combat into `src/sim/sim_hit_resolver.gd`, `sim_limbs.gd`, `sim_stamina.gd`, `sim_movement.gd`, `sim_combat.gd`, `sim_input_buffer.gd`, and `chain_record.gd`. `SimWorld.step` still owns the tick.
- Move, fighter, and `data/balance/combat.json` data, plus schemas. Added `data/moves/grab.json`.
- Tests: `tests/unit/test_combat_*.gd`, `tests/regression/test_replays.gd`, regenerated `tests/golden/proto_match_01.json` and `proto_match_01.replay.json`.
- `tools/sim/replay.gd`, `record_replay.gd`, `fuzz.gd`, and `src/presentation/replay_check.gd`.
- Debug overlay and fighter tint. `--record=` on the match scene writes a live input log.
- `docs/COMBAT_RULES.md`. Schema `$ref` is expanded by the loader and `validate_all.py`.

## Commands actually run

- Pinned Godot `--import`, then `--script res://tests/run_all.gd`. Summary: `49 passed, 0 failed, 0 skipped`. Exit 0.
- `tools/sim/record_replay.gd` printed `RECORDED ... proto_match_01.replay.json ticks=2096` and exited 0.
- `tools/sim/replay.gd` printed `REPLAY_OK proto_match_01.replay.json` and exited 0.
- `tools/sim/run_scripted_match.gd` printed `FINAL_HASH=6354485122121618977`, `WINS=2,0`, `TICKS=2096`, `PHASE=1`, exit 0.
- `tools/sim/fuzz.gd` printed `CRASHES=0`, `MATCHES=1000`, `DOUBLE_RUNS=200`, `TICKS=480000`, `MSEC=27691`, `TICKS_PER_SEC=17334`, exit 0.
- `gdlint src tests` printed `Success: no problems found`.
- `D:\Git\bin\bash.exe tools/check_all.sh` exited 0. Godot 49 passed. Validator 7 OK. Status 12 OK. `gdformat --check` reported 42 files unchanged. `validate_all: PASS`. `status_check: PASS`.

## Test results

| Check | Result |
|---|---|
| Godot unit and regression tests | PASS. 49 passed, 0 failed, 0 skipped. |
| Scripted hash | PASS. `6354485122121618977`. Replaced the stage 05 hash because stamina, meter, integrity, hit-stop, and the buffer are now in the hash. Wins stayed 2-0. |
| Replay | PASS. `REPLAY_OK proto_match_01.replay.json`. |
| Fuzz | PASS. 0 crashes. Each of the 1000 matches ran 480 ticks, not a full best of three. 200 paired runs of 120 ticks matched. About 17334 ticks per second. |
| `tools/check_all.sh` | PASS. Exit 0. |
| Purity | PASS. No allow-list comments. |
| Windowed combat feel | UNVERIFIED. No new play session this stage. |

## Acceptance criteria

1. **PASS.** Per-limb boxes are in the fighter files. Tests cover head-over-torso, limb tie order, torso main damage, and the arm split.
2. **PASS.** Block keeps 30 and chips 25 on exact fixtures. Stamina, dodge i-frames, grab versus block and dodge, the 90/91 combo gap, the cancel window, and hit-stop all have passing tests.
3. **PASS** for the replay and the fuzz invariants that were run. The fuzz cap is 480 ticks per match.
4. **PASS.** `docs/COMBAT_RULES.md` names each rule and its data file.

## Known bugs and blockers

| ID | Status | Notes |
|---|---|---|
| — | Limitation | No sever, cracked state, or body-state movement. Crouch, hop, crawl, and torso boxes are data only. |
| — | Limitation | Fuzz matches stop at 480 ticks. |
| — | Limitation | Smash hitbox height was reduced from 700 to 480 so the starter smash still strikes the torso instead of the arm above it. |

## Decisions made

- Block keep percent is 30 (D-023's 70 percent reduction). Chip is 25 percent of scaled limb damage.
- Limb hits deal 50 percent of scaled main damage and 100 percent of scaled limb damage. Head hits deal 125 percent of scaled main damage.
- Toughness percents are `[0, 80, 90, 100, 115, 140]` applied to a base of 100. Stamina regen is 1 per tick. Stagger is 20 ticks. Buffer is 6 ticks. These are recorded in `data/balance/combat.json`. No locked row was rewritten.

## Owner action

GitHub push of this machine still needs a login. The remote is `https://github.com/Dhanushmcmsd/Greek-Curse.git`. No gameplay checkpoint is due before stage 07.

## Next prompt to execute

`07_LIMB_INTEGRITY_SEVERING_AND_STUMP_CAPS.md`
