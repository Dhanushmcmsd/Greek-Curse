# Early model pipeline

Owner requested models/maps at the beginning of stage 07. Run `D:/blender/blender.exe --background --python tools/blender/build_early_art.py`. Four original faceted modular fighters and three arena GLBs go to assets/generated/models. Blender Z is up, front is -Y; glTF imports Y-up with front +Z. Origins are at floor center. Limbs are children of shoulder/hip sockets; caps are hidden by the Godot rig.

Early art is provisional, without the stage 12 armature. Stage 11/12 must replace script constants with validated parameters, add rigid skinning and prove regeneration stability. Models contain no downloaded assets or image textures.

Visual review: first export appeared white because the exporter needed Principled BSDF base colors; fixed with node materials and re-exported. Revised window capture shows scarlet/bronze Theron, green Atalanta, white/gold Olympus. Close combat silhouettes overlap at the current narrow sim body widths; camera readability and stance need later refinement. Owner judgement remains Checkpoint B.
