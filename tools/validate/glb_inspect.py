"""Dependency-free glTF 2 binary reader; never executes asset extras."""
import json
import math
import struct
from pathlib import Path


def multiply(a, b):
    return [[sum(a[r][k] * b[k][c] for k in range(4)) for c in range(4)] for r in range(4)]


def local_matrix(node):
    if "matrix" in node:
        return [[node["matrix"][c * 4 + r] for c in range(4)] for r in range(4)]
    x, y, z, w = node.get("rotation", [0, 0, 0, 1])
    s = node.get("scale", [1, 1, 1])
    t = node.get("translation", [0, 0, 0])
    r = [[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)],
         [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)],
         [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]]
    return [[r[i][j] * s[j] for j in range(3)] + [t[i]] for i in range(3)] + [[0, 0, 0, 1]]


def world_geometry(data):
    transforms = {}
    parents = {child: index for index, n in enumerate(data.get("nodes", [])) for child in n.get("children", [])}
    def matrix(index):
        if index not in transforms:
            local = local_matrix(data["nodes"][index])
            transforms[index] = multiply(matrix(parents[index]), local) if index in parents else local
        return transforms[index]
    geometry = {}
    for index, node in enumerate(data.get("nodes", [])):
        m = matrix(index)
        points = []
        if "mesh" in node:
            for primitive in data["meshes"][node["mesh"]]["primitives"]:
                a = data["accessors"][primitive["attributes"]["POSITION"]]
                for x in [a["min"][0], a["max"][0]]:
                    for y in [a["min"][1], a["max"][1]]:
                        for z in [a["min"][2], a["max"][2]]:
                            points.append([sum(m[r][c]*[x,y,z,1][c] for c in range(4)) for r in range(3)])
        geometry[node.get("name", str(index))] = {"position": [m[r][3] for r in range(3)],
            "min": [min(p[i] for p in points) for i in range(3)] if points else [],
            "max": [max(p[i] for p in points) for i in range(3)] if points else []}
    return geometry


def inspect(path):
    raw = Path(path).read_bytes()
    if len(raw) < 20 or raw[:4] != b"glTF":
        raise ValueError("Not a GLB")
    _, version, length = struct.unpack_from("<4sII", raw)
    if version != 2 or length != len(raw):
        raise ValueError("Invalid GLB version/length")
    size, kind = struct.unpack_from("<II", raw, 12)
    if kind != 0x4E4F534A or 20 + size > len(raw):
        raise ValueError("Missing JSON chunk")
    data = json.loads(raw[20:20 + size])
    triangles = 0
    colors = True
    bounds = []
    for mesh in data.get("meshes", []):
        for primitive in mesh["primitives"]:
            accessors = data["accessors"]
            pos = accessors[primitive["attributes"]["POSITION"]]
            count = accessors[primitive["indices"]]["count"] if "indices" in primitive else pos["count"]
            triangles += count // 3
            colors &= "COLOR_0" in primitive["attributes"]
            bounds.extend([pos.get("min", []), pos.get("max", [])])
    if any(not math.isfinite(v) for vector in bounds for v in vector):
        raise ValueError("Non-finite bounds")
    return {"data": data, "nodes": [n.get("name", "") for n in data.get("nodes", [])],
            "triangles": triangles, "vertex_colors": colors, "bounds": bounds,
            "skins": data.get("skins", []), "geometry": world_geometry(data)}


if __name__ == "__main__":
    import sys
    result = inspect(sys.argv[1])
    print(json.dumps({k: v for k, v in result.items() if k != "data"}, indent=2))
