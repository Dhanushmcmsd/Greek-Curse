# Stage 14: Animation And Code Driven Motion

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Technical animator / gameplay animation programmer (code-driven motion).

## 2. Context
Stage 13 COMPLETE and Checkpoint B resolved: rigged generated fighters, regrown limbs, sim states for everything.

## 3. Objective
Implement presentation-only, code-driven animation for all fighter states from a data-defined pose library, with dedicated hop, crawl and Torso Mode behaviour, missing-limb hiding, regrown-limb quirks and frame-exact attack readability. No Blender-authored animation clips (D-013).

## 4. Prerequisites
1. Stage 13 COMPLETE + Checkpoint B resolved (record result).

## 5. Workspace inspection
1. `src/presentation/{fighter_rig,fighter_view,limb_quirks}.gd`, `src/sim/` state enums and move data (startup/active/recovery), `data/balance/body_states.json`.
2. GDD Technical Design (Animation row), Addendum C; Build Requirements section 4; Checkpoint B notes.

## 6. Implementation tasks
1. Pose library `data/animation/poses.json` (+schema): named poses as bone Euler rotations (degrees) and optional root offsets for the shared skeleton (rest = zero). Pose sets: `idle`, `walk` cycle (4-6 keys), `block`, `dodge_roll`, `hit_light`, `hit_heavy`, `knockdown`, `get_up`, `victory`, `defeat`, `stagger`, `grab_hold`, `grab_throw`; attack key poses (`startup`, `active`, `recovery`) per move class (`punch_light`, `punch_heavy`, `kick_mid`, `kick_low`, `kick_flying`, `headbutt`, `shoulder_charge`, `bite`, `stump_strike`, `low_sweep`, `scuttle_attack`, `roll_attack`, `super_cast`, `ultimate_cast`); body-state sets `hop`, `crawl`, `torso_scuttle`, `torso_roll`; moves reference `anim_set` ids in their data.
2. `src/presentation/pose_driver.gd` (`PoseDriver`): reads sim state each frame (state enum, `state_tick`, move data, facing, body state, hitstop) and sets `Skeleton3D` bone poses by blending pose keys; attack poses are **phase-locked to sim ticks** (startup/active/recovery boundaries map exactly) so what the player sees matches the hitbox timing; smoothing is visual only. Uses Godot `Skeleton3D.set_bone_pose_*`; no AnimationPlayer clips required (an AnimationTree is NOT used).
3. Procedural layers: breathing/idle sway, weight shift on walk, lean into movement, hit reaction recoil from knockback direction, hit-stop shake, tail-less secondary motion for capes (simple spring on a cape bone or node if present), limb hang for Cracked limbs (limb group rotated/drooped using data-defined angles), stump twitch on severing.
4. Missing limbs: hide limb groups and show stumps (rig layer). Pose driver must skip missing bones' effects safely and re-balance the root (e.g., one-leg hop lowers the pelvis; no-legs crawl drops the torso to ground height; torso mode uses a rolling pivot). Dedicated motion is limited to **hop, crawl, Torso Mode scuttle and roll** (D-013); everything else reuses base poses.
5. Regrown limb quirk motion hooks (squeak squash on punch, claw snap, giant hand wave in idle, marble pose + creak timing, sandal wing flutter) via `limb_quirks.gd`, driven by sim events and idle timers.
6. Scale-robustness: poses are rotation based and proportion independent; verify on Pyrrhus (1.55 m) and Theron (2.05 m) that feet touch the floor (compute foot-height offset per fighter from rig and correct root height), and that attack reach in visuals approximates hitbox reach (log mismatch in mm; tolerance data-driven).
7. Tools: `scenes/debug/animation_lab.tscn` (pick fighter, state, limb mask, regrown limb; scrub `state_tick`; show hitbox overlay on top of poses) and `tools/anim/pose_validate.py` (every referenced pose/bone exists; angles within joint limits defined in data; no NaN).
8. Tests, previews (contact sheet of key poses per fighter via headless Godot screenshots if possible), docs `docs/ANIMATION.md`, commit.

## 7. Technical constraints
1. Presentation-only; never feeds back to the sim.
2. No authored clips, no mocap, no Mixamo or external animation.
3. Pose data editable without code; no magic numbers in `pose_driver.gd`.
4. Maintain 60 FPS budget: no per-frame allocations in hot loops where avoidable.

## 8. Files and outputs
1. `data/animation/poses.json` (+schema)
2. `src/presentation/{pose_driver,limb_quirks}.gd` updates, `scenes/debug/animation_lab.tscn`
3. `tools/anim/pose_validate.py`
4. `docs/ANIMATION.md`, tests

## 9. Automated tests
1. Pose validation script on all pose data (Python unittest + CI hook).
2. Godot: for every fighter x sim state x body-state mask, driver produces finite bone transforms (no NaN/inf), no exceptions, no missing-bone errors.
3. Phase-lock test: for each move, the pose phase at `startup_end`, `active_start`, `active_end` ticks equals the declared keys (table test).
4. Foot-floor test on all four fighters in idle, walk, hop, crawl.
5. Missing-limb visibility test per mask.

## 10. Execution and verification
1. `tools/run_tests.sh` passes; `python3 tools/anim/pose_validate.py` passes.
2. Windowed (if possible): capture screenshot strip of each state for Theron and Pyrrhus from `animation_lab.tscn`; else UNVERIFIED.
3. Replay a golden match through the full presentation headlessly and confirm 0 ERROR logs.
4. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. Every sim state has readable code-driven motion on every fighter, including hop, crawl, torso scuttle/roll.
2. Attack poses are phase-locked to sim ticks (tested).
3. No NaN/log errors across the fighter x state x mask matrix.
4. No Blender-authored animation was added.
5. Regrown-limb quirks work.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/14_ANIMATION_AND_CODE_DRIVEN_MOTION.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No motion-capture, retargeting libraries, or new Blender work except trivial fixes to rig bone names if a defect is found (then regenerate and re-validate).
2. No cinematics for ultimates beyond simple poses (17).
3. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
