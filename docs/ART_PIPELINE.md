# Early model pipeline

Owner requested models/maps at the beginning of stage 07. Run `D:/blender/blender.exe --background --python tools/blender/build_early_art.py`. Four original faceted modular fighters and three arena GLBs go to assets/generated/models. Blender Z is up, front is -Y; glTF imports Y-up with front +Z. Origins are at floor center. Limbs are children of shoulder/hip sockets; caps are hidden by the Godot rig.

Early art is provisional, without the stage 12 armature. Stage 11/12 must replace script constants with validated parameters, add rigid skinning and prove regeneration stability. Models contain no downloaded assets or image textures.

Visual review: first export appeared white because the exporter needed Principled BSDF base colors; fixed with node materials and re-exported. Revised window capture shows scarlet/bronze Theron, green Atalanta, white/gold Olympus. Close combat silhouettes overlap at the current narrow sim body widths; camera readability and stance need later refinement. Owner judgement remains Checkpoint B.

## Validated pipeline (stages 11/12)

Run tools/build_assets.ps1 or tools/build_assets.sh. Source lives in tools/blender/lib (owned-scene reset, primitives, vertex colors/materials, naming, export, manifest, skeleton, stats). Generators only delete tagged owned objects and export owned selection. Sentinel-object test proved unrelated scene content survives and repeated generation stays at 55 objects.

Manifest stores SHA-256 output/source/parameter hashes, Blender version, budgets, triangles and bounds. Pure Python inspector reads GLB chunks and transforms; validation covers orphan files, hashes, colors, sockets, triangle budgets, equal 15-bone hierarchy, height within 1%, floor and socket positions. CHECK_ASSET_REGEN=1 on check_all runs the expensive two-build byte-comparison gate.

Fighters read data/fighters/<id>.json body parameters. Tested a temporary fifth parameter-only fighter in build/data_only_fixture. All four use 15 identically named bones and one rigid weight per vertex. Natural limbs and stump groups have logical metadata because Godot flattens skinned meshes under Skeleton3D. FighterRig explicitly maps rendered part meshes to each group; hiding a logical empty alone is insufficient and regression tests cover actual mesh visibility. Preserve imported bone pose quaternions when adding pose offsets.

Blender Z-up/-Y-front exports to Godot Y-up/+Z-front; render rotation is -facing*0.95 radians for a readable three-quarter view. Feet origin at zero, model actual foot soles about 2cm above origin. Skin meshes are flattened before binding to prevent double socket transforms. Models remain under 5000 triangles including costume. No authored clips.

Workbench preview supports true-scale four-fighter lineup (--roster) and ten-view contact sheet (8 orbit plus front/side). Inspected roster and pipeline sheet: distinct heights, bronze helm/cape, braid/sash, wrestler wreath/buckle, oracle veil/stole. Fixed white materials, overly tall crest, skinned socket double transforms and imported-rest-pose flips. Camera FOV now 50 degrees so models read better in game. Quality remains deliberately simple faceted prototype art; owner acceptance at B.
