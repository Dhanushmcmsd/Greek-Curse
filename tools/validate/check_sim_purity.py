"""Fail src/sim scripts that could break the integer, deterministic combat rules.

A line containing `# sim-purity-ok: <reason>` is ignored. Review every such line
in the stage handoff. There is no allow-list file.
"""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SIM_ROOT = ROOT / "src" / "sim"

_TOKEN_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"\brandf\b"), "randf"),
    (re.compile(r"\brandi\b"), "randi"),
    (re.compile(r"\brandomize\b"), "randomize"),
    (re.compile(r"\bTime\."), "Time."),
    (re.compile(r"\bOS\."), "OS."),
    (re.compile(r"\bEngine\."), "Engine."),
    (re.compile(r"\bget_node\b"), "get_node"),
    (re.compile(r"\bget_tree\b"), "get_tree"),
    (re.compile(r"\bPhysicsServer\b"), "PhysicsServer"),
    (re.compile(r"\bRigidBody"), "RigidBody"),
    (re.compile(r"\bCharacterBody"), "CharacterBody"),
    (re.compile(r"\bArea3D\b"), "Area3D"),
    (re.compile(r"\bHTTPRequest\b"), "HTTPRequest"),
    (re.compile(r"\bENet"), "ENet"),
    (re.compile(r"\bWebSocket"), "WebSocket"),
    (re.compile(r"\d+\.\d+"), "float literal"),
    (re.compile(r"\bfloat\b"), "float type"),
    (re.compile(r"\bVector2\s*\("), "Vector2("),
    (re.compile(r"\bVector3\s*\("), "Vector3("),
    (
        re.compile(
            r"\bextends\s+(Node2D|Node3D|Node|Control|CanvasItem|RigidBody\w*|CharacterBody\w*|Area3D)\b"
        ),
        "Node inheritance",
    ),
]

_ALLOW = "# sim-purity-ok:"


def scan_text(path: str, text: str) -> list[str]:
    errors: list[str] = []
    for line_number, line in enumerate(text.splitlines(), start=1):
        if _ALLOW in line:
            continue
        for pattern, label in _TOKEN_PATTERNS:
            if pattern.search(line):
                errors.append(f"{path}:{line_number}: forbidden {label}")
    return errors


def check_sim(sim_root: Path = SIM_ROOT) -> list[str]:
    if not sim_root.is_dir():
        return [f"{sim_root}: sim directory is missing"]
    errors: list[str] = []
    files = sorted(sim_root.rglob("*.gd"))
    if not files:
        return [f"{sim_root}: no GDScript files to check"]
    for path in files:
        errors.extend(scan_text(str(path), path.read_text(encoding="utf-8")))
    return errors
