# Stage 08 — Body state movement and input

## Stage result
COMPLETE.

## Changed files
SimBodyState/SimMoveAvailability, nine body moves and schemas, body balance, InputBindings/PlayerInput/InputRecorder, directional input buffer, body_state_lab, 16 golden replays, matrix runner, tests and combat rules. Included the stage-07 severing_lab scene missed by the previous staging path list.

## Actual commands and test results
Godot import, tests/run_all, tools/sim/body_state_matrix.gd, record_replay.gd, tools/sim/replay.gd, D:/Git/bin/bash.exe tools/check_all.sh. Final full suite: 73 passed, zero failed/skipped, Python 7+12 OK, lint/format/schema/purity/status PASS. BODY_MATRIX masks=16 failures=0: each moves and damages a dummy. All 18 golden replays verified.

## Acceptance criteria
PASS: all 16 masks derive expected profiles, move, and have working attacks. PASS: cracked-vs-missing, directional sides, hop dodge speed/wall clamps, crawl/torso contacts. PASS: toggle block, binding conflicts and roundtrip, buffer edges/directions, recorded input hashes. PASS: no skeletal clips or bespoke body animations, simple model transforms only.

## Windowed evidence
Ran body_state_lab for masks 0,1,3,4,12,15; wrote build/body_<mask>.png. Inspected torso image: torso is lowered to the floor and standing opponent remains visible; debug controls occupy too much screen width, to refine with HUD. Hardware gamepad/manual responsiveness remains UNVERIFIED until owner checkpoint B.

## Known issues / decisions
Fixed dodge adding both a walk and dodge step in the same tick. Deterministic hashes deliberately changed for directional buffering. No new consequential decisions.

## Owner action
None now; continue to checkpoint B.

## Next prompt to execute
09_FIGHTER_AI_AND_LOCAL_1V1.md
