import bpy


def export_glb(path):
    # Purge any stray default objects before export
    for obj in list(bpy.data.objects):
        if obj.name in ["Cube", "Light", "Camera"] and obj.get("generated_by") != "severed":
            bpy.data.objects.remove(obj, do_unlink=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.context.scene.objects:
        obj.select_set(obj.get("generated_by") == "severed")
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB",
                             export_extras=True, export_yup=True, use_selection=True,
                             export_animations=False, export_cameras=False, export_lights=False)
