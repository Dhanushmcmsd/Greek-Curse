# Stage 05: First Playable Prototype

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Gameplay programmer building a thin but real vertical slice on top of a deterministic simulation.

## 2. Context
Stages 00-04 COMPLETE: project, test runner, `Fx`, `SimRng`, `StateHash`, `DataLoader`, purity checker, tracker tooling.

## 3. Objective
Deliver the first playable prototype (Human Checkpoint A): two greybox fighters on one greybox arena, moving and attacking in a real fixed-tick simulation, with main health, round timer, best-of-three flow and restart - local 1v1 on keyboard/gamepad. Presentation uses simple boxes/capsules, which is an honest greybox; the **simulation is real and is the same one used in the final game**.

## 4. Prerequisites
1. Stage 04 COMPLETE.

## 5. Workspace inspection
1. `docs/ARCHITECTURE.md`, `docs/CONVENTIONS.md`, `docs/DECISIONS.md` (D-003, D-004, D-023, D-029).
2. `src/core/*`, `tests/run_all.gd`, `tools/validate/check_sim_purity.py`.
3. GDD section 5 (controls, rules) in `docs/source/GDD_extracted.txt`.

## 6. Implementation tasks
1. Define data: `data/schema/move.schema.json`, `data/schema/fighter.schema.json`; `data/fighters/theron.json` and `data/fighters/atalanta.json` (stats 1-5 as in the GDD, mapped to numbers by `data/balance/stat_curves.json` - define the curves now: e.g. speed 1-5 -> mm per tick table, power 1-5 -> damage multiplier percent); `data/moves/jab_of_hermes.json`, `cyclops_smash.json`, `pegasus_kick.json` with startup/active/recovery ticks, damage, hitstun, blockstun, knockback (mm), hitbox rectangle (mm, relative to fighter), cost, cancel flags (cancels come in stage 06).
2. Implement the sim core in `src/sim/`: `SimInput` (bitmask int per player per tick: left, right, up, down, light, heavy, kick, block, dodge, super, ultimate), `SimFighter` (integer position x/y in mm, facing, velocity, state enum, state_tick, health 300, stamina placeholder, current move id), `SimWorld` (two fighters, arena bounds, round state, tick counter, `step(inputs: Array[int]) -> Array[SimEvent]`), `SimEvent` (typed small objects: hit, ko, round_start, round_end, match_end). Fighters auto-face each other. Movement: walk left/right with speeds from stat curves, clamped to arena bounds, simple push-apart so fighters do not overlap. Attacks: state machine startup -> active -> recovery; AABB hitbox vs fighter body AABB in integers; hit applies damage, hitstun and knockback; no double hits per move instance.
3. Implement round/match rules in `SimWorld`: 300 HP, 90 second round timer (5400 ticks), KO ends round, timeout awards the higher health fighter (tie = draw round replayed once, then higher health or coin via SimRng documented), best of three, match end event. All numbers from data/constants, none hard-coded in logic.
4. Presentation (Node layer, `src/presentation/`): `MatchController` node that owns a `SimWorld`, collects input every `_physics_process` (60 Hz; use an accumulator guard so exactly one `step` per tick), forwards events, and drives `FighterView` nodes (capsule/box meshes, colours per player, a flash on hit) and a basic `ArenaGreybox` (floor, two walls, a light). Camera: fixed side-on camera framing both fighters. HUD (`src/ui/`): two health bars, timer, round pips, 'KO' / 'Round N' / 'Winner' text, 'Press R to restart'. Scene: `scenes/match/match_prototype.tscn`; set as main scene for now.
5. Input (temporary, finalised in stage 08): add InputMap actions per player created in code at startup from a data table (P1: A/D move, W jump placeholder unused, S down, J light, K heavy, L kick, Shift block, Space dodge; P2: arrow keys + numpad 1/2/3, or gamepad device 0 and 1). Gamepad mapping per GDD: X light, Y heavy, A kick, left stick move. Block and dodge may be no-ops this stage except block state animation flag (they are implemented in stage 06).
6. Debug overlay (`src/debug/`): toggle with F1 to draw hitboxes/hurtboxes (wireframe boxes), show tick number, state names, state hash. Add `--sim-test` style entry in a headless script `tools/sim/run_scripted_match.gd` that plays a scripted input list to the end of a match and prints the final state hash.
7. Write tests (below), run everything, commit. Prepare the **Checkpoint A** package: `docs/playtest/CHECKPOINT_A.md` with exact launch instructions for the owner's OS (how to run `"$GODOT_BIN" --path .` or open in editor and press F5), controls, expected results, and the bug-report template copied from `MANUAL_CHECKPOINTS.md`.

## 7. Technical constraints
1. The sim must pass `check_sim_purity.py` with zero allow-list exceptions.
2. Sim is 2.5D lane: positions are (x, y) integers; depth is fixed (D-003).
3. Do not use Godot physics, `CharacterBody3D`, `Area3D` or animations for gameplay decisions.
4. Presentation must not mutate sim state; it only submits inputs and reads state/events.
5. Greybox visuals only - do not start Blender work.

## 8. Files and outputs
1. `src/sim/{sim_input,sim_fighter,sim_world,sim_event,sim_constants}.gd`
2. `src/presentation/{match_controller,fighter_view,arena_greybox}.gd`, `src/ui/hud_prototype.gd`, `src/debug/debug_overlay.gd`
3. `scenes/match/match_prototype.tscn`
4. `data/{schema,fighters,moves,balance}/...` as listed
5. `tools/sim/run_scripted_match.gd`
6. `docs/playtest/CHECKPOINT_A.md`

## 9. Automated tests
1. Movement: speed per tick matches data; clamp at bounds; fighters never overlap beyond the allowed push-apart.
2. Attack frames: each move's active window starts exactly at startup tick; one hit per move instance; damage equals data x stat multiplier (integer).
3. Round flow: KO ends round; timeout winner; best-of-three produces match_end after 2 round wins; draw handling.
4. Determinism: same scripted input log twice -> identical state hash every tick; golden final hash recorded in `tests/golden/proto_match_01.json`.
5. Data validation: all new JSON passes schemas.

## 10. Execution and verification
1. `tools/run_tests.sh` passes (show counts).
2. `"$GODOT_BIN" --headless --path . --script res://tools/sim/run_scripted_match.gd` prints final hash equal to the golden value.
3. If windowed run is possible (see capabilities): launch the game for a few seconds with a scripted autoplay flag, confirm no ERROR lines in the log, and save a screenshot (`docs/playtest/screenshots/a_prototype.png`). If not possible, mark `UNVERIFIED` and rely on the owner at Checkpoint A.
4. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. Two fighters move, attack, take damage and a full best-of-three match completes headlessly and in the scene.
2. Simulation is deterministic (golden hash) and passes the purity check.
3. HUD shows health/timer/rounds; R restarts.
4. Hitbox debug overlay works.
5. Checkpoint A instructions are written.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/05_FIRST_PLAYABLE_PROTOTYPE.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No limb damage, severing, blocking, stamina, grabs, combos or abilities beyond the 3 starter moves (stages 06-08, 17).
2. No AI (stage 09), no menus (stage 20), no Blender assets.
3. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
