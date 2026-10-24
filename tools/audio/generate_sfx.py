"""Deterministic original placeholder synthesis; Python standard library only."""
import json, math, random, struct, wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
RATE=22050
NAMES=['light_bone','heavy_bone','light_flesh','heavy_flesh','light_stone','heavy_stone','light_bronze','heavy_bronze','whoosh','block','dodge','grab','limb_crack','sever','squelch','chunk_bounce','lightning','lava','ui_click','ui_confirm','ui_back','stamina_empty','ultimate_ready','round_bell','ko']
def write(path,samples):
    path.parent.mkdir(parents=True,exist_ok=True)
    peak=max(abs(x) for x in samples)
    samples=[int(x/max(peak,1)*24000) for x in samples]
    with wave.open(str(path),'wb') as f:
        f.setparams((1,2,RATE,len(samples),'NONE','not compressed'));f.writeframes(struct.pack('<%dh'%len(samples),*samples))
    return {'sample_rate':RATE,'seconds':len(samples)/RATE,'peak':max(abs(x) for x in samples)/32768}
def main():
    manifest={}
    for index,name in enumerate(NAMES):
        rng=random.Random(1701+index);duration=.55 if name in ['sever','lightning','ko'] else .22
        samples=[]
        for i in range(int(RATE*duration)):
            t=i/RATE; envelope=math.sin(math.pi*t/duration)**2*math.exp(-t*8)
            frequency=95+index*23
            samples.append(envelope*(math.sin(math.tau*frequency*t)*.5+rng.uniform(-1,1)*(.7 if index<18 else .15)))
        manifest[name]=write(ROOT/'assets/audio/sfx'/f'{name}.wav',samples)
    (ROOT/'assets/audio/sfx/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
if __name__=='__main__':main()
