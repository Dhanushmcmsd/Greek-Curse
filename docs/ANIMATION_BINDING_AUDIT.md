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
4. Uses the verified shared bone map (`data/animation/mixamo_bone_map.json`) to translate bone names and re-targets each transform track:
   ```gdscript
   var new_track_path := NodePath(skel_rel_path + ":" + shared_bone_name)
   anim.track_set_path(track_idx, new_track_path)
   ```
5. Strips unmapped/helper tracks cleanly while retaining all 15 required deform bones.

### B. Clean Animation Baking Pipeline (`tools/blender/retarget_mixamo_anims.py`)
1. Purges all unbaked source actions and stale NLA strips prior to exporting single-action GLBs.
2. Disables lossy glTF animation optimization (`export_optimize_animation_size=False`) to ensure Godot receives full keyframe curves for position and rotation across all 46 clips.

## 4. Verification & Regression Tests
- Added `tests/unit/test_anim_binding_regression.gd`:
  - `test_clip_track_binding_across_all_fighters_and_models`: Verified 0 unresolved tracks across all 4 gameplay fighters (Theron, Atalanta, Pyrrhus, Sibyl) and all 10 visual models (`skin_ch39`, `skin_ch40`, `skin_demon`, `skin_kachujin`, `skin_nightshade`, `vampire_stress`).
  - `test_motion_playback_proves_active_bone_transform_changes`: Samples keyframes across walk, punch, and kick; proves angular rotation deltas > 0.05 rad on striking limbs across all fighters.
  - `test_simultaneous_fighters_two_instances_independent`: Confirms two simultaneous fighter instances hold independent animation players and tracks without collisions.
- Engine warnings for `unresolved track` eliminated completely across all test runs.
