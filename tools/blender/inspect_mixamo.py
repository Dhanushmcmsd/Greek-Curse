import bpy
import glob
import json
import os
from pathlib import Path

CHAR_DIR = Path(r"D:\Charecter model")
ANIM_DIR = Path(r"D:\charecter animation")

results = {"characters": [], "animations": []}

for f in sorted(CHAR_DIR.glob("*.fbx")):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(f))
    arm = [o for o in bpy.data.objects if o.type == 'ARMATURE']
    arm_name = arm[0].name if arm else None
    bones = [b.name for b in arm[0].data.bones] if arm else []
    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    mats = sorted(list(set(mat.name for m in meshes for mat in m.data.materials if mat)))
    total_verts = sum(len(m.data.vertices) for m in meshes)
    total_polys = sum(len(m.data.polygons) for m in meshes)
    min_z = min((m.bound_box[0][2] for m in meshes), default=0)
    max_z = max((m.bound_box[6][2] for m in meshes), default=0)
    
    results["characters"].append({
        "file": f.name,
        "armature": arm_name,
        "bone_count": len(bones),
        "bones_sample": bones[:10],
        "all_bones": bones,
        "mesh_count": len(meshes),
        "meshes": [m.name for m in meshes],
        "vertices": total_verts,
        "polygons": total_polys,
        "materials": mats,
        "bbox_height": max_z - min_z,
        "bbox_min_z": min_z,
        "bbox_max_z": max_z
    })

for f in sorted(ANIM_DIR.rglob("*.fbx")):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(f))
    arm = [o for o in bpy.data.objects if o.type == 'ARMATURE']
    bones = [b.name for b in arm[0].data.bones] if arm else []
    actions = [a.name for a in bpy.data.actions]
    fr = (bpy.data.actions[0].frame_range[0], bpy.data.actions[0].frame_range[1]) if bpy.data.actions else (0, 0)
    results["animations"].append({
        "file": str(f.relative_to(ANIM_DIR)).replace("\\", "/"),
        "bone_count": len(bones),
        "actions": actions,
        "frame_range": fr
    })

out_path = Path(r"E:\zeus balls\build\mixamo_inspection.json")
out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text(json.dumps(results, indent=2))
print(f"MIXAMO_INSPECTION_OK written to {out_path}")
