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


def shape(name, at, size, mat, parent=None, kind="box"):
    if kind == "box":
        bpy.ops.mesh.primitive_cube_add(size=1)
    elif kind == "orb":
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.5)
    else:
        bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.5, depth=1)
    obj = bpy.context.object
    obj.name = validate(name)
    obj["generated_by"] = "severed"
    obj.parent = parent
    obj.location = at
    obj.scale = size
    obj.data["generated_by"] = "severed"
    obj.data.materials.append(mat)
    paint(obj.data, mat.diffuse_color)
    return obj


