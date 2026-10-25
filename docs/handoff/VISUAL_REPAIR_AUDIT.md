# Visual Repair Audit & Handoff: Mixamo Fighters & Presentation

**Date:** 2026-10-25  
**Branch:** `stage-m0-mixamo`  
**Status:** COMPLETE — Ready for Owner Visual Retest  

---

## 1. Executive Summary

This visual-repair pass resolved reported rendering and presentation anomalies across character models, animations, facing orientation, debris meshes, and combat VFX without disturbing simulation determinism or replay goldens:

1. **Scene-Reset Sentinel Test & Asset Cleanliness**: Verified Blender scene-reset safety via `tools/blender/test_scene_reset.py` in Blender 5.2.3 LTS (`SCENE_RESET_OK count=96`, verifying that 96 retained scene objects/datablocks and unowned sentinels survive consecutive pipeline resets without leaking or purging). Removed temporary fixture GLBs (`fighter_reset_fixture.glb`, `reset_fixture.glb`) and orphan import sidecars (`fighter_test.glb.import`, `fighter_test_export.glb.import`) from production asset folders. Ensured test fixtures write under `build/reset_fixture/`. Confirmed `python tools/validate/validate_all.py` passes cleanly.
2. **Theron Model & Head Audit**: Diagnosed root cause of perceived "missing head" through inspection scripts (`tools/scratch_inspect_theron.gd`, `tools/scratch_test_rig.gd`) and GLB/FBX examination. Theron's head mesh (`HEAD` / `Paladin_J_Nordstrom_Helmet`) and body are fully intact and weighted to `head` bone (idx 6) with valid AABB `(-0.11, 1.75, -0.18)` of size `(0.22, 0.30, 0.31)` and active materials. The perceived defect was fighters facing backward relative to the camera due to inverted root-yaw orientation.
3. **Atalanta Combat-Ready Idle**: Replaced acrobatic capoeira spin-kick (`idle_and_start_animation_chapa-giratoria`) with grounded, combat-ready fighting idle (`idle_and_start_animation_idle_5`) from supplied clips in `D:\charecter animation`.
4. **Visual Facing, Retreat & Side Swaps**: Corrected `PoseDriver` and `FighterView` so fighters face each other (+90° / -90° yaw) during idle, guard, attacks, advancing, and retreating across both sides (+1 and -1) and during side swaps. Moving backward away from opponent properly triggers `walk_back` while maintaining facing lock on the opponent.
5. **Gore Debris & Blood Tuning**:
   - Diagnosed source of giant opaque chunks: partitioned limb meshes (`ARM_UPPER_L`, `LEG_UPPER_L`, etc.) have local bounding dimensions up to ~0.56m with origins at (0,0,0).
   - In `GoreManager.debris()`, resolved this at the transform/scale level: when the mesh AABB max dimension exceeds 0.35m, visual mesh and collision box are proportionally scaled together (`s = 0.35 / max_dim`), keeping visual mesh and collider dimensions perfectly consistent.
   - In `GoreManager.burst()`, tuned blood bursts to a small, joint-local, brief effect: reduced particle count from 70/112 down to 28 (scaled by gore level), tightened spread cone to 45°, lowered maximum velocity from 4.0 m/s to 2.0 m/s, halved droplet radius to 0.012–0.018m, shortened lifetime to 0.28s, and reduced expanding shock ring scale to 1.6 (lifetime 0.2s).
6. **Mechanics & Determinism Preservation**: Preserved limb severing, stump caps, and regrown-limb modifiers. All 131 Godot test cases, Python validation tests, and replay golden hashes pass.

---

## 2. Detailed Technical Findings & Fixes

