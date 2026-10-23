import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))
from tools.validate.glb_inspect import inspect


def write():
    assets = []
    for path in sorted((ROOT / "assets/generated/models").glob("*.glb")):
        info = inspect(path)
        fighter = path.stem.startswith("fighter_")
        limb = path.stem.startswith("limb_")
        required = []
        if fighter:
            required = [prefix + slot for prefix in ["SOCKET_", "LIMB_", "STUMP_"]
                        for slot in ["ARM_L", "ARM_R", "LEG_L", "LEG_R"]]
        elif path.stem == "pipeline_test":
            required = ["SOCKET_TEST"]
        assets.append({"id": path.stem, "path": path.relative_to(ROOT).as_posix(),
                       "script": "tools/blender/build_all.py", "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                       "triangles": info["triangles"], "bounds": info["bounds"],
                       "budget": 5000 if fighter else (600 if limb else 8000),
                       "required_nodes": required, "rigged": bool(info["skins"])})
    sources = sorted((ROOT / "tools/blender").rglob("*.py"))
    source_hash = hashlib.sha256(b"".join(p.read_bytes() for p in sources)).hexdigest()
    params = sorted((ROOT / "data/art").glob("*.json")) + sorted((ROOT / "data/fighters").glob("*.json"))
    params_hash = hashlib.sha256(b"".join(p.read_bytes() for p in params)).hexdigest()
    import bpy
    payload = {"assets": assets, "source_hash": source_hash, "parameters_hash": params_hash,
               "blender": bpy.app.version_string}
    (ROOT / "assets/generated/manifest.json").write_text(json.dumps(payload, indent=2) + "\n")
