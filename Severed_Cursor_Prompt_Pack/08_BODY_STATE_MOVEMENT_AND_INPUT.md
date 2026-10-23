# Stage 08: Body State Movement And Input

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Gameplay and input programmer.

## 2. Context
Stage 07 COMPLETE: limbs can be Bruised, Cracked, Severed in the sim; greybox shows it.

## 3. Objective
Implement body-state-dependent moves and movement in the sim (one arm, no arms, one leg, no legs, Torso Mode), and the full input layer: bindings, buffering, gamepad/keyboard, remappable action map, and input recording.

## 4. Prerequisites
1. Stage 07 COMPLETE.

## 5. Workspace inspection
1. `src/sim/*`, `data/moves/*`, `data/fighters/*`, current InputMap setup in `src/presentation/match_controller.gd`.
2. GDD section 5.1, 5.3, 6.1 and Technical Design (animation row); D-014, D-029.

## 6. Implementation tasks
1. Define `BodyState` derivation (pure function of the 4 limb states, with Cracked counting as unusable for attack/block but **still present**; Severed = missing): `full`, `one_arm` (L or R), `no_arms`, `one_leg` (L or R), `no_legs`, `torso_mode` (three or more limbs missing). Combine arm and leg conditions into a profile (e.g. one arm + one leg) with a documented precedence and test every combination of the 16 limb-missing masks.
2. Movement rules in data (`data/balance/body_states.json`): standing walk; one-leg **hop** (slower, dodge becomes a hop); no-legs **crawl** (slowest, smallest hurtbox profile); torso mode **scuttle/roll**. Switch the fighter's hurtbox profile (`standing/crouch/hop/crawl/torso`) accordingly; avoid teleporting the hurtbox on transition (clamp/push rules).
3. Move availability: arm missing/cracked -> that side's punch inputs disabled, grabs weaker, block reduced on that side (values in data); leg missing/cracked -> kicks limited to one low kick and one flying kick (data-defined `body_state_moves`), dodge->hop. Both arms: headbutt, shoulder charge, bite finisher (3 new move data files); both legs: stump strike, low sweep; torso mode: scuttle attack and roll attack (data). Moves are data (`data/moves/body_*.json`) reusing the existing move engine; only the minimum new engine support.
4. Input layer (`src/input/`): `InputBindings` resource/JSON (`data/ui/default_bindings.json`) for P1 keyboard, P2 keyboard, and gamepad; defaults exactly per GDD 5.1 (keyboard: J/K/L/Shift/Space/U/I/J+L; gamepad: X/Y/A, RB/B, LT, RT+LT, X+A); `PlayerInput` converts device state into a `SimInput` bitmask each tick; input buffer for direction+button combos per D-029 (button alone = slot A / left limb; Forward+button = slot B / right limb for punches; Down+kick = slot B for kicks); `grab` = light+kick same tick; hold-to-toggle option for block; remapping API (`rebind(action, event)`, conflict detection, `reset_defaults()`) - persistence of bindings is saved by stage 16's settings service, so expose `export_bindings()/import_bindings()` only.
5. Input recorder/replayer in `src/input/` writing the same replay format used by `tools/sim/` so a human match can be turned into a regression test.
6. Debug scene `scenes/debug/body_state_lab.tscn`: pick any limb mask, spawn a fighter, move it, attack a dummy, display allowed moves; `tools/sim/body_state_matrix.gd` iterates all 16 masks x all moves and writes `build/body_state_matrix.json`.
7. Greybox presentation updates: hop/crawl/torso stances rendered as simple transforms of the boxes (tilt/lower); real motion arrives in stage 14.
8. Tests, goldens (one replay per body state), docs update (`COMBAT_RULES.md` body-state table), commit.

## 7. Technical constraints
1. Everything affecting gameplay is in sim/data; input layer only produces `SimInput`.
2. Do not author bespoke animation; do not duplicate attack logic per body state.
3. Keep replay format backwards compatible with stage 06 goldens (add fields, do not break).

## 8. Files and outputs
1. `src/sim/{sim_body_state,sim_move_availability}.gd`
2. `src/input/{input_bindings,player_input,input_recorder}.gd`
3. `data/balance/body_states.json`, `data/moves/body_*.json`, `data/ui/default_bindings.json` (+schemas)
4. `scenes/debug/body_state_lab.tscn`, `tools/sim/body_state_matrix.gd`
5. Tests + replays per body state

## 9. Automated tests
1. Body-state derivation for all 16 masks (table-driven) incl. Cracked vs Severed distinction.
2. Move availability per state; disabled inputs are ignored (no crash, no phantom hit).
3. Movement speeds and hurtbox profile per state; transitions don't leave fighters inside walls/each other.
4. Hop dodge, crawl strike and torso roll each connect against a dummy in a replay.
5. Input: buffer windows; slot A/B mapping; hold-to-toggle; rebind conflict detection; export/import round trip; recorder->replay produces identical hashes.

## 10. Execution and verification
1. `tools/run_tests.sh` passes.
2. Run `tools/sim/body_state_matrix.gd` and attach summary (every mask has at least one working attack and movement).
3. Windowed (if possible): open `body_state_lab.tscn` and screenshot each body state; else UNVERIFIED.
4. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. Every one of the 16 limb masks yields a playable fighter (can move and has at least one usable attack).
2. Input defaults match the GDD; remap API tested.
3. Recorded human play can be replayed deterministically.
4. No bespoke per-state animation was added.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/08_BODY_STATE_MOVEMENT_AND_INPUT.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No AI (09), no HUD work (10), no real models/animation (12-14), no settings persistence UI (16/20).
2. No regrown-limb behaviour yet (13).
3. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
