"""Lossless GLB packaging regression."""
import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('glb_images', Path(__file__).parents[1] / 'blender/externalize_glb_images.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PackagingTests(unittest.TestCase):
    def test_image_extraction_preserves_vertex_bytes_and_view_references(self):
        doc = {'asset': {'version': '2.0'}, 'buffers': [{'byteLength': 12}],
               'bufferViews': [{'buffer': 0, 'byteOffset': 0, 'byteLength': 4},
                               {'buffer': 0, 'byteOffset': 4, 'byteLength': 8}],
               'images': [{'bufferView': 0, 'mimeType': 'image/png'}],
               'accessors': [{'bufferView': 1, 'componentType': 5126, 'count': 2, 'type': 'SCALAR'}]}
        encoded = json.dumps(doc).encode()
        encoded += b' ' * (-len(encoded) % 4)
        vertices = struct.pack('<2f', 1.5, -3.25)
        payload = b'PNG!' + vertices
        raw = (struct.pack('<4sII', b'glTF', 2, 28 + len(encoded) + len(payload))
               + struct.pack('<I4s', len(encoded), b'JSON') + encoded
               + struct.pack('<I4s', len(payload), b'BIN\0') + payload)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'fighter.glb'
            path.write_bytes(raw)
            module.externalize_large_glb(path, limit=1)
            result = path.read_bytes()
            size = struct.unpack_from('<I', result, 12)[0]
            actual = json.loads(result[20:20 + size])
            self.assertEqual(actual['accessors'][0]['bufferView'], 0)
            self.assertEqual(result[28 + size:], vertices)
            self.assertEqual(path.with_name(actual['images'][0]['uri']).read_bytes(), b'PNG!')
            self.assertEqual(struct.unpack_from('<I', result, 8)[0], len(result))
            before = path.read_bytes()
            module.externalize_large_glb(path)
            self.assertEqual(path.read_bytes(), before)
