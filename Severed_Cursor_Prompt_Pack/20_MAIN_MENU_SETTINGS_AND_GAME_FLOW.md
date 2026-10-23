# Stage 20: Main Menu Settings And Game Flow

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
UI/UX programmer and game-flow integrator.

## 2. Context
Stage 19 COMPLETE: Career, saves, Obol, results, Chronicle components; settings service; HUD; all content. There is no main menu yet.

## 3. Objective
Integrate everything into a complete local game flow from first launch to quitting (age gate, content warning, main menu, Career hub, Fresh Body, Local Versus, Practice, settings, controls, credits), fully navigable by keyboard and gamepad. **Prepares Human Checkpoint C.**

## 4. Prerequisites
1. Stage 19 COMPLETE.

## 5. Workspace inspection
1. All `scenes/ui/*`, `src/ui/*`, `src/presentation/match_launcher.gd`, `src/persistence/*`, `data/ui/*`.
2. GDD sections 3.2, 11, 16.2, 17 (modes), Build Requirements section 6 (screens list); D-014, D-018, D-019.

## 6. Implementation tasks
1. `src/core/scene_router.gd` (autoload `Router`): explicit state machine with a transition table (`boot -> age_gate -> content_warning -> main_menu -> {career_hub, fresh_body_setup, versus_setup, practice_setup, settings, credits}`, `*_setup -> match -> results -> origin`, `career_hub -> {fighter_create, loadout, obol, chronicle, retire, ladder_fight}`), back-stack handling, scene preloading, error screen on any missing scene/data (`scenes/ui/error_screen.tscn` with copyable details and a safe 'return to menu' option).
2. First-launch flow: age gate (self-declaration 18+ with clear wording, decline quits; record in settings; this is a courtesy gate, not verification - state so in docs) and content warning screen explaining extreme violence/dismemberment, the gore slider and that Career limb loss is persistent while Fresh Body is not; shown on first launch and reachable from settings.
3. Main menu (stone/bronze themed, focus-navigable): Career (Continue / New), Fresh Body, Local Versus, Practice, Settings, Credits and Licences, Quit. Continue disabled with explanation when no valid save; if a save is corrupt show the recovery dialog from stage 19.
4. Mode setup screens: fighter select with silhouette/stat bars/palette picker (stats from data), arena select with preview and hazard toggle, loadout screen (equip from unlocked pool; Versus/Practice use full loadout picker with the 21 abilities; locked during match), controller assignment for Versus (P1/P2 keyboard or pads) and AI difficulty for Fresh Body/Practice; a **match banner screen with large text naming the match type** (CAREER - limb loss is permanent / FRESH BODY - no permanent loss / VERSUS / PRACTICE) before the player confirms.
5. Career hub screen (2D menu hub - D-014/D-015): shows fighter body diagram, record, next ladder opponent; actions: Fight, Loadout, Visit Obol (enabled with missing limb), Chronicle, Retire (confirm). Obol's bust and barks displayed in the Obol screen.
6. Settings screen implementing every option from stage 16 with live preview where practical (volume test sounds, shake demo), controls remapping UI for keyboard and gamepad with conflict handling and reset; text scale applies immediately; apply/revert with a 10-second revert timer for display mode changes.
7. Credits and Licences screen generated from `docs/ASSET_LEDGER.md`/`THIRD_PARTY_LICENSES.md` data (build script `tools/build/gen_credits.py` outputs `data/ui/credits.json`).
8. Pause integration, restart/rematch from results, quit-to-menu confirmation in Career matches (explain forfeiting counts as a loss if that is the rule you implement - choose the conservative rule: quitting mid-match in Career does not save limb damage taken in that match, documented in `DECISIONS.md` and the confirm dialog).
9. Autoplay/smoke support: command-line flags (after `--`): `--autoplay-smoke` (boot, load all content, play one AI-vs-AI scripted match through the real router, write `user://smoke_result.json`, exit with code 0 or 1), `--autoplay-career` (scripted Career loop through menus using the router API), `--user-profile <dir>` for isolated settings/saves in tests. These will be reused by the export smoke test.
10. UI tests and navigation audit: `tools/validate/check_ui_graph.py` ensures every screen is reachable, every screen has a back path, no dead ends; Godot smoke test instantiates every scene in `scenes/` headless and reports errors; focus order tests where feasible.
11. Full-flow test: automated run of boot -> menu -> Career new -> fight (AI auto-win using forced replay or AI-vs-AI proxy) -> offer -> Obol (forced severed limb) -> save/exit -> relaunch -> Continue. Docs `docs/GAME_FLOW.md`; Checkpoint C package `docs/playtest/CHECKPOINT_C.md`; commit.

## 7. Technical constraints
1. No new gameplay systems; this is integration and UI.
2. Every screen operable with keyboard and gamepad only; text scale respected.
3. No network features of any kind; no analytics; no external links opened without user action (credits may display URLs as text).
4. Do not hide errors: failures show the error screen and log ERROR.

## 8. Files and outputs
1. `src/core/scene_router.gd`, scenes under `scenes/menus` and `scenes/ui` for all screens
2. `tools/validate/check_ui_graph.py`, `tools/build/gen_credits.py`, `data/ui/credits.json`
3. CLI flags support, `docs/GAME_FLOW.md`, `docs/playtest/CHECKPOINT_C.md`

## 9. Automated tests
1. Router transition table tests (valid and invalid transitions; back-stack).
2. Age gate/content warning first-launch persistence; decline path.
3. Every scene loads headless without errors; UI graph validator.
4. Settings screen -> service round trip; remap conflict handling.
5. `--autoplay-smoke` and `--autoplay-career` executed as tests with isolated profile; assertions on `smoke_result.json`.
6. Loadout screen enforces rules; mode banner text matches mode.

## 10. Execution and verification
1. `tools/run_tests.sh` passes.
2. Run `"$GODOT_BIN" --headless --path . -- --autoplay-smoke --user-profile build/test_profile` and show exit code and result file.
3. Run the career autoplay and show its summary.
4. Windowed (if possible): screenshots of every main screen; else UNVERIFIED.
5. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. From a clean profile the game can be started, accepted, navigated and a full Career loop completed (fight, offer, Obol, save, restart, continue).
2. All MVP modes launch matches with correct rules; settings apply.
3. Navigation graph has no dead ends; error screen handles missing data.
4. Autoplay flags work for later export testing.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/20_MAIN_MENU_SETTINGS_AND_GAME_FLOW.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No online menus, matchmaking, leaderboards, store/shop, Hall of the Fallen, Death Match options, Co-op/4P/Spectator entries, or voice options.
2. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
