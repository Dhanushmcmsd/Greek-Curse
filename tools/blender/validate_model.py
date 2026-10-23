"""Blender-side finite transforms and rigid-weight audit."""
import bpy
import math


def validate():
    errors = []
    for obj in bpy.context.scene.objects:
        if obj.get("generated_by") != "severed":
            continue
        if any(not math.isfinite(v) for row in obj.matrix_world for v in row):
            errors.append(obj.name + " non-finite transform")
        if obj.type == "MESH" and obj.get("rigid_bone"):
            for vertex in obj.data.vertices:
                if len(vertex.groups) != 1 or abs(vertex.groups[0].weight - 1) > .00001:
                    errors.append(obj.name + " non-rigid weight")
    if errors:
        raise ValueError("; ".join(errors))
    return True
