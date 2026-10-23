# Stage 18: Fighter Roster And Mvp Content

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Content designer-programmer and QA-minded technical artist.

## 2. Context
Stage 17 COMPLETE: abilities, loadouts, balance harness. Four fighter models exist with preliminary stats.

## 3. Objective
Finalise the four MVP fighters (stats, body rules, palettes, identities), the Career ladder opponent data, and verify the complete fighter x arena x body-state content matrix.

## 4. Prerequisites
1. Stage 17 COMPLETE.

## 5. Workspace inspection
1. `data/fighters/*`, `data/balance/stat_curves.json`, `tools/blender/build_fighter*.py`, previews, `data/ai/*`.
2. GDD 4.1-4.3 and body rules; D-006, D-014, D-021, D-022; Build Requirements gap note on Pantheon opponents.

## 6. Implementation tasks
1. Stat mapping (D-022): finalise `data/balance/stat_curves.json`: reach/speed/power/limb toughness/target size 1-5 -> numeric sim values; body rules implemented from the GDD sentence: height adds reach and target size; weight adds knockback resistance and reduces speed; muscle mass adds damage and limb toughness; tougher fighters take longer to cripple but are easier to hit. Express as formulas in data (`body_rules`) that combine the explicit 1-5 stats and the body parameters without double counting; document the worked example for each fighter in `docs/FIGHTERS.md`. Gender/cosmetics never affect stats (assert by test: mirrored-stat fighters with different cosmetics produce identical sim results).
2. Finalise the four roster entries: theron (Reach 4, Speed 2, Power 5, Toughness 5, Target 5), atalanta (3,5,2,2,2), pyrrhus (2,3,4,4,2), sibyl (3,3,3,3,3), their hurtbox profiles generated from height/target size, default AI archetype, default palette set (3 palettes each, start-unlocked), display name/bio line (1 sentence of flavour grounded in the GDD cosmetic identity only - do not invent new lore).
3. Cosmetics: palette application via `apply_palette(id)` for all fighters; costume items visible and distinct in the fighter-select silhouette; verify palettes keep fighters distinguishable in a mirror match (P1/P2 tint rule: if both fighters share a palette, auto-pick an alternative for P2 - data-driven).
4. Career ladder data `data/ladder/career_ladder.json` (+schema): a fixed list of AI opponents for the MVP Career mode (e.g. 6 matches: reskinned MVP fighters with palettes, difficulty ramp, preset loadouts that grow stronger, arena order, optional hazard flag), with names that reuse GDD mythic flavour only as titles (e.g. 'Initiate', 'Challenger') - a deliberate, documented MVP stand-in for the undefined Pantheon list (no bosses, no new models).
5. Name filter: `src/progression/name_filter.gd` with a small local word list in `data/ui/blocked_words.json` (stub list; document that it is basic and replaceable), length/character rules, trim, unicode normalisation; tests.
6. Matrix verification tooling: `tools/sim/content_matrix.gd` loads every fighter x arena x body-state mask (16) x regrown-limb option and runs a short scripted exchange headlessly; reports failures. `tests/integration/test_content_matrix.gd` runs a reduced matrix in the normal suite and the full matrix in `--suite slow`.
7. Balance: run the stage 17 harness with final stats; tune data only; update balance changelog; write `docs/FIGHTERS.md` (stats table, body formulas, design intent per fighter).
8. Visual review: regenerate all fighters and previews; produce side-by-side mirrored-pair previews; list distinctness issues; fix generator parameters; ledger updates.
9. Tests, handoff, commit.

## 7. Technical constraints
1. No new fighters, no stat tweaks via code, no lore invention beyond GDD cosmetic descriptors.
2. All fighters remain on the shared skeleton; regenerate via scripts only.
3. Content additions must stay within triangle budgets.

## 8. Files and outputs
1. Final `data/fighters/*.json`, `data/balance/stat_curves.json`, `data/ladder/career_ladder.json` (+schemas)
2. `src/progression/name_filter.gd`, `data/ui/blocked_words.json`
3. `tools/sim/content_matrix.gd`, `tests/integration/test_content_matrix.gd`
4. `docs/FIGHTERS.md`, balance updates, regenerated models

## 9. Automated tests
1. Stat curve table tests; body-rule formulas with worked examples per fighter (exact integers).
2. Cosmetic neutrality test (stats unaffected by gender/palette/costume).
3. Palette distinguishability rule test.
4. Ladder schema + semantic checks (ids exist, loadouts valid, ramp monotonic).
5. Name filter cases (empty, long, blocked, unicode, whitespace).
6. Content matrix (reduced in normal suite, full in slow suite) passes with zero errors.

## 10. Execution and verification
1. `tools/build_assets.sh`, validators, `tools/run_tests.sh` pass; `--suite slow` full matrix passes (time it).
2. Balance harness run summary pasted.
3. Windowed (if possible): all four fighters in each arena screenshots; else UNVERIFIED.
4. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. Four fighters are mechanically distinct per the GDD stat table and visually distinct.
2. Full fighter x arena x body-state x limb matrix runs clean.
3. Career ladder data defined and valid.
4. Balance report acceptable or documented.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/18_FIGHTER_ROSTER_AND_MVP_CONTENT.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No fifth fighter or additional arena, no Argos/Hippolyta etc., no voice sets, no cosmetic unlock system.
2. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
