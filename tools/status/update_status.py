"""Edit one PROJECT_STATUS.md section, or regenerate the handoff index.

Standard library only. Bad input prints update_status: and exits 1.
"""

from __future__ import annotations

import json
import re
import sys
from datetime import date, datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
STATUSES = {"NOT_STARTED", "IN_PROGRESS", "COMPLETE", "PARTIAL", "BLOCKED"}
PROMPT_NAME = re.compile(r"^[0-9]{2}[A-Z]?_[A-Za-z0-9_]+\.md$")


class StatusError(Exception):
    """Expected input or tracker problem."""


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    root = ROOT
    if args and args[0] == "--root":
        if len(args) < 2:
            print("update_status: --root needs a directory", file=sys.stderr)
            return 1
        root = Path(args[1])
        args = args[2:]
    try:
        if not args:
            raise StatusError(
                "usage: update_status.py [--root DIR] "
                "set-stage ID STATUS | log MESSAGE | record-tests PATH | "
                "next FILENAME | index"
            )
        command, rest = args[0], args[1:]
        if command == "set-stage":
            if len(rest) != 2:
                raise StatusError("usage: set-stage <id> <STATUS>")
            set_stage(root, rest[0], rest[1])
        elif command == "log":
            if len(rest) != 1:
                raise StatusError("usage: log <message>")
            log_message(root, rest[0])
        elif command == "record-tests":
            if len(rest) != 1:
                raise StatusError("usage: record-tests <path>")
            record_tests(root, Path(rest[0]))
        elif command == "next":
            if len(rest) != 1:
                raise StatusError("usage: next <filename>")
            set_next(root, rest[0])
        elif command == "index":
            if rest:
                raise StatusError("usage: index")
            write_index(root)
        else:
            raise StatusError(f"unknown command '{command}'")
    except StatusError as exc:
        print(f"update_status: {exc}", file=sys.stderr)
        return 1
    return 0


def set_stage(root: Path, stage_id: str, status: str) -> None:
    if status not in STATUSES:
        raise StatusError(f"status '{status}' is not one of {', '.join(sorted(STATUSES))}")
    path = _tracker(root)
    text = _read(path)
    row_pattern = re.compile(rf"(?m)^\| {re.escape(stage_id)} \|.*$")
    match = row_pattern.search(text)
    if match is None:
        raise StatusError(f"stage {stage_id} is not in the stage table")
    cells = [part.strip() for part in match.group(0).strip().strip("|").split("|")]
    if len(cells) < 5:
        raise StatusError(f"stage {stage_id} row does not have five columns")
    handoff = cells[4]
    if status == "COMPLETE" and handoff == "":
        handoff = _handoff_for(root, stage_id)
        if not (root / handoff).is_file():
            raise StatusError(f"write the handoff before marking {stage_id} COMPLETE: {handoff}")
    updated = date.today().isoformat()
    new_row = f"| {cells[0]} | {cells[1]} | {status} | {updated} | {handoff} |"
    text = text[: match.start()] + new_row + text[match.end() :]
    text = _replace_in_section(
        text,
        "Current Stage",
        r"(?m)^- Stage: .*$",
        f"- Stage: {stage_id} ({status})",
    )
    text = _replace_in_section(
        text,
        "Current Stage",
        r"(?m)^- Started / last updated: .*$",
        f"- Started / last updated: {updated}",
    )
    _write(path, text)


def log_message(root: Path, message: str) -> None:
    if message.strip() == "" or "|" in message or "\n" in message or "\r" in message:
        raise StatusError("log message must be one line and must not contain '|'")
    path = _tracker(root)
    text = _read(path)
    stage_id, result = _current_stage(text)
    row = f"| {date.today().isoformat()} | {stage_id} | {message.strip()} | {result} |"
    body_start, body_end = _section_body(text, "Session Log")
    body = text[body_start:body_end]
    lines = body.splitlines()
    last = -1
    for index, line in enumerate(lines):
        if line.startswith("|"):
            last = index
    if last < 0:
        raise StatusError("Session Log has no table row to append after")
    lines.insert(last + 1, row)
    newline = "\r\n" if "\r\n" in text else "\n"
    new_body = newline.join(lines)
    if body.endswith(("\n", "\r\n")):
        new_body += newline
    _write(path, text[:body_start] + new_body + text[body_end:])


