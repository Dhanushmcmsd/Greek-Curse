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

    # Validate Mixamo converted models if present
    mixamo_manifest_path = ROOT / "assets/fighters_mixamo/mixamo_models_manifest.json"
    if mixamo_manifest_path.exists():
        try:
            mixamo_manifest = json.loads(mixamo_manifest_path.read_text(encoding="utf-8"))
            mixamo_models = mixamo_manifest.get("models", {})
            mixamo_tri_budget = 65000  # D-044: up to 60,000 tris with headroom
            mixamo_skeletons = []
            req_nodes = [
                "SOCKET_ARM_L", "SOCKET_ARM_R", "SOCKET_LEG_L", "SOCKET_LEG_R", "SOCKET_NECK",
                "LIMB_ARM_L", "LIMB_ARM_R", "LIMB_LEG_L", "LIMB_LEG_R",
                "STUMP_ARM_L", "STUMP_ARM_R", "STUMP_LEG_L", "STUMP_LEG_R"
            ]
            for mid, entry in mixamo_models.items():
                m_path = ROOT / entry["path"]
                if not m_path.exists():
                    continue
                m_info = inspect(m_path)
                if m_info["triangles"] > mixamo_tri_budget:
                    errors.append(f"mixamo_{mid}: triangle budget exceeded ({m_info['triangles']} > {mixamo_tri_budget})")
                for rnode in req_nodes:
                    if rnode not in m_info["nodes"]:
                        errors.append(f"mixamo_{mid}: missing node {rnode}")
                if not m_info["skins"]:
                    errors.append(f"mixamo_{mid}: missing skeleton skin")
                else:
                    m_nodes = m_info["data"]["nodes"]
                    m_joints = set(m_info["skins"][0]["joints"])
                    m_parents = {c: i for i, node in enumerate(m_nodes) for c in node.get("children", [])}
                    m_hierarchy = sorted((m_nodes[i]["name"], m_nodes[m_parents[i]]["name"] if m_parents.get(i) in m_joints else "") for i in m_joints)
                    mixamo_skeletons.append(m_hierarchy)
            if mixamo_skeletons and any(s != mixamo_skeletons[0] for s in mixamo_skeletons[1:]):
                errors.append("mixamo fighter skeleton hierarchies differ")
        except Exception as err:
            errors.append(f"mixamo manifest validation error: {err}")

    return errors


if __name__ == "__main__":
    errors = check_assets()
    print("\n".join(errors) if errors else "validate_assets: PASS")
    sys.exit(bool(errors))
