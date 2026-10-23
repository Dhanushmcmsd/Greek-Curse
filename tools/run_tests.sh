#!/usr/bin/env bash
# Linux/macOS launcher. Not executed on the Windows dev machine (UNVERIFIED there).
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
GODOT="${GODOT_BIN:-}"
if [[ -z "$GODOT" ]]; then
  GODOT="$(grep -o 'PINNED `[^`]*`' PROJECT_STATUS.md | head -n 1 | sed 's/PINNED `//; s/`$//')"
fi
case "$GODOT" in
  *Godot_v4.0*) echo "Refusing Godot 4.0 at $GODOT" >&2; exit 2 ;;
esac
if [[ ! -x "$GODOT" && ! -f "$GODOT" ]]; then
  echo "Godot executable not found: $GODOT" >&2
  exit 2
fi
echo "GODOT_BIN=$GODOT"
"$GODOT" --headless --path "$ROOT" --import
"$GODOT" --headless --path "$ROOT" --script res://tests/run_all.gd -- "$@"
PY=python3
if ! command -v python3 >/dev/null 2>&1; then
  PY=python
fi
"$PY" -m unittest discover -s tools/validate -p "test_*.py"
