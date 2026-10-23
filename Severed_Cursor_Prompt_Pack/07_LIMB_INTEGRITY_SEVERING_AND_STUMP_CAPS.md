# Stage 07: Limb Integrity Severing And Stump Caps

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Gameplay systems engineer implementing the dismemberment rules with exact, testable semantics.

## 2. Context
Stage 06 COMPLETE: per-limb hit detection, damage split, combo tracking, determinism harness.

## 3. Objective
Implement limb integrity states, Severance Combos, amputation credit, per-match limb caps, Desperate Fury, and greybox severing presentation (hide limb + stump cap + blood), all exactly as the GDD defines and fully unit-tested.

## 4. Prerequisites
1. Stage 06 COMPLETE.

## 5. Workspace inspection
1. `src/sim/*`, `docs/COMBAT_RULES.md`, `data/balance/combat.json`.
2. GDD section 7 and 8.x (limb rules only), Addendum D in `docs/source/GDD_extracted.txt`; `docs/DECISIONS.md` D-010, D-011, D-023, D-024, D-025.

## 6. Implementation tasks
1. Data: `data/balance/limbs.json` (integrity base 100; toughness 1-5 -> multiplier table; thresholds Healthy >50%, Bruised 50-26%, Cracked 25-1%, Severed 0; Bruised attack penalty 10%; Severance Combo min hits 3; gap 90 ticks; post-combo grace 30 ticks; per-match limb cap 2; Desperate Fury 360 ticks with speed/damage % buff; ultimate meter gain 30% of max on limb loss; regrown integrity pct 80). Schema + validation.
2. `SimLimb` state per limb: `integrity`, `max_integrity`, `state` (healthy, bruised, cracked, severed), `zero_pending` flag (reached 0 outside a Severance Combo), `credited` flag (amputation credit used this match), `regrown_id` (empty until stage 13). Derive state from integrity by integer percentage thresholds with exact boundary semantics documented in `COMBAT_RULES.md` (use `integrity*100 / max` with floor; 50% exact is Bruised-or-Healthy? **Decide: >50 Healthy, 26-50 Bruised, 1-25 Cracked as per GDD and test the exact boundaries**).
3. Severance Combo detection per defender: a chain of >=3 hits, each gap <= 90 ticks; the chain stays 'live' for 30 ticks after its last hit (grace). A limb whose integrity reaches 0 while the chain is live (or within the grace) becomes **Severed**. Reaching 0 outside a live chain -> state Cracked with `zero_pending=true`; the **next hit that lands on that limb** severs it (subject to caps). Cracked limbs cannot attack or block; Bruised limbs deal 10% less damage.
4. Amputation credit: the attacker (in 1v1 the opponent, but implement per-attacker accumulation) with the most damage dealt to that limb **during the chain** is credited; define and test the tie-break (earliest attacker id). A limb can be credited once per match; record `AmputationRecord {limb, attacker, victim, tick, chain_hits}` for the results screen.
5. Limb cap: in normal matches a fighter can lose at most 2 limbs per match; further limbs stay Cracked (integrity 0, `cap_blocked=true`). (No Death Match exception since Death Match is deferred; leave the cap as a rules field in data.) Heads cannot be severed (D-011).
6. Desperate Fury: on losing a limb the victim gains the buff for 360 ticks (re-triggering refreshes, does not stack) and +30% ultimate meter; wire the meter fill and buff multipliers into the damage/speed calculations through data-driven modifiers (design a small `SimModifier` list on each fighter so stage 13/17 can reuse it).
7. Integrity never regenerates within a round or match. Provide `reset_for_match(mode)` semantics: Fresh Body/Versus/Practice restore all limbs after the match; Career persists limb state (persistence itself is stage 19, but define the pure data in/out: `SimWorld.setup(match_config)` accepts initial limb states; `export_limb_state()` returns them).
8. Events: `limb_state_changed`, `limb_severed {credit}`, `desperate_fury_started`, `limb_cap_blocked`, `combo_extended`. Document each event payload.
9. Presentation (greybox, clearly labelled): `FighterView` tints Bruised limbs, shows a hanging/rotated box for Cracked, hides a Severed limb's box, shows a stump cube and spawns a simple flying limb box and red particle burst; this is replaced by real models in stages 12-15. Add a debug scene `scenes/debug/severing_lab.tscn` with buttons/keys to set limb integrity, force a 3-hit chain, and print events.
10. Update replays/goldens deliberately; write tests; update `COMBAT_RULES.md`; commit.

## 7. Technical constraints
1. Exact GDD semantics; where the GDD is ambiguous record the resolution in `DECISIONS.md` and test it.
2. Integer maths only; thresholds from data.
3. Random luck must never decide an amputation (no RNG in severing logic).
4. Greybox presentation must not alter sim results.

## 8. Files and outputs
1. `src/sim/{sim_limb,sim_limbs,sim_severance,sim_modifier}.gd`
2. `data/balance/limbs.json` (+schema)
3. `scenes/debug/severing_lab.tscn` + script
4. `tests/unit/test_limb_states.gd`, `test_severance.gd`, `test_amputation_credit.gd`, `test_limb_cap.gd`, `test_desperate_fury.gd`; new golden replays `severance_01.replay.json`
5. Updated `docs/COMBAT_RULES.md`

## 9. Automated tests
1. State thresholds at every boundary value for max 100 and for scaled max (e.g. 130, 80).
2. Chain exactly 3 hits with 90-tick gaps severs at 0; 2 hits does not; gap 91 breaks the chain; hit at tick last+30 severs, last+31 does not (Cracked/pending instead).
3. Zero outside chain -> cracked+pending -> next hit severs; hit on a different limb does not.
4. Credit: most damage wins; tie-break; single credit per limb per match; multiple attackers (simulated in unit test).
5. Cap: third limb stays Cracked at 0; cap value from data.
6. Desperate Fury duration, refresh without stacking, meter +30%.
7. Cracked/Bruised combat effects; head never severs.
8. Fuzz: random chains never produce >2 severed limbs, never negative integrity, deterministic hashes.

## 10. Execution and verification
1. `tools/run_tests.sh` passes.
2. Run replay `severance_01` and show the event list in order.
3. If windowed run possible: open `severing_lab.tscn`, trigger a sever, screenshot; otherwise UNVERIFIED (owner sees it at Checkpoint B).
4. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. All limb-rule tests pass with exact boundary coverage.
2. Severing, credit, cap and Desperate Fury work in headless replays and in the greybox lab.
3. No RNG used in severing; purity check passes.
4. COMBAT_RULES.md documents every ambiguity resolution.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/07_LIMB_INTEGRITY_SEVERING_AND_STUMP_CAPS.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No regrown limbs (stage 13), body-state movement (stage 08), real models (stage 12), Death Match/Execution/Last Stand, scars/Chronicle.
2. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
