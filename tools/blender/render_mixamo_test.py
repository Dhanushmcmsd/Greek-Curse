import bpy
import sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]

def render_state(glb_path, out_dir, prefix):
    out_dir.mkdir(parents=True, exist_ok=True)
    
    slots = ["ARM_L", "ARM_R", "LEG_L", "LEG_R"]
    
    states = [
        ("full_body", [], []),
        ("severed_arm_l", ["ARM_L"], ["ARM_L"]),
        ("severed_arm_r", ["ARM_R"], ["ARM_R"]),
        ("severed_leg_l", ["LEG_L"], ["LEG_L"]),
        ("severed_leg_r", ["LEG_R"], ["LEG_R"]),
        ("regrown_arm_l", ["ARM_L"], []),
    ]
    
    for state_name, hidden_limbs, visible_stumps in states:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=str(glb_path))
        
        # If regrown, import replacement limb and attach to SOCKET_ARM_L
        if state_name == "regrown_arm_l":
            chicken_path = ROOT / "assets/generated/models/limb_rubber_chicken_arm.glb"
            if chicken_path.exists():
                before = set(bpy.data.objects)
                bpy.ops.import_scene.gltf(filepath=str(chicken_path))
                chicken_objs = set(bpy.data.objects) - before
                socket = bpy.data.objects.get("SOCKET_ARM_L")
                for obj in chicken_objs:
                    if obj.parent is None and socket:
                        obj.parent = socket
                        obj.matrix_parent_inverse = socket.matrix_world.inverted()
        
        # Set visibility
        for obj in bpy.data.objects:
            # Check if part of a stump
            for s in slots:
                if s in obj.name and any(p in obj.name for p in ["STUMP_", "CUT_", "BONE_"]):
                    obj.hide_render = (s not in visible_stumps)
                    obj.hide_viewport = obj.hide_render
            # Check if part of a limb group
            for s in slots:
                if f"LIMB_{s}" in obj.name or any(f"{p}_{s[-1]}" in obj.name for p in ["ARM_UPPER", "ARM_LOWER", "ARM_END", "LEG_UPPER", "LEG_LOWER", "LEG_END"]):
                    if s in hidden_limbs:
                        obj.hide_render = True
                        obj.hide_viewport = True

        # Camera setup looking along +Y towards character front
        bpy.ops.object.camera_add(location=(0, -4.0, 1.1))
        camera = bpy.context.object
        camera.rotation_euler = (Vector((0, 0, 1.05)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
        camera.data.type = "PERSP"
        camera.data.lens = 45.0
        
        scene = bpy.context.scene
        scene.camera = camera
        scene.render.engine = "BLENDER_WORKBENCH"
        scene.display.shading.light = "STUDIO"
        scene.display.shading.color_type = "TEXTURE"
        scene.display.shading.show_shadows = True
        scene.display.shading.show_cavity = True
        scene.display.shading.background_type = "WORLD"
        if not scene.world:
            scene.world = bpy.data.worlds.new("World")
        scene.world.color = (0.08, 0.09, 0.12)
        
        scene.render.resolution_x = 800
        scene.render.resolution_y = 1000
        scene.render.image_settings.file_format = "PNG"
        
        out_file = out_dir / f"{prefix}_{state_name}.png"
        scene.render.filepath = str(out_file)
        bpy.ops.render.render(write_still=True)
        print(f"RENDER_OK: {out_file}")

if __name__ == "__main__":
    out_dir = ROOT / "docs/playtest/screenshots/mixamo_step2"
    render_state(ROOT / "assets/fighters_mixamo/fighter_atalanta.glb", out_dir, "atalanta")
    render_state(ROOT / "assets/fighters_mixamo/fighter_vampire_stress.glb", out_dir, "vampire_stress")
