"""Converts Mixamo character FBX to standard 15-bone game-contract fighter GLB.

Reproducible, idempotent conversion with bone mapping, mesh partitioning,
stump caps generation, socket attachments, and SHA-256 manifest output.
"""
import hashlib
import json
import math
import os
from pathlib import Path
import sys

import bpy
import bmesh
from mathutils import Vector, Matrix
from collections import defaultdict

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/blender"))

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


PART_TO_BONE = {
    "ARM_UPPER_L": "upper_arm.l",
    "ARM_LOWER_L": "forearm.l",
    "ARM_END_L": "hand.l",
    "ARM_UPPER_R": "upper_arm.r",
    "ARM_LOWER_R": "forearm.r",
    "ARM_END_R": "hand.r",
    "LEG_UPPER_L": "thigh.l",
    "LEG_LOWER_L": "shin.l",
    "LEG_END_L": "foot.l",
    "LEG_UPPER_R": "thigh.r",
    "LEG_LOWER_R": "shin.r",
    "LEG_END_R": "foot.r",
}


def build_rigged_armature(root, height, width, joints_pos):
    """Builds the standard 15-bone armature matching the exact fighter joints."""
    data = bpy.data.armatures.new("GEN_shared_skeleton")
    data["generated_by"] = "mixamo"
    armature = bpy.data.objects.new("Skeleton", data)
    armature["generated_by"] = "mixamo"
    bpy.context.collection.objects.link(armature)
    armature.parent = root
    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    
    root_pos = joints_pos.get("root", (0, 0, height * 0.45))
    spine_pos = joints_pos.get("spine", (0, 0, height * 0.55))
    neck_pos = joints_pos.get("neck", joints_pos.get("head", (0, 0, height * 0.85)))
    head_pos = joints_pos.get("head", (0, 0, height * 0.88))
    
    # Spine bone runs from root to neck/base-of-head; head bone pivots at neck
    head_pivot = neck_pos
    specs = [
        ("root", None, (0, 0, 0), root_pos),
        ("spine", "root", root_pos, head_pivot),
        ("head", "spine", head_pivot, (head_pivot[0], head_pivot[1], height)),
    ]
    
    for side in ["l", "r"]:
        upper_arm_pos = joints_pos.get(f"upper_arm.{side}", (width * 0.53 * (-1 if side == "l" else 1), 0, height * 0.79))
        forearm_pos = joints_pos.get(f"forearm.{side}", (upper_arm_pos[0] + (-0.2 if side == "l" else 0.2), 0, height * 0.79))
        hand_pos = joints_pos.get(f"hand.{side}", (forearm_pos[0] + (-0.15 if side == "l" else 0.15), 0, height * 0.79))
        hand_end = (hand_pos[0] + (-0.1 if side == "l" else 0.1), hand_pos[1], hand_pos[2])
        
        specs.append((f"upper_arm.{side}", "spine", upper_arm_pos, forearm_pos))
        specs.append((f"forearm.{side}", f"upper_arm.{side}", forearm_pos, hand_pos))
        specs.append((f"hand.{side}", f"forearm.{side}", hand_pos, hand_end))
        
        thigh_pos = joints_pos.get(f"thigh.{side}", (width * 0.23 * (-1 if side == "l" else 1), 0, height * 0.45))
        shin_pos = joints_pos.get(f"shin.{side}", (thigh_pos[0], 0, height * 0.25))
        foot_pos = joints_pos.get(f"foot.{side}", (thigh_pos[0], 0, height * 0.06))
        foot_end = (thigh_pos[0], foot_pos[1] + 0.15, 0.0)
        
        specs.append((f"thigh.{side}", "root", thigh_pos, shin_pos))
        specs.append((f"shin.{side}", f"thigh.{side}", shin_pos, foot_pos))
        specs.append((f"foot.{side}", f"shin.{side}", foot_pos, foot_end))

    for name, parent, start, end in specs:
        bone = data.edit_bones.new(name)
        bone.head = start
        bone.tail = end
        if parent:
            bone.parent = data.edit_bones[parent]
            
    bpy.ops.object.mode_set(mode="OBJECT")
    
    # Bind all mesh parts to Skeleton with rigid weights
    for obj in list(root.children):
        if obj.type != "MESH":
            continue
        name = obj.name
        bone = "head" if name == "HEAD" else "spine"
        if name == "PELVIS":
            bone = "root"
        for limb, names in [("ARM", ["upper_arm", "forearm", "hand"]), ("LEG", ["thigh", "shin", "foot"])]:
            for side in ["L", "R"]:
                for part, joint in zip(["UPPER", "LOWER", "END"], names):
                    if name == f"{limb}_{part}_{side}":
                        bone = joint + "." + side.lower()
                for cap_type in ["CUT_", "BONE_"]:
                    if name == f"{cap_type}{limb}{side}":
                        bone = ("upper_arm." if limb == "ARM" else "thigh.") + side.lower()
        obj["rigid_bone"] = bone
        group = obj.vertex_groups.new(name=bone)
        group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
        modifier = obj.modifiers.new("RigidSkin", "ARMATURE")
        modifier.object = armature
        
    return armature


