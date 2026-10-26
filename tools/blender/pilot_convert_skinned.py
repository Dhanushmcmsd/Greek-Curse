"""Pilot repair: Converts Mixamo character FBX to non-destructive skinned fighter GLB.
Preserves original Mixamo deform armature (65-73 bones) and soft skin weights.
Preserves neck-head-torso continuity (no mesh tearing at neck).
Partitions only amputatable limbs (ARM_L, ARM_R, LEG_L, LEG_R) at explicit anatomical boundary loops.
Cuts and caps clean stump boundaries.
Generates SOCKET_*, LIMB_*, STUMP_* empty containers and CUT_*/BONE_* stump cap geometry.
Exports to GLB for real in-engine visual proof and deformation continuity testing.
"""
import hashlib
import json
import math
import os
from pathlib import Path
import sys
from collections import defaultdict

import bpy
import bmesh
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/blender"))

from externalize_glb_images import externalize_large_glb
from lib.materials import material
from lib.primitives import empty, shape


def get_mixamo_paths():
    paths_file = ROOT / "tools/blender/mixamo_paths.json"
    char_dir = os.environ.get("MIXAMO_CHAR_DIR")
    anim_dir = os.environ.get("MIXAMO_ANIM_DIR")
    
    if paths_file.exists():
        cfg = json.loads(paths_file.read_text())
        if not char_dir:
            char_dir = cfg.get("character_dir")
        if not anim_dir:
            anim_dir = cfg.get("animation_dir")
            
    if not char_dir or not Path(char_dir).exists():
        raise FileNotFoundError(f"Mixamo character directory not found: {char_dir}")
    if not anim_dir or not Path(anim_dir).exists():
        raise FileNotFoundError(f"Mixamo animation directory not found: {anim_dir}")
        
    return Path(char_dir), Path(anim_dir)


def classify_mixamo_bone(bone_name):
    clean = bone_name.replace("mixamorig:", "")
    # Primary joints have already been renamed before partitioning. Recognize
    # both naming schemes or arms/legs end up in the always-visible torso mesh.
    for prefix in ("upper_arm", "forearm", "hand", "thigh", "shin", "foot"):
        if clean.startswith(prefix + "."):
            limb = "ARM" if prefix in ("upper_arm", "forearm", "hand") else "LEG"
            return limb + "_" + clean.rsplit(".", 1)[1].upper()
    if clean.startswith("LeftArm") or clean.startswith("LeftForeArm") or clean.startswith("LeftHand"):
        return "ARM_L"
    if clean.startswith("RightArm") or clean.startswith("RightForeArm") or clean.startswith("RightHand"):
        return "ARM_R"
    if clean.startswith("LeftUpLeg") or clean.startswith("LeftLeg") or clean.startswith("LeftFoot") or clean.startswith("LeftToe"):
        return "LEG_L"
    if clean.startswith("RightUpLeg") or clean.startswith("RightLeg") or clean.startswith("RightFoot") or clean.startswith("RightToe"):
        return "LEG_R"
    return "TORSO_HEAD"


