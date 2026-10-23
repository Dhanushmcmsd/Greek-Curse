"""Explicit expensive check; builds twice and compares the complete manifest."""
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
blender = os.environ.get("BLENDER_BIN", "D:/blender/blender.exe")
command = [blender, "--background", "--python", str(ROOT / "tools/blender/build_all.py")]
subprocess.run(command, cwd=ROOT, check=True)
first = (ROOT / "assets/generated/manifest.json").read_bytes()
subprocess.run(command, cwd=ROOT, check=True)
second = (ROOT / "assets/generated/manifest.json").read_bytes()
if first != second:
    raise SystemExit("IDEMPOTENCE_FAIL")
print("IDEMPOTENCE_OK")
