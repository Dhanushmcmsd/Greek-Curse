"""Builds non-destructive converted GLB replacement limb assets from supplied elemental limbs.
Reads:
  - Source models from d:\\Elemental_Limbs_10_Characters\\Elemental_Limbs
  - Character scales and offsets from build/character_scales.json
Outputs:
  - Processed skinned limb assets under assets/limbs_elemental/
  - Generates both Right (_R) and mirrored Left (_L) articulated skinned models.
  - Manifest at assets/limbs_elemental/limbs_manifest.json
"""
import hashlib
import json
import os
from pathlib import Path
import sys

import bpy

ROOT = Path(__file__).resolve().parents[2]

PRIMARY_BONE_RENAME = {
    "mixamorig:Hips": "root",
    "mixamorig:Spine": "spine",
    "mixamorig:Head": "head",
    "mixamorig:LeftArm": "upper_arm.l",
    "mixamorig:LeftForeArm": "forearm.l",
    "mixamorig:LeftHand": "hand.l",
    "mixamorig:RightArm": "upper_arm.r",
    "mixamorig:RightForeArm": "forearm.r",
    "mixamorig:RightHand": "hand.r",
    "mixamorig:LeftUpLeg": "thigh.l",
    "mixamorig:LeftLeg": "shin.l",
    "mixamorig:LeftFoot": "foot.l",
    "mixamorig:RightUpLeg": "thigh.r",
    "mixamorig:RightLeg": "shin.r",
    "mixamorig:RightFoot": "foot.r",
}

R_TO_L_BONE_MAP = {
    "upper_arm.r": "upper_arm.l",
    "forearm.r": "forearm.l",
    "hand.r": "hand.l",
    "RightShoulder": "LeftShoulder",
    "thigh.r": "thigh.l",
    "shin.r": "shin.l",
    "foot.r": "foot.l",
    "RightToeBase": "LeftToeBase",
    "RightToe_End": "LeftToe_End",
}

CHAR_TO_MODEL = {
    "Arissa": "atalanta",
    "Paladin": "theron",
    "Ch34": "pyrrhus",
    "Maria": "sibyl",
    "Ch39": "skin_ch39",
    "Ch40": "skin_ch40",
    "Demon": "skin_demon",
    "Kachujin": "skin_kachujin",
    "Nightshade": "skin_nightshade",
    "Vampire": "vampire_stress",
}


def get_paths():
    paths_file = ROOT / "tools/blender/mixamo_paths.json"
    cfg = json.loads(paths_file.read_text())
    limbs_dir = Path(cfg["elemental_limbs_dir"])
    scales_file = ROOT / "build/character_scales.json"
    scales = json.loads(scales_file.read_text())
    return limbs_dir, scales