def record_tests(root: Path, results_path: Path) -> None:
    if not results_path.is_file():
        raise StatusError(f"test results not found: {results_path}")
    try:
        payload = json.loads(results_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise StatusError(f"test results are not JSON: {exc}") from exc
    if not isinstance(payload, dict):
        raise StatusError("test results must be a JSON object")
    counts = []
    for key in ("passed", "failed", "skipped"):
        value = payload.get(key)
        if isinstance(value, bool) or not isinstance(value, int):
            raise StatusError(f"test results field '{key}' must be an integer")
        counts.append(f"{value} {key}")
    stamp = datetime.now().astimezone().isoformat(timespec="seconds")
    line = f"- Machine counts: {', '.join(counts)} ({stamp})."
    path = _tracker(root)
    text = _read(path)
    body_start, body_end = _section_body(text, "Tests (latest run)")
    body = text[body_start:body_end]
    pattern = re.compile(r"(?m)^- Machine counts: .*$")
    if pattern.search(body):
        body = pattern.sub(line, body, count=1)
    else:
        newline = "\r\n" if "\r\n" in text else "\n"
        body = line + newline + body
    _write(path, text[:body_start] + body + text[body_end:])


def set_next(root: Path, filename: str) -> None:
    if not PROMPT_NAME.match(filename):
        raise StatusError(f"not a prompt filename: {filename}")
    prompt = root / "Severed_Cursor_Prompt_Pack" / filename
    if not prompt.is_file():
        raise StatusError(f"next prompt does not exist: Severed_Cursor_Prompt_Pack/{filename}")
    path = _tracker(root)
    text = _read(path)
    body_start, body_end = _section_body(text, "Next Prompt Filename")
    body = text[body_start:body_end]
    lines = body.splitlines()
    replaced = False
    for index, line in enumerate(lines):
        if line.strip():
            lines[index] = filename
            replaced = True
            break
    if not replaced:
        lines = [filename]
    newline = "\r\n" if "\r\n" in text else "\n"
    new_body = newline.join(lines)
    if not new_body.endswith(("\n", "\r\n")):
        new_body += newline
    _write(path, text[:body_start] + new_body + text[body_end:])


def write_index(root: Path) -> None:
    handoff = root / "docs" / "handoff"
    if not handoff.is_dir():
        raise StatusError(f"handoff directory not found: {handoff}")
    files = sorted(
        path
        for path in handoff.glob("*.md")
        if path.name not in {"INDEX.md", "_TEMPLATE.md"}
    )
    lines = [
        "# Handoff index",
        "",
        "Generated by `python tools/status/update_status.py index`. "
        "Edit the handoff files, then regenerate this list.",
        "",
        "| File | Title |",
        "|---|---|",
    ]
    for path in files:
        title = _first_heading(path).replace("|", "/")
        lines.append(f"| docs/handoff/{path.name} | {title} |")
    lines.extend(["", "Template: `docs/handoff/_TEMPLATE.md`.", ""])
    index = handoff / "INDEX.md"
    index.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(f"update_status: wrote {index}")


def _handoff_for(root: Path, stage_id: str) -> str:
    index = root / "Severed_Cursor_Prompt_Pack" / "PROMPT_INDEX.md"
    if not index.is_file():
        raise StatusError("PROMPT_INDEX.md is missing, so the handoff path cannot be derived")
    text = index.read_text(encoding="utf-8")
    match = re.search(rf"(?m)^\| {re.escape(stage_id)} \| `([^`]+)` \|", text)
    if match is None:
        raise StatusError(f"stage {stage_id} is not listed in PROMPT_INDEX.md")
    return f"docs/handoff/{match.group(1)}"


def _current_stage(text: str) -> tuple[str, str]:
    body_start, body_end = _section_body(text, "Current Stage")
    body = text[body_start:body_end]
    match = re.search(r"(?m)^- Stage: ([0-9]{2}[A-Z]?) \(([A-Z_]+)\)\s*$", body)
    if match is None:
        raise StatusError("Current Stage does not contain '- Stage: <id> (<STATUS>)'")
    return match.group(1), match.group(2)


def _replace_in_section(text: str, heading: str, pattern: str, replacement: str) -> str:
    body_start, body_end = _section_body(text, heading)
    body = text[body_start:body_end]
    new_body, count = re.subn(pattern, replacement, body, count=1)
    if count != 1:
        raise StatusError(f"section '{heading}' has no line matching {pattern}")
    return text[:body_start] + new_body + text[body_end:]


def _section_body(text: str, heading: str) -> tuple[int, int]:
    matches = list(re.finditer(r"(?m)^## (.+)$", text))
    for index, match in enumerate(matches):
        if match.group(1).strip() != heading:
            continue
        body_start = match.end()
        if text[body_start : body_start + 2] == "\r\n":
            body_start += 2
        elif text[body_start : body_start + 1] == "\n":
            body_start += 1
        body_end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        return body_start, body_end
    raise StatusError(f"missing heading '{heading}'")


def _first_heading(path: Path) -> str:
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return path.stem


def _tracker(root: Path) -> Path:
    path = root / "PROJECT_STATUS.md"
    if not path.is_file():
        raise StatusError(f"tracker file not found: {path}")
    return path


def _read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeError as exc:
        raise StatusError(f"tracker is not valid UTF-8: {path}: {exc}") from exc


def _write(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8", newline="")


if __name__ == "__main__":
    sys.exit(main())
