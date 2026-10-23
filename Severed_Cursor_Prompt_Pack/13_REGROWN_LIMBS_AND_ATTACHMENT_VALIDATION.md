# Stage 13: Regrown Limbs And Attachment Validation

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Gameplay programmer and technical artist.

## 2. Context
Stage 12 COMPLETE: four generated fighters with sockets, stumps, limb groups; rig layer; sim has limb states and a `SimModifier` list.

## 3. Objective
Implement the five MVP regrown limbs end to end (data, generated models, sim effects with benefits and twists, rig attachment) and an automated test that attaches every regrown limb to every fighter. **Prepares Human Checkpoint B.**

## 4. Prerequisites
1. Stage 12 COMPLETE.

## 5. Workspace inspection
1. `data/fighters/*`, `src/sim/{sim_limb,sim_limbs,sim_modifier}.gd`, `src/presentation/fighter_rig.gd`, `tools/blender/lib/*`.
2. GDD section 9 (full table), 7.1, 13.1; D-009; Build Requirements 'Regrown limbs'.

## 6. Implementation tasks
1. Data: `data/limbs/<id>.json` for `rubber_chicken_arm`, `cyclops_giant_hand`, `crab_claw_arm`, `marble_statue_leg`, `hermes_sandal_leg`: slot (arm/leg), display name, benefit text and twist text (from the GDD, unaltered meaning), `integrity_pct: 80`, modifier definitions (numbers in data), cosmetic quirk ids, tooltip lines, icon id. Schema + validation. No hidden penalties: every effect must appear in the tooltip text; add a validator test that each modifier key has a tooltip line.
2. Sim effects through `SimModifier` + small hooks (document each in `COMBAT_RULES.md`): **Rubber Chicken Arm** +30% light-punch reach (hitbox extension), twist: a whiffed heavy punch causes a 0.3 s (18 tick) self-stagger; squeak is a presentation event. **Cyclops Giant Hand** larger arm hitbox and +40% heavy-punch damage (screen-blocking is NOT implemented as an input-affecting thing; the twist is cosmetic: oversized model and an idle wave - the limb's larger body hurtbox is the real downside; state this in the tooltip). **Crab Claw Arm** pincer grab from the arm slot that holds the target briefly and deals high chip damage; twist: after a whiffed grab, with a data-driven percent chance (seeded `SimRng`) the claw gets stuck for 30 ticks. **Marble Statue Leg** +50% leg integrity and heavier kicks (+damage %), twist -20% movement speed. **Hermes Sandal Leg** +25% movement speed and a quick short dash (data), twist: occasionally (seeded RNG, data-driven chance per N ticks while moving) zooms a short distance in a random direction.
3. Regrow API in sim: `SimLimbs.regrow(slot_id, limb_id)` valid only if that slot is Severed; sets integrity to 80% of the slot's normal max (scaled by toughness), state recomputed, `regrown_id` set, modifiers registered; regrown limbs can be Cracked/Severed again by the same rules; severing a regrown limb clears its modifiers. A fighter can have several regrown limbs. Regrowth never restores the original limb.
4. Generate models: `tools/blender/build_limb.py --id <id>` for each of the five using the shared primitives, sized to attach at `SOCKET_ARM_*` / `SOCKET_LEG_*` using a socket-relative local frame; separate named child nodes for moving parts (`PART_beak`, `PART_claw_upper`, `PART_claw_lower`, `PART_wing` not needed, `PART_sandal_wing`, `PART_hand_finger_*` as meaningful) so code can wobble them; budgets <= 600 tris; palette-driven; left/right handedness handled by generator mirror or sign parameter, never by manual flipping in Godot. Export `limb_<id>.glb` (slot-agnostic mirrored variants `_l`/`_r` if mirroring is needed).
5. Rig attachment: `FighterRig.attach_regrown(slot, limb_id)` hides the natural limb group and stump, attaches the limb scene to the socket with a per-fighter scale factor derived from the fighter's limb thickness/length parameters, and exposes moving parts. `detach_regrown(slot)`. Procedural quirks (`src/presentation/limb_quirks.gd`): squash/stretch/wobble/wave/jitter driven by time and sim events - transforms only, no animation clips.
6. **Attachment validation matrix**: Python (`tools/validate/validate_attachments.py`) computes, from GLB data, for every regrown limb x every compatible slot x every fighter: attachment point error vs socket, bounding box overlap with torso/head beyond tolerance, protrusion below floor, scale sanity. Godot test `tests/integration/test_attachment_matrix.gd` instantiates every fighter, attaches every limb in every compatible slot, asserts nodes resolve, transforms are finite, bounds are within tolerance, and detaching restores the natural limb. Also `scenes/debug/attachment_lab.tscn` cycling the matrix with optional screenshots into `build/previews/attachment_matrix/`.
7. Generate limb preview sheet `build/previews/limbs.png` and review for clarity (silhouette distinct from natural limbs and from each other at game camera distance); fix the top visual issues in generators.
8. Update replays/goldens deliberately; tests; handoff includes the Checkpoint B package: `docs/playtest/CHECKPOINT_B.md`. Because Obol trading is not built until stage 19, provide a debug way to grant limbs: `scenes/debug/regrow_lab.tscn` (choose fighter, sever a slot, regrow any valid limb, fight a dummy/AI).

## 7. Technical constraints
1. All numbers in data; no per-limb hard-coded logic outside small, documented hooks driven by modifier keys.
2. Randomness only via sim `SimRng`; deterministic replays must still pass.
3. Do not implement Obol UI or the unlock economy (19).

## 8. Files and outputs
1. `data/limbs/*.json` (+schema)
2. `src/sim/` regrow + hooks, `src/presentation/limb_quirks.gd`
3. `tools/blender/build_limb.py`, `assets/generated/models/limb_*.glb`
4. `tools/validate/validate_attachments.py`, `tests/integration/test_attachment_matrix.gd`
5. `scenes/debug/{attachment_lab,regrow_lab}.tscn`
6. `docs/playtest/CHECKPOINT_B.md`

## 9. Automated tests
1. Each limb's benefit and twist have unit tests with exact numbers (reach %, stagger ticks, damage %, speed %, durability %, seeded RNG sequence for twists).
2. Regrow validity (slot must be Severed; arm limb cannot go to leg slot); integrity 80% math; re-severing; modifier registration/removal.
3. Attachment matrix (Python + Godot) over 4 fighters x 5 limbs x valid slots.
4. Replay goldens for each regrown limb scenario.
5. Tooltip completeness validator.

## 10. Execution and verification
1. `tools/build_assets.sh`, `tools/validate/validate_assets.py`, `validate_attachments.py` pass.
2. `tools/run_tests.sh` passes (show attachment matrix counts).
3. Generate and inspect `limbs.png`; list issues.
4. Windowed (if possible): `regrow_lab.tscn` screenshot with each limb attached to the tallest and shortest fighter (Theron, Pyrrhus); else UNVERIFIED.
5. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. All five limbs exist as data, models, sim effects and rig attachments.
2. Matrix test passes for all fighters and slots; zero clipping failures under tolerance (tolerances documented).
3. Every benefit and twist is in the tooltip text and is tested.
4. Deterministic replays still pass.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/13_REGROWN_LIMBS_AND_ATTACHMENT_VALIDATION.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No Obol shop or trade UI (19), no unlock offers (19), no extra limbs beyond the five (Pegasus Wing, Satyr Hoof, Olive Branch, Octopus, Hound Pup are deferred), no animation clips.
2. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
