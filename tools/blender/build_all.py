"""One Blender process, fixed order; generated GLBs stay in source control."""
from pathlib import Path
import runpy
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
runpy.run_path(str(HERE / "build_early_art.py"), run_name="__main__")
runpy.run_path(str(HERE / "build_pipeline_test.py"), run_name="__main__")
from lib.manifest import write
write()
print("BUILD_ALL_OK")