def convert_character(fbx_name, target_id, target_height_m, target_width_m, out_dir):
    char_dir, _ = get_mixamo_paths()
    fbx_path = char_dir / fbx_name
    if not fbx_path.exists():
        raise FileNotFoundError(f"Character FBX not found: {fbx_path}")
        
    bone_map_path = ROOT / "data/animation/mixamo_bone_map.json"
    bone_map = json.loads(bone_map_path.read_text())["bone_map"]
    
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(fbx_path))
    
    arm_src = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
    meshes = [o for o in bpy.data.objects if o.type == "MESH" and o.name != "Cube"]
    
    # Clear parent and keep exact world transform
    for m in meshes:
        bpy.ops.object.select_all(action="DESELECT")
        m.select_set(True)
        bpy.context.view_layer.objects.active = m
        bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        
    # Accessory clothing/items weight preservation:
    # Cloaks, skirts, or accessory meshes with minor arm weights should not have their arm parts torn off.
    for m in meshes:
        if any(acc in m.name.lower() for acc in ["cloak", "cape", "skirt", "weapon", "belt", "cloth"]):
            for arm_bone in ["mixamorig:LeftArm", "mixamorig:RightArm", "mixamorig:LeftForeArm", "mixamorig:RightForeArm"]:
                if arm_bone in m.vertex_groups:
                    m.vertex_groups.remove(m.vertex_groups[arm_bone])
        
    bpy.context.view_layer.objects.active = meshes[0]
    for m in meshes:
        m.select_set(True)
    if len(meshes) > 1:
        bpy.ops.object.join()
    joined = bpy.context.view_layer.objects.active
    joined.name = "BASE_MESH"
    
    # Record initial boundary vertices to distinguish original seams from newly cut edges
    init_bm = bmesh.new()
    init_bm.from_mesh(joined.data)
    initial_boundary_coords = set(tuple(round(c, 4) for c in v.co) for e in init_bm.edges if e.is_boundary for v in e.verts)
    init_bm.free()
    
    # Calculate scale factor to normalize height to target_height_m and floor at z=0
    min_z = min(v.co.z for v in joined.data.vertices)
    max_z = max(v.co.z for v in joined.data.vertices)
    raw_h = max_z - min_z
    scale_f = target_height_m / raw_h
    
    # Scale and floor vertices in mesh data
    for v in joined.data.vertices:
        v.co.z = (v.co.z - min_z) * scale_f
        v.co.x *= scale_f
        v.co.y *= scale_f
        
    # Sample actual scaled joint positions from Mixamo armature
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
            joints_pos[j_name] = (head_w.x * scale_f, head_w.y * scale_f, (head_w.z - min_z) * scale_f)
            
    # Delete original source armature
    bpy.data.objects.remove(arm_src, do_unlink=True)
    
    # Map vertex groups to standard 15-bone skeleton
    vg_map = {}
    for vg in joined.vertex_groups:
        clean = vg.name.replace("mixamorig:", "")
        tgt = bone_map.get(clean, "spine")
        vg_map[vg.index] = tgt
        
    vert_to_bone = {}
    for v in joined.data.vertices:
        weights = defaultdict(float)
        for g in v.groups:
            if g.group in vg_map:
                weights[vg_map[g.group]] += g.weight
        best_bone = max(weights.items(), key=lambda x: x[1])[0] if weights else "spine"
        vert_to_bone[v.index] = best_bone
        
    # Root container
    root = empty("FIGHTER_" + target_id.upper())
    root["height_m"] = target_height_m
    root["early_test_model"] = False
    
    # Materials for stump caps
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
    
    def process_partition(copy_obj, target_bones, group_name):
        copy_obj.parent = root
        copy_obj.location = (0, 0, 0)
        copy_obj["limb_group"] = group_name
        
        bm = bmesh.new()
        bm.from_mesh(copy_obj.data)
        faces_to_remove = []
        for f in bm.faces:
            pw = defaultdict(int)
            for v in f.verts:
                pw[vert_to_bone[v.index]] += 1
            best = max(pw.items(), key=lambda x: x[1])[0]
            if isinstance(target_bones, list):
                if best not in target_bones:
                    faces_to_remove.append(f)
            else:
                if best != target_bones:
                    faces_to_remove.append(f)
        bmesh.ops.delete(bm, geom=faces_to_remove, context="FACES")
        
        # Cleanly cap only newly created cut loops
        new_cut_edges = [
            e for e in bm.edges
            if e.is_boundary and not (
                tuple(round(c / scale_f + (min_z if i == 2 else 0), 4) for i, c in enumerate(e.verts[0].co)) in initial_boundary_coords
                and tuple(round(c / scale_f + (min_z if i == 2 else 0), 4) for i, c in enumerate(e.verts[1].co)) in initial_boundary_coords
            )
        ]
        if new_cut_edges:
            try:
                bmesh.ops.edgeloop_fill(bm, edges=new_cut_edges)
            except Exception:
                pass
                
        bm.to_mesh(copy_obj.data)
        bm.free()
        
        # Ensure default Color attribute exists for tinting / compatibility
        if "Color" not in copy_obj.data.color_attributes:
            ca = copy_obj.data.color_attributes.new(name="Color", type="FLOAT_COLOR", domain="POINT")
            for c in ca.data:
                c.color = (1.0, 1.0, 1.0, 1.0)
    
    # Partition meshes into the 12 limb parts
    for part_name, target_bone in PART_TO_BONE.items():
        slot_name = part_name.split("_")[0] + "_" + part_name.split("_")[2]
        copy_obj = joined.copy()
        copy_obj.data = joined.data.copy()
        copy_obj.name = part_name
        bpy.context.collection.objects.link(copy_obj)
        process_partition(copy_obj, target_bone, "LIMB_" + slot_name)
        
    # Core parts: HEAD, TORSO, PELVIS
    for core_name, target_bones in [("HEAD", ["head"]), ("TORSO", ["spine"]), ("PELVIS", ["root"])]:
        copy_obj = joined.copy()
        copy_obj.data = joined.data.copy()
        copy_obj.name = core_name
        bpy.context.collection.objects.link(copy_obj)
        process_partition(copy_obj, target_bones, core_name)
        
    # Remove temporary BASE_MESH
    bpy.data.objects.remove(joined, do_unlink=True)
    
    # Build shared 15-bone armature matching exact joint positions and bind all parts
    build_rigged_armature(root, target_height_m, target_width_m, joints_pos)
    
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
        export_all_influences=False,
    )
    
    h = hashlib.sha256(out_glb.read_bytes()).hexdigest()
    print(f"Exported {target_id} -> {out_glb} (SHA-256: {h})")
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
        print(f"--- Converting {cid} ({fbx}) ---")
        glb_path, sha = convert_character(fbx, cid, h, w, out_dir)
        manifest["models"][cid] = {
            "fbx": fbx,
            "path": str(glb_path.relative_to(ROOT)),
            "sha256": sha,
            "height_m": h,
            "width_m": w,
        }
    manifest_path = out_dir / "mixamo_models_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2))
    print(f"Batch conversion finished. Manifest saved to {manifest_path}")
    return manifest


if __name__ == "__main__":
    convert_all()
    print("CONVERSION_COMPLETE")
