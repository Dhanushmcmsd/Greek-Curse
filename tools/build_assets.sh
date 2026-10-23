#!/usr/bin/env bash
set -eu
cd "$(dirname "$0")/.."
"${BLENDER_BIN:-D:/blender/blender.exe}" --background --python tools/blender/build_all.py
"${PYTHON_BIN:-python}" tools/validate/validate_assets.py
