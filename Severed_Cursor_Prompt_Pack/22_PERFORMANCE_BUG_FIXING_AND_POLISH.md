# Stage 22: Performance Bug Fixing And Polish

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Performance engineer and gameplay polish engineer.

## 2. Context
Stage 21 COMPLETE: robust regression suite. Known issues are listed in `docs/KNOWN_ISSUES.md` and `docs/playtest/*` reports.

## 3. Objective
Profile and optimise within documented target-hardware assumptions, remove log errors and leaks, burn down known bugs by severity with regression tests, and apply data-driven game-feel polish - without changing locked scope.

## 4. Prerequisites
1. Stage 21 COMPLETE.

## 5. Workspace inspection
1. `docs/KNOWN_ISSUES.md`, `docs/playtest/*`, `docs/test_reports/latest.md`, `docs/TECHNICAL_PLAN.md` (performance budgets, renderer).
2. GDD 14 (performance target: 60 FPS on mid-range integrated graphics, decal budget and chunk cap).

## 6. Implementation tasks
1. Define target hardware assumptions in `docs/PERFORMANCE.md` (example: 4-core CPU ~2018+, integrated GPU class such as Intel UHD 620-630/AMD Vega 8, 8 GB RAM, 1280x720-1920x1080) and clearly state that you can only measure on the developer machine; record its specs from the OS.
2. Performance harness: `scenes/debug/perf_harness.tscn` with `--perf` flag running scripted AI-vs-AI matches in each arena at gore Max with hazards on and writing `build/perf_<arena>.json` (average/p95/p99 frame time via `Performance` monitors, draw calls, objects, memory, particle/decal/chunk counts, sim step time in microseconds). Also `tools/sim/bench_sim.gd` measuring headless ticks/second.
3. Analyse and fix hotspots within reason: pooled particles/decals/chunks, shadow quality presets, reduced per-frame allocations, material/mesh count reduction, `MultiMesh` for crowd/props if needed, lower default shadow/AA for low-end preset, add an automatic **Low/Medium/High graphics preset** in settings (data-driven; default chosen from a quick benchmark or Medium) - keep the settings UI consistent with stage 20 (update the screen and tests). Targets: sim step <= 1 ms average on the dev machine; frame time p95 <= 16.6 ms at 1080p dev machine; if the dev machine cannot represent the target class, mark target-hardware performance `UNVERIFIED` and ask the owner at Checkpoint D to report the FPS on their hardware.
4. Leak and error hygiene: run autoplay for 50 matches with `--verbose`; assert zero ERROR/WARN spam, orphan node count stable (`Performance.OBJECT_ORPHAN_NODE_COUNT` check at match end), memory growth bounded; fix leaks (freed nodes, signals, pooled objects).
5. Bug burn-down: triage every item in `docs/KNOWN_ISSUES.md` and playtest reports by severity (blocker/major/minor/cosmetic); fix all blockers and majors; for each fix add a regression test or replay; record deferrals for minors with reasons.
6. Game-feel polish through **data** only where possible: hit-stop and shake defaults, camera smoothing, input buffer length, telegraph visibility, sound mix levels (balance SFX/music), UI feedback timing, health-bar clarity; keep sim-affecting changes minimal and re-run goldens/balance deliberately. Record before/after rationale; state that final feel judgement belongs to the owner.
7. Readability pass: contrast of fighters against arenas, limb state readability on all palettes, HUD at 720p and 1080p and text scale 200%, caption readability.
8. Input latency review: document the pipeline from device event to sim step to rendered frame, confirm no extra buffered frames are introduced by our code, and list measured values or mark UNVERIFIED.
9. Update docs and tracker; commit.

## 7. Technical constraints
1. No new features. Optimisations must not change sim outcomes (goldens identical) unless deliberately regenerated with justification.
2. Do not claim target-hardware results you did not measure.
3. Keep the Compatibility-renderer decision unless measurements justify change (record the evidence).

## 8. Files and outputs
1. `docs/PERFORMANCE.md`
2. `scenes/debug/perf_harness.tscn`, `tools/sim/bench_sim.gd`, perf JSON in `build/` (uncommitted)
3. Fixes with regression tests, updated `KNOWN_ISSUES.md`, `docs/POLISH_LOG.md`

## 9. Automated tests
1. Regression tests for each fixed bug.
2. Perf budget tests where deterministic (sim step ceiling measured in ticks/sec with generous margin; pool caps).
3. Leak test: orphan node count after N matches does not grow beyond a tolerance.
4. Graphics preset persistence/validation tests.

## 10. Execution and verification
1. Run the perf harness for all arenas; paste summary table.
2. Run 50-match autoplay and paste ERROR/WARN count and orphan stats.
3. `tools/check_all.sh --full` exits 0.
4. Confirm goldens unchanged (or list deliberate regenerations).

## 11. Acceptance criteria
1. Measured performance recorded and meets documented budgets on the dev machine (or UNVERIFIED target clearly flagged).
2. No blocker/major known issues remain open; each minor has a justification.
3. Autoplay shows no ERROR logs or leaks.
4. Polish changes documented.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/22_PERFORMANCE_BUG_FIXING_AND_POLISH.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No new content/features/arenas/abilities; no engine upgrade without owner approval.
2. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
