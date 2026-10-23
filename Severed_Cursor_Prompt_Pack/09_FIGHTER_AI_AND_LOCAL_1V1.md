# Stage 09: Fighter Ai And Local 1V1

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Gameplay AI programmer for fighting games.

## 2. Context
Stage 08 COMPLETE: complete combat sim with limbs, body states, input layer, replays.

## 3. Objective
Implement a deterministic data-driven fighter AI (it only produces `SimInput`), practice dummies, and the complete local 1v1 match setup (P1 vs P2, P1 vs AI, AI vs AI), plus a headless soak harness.

## 4. Prerequisites
1. Stage 08 COMPLETE.

## 5. Workspace inspection
1. `src/sim/*` (read-only observation API), `src/input/*`, `data/moves/*`, `data/balance/body_states.json`.
2. GDD section 3 and 11 (modes, solo), `docs/DECISIONS.md` D-014.

## 6. Implementation tasks
1. Define `data/ai/difficulty.json` (Easy/Normal/Hard: reaction ticks, decision interval, aggression %, block %, punish accuracy %, spacing tolerance mm, combo-continue %) and `data/ai/archetypes.json` (rushdown, zoner, grappler, defensive, balanced -> weights over action classes). Schema + validation.
2. `src/ai/fighter_ai.gd` (`FighterAI`): `decide(observation: AIObservation, rng: SimRng) -> int` returning a `SimInput`. `AIObservation` is a read-only plain-data snapshot of what a human could see (positions, states, ticks into recovery of the opponent, own stamina/meter, available moves, limb states, body state). AI has its own `SimRng` seeded from the match seed so replays stay deterministic. Reaction delay implemented by observing the sim state N ticks old (ring buffer).
3. Behaviour: utility scoring over action classes (approach, retreat, poke, whiff-punish, block, dodge, grab, combo-continue, finish limb pressure, special moves later). Spacing uses move reach from data (not hard-coded). Must handle every body state using only moves that are currently legal; must work with unknown future moves by reading move data (startup, range, damage, limb side) so stage 17 needs no AI edits other than data. Limb pressure: prefer targeting the opponent's already Bruised/Cracked limb when a combo is available, per archetype weights.
4. Practice dummies: `idle`, `block_always`, `walk_back_forth`, `attack_on_interval`, `regen_reset` (limb/health reset on demand) in `src/ai/dummy_controller.gd`.
5. Match setup (`src/sim/match_config.gd` pure data + `src/presentation/match_launcher.gd`): `MatchConfig {fighter_ids, loadouts (default for now), arena_id (greybox), controllers [human_kb1|human_kb2|human_pad0|human_pad1|ai_easy|ai_normal|ai_hard|dummy_*], seed, mode, rules}` so menus (stage 20) only build a config. Support P1 vs P2 on one keyboard or with pads, P1 vs AI, AI vs AI (auto-played, for tests), and `Fresh Body` limb restoration after match.
6. Headless soak harness `tools/sim/soak.gd`: N AI-vs-AI matches across all fighter pairs and difficulty pairs with seeds; asserts every match ends, no invariant violations, no stuck states (no progress in damage/position for > 10 s of ticks triggers a failure with replay saved to `build/soak_failures/`), prints win rates, average match ticks, severance counts, and body-state coverage.
7. Wire a minimal `scenes/match/match_prototype.tscn` mode switch (keys 1/2/3 on a temporary launcher scene) so the owner can try P1 vs AI before stage 20 menus exist.
8. Tests, docs (`docs/AI.md`), commit.

## 7. Technical constraints
1. AI must not read hidden information the player could not infer, and must not mutate sim state.
2. AI randomness only through its own seeded `SimRng`.
3. No per-fighter hard-coded AI scripts; behaviour from data.

## 8. Files and outputs
1. `src/ai/{fighter_ai,ai_observation,dummy_controller}.gd`
2. `src/sim/match_config.gd`, `src/presentation/match_launcher.gd`
3. `data/ai/*.json` (+schemas)
4. `tools/sim/soak.gd`, `docs/AI.md`
5. `tests/unit/test_ai_*.gd`, `tests/regression/test_ai_determinism.gd`

## 9. Automated tests
1. AI emits only legal inputs for all 16 body-state masks (fuzzed).
2. AI-vs-AI with same seed twice -> identical hash; different seeds -> different outcomes over a sample.
3. Reaction delay obeyed (AI doesn't respond to a move earlier than N ticks after startup).
4. Difficulty ordering: Hard beats Normal beats Easy in a 200-match soak with win rate > 55% each step (report and, if failing, tune data).
5. Dummies behave as specified. MatchConfig validation (bad ids, duplicate controllers).
6. Soak: 300 matches without stuck/invariant failures.

## 10. Execution and verification
1. `tools/run_tests.sh` passes.
2. Run `tools/sim/soak.gd` and paste its summary table.
3. If windowed: run P1 vs AI for 60 s scripted, no ERROR logs.
4. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. Local 1v1 works for human-human, human-AI, AI-AI via MatchConfig.
2. Soak passes with no stuck or invalid states and difficulty ordering holds (or documented tuning applied).
3. AI works unchanged for new move data (demonstrate with one fixture move).

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/09_FIGHTER_AI_AND_LOCAL_1V1.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No machine learning, no external AI libraries.
2. No menu UI (20), no online play, no AI cheating via hidden state.
3. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
