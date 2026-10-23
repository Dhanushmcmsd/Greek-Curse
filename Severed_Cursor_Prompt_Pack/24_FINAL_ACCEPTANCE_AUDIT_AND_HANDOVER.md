# Stage 24: Final Acceptance Audit And Handover

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Independent acceptance auditor and technical writer. You verify; you do not build features.

## 2. Context
Stage 23 COMPLETE and Checkpoint D passed. A release-candidate build exists.

## 3. Objective
Independently re-verify every stage's claims, audit scope compliance, produce the final acceptance report separating verified from unverified and deferred work, and write the handover documentation so the project can be maintained and extended.

## 4. Prerequisites
1. Stage 23 COMPLETE + Checkpoint D PASS recorded.

## 5. Workspace inspection
1. `PROJECT_STATUS.md`, all `docs/handoff/*`, `docs/TEST_MATRIX.md`, `docs/KNOWN_ISSUES.md`, `docs/release/*`, the release-candidate package, the git log.
2. GDD MVP scope (Production Addendum A-E) and `docs/DECISIONS.md`.

## 6. Implementation tasks
1. Fresh verification run from a clean clone: `git clone` the repo into a temp directory (or `git worktree`), follow the README build instructions exactly, regenerate assets, run `tools/check_all --full`, build, run the exported smoke tests. Any divergence from the documented procedure is a defect: document and fix the docs or code.
2. Stage-by-stage audit: for stages 01-23 re-check the acceptance criteria that can be re-run mechanically; produce a table stage | criterion | re-verified (PASS/FAIL/UNVERIFIED) | evidence command/output. Any FAIL reopens that stage (set PARTIAL in tracker) and gets a targeted fix.
3. Scope audit: automated + manual checks that none of the deferred features exist: grep for network classes/addons, `rollback`, `matchmaking`, `ranked`, 4-player/co-op/spectator scenes, Death Match/Thunder Strike/Legacy/Hall features, extra fighters/arenas/abilities/limbs beyond the locked lists (count data files and compare to DECISIONS), unexpected dependencies, voice/TTS assets. Report counts: fighters=4, arenas=3, abilities=21, regrown limbs=5.
4. GDD fidelity audit: compare implemented rules against the GDD numbers (300 HP, 100 integrity, 70%/25% block, 3-hit combo and 1.5 s gap, 0.5 s grace, 2-limb cap, Desperate Fury 6 s, 30% meter on limb loss, 80% regrown integrity, rounds best of three at 90 s) via a script that reads data and prints a table of GDD value vs data value; list intentional deviations with decision ids.
5. Write `docs/release/FINAL_ACCEPTANCE_REPORT.md`: **Verified** (with evidence), **Unverified** (with why and who can verify), **Deferred** (with GDD reference), **Known issues**, **Human checkpoint results A-D**, **Performance measured vs assumed**, **Legal/store status (verified/assumed/owner-only)**, and an explicit statement that automated tests do not prove fun, balance feel, or visual quality.
6. Handover documentation: `docs/HANDOVER.md` plus how-tos `docs/howto/{ADD_FIGHTER,ADD_ABILITY,ADD_REGROWN_LIMB,ADD_ARENA,REGENERATE_ASSETS,RUN_TESTS,BUILD_RELEASE,UPDATE_GOLDENS}.md`, each validated by actually following it once with a throwaway fixture (e.g. add and remove a fixture ability) and reverting; architecture overview refreshed; list of tuning files; glossary.
7. Update `docs/post_mvp/` pointers (prompt 25 will expand). Make a final tracker update; propose (do not create) the release tag; compile the owner's final approval checklist (release go/no-go) in `docs/release/OWNER_SIGNOFF.md`.
8. Commit; hand off.

## 7. Technical constraints
1. No new features. Fix only documentation or defects found by the audit (with tests).
2. Be adversarial: try to disprove earlier claims.
3. Do not mark anything verified without a command output or a recorded human checkpoint result.

## 8. Files and outputs
1. `docs/release/FINAL_ACCEPTANCE_REPORT.md`, `OWNER_SIGNOFF.md`
2. `docs/HANDOVER.md`, `docs/howto/*.md`
3. `tools/validate/gdd_fidelity.py` (+ test)
4. Updated tracker

## 9. Automated tests
1. GDD fidelity script test against fixture data; scope-audit script `tools/validate/check_scope.py` with tests (fails if deferred artefacts or counts exceed locked lists).

## 10. Execution and verification
1. Clean-clone build and test run results pasted.
2. `check_scope.py` and `gdd_fidelity.py` outputs pasted.
3. Each how-to followed once; list results.
4. `python3 tools/status/status_check.py` passes.

## 11. Acceptance criteria
1. Clean-clone reproduction succeeds or defects are logged and fixed.
2. Final acceptance report complete, honest and consistent with the tracker.
3. Scope audit confirms the MVP contains only locked content and no deferred systems.
4. Handover docs validated by use.
5. Owner sign-off checklist ready.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/24_FINAL_ACCEPTANCE_AUDIT_AND_HANDOVER.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No features, no publishing, no tagging without approval.
2. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
