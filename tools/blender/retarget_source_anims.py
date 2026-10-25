"""Core retargeting module for retained source character armatures."""
import hashlib
import json
import os
from pathlib import Path
import sys

import bpy
from mathutils import Vector, Quaternion, Matrix

ROOT = Path(__file__).resolve().parents[2]

def retarget_action_to_character(
    char_fbx_path: Path,
    anim_fbx_path: Path,
    action_name: str,
    out_glb_path: Path,
    target_height_m: float = 1.78,
    zero_horizontal_root: bool = True
) -> dict:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    
    # 1. Import Character FBX
    bpy.ops.import_scene.fbx(filepath=str(char_fbx_path))
    char_arms = [o for o in bpy.data.objects if o.type == 'ARMATURE']
    if not char_arms:
        raise RuntimeError(f"No armature found in {char_fbx_path}")
    char_arm = char_arms[0]
    char_arm.name = "Skeleton"
    
    # Clear any static actions introduced by the character FBX
    if char_arm.animation_data:
        char_arm.animation_data_clear()
    for a in list(bpy.data.actions):
        bpy.data.actions.remove(a)
    
    # 2. Import Animation FBX
    bpy.ops.import_scene.fbx(filepath=str(anim_fbx_path))
    anim_arms = [o for o in bpy.data.objects if o.type == 'ARMATURE' and o != char_arm]
    if not anim_arms:
        raise RuntimeError(f"No armature found in {anim_fbx_path}")
    anim_arm = anim_arms[0]
    anim_arm.name = "AnimSource"
    
    # The newly imported animation action is now in anim_arm.animation_data.action or in bpy.data.actions
    src_action = anim_arm.animation_data.action if anim_arm.animation_data else None
    if src_action is None and bpy.data.actions:
        src_action = bpy.data.actions[0]
    if src_action is None:
        raise RuntimeError(f"No action found in {anim_fbx_path}")
        
    fr = src_action.curve_frame_range
    fstart = int(fr[0])
    fend = int(fr[1])
    
    # 3. Setup World-space constraints on Character pose bones
    bpy.context.view_layer.objects.active = char_arm
    bpy.ops.object.mode_set(mode='POSE')
    
    mapped_bones = []
    for pb in char_arm.pose.bones:
        if pb.name in anim_arm.pose.bones:
            c = pb.constraints.new('COPY_ROTATION')
            c.target = anim_arm
            c.subtarget = pb.name
            c.target_space = 'WORLD'
            c.owner_space = 'WORLD'
            mapped_bones.append(pb.name)
            
    root_bone_name = "mixamorig:Hips" if "mixamorig:Hips" in char_arm.pose.bones else "Hips"
    if root_bone_name in char_arm.pose.bones:
        c_loc = char_arm.pose.bones[root_bone_name].constraints.new('COPY_LOCATION')
        c_loc.target = anim_arm
        c_loc.subtarget = root_bone_name
        c_loc.target_space = 'WORLD'
        c_loc.owner_space = 'WORLD'
        if zero_horizontal_root:
            c_loc.use_x = False
            c_loc.use_y = False
            c_loc.use_z = True
        else:
            c_loc.use_x = True
            c_loc.use_y = True
            c_loc.use_z = True
            
    # 4. Bake Pose Action visually across full frame range
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
    
    baked_action = char_arm.animation_data.action
    baked_action.name = action_name
    
    bpy.ops.object.mode_set(mode='OBJECT')
    
    # 5. Clean up anim armature and mesh geometry so export contains only the animated skeleton
    bpy.data.objects.remove(anim_arm, do_unlink=True)
    for m in [o for o in bpy.data.objects if o.type == 'MESH']:
        bpy.data.objects.remove(m, do_unlink=True)
        
    for a in list(bpy.data.actions):
        if a != baked_action:
            bpy.data.actions.remove(a)
            
    # 6. Export to GLB
    out_glb_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    char_arm.select_set(True)
    bpy.context.view_layer.objects.active = char_arm
    
    bpy.ops.export_scene.gltf(
        filepath=str(out_glb_path),
        use_selection=True,
        export_format='GLB',
        export_yup=True,
        export_skins=True,
        export_all_influences=True,
        export_animations=True,
    )
    
    sha256 = hashlib.sha256(out_glb_path.read_bytes()).hexdigest()
    
    return {
        "action_name": action_name,
        "source_clip": str(anim_fbx_path.name),
        "frame_range": [fstart, fend],
        "duration_sec": (fend - fstart) / 30.0,
        "mapped_bones_count": len(mapped_bones),
        "total_char_bones": len(char_arm.data.bones),
        "out_glb": str(out_glb_path.relative_to(ROOT)),
        "sha256": sha256
    }
