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
    
    # Create target 15-bone armature
    target_root = bpy.data.objects.new("ROOT_TARGET", None)
    bpy.context.collection.objects.link(target_root)
    tgt_arm = build_rigged_armature(target_root, 1.8, 0.45, {})
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
    
    # Create target action
    tgt_act = bpy.data.actions.new(name=clip_name)
    if tgt_arm.animation_data is None:
        tgt_arm.animation_data_create()
    tgt_arm.animation_data.action = tgt_act
    
    scene = bpy.context.scene
    for f in range(fstart, fend + 1):
        scene.frame_set(f)
        for b in tgt_arm.pose.bones:
            b.keyframe_insert(data_path="rotation_quaternion", frame=f)
            if b.name == "root":
                b.keyframe_insert(data_path="location", frame=f)
                
    # Remove constraints
    for b in tgt_arm.pose.bones:
        for c in list(b.constraints):
            b.constraints.remove(c)
            
    bpy.ops.object.mode_set(mode='OBJECT')
    
    # Remove source armature and root empty before export
    bpy.data.objects.remove(src_arm, do_unlink=True)
    bpy.data.objects.remove(target_root, do_unlink=True)
    
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
        export_animations=True
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
