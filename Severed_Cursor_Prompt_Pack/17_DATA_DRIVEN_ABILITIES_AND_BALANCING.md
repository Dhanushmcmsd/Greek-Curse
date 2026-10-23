# Stage 17: Data Driven Abilities And Balancing

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Combat designer-programmer and balance engineer.

## 2. Context
Stage 16 COMPLETE. The sim has starter moves, body-state moves, limb rules, modifiers and hazards; AI reads move data generically.

## 3. Objective
Build the ability framework and implement all 21 MVP abilities (D-008) as data + minimal reusable effect primitives, the loadout model, and a balance harness with reports. Re-validate AI and animation against new content.

## 4. Prerequisites
1. Stage 16 COMPLETE.

## 5. Workspace inspection
1. `data/moves/*`, `src/sim/*` (modifier list, move engine, meter, cooldown support), `data/ai/*`, `data/animation/poses.json`.
2. GDD sections 6.1-6.7; D-008, D-029; Build Requirements section 9 (ability framework).

## 6. Implementation tasks
1. Schema `data/schema/ability.schema.json` and files `data/abilities/<id>.json` for the 21 MVP abilities. **Light (4):** `jab_of_hermes`, `spartan_cross`, `bronze_knuckle`, `quick_fury`. **Heavy (4):** `cyclops_smash`, `hammer_of_hephaestus`, `minotaur_haymaker`, `gorgon_backfist`. **Kick (4):** `pegasus_kick`, `achilles_heel_snap`, `satyr_dropkick`, `sweeping_hydra`. **Superpower (4):** `zeus_bolt`, `hermes_dash`, `ares_rage`, `hephaestus_forge_shield`. **Passive (3):** `iron_skin`, `blood_frenzy`, `stoneheart`. **Ultimate (2):** `zeus_wrath`, `olympian_barrage`. Each: id, name, type, description (from GDD), tags, unlock group, move-data link (for punches/kicks via `data/moves/`), cooldown ticks, stamina cost, meter cost, effects list, icon id, anim_set, audio ids, caption id.
2. Effect primitives (small, composable, integer, in `src/sim/effects/`): `projectile_line` (instant/fast lightning line hitbox), `dash` (with `invulnerable_ticks`), `buff_self` / `debuff_target` (modifier with duration, percent changes to damage dealt/taken, speed), `shield` (absorb N damage then burst chip), `force_limb_state` (guaranteed Cracked), `damage_sequence` (scripted multi-hit strike list ending in a slam), `status_limb_vulnerability` (Zeus Bolt chars limbs: raised limb damage taken for 5 s), `armor_hits`, `wall_bounce`, `ground_bounce` (simplified knockdown), `stone_stiff` slowdown (Gorgon Backfist). Specific numbers from the GDD: Zeus Bolt 14 s cooldown, Hermes Dash 8 s, Ares Rage +25% damage dealt/+15% taken for 6 s at 20 s, Forge Shield absorbs 40 then bursts, Iron Skin -15% incoming limb damage, Stoneheart +20% damage needed to sever with slower movement, Blood Frenzy faster as main health drops, ultimates need full meter and have a **0.7 s (42 tick) startup counterplay window**, Zeus's Wrath high damage + guaranteed Cracked limb.
3. Cooldowns/meter: cooldown ticks per ability tracked in sim, UI-readable; ultimate meter spend; passives register modifiers at match start. Ultimate 'cinematic' in the MVP is a short sim-driven sequence with camera/VFX cues via events (zoom, flash with flash-reduction) - no cutscene system.
4. Loadout model `src/progression/loadout.gd` (pure data/validation): slots 2 light, 2 heavy, 2 kick, 1 superpower, 1 passive, 1 ultimate; starter kit (Jab of Hermes, Cyclops Smash, Pegasus Kick); only unlocked abilities may be equipped (progression state is supplied by stage 19; for now accept an `unlocked` set parameter); a `default_full_loadout` per fighter for Versus/Practice/AI (documented, data-driven); loadout locked during a match. Sim receives resolved loadout via `MatchConfig`.
5. Wire the input mapping (D-029): slot A/B resolution, superpower (U/LT), ultimate (I/RT+LT) triggers; AI uses superpowers/ultimates by data (cooldown ready, range, archetype weights).
6. Animation/presentation: add `anim_set` pose entries and VFX/audio/caption mapping for each new ability (reuse poses; add only essential new key poses); lightning/forge shield/dash visuals via existing VFX primitives; regenerate icons for all abilities (`tools/ui/generate_icons.py`).
7. Balance harness `tools/sim/balance_sim.gd`: round-robin AI-vs-AI over fighter pairs x a set of representative loadouts (generate deterministic random loadouts with seeds) x arenas (hazards off and on) with N matches each; outputs `docs/balance/report_<date>.md` + JSON: win rates per fighter/ability, average round length, severances per match, ability usage, time-to-kill, ultimate usage, matches ending by timeout. Flag outliers (win rate outside 40-60% per fighter on mirrored loadouts; any ability appearing in > 65% of wins at > 3 sigma; severance per match outside 0.5-3 target band). Tune **data only** (`data/abilities`, `data/balance`) in at most 3 iterations; record each iteration in `docs/balance/CHANGELOG.md`.
8. Re-run soak, AI tests, animation validation, replay goldens (regenerate deliberately with explanation); add per-ability replay goldens; update `docs/COMBAT_RULES.md` and `docs/ABILITIES.md` (auto-generated table from data via `tools/validate/gen_ability_docs.py`).
9. Tests, handoff, commit.

## 7. Technical constraints
1. All 21 abilities defined purely by data + shared primitives; adding an ability must not need new code unless it needs a new primitive (prove with a temporary fixture ability).
2. Integer maths, seeded RNG only where unavoidable (Hermes Sandal etc. are limbs, not abilities).
3. Do not add the other 29 GDD abilities or extra ultimates; do not build Pandora's Box/random harmful effects.

## 8. Files and outputs
1. `data/abilities/*.json`, schema, `src/sim/effects/*`, `src/progression/loadout.gd`
2. `tools/sim/balance_sim.gd`, `docs/balance/*`, `docs/ABILITIES.md`
3. Updated animation/audio/icons/AI data; tests and goldens

## 9. Automated tests
1. Per-ability unit tests with exact numbers (cooldown ticks, damage, durations, absorb value, startup window = 42 ticks for ultimates).
2. Loadout validation: slot counts, starter kit, unlocked-only rule, duplicate prevention, lock during match.
3. Effect primitives: each tested in isolation plus stacking/refresh rules.
4. Cooldown cannot be bypassed by input spam; meter spending exact; passives register once.
5. Replays for each ability; AI-uses-abilities soak (no stuck states, invariants hold).
6. Data completeness: every ability has icon, anim_set, audio id, caption id.

## 10. Execution and verification
1. `tools/run_tests.sh` passes.
2. Run `tools/sim/balance_sim.gd` and paste the report summary and any outlier decisions.
3. `python3 tools/validate/validate_all.py` passes; animation validation passes.
4. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. All 21 abilities function in the sim, are equippable per loadout rules and are used by AI.
2. Balance report shows no flagged outliers or each outlier is explained/tuned in data.
3. Regression suite (replays, soak, AI, animation, attachment) passes.
4. Documentation auto-generated from data matches code behaviour.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/17_DATA_DRIVEN_ABILITIES_AND_BALANCING.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No new abilities beyond the 21, no per-ability bespoke scripts, no cinematics system, no unlock logic (19).
2. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
