"""Renders high-quality visual proof contact sheets and individual keyframe stills for Gate A Pilot.
Evaluates the intact Arissa deform skeleton playing:
- idle: combat ready idle
- walk_fwd: forward combat walk
- walk_back: Walking Backwards retreat
- punch_jab: Lead jab strike
- kick_thrust: Thrust kick extension
Renders via Blender WORKBENCH engine directly into docs/playtest/pilot_gate_a/.
"""
from pathlib import Path
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "docs/playtest/pilot_gate_a"
OUT_DIR.mkdir(parents=True, exist_ok=True)

MODEL_GLB = ROOT / "build/pilot_gate_a/arissa_intact.glb"
ACTIONS = [
    ("idle", "anim_idle.glb", [1, 25, 50]),
    ("walk_fwd", "anim_walk_fwd.glb", [1, 16, 28]),
    ("walk_back", "anim_walk_back.glb", [1, 14, 25]),
    ("punch_jab", "anim_punch_jab.glb", [1, 28, 48]),
    ("kick_thrust", "anim_kick_thrust.glb", [1, 35, 55]),
]

def render_gate_a_proof():
    print("=== Rendering Gate A Visual Proof Stills ===")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    
    # 1. Import intact Arissa GLB
    bpy.ops.import_scene.gltf(filepath=str(MODEL_GLB))
    armature = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"][0]
    
    # Setup Camera & Studio Lighting
    bpy.ops.object.camera_add(location=(1.8, -2.6, 1.4))
    camera = bpy.context.object
    camera.rotation_euler = (Vector((0, 0, 0.9)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
    camera.data.type = "PERSP"
    camera.data.lens = 45.0
    
    bpy.ops.object.light_add(type='SUN', location=(2, -2, 4))
    sun = bpy.context.object
    sun.data.energy = 2.5
    
    scene = bpy.context.scene
    scene.camera = camera
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "MATERIAL"
    scene.display.shading.show_shadows = True
    scene.display.shading.show_cavity = True
    scene.display.shading.background_type = "WORLD"
    if not scene.world:
        scene.world = bpy.data.worlds.new("World")
    scene.world.color = (0.12, 0.14, 0.18)
    scene.render.resolution_x = 640
    scene.render.resolution_y = 640
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    
    rendered_stills = []
    
    for act_name, anim_file, keyframes in ACTIONS:
        anim_path = ROOT / f"build/pilot_gate_a/{anim_file}"
        bpy.ops.import_scene.gltf(filepath=str(anim_path))
        
        anim_arms = [o for o in bpy.context.scene.objects if o.type == "ARMATURE" and o != armature]
        anim_arm = anim_arms[-1] if anim_arms else None
        
        if anim_arm and anim_arm.animation_data and anim_arm.animation_data.action:
            act = anim_arm.animation_data.action
            slot = anim_arm.animation_data.action_slot
            
            armature.animation_data_create()
            armature.animation_data.action = act
            if hasattr(armature.animation_data, "action_slot") and slot:
                armature.animation_data.action_slot = slot
                
            for idx, fnum in enumerate(keyframes):
                scene.frame_set(fnum)
                bpy.context.view_layer.update()
                out_png = OUT_DIR / f"{act_name}_frame_{idx+1}_f{fnum}.png"
                scene.render.filepath = str(out_png)
                bpy.ops.render.render(write_still=True)
                print(f"Rendered: {out_png.name} (action: {act_name}, frame: {fnum})")
                rendered_stills.append(out_png)
                
        # Clean up imported anim armature
        if anim_arm:
            bpy.data.objects.remove(anim_arm, do_unlink=True)
            
    print("All stills rendered.")

if __name__ == "__main__":
    render_gate_a_proof()
