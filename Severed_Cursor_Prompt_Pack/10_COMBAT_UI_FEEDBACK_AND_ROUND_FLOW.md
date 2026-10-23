# Stage 10: Combat Ui Feedback And Round Flow

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Gameplay UI programmer and game-feel engineer.

## 2. Context
Stage 09 COMPLETE: MatchConfig, AI, soak, greybox match scene.

## 3. Objective
Build the in-match HUD with the accessible body diagram, round flow presentation, combat feedback (hit-stop use, screen shake, sparks, damage/credit banners), pause menu, and a basic results screen stub, all driven by sim events and settings hooks.

## 4. Prerequisites
1. Stage 09 COMPLETE.

## 5. Workspace inspection
1. `src/presentation/*`, `src/ui/hud_prototype.gd`, sim event definitions in `src/sim/sim_event.gd`.
2. GDD 13.3 (UI), 16.1 (accessibility), 5.2 (rounds); D-018.

## 6. Implementation tasks
1. Create `src/core/settings_hooks.gd` (`SettingsHooks`): a tiny read-only accessor with defaults for screen-shake scale, hit-stop scale, flash reduction, gore level, blood colour, UI text scale, subtitles - stage 16 replaces the backing store with the real service; keep the same interface.
2. Round flow state machine (presentation, `RoundFlow`): intro (fighter names) -> ready -> fight -> KO/time banner -> round end -> next round or match end -> results. It reacts to sim events; the sim remains the authority on outcomes. Deterministic pause: pausing stops the match controller from stepping.
3. HUD (`src/ui/hud/`): main health bars with delayed-damage ghost; stamina bar; ultimate meter; round pips; timer; **body diagram** per fighter (head, torso, 4 limbs) whose limb segments show integrity fill, state icon (check/crack/bandage/X), and **distinct fill patterns per state** (solid, diagonal hatch, dotted, outline) so state is readable without colour; combo counter with hit count and a 'SEVERANCE COMBO' indicator when the chain is eligible; amputation-credit banner; Desperate Fury indicator. Build the pattern textures with a script (`tools/ui/generate_patterns.gd`) rather than hand art, and log them in the ledger.
4. Combat feedback: hit-stop consumption from sim (`hitstop_remaining`) scaled by setting; camera shake on heavy hits and severs scaled by setting; hit sparks and block sparks (CPUParticles3D, low counts); limb flash/tint on damage; slow-down (presentation-only time scale) is NOT used because it would desync; screen-edge vignette for low health (respect flash reduction).
5. Pause menu (Resume / Restart match / Controls reference / Quit to launcher) using `ui_cancel`/Start; works with keyboard and gamepad focus navigation.
6. Results stub (`scenes/ui/results_stub.tscn`): winner, rounds, per-fighter damage dealt, longest combo, amputation list with credit. Real progression/rewards come in stage 19.
7. Theme: create a placeholder `Theme` resource with readable default font and UI scale support (stone/bronze styling is stage 16).
8. Tests, screenshots if possible, docs (`docs/UI_HUD.md`), commit.

## 7. Technical constraints
1. UI/presentation never alters sim state.
2. All visuals must respect `SettingsHooks` (shake, hit-stop scale, flash reduction).
3. No colour-only information anywhere in the HUD.
4. Keep HUD scenes modular (one scene per widget).

## 8. Files and outputs
1. `src/core/settings_hooks.gd`
2. `src/ui/hud/*` + scenes, `src/presentation/round_flow.gd`, pause menu scene, results stub
3. `tools/ui/generate_patterns.gd`, generated pattern textures in `assets/ui/`
4. `docs/UI_HUD.md`; tests

## 9. Automated tests
1. RoundFlow state machine table tests with scripted events (headless).
2. Body diagram: given limb states array -> expected icon/pattern ids per limb (pure function test).
3. Settings scaling: shake/hit-stop values clamp and scale as expected.
4. Pause: stepping stops while paused; resume continues with identical hash to an unpaused run (determinism).
5. Scene smoke: instantiate HUD, pause, results scenes headless without errors.
6. Replay-driven test: run `severance_01` through the controller headlessly and assert the HUD received the credit banner event.

## 10. Execution and verification
1. `tools/run_tests.sh` passes.
2. Windowed (if possible): scripted match with screenshots of HUD at full health, after a severance, and results; save under `docs/playtest/screenshots/`. Otherwise UNVERIFIED.
3. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. HUD shows all required elements and reacts to events.
2. Body diagram readable without colour (patterns+icons).
3. Pause/resume does not change sim determinism.
4. Round flow completes a full match to results.
5. Feedback scales with settings hooks.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/10_COMBAT_UI_FEEDBACK_AND_ROUND_FLOW.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No final art (UI kit is stage 16), no audio (16), no menus beyond pause/results stub (20), no progression (19).
2. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
