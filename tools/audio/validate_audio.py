import json, struct, wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def check():
    errors=[];total=0
    for path in (ROOT/'assets/audio').rglob('*.wav'):
        total+=path.stat().st_size
        with wave.open(str(path)) as f: samples=struct.unpack('<%dh'%f.getnframes(),f.readframes(f.getnframes()))
        peak=max(abs(x) for x in samples)/32768
        if not 0<peak<.8913:errors.append(str(path)+': peak')
        if path.parent.name=='music' and abs(samples[0]-samples[-1])/32768>.01:errors.append(str(path)+': seam')
    for name in json.loads((ROOT/'data/audio/event_map.json').read_text()).values():
        if not (ROOT/'assets/audio/sfx'/f'{name}.wav').is_file():errors.append(name+': missing')
    if total>25_000_000:errors.append('audio budget exceeded')
    return errors
if __name__=='__main__':
    errors=check();print(errors or 'AUDIO_VALID');raise SystemExit(bool(errors))
