"""Self-test for the standard-library schema checker."""

import json
import unittest
from pathlib import Path

from tools.validate.validate_all import check_data, validate_instance


ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests" / "assets"


class ValidateInstanceTests(unittest.TestCase):
    def test_good_fixture_passes(self) -> None:
        payload = json.loads((FIXTURE / "sample.json").read_text(encoding="utf-8"))
        schema = json.loads((FIXTURE / "sample.schema.json").read_text(encoding="utf-8"))
        self.assertEqual(validate_instance(payload, schema, "sample"), [])

    def test_bad_fixture_reports_path(self) -> None:
        payload = json.loads((FIXTURE / "sample_bad.json").read_text(encoding="utf-8"))
        schema = json.loads((FIXTURE / "sample.schema.json").read_text(encoding="utf-8"))
        errors = validate_instance(payload, schema, "sample_bad")
        self.assertTrue(any("ticks" in error for error in errors))
        self.assertTrue(any("name" in error for error in errors))

    def test_project_data_passes(self) -> None:
        self.assertEqual(check_data(), [])


if __name__ == "__main__":
    unittest.main()
