# Character fit and regrowth follow-up

## Confirmed causes and changes

- The skinned model builder scaled both the armature and its parented meshes. This normalized joints once but geometry twice, stretching Theron's hands away from their finger bones. Meshes are now detached before transform application, and one identical normalization is applied to mesh data and bone data. All ten models and forty replacement limbs were rebuilt. `model_dimensions.json` records the shared normalization.
- The old animation export reduced the source to fifteen joints. The new source clips preserve the original animated spine, shoulder and finger hierarchy. Runtime retargeting transfers rest-relative rotations through each model's coordinate basis, preserving its bone lengths and joint rolls even when source and target have equal bone counts.
- Backward movement now uses the straight backward-walking clip at positive playback speed for all four fighters. Forward movement uses the straight walking clip. Non-attack changes blend over 0.1 seconds. Damage offsets no longer accumulate during hitstop.
- The reported pilot failure was reproduced using the existing project's stale imported limb scenes, despite its GLB files matching the corrected assets. ModelLoader checks the import's recorded source hash and loads the current GLB when the import is stale. Raw GLTF indexed skin bindings are supported alongside named bindings. Failed attachments retain a visible stump.

## Verification

`tests/unit/test_character_fit.gd` covers all ten model heights and floor origins, equal-count rest-pose retargeting, raw-source pilot arm/leg attachment, backward playback and facing for all four fighters, and stable cracked-limb poses during hitstop.

The integration floor-contact test evaluates skinned leg vertices instead of treating an entire leg as a rigid foot. The attachment matrix checks all forty replacements.

The included captures show Theron and Atalanta at 10%, 50% and 90% of idle, forward walking and backward walking. `pilot_regrowth.png` shows both elemental replacements visibly attached in the pilot.

## Rebuilding

Use the local paths configured in `tools/blender/mixamo_paths.json`. Run `pilot_convert_skinned.py` before `build_elemental_limbs.py`, so both use the persisted model normalization. Run `export_source_clips.py` to regenerate full-hierarchy animation sources. Generated runtime assets are committed; Blender and the original FBX files are not required to play the game.

Final validation on Godot 4.7.2: 149 tests passed, 0 failed. Python asset/data validators: 15 passed. GDScript lint and staged whitespace checks passed.