### A. Scene-Reset Sentinel & Asset Validation
- Executed `tools/blender/test_scene_reset.py` in Blender 5.2.3 LTS. The test instantiates unowned sentinels (`USER_KEEP_ME`, `Cube`, `Camera`, `Light`, mesh/material datablocks), runs two consecutive pipeline exports to `build/reset_fixture`, and asserts that unowned datablocks and startup nodes survive intact (`SCENE_RESET_OK count=96`, where 96 is the total retained datablock object count).
- Purged temporary fixture artifacts `assets/generated/models/fighter_reset_fixture.glb` and `assets/generated/models/reset_fixture.glb`, as well as orphan sidecars `assets/generated/models/fighter_test.glb.import` and `assets/generated/models/fighter_test_export.glb.import`.
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
  - Locked facing angle (`deg_to_rad(90) * fighter.facing`) so fighters face each other (+90° / -90° yaw along Godot X/Z axes) across idle, guard, attacks, advance, and retreat.

### E. Gore Debris & Blood Particle Tuning
- In `src/presentation/gore_manager.gd`:
  - **Debris Scale/Collider Consistency**: Scaled visual mesh and collision box together when bounding dimension exceeds 0.35m (`visual.scale = Vector3.ONE * s`, `shape.size = (box.size * s).max(Vector3.ONE * 0.03)`).
  - **Blood Burst Tuning**:
    - Severed particle amount: reduced to 28 (at normal gore; scaled by gore level).
    - Severed spread: tightened to 45°.
    - Particle max velocity: capped at 2.0 m/s (down from 4.0 m/s).
    - Droplet radius: 0.012m (normal) / 0.018m (severed).
    - Particle lifetime: shortened to 0.28s.
    - Torus shock ring: inner 0.08m, outer 0.11m, scaled to 1.6 max (down from 4.5), expiring in 0.2s.

---

## 3. Regression Tests & Verification

- Added focused regression tests in `tests/unit/test_anim_binding_regression.gd`:
  - `test_atalanta_idle_and_backward_walk_presentation()`:
    - Verifies Atalanta initializes with `idle` action and clip `idle_and_start_animation_idle_5`.
    - Verifies moving away from opponent switches to `walk_back`.
    - Verifies moving forward switches to `walk_fwd`.
    - Verifies presentation facing on both sides (+1 and -1), retreat (walking backward), and side swaps for both Atalanta and Theron (`rig.basis.z.x * facing > 0.99`).
  - `test_gore_debris_and_burst_joint_local()`:
    - Verifies severed burst particle amount is 28 at normal gore, spread is 45°, velocity <= 2 m/s, droplet radius <= 0.02m.
    - Verifies debris visual mesh scale matches collision shape max dimension (clamped to <= 0.35m).
- Full Verification Suite (`tools/check_all.ps1`):
  - **Godot Unit Tests**: 131 passed, 0 failed, 0 skipped.
  - **Python Unit Tests**: 14 tests OK.
  - **Status Tracker**: 12 tests OK.
  - **GDScript Formatter (`gdformat`)**: 128 files clean.
  - **GDScript Linter (`gdlint`)**: Success, no problems found.
  - **validate_all.py**: PASS.
  - **Deterministic Replays**: Golden hashes intact (`test_proto_determinism.gd` passes).

---

## 4. Visual Inspection Artifacts

Playtest screenshots captured from real gameplay match runs via Compatibility renderer:
1. `docs/playtest/anim/match_shot_theron.png`: Clean visual presentation in Mount Olympus showing Theron and Atalanta facing each other, Theron's helmet clearly visible, Atalanta in combat idle.
2. `docs/playtest/anim/match_shot_combat.png`: Combat clash demonstrating joint-local blood burst effects and clean model silhouettes without giant chunks.
3. `docs/playtest/anim/match_shot_tartarus.png`: Tartarus arena lighting and root-yaw orientation during action.

---

## 5. Next Steps for Owner
- Launch `scenes/match/match_prototype.tscn` or `scenes/debug/animation_lab.tscn` in Godot to visually inspect idle postures, backward walk, and hit effects.
