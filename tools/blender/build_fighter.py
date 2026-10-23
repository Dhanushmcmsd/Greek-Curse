import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lib.cli import parse
import build_early_art as art
from lib.manifest import write

id = parse().id
if not id.replace("_", "").isalnum():
    raise ValueError("Invalid fighter ID")
row = json.loads((art.ROOT / "data/fighters" / (id + ".json")).read_text())
b = row["body"]
art.fighter((id, b["height_m"], b["shoulder_width"], b["skin_tone"], b["cloth_color"], b["costume"]))
write()
