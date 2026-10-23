"""Generate a temporary fifth model using parameters only; no roster mutation."""
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_early_art as art

art.OUT = art.ROOT / "build/data_only_fixture"
art.OUT.mkdir(parents=True, exist_ok=True)
art.fighter(("fixture_fifth", 1.9, .47, (.5, .3, .2), (.1, .3, .5), "hunter"))
assert (art.OUT / "fighter_fixture_fifth.glb").exists()
print("DATA_ONLY_FIGHTER_OK")
