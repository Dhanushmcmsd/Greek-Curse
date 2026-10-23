"""Check PROJECT_STATUS.md against the stage dependency map.

Standard library only. Expected problems print as status_check: lines and
exit 1. They do not print a traceback.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


REQUIRED_HEADINGS = (
    "Environment",
    "Current Stage",
    "Stage Table",
    "Completed Features",
    "Files and Systems Changed",
    "Tests (latest run)",
    "Known Bugs and Blockers",
    "Decisions Made",
    "Deferred / Proposed Work",
    "Owner Actions and Checkpoints",
    "Next Recommended Action",
    "Next Prompt Filename",
    "Session Log",
)

STATUSES = {"NOT_STARTED", "IN_PROGRESS", "COMPLETE", "PARTIAL", "BLOCKED"}

CHECKPOINTS = (
    ("A", "05"),
    ("B", "13"),
    ("C", "20"),
    ("D", "23"),
)

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


class StatusError(Exception):
    """A tracker problem the caller can print without a traceback."""


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    try:
        target = Path(args[0]) if args else ROOT / "PROJECT_STATUS.md"
        errors = check_file(target)
    except StatusError as exc:
        print(f"status_check: {exc}", file=sys.stderr)
        return 1
    if errors:
        for error in errors:
            print(f"status_check: {error}", file=sys.stderr)
        return 1
    print("status_check: PASS")
    return 0


def check_file(path: Path) -> list[str]:
    if not path.is_file():
        raise StatusError(f"tracker file not found: {path}")
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeError as exc:
        raise StatusError(f"tracker is not valid UTF-8: {path}: {exc}") from exc
    return check_text(text, path.parent if path.name == "PROJECT_STATUS.md" else ROOT)


def check_text(text: str, root: Path) -> list[str]:
    errors: list[str] = []
    sections = _sections(text)
    for heading in REQUIRED_HEADINGS:
        if heading not in sections:
            errors.append(f"missing heading '{heading}'")
    if errors:
        return errors
    rows = _stage_rows(sections["Stage Table"], errors)
    dependencies = _load_dependencies()
    known = {row["id"] for row in rows}
    for stage_id in dependencies:
        if stage_id not in known:
            errors.append(f"stage table is missing {stage_id}")
    for row in rows:
        if row["id"] not in dependencies:
            errors.append(f"stage {row['id']} is not in dependencies.json")
            continue
        if row["status"] not in STATUSES:
            errors.append(
                f"stage {row['id']} status '{row['status']}' is not one of "
                + ", ".join(sorted(STATUSES))
            )
            continue
        if row["status"] != "COMPLETE":
            continue
        _check_complete(row, rows, dependencies, root, errors)
    _check_next_prompt(sections["Next Prompt Filename"], root, errors)
    _check_checkpoints(sections["Owner Actions and Checkpoints"], rows, errors)
    return errors


def _check_complete(
    row: dict[str, str],
    rows: list[dict[str, str]],
    dependencies: dict[str, list[str]],
    root: Path,
    errors: list[str],
) -> None:
    by_id = {item["id"]: item for item in rows}
    for required in dependencies[row["id"]]:
        required_row = by_id.get(required)
        if required_row is None or required_row["status"] != "COMPLETE":
            errors.append(
                f"stage {row['id']} is COMPLETE but required stage {required} is not COMPLETE"
            )
    handoff = row["handoff"]
    if handoff == "":
        errors.append(f"stage {row['id']} is COMPLETE but has no handoff file")
        return
    if "\\" in handoff or handoff.startswith("/") or ".." in Path(handoff).parts:
        errors.append(f"stage {row['id']} handoff path is not a project-relative path")
        return
    if not (root / handoff).is_file():
        errors.append(f"stage {row['id']} handoff file does not exist: {handoff}")


def _check_next_prompt(body: str, root: Path, errors: list[str]) -> None:
    filename = ""
    for line in body.splitlines():
        stripped = line.strip().strip("`")
        if stripped:
            filename = stripped
            break
    if filename == "":
        errors.append("Next Prompt Filename is empty")
        return
    if "/" in filename or "\\" in filename:
        errors.append(f"Next Prompt Filename is not a file name: {filename}")
        return
    prompt = root / "Severed_Cursor_Prompt_Pack" / filename
    if not prompt.is_file():
        errors.append(f"next prompt does not exist: Severed_Cursor_Prompt_Pack/{filename}")


def _check_checkpoints(body: str, rows: list[dict[str, str]], errors: list[str]) -> None:
    by_id = {row["id"]: row["status"] for row in rows}
    for letter, stage_id in CHECKPOINTS:
        if by_id.get(stage_id) != "COMPLETE":
            continue
        if not _checkpoint_recorded(body, letter):
            errors.append(
                f"checkpoint {letter} is due because stage {stage_id} is COMPLETE, "
                "but Owner Actions and Checkpoints has no status for it"
            )


def _checkpoint_recorded(body: str, letter: str) -> bool:
    label = f"Checkpoint {letter}"
    for line in body.splitlines():
        cells = _cells(line)
        if len(cells) < 3:
            continue
        if cells[0] != label:
            continue
        return cells[2] != ""
    return False


def _stage_rows(body: str, errors: list[str]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for line in body.splitlines():
        cells = _cells(line)
        if len(cells) < 5:
            continue
        if cells[0] in {"ID", ""} or set(cells[0]) <= {"-"}:
            continue
        rows.append(
            {
                "id": cells[0],
                "name": cells[1],
                "status": cells[2],
                "updated": cells[3],
                "handoff": cells[4],
            }
        )
    if not rows:
        errors.append("stage table has no rows")
    return rows


def _cells(line: str) -> list[str]:
    if not line.strip().startswith("|"):
        return []
    parts = [part.strip() for part in line.strip().strip("|").split("|")]
    return parts


def _sections(text: str) -> dict[str, str]:
    found: dict[str, str] = {}
    lines = text.splitlines()
    current = ""
    bucket: list[str] = []
    for line in lines:
        if line.startswith("## "):
            if current:
                found[current] = "\n".join(bucket).strip("\n")
            current = line[3:].strip()
            bucket = []
            continue
        if current:
            bucket.append(line)
    if current:
        found[current] = "\n".join(bucket).strip("\n")
    return found


def _load_dependencies() -> dict[str, list[str]]:
    path = HERE / "dependencies.json"
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise StatusError(f"cannot read dependencies.json: {exc}") from exc
    if not isinstance(payload, dict):
        raise StatusError("dependencies.json must be an object")
    cleaned: dict[str, list[str]] = {}
    for key, value in payload.items():
        if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
            raise StatusError(f"dependencies for {key} must be a list of stage ids")
        cleaned[str(key)] = list(value)
    return cleaned


if __name__ == "__main__":
    sys.exit(main())
