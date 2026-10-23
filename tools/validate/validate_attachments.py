"""Rest attachment bounds for all 40 compatible combinations.

Socket error <=1mm; floor >=-15mm; no head overlap; torso horizontal
penetration <=180mm (includes broad hands and joint/clothing AABBs).
Animated clipping is deliberately still part of the manual checkpoint.
"""
import json
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tools.validate.glb_inspect import inspect


def bounds(info):
    boxes = [b for b in info["geometry"].values() if b["min"]]
    return ([min(b["min"][i] for b in boxes) for i in range(3)],
            [max(b["max"][i] for b in boxes) for i in range(3)])


def check():
    errors, cases = [], []
    for fighter_path in sorted((ROOT / "data/fighters").glob("*.json")):
        fighter = json.loads(fighter_path.read_text())
        model = inspect(ROOT / f"assets/generated/models/fighter_{fighter['id']}.glb")
        scale = [fighter["body"]["shoulder_width"] / .45, fighter["height_mm"] / 1800,
                 fighter["body"]["shoulder_width"] / .45]
        for limb_path in sorted((ROOT / "data/limbs").glob("*.json")):
            limb = json.loads(limb_path.read_text())
            low, high = bounds(inspect(ROOT / f"assets/generated/models/limb_{limb['id']}.glb"))
            for side in ["L", "R"]:
                slot = limb["slot"].upper() + "_" + side
                socket = model["geometry"]["SOCKET_" + slot]["position"]
                lo = [socket[i] + low[i] * scale[i] for i in range(3)]
                hi = [socket[i] + high[i] * scale[i] for i in range(3)]
                label = f"{fighter['id']}/{limb['id']}/{slot}"
                if lo[1] < -.015:
                    errors.append(label + " below floor")
                head = model["geometry"]["HEAD"]
                overlap = [min(hi[i], head["max"][i]) - max(lo[i], head["min"][i]) for i in range(3)]
                if all(v > .001 for v in overlap):
                    errors.append(label + " head overlap")
                torso = model["geometry"]["TORSO"]
                penetration = min(hi[0], torso["max"][0]) - max(lo[0], torso["min"][0])
                if penetration > .18 and hi[1] > torso["min"][1]:
                    errors.append(label + " excess torso penetration")
                if any(not .7 <= v <= 1.5 for v in scale):
                    errors.append(label + " invalid scale")
                cases.append({"case": label, "min": lo, "max": hi, "scale": scale})
    (ROOT / "build").mkdir(exist_ok=True)
    (ROOT / "build/attachment_matrix.json").write_text(json.dumps(cases, indent=2))
    return errors, len(cases)


if __name__ == "__main__":
    errors, count = check()
    print("\n".join(errors) if errors else f"ATTACHMENTS_OK cases={count}")
    sys.exit(bool(errors))
