# Stage 07 — Limb integrity, severing and early models

## Stage result
COMPLETE. Four original modular fighter GLBs and three arena GLBs introduced early at owner request. Later art pipeline gates are not marked complete.

## Changed files
SimLimb/SimSeverance/SimModifier, SimLimbs/World/Combat/Movement/ChainRecord/events/hash, limbs data/schema, seven new test files, two golden replays, FighterRig/FighterView, severing lab, original Blender generator, seven GLBs, documentation. Bash launchers now fall back from an unusable WindowsApps python3 alias to python.

## Commands and results
- Baseline tools/run_tests.ps1: 49 passed, Python 7+12 passed, formatting/lint clean.
- Blender background build_early_art.py: exit 0, all seven GLBs generated.
- Godot --import: exit 0.
- tools/sim/record_replay.gd and record_severance.gd: re-recorded changed state hashes. Severance replay contacts tick 5/22/39; combo, bruise, combo, sever, Fury, state transition order in build/severance_events_retry.log.
- D:/Git/bin/bash.exe tools/check_all.sh: exit 0, 65 Godot tests passed, 0 failed/skipped; Python 7 validator +12 tracker tests OK, lint/format/purity/schema/status PASS (build/check07.log).
- Windowed severing_lab --autoplay --demo-sever --shot=res://build/severing_lab.png: exit 0, screenshot inspected. Fixed white material export. Full human feel is UNVERIFIED, due at B.

## Acceptance criteria
PASS: integer thresholds exhaustively checked at maxima 100/130/80, 90/91 combo gap, 30/31 grace, pending next-hit, per-attacker credit and ties, data cap, Fury refresh/expiry/meter, combat penalties, head protection, 3000 paired random chain steps. PASS: generated models import and all limb/stump nodes toggle. PASS: no severing RNG and purity gate. PASS: rules/ambiguities documented.

## Known limitations
Early art has no shared armature yet (stage 12); camera/silhouette readability needs refinement. Sandbox initially prevented external Godot log/cache writes; checks use process-local APPDATA=build/runtime. Engine reports inability to read system certificates; game contains no networking. First replay tool attempt failed at early autoload compilation, fixed by dynamic fixture loading and rerun.

## Decisions
D-040 next-hit rule with healthy-start protection; D-041 credit and Fury; D-042 owner-authorized early art.

## Owner action
None now. Visual/style/feel judgement at Checkpoint B.

## Next prompt to execute
08_BODY_STATE_MOVEMENT_AND_INPUT.md
