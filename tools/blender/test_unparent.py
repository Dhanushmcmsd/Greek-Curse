import bpy
from pathlib import Path

char_dir = Path(r"D:\Charecter model")
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(char_dir / "Arissa.fbx"))
meshes = [o for o in bpy.data.objects if o.type == "MESH" and o.name != "Cube"]
for m in meshes:
    # Evaluate global matrix on unparented mesh
    m.matrix_world = m.matrix_world.copy()
    m.parent = None
    m.select_set(True)

bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
joined = bpy.context.view_layer.objects.active
joined.name = "BASE"
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

print("Joined vertex count:", len(joined.data.vertices))
print(f"Joined bounds X: [{min(v.co.x for v in joined.data.vertices):.3f}, {max(v.co.x for v in joined.data.vertices):.3f}]")
print(f"Joined bounds Y: [{min(v.co.y for v in joined.data.vertices):.3f}, {max(v.co.y for v in joined.data.vertices):.3f}]")
print(f"Joined bounds Z: [{min(v.co.z for v in joined.data.vertices):.3f}, {max(v.co.z for v in joined.data.vertices):.3f}]")
