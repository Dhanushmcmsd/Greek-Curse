"""Tracker checker and surgical editor tests. Standard library only."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from tools.status.status_check import REQUIRED_HEADINGS, check_file, check_text
from tools.status.update_status import main as update_main


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


def _stage_ids() -> list[str]:
    payload = json.loads((HERE / "dependencies.json").read_text(encoding="utf-8"))
    return list(payload)


def _tracker(stages: dict[str, tuple[str, str]] | None = None, next_name: str = "01_PROJECT_AUDIT_AND_TECHNICAL_PLAN.md") -> str:
    chosen = stages or {"00": ("COMPLETE", "docs/handoff/00_README_AND_EXECUTION_GUIDE.md")}
    rows = ["| ID | Stage | Status | Last updated | Handoff file |", "|---|---|---|---|---|"]
    for stage_id in _stage_ids():
        status, handoff = chosen.get(stage_id, ("NOT_STARTED", ""))
        rows.append(f"| {stage_id} | Stage {stage_id} | {status} | 2026-01-01 | {handoff} |")
    sections = {
        "Environment": "- OS: keep-me",
        "Current Stage": "- Stage: 00 (COMPLETE)\n- Started / last updated: 2026-01-01\n- Note: owner note stays",
        "Stage Table": "\n".join(rows),
        "Completed Features": "- none",
        "Files and Systems Changed": "- none",
        "Tests (latest run)": "- Passed / failed / skipped: historical note stays",
        "Known Bugs and Blockers": "- none",
        "Decisions Made": "- keep-decision",
        "Deferred / Proposed Work": "- none",
        "Owner Actions and Checkpoints": "\n".join(
            [
                "| Item | When | Status | Evidence returned |",
                "|---|---|---|---|",
                "| Checkpoint A | after 05 | PENDING | |",
                "| Checkpoint B | after 13 | PENDING | |",
                "| Checkpoint C | after 20 | PENDING | |",
                "| Checkpoint D | after 23 | PENDING | |",
            ]
        ),
        "Next Recommended Action": "Stay on this stage.",
        "Next Prompt Filename": next_name,
        "Session Log": "\n".join(
            [
                "| Date | Stage | Summary | Result |",
                "|---|---|---|---|",
                "| 2026-01-01 | 00 | started | COMPLETE |",
            ]
        ),
    }
    parts = ["# Tracker", ""]
    for heading in REQUIRED_HEADINGS:
        parts.append(f"## {heading}")
        parts.append(sections[heading])
        parts.append("")
    return "\n".join(parts)


class StatusCheckTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.pack = self.root / "Severed_Cursor_Prompt_Pack"
        self.pack.mkdir()
        (self.pack / "01_PROJECT_AUDIT_AND_TECHNICAL_PLAN.md").write_text("prompt", encoding="utf-8")
        (self.pack / "PROMPT_INDEX.md").write_text(
            "| 00 | `00_README_AND_EXECUTION_GUIDE.md` | docs | - |\n",
            encoding="utf-8",
        )
        handoff = self.root / "docs" / "handoff"
        handoff.mkdir(parents=True)
        (handoff / "00_README_AND_EXECUTION_GUIDE.md").write_text("# Stage 00\n", encoding="utf-8")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_valid_tracker_passes(self) -> None:
        self.assertEqual(check_text(_tracker(), self.root), [])

    def test_missing_heading_fails(self) -> None:
        text = _tracker().replace("## Decisions Made\n", "")
        errors = check_text(text, self.root)
        self.assertTrue(any("missing heading 'Decisions Made'" in error for error in errors))

    def test_complete_stage_without_handoff_fails(self) -> None:
        text = _tracker({"00": ("COMPLETE", "")})
        errors = check_text(text, self.root)
        self.assertTrue(any("no handoff file" in error for error in errors))

    def test_complete_stage_with_incomplete_dependency_fails(self) -> None:
        handoff = "docs/handoff/02_PROJECT_SCAFFOLD_AND_DEVELOPMENT_TOOLS.md"
        (self.root / handoff).parent.mkdir(parents=True, exist_ok=True)
        (self.root / handoff).write_text("# Stage 02\n", encoding="utf-8")
        text = _tracker({"02": ("COMPLETE", handoff)})
        errors = check_text(text, self.root)
        self.assertTrue(any("required stage 01 is not COMPLETE" in error for error in errors))

    def test_missing_next_prompt_fails(self) -> None:
        text = _tracker(next_name="99_NOT_A_REAL_PROMPT.md")
        errors = check_text(text, self.root)
        self.assertTrue(any("next prompt does not exist" in error for error in errors))

    def test_due_checkpoint_must_be_recorded(self) -> None:
        stages = {}
        for stage_id in _stage_ids():
            if stage_id in {"00", "01", "02", "03", "04", "05"}:
                name = f"docs/handoff/{stage_id}_example.md"
                (self.root / name).parent.mkdir(parents=True, exist_ok=True)
                (self.root / name).write_text("# x\n", encoding="utf-8")
                stages[stage_id] = ("COMPLETE", name)
        text = _tracker(stages)
        text = text.replace("| Checkpoint A | after 05 | PENDING | |\n", "")
        errors = check_text(text, self.root)
        self.assertTrue(any("checkpoint A is due" in error for error in errors))

    def test_missing_file_has_no_traceback_message(self) -> None:
        with self.assertRaises(Exception) as caught:
            check_file(self.root / "PROJECT_STATUS.md")
        self.assertIn("not found", str(caught.exception))


class UpdateStatusTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        pack = self.root / "Severed_Cursor_Prompt_Pack"
        pack.mkdir()
        (pack / "PROMPT_INDEX.md").write_text(
            "| 00 | `00_README_AND_EXECUTION_GUIDE.md` | docs | - |\n"
            "| 01 | `01_PROJECT_AUDIT_AND_TECHNICAL_PLAN.md` | docs | 00 |\n",
            encoding="utf-8",
        )
        (pack / "01_PROJECT_AUDIT_AND_TECHNICAL_PLAN.md").write_text("prompt", encoding="utf-8")
        handoff = self.root / "docs" / "handoff"
        handoff.mkdir(parents=True)
        (handoff / "00_README_AND_EXECUTION_GUIDE.md").write_text("# Stage 00 handoff\n", encoding="utf-8")
        (self.root / "PROJECT_STATUS.md").write_text(_tracker(), encoding="utf-8")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def _run(self, *args: str) -> int:
        return update_main(["--root", str(self.root), *args])

    def _text(self) -> str:
        return (self.root / "PROJECT_STATUS.md").read_text(encoding="utf-8")

    def test_round_trip_preserves_untouched_sections(self) -> None:
        before = self._text()
        self.assertEqual(self._run("set-stage", "00", "COMPLETE"), 0)
        after = self._text()
        self.assertIn("- OS: keep-me", after)
        self.assertIn("- keep-decision", after)
        self.assertIn("- Note: owner note stays", after)
        self.assertIn("| 00 | Stage 00 | COMPLETE |", after)
        self.assertEqual(_between(before, "Environment"), _between(after, "Environment"))
        self.assertEqual(_between(before, "Decisions Made"), _between(after, "Decisions Made"))

    def test_record_tests_and_log_and_next_keep_environment(self) -> None:
        results = self.root / "results.json"
        results.write_text(json.dumps({"passed": 2, "failed": 1, "skipped": 0}), encoding="utf-8")
        before = self._text()
        self.assertEqual(self._run("record-tests", str(results)), 0)
        self.assertEqual(self._run("log", "checked the tracker"), 0)
        self.assertEqual(self._run("next", "01_PROJECT_AUDIT_AND_TECHNICAL_PLAN.md"), 0)
        after = self._text()
        self.assertEqual(_between(before, "Environment"), _between(after, "Environment"))
        self.assertIn("2 passed, 1 failed, 0 skipped", after)
        self.assertIn("historical note stays", after)
        self.assertIn("checked the tracker", after)
        self.assertIn("01_PROJECT_AUDIT_AND_TECHNICAL_PLAN.md", after)

    def test_bad_command_does_not_raise(self) -> None:
        self.assertEqual(self._run("set-stage", "00", "SHIPPED"), 1)

    def test_index_lists_handoff_and_not_the_template(self) -> None:
        (self.root / "docs" / "handoff" / "_TEMPLATE.md").write_text("# Template\n", encoding="utf-8")
        self.assertEqual(self._run("index"), 0)
        index = (self.root / "docs" / "handoff" / "INDEX.md").read_text(encoding="utf-8")
        self.assertIn("00_README_AND_EXECUTION_GUIDE.md", index)
        self.assertIn("Template: `docs/handoff/_TEMPLATE.md`.", index)
        self.assertNotIn("| docs/handoff/_TEMPLATE.md |", index)

    def test_dependencies_match_the_prompt_pack(self) -> None:
        pack = (ROOT / "Severed_Cursor_Prompt_Pack" / "PROMPT_INDEX.md").read_text(encoding="utf-8")
        start = pack.index("```json") + len("```json")
        end = pack.index("```", start)
        packed = json.loads(pack[start:end])
        local = json.loads((HERE / "dependencies.json").read_text(encoding="utf-8"))
        self.assertEqual(local, packed)


def _between(text: str, heading: str) -> str:
    start = text.index(f"## {heading}\n")
    rest = text[start + len(f"## {heading}\n") :]
    next_heading = rest.index("\n## ")
    return rest[:next_heading]


if __name__ == "__main__":
    unittest.main()
