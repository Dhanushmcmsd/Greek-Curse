import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def check():
    errors=[]
    for path in (ROOT/'data/arenas').glob('*.json'):
        d=json.loads(path.read_text()); lo,hi=d['bounds']; a,b=d['safe_zone']; h=d['hazard']
        if not lo<=a<b<=hi: errors.append(str(path)+': invalid safe zone')
        if any(not a<=x<=b for x in d['spawn_x']): errors.append(str(path)+': spawn outside safe zone')
        if h['type']!='none':
            if h['telegraph_ticks']<90 or h['period']<=h['telegraph_ticks']+h['active_ticks']: errors.append(str(path)+': invalid timing')
            for x,y in h['zones']:
                if not lo<=x<y<=hi or (x<b and y>a): errors.append(str(path)+': unsafe hazard zone')
    return errors
if __name__=='__main__':
    errors=check();print(errors or 'ARENAS_VALID');raise SystemExit(bool(errors))
