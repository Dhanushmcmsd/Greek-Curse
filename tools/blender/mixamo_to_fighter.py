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

from lib.skeleton import build_armature
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
    
    # Detach meshes from armature parent and orient upright (Z-up, Y-forward)
    bpy.ops.object.select_all(action="DESELECT")
    for m in meshes:
        m.parent = None
        m.rotation_euler = (1.5707963, 0.0, 0.0)
        m.select_set(True)
        
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    joined = bpy.context.view_layer.objects.active
    joined.name = "BASE_MESH"
    
    # Apply all transforms so vertices are directly in world coordinates
    bpy.ops.object.select_all(action="DESELECT")
    joined.select_set(True)
    bpy.context.view_layer.objects.active = joined
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    
    # Delete original source armature
    bpy.data.objects.remove(arm_src, do_unlink=True)
    
    # Calculate scale factor to normalize height to target_height_m and floor at 0
    min_z = min(v.co.z for v in joined.data.vertices)
    max_z = max(v.co.z for v in joined.data.vertices)
    raw_h = max_z - min_z
    scale_f = target_height_m / raw_h
    
    # Shift vertices to floor at z=0, scaled
    for v in joined.data.vertices:
        v.co.z = (v.co.z - min_z) * scale_f
        v.co.x *= scale_f
        v.co.y *= scale_f
        
    # Map vertex groups
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
    for side, sign in (("L", -1), ("R", 1)):
        for limb in ("ARM", "LEG"):
            slot = limb + "_" + side
            is_arm = limb == "ARM"
            x = sign * target_width_m * (0.53 if is_arm else 0.23)
            z = target_height_m * (0.79 if is_arm else 0.45)
            
            socket = empty("SOCKET_" + slot, (x, 0, z), root)
            sockets[slot] = socket
            group = empty("LIMB_" + slot, parent=socket)
            groups[slot] = group
            stump = empty("STUMP_" + slot, parent=socket)
            stumps[slot] = stump
            
            # Stump cap geometry
            thick = target_width_m * (0.26 if is_arm else 0.30)
            shape("CUT_" + limb + side, (0, 0, -0.015), (thick, thick, 0.035), red, stump, "cylinder")
            shape("BONE_" + limb + side, (0, 0, -0.035), (0.035, 0.035, 0.025), bone_mat, stump, "cylinder")
            
    empty("SOCKET_NECK", (0, 0, target_height_m * 0.85), root)
    
    # Partition meshes into the 12 limb parts
    for part_name, target_bone in PART_TO_BONE.items():
        slot_name = part_name.split("_")[0] + "_" + part_name.split("_")[2]
        copy_obj = joined.copy()
        copy_obj.data = joined.data.copy()
        copy_obj.name = part_name
        bpy.context.collection.objects.link(copy_obj)
        copy_obj.parent = groups[slot_name]
        
        bm = bmesh.new()
        bm.from_mesh(copy_obj.data)
        faces_to_remove = []
        for f in bm.faces:
            pw = defaultdict(int)
            for v in f.verts:
                pw[vert_to_bone[v.index]] += 1
            best = max(pw.items(), key=lambda x: x[1])[0]
            if best != target_bone:
                faces_to_remove.append(f)
        bmesh.ops.delete(bm, geom=faces_to_remove, context="FACES")
        
        # Close cut boundaries
        boundary_edges = [e for e in bm.edges if e.is_boundary]
        try:
            bmesh.ops.edgenet_fill(bm, edges=boundary_edges)
        except Exception:
            pass
            
        bm.to_mesh(copy_obj.data)
        bm.free()
        
    # Core parts: HEAD, TORSO, PELVIS
    for core_name, target_bones in [("HEAD", ["head"]), ("TORSO", ["spine"]), ("PELVIS", ["root"])]:
        copy_obj = joined.copy()
        copy_obj.data = joined.data.copy()
        copy_obj.name = core_name
        bpy.context.collection.objects.link(copy_obj)
        copy_obj.parent = root
        
        bm = bmesh.new()
        bm.from_mesh(copy_obj.data)
        faces_to_remove = []
        for f in bm.faces:
            pw = defaultdict(int)
            for v in f.verts:
                pw[vert_to_bone[v.index]] += 1
            best = max(pw.items(), key=lambda x: x[1])[0]
            if best not in target_bones:
                faces_to_remove.append(f)
        bmesh.ops.delete(bm, geom=faces_to_remove, context="FACES")
        bm.to_mesh(copy_obj.data)
        bm.free()
        
    # Remove temporary BASE_MESH
    bpy.data.objects.remove(joined, do_unlink=True)
    
    # Build shared 15-bone armature and bind all parts
    build_armature(root, target_height_m, target_width_m)
    
    # Export GLB
    out_dir.mkdir(parents=True, exist_ok=True)
    out_glb = out_dir / f"fighter_{target_id}.glb"
    
    # Select root and descendants for export
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


if __name__ == "__main__":
    out_dir = ROOT / "assets/fighters_mixamo"
    convert_character("Arissa.fbx", "atalanta", 1.80, 0.45, out_dir)
    convert_character("Vampire A Lusth.fbx", "vampire_stress", 2.05, 0.50, out_dir)
    print("CONVERSION_COMPLETE")
