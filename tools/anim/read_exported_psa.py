"""Read bounded ActorX chunks; emit an intermediate for the Godot retarget tool."""
import argparse, collections, hashlib, json, math, pathlib, struct

def read_psa(path):
    raw=path.read_bytes(); offset=0; chunks={}
    while offset+32<=len(raw):
        tag,_,size,count=struct.unpack_from('<20siii',raw,offset); offset+=32
        if size<0 or count<0 or offset+size*count>len(raw): raise ValueError('Invalid chunk extent')
        chunks[tag.rstrip(b'\0').decode()]=(size,count,raw[offset:offset+size*count]);offset+=size*count
    size,count,buf=chunks['BONENAMES']; bones=[]
    if size!=120: raise ValueError('Unsupported bone record')
    for i in range(count):
        row=struct.unpack_from('<64siii4f3f',buf,i*size)
        if row[3] < -1 or row[3] >= i or not all(math.isfinite(x) for x in row[4:11]): raise ValueError('Invalid bone hierarchy or rest transform')
        bones.append(dict(name=row[0].split(b'\0')[0].decode(),parent=row[3],q=list(row[4:8]),p=list(row[8:11])))
    _,count,info=chunks['ANIMINFO']
    if count!=1: raise ValueError('Expected single exported sequence')
    fields=struct.unpack_from('<iiiifffiii',info,128); fps=fields[6]; frames=fields[9]
    size,count,keys=chunks['ANIMKEYS']
    if size!=32 or count!=frames*len(bones) or not math.isfinite(fps) or fps<=0: raise ValueError('Key count/rate mismatch')
    rotations=[]
    for frame in range(frames):
        row=[]
        for bone in range(len(bones)):
            q=struct.unpack_from('<4f',keys,(frame*len(bones)+bone)*32+12)
            if not all(math.isfinite(x) for x in q) or sum(x*x for x in q)<1e-8: raise ValueError('Nonfinite key')
            row.append(q)
        rotations.append(row)
    return dict(name=path.stem,fps=fps,frames=frames,bones=bones,rotations=rotations,sha256=hashlib.sha256(raw).hexdigest())

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('root');ap.add_argument('output');args=ap.parse_args()
    root=pathlib.Path(args.root);out=pathlib.Path(args.output);out.mkdir(parents=True,exist_ok=True)
    selected=['FrontPunch_1','FrontPunch_1_2ndBackPunch','FrontPunch_1_3rdBackPunch','BackPunch_1','FrontKick_1','BackKick_1','DuckFrontKick_1','DuckBackPunch_1']
    report={'extensions':dict(collections.Counter(p.suffix for p in root.rglob('*') if p.is_file())),'clips':[]}
    for name in selected:
        clip=read_psa(root/'attack'/(name+'.psa'))
        (out/(name+'.json')).write_text(json.dumps(clip,separators=(',',':')))
        report['clips'].append({k:v for k,v in clip.items() if k not in ('bones','rotations')})
    (out/'inventory.json').write_text(json.dumps(report,indent=2))
    print(json.dumps(report,indent=2))
