"""Validate pose references, finite rotations and per-bone joint limits."""
import json
import math
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]


def validate(data, moves):
 errors = []
 for name, pose in data['poses'].items():
  for bone, angles in pose['bones'].items():
   if bone not in data['bones']:
    errors.append(name + ': unknown bone ' + bone)
    continue
   limits = data['joint_limits'][bone]
   if len(angles) != 3 or any(not isinstance(v, (int,float)) or not math.isfinite(v) or not limits[0] <= v <= limits[1] for v in angles):
    errors.append(name + ': invalid angles ' + bone)
 for name, phases in data['sets'].items():
  for phase in ['startup','active','recovery']:
   if phases.get(phase) not in data['poses']: errors.append(name + ': missing phase ' + phase)
 for name in data['walk']:
  if name not in data['poses']: errors.append('missing walk pose ' + name)
 for move in moves:
  if move.get('anim_set') not in data['sets']: errors.append(move['id'] + ': missing anim_set')
 return errors


def check():
 data = json.loads((ROOT/'data/animation/poses.json').read_text())
 moves = [json.loads(p.read_text()) for p in (ROOT/'data/moves').glob('*.json')]
 errors = validate(data,moves)
 from tools.validate.glb_inspect import inspect
 for fighter in ['theron','atalanta','pyrrhus','sibyl']:
  actual=inspect(ROOT / f'assets/generated/models/fighter_{fighter}.glb')['nodes']
  for bone in data['bones']:
   if bone not in actual: errors.append(fighter + ': missing generated bone ' + bone)
 return errors


if __name__ == '__main__':
 import sys
 sys.path.insert(0,str(ROOT))
 errors=check()
 print('POSES_OK' if not errors else '\n'.join(errors))
 raise SystemExit(bool(errors))
