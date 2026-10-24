import math, json
from generate_sfx import ROOT,RATE,write
NAMES=['menu','mount_olympus','athens_colosseum','tartarus_pits','win','loss']
def main():
    manifest={}
    for index,name in enumerate(NAMES):
        duration=32 if index<4 else 4
        notes=[0,2,3,5,7,9,10,12] if index%2==0 else [0,1,3,5,7,8,10,12]
        samples=[]
        for i in range(RATE*duration):
            t=i/RATE;beat=int(t*2);phase=t*.5%1
            note=notes[(beat//2+index)%len(notes)];freq=110*2**(note/12)
            env=math.sin(math.pi*((t*2)%1))**2
            edge=min(1,t/.05,(duration-t)/.05)
            samples.append(edge*(.2*math.sin(math.tau*freq*t)*env+.1*math.sin(math.tau*55*t)*math.sin(math.pi*phase)**2))
        manifest[name]=write(ROOT/'assets/audio/music'/f'{name}.wav',samples)
    (ROOT/'assets/audio/music/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
if __name__=='__main__':main()
