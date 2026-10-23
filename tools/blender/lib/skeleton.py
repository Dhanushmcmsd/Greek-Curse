"""One fixed named hierarchy; proportional rest positions, rigid vertex weights."""
import bpy
from mathutils import Vector


def build_armature(root, height, width):
    # glTF skinned POSITION data is in armature space. Flatten mesh parents
    # before binding, retaining logical groups as metadata; nested socket
    # translations otherwise get applied twice by the Godot importer.
    bpy.context.view_layer.update()
    for obj in list(root.children_recursive):
        if obj.type == "MESH":
            world = obj.matrix_world.copy()
            ancestor = obj.parent
            while ancestor and ancestor != root:
                if ancestor.name.startswith(("LIMB_", "STUMP_")):
                    obj["limb_group"] = ancestor.name
                    break
                ancestor = ancestor.parent
            obj.parent = root
            obj.matrix_world = world
    bpy.context.view_layer.update()
    data = bpy.data.armatures.new("GEN_shared_skeleton")
    data["generated_by"] = "severed"
    armature = bpy.data.objects.new("Skeleton", data)
    armature["generated_by"] = "severed"
    bpy.context.collection.objects.link(armature)
    armature.parent = root
    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    specs = [("root", None, (0, 0, 0), (0, 0, height * .45)),
             ("spine", "root", (0, 0, height * .45), (0, 0, height * .84)),
             ("head", "spine", (0, 0, height * .84), (0, 0, height))]
    for side, sign in [("l", -1), ("r", 1)]:
        for limb, x, z, length in [("arm", sign * width * .53, height * .79, height * .31),
                                    ("leg", sign * width * .23, height * .45, height * .43)]:
            names = ["upper_arm", "forearm", "hand"] if limb == "arm" else ["thigh", "shin", "foot"]
            parent = "spine" if limb == "arm" else "root"
            for index, (start, end) in enumerate([(0, .5), (.5, .9), (.9, 1.0)]):
                name = names[index] + "." + side
                specs.append((name, parent, (x, 0, z - length * start), (x, 0, z - length * end)))
                parent = name
    for name, parent, start, end in specs:
        bone = data.edit_bones.new(name)
        bone.head = start
        bone.tail = end
        if parent:
            bone.parent = data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    for obj in list(root.children_recursive):
        if obj.type != "MESH":
            continue
        name = obj.name
        bone = "head" if name.startswith(("HEAD", "HELM", "CREST", "BRAID", "WREATH", "VEIL")) else "spine"
        for limb, names in [("ARM", ["upper_arm", "forearm", "hand"]), ("LEG", ["thigh", "shin", "foot"])]:
            for side in ["L", "R"]:
                for part, joint in zip(["UPPER", "LOWER", "END"], names):
                    if name == f"{limb}_{part}_{side}":
                        bone = joint + "." + side.lower()
        obj["rigid_bone"] = bone
        group = obj.vertex_groups.new(name=bone)
        group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
        modifier = obj.modifiers.new("RigidSkin", "ARMATURE")
        modifier.object = armature
    return armature
