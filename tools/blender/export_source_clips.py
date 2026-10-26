"""Export the original animated Mixamo hierarchy, without reducing it to 15 joints."""
import hashlib
import json
from pathlib import Path
import sys
import bpy

ROOT = Path(__file__).resolve().parents[2]


def export_source_clips():
    cfg = json.loads((ROOT / 'tools/blender/mixamo_paths.json').read_text())
    source_dir = Path(cfg['animation_dir'])
    manifest = json.loads((ROOT / 'assets/fighters_mixamo/anims/mixamo_anims_manifest.json').read_text())
    out = ROOT / 'assets/fighters_mixamo/source_anims'
    out.mkdir(parents=True, exist_ok=True)
    exported = {}
    for clip_id, row in manifest['clips'].items():
        source = source_dir / row['source_file']
        if not source.exists():
            raise FileNotFoundError(source)
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.fbx(filepath=str(source))
        arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
        action = arm.animation_data.action
        first, last = action.curve_frame_range
        bpy.context.scene.frame_start = int(first)
        bpy.context.scene.frame_end = int(last)
        action.name = clip_id
        arm.name = 'Skeleton'
        for obj in list(bpy.data.objects):
            if obj != arm:
                bpy.data.objects.remove(obj, do_unlink=True)
        bpy.ops.object.select_all(action='DESELECT')
        arm.select_set(True)
        bpy.context.view_layer.objects.active = arm
        path = out / (clip_id + '.glb')
        bpy.ops.export_scene.gltf(filepath=str(path), use_selection=True,
            export_format='GLB', export_yup=True, export_skins=True,
            export_animations=True, export_force_sampling=True,
            export_optimize_animation_size=False)
        exported[clip_id] = {'source_file': row['source_file'],
            'bones': len(arm.data.bones), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    (out / 'manifest.json').write_text(json.dumps({'clips': exported}, indent=2) + '\n')
    print('FULL_SOURCE_CLIPS_EXPORTED', len(exported))


if __name__ == '__main__':
    export_source_clips()
