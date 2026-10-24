import bpy

def material(name, color):
    mat = bpy.data.materials.new("GEN_" + name)
    mat["generated_by"] = "severed"
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (1, 1, 1, 1)
    bsdf.inputs["Roughness"].default_value = .32 if name in ["bronze", "steel", "gem"] else .72
    bsdf.inputs["Metallic"].default_value = .7 if name in ["bronze", "steel"] else 0
    attr = mat.node_tree.nodes.new("ShaderNodeVertexColor")
    attr.layer_name = "Col"
    mat.node_tree.links.new(attr.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


