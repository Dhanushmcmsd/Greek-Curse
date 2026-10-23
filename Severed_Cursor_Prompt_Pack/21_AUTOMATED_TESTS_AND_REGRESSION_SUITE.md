# Stage 21: Automated Tests And Regression Suite

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
QA automation engineer.

## 2. Context
Stage 20 COMPLETE and Checkpoint C resolved: complete content and flow. Tests exist per stage, written incrementally.

## 3. Objective
Audit, consolidate and harden the test suite into a trustworthy regression system: coverage matrix against the GDD Addendum D invariants, golden replays for every body state/fighter/hazard/ability, fuzz and property tests, asset/data/save validation, flake detection, and one-command reporting.

## 4. Prerequisites
1. Stage 20 COMPLETE + Checkpoint C bug fixes completed (record in tracker).

## 5. Workspace inspection
1. `tests/**`, `tools/validate/**`, `tools/sim/**`, `tools/check_all.*`, `docs/TEST_MATRIX.md` (may not exist yet), `docs/COMBAT_RULES.md`.
2. GDD Addendum D (required invariants) and Build Requirements section 9 (tests list).

## 6. Implementation tasks
1. Create `docs/TEST_MATRIX.md` mapping each required invariant to concrete test files: damage and limb-integrity thresholds; Severance Combo timing and attribution; limb caps; body-state transitions (all 16 masks); ability cooldowns; socket compatibility (every regrown limb on every fighter); fighter x arena load; save/load; settings; data schema validity; asset budgets; determinism. Any invariant without a test is a gap - write the missing tests.
2. Golden replays: ensure at least one committed replay for each: each of 4 fighters; each of 3 arenas incl. each hazard; each body-state class; each of the 5 regrown limbs; each of the 21 abilities; a full best-of-three match; a cap-blocked third limb. Replay runner verifies tick-by-tick hash checkpoints. Add `tools/sim/regen_goldens.gd` that regenerates goldens only when called with `--confirm` and prints a diff summary so rule changes are deliberate.
3. Fuzz/property suite (`tests/regression/test_fuzz_sim.gd`): seeded random inputs/loadouts/fighters/arenas for thousands of matches asserting invariants (HP bounds, integrity bounds and monotonicity within a match, cap respected, cooldown never negative, meter bounds, deterministic re-run equality, no stuck states). Print the failing seed and save a replay on failure so failures are reproducible.
4. Mutation sanity check script `tools/sim/mutation_check.py`: for a list of rule constants (block %, chip %, combo gap, grace window, limb cap, regrow %), temporarily alter the data, run the targeted tests, and assert at least one test fails; restore data after (use git stash/temp copies safely). Report any constant whose change no test detects and add tests.
5. Asset/data validation consolidation: `validate_all.py` covers JSON schemas, cross-reference integrity (every id referenced exists: abilities, limbs, moves, anim sets, audio ids, icons, arenas, fighters, captions), `.glb` budgets/nodes/manifest hashes, orphan files, ledger completeness (every file under `assets/` has a ledger row or is in a generated-manifest-covered path), audio validation, UI graph validation, status check, sim purity.
6. Test infrastructure: `--suite` filters (`unit`, `integration`, `regression`, `slow`, `assets`), timing per test, slowest-10 report, JUnit-style XML (`build/test_results.xml`) plus JSON, `docs/test_reports/latest.md` generated summary, exit codes; `tools/check_all.*` runs fast set by default and `--full` runs slow suites.
7. Flake detection: run the full suite 3 times and the fuzz suite with 3 different seeds; any inconsistent result is a defect to fix (usually hidden nondeterminism or order dependence). Randomise test order once to detect inter-test dependence.
8. Missing-resource scanning: a script that loads every `.tscn`/`.tres` and resolves every `res://` path referenced in data files; run Godot headless to capture 'Failed loading resource' lines.
9. Review test quality: list any tests that merely assert existence; strengthen them. Document what the tests do NOT prove (visual quality, game feel, audio quality, performance on target hardware, packaged-build behaviour).
10. Handoff + commit.

## 7. Technical constraints
1. Do not weaken or delete existing tests to achieve green; fix causes.
2. Goldens may only be regenerated through the deliberate tool with an explanation in the handoff.
3. Fast suite should stay under ~2 minutes on a typical dev machine; move slow tests to `--suite slow`.

## 8. Files and outputs
1. `docs/TEST_MATRIX.md`, `docs/test_reports/latest.md`
2. New/updated tests and goldens under `tests/`
3. `tools/sim/{regen_goldens.gd,mutation_check.py}`, enhanced runner and validators

## 9. Automated tests
1. This stage *is* tests; additionally meta-tests: runner returns non-zero on failure; golden regeneration requires `--confirm`; validators fail on fixtures with each class of error (missing reference, bad hash, orphan file, schema violation).

## 10. Execution and verification
1. `tools/check_all.sh --full` exits 0 - paste summary and timing.
2. Run suite three times plus randomised order; paste results.
3. Run mutation check; paste detection table.
4. Show `docs/TEST_MATRIX.md` has no uncovered invariant rows.

## 11. Acceptance criteria
1. Every invariant in the Addendum D list has at least one passing automated test mapped in `TEST_MATRIX.md`.
2. Goldens cover all required content classes; fuzz runs clean across seeds.
3. No flaky tests; mutation check shows tests detect rule changes.
4. Test report generated; limits of automated testing documented.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/21_AUTOMATED_TESTS_AND_REGRESSION_SUITE.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No new gameplay features; only fix defects that tests reveal (smallest fixes, with a regression test each).
2. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
