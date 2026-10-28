import importlib.util
import pathlib
import struct
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('exported_psa', ROOT / 'tools/anim/read_exported_psa.py')
psa = importlib.util.module_from_spec(spec)
spec.loader.exec_module(psa)


def chunk(name, size, count, payload=b''):
    return struct.pack('<20siii', name.encode(), 0, size, count) + payload


class ExportedMotionReaderTests(unittest.TestCase):
    def test_rejects_truncated_chunk(self):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / 'bad.psa'
            path.write_bytes(chunk('BONENAMES', 120, 1, b'bad'))
            with self.assertRaisesRegex(ValueError, 'chunk extent'):
                psa.read_psa(path)

    def test_preserves_rate_frames_and_quaternion_samples(self):
        bone = struct.pack('<64siii4f3ff3f', b'Hips', 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1)
        info = b'Punch'.ljust(128, b'\0') + struct.pack('<iiiifffiii', 1, 0, 0, 2, 0, 2, 60, 0, 0, 2)
        key = struct.pack('<3f4ff', 0, 0, 0, 0, 0, 0, 1, 1/60)
        raw = chunk('ANIMHEAD', 0, 0) + chunk('BONENAMES',120,1,bone) + chunk('ANIMINFO',168,1,info) + chunk('ANIMKEYS',32,2,key*2)
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / 'punch.psa'
            path.write_bytes(raw)
            result = psa.read_psa(path)
            self.assertEqual(result['fps'], 60)
            self.assertEqual(result['frames'], 2)
            self.assertEqual(result['rotations'][1][0], (0,0,0,1))
            self.assertEqual(result['bones'][0]['parent'], -1)

    def test_rejects_nonfinite_animation(self):
        bone = struct.pack('<64siii4f3ff3f', b'Hips', 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1)
        info = b'Punch'.ljust(128, b'\0') + struct.pack('<iiiifffiii', 1, 0, 0, 1, 0, 1, 60, 0, 0, 1)
        key = struct.pack('<3f4ff', 0, 0, 0, float('nan'), 0, 0, 1, 1/60)
        raw = chunk('BONENAMES',120,1,bone) + chunk('ANIMINFO',168,1,info) + chunk('ANIMKEYS',32,1,key)
        with tempfile.TemporaryDirectory() as directory:
            path=pathlib.Path(directory)/'bad.psa';path.write_bytes(raw)
            with self.assertRaisesRegex(ValueError, 'Nonfinite'):
                psa.read_psa(path)
