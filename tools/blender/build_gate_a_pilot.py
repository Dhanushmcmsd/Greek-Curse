"""Builds intact Gate A Pilot for Arissa (Atalanta):
Preserves original Mixamo deform armature (73 bones) and soft skin weights directly from FBX.
Keeps 1 unit = 1 meter coordinates.
Retargets core action set:
- idle: idle (5).fbx
- walk_fwd: walking.fbx
- walk_back: Walking Backwards.fbx
- punch_jab: Lead Jab.fbx
- kick_thrust: Kicking.fbx
"""
import json
from pathlib import Path
import sys

import bpy

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/blender"))

from retarget_source_anims import retarget_action_to_character

def build_arissa_intact_pilot():
    char_fbx = Path(r"D:\Charecter model\Arissa.fbx")
    anim_dir = Path(r"D:\charecter animation")
    out_dir = ROOT / "build/pilot_gate_a"
    out_dir.mkdir(parents=True, exist_ok=True)
    
    # 1. Export intact model without destructive transform_apply
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(char_fbx))
    
    arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
    arm.name = "Skeleton"
    
    model_glb = out_dir / "arissa_intact.glb"
    bpy.ops.export_scene.gltf(
        filepath=str(model_glb),
        export_format='GLB',
        export_yup=True,
        export_skins=True,
        export_all_influences=True,
    )
    print(f"Exported intact model: {model_glb}")
    
    # 2. Retarget core action set directly
    core_clips = [
        ("idle", anim_dir / "idle and start animation/idle (5).fbx", True),
        ("walk_fwd", anim_dir / "walking front/walking.fbx", True),
        ("walk_back", anim_dir / "walking back/Walking Backwards.fbx", True),
        ("punch_jab", anim_dir / "punch/Lead Jab.fbx", True),
        ("kick_thrust", anim_dir / "kick/Kicking.fbx", True),
    ]
    
    manifest = {
        "character": "arissa",
        "source_fbx": str(char_fbx),
        "total_bones": len(arm.data.bones),
        "height_m": 1.78,
        "actions": {}
    }
    
    for act_name, clip_path, zero_root in core_clips:
        anim_glb = out_dir / f"anim_{act_name}.glb"
        print(f"Retargeting {act_name} from {clip_path.name}...")
        meta = retarget_action_to_character(
            char_fbx,
            clip_path,
            act_name,
            anim_glb,
            target_height_m=1.78,
            zero_horizontal_root=zero_root
        )
        manifest["actions"][act_name] = meta
        print(f"  -> {anim_glb.name}: {meta['frame_range']} ({meta['duration_sec']:.2f}s, {meta['mapped_bones_count']} bones)")
        
    manifest_path = out_dir / "pilot_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2))
    print(f"Gate A Pilot manifest written to: {manifest_path}")

if __name__ == "__main__":
    build_arissa_intact_pilot()
