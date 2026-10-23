"""Workbench preview from generated GLBs; optional --roster true-scale lineup."""
import math
from pathlib import Path
import sys
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
roster = "--roster" in args
asset = next((a for a in args if not a.startswith("--")), "pipeline_test")
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
ids = ["fighter_theron", "fighter_atalanta", "fighter_pyrrhus", "fighter_sibyl"] if roster else [asset]
for index, name in enumerate(ids):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(ROOT / f"assets/generated/models/{name}.glb"))
    imported = set(bpy.data.objects) - before
    for obj in imported:
        if obj.name.startswith("STUMP_"):
            obj.hide_render = True
            for child in obj.children_recursive:
                child.hide_render = True
        if obj.parent is None:
            obj.location.x += (index - 1.5) * 1.5 if roster else 0
bpy.ops.object.camera_add(location=(0, -8, 3.0))
camera = bpy.context.object
camera.rotation_euler = (Vector((0, 0, 1.05)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = 7.0 if roster else 3.0
scene = bpy.context.scene
scene.camera = camera
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "VERTEX"
scene.display.shading.show_shadows = True
scene.display.shading.show_cavity = True
scene.display.shading.background_type = "WORLD"
scene.world.color = (.055, .065, .09)
scene.render.resolution_x = 1200 if roster else 600
scene.render.resolution_y = 600
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
out = ROOT / "build/previews"
out.mkdir(parents=True, exist_ok=True)
scene.render.filepath = str(out / ("roster.png" if roster else asset + ".png"))
try:
    bpy.ops.render.render(write_still=True)
    print("PREVIEW_OK " + scene.render.filepath)
except RuntimeError as exc:
    print("PREVIEW_UNVERIFIED " + str(exc))
    raise SystemExit(1)
