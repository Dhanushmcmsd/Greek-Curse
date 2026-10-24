import bpy
import json
import math
from pathlib import Path
from mathutils import Quaternion, Vector, Matrix

ROOT = Path(__file__).resolve().parents[2]
import sys
sys.path.insert(0, str(ROOT / "tools/blender"))
from mixamo_to_fighter import build_rigged_armature, get_mixamo_paths

# Load bone map
bone_map_cfg = json.loads((ROOT / "data/animation/mixamo_bone_map.json").read_text())
BONE_MAP = bone_map_cfg["bone_map"]

TARGET_BONES = [
    "root", "spine", "head",
    "upper_arm.l", "forearm.l", "hand.l",
    "upper_arm.r", "forearm.r", "hand.r",
    "thigh.l", "shin.l", "foot.l",
    "thigh.r", "shin.r", "foot.r"
]

def test_retarget(clip_rel_path):
    _, anim_dir = get_mixamo_paths()
    fbx_file = anim_dir / clip_rel_path
    
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(fbx_file))
    
    src_arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
    src_arm.name = "SRC_Armature"
    
    # Create target 15-bone armature
    target_root = bpy.data.objects.new("ROOT_TARGET", None)
    bpy.context.collection.objects.link(target_root)
    tgt_arm = build_rigged_armature(target_root, 1.8, 0.45, {})
    tgt_arm.name = "TGT_Skeleton"
    
    # Constrain each target bone to corresponding source Mixamo bone
    bpy.context.view_layer.objects.active = tgt_arm
    bpy.ops.object.mode_set(mode='POSE')
    
    # Find matching source bone for each target bone
    reverse_map = {
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
    
    for tgt_bone_name, src_bone_name in reverse_map.items():
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
                # Strip horizontal root motion, keep vertical bounce/grounding
                loc_con.use_x = False
                loc_con.use_y = False
                loc_con.use_z = True
                
    bpy.ops.object.mode_set(mode='OBJECT')
    
    bpy.ops.object.mode_set(mode='POSE')
        
    scene = bpy.context.scene
    act = bpy.data.actions[0] if bpy.data.actions else None
    fstart = int(act.frame_range[0]) if act else 1
    fend = int(act.frame_range[1]) if act else 30
    
    # Create action for target skeleton
    tgt_act = bpy.data.actions.new(name="Action_Retarget")
    if tgt_arm.animation_data is None:
        tgt_arm.animation_data_create()
    tgt_arm.animation_data.action = tgt_act
    
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
    
    print(f"Bake complete for {clip_rel_path}: {fstart}..{fend}")
    out_glb = ROOT / "test_retarget_jab.glb"
    bpy.ops.export_scene.gltf(
        filepath=str(out_glb),
        use_selection=True,
        export_format="GLB",
        export_yup=True,
        export_skins=True,
        export_animations=True
    )
    print("Exported GLB:", out_glb, "bytes:", out_glb.stat().st_size)

test_retarget("punch/Lead Jab.fbx")
