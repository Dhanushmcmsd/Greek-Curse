"""Generates contact sheets and individual preview stills for all 4 fighters

covering idle, walk, run, 3 attacks, block, stagger, knockdown.
Outputs to docs/playtest/anim/
"""
from pathlib import Path
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "docs/playtest/anim"
OUT_DIR.mkdir(parents=True, exist_ok=True)

FIGHTERS = ["theron", "atalanta", "pyrrhus", "sibyl"]
ACTIONS = [
    ("idle", "idle", 15),
    ("walk", "walk_fwd", 15),
    ("run", "run", 10),
    ("attack_jab", "punch_jab", 8),
    ("attack_heavy", "overhead_slam", 15),
    ("attack_kick", "kick_thrust", 10),
    ("block", "block", 12),
    ("stagger", "stagger", 6),
    ("knockdown", "knockdown", 15),
]


def render_fighter_sheets():
    for fighter_id in FIGHTERS:
        print(f"=== Rendering anim previews for {fighter_id} ===")
        bpy.ops.wm.read_factory_settings(use_empty=True)

        # Import fighter model
        model_path = ROOT / f"assets/generated/models/fighter_{fighter_id}.glb"
        bpy.ops.import_scene.gltf(filepath=str(model_path))

        armature = None
        for obj in bpy.context.scene.objects:
            if obj.type == "ARMATURE":
                armature = obj
                break

        # Hide gore/stump meshes
        for obj in bpy.context.scene.objects:
            if obj.name.startswith(("STUMP_", "CUT_", "BONE_")):
                obj.hide_render = True
                for child in obj.children_recursive:
                    child.hide_render = True

        # Import retargeted animations
        anim_path = ROOT / f"assets/fighters/{fighter_id}/anims/anims.glb"
        bpy.ops.import_scene.gltf(filepath=str(anim_path))

        # Setup Camera & Lighting
        bpy.ops.object.camera_add(location=(0, -3.8, 1.2))
        camera = bpy.context.object
        camera.rotation_euler = (Vector((0, 0, 1.0)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
        camera.data.type = "PERSP"
        camera.data.lens = 50.0

        scene = bpy.context.scene
        scene.camera = camera
        scene.render.engine = "BLENDER_WORKBENCH"
        scene.display.shading.light = "STUDIO"
        scene.display.shading.color_type = "VERTEX"
        scene.display.shading.show_shadows = True
        scene.display.shading.show_cavity = True
        scene.display.shading.background_type = "WORLD"
        if not scene.world:
            scene.world = bpy.data.worlds.new("World")
        scene.world.color = (0.08, 0.09, 0.12)
        scene.render.resolution_x = 400
        scene.render.resolution_y = 400
        scene.render.resolution_percentage = 100
        scene.render.image_settings.file_format = "PNG"

        action_images = []
        for shot_name, act_suffix, frame_num in ACTIONS:
            clip_name = f"{fighter_id}_{act_suffix}"
            target_act = bpy.data.actions.get(clip_name)
            if armature and target_act:
                armature.animation_data_create()
                armature.animation_data.action = target_act
                scene.frame_set(frame_num)
            
            out_file = OUT_DIR / f"{fighter_id}_{shot_name}.png"
            scene.render.filepath = str(out_file)
            bpy.ops.render.render(write_still=True)
            action_images.append(out_file)

        # Create 3x3 contact sheet using PIL or basic image combine if available
        try:
            from PIL import Image
            sheet = Image.new("RGBA", (1200, 1200), (20, 22, 28, 255))
            for idx, img_path in enumerate(action_images):
                img = Image.open(img_path)
                col = idx % 3
                row = idx // 3
                sheet.paste(img, (col * 400, row * 400))
            sheet_path = OUT_DIR / f"contact_sheet_{fighter_id}.png"
            sheet.save(sheet_path)
            print(f"Saved contact sheet -> {sheet_path}")
        except ImportError:
            print("Pillow not installed in Blender python; individual stills saved.")

    print("ALL_ANIM_PREVIEWS_RENDERED_OK")


if __name__ == "__main__":
    render_fighter_sheets()
