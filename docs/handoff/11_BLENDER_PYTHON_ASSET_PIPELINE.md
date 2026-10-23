# Stage 11 - Blender Python Asset Pipeline

## Stage result
COMPLETE. Art was introduced early at explicit owner request, then validated against this stage.

## Changed files
Blender generator/library, art configuration and schemas, fighter body parameters, GLB inspector/validator and negative tests, manifest and eight GLBs, model loader/viewer/rig, expanded model regression tests, previews and pipeline documentation.

## Actual commands and results
tools/build_assets.ps1; tools/blender/test_idempotence.py; Blender test_scene_reset.py and test_data_only.py; Workbench preview_asset.py; Godot import and window captures; tools/check_all.sh with CHECK_ASSET_REGEN=1. 83 Godot tests passed, 0 failed/skipped. Python validators/status tests passed. Full check_all PASS in build/check10_12.log; subsequent helper extraction rechecked by idempotence11_final.log and validate_assets PASS.

## Acceptance criteria
Eight assets (four fighters, three arenas and pipeline fixture) regenerate byte-identically. Owned reset preserves sentinel and stable object count (55). GLB negative tests, manifests, vertex colors, triangles, nodes and Godot loader PASS. Workbench ten-view contact sheet and roster rendered and inspected. Helpers consolidated into shared primitives/materials rather than one separate file for every primitive.

## Decisions and known limitations
Documented importer adaptation rather than relying on glTF parent empties. Meshes use vertex colors; enable their Godot material flag explicitly. Low-poly original art, not a claim of professional finish. Per-fighter skinning and floor/scale contract are tested. No animation clips.

## Owner action
None until Checkpoint B.

## Next prompt to execute
12_SHARED_SKELETON_MODULAR_FIGHTERS_AND_SOCKETS.md
