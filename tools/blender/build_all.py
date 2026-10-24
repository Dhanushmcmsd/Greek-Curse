"""One Blender process, fixed order; generated GLBs stay in source control."""
from pathlib import Path
import runpy
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
runpy.run_path(str(HERE / "build_early_art.py"), run_name="__main__")
runpy.run_path(str(HERE / "build_pipeline_test.py"), run_name="__main__")
import json
from build_limb import build
for path in sorted((HERE.parents[1] / "data/limbs").glob("*.json")):
    build(json.loads(path.read_text()))
from build_gore import build as build_gore
build_gore()
from build_obol import build as build_obol
build_obol()
from lib.manifest import write
write()
print("BUILD_ALL_OK")
