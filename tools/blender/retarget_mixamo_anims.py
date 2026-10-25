"""Retargets all 46 Mixamo animation clips to the shared 15-bone game armature.

Strips horizontal root motion (keeps vertical bobbing/grounding), bakes rotations,
and exports standalone .glb animation files to assets/fighters_mixamo/anims/.
"""
import hashlib
import json
import os
from pathlib import Path
import sys

import bpy
from mathutils import Vector, Quaternion, Matrix

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/blender"))
from mixamo_to_fighter import build_rigged_armature, get_mixamo_paths

REVERSE_MAP = {
    "root": "mixamorig:Hips",
    "spine": "mixamorig:Spine",
    "head": "mixamorig:Head",
    "upper_arm.l": "mixamorig:LeftArm",
    "forearm.l": "mixamorig:LeftForeArm",
    "hand.l": "mixamorig:LeftHand",
    "upper_arm.r": "mixamorig:RightArm",
    "forearm.r": "mixamorig:RightForeArm",
    "hand.r": "mixamorig:RightHand",
    "thigh.l": "mixamorig:LeftUpLeg",
    "shin.l": "mixamorig:LeftLeg",
    "foot.l": "mixamorig:LeftFoot",
    "thigh.r": "mixamorig:RightUpLeg",
    "shin.r": "mixamorig:RightLeg",
    "foot.r": "mixamorig:RightFoot",
}


def retarget_clip(fbx_path, out_glb_path, clip_name):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(fbx_path))
    
    src_arms = [o for o in bpy.data.objects if o.type == 'ARMATURE']
    if not src_arms:
        print(f"ERROR: No armature in {fbx_path}")
        return None
    src_arm = src_arms[0]
    src_arm.name = "SRC_Armature"
    
    # Create target 15-bone armature matching source joint layout
    target_root = bpy.data.objects.new("ROOT_TARGET", None)
    bpy.context.collection.objects.link(target_root)
    
    # Sample source joint positions to preserve matching bone lengths and pivots
    joints_pos = {}
    src_map = {
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
    for b_src, j_name in src_map.items():
        if b_src in src_arm.data.bones:
            head_w = src_arm.matrix_world @ src_arm.data.bones[b_src].head_local
            joints_pos[j_name] = (head_w.x, head_w.y, head_w.z)
            
    tgt_arm = build_rigged_armature(target_root, 1.8, 0.45, joints_pos)
    tgt_arm.name = "Skeleton"
    
    # Add constraints
    bpy.context.view_layer.objects.active = tgt_arm
    bpy.ops.object.mode_set(mode='POSE')
    
    for tgt_bone_name, src_bone_name in REVERSE_MAP.items():
        pb = tgt_arm.pose.bones.get(tgt_bone_name)
        if pb and src_bone_name in src_arm.pose.bones:
            con = pb.constraints.new('COPY_ROTATION')
            con.target = src_arm
            con.subtarget = src_bone_name
            con.target_space = 'WORLD'
            con.owner_space = 'WORLD'
            if tgt_bone_name == "root":
                loc_con = pb.constraints.new('COPY_LOCATION')
                loc_con.target = src_arm
                loc_con.subtarget = src_bone_name
                loc_con.target_space = 'WORLD'
                loc_con.owner_space = 'WORLD'
                # Strip horizontal root motion, keep vertical bounce
                loc_con.use_x = False
                loc_con.use_y = False
                loc_con.use_z = True
                
    # Find frame range
    act = bpy.data.actions[0] if bpy.data.actions else None
    fstart = int(act.frame_range[0]) if act else 1
    fend = int(act.frame_range[1]) if act else 30
    
    # Bake animation visually using Blender's NLA bake operator to properly sample constraints
    bpy.context.view_layer.objects.active = tgt_arm
    bpy.ops.object.mode_set(mode='POSE')
    bpy.ops.pose.select_all(action='SELECT')
    
    bpy.ops.nla.bake(
        frame_start=fstart,
        frame_end=fend,
        only_selected=True,
        visual_keying=True,
        clear_constraints=True,
        use_current_action=False,
        bake_types={'POSE'}
    )
    
    if tgt_arm.animation_data and tgt_arm.animation_data.action:
        tgt_arm.animation_data.action.name = clip_name
        
    bpy.ops.object.mode_set(mode='OBJECT')
    
    # Remove source armature and root empty before export
    bpy.data.objects.remove(src_arm, do_unlink=True)
    bpy.data.objects.remove(target_root, do_unlink=True)
    
    # Purge all actions except the newly baked target action
    baked_action = tgt_arm.animation_data.action if tgt_arm.animation_data else None
    for a in list(bpy.data.actions):
        if a != baked_action:
            bpy.data.actions.remove(a)
            
    # Select target armature only
    bpy.ops.object.select_all(action='DESELECT')
    tgt_arm.select_set(True)
    bpy.context.view_layer.objects.active = tgt_arm
    
    out_glb_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(out_glb_path),
        use_selection=True,
        export_format="GLB",
        export_yup=True,
        export_skins=True,
        export_animations=True,
        export_optimize_animation_size=False
    )
    
    h = hashlib.sha256(out_glb_path.read_bytes()).hexdigest()
    print(f"Retargeted: {clip_name} -> {out_glb_path.name} ({fend - fstart + 1} frames, SHA: {h[:12]})")
    return h


def retarget_all():
    _, anim_dir = get_mixamo_paths()
    out_dir = ROOT / "assets/fighters_mixamo/anims"
    out_dir.mkdir(parents=True, exist_ok=True)
    
    insp = json.loads((ROOT / "build/mixamo_inspection.json").read_text())
    anims = insp.get("animations", [])
    
    manifest = {"clips": {}}
    for a in anims:
        rel_fbx = a["file"]
        fbx_path = anim_dir / rel_fbx
        clean_name = Path(rel_fbx).stem.lower().replace(" ", "_").replace("(", "").replace(")", "")
        category = rel_fbx.split("/")[0].replace(" ", "_")
        clip_id = f"{category}_{clean_name}"
        out_glb = out_dir / f"{clip_id}.glb"
        
        sha = retarget_clip(fbx_path, out_glb, clip_id)
        if sha:
            manifest["clips"][clip_id] = {
                "source_file": rel_fbx,
                "output_glb": str(out_glb.relative_to(ROOT)),
                "sha256": sha,
                "frames": int(a["frame_range"][1] - a["frame_range"][0] + 1),
            }
            
    manifest_file = out_dir / "mixamo_anims_manifest.json"
    manifest_file.write_text(json.dumps(manifest, indent=2))
    print(f"Successfully retargeted all {len(manifest['clips'])} clips to {out_dir}")


if __name__ == "__main__":
    retarget_all()
