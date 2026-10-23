# Stage 25: Post Mvp Online And Content Expansion Plan

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Technical producer and netcode/feasibility planner. **Planning only - no code changes.**

## 2. Context
The MVP is released or approved for release. Stages 00-24 COMPLETE. This stage is optional and starts only when the owner explicitly asks to plan the next phase.

## 3. Objective
Produce a realistic, evidence-based expansion roadmap and ready-to-use prompt outlines for online rollback play and content growth, based on what the MVP actually proved, without implementing anything.

## 4. Prerequisites
1. Stage 24 COMPLETE and owner release approval recorded.
2. Owner explicitly requests post-MVP planning.

## 5. Workspace inspection
1. `docs/release/FINAL_ACCEPTANCE_REPORT.md`, `docs/KNOWN_ISSUES.md`, balance reports, playtest feedback, `docs/ARCHITECTURE.md`, `docs/COMBAT_RULES.md`, `docs/PERFORMANCE.md`.
2. GDD sections 8, 11, 12, 17 (phases 2-5), Build Requirements sections 1, 9, 10.

## 6. Implementation tasks
1. Online feasibility assessment: using the current sim, list exactly what rollback needs (input-delay vs rollback model, state snapshot/restore performance, serialisation size, determinism evidence from replays/fuzz, presentation rollback-safety, RNG restoration, event replays); evaluate candidate approaches (e.g. the netfox addon with a relay such as noray, or a custom rollback layer) by reading their **current** documentation/licences/Godot-version support if web access exists - mark each claim verified or unverified; propose a spike plan with measurable exit criteria (e.g. 100 ms RTT sim, desync count zero over N matches) and a go/no-go rule.
2. Define the online prompt series outline (each a future prompt file, 30-50 lines): snapshot/restore API and tests; deterministic input serialisation; local rollback simulation with artificial latency; transport/relay integration; lobby and direct-connect; desync detection and reporting; matchmaking/ranking; server-checked results for ranked (backend options, costs, privacy duties); anti-cheat limits; safety/reporting; QA plan; rollout/beta plan.
3. Content expansion roadmap: priority order and effort estimates for remaining fighters (6), arenas (5), abilities (29), regrown limbs (5), Death Match/Thunder Strike/Last Stand/Execution, Legacy, Hall of the Fallen, cosmetics/titles, Pantheon bosses, additional animation; for each, list which data/scripts/tools already support it and what new primitives are needed; use measured MVP effort per item from the handoff history.
4. Deferred modes assessment (4-player brawl, co-op bosses, spectator/replays): technical prerequisites and recommended sequencing; clearly keep them out of any near-term plan unless the owner chooses.
5. Risk register and legal/privacy implications of going online (data collection, accounts, moderation, reports/blocks, age-related rules, platform requirements) flagged for professional review; no legal conclusions.
6. Write `docs/post_mvp/ROADMAP.md`, `ONLINE_FEASIBILITY.md`, `CONTENT_EXPANSION.md`, and prompt outline files under `docs/post_mvp/prompt_outlines/`. Commit docs only.

## 7. Technical constraints
1. Documentation only: do not modify `src/`, `data/`, `tools/` or add dependencies.
2. Every external-tool claim must cite a source and retrieval date or be labelled unverified.

## 8. Files and outputs
1. `docs/post_mvp/*`

## 9. Automated tests
1. None (docs). Run `tools/check_all.sh` to confirm nothing else changed and `git diff --stat` shows docs only.

## 10. Execution and verification
1. `git diff --stat` shows only `docs/post_mvp/` and tracker changes.
2. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. Roadmap and feasibility documents exist, are evidence-based and flag unverified claims.
2. Prompt outlines exist for online and content phases.
3. No code or dependency changed.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/25_POST_MVP_ONLINE_AND_CONTENT_EXPANSION_PLAN.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. Do NOT implement netcode, add addons, or add content in this stage.
2. Do not commit the owner to dates or costs.
3. Keep free/no-monetisation commitment intact.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
