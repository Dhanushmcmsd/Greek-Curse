"""Delete only objects owned by this generator; preserve user content."""
import bpy


def reset():
    for obj in list(bpy.data.objects):
        if obj.get("generated_by") == "severed":
            bpy.data.objects.remove(obj, do_unlink=True)
    for collection in (bpy.data.meshes, bpy.data.materials, bpy.data.armatures, bpy.data.cameras, bpy.data.lights):
        for item in list(collection):
            if item.users == 0 and item.get("generated_by") == "severed":
                collection.remove(item)
