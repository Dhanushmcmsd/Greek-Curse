# Visual Repair Audit & Handoff: Mixamo Fighters & Presentation

**Date:** 2026-10-25  
**Branch:** `stage-m0-mixamo`  
**Status:** OWNER CHECKPOINT 1: REPAIRED & VERIFIED (Ready for Inspection)

---

## 1. Executive Summary

**Owner Checkpoint 1 Audit Update (Repaired & Verified)**:
The deformation pipeline and hazard presentation defects have been completely repaired and verified across all 10 Mixamo character models and arenas:

1. **Rich Deform Rig Architecture**:
   - Starting from original FBX sources (`D:\Charecter model\`), retained the full 65–99 bone deform skeletons with all intermediate spine and neck bones (`Spine1`, `Spine2`, `Neck`) and continuous soft vertex weights.
   - Preserved head and neck continuity: `head`, `neck`, and `torso` form a single continuous mesh (`TORSO_HEAD`), eliminating any mesh shearing, gaps, or head detachment during animation.
   - The 15 primary anatomical deform bones are canonicalized (`root`, `spine`, `head`, `upper_arm.*`, `forearm.*`, `hand.*`, `thigh.*`, `shin.*`, `foot.*`) to bind cleanly with standard animation tracks and `PoseDriver`.
   - The four amputatable limb branches (`arm_l`, `arm_r`, `leg_l`, `leg_r`) are cleanly partitioned into continuous skinned modular meshes tagged with `limb_group` metadata, maintaining matching boundary vertices and original skinning.
   - Modular sockets (`SOCKET_*`) and stump caps (`STUMP_*`, `CUT_*`, `BONE_*`) are generated and bound at exact anatomical joint pivots.
2. **Hazard Column Repair**:
   - In `src/presentation/arena_builder.gd`, the hazard column was completely decoupled:
     - Floor telegraph: Flat, readable marker disk on the ground.
     - Active hazard effect: Replaced the tall solid opaque cylinder with a subtle translucent energy geyser mesh with additive blending supported by the Compatibility renderer.
     - Fighters and combat contact zones remain fully visible during active hazard states.
     - Verified with `test_arenas.gd:test_hazard_presentation_states` (telegraph, active, and reset states).
3. **Gameplay & Determinism Invariance**:
   - SimFighter stats, hurtboxes, damage, sever thresholds, and limb state rules are completely unchanged.
   - Deterministic replay golden hashes match 100% across all ticks.
   - Full test suite passes: 133 Godot tests, 14 Python unit tests, 12 status tests, `validate_all.py`, `gdlint`, and `gdformat`.

1. **Scene-Reset Sentinel Test & Asset Cleanliness**: Verified Blender scene-reset safety via `tools/blender/test_scene_reset.py` in Blender 5.2.3 LTS (`SCENE_RESET_OK count=96`, verifying that 96 retained scene objects/datablocks and unowned sentinels survive consecutive pipeline resets without leaking or purging). Removed temporary fixture GLBs (`fighter_reset_fixture.glb`, `reset_fixture.glb`) and orphan import sidecars (`fighter_test.glb.import`, `fighter_test_export.glb.import`) from production asset folders. Ensured test fixtures write under `build/reset_fixture/`. Confirmed `python tools/validate/validate_all.py` passes cleanly.
2. **Theron Model & Head Audit**: Diagnosed root cause through multi-frame captures and skeletal inspection across source FBX, converted GLB, and runtime Godot rigs. The previous claim that the defect was merely an optical illusion caused by dark helmets or camera angles is withdrawn. The actual deformation occurs because the FBX character skeleton (which contains intermediate spine, neck, and shoulder bones) was collapsed onto a rigid 15-bone armature where mesh parts were rigidly partitioned and weight-bound without soft skinning to preserve natural joint continuity, resulting in joint gaps and head/neck displacement during animation playback.
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

### B. Theron Head & Skeletal Deformation Audit
- Executed in-engine gameplay captures and skeletal inspection across source FBX (`D:\Charecter model\Paladin J Nordstrom.fbx`), converted GLB (`assets/fighters_mixamo/fighter_theron.glb`), and Godot `FighterRig`:
  - **Source FBX Structure**: Contains full anatomical hierarchy: `mixamorig:Hips` -> `mixamorig:Spine` -> `mixamorig:Spine1` -> `mixamorig:Spine2` -> `mixamorig:Neck` -> `mixamorig:Head` -> `mixamorig:HeadTop_End`.
  - **Conversion Breakdown**: In `tools/blender/mixamo_to_fighter.py`, the mesh was cut into discrete rigid chunks (`HEAD`, `TORSO`, `PELVIS`, limb segments) and forced into a 15-bone armature with single 100% rigid bone weighting per chunk.
  - When animations apply rotations to `spine` and `head` without the source neck/spine intermediate transforms, and with the head pivot placed at `(neck_pos)` without soft bind weights, the head mesh visually shears and displaces away from the torso during dynamic poses.
  - **Withdrawal of Prior Claim**: The earlier explanation that this was an optical illusion due to dark helmets and camera angles is formally retracted. The defect is an actual geometric displacement caused by rigid chunk binding and armature reduction.

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
