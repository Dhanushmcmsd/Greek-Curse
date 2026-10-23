def paint(mesh, rgba):
    layer = mesh.color_attributes.get("Col") or mesh.color_attributes.new(
        name="Col", type="FLOAT_COLOR", domain="CORNER")
    for entry in layer.data:
        entry.color = rgba
