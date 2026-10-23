def mesh_stats(obj):
    obj.data.calc_loop_triangles()
    return {"triangles": len(obj.data.loop_triangles),
            "bounds": [list(corner) for corner in obj.bound_box],
            "vertex_colors": bool(obj.data.color_attributes)}
