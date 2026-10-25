import bpy
from .naming import validate
from .colors import paint

def empty(name, location=(0, 0, 0), parent=None):
    obj = bpy.data.objects.new(validate(name), None)
    bpy.context.collection.objects.link(obj)
    obj["generated_by"] = "severed"
    obj.parent = parent
    obj.location = location
    return obj


import bmesh


def shape(name, at, size, mat, parent=None, kind="box"):
    valid_name = validate(name)
    mesh_data = bpy.data.meshes.new(valid_name)
    mesh_data["generated_by"] = "severed"
    
    bm = bmesh.new()
    if kind == "box":
        bmesh.ops.create_cube(bm, size=1.0)
    elif kind == "body":
        bmesh.ops.create_icosphere(bm, subdivisions=2, radius=0.5)
    elif kind == "orb":
        bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.5)
    else:
        bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=10, radius1=0.5, radius2=0.5, depth=1.0)
    
    if kind == "body":
        for face in bm.faces:
            face.smooth = True
            
    bm.to_mesh(mesh_data)
    bm.free()
    
    obj = bpy.data.objects.new(valid_name, mesh_data)
    bpy.context.collection.objects.link(obj)
    obj["generated_by"] = "severed"
    obj.parent = parent
    obj.location = at
    obj.scale = size
    
    mesh_data.materials.append(mat)
    paint(mesh_data, mat.diffuse_color)
    return obj


