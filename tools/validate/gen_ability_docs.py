import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
rows=['# Abilities','', 'Generated from data/abilities. Loadouts: two light, two heavy, two kick, one superpower, passive and ultimate. U activates superpower; I ultimate; forward+attack selects B (down+kick selects B). Ultimate startup is 42 ticks. Buffs refresh by kind, never stack with themselves. Cooldowns use absolute simulation ticks, including hit-stop.','']
for p in sorted((ROOT/'data/abilities').glob('*.json')):
 d=json.loads(p.read_text());rows += ['## '+d['name'],d['description'],f"Type: {d['type']}; cooldown {d['cooldown_ticks']} ticks; stamina {d['stamina_cost']}; meter {d['meter_cost']}.",'Effects: '+json.dumps(d['effects']), '']
(ROOT/'docs/ABILITIES.md').write_text('\n'.join(rows),encoding='utf-8')
