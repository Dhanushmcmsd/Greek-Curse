# Stage 06: Combat Simulation And Hit Detection

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Combat systems engineer specialising in deterministic fighting-game simulation.

## 2. Context
Stage 05 COMPLETE and Checkpoint A passed (or accepted by the owner). Basic sim: movement, 3 starter moves, main health, rounds.

## 3. Objective
Turn the prototype sim into the real combat core: per-limb hurtboxes and hitboxes, full hit resolution, block, stamina, dodge, grab, combo tracking, hit-stop, input buffering, ultimate meter fill, and a determinism/replay harness.

## 4. Prerequisites
1. Stage 05 COMPLETE + Checkpoint A resolved (record the owner's result in `PROJECT_STATUS.md`).

## 5. Workspace inspection
1. All `src/sim/*`, `data/moves/*`, `data/balance/*`, `tests/golden/*`.
2. GDD sections 5.1-5.3, 7.1-7.3 and Addendum D; `docs/DECISIONS.md` D-023, D-029.
3. Checkpoint A notes/fixes.

## 6. Implementation tasks
1. Hit-zone model (D-003): define per-fighter hurtbox sets in `data/fighters/<id>.json` per **pose profile** (`standing`, `crouch`, `hop`, `crawl`, `torso`), each a list of named integer AABBs: `head`, `torso`, `arm_l`, `arm_r`, `leg_l`, `leg_r`, scaled from height. Hitboxes in move data carry `zone_priority` and which limb produced them (`limb_side`, see D-029). Resolve overlaps deterministically: a hit applies to **one** hurtbox - the first by fixed priority (head > arm/leg by overlap area, ties -> lower index), documented in `docs/COMBAT_RULES.md`.
2. Damage model: on hit, main damage and (for arm/leg zones) limb damage computed from move data x attacker power multiplier x defender modifiers, all integer with `Fx.mul_div`. Body (torso) hits damage main bar only; limb hits do more limb damage than main damage (ratios in `data/balance/combat.json`); head hits use a main-damage multiplier and **no head integrity** (D-011). Limb integrity itself is stored here but state thresholds/severing come in stage 07 - expose a clean hook `SimLimbs.apply_limb_damage(...)` as a stub that records integrity and emits events.
3. Move properties in data and engine: startup/active/recovery, hit-stop (attacker and defender), hitstun, blockstun, knockback, `on_block_pushback`, `cancel_into` windows (light->light->heavy->kick chains with limited cancels per GDD), `armor` flag/hits, `unblockable`, `multi_hit` with hit intervals, `launch` (ground/wall bounce flags; wall bounce needs arena walls - implement bounce against arena bounds). Implement an input buffer (6 tick default, data-driven) with leniency rules documented.
4. Block: reduces main damage by 70%, chips limb integrity by 25% (values from `combat.json`); block high/low not required in MVP (single block stance; low attacks must still be blockable); blocking drains stamina. Stamina: pool, costs per move (light small, heavy large), regen rate, empty bar => short stagger state. Dodge: short roll with i-frames (data), cooldown, stamina cost; grab: beats block, loses to dodge, grab throw sequence as a sim state with damage and positional swap.
5. Combo tracking per defender: `combo_hits`, `last_hit_tick`, per-limb damage accumulated per attacker within the chain; chain breaks if gap > 90 ticks (1.5 s). Do **not** implement severing here; expose the data stage 07 needs (`ChainRecord`). Combo scaling is NOT in scope (keep damage flat unless data says otherwise).
6. Ultimate meter: shared 0-100 style meter (data-driven max) filled by damage dealt, damage taken and (later) limb loss; stored per fighter; fill events emitted; no ultimate yet.
7. Hit-stop: global freeze ticks implemented inside the sim (both fighters' state timers pause) so determinism is preserved; presentation reads `hitstop_remaining` for shake/flash.
8. Determinism harness: `SimWorld.snapshot_hash()` hashing all sim state in canonical order each tick; `tools/sim/replay.gd` runs an input log file (`tests/golden/*.replay.json`: seed, fighters, arena, per-tick inputs) and compares per-N-tick hashes to expected; `tools/sim/record_replay.gd` records the live game's inputs to such a file (also wire into `MatchController` behind a debug flag). Write `docs/COMBAT_RULES.md` summarising every rule and its data source.
9. Extend debug overlay: show hurtbox/hitbox per limb, combo counter, stamina, meter, hit-stop. Extend presentation minimally (flash on block, stagger tint).

## 7. Technical constraints
1. All logic in `src/sim/`, integer-only, purity check clean.
2. No hard-coded balance numbers in code; all in `data/`.
3. Keep files small and single-purpose (no `sim_world.gd` over ~500 lines; split `SimCombat`, `SimMovement`, `SimStamina`, `SimInputBuffer`, `SimHitResolver`).
4. Do not break the golden hash test unintentionally; if rules changed, regenerate goldens deliberately and explain why in the handoff.

## 8. Files and outputs
1. `src/sim/` new/split modules as listed
2. `data/balance/combat.json` + schema, updated fighter/move schemas and data
3. `tools/sim/{replay,record_replay}.gd`
4. `tests/golden/*.replay.json`, `tests/unit/test_combat_*.gd`, `tests/regression/test_replays.gd`
5. `docs/COMBAT_RULES.md`

## 9. Automated tests
1. Hit resolution: overlap priority, single-hit-per-instance, multi-hit intervals, hit on each zone applies correct main/limb split.
2. Block: 70% reduction and 25% chip exact numbers; stamina drain; guard break/stagger at empty.
3. Stamina costs/regen/empty stagger; dodge i-frames exact tick range; grab beats block, loses to dodge.
4. Combo chain: gap of exactly 90 ticks continues, 91 breaks; cancel windows exact.
5. Hit-stop pauses timers symmetrically.
6. Determinism: replays reproduce golden hashes; 200 randomised input logs (seeded) run twice and agree tick-by-tick; invariants (HP within [0,300], integrity within [0,max], stamina within bounds) hold.
7. Schema validation of all data.

## 10. Execution and verification
1. `tools/run_tests.sh` passes.
2. Run `tools/sim/replay.gd` on every golden replay and show results.
3. Run 1000 random-input headless matches (`tools/sim/fuzz.gd`) and report crashes (must be zero) and average ticks/sec.
4. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. Per-limb hit detection works and is data-driven.
2. Block, stamina, dodge, grab, combos, hit-stop and buffering behave as specified with exact-boundary tests.
3. Replay/hash determinism proven; fuzz run has zero invariant violations.
4. `docs/COMBAT_RULES.md` accurate.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/06_COMBAT_SIMULATION_AND_HIT_DETECTION.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No severing/cracked logic beyond integrity storage (stage 07).
2. No body-state movement (stage 08), no AI (stage 09), no abilities beyond starter data + whatever test fixtures need (stage 17).
3. No rollback/snapshot-restore. State hashing and replay only.
4. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
