import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]


class LimbDataTests(unittest.TestCase):
    def test_every_effect_has_a_visible_tooltip(self):
        rows = list((ROOT / "data/limbs").glob("*.json"))
        self.assertEqual(len(rows), 5)
        for path in rows:
            row = json.loads(path.read_text())
            for key, value in row["modifiers"].items():
                self.assertIsInstance(value, int)
                self.assertIn(key, row["tooltip_lines"], f"hidden effect {path}/{key}")
                self.assertTrue(row["tooltip_lines"][key].strip())
            self.assertEqual(row["integrity_pct"], 80)
            self.assertIn(row["slot"], ["arm", "leg"])

    def test_all_attachment_rest_bounds(self):
        from tools.validate.validate_attachments import check
        errors, cases = check()
        self.assertEqual(cases, 40)
        self.assertEqual(errors, [])
