"""JSON syntax and a small schema check for files under data/.

Schemas live in data/schema/<same relative path>.schema.json.
Supported keys: type, required, properties, enum, minimum, maximum, items.
Standard library only.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"


def _type_ok(value: object, expected: str) -> bool:
    if expected == "object":
        return isinstance(value, dict)
    if expected == "array":
        return isinstance(value, list)
    if expected == "string":
        return isinstance(value, str)
    if expected == "boolean":
        return isinstance(value, bool)
    if expected == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if expected == "number":
        return isinstance(value, (int, float)) and not isinstance(value, bool)
    return False


def validate_instance(value: object, schema: dict, path: str) -> list[str]:
    errors: list[str] = []
    expected = schema.get("type")
    if expected is not None and not _type_ok(value, expected):
        errors.append(f"{path}: expected {expected}")
        return errors
    if "enum" in schema and value not in schema["enum"]:
        errors.append(f"{path}: value {value!r} is not in enum {schema['enum']!r}")
    if expected in ("integer", "number") and isinstance(value, (int, float)) and not isinstance(value, bool):
        if "minimum" in schema and value < schema["minimum"]:
            errors.append(f"{path}: {value} is below minimum {schema['minimum']}")
        if "maximum" in schema and value > schema["maximum"]:
            errors.append(f"{path}: {value} is above maximum {schema['maximum']}")
    if expected == "object" and isinstance(value, dict):
        for key in schema.get("required", []):
            if key not in value:
                errors.append(f"{path}/{key}: missing required property")
        for key, sub in schema.get("properties", {}).items():
            if key in value:
                errors.extend(validate_instance(value[key], sub, f"{path}/{key}"))
    if expected == "array" and isinstance(value, list) and "items" in schema:
        for index, item in enumerate(value):
            errors.extend(validate_instance(item, schema["items"], f"{path}/{index}"))
    return errors


def schema_for(data_file: Path) -> Path | None:
    relative = data_file.relative_to(DATA)
    candidate = DATA / "schema" / relative.parent / f"{relative.stem}.schema.json"
    if candidate.is_file():
        return candidate
    return None


def check_data(data_root: Path = DATA) -> list[str]:
    errors: list[str] = []
    if not data_root.is_dir():
        return [f"{data_root}: data directory is missing"]
    for path in sorted(data_root.rglob("*.json")):
        if "schema" in path.relative_to(data_root).parts:
            continue
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            errors.append(f"{path}: invalid JSON ({exc})")
            continue
        schema_path = schema_for(path)
        if schema_path is None:
            continue
        try:
            schema = json.loads(schema_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            errors.append(f"{schema_path}: invalid schema JSON ({exc})")
            continue
        errors.extend(validate_instance(payload, schema, str(path)))
    return errors


def main() -> int:
    errors = check_data()
    if errors:
        print(f"validate_all: {len(errors)} error(s)")
        for error in errors:
            print(error)
        return 1
    print("validate_all: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
