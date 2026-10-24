import bpy
from pathlib import Path

ROOT = Path(r"e:/zeus balls")
bpy.ops.import_scene.gltf(filepath=str(ROOT / "assets/fighters_mixamo/fighter_atalanta.glb"))

print("=== ATALANTA OBJECTS ===")
for o in bpy.data.objects:
    if o.type == "MESH":
        mods = [m.type for m in o.modifiers]
        vgs = [vg.name for vg in o.vertex_groups]
        print(f"MESH: {o.name:20} verts={len(o.data.vertices):5} parent={o.parent.name if o.parent else 'None'} loc={o.location} mods={mods} vgs={vgs}")
    elif o.type == "ARMATURE":
        print(f"ARMATURE: {o.name:20} bones={[b.name for b in o.data.bones]}")
    else:
        print(f"EMPTY: {o.name:20} parent={o.parent.name if o.parent else 'None'} loc={o.location}")
