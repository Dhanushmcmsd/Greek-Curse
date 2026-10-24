import bpy
from pathlib import Path

char_dir = Path(r"D:\Charecter model")
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(char_dir / "Arissa.fbx"))
arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
body = bpy.data.objects.get("arissa:Body_Geo")

print("Armature matrix_world:")
print(arm.matrix_world)
print("Body matrix_world before unparent:")
print(body.matrix_world)

# In Blender, to keep transform when unparenting:
body.matrix_world = body.matrix_world.copy()
body.parent = None
print("Body matrix_world after unparent:")
print(body.matrix_world)
w_verts = [body.matrix_world @ v.co for v in body.data.vertices]
print(f"World Z bounds: min={min(v.z for v in w_verts):.3f}, max={max(v.z for v in w_verts):.3f}")
print(f"World Y bounds: min={min(v.y for v in w_verts):.3f}, max={max(v.y for v in w_verts):.3f}")
