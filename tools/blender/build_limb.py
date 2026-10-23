"""Socket-relative models from declarative limb part data; symmetric handedness."""
import json
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_early_art as art
from lib.cli import parse


def build(row):
    art.clear()
    root = art.empty("REGROWN_" + row["id"].upper())
    root["slot"] = row["slot"]
    root["reference_height"] = 1.8
    for part in row["parts"]:
        mat = art.material(part["name"], part["color"])
        art.shape(part["name"], part["at"], part["size"], mat, root, part["kind"])
    art.export("limb_" + row["id"])


if __name__ == "__main__":
    id = parse().id
    if not id.replace("_", "").isalnum():
        raise ValueError("Invalid limb ID")
    build(json.loads((art.ROOT / "data/limbs" / (id + ".json")).read_text()))
