"""Workbench preview from generated GLBs; optional --roster true-scale lineup."""
import math
from pathlib import Path
import sys
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
limbs = "--limbs" in args
roster = "--roster" in args or limbs
asset = next((a for a in args if not a.startswith("--")), "pipeline_test")
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
ids = ["fighter_theron", "fighter_atalanta", "fighter_pyrrhus", "fighter_sibyl"] if roster else [asset]
if limbs:
    ids = ["limb_" + p.stem for p in sorted((ROOT / "data/limbs").glob("*.json"))]
for index, name in enumerate(ids):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(ROOT / f"assets/generated/models/{name}.glb"))
    imported = set(bpy.data.objects) - before
    for obj in imported:
        if obj.name.startswith(("STUMP_", "CUT_", "BONE_")):
            obj.hide_render = True
            for child in obj.children_recursive:
                child.hide_render = True
        if obj.parent is None:
            obj.location.x += (index - (len(ids)-1)/2) * 1.2 if roster else 0
bpy.ops.object.camera_add(location=(0, -8, 3.0))
if limbs:
    for obj in bpy.data.objects:
        if obj.parent is None and obj.type != "CAMERA":
            obj.location.z += 1.5
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
scene.render.filepath = str(out / ("limbs.png" if limbs else "roster.png" if roster else asset + ".png"))
try:
    bpy.ops.render.render(write_still=True)
    if not roster:
        import numpy as np
        sheet = np.zeros((1200, 3000, 4), dtype=np.float32)
        target = scene.render.filepath
        for index in range(10):
            angle = index * math.tau / 8 if index < 8 else (0 if index == 8 else math.pi / 2)
            camera.location = (math.sin(angle) * 6, -math.cos(angle) * 6, 2.5 if index < 8 else 1)
            camera.rotation_euler = (Vector((0, 0, 1)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
            scene.render.filepath = str(out / f"{asset}_{index:02}.png")
            bpy.ops.render.render(write_still=True)
            frame = bpy.data.images.load(scene.render.filepath, check_existing=False)
            pixels = np.array(frame.pixels[:], dtype=np.float32).reshape(600, 600, 4)
            y, x = divmod(index, 5)
            sheet[y*600:(y+1)*600, x*600:(x+1)*600] = pixels
            bpy.data.images.remove(frame)
        image = bpy.data.images.new("contact_sheet", width=3000, height=1200, alpha=True)
        image.pixels.foreach_set(sheet.ravel())
        image.filepath_raw = target
        image.file_format = "PNG"
        image.save()
        scene.render.filepath = target
    print("PREVIEW_OK " + scene.render.filepath)
except RuntimeError as exc:
    print("PREVIEW_UNVERIFIED " + str(exc))
    raise SystemExit(1)
