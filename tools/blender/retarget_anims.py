"""Reproducible retargeting pipeline: Quaternius animations -> Severed 15-bone shared rig.

Strips horizontal root motion, preserves vertical bob/physics, and exports
per-fighter anim GLBs to assets/fighters/<id>/anims/anims.glb.
"""
import json
from pathlib import Path
import sys

import bpy
from mathutils import Matrix, Quaternion, Vector

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/blender"))

from lib.skeleton import build_armature

BONE_MAP = {
    "root": "pelvis",
    "spine": "spine_02",
    "head": "Head",
    "upper_arm.l": "upperarm_l",
    "forearm.l": "lowerarm_l",
    "hand.l": "hand_l",
    "upper_arm.r": "upperarm_r",
    "forearm.r": "lowerarm_r",
    "hand.r": "hand_r",
    "thigh.l": "thigh_l",
    "shin.l": "calf_l",
    "foot.l": "foot_l",
    "thigh.r": "thigh_r",
    "shin.r": "calf_r",
    "foot.r": "foot_r",
}


def load_source_libraries():
    """Loads UAL1 and UAL2 actions into Blender memory."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    ual_paths = [
        ROOT / "d_scratch/UAL1_Standard.glb" if (ROOT / "d_scratch/UAL1_Standard.glb").exists()
        else Path(r"D:\godot_scratch_anim\UAL1_Standard.glb"),
        ROOT / "d_scratch/UAL2_Standard.glb" if (ROOT / "d_scratch/UAL2_Standard.glb").exists()
        else Path(r"D:\godot_scratch_anim\UAL2_Standard.glb"),
    ]
    
    actions = {}
    for path in ual_paths:
        if not path.exists():
            print(f"Warning: path {path} not found")
            continue
        bpy.ops.import_scene.gltf(filepath=str(path))
        for act in bpy.data.actions:
            clean_name = act.name.replace("_Loop", "").replace("UAL1_", "").replace("UAL2_", "")
            actions[act.name] = act
            actions[clean_name] = act

    return actions


def retarget_fighter(fighter_id, actions_dict, pack_map):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    
    fighter_cfg_path = ROOT / f"data/fighters/{fighter_id}.json"
    with open(fighter_cfg_path, "r", encoding="utf-8") as f:
        fighter_cfg = json.load(f)
        
    height = fighter_cfg["height_mm"] / 1000.0
    width = float(fighter_cfg["body"]["shoulder_width"])
    
    # Create empty root node matching fighter model hierarchy
    root_obj = bpy.data.objects.new(f"FIGHTER_{fighter_id.upper()}", None)
    bpy.context.collection.objects.link(root_obj)
    
    # Create shared skeleton
    armature_obj = build_armature(root_obj, height, width)
    bpy.context.view_layer.objects.active = armature_obj
    armature_obj.select_set(True)
    
    # Load source UAL models to sample transforms
    ual1_path = Path(r"D:\godot_scratch_anim\UAL1_Standard.glb")
    bpy.ops.import_scene.gltf(filepath=str(ual1_path))
    source_armature = None
    for obj in bpy.context.scene.objects:
        if obj.type == "ARMATURE" and obj != armature_obj:
            source_armature = obj
            break
            
    ual2_path = Path(r"D:\godot_scratch_anim\UAL2_Standard.glb")
    if ual2_path.exists():
        bpy.ops.import_scene.gltf(filepath=str(ual2_path))
        
    fighter_actions = pack_map["fighters"][fighter_id]["actions"]
    lean = pack_map["fighters"][fighter_id].get("lean_offset_degrees", {})
    
    target_actions = []
    
    for action_key, action_info in fighter_actions.items():
        clip_name = action_info["clip"]
        src_action = None
        for name, act in bpy.data.actions.items():
            if name == clip_name or name == f"{clip_name}_Loop" or name.startswith(clip_name):
                src_action = act
                break
                
        if not src_action:
            print(f"Warning: source action {clip_name} not found for {fighter_id} {action_key}")
            continue
            
        target_act_name = f"{fighter_id}_{action_key}"
        target_act = bpy.data.actions.new(name=target_act_name)
        target_act.use_fake_user = True
        
        # Animate bones across frames
        source_armature.animation_data_create()
        source_armature.animation_data.action = src_action
        
        armature_obj.animation_data_create()
        armature_obj.animation_data.action = target_act
        
        start_frame = int(src_action.frame_range[0])
        end_frame = int(src_action.frame_range[1])
        
        bpy.ops.object.mode_set(mode="POSE")
        
        for frame in range(start_frame, end_frame + 1):
            bpy.context.scene.frame_set(frame)
            bpy.context.view_layer.update()
            
            # Root bone
            root_pbone = armature_obj.pose.bones.get("root")
            if root_pbone:
                src_root = source_armature.pose.bones.get("pelvis")
                if src_root:
                    # Strip horizontal root motion, keep vertical bob
                    pos = src_root.location.copy()
                    pos.x = 0.0
                    pos.y = 0.0
                    root_pbone.location = pos
                    root_pbone.keyframe_insert(data_path="location", frame=frame)
                    root_pbone.rotation_quaternion = src_root.rotation_quaternion.copy()
                    root_pbone.keyframe_insert(data_path="rotation_quaternion", frame=frame)
            
            # Map all 15 bones
            for tgt_bone_name, src_bone_name in BONE_MAP.items():
                if tgt_bone_name == "root":
                    continue
                tgt_pbone = armature_obj.pose.bones.get(tgt_bone_name)
                src_pbone = source_armature.pose.bones.get(src_bone_name)
                if tgt_pbone and src_pbone:
                    tgt_pbone.rotation_mode = "QUATERNION"
                    rot = src_pbone.rotation_quaternion.copy()
                    
                    # Apply archetype lean offsets if applicable
                    if tgt_bone_name == "spine" and "spine_x" in lean:
                        add_q = Matrix.Rotation(lean["spine_x"] * 0.0174533, 4, "X").to_quaternion()
                        rot = add_q @ rot
                        
                    tgt_pbone.rotation_quaternion = rot
                    tgt_pbone.keyframe_insert(data_path="rotation_quaternion", frame=frame)
                    
        bpy.ops.object.mode_set(mode="OBJECT")
        target_actions.append(target_act)
        
    # Clean up all objects except root and target armature
    for obj in list(bpy.context.scene.objects):
        if obj != armature_obj and obj != root_obj:
            bpy.data.objects.remove(obj, do_unlink=True)
            
    # Clean up all actions that are not retargeted actions
    for act in list(bpy.data.actions):
        if act not in target_actions:
            bpy.data.actions.remove(act)
            
    # Export per-fighter anim GLB
    out_dir = ROOT / f"assets/fighters/{fighter_id}/anims"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_glb = out_dir / "anims.glb"
    
    bpy.ops.object.select_all(action="DESELECT")
    armature_obj.select_set(True)
    root_obj.select_set(True)
    bpy.context.view_layer.objects.active = armature_obj
    
    bpy.ops.export_scene.gltf(
        filepath=str(out_glb),
        use_selection=True,
        export_animations=True,
        export_current_frame=False,
    )
    print(f"Exported {fighter_id} anims -> {out_glb} with {len(target_actions)} clips.")


def main():
    pack_map_path = ROOT / "data/animation/pack_map.json"
    with open(pack_map_path, "r", encoding="utf-8") as f:
        pack_map = json.load(f)
        
    actions = load_source_libraries()
    for fighter_id in ["theron", "atalanta", "pyrrhus", "sibyl"]:
        print(f"=== Retargeting {fighter_id} ===")
        retarget_fighter(fighter_id, actions, pack_map)
    print("ALL_ANIM_RETARGET_OK")


if __name__ == "__main__":
    main()