def build_elemental_limbs(only_chars=None):
    limbs_dir, scales = get_paths()
    out_dir = ROOT / "assets/limbs_elemental"
    out_dir.mkdir(parents=True, exist_ok=True)

    manifest_entries = {}

    target_chars = [c for c in sorted(limbs_dir.iterdir()) if c.is_dir() and (c / "asset_manifest.json").exists()]
    if only_chars:
        target_chars = [c for c in target_chars if c.name in only_chars]

    for char_dir in target_chars:
        char_name = char_dir.name
        model_id = CHAR_TO_MODEL[char_name]
        scale_info = scales[model_id]
        min_z = scale_info["min_z"]
        scale_f = scale_info["scale_f"]
        char_manifest = json.loads((char_dir / "asset_manifest.json").read_text())
        theme = char_manifest.get("theme", "")

        fighter_glb_path = ROOT / f"assets/fighters_mixamo/fighter_{model_id}.glb"
        if not fighter_glb_path.exists():
            print(f"Skipping {char_name}: fighter GLB not found at {fighter_glb_path}")
            continue

        for limb_type in ["arm", "leg"]:
            # Process Right side (_r)
            for side in ["r", "l"]:
                bpy.ops.wm.read_factory_settings(use_empty=True)

                # 1. Load fighter armature as canonical skeleton
                bpy.ops.import_scene.gltf(filepath=str(fighter_glb_path))
                fighter_skel = bpy.data.objects["Skeleton"]

                # 2. Load supplied elemental limb GLB
                src_limb_glb = char_dir / f"{char_name}_{limb_type}_R.glb"
                if not src_limb_glb.exists():
                    print(f"Warning: {src_limb_glb} missing!")
                    continue

                bpy.ops.import_scene.gltf(filepath=str(src_limb_glb))
                elem_mesh = bpy.data.objects[f"{char_name}_{limb_type}_R"]
                elem_skel = [o for o in bpy.data.objects if o.type == "ARMATURE" and o != fighter_skel][0]

                # Align to world and detach from temp armature
                elem_mesh.matrix_world = elem_skel.matrix_world @ elem_mesh.matrix_local
                bpy.ops.object.select_all(action="DESELECT")
                elem_mesh.select_set(True)
                bpy.context.view_layer.objects.active = elem_mesh
                bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
                bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

                # Apply character normalization offset and height scale
                elem_mesh.location.z -= min_z
                elem_mesh.scale = (scale_f, scale_f, scale_f)
                bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

                # If left side, mirror geometry across sagittal plane (X -> -X)
                if side == "l":
                    elem_mesh.scale.x = -1.0
                    bpy.ops.object.transform_apply(scale=True)
                    bpy.ops.object.mode_set(mode="EDIT")
                    bpy.ops.mesh.select_all(action="SELECT")
                    bpy.ops.mesh.flip_normals()
                    bpy.ops.object.mode_set(mode="OBJECT")

                # Remap vertex groups
                target_vg_map = {}
                for vg in list(elem_mesh.vertex_groups):
                    orig_name = vg.name
                    # First map mixamo names to canonical
                    canon_name = PRIMARY_BONE_RENAME.get(orig_name, orig_name.replace("mixamorig:", ""))
                    if side == "l":
                        if canon_name in R_TO_L_BONE_MAP:
                            canon_name = R_TO_L_BONE_MAP[canon_name]
                        elif canon_name.startswith("RightHand"):
                            canon_name = canon_name.replace("RightHand", "LeftHand")
                    target_vg_map[vg] = canon_name

                # Apply renames
                for vg, new_name in target_vg_map.items():
                    vg.name = new_name

                # Bind Armature modifier to fighter skeleton
                for mod in elem_mesh.modifiers:
                    if mod.type == "ARMATURE":
                        mod.object = fighter_skel

                elem_mesh.parent = fighter_skel

                # Clean up all objects except elem_mesh and fighter_skel
                for o in list(bpy.data.objects):
                    if o != elem_mesh and o != fighter_skel:
                        bpy.data.objects.remove(o, do_unlink=True)

                # Name mesh node
                asset_id = f"elemental_{model_id}_{limb_type}_{side}"
                elem_mesh.name = asset_id

                out_file = out_dir / f"{asset_id}.glb"
                bpy.ops.export_scene.gltf(
                    filepath=str(out_file),
                    export_format="GLB",
                    export_yup=True,
                    export_skins=True,
                    export_all_influences=True,
                )

                sha = hashlib.sha256(out_file.read_bytes()).hexdigest()
                manifest_entries[asset_id] = {
                    "source_char": char_name,
                    "model_id": model_id,
                    "theme": theme,
                    "limb_type": limb_type,
                    "side": side,
                    "slot": f"{limb_type}_{side}",
                    "file": out_file.name,
                    "sha256": sha,
                    "verts": len(elem_mesh.data.vertices),
                    "tris": len(elem_mesh.data.polygons),
                }
                print(f"Exported {asset_id} -> {out_file.name} (SHA: {sha[:12]})")

    manifest_path = out_dir / "limbs_manifest.json"
    manifest_path.write_text(json.dumps(manifest_entries, indent=2))
    print(f"Wrote elemental limbs manifest: {manifest_path}")


if __name__ == "__main__":
    only = None
    if "--only" in sys.argv:
        idx = sys.argv.index("--only")
        only = sys.argv[idx + 1].split(",")
    build_elemental_limbs(only)
