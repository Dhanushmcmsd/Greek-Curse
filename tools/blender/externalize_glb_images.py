"""Keep large GLBs below GitHub's file limit without recompressing textures."""
import json
from pathlib import Path
import struct


def externalize_large_glb(path: Path, limit=95 * 1024 * 1024):
    if path.stat().st_size < limit:
        return
    raw = path.read_bytes()
    json_size = struct.unpack_from('<I', raw, 12)[0]
    doc = json.loads(raw[20:20 + json_size])
    binary = raw[28 + json_size:]
    image_views = set()
    for index, image in enumerate(doc.get('images', [])):
        if 'bufferView' not in image:
            continue
        view_index = image.pop('bufferView')
        view = doc['bufferViews'][view_index]
        suffix = '.png' if image['mimeType'] == 'image/png' else '.jpg'
        name = f'{path.stem}_texture_{index:02d}{suffix}'
        offset = view.get('byteOffset', 0)
        path.with_name(name).write_bytes(binary[offset:offset + view['byteLength']])
        image['uri'] = name
        image_views.add(view_index)
    retained = []
    remap = {}
    payload = bytearray()
    for index, view in enumerate(doc['bufferViews']):
        if index in image_views:
            continue
        remap[index] = len(retained)
        offset = view.get('byteOffset', 0)
        data = binary[offset:offset + view['byteLength']]
        view['byteOffset'] = len(payload)
        payload.extend(data)
        payload.extend(b'\0' * (-len(payload) % 4))
        retained.append(view)
    for accessor in doc.get('accessors', []):
        if 'bufferView' in accessor:
            accessor['bufferView'] = remap[accessor['bufferView']]
        for value in accessor.get('sparse', {}).values():
            if isinstance(value, dict) and 'bufferView' in value:
                value['bufferView'] = remap[value['bufferView']]
    doc['bufferViews'] = retained
    doc['buffers'][0]['byteLength'] = len(payload)
    encoded = json.dumps(doc, separators=(',', ':')).encode()
    encoded += b' ' * (-len(encoded) % 4)
    result = (struct.pack('<4sII', b'glTF', 2, 28 + len(encoded) + len(payload))
              + struct.pack('<I4s', len(encoded), b'JSON') + encoded
              + struct.pack('<I4s', len(payload), b'BIN\0') + payload)
    path.write_bytes(result)


if __name__ == '__main__':
    import sys
    externalize_large_glb(Path(sys.argv[1]))
