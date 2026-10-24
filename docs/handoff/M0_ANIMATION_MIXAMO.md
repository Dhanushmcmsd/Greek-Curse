# M0 Animation Pipeline Handoff (Mixamo Integration)

## 1. Summary
Stage M0 Step 3 (Mixamo Animation Integration & Clip Track Binding) is complete. The animation pipeline cleanly loads, binds, and drives the 10 visual fighter models using the 46 retargeted Mixamo clips, with zero unresolved track warnings, accurate foot floor grounding, and verified deterministic combat purity.

## 2. Changed Files
- `src/presentation/fighter_rig.gd`:
  - Implemented dynamic runtime track path rewriting (`_bind_animation_library_to_skeleton`) targeting the live `Skeleton3D` relative to `anim_player.root_node`.
  - Resource duplication on load to prevent cross-fighter track mutation.
  - Integration of `data/animation/mixamo_bone_map.json` for shared 15-bone naming.
- `src/presentation/pose_driver.gd`:
  - Corrected floor grounding in `_ground()`: excludes decorative torso/cloak mesh bounds when legs/feet are intact so foot vertices accurately contact `abs(floor_y) <= 0.015`.
  - Corrected visual reach mismatch measurement: self-buff superpower moves with zero-width hitboxes (`hit_w == 0`) no longer register spurious reach deltas against physical strike tolerances.
- `tools/blender/retarget_mixamo_anims.py`:
  - Added action purge and NLA strip cleanup before GLB export.
  - Set `export_optimize_animation_size=False` in Blender 5.2 to preserve keyframe curves.
- `tests/unit/test_anim_binding_regression.gd`:
  - 3 new regression tests verifying clip track resolution, dynamic skeletal motion, and two-fighter independence.
- `src/debug/animation_lab.gd`:
  - Added clip name, source indicator (`Mixamo [clip_name]` vs `Procedural Fallback`), contact phase marker, and reach delta display.

## 3. Clip Mapping & Seed
- Assignment seed: `42` (reproducible offline mapping stored in `data/animation/mixamo_pack_map.json`).
- Source Inventory: 46 clips processed from `D:\charecter animation` across 9 categories (idle, walk, punch, kick, block, damage taken, death, no legs, walking back/front).
- Shared Clips: Universal damage reactions (`hit_light`, `hit_heavy`, `stagger`, `knockdown`), death, and crawl clips are shared across fighters where appropriate.

## 4. Test & Verification Evidence
- `tools/check_all.ps1`: Exit Code **0**
- Test Count: **128 unit/integration tests passed, 0 failed, 0 skipped**.
- Replay Determinism: Golden hashes matched identically (`test_golden_final_hash` PASS, `test_two_runs_match_every_tick` PASS). Presentation changes did not alter simulation hashes.
- Reach Tolerance: Max reach delta observed: **685 mm** (strictly under the documented 700 mm limit in `data/animation/poses.json`; no tolerances were expanded).

## 5. Visual Evidence
Real in-engine Godot match frames inspected and verified:
1. `docs/playtest/anim/match_shot_theron.png`: Theron vs Atalanta initial round setup in Mount Olympus.
2. `docs/playtest/anim/match_shot_combat.png`: Active combat clash in Mount Olympus with blood particles and dynamic posing.
3. `docs/playtest/anim/match_shot_tartarus.png`: Fighter locomotion and arena boundary lighting in Tartarus Pits.
4. `docs/playtest/screenshots/mixamo_step2/*.png`: Inspected Theron, Atalanta, and Vampire full-body, severed arm/leg, and regrown attachments.

## 6. Known Visual Limitations
- Mixamo models use standard rigid/weight-painted stump cap geometry.
- Full torso crawl/roll uses procedural pitching blended with Mixamo crawl loops when both legs are amputated.

## 7. Next Phase
- Phase C: Diagnose and fix non-working ultimates (starting only upon owner approval).
