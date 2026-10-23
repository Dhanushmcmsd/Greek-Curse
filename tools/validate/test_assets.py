import copy
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from tools.validate.glb_inspect import inspect
from tools.validate.validate_assets import ROOT, validate_asset


class AssetTests(unittest.TestCase):
    def setUp(self):
        self.records = json.loads((ROOT / "assets/generated/manifest.json").read_text())["assets"]
        self.record = next(r for r in self.records if r["id"] == "fighter_theron")
        self.path = ROOT / self.record["path"]

    def test_real_asset_and_negative_contracts(self):
        self.assertEqual(validate_asset(self.path, self.record), [])
        for change, expected in [({"budget": 1}, "triangle budget exceeded"),
                                 ({"sha256": "wrong"}, "hash mismatch"),
                                 ({"required_nodes": ["MISSING_SOCKET"]}, "missing node MISSING_SOCKET")]:
            record = self.record | change
            self.assertIn(expected, validate_asset(self.path, record))

    def test_malformed_glb(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "bad.glb"
            path.write_bytes(b"bad")
            with self.assertRaises(ValueError):
                inspect(path)

    def test_pipeline_socket_and_vertex_colors(self):
        info = inspect(ROOT / "assets/generated/models/pipeline_test.glb")
        self.assertIn("SOCKET_TEST", info["nodes"])
        self.assertTrue(info["vertex_colors"])


if __name__ == "__main__":
    unittest.main()
