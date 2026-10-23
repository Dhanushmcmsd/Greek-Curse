# Stage 19: Match Results Progression And Saves

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Gameplay/persistence engineer.

## 2. Context
Stage 18 COMPLETE: finalised roster, ladder data, abilities, loadouts, results stub, settings service.

## 3. Objective
Implement the MVP persistence and progression loop: Career fighter creation, match results and Chronicle, win unlock offers, Obol the Broker trade logic and screen components, persistent limb state, minimal retirement, and robust local saves.

## 4. Prerequisites
1. Stage 18 COMPLETE.

## 5. Workspace inspection
1. `src/ui/results_stub`, `src/progression/loadout.gd`, `src/sim/` (limb export/import, AmputationRecord), `data/limbs/*`, `data/abilities/*`, `data/ladder/*`, `src/persistence/settings_service.gd`.
2. GDD sections 3, 6.2, 8.1, 8.2 (retire only), 8.6, 9.1-9.2; D-014, D-015, D-024, D-025; Production Addendum A.

## 6. Implementation tasks
1. Define save schema `data/schema/career_save.schema.json` and `src/persistence/career_save.gd`: `version`, `fighter {id, name, palette, created, unlocked_abilities[], traded_abilities[], loadout, win_count, loss_count, limbs{slot: state/integrity/regrown_id}, ladder_index, offers_state}`, `chronicle {matches[], limbs_lost[], limbs_taken[], longest_combo}`, `fallen[]`, `rng_seed_counter`. Single slot MVP. Atomic writes (write temp, flush, rename), automatic `.bak` of the previous good save, load with schema validation, corruption recovery (fall back to `.bak`, else report 'no valid save' without deleting the corrupt file - rename to `.corrupt-<timestamp>`), migration framework with a v1->v2 test fixture, and no cloud/network anything.
2. Career fighter creation: pick one of the four fighters, name via `name_filter`, pick one of 3 palettes; starter kit unlocked; `fighter.limbs` all healthy. Only one living fighter at a time.
3. Unlock offers `src/progression/unlock_offers.gd`: each Career win offers 3 locked abilities chosen with a seeded RNG (seed derived from save seed counter so save-scumming yields the same offer); first win guarantees a superpower offer, third a passive, fifth an ultimate (offer set may include fewer than 3 if the pool is small); the player picks one; traded abilities return to the locked pool (can be won back); never offer unlocked or starter abilities. **Fresh Body wins** give an offer every third win with a separate counter. Persist pending offers so quitting mid-offer cannot lose or reroll it.
4. Persistent body state in Career: limb states and regrown limbs carry between matches; Fresh Body/Versus/Practice never alter the career limbs; `MatchConfig` for Career takes limbs from the save and match end returns `MatchResult` (winner, rounds, amputation records, combos, limb end-state) which `CareerService.apply_match_result()` applies, including the per-match limb cap already enforced by the sim and the comeback buff handled in-sim.
5. Obol trade logic `src/progression/obol_trade.gd` (pure logic): preconditions (at least one Severed slot, at least one unlocked non-starter ability); the player gives one unlocked non-starter ability; Obol offers up to 3 random options from the MVP limbs that **fit the chosen missing slot** (seeded; fewer than 3 if fewer fit; always allow Decline); each option exposes full benefit/twist/integrity tooltip text from data; accept -> ability removed from unlocked pool and loadout, limb regrown at 80% integrity via the sim limb data; prices never change; no currency exists. Document the 3-arm/2-leg availability consequence (D-009).
6. Obol screen components (`scenes/ui/obol_trade.tscn` + scripts): shows body diagram of missing slots, ability picker, three option cards with tooltips, confirm/decline; Obol's presence = a generated low-poly bust model rendered in a SubViewport (`tools/blender/build_obol.py` using the shared primitive library; <= 800 tris; horned/winged-sandal Hermes-like merchant per GDD text only) and text barks from `captions_en.json` (sarcastic, funny, short; no voice).
7. Chronicle `src/progression/chronicle.gd` + screen component: match history list (opponent, result, rounds, date), limbs lost/taken, notable moment (longest combo), amputation credits; no scars/share-card (deferred).
8. Retire fighter (minimal 'Offering'): confirm dialog with clear warning; archives the fighter into `fallen[]` with final stats/chronicle summary; allows creating a new fighter; **no Thunder Strike cinematic, no Legacy** (D-015). A fighter missing all four limbs gets a gentle prompt suggesting Obol or Offering, never forced.
9. Results screen (replace stub): winner, rounds, damage, combos, amputation credits (both fighters), then Career flow hooks: show unlock offer when due, then 'Visit Obol' if eligible, then ladder progress; Fresh Body/Versus/Practice show results only.
10. Tests: **save/load** round trip; atomic-write interruption simulation (kill between temp write and rename -> old save intact); corrupt-file recovery; migration; unlock offer determinism and guarantees (1st/3rd/5th); trade invariants (cannot trade starter kit; cannot regrow into non-severed slot; ability leaves pool and loadout; limb integrity 80%; only fitting slot options; decline leaves state unchanged); random-sequence fuzz of 10k career events asserting invariants (loadout valid, unlocked pool consistent, no duplicates, at most one living fighter); Chronicle accuracy against replay results.
11. Docs `docs/PROGRESSION_AND_SAVES.md` (flows, schema, recovery behaviour), handoff, commit.

## 7. Technical constraints
1. Local only; no network, no cloud saves, no tamper protection (server checks are deferred) - state this plainly in docs.
2. All writes go through `CareerSave`; no other module writes save files.
3. Progression logic is pure and testable without UI.
4. Do not break sim determinism: sim never reads the save, only a `MatchConfig`.

## 8. Files and outputs
1. `src/persistence/career_save.gd`, `src/progression/{unlock_offers,obol_trade,chronicle,career_service,retire}.gd`
2. `scenes/ui/{obol_trade,chronicle,results}.tscn` + scripts
3. `tools/blender/build_obol.py`, `assets/generated/models/npc_obol.glb`
4. Schemas, `docs/PROGRESSION_AND_SAVES.md`, tests

## 9. Automated tests
1. As listed in task 11 (save, recovery, migration, offers, trade, chronicle, fuzz).
2. UI component smoke tests (instantiate headless, feed a fake save, assert no errors and expected child counts).
3. Asset validators for Obol.

## 10. Execution and verification
1. `tools/run_tests.sh` passes (show fuzz iteration count and seed).
2. Run an automated headless career script `tools/sim/career_autoplay.gd`: create fighter -> AI win -> pick unlock -> lose a limb (forced replay) -> Obol trade -> save -> reload -> verify identical state; show output.
3. `python3 tools/validate/validate_all.py` passes.
4. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. A Career can be created, played through offers/trades, saved and reloaded losslessly.
2. Corruption and interrupted-write recovery tested.
3. Obol trade rules exactly per GDD with MVP limb set; tooltips complete.
4. Retire flow works without cinematic/Legacy.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/19_MATCH_RESULTS_PROGRESSION_AND_SAVES.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No Death Match, Thunder Strike, Last Stand, Legacy, Hall of the Fallen, titles, cosmetic unlocks, share cards, server checks or online anything.
2. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
