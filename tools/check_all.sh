#!/usr/bin/env bash
# Linux/macOS one-screen check. Not executed on the Windows dev machine (UNVERIFIED there).
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
"$(dirname "$0")/run_tests.sh" "$@"
python3 tools/validate/validate_all.py
GODOT="${GODOT_BIN:-}"
if [[ -z "$GODOT" ]]; then
  GODOT="$(grep -o 'PINNED `[^`]*`' PROJECT_STATUS.md | head -n 1 | sed 's/PINNED `//; s/`$//')"
fi
case "$GODOT" in
  *Godot_v4.0*) echo "Refusing Godot 4.0" >&2; exit 2 ;;
esac
"$GODOT" --headless --path "$ROOT" --check-only --script res://tests/run_all.gd
"$GODOT" --headless --path "$ROOT" --check-only --script res://src/core/log.gd
if [[ -f tools/status/status_check.py ]]; then
  python3 tools/status/status_check.py
else
  echo "status_check.py: not present yet (stage 04)"
fi
echo "check_all: PASS"
