"""Builds partitioned Gate A Amputation Pilot for Arissa:
Preserves original Mixamo deform armature (73 bones) and original soft skin weights.
Partitions mesh geometry into:
- Core torso/head/clothing: always retained (no head or neck separation)
- LIMB_ARM_L: Left arm branch
- LIMB_LEG_L: Left leg branch
- STUMP_ARM_L, STUMP_LEG_L: Flesh stump caps and bone fragments
- SOCKET_ARM_L, SOCKET_LEG_L: Empty attachment sockets tracking shoulder and hip
Exports to build/pilot_gate_a/arissa_partitioned.glb.
"""
from collections import defaultdict
import json
from pathlib import Path
import sys

import bpy
import bmesh
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[2]

def build_partitioned_pilot():
    char_fbx = Path(r"D:\Charecter model\Arissa.fbx")
    out_dir = ROOT / "build/pilot_gate_a"
    out_dir.mkdir(parents=True, exist_ok=True)
    
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(char_fbx))
    
    arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
    arm.name = "Skeleton"
    
    # 1. Identify branch deform bones
    left_arm_bones = set()
    def gather(b, s):
        s.add(b.name)
        for c in b.children: gather(c, s)
    gather(arm.data.bones['mixamorig:LeftArm'], left_arm_bones)
    
    left_leg_bones = set()
    gather(arm.data.bones['mixamorig:LeftUpLeg'], left_leg_bones)
    
    # 2. Setup Sockets as child empties of Armature tracking bone positions
    # Sockets for regrown attachments
    def create_socket(name, bone_name, local_pos):
        sock = bpy.data.objects.new(name, None)
        sock.empty_display_type = 'PLAIN_AXES'
        sock.empty_display_size = 0.1
        sock.location = local_pos
        sock.parent = arm
        sock.parent_type = 'BONE'
        sock.parent_bone = bone_name
        bpy.context.collection.objects.link(sock)
        return sock
        
    create_socket("SOCKET_ARM_L", "mixamorig:LeftShoulder", Vector((0, 0, 0)))
    create_socket("SOCKET_LEG_L", "mixamorig:Hips", Vector((0, 0, 0)))
    
    # Stump containers
    stump_arm_l = bpy.data.objects.new("STUMP_ARM_L", None)
    stump_arm_l.parent = arm
    stump_arm_l.parent_type = 'BONE'
    stump_arm_l.parent_bone = "mixamorig:LeftShoulder"
    bpy.context.collection.objects.link(stump_arm_l)
    
    stump_leg_l = bpy.data.objects.new("STUMP_LEG_L", None)
    stump_leg_l.parent = arm
    stump_leg_l.parent_type = 'BONE'
    stump_leg_l.parent_bone = "mixamorig:Hips"
    bpy.context.collection.objects.link(stump_leg_l)
    
    # Simple red flesh stump cap and bone fragment
    # Flesh cap for arm
    mesh_cap_arm = bpy.data.meshes.new("CUT_ARML")
    bm = bmesh.new()
    bmesh.ops.create_circle(bm, cap_ends=True, radius=0.045, segments=12)
    bm.to_mesh(mesh_cap_arm)
    bm.free()
    cap_arm_obj = bpy.data.objects.new("CUT_ARML", mesh_cap_arm)
    cap_arm_obj.parent = stump_arm_l
    bpy.context.collection.objects.link(cap_arm_obj)
    
    # Flesh cap for leg
    mesh_cap_leg = bpy.data.meshes.new("CUT_LEGL")
    bm = bmesh.new()
    bmesh.ops.create_circle(bm, cap_ends=True, radius=0.065, segments=12)
    bm.to_mesh(mesh_cap_leg)
    bm.free()
    cap_leg_obj = bpy.data.objects.new("CUT_LEGL", mesh_cap_leg)
    cap_leg_obj.parent = stump_leg_l
    bpy.context.collection.objects.link(cap_leg_obj)
    
    # 3. Partition meshes cleanly
    source_meshes = [o for o in list(bpy.data.objects) if o.type == 'MESH' and o not in [cap_arm_obj, cap_leg_obj]]
    
    # Logical limb group empties
    limb_arm_l_group = bpy.data.objects.new("LIMB_ARM_L", None)
    limb_arm_l_group.parent = arm
    bpy.context.collection.objects.link(limb_arm_l_group)
    
    limb_leg_l_group = bpy.data.objects.new("LIMB_LEG_L", None)
    limb_leg_l_group.parent = arm
    bpy.context.collection.objects.link(limb_leg_l_group)
    
    for mesh_obj in source_meshes:
        vg_map = {vg.index: vg.name for vg in mesh_obj.vertex_groups}
        vert_limb = {}
        for v in mesh_obj.data.vertices:
            best_vg = None
            best_w = 0.0
            for g in v.groups:
                if g.group in vg_map and g.weight > best_w:
                    best_w = g.weight
                    best_vg = vg_map[g.group]
            if best_vg in left_arm_bones:
                vert_limb[v.index] = 'arm_l'
            elif best_vg in left_leg_bones:
                vert_limb[v.index] = 'leg_l'
            else:
                vert_limb[v.index] = 'core'
                
        # Check if mesh has limb faces
        arm_faces = []
        leg_faces = []
        core_faces = []
        for f in mesh_obj.data.polygons:
            types = [vert_limb[vi] for vi in f.vertices]
            dominant = max(set(types), key=types.count)
            if dominant == 'arm_l':
                arm_faces.append(f.index)
            elif dominant == 'leg_l':
                leg_faces.append(f.index)
            else:
                core_faces.append(f.index)
                
        # If mesh is pure core (like Weapons_Geo), keep it intact
        if not arm_faces and not leg_faces:
            mesh_obj.name = mesh_obj.name.replace("arissa:", "") + "_CORE"
            continue
            
        # Create Arm_L partition if present
        if arm_faces:
            arm_copy = mesh_obj.copy()
            arm_copy.data = mesh_obj.data.copy()
            arm_copy.name = mesh_obj.name.replace("arissa:", "") + "_ARM_L"
            arm_copy["limb_group"] = "LIMB_ARM_L"
            arm_copy.parent = arm
            bpy.context.collection.objects.link(arm_copy)
            
            bm = bmesh.new()
            bm.from_mesh(arm_copy.data)
            del_faces = [f for f in bm.faces if f.index not in arm_faces]
            bmesh.ops.delete(bm, geom=del_faces, context='FACES')
            bm.to_mesh(arm_copy.data)
            bm.free()
            
        # Create Leg_L partition if present
        if leg_faces:
            leg_copy = mesh_obj.copy()
            leg_copy.data = mesh_obj.data.copy()
            leg_copy.name = mesh_obj.name.replace("arissa:", "") + "_LEG_L"
            leg_copy["limb_group"] = "LIMB_LEG_L"
            leg_copy.parent = arm
            bpy.context.collection.objects.link(leg_copy)
            
            bm = bmesh.new()
            bm.from_mesh(leg_copy.data)
            del_faces = [f for f in bm.faces if f.index not in leg_faces]
            bmesh.ops.delete(bm, geom=del_faces, context='FACES')
            bm.to_mesh(leg_copy.data)
            bm.free()
            
        # Reduce original mesh to core faces only
        bm = bmesh.new()
        bm.from_mesh(mesh_obj.data)
        del_faces = [f for f in bm.faces if f.index not in core_faces]
        bmesh.ops.delete(bm, geom=del_faces, context='FACES')
        bm.to_mesh(mesh_obj.data)
        bm.free()
        mesh_obj.name = mesh_obj.name.replace("arissa:", "") + "_CORE"
        
    out_glb = out_dir / "arissa_partitioned.glb"
    bpy.ops.export_scene.gltf(
        filepath=str(out_glb),
        export_format='GLB',
        export_yup=True,
        export_skins=True,
        export_all_influences=True,
    )
    print(f"Exported partitioned pilot: {out_glb}")

if __name__ == "__main__":
    build_partitioned_pilot()
