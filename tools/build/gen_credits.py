import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
text='Severed: Trials of Olympus\nOriginal generated art, audio and code.\nEngine: Godot (MIT). Authoring: Blender (GPL).\nDefault Godot font. No downloaded commercial character models.\n\n'
for name in ['docs/ASSET_LEDGER.md','THIRD_PARTY_LICENSES.md']:
 p=ROOT/name
 if p.exists():text+=p.read_text(encoding='utf-8')+'\n'
(ROOT/'data/ui/credits.json').write_text(json.dumps({'text':text},indent=2)+'\n',encoding='utf-8')
