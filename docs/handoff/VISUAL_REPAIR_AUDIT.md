# Visual Repair Audit & Handoff: Mixamo Fighters & Presentation

**Date:** 2026-10-25  
**Branch:** `stage-m0-mixamo`  
**Status:** COMPLETE — Ready for Owner Visual Retest  

---

## 1. Executive Summary

This visual-repair pass resolved reported rendering and presentation anomalies across character models, animations, facing orientation, and combat VFX without disturbing simulation determinism or replay goldens:

1. **Scene-Reset Sentinel Test & Asset Cleanliness**: Verified Blender scene-reset safety (`test_scene_reset.py` passes with 96/96 cases). Removed temporary fixture GLBs (`fighter_reset_fixture.glb`, `reset_fixture.glb`) from production asset directories; `validate_all.py` passes cleanly.
2. **Theron Model & Head Audit**: Diagnosed root cause of perceived "missing head" through inspection scripts (`tools/scratch_inspect_theron.gd`, `tools/scratch_test_rig.gd`) and GLB/FBX examination. Theron's head mesh (`HEAD` / `Paladin_J_Nordstrom_Helmet`) and body are fully intact and weighted to `head` bone with valid AABB and active materials. The perceived defect was fighters facing backward relative to the camera due to root-yaw orientation.
3. **Atalanta Combat-Ready Idle**: Replaced acrobatic capoeira spin-kick (`idle_and_start_animation_chapa-giratoria`) with grounded, combat-ready fighting idle (`idle_and_start_animation_idle_5`) from supplied clips in `D:\charecter animation`.
4. **Visual Facing & Backward Walk Presentation**: Corrected `PoseDriver` and `FighterView` so fighters face each other during idle, guard, attacks, and walking. Moving backward away from opponent properly triggers `walk_back` while maintaining forward-facing lock.
5. **Gore & Blood Debris Fixes**: Diagnosed giant opaque chunks (previously whole limb partition meshes with uncentered origins were spawned in `debris()`). Clamped debris piece collision sizing and tuned blood bursts to small, tight, joint-local spreads.
6. **Mechanics & Determinism Preservation**: Preserved limb severing, stump caps, and regrown-limb modifiers. All 130 Godot test cases, Python validation tests, and replay hashes pass.

---

## 2. Detailed Technical Findings & Fixes

### A. Scene-Reset Sentinel & Asset Validation
- Executed `tools/blender/test_scene_reset.py` with Blender 5.2.3 LTS (`SCENE_RESET_OK count=96`).
- Purged temporary fixture artifacts `assets/generated/models/fighter_reset_fixture.glb` and `assets/generated/models/reset_fixture.glb` from Git tracking.
- Confirmed `tools/validate/validate_all.py` passes with 0 orphan or malformed files.

### B. Theron Head Audit
- Ran `tools/scratch_inspect_theron.gd` and `tools/scratch_test_rig.gd` across FBX, converted GLB, and runtime Godot rig.
- Output metrics:
  - Bone: `head` (idx 6, rest origin `(0.00, 0.08, -0.01)`)
  - Mesh node: `HEAD` (`Paladin_J_Nordstrom_Helmet`), visible `true`, skin bind count `67`, valid active materials.
  - Mesh AABB: `(-0.11, 1.75, -0.18)` size `(0.22, 0.30, 0.31)` — non-empty, matching helmet dimensions.
- **Root Cause**: The model was never missing its head; Theron wears a dark helmet that blended into dark backdrops when viewed from behind. Correcting fighter yaw and camera-relative facing revealed his head and armor clearly.

### C. Atalanta Idle Pose
- Edited `data/animation/mixamo_pack_map.json`:
  - `actions.idle.clip`: `idle_and_start_animation_idle_5`
  - `actions.idle.speed_scale`: `1.0`
- Atalanta now rests in an upright, stable guard stance facing opponent rather than spinning in place.

### D. Visual Facing & Root-Yaw Handling
- In `src/presentation/fighter_view.gd`:
  - Tracked horizontal displacement `fighter.x - _prev_x` to drive `PoseDriver.walk_direction` (+1 or -1).
- In `src/presentation/pose_driver.gd`:
  - When walking away from opponent (`walk_direction != 0 and walk_direction != fighter.facing`), prioritizes `walk_back` over `run`.
  - Exposed `current_action_name` and `current_clip_id` for automated regression testing.
  - Preserved facing angle (+90° / -90° yaw along Godot X/Z axes) so fighters always face each other during all grounded actions.

### E. Gore & Blood Particle Debris
- In `src/presentation/gore_manager.gd`:
  - Clamped debris collision half-extents in `debris()` to `Vector3(0.35, 0.35, 0.35)`.
  - Tuned `burst()` particle size from oversized sprites to compact droplets (`0.016m` normal, `0.025m` severed).
  - Reduced particle spread velocity to keep blood bursts local to the severed joint socket.

---

## 3. Regression Tests & Verification

- Added `test_atalanta_idle_and_backward_walk_presentation()` in `tests/unit/test_anim_binding_regression.gd`:
  - Verifies Atalanta initializes with `idle` action and clip `idle_and_start_animation_idle_5`.
  - Verifies moving away from opponent switches to `walk_back`.
  - Verifies moving forward switches to `walk_fwd`.
- Verification Suite (`tools/check_all.ps1`):
  - **Godot Unit Tests**: 130 passed, 0 failed, 0 skipped.
  - **Python Unit Tests**: 14 tests OK.
  - **Status Tracker**: 12 tests OK.
  - **GDScript Formatter (`gdformat`)**: 128 files clean.
  - **GDScript Linter (`gdlint`)**: Success, no problems found.
  - **validate_all.py**: PASS.
  - **Deterministic Replays**: Golden hashes intact (`test_proto_determinism.gd` passes).

---

## 4. Visual Inspection Artifacts

Playtest screenshots captured and verified:
1. `docs/playtest/anim/match_shot_theron.png`: Clean visual presentation in Mount Olympus showing Theron and Atalanta facing each other, Theron's helmet clearly visible, Atalanta in combat idle.
2. `docs/playtest/anim/match_shot_combat.png`: Combat clash demonstrating joint-local blood burst effects and clean model silhouettes.
3. `docs/playtest/anim/match_shot_tartarus.png`: Tartarus arena lighting and root-yaw orientation during action.

---

## 5. Next Steps for Owner
- Launch `scenes/match/match_prototype.tscn` or `scenes/debug/animation_lab.tscn` in Godot to visually inspect idle postures, backward walk, and hit effects.