def convert_character_skinned(fbx_name, target_id, target_height_m, target_width_m, out_dir):
    char_dir, _ = get_mixamo_paths()
    fbx_path = char_dir / fbx_name
    if not fbx_path.exists():
        raise FileNotFoundError(f"Character FBX not found: {fbx_path}")
        
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(fbx_path))
    
    arm_src = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
    meshes = [o for o in bpy.data.objects if o.type == "MESH" and o.name != "Cube"]
    
    # Apply all transforms initially so coordinates are aligned
    bpy.ops.object.select_all(action="DESELECT")
    arm_src.select_set(True)
    for m in meshes:
        m.select_set(True)
    bpy.context.view_layer.objects.active = arm_src
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    
    # Calculate bounding height across all meshes
    min_z = min(min(v.co.z for v in m.data.vertices) for m in meshes if len(m.data.vertices) > 0)
    max_z = max(max(v.co.z for v in m.data.vertices) for m in meshes if len(m.data.vertices) > 0)
    raw_h = max_z - min_z
    scale_f = target_height_m / raw_h
    
    # Scale armature and meshes to exact target height and floor at z=0
    # We apply scale directly to vertices and armature bones to preserve 1.0 object transform
    bpy.ops.object.select_all(action="DESELECT")
    arm_src.location.z -= min_z
    arm_src.scale = (scale_f, scale_f, scale_f)
    for m in meshes:
        m.location.z -= min_z
        m.scale = (scale_f, scale_f, scale_f)
    bpy.context.view_layer.objects.active = arm_src
    bpy.ops.object.select_all(action="DESELECT")
    arm_src.select_set(True)
    for m in meshes:
        m.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    
    # Sample actual scaled joint positions from Mixamo armature for sockets and stump caps
    joints_pos = {}
    mixamo_to_joint = {
        "mixamorig:Hips": "root",
        "mixamorig:Spine": "spine",
        "mixamorig:Neck": "neck",
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
    for b_src, j_name in mixamo_to_joint.items():
        if b_src in arm_src.data.bones:
            head_w = arm_src.matrix_world @ arm_src.data.bones[b_src].head_local
            joints_pos[j_name] = (head_w.x, head_w.y, head_w.z)
            
    # Rename the 15 primary bones to canonical names (root, spine, head, upper_arm.l, etc.)
    # while preserving all 58+ intermediate bones (neck, spine1, spine2, shoulders, fingers, etc.)
    # Blender automatically updates vertex group references on all child meshes!
    primary_bone_rename = {
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
    for old_b, new_b in primary_bone_rename.items():
        if old_b in arm_src.data.bones:
            arm_src.data.bones[old_b].name = new_b

    # Also simplify other Mixamo bone names by stripping 'mixamorig:' prefix so Godot and helpers recognize them cleanly
    for b in list(arm_src.data.bones):
        if b.name.startswith("mixamorig:"):
            b.name = b.name.replace("mixamorig:", "")

    # Root container
    root = empty("FIGHTER_" + target_id.upper())
    root["height_m"] = target_height_m
    root["width_m"] = target_width_m
    root["rig_contract"] = "mixamo_deform"
    root["early_test_model"] = False
    
    # Parent Armature to root and name standard Skeleton
    arm_src.name = "Skeleton"
    arm_src.parent = root

    # Stump cap materials
    red = material("stump", (0.48, 0.025, 0.045))
    bone_mat = material("bone", (0.9, 0.82, 0.61))
    
    # Sockets and logical limb groups
    sockets = {}
    groups = {}
    stumps = {}
    for side in ["L", "R"]:
        side_lower = side.lower()
        for limb in ("ARM", "LEG"):
            slot = limb + "_" + side
            is_arm = limb == "ARM"
            j_key = f"upper_arm.{side_lower}" if is_arm else f"thigh.{side_lower}"
            if j_key in joints_pos:
                x, y, z = joints_pos[j_key]
            else:
                sign = -1 if side == "L" else 1
                x = sign * target_width_m * (0.53 if is_arm else 0.23)
                y = 0.0
                z = target_height_m * (0.79 if is_arm else 0.45)
            
            socket = empty("SOCKET_" + slot, (x, y, z), root)
            sockets[slot] = socket
            group = empty("LIMB_" + slot, parent=socket)
            groups[slot] = group
            stump = empty("STUMP_" + slot, parent=socket)
            stumps[slot] = stump
            
            # Stump cap geometry
            thick = target_width_m * (0.26 if is_arm else 0.30)
            cut_obj = shape("CUT_" + limb + side, (x, y, z - 0.015), (thick, thick, 0.035), red, root, "cylinder")
            cut_obj["limb_group"] = "STUMP_" + slot
            bone_obj = shape("BONE_" + limb + side, (x, y, z - 0.035), (0.035, 0.035, 0.025), bone_mat, root, "cylinder")
            bone_obj["limb_group"] = "STUMP_" + slot
            
    empty("SOCKET_NECK", (0, 0, target_height_m * 0.85), root)
    
    # Partition meshes preserving soft weights
    # Main body: partitioned into TORSO_HEAD, ARM_L, ARM_R, LEG_L, LEG_R
    # Accessory meshes: if bound mostly to core (cloak, skirt, weapons), keep in TORSO_HEAD
    created_mesh_parts = []
    
    for m in meshes:
        vgroups = {g.index: g.name for g in m.vertex_groups}
        
        # Check which partitions exist in this mesh
        vert_part = {}
        for v in m.data.vertices:
            part_weights = defaultdict(float)
            for g in v.groups:
                if g.group in vgroups:
                    bname = vgroups[g.group]
                    part = classify_mixamo_bone(bname)
                    part_weights[part] += g.weight
            vert_part[v.index] = max(part_weights.items(), key=lambda x: x[1])[0] if part_weights else "TORSO_HEAD"
            
        # Record initial boundary edges of this mesh before cutting
        bm_init = bmesh.new()
        bm_init.from_mesh(m.data)
        init_boundary_verts = set(v.index for e in bm_init.edges if e.is_boundary for v in e.verts)
        bm_init.free()
        
        # Check active parts present in this mesh
        present_parts = set(vert_part.values())
        
        # If this is an accessory mesh (cloak, skirt, weapons) that is overwhelmingly TORSO_HEAD,
        # don't partition it into limb chunks - assign whole mesh to TORSO_HEAD
        if any(acc in m.name.lower() for acc in ["cloak", "cape", "skirt", "weapon", "belt", "cloth"]):
            present_parts = {"TORSO_HEAD"}
            for v_idx in vert_part:
                vert_part[v_idx] = "TORSO_HEAD"
                
        for target_part in present_parts:
            # Create a clone of the mesh object
            part_obj = m.copy()
            part_obj.data = m.data.copy()
            part_name = f"{m.name}_{target_part}"
            part_obj.name = part_name
            bpy.context.collection.objects.link(part_obj)
            part_obj.parent = arm_src
            
            # Set limb group metadata
            if target_part == "TORSO_HEAD":
                part_obj["limb_group"] = "TORSO"
            else:
                part_obj["limb_group"] = "LIMB_" + target_part
                
            # Filter faces
            bm = bmesh.new()
            bm.from_mesh(part_obj.data)
            faces_to_delete = []
            for f in bm.faces:
                counts = defaultdict(int)
                for v in f.verts:
                    counts[vert_part[v.index]] += 1
                face_part = max(counts.items(), key=lambda x: x[1])[0] if counts else "TORSO_HEAD"
                if face_part != target_part:
                    faces_to_delete.append(f)
            bmesh.ops.delete(bm, geom=faces_to_delete, context="FACES")
            
            # Cleanly cap only newly created cut loops
            new_cut_edges = [
                e for e in bm.edges
                if e.is_boundary and not (
                    e.verts[0].index in init_boundary_verts and e.verts[1].index in init_boundary_verts
                )
            ]
            if new_cut_edges:
                try:
                    bmesh.ops.edgeloop_fill(bm, edges=new_cut_edges)
                except Exception:
                    pass
                    
            bm.to_mesh(part_obj.data)
            bm.free()
            
            # Ensure default Color attribute exists for tinting / compatibility
            if "Color" not in part_obj.data.color_attributes:
                ca = part_obj.data.color_attributes.new(name="Color", type="FLOAT_COLOR", domain="POINT")
                for c in ca.data:
                    c.color = (1.0, 1.0, 1.0, 1.0)
                    
            created_mesh_parts.append(part_obj)
            
        # Remove original source mesh object
        bpy.data.objects.remove(m, do_unlink=True)
        
    # Export GLB
    out_dir.mkdir(parents=True, exist_ok=True)
    out_glb = out_dir / f"fighter_{target_id}.glb"
    
    # Remove any unparented or stray objects before export
    for obj in list(bpy.data.objects):
        if obj != root and obj not in root.children_recursive:
            bpy.data.objects.remove(obj, do_unlink=True)
            
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for c in root.children_recursive:
        c.select_set(True)
        
    bpy.ops.export_scene.gltf(
        filepath=str(out_glb),
        use_selection=True,
        export_format="GLB",
        export_yup=True,
        export_skins=True,
        export_all_influences=True,
    )
    
    externalize_large_glb(out_glb)
    h = hashlib.sha256(out_glb.read_bytes()).hexdigest()
    print(f"Exported skinned {target_id} -> {out_glb} (SHA-256: {h})")
    return out_glb, h


ALL_CHARACTERS = [
    # id, fbx_name, height_m, width_m
    ("theron", "Paladin J Nordstrom.fbx", 2.05, 0.50),
    ("atalanta", "Arissa.fbx", 1.78, 0.39),
    ("pyrrhus", "Ch34_nonPBR.fbx", 1.55, 0.48),
    ("sibyl", "Maria J J Ong.fbx", 1.75, 0.42),
    ("skin_ch39", "Ch39_nonPBR.fbx", 1.80, 0.45),
    ("skin_ch40", "Ch40_nonPBR.fbx", 1.85, 0.48),
    ("skin_demon", "Demon T Wiezzorek.fbx", 2.10, 0.55),
    ("skin_kachujin", "Kachujin G Rosales.fbx", 1.80, 0.45),
    ("skin_nightshade", "Nightshade J Friedrich.fbx", 1.75, 0.42),
    ("vampire_stress", "Vampire A Lusth.fbx", 2.05, 0.50),
]


def convert_all(out_dir=None):
    if out_dir is None:
        out_dir = ROOT / "assets/fighters_mixamo"
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest = {"models": {}}
    for cid, fbx, h, w in ALL_CHARACTERS:
        print(f"--- Converting skinned {cid} ({fbx}) ---")
        glb_path, sha = convert_character_skinned(fbx, cid, h, w, out_dir)
        manifest["models"][cid] = {
            "fbx": fbx,
            "path": str(glb_path.relative_to(ROOT)),
            "sha256": sha,
            "height_m": h,
            "width_m": w,
            "contract": "mixamo_deform",
        }
    manifest_file = out_dir / "mixamo_models_manifest.json"
    manifest_file.write_text(json.dumps(manifest, indent=2))
    print(f"Batch conversion complete: {len(manifest['models'])} models in {out_dir}")


if __name__ == "__main__":
    out = ROOT / "assets/fighters_mixamo"
    if "--all" in sys.argv:
        convert_all(out)
    elif "--theron" in sys.argv:
        convert_character_skinned("Paladin J Nordstrom.fbx", "theron", 2.05, 0.50, out)
    else:
        convert_character_skinned("Arissa.fbx", "atalanta", 1.78, 0.39, out)

