# Animation Clip Track Binding Audit (Phase A)

## 1. Overview & Objective
Diagnose and eliminate unresolved animation tracks (such as `AnimationMixer: couldn't resolve track: Skeleton/Skeleton3D:upper_arm.r`) and ensure imported Mixamo animation clips drive the actual displayed fighter skeleton at runtime.

## 2. Runtime Hierarchy Diagnosis

### Real Runtime Node Structure (Match Scene)
When a `FighterView` / `FighterRig` instance is loaded in the match:
- Fighter View: `res://src/presentation/fighter_view.gd`
- Fighter Rig: `res://src/presentation/fighter_rig.gd`
- AnimationPlayer Path: `FighterView/FighterRig/@AnimationPlayer@...` (or sibling/child depending on hierarchy)
- AnimationPlayer `root_node`: `..` (pointing to `FighterRig`)
- Resolved Animation Root Path: `FighterRig`
- Skeleton Node Path: `FighterRig/FIGHTER_<ID>/Skeleton/Skeleton3D`
- Relative Path from Animation Root to Skeleton: `FIGHTER_<ID>/Skeleton/Skeleton3D`

### Root Cause of Track Binding Warnings
Mixamo FBX animations retargeted to GLB contained skeletal track paths formatted either as:
1. `Skeleton/Skeleton3D:bone_name` (assuming a generic root node structure)
2. `FIGHTER_<ID>/Skeleton/Skeleton3D:bone_name` (matching only one specific model casing)
3. Direct root-relative node paths that did not match the live match scene's actual node path from `AnimationPlayer.root_node` to `Skeleton3D`.

When `AnimationMixer` attempted to evaluate tracks at runtime:
```
WARNING: AnimationMixer: couldn't resolve track: Skeleton/Skeleton3D:upper_arm.r
```
Because `AnimationPlayer.root_node` resolved to `FighterRig`, the relative path to the skeleton was `FIGHTER_<ID>/Skeleton/Skeleton3D`, not `Skeleton/Skeleton3D`. Furthermore, imported clips contained 65+ raw Mixamo deform and helper tracks instead of the project's standard 15-bone shared skeleton.

## 3. Implemented Fix

### A. Runtime Skeleton Binding & Track Path Rewriting (`src/presentation/fighter_rig.gd`)
1. Before loading or playing animation libraries, `FighterRig` locates the displayed `Skeleton3D` and resolves `anim_player.root_node`.
2. Computes the exact relative path:
   ```gdscript
   var skel_rel_path: String = str(resolved_root.get_path_to(skeleton))
   ```
3. Dynamically duplicates animation libraries and clips (`Animation.duplicate()`) per instance so fighters don't collide or mutate shared resources.
4. Classifies tracks by track type before rewriting:
   - Evaluates `anim.track_get_type(t)` to distinguish skeletal 3D transform tracks (`TYPE_POSITION_3D`, `TYPE_ROTATION_3D`, `TYPE_SCALE_3D`) from method/property tracks.
   - Distinguishes bone subnames from node path properties, avoiding indiscriminate treatment of subnames as bones.
5. Uses the verified shared bone map (`data/animation/mixamo_bone_map.json`) to translate bone names and re-targets each transform track:
   ```gdscript
   var new_track_path := NodePath(skel_rel_path + ":" + shared_bone_name)
   anim.track_set_path(track_idx, new_track_path)
   ```
6. Enforces non-silent track handling:
   - Required skeletal transform tracks (`FighterRig.REQUIRED_BONES`: 15 deform bones) must resolve to a valid bone on the displayed `Skeleton3D`.
   - If any required bone track is lost or unresolved, validation fails with `push_error`.
   - Optional/helper tracks (such as hand fingers, eyes, skirts, horns) are excluded only through an explicit allowlist rule (`ALLOWED_EXCLUDED_TRACKS`) with an explicit reason.
   - Every track rewrite or exclusion is logged into `FighterRig.binding_audit_log` with `{source_clip, original_path, target_path, track_type, status, reason}`.

### B. Clean Animation Baking Pipeline (`tools/blender/retarget_mixamo_anims.py`)
1. Purges all unbaked source actions and stale NLA strips prior to exporting single-action GLBs.
2. Disables lossy glTF animation optimization (`export_optimize_animation_size=False`) to ensure Godot receives full keyframe curves for position and rotation across all 46 clips.

## 4. Verification & Regression Tests
- Enhanced `tests/unit/test_anim_binding_regression.gd`:
  - `test_clip_track_binding_across_all_fighters_and_models`: Tests all 40 supported fighter/model combinations (4 gameplay fighters: Theron, Atalanta, Pyrrhus, Sibyl x 10 visual models: `theron`, `atalanta`, `pyrrhus`, `sibyl`, `skin_ch39`, `skin_ch40`, `skin_demon`, `skin_kachujin`, `skin_nightshade`, `vampire_stress`).
  - Asserts that the intended Mixamo model is loaded (`is_using_mixamo_model()`) so fallbacks cannot masquerade as success.
  - Compares expected source-bone coverage against the bound animation to confirm all 15 required bones exist and have active tracks.
  - `test_simultaneous_fighters_two_instances_independent`: Records Fighter B's full 15-bone rotation pose, advances Fighter A only, and strictly asserts that Fighter B's pose remains completely unchanged (isolated state). Then advances Fighter B to prove independent playback.
  - `test_motion_playback_proves_active_bone_transform_changes`: Samples keyframes across walk, punch, and kick; proves angular rotation deltas > 0.05 rad on striking limbs across all fighters.
  - `test_visual_multi_frame_sequences`: Tests multi-frame sequences across ticks [0, 8, 16, 24] for idle, walk forward/backward, derived run, block, punches, kicks, stagger, knockdown, crawl, and severed/regrown states; verifies finite bone poses throughout.
- Engine warnings for `unresolved track` eliminated completely across all test runs.

## 5. Track Classification & Audit Status
- All 15 required skeletal transform tracks resolve to displayed skeletons with status `RETAINED`.
- Mixamo accessory/finger/skirt bones are cleanly recorded as `EXCLUDED` via `ALLOWED_EXCLUDED_TRACKS`.
- Zero required deform bones lost.

