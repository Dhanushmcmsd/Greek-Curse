import json

data = json.load(open("build/mixamo_inspection.json"))
print("=== CHARACTERS ===")
for c in data["characters"]:
    print(f"{c['file']}: bones={c['bone_count']}, meshes={c['mesh_count']}, verts={c['vertices']}, polys={c['polygons']}, bbox_h={c['bbox_height']:.2f}, mats={c['materials']}")

cats = sorted(list(set(a["file"].split("/")[0] for a in data["animations"])))
print("\n=== ANIMATION CATEGORIES ===")
for cat in cats:
    anims = [a for a in data["animations"] if a["file"].startswith(cat + "/")]
    print(f"{cat}: {len(anims)} clips")
    for a in anims:
        print(f"  - {a['file']} (frames: {a['frame_range']})")
