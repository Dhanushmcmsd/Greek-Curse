"""Manifest/file checks and topology contracts for generated assets."""
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tools.validate.glb_inspect import inspect


def validate_asset(path, record, require_rig=False):
    errors = []
    try:
        info = inspect(path)
    except (ValueError, KeyError, OSError) as error:
        return [str(error)]
    if hashlib.sha256(Path(path).read_bytes()).hexdigest() != record["sha256"]:
        errors.append("hash mismatch")
    if info["triangles"] > record["budget"]:
        errors.append("triangle budget exceeded")
    for name in record.get("required_nodes", []):
        if name not in info["nodes"]:
            errors.append("missing node " + name)
    if not info["vertex_colors"]:
        errors.append("missing vertex colors")
    if require_rig and not info["skins"]:
        errors.append("missing skeleton skin")
    return errors


def check_assets():
    manifest_path = ROOT / "assets/generated/manifest.json"
    if not manifest_path.exists():
        return ["missing asset manifest"]
    manifest = json.loads(manifest_path.read_text())
    errors = []
    paths = set()
    for record in manifest["assets"]:
        path = ROOT / record["path"]
        paths.add(path.resolve())
        errors.extend(f"{record['id']}: {e}" for e in validate_asset(path, record, record.get("rigged", False)))
    for path in (ROOT / "assets/generated").rglob("*.glb"):
        if path.resolve() not in paths:
            errors.append("orphan asset " + str(path))
    skeletons = []
    for record in manifest["assets"]:
        if not record["id"].startswith("fighter_") or not record.get("rigged", False):
            continue
        info = inspect(ROOT / record["path"])
        nodes = info["data"]["nodes"]
        joints = set(info["skins"][0]["joints"])
        parents = {c: i for i, node in enumerate(nodes) for c in node.get("children", [])}
        hierarchy = sorted((nodes[i]["name"], nodes[parents[i]]["name"] if parents.get(i) in joints else "") for i in joints)
        skeletons.append(hierarchy)
        row = json.loads((ROOT / "data/fighters" / (record["id"].removeprefix("fighter_") + ".json")).read_text())
        height = row["body"]["height_m"]
        boxes = [g for g in info["geometry"].values() if g["min"]]
        top = max(g["max"][1] for g in boxes)
        bottom = min(g["min"][1] for g in boxes)
        if abs(top - height) > height * .01 or bottom < -.01:
            errors.append(record["id"] + f" height/floor mismatch {bottom}..{top} expected {height}")
        for slot in ["ARM_L", "ARM_R", "LEG_L", "LEG_R"]:
            socket = info["geometry"]["SOCKET_" + slot]["position"]
            expected = height * (.79 if slot.startswith("ARM") else .45)
            if abs(socket[1] - expected) > .005:
                errors.append(record["id"] + " socket position " + slot)
    if skeletons and any(s != skeletons[0] for s in skeletons[1:]):
        errors.append("fighter skeleton hierarchies differ")
    return errors


if __name__ == "__main__":
    errors = check_assets()
    print("\n".join(errors) if errors else "validate_assets: PASS")
    sys.exit(bool(errors))
