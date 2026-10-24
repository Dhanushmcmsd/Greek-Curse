import bpy
from pathlib import Path

fbx = r"d:\charecter animation\punch\Lead Jab.fbx"
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=fbx)
arm = bpy.data.objects['Armature']

# Scrub frames
scene = bpy.context.scene
for f in [1, 10, 20]:
    scene.frame_set(f)
    hips = arm.pose.bones.get('mixamorig:Hips')
    arm_l = arm.pose.bones.get('mixamorig:LeftArm')
    print(f"Frame {f}: Hips loc={hips.location}, Arm_L rot={arm_l.rotation_quaternion}")
