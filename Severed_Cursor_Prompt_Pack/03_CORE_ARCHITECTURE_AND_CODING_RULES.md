# Stage 03: Core Architecture And Coding Rules

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Lead gameplay/systems architect for a deterministic fixed-tick Godot 4 game.

## 2. Context
Stage 02 COMPLETE: project, test runner, `Log`, validators and launch scripts exist and pass.

## 3. Objective
Define and implement the architectural foundation: layer rules, the integer/fixed-point toolkit, deterministic RNG and hashing, the data-loading layer, and a static check that keeps the simulation pure.

## 4. Prerequisites
1. Stage 02 COMPLETE.

## 5. Workspace inspection
1. `PROJECT_STATUS.md`, `docs/TECHNICAL_PLAN.md`, `docs/DECISIONS.md` (D-003, D-004, D-005, D-023, D-029).
2. Everything under `src/`, `tests/`, `tools/` as created by stage 02.

## 6. Implementation tasks
1. Write `docs/ARCHITECTURE.md`: layers and allowed dependency directions; the tick loop (`SimWorld.step(inputs)` is the only way state changes; presentation reads state and consumes an event list; presentation never mutates sim state); data flow input -> `SimInput` -> sim -> events/state -> presentation/UI/audio; where each future system plugs in (AI produces `SimInput`; UI reads state; persistence stores match results and career data, never raw sim state); list the forbidden constructs in `src/sim/`.
2. Implement `src/core/fx.gd` (class `Fx`): integer helpers `mul_div(a,b,c)` with defined rounding (round-half-away-from-zero, documented), `clamp_i`, `abs_i`, `sign_i`, `percent(value, pct)`, `lerp_i`, integer square root `isqrt`, and constants (`TICKS_PER_SECOND=60`, `MM_PER_M=1000`). Provide `ticks_from_ms(ms)` and `ticks_from_seconds_x100(s100)` using integers only.
3. Implement `src/core/sim_rng.gd` (`SimRng`): xorshift32 (or PCG32) fully integer, seeded, with `next_u32`, `range_i(lo,hi)`, `chance_percent(p)`, `get_state/set_state`. Verify 32-bit masking explicitly (GDScript ints are 64-bit).
4. Implement `src/core/state_hash.gd` (`StateHash`): FNV-1a 64-bit (or equivalent) over an ordered stream of integers; helpers to feed ints/arrays in canonical order. This will be used for determinism and golden-replay tests.
5. Implement `src/core/data_loader.gd` (`DataLoader`): loads JSON from `res://data/...` with schema validation (reuse the schema shapes from `data/schema/`), returns typed result objects with clear error messages including file path and field path, caches results, never crashes on malformed data (returns an error Result and logs ERROR). Add `src/core/result.gd` (`Result` with `ok`, `value`, `error`).
6. Implement `tools/validate/check_sim_purity.py` and hook it into `validate_all.py`: scans `src/sim/**/*.gd` and fails on forbidden tokens: `randf`, `randi`, `randomize`, `Time.`, `OS.`, `Engine.`, `get_node`, `get_tree`, `Node`/`Node3D`/`Control` inheritance (allowed bases: `RefCounted`, `Resource`), `PhysicsServer`, `RigidBody`, `CharacterBody`, `Area3D`, `HTTPRequest`, `ENet`, `WebSocket`, floating-point literals (`\d+\.\d+`), `float` type annotations, `Vector2(`/`Vector3(` constructors with float args (integer `Vector2i` is allowed). Include an allow-list comment mechanism `# sim-purity-ok: <reason>` that must be reviewed in the handoff. Add Python unit tests for the checker with passing and failing sample files.
7. Create `src/sim/` skeleton only as empty typed base classes needed by the rules (`SimConstants` for data-derived constants). No gameplay logic yet.
8. Write `docs/CONVENTIONS.md` additions: typing rules, signal usage, error handling pattern (`Result`), logging categories, how to add data + schema + test for a new content type, and commit-message style.
9. Add unit tests for every helper; run everything; commit.

## 7. Technical constraints
1. Simulation determinism rules (D-004) are mandatory: integers only, explicit rounding, no engine physics, no wall-clock time.
2. Do not over-engineer: no ECS frameworks, no event-bus plugins, no dependency injection frameworks.
3. Public APIs must have type hints and short doc comments.

## 8. Files and outputs
1. `docs/ARCHITECTURE.md`, updated `docs/CONVENTIONS.md`
2. `src/core/{fx,sim_rng,state_hash,data_loader,result}.gd`
3. `tools/validate/check_sim_purity.py` (+ tests)
4. `tests/unit/test_fx.gd`, `test_sim_rng.gd`, `test_state_hash.gd`, `test_data_loader.gd`

## 9. Automated tests
1. `Fx`: rounding at +/- boundaries, `mul_div` overflow safety within expected ranges, `isqrt` for 0..10^6 sample, percent maths exact cases.
2. `SimRng`: known-sequence test for fixed seed (record the first 20 outputs as golden values), state save/restore reproduces sequence, `range_i` bounds over 100k draws, 32-bit masking verified.
3. `StateHash`: same stream -> same hash; order sensitivity; golden hash value for a fixed stream.
4. `DataLoader`: valid file loads; missing file, malformed JSON, schema violation each produce an error Result, log ERROR, and do not crash.
5. Purity checker: fails on each forbidden token sample, passes on clean sample, honours the allow-comment.

## 10. Execution and verification
1. `tools/run_tests.sh` -> all pass, show counts.
2. `python3 tools/validate/validate_all.py` -> passes including the purity check on the (currently tiny) `src/sim/`.
3. Temporarily add a `randf()` call to a sim file, confirm the checker fails, revert.
4. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. Architecture and conventions documents exist and match the implemented code.
2. Integer toolkit, RNG, hash and data loader are implemented and fully unit-tested with golden values.
3. Purity checker is wired into `check_all` and demonstrably catches violations.
4. All tests pass; working tree committed.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/03_CORE_ARCHITECTURE_AND_CODING_RULES.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No combat logic, fighters, or moves yet (stage 05/06).
2. No UI, scenes or art.
3. No third-party libraries.
4. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
