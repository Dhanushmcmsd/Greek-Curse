"""Decode the exported Texture2D external first mip, with strict extent checks."""
import argparse, hashlib, json, pathlib, re, struct, sys
from PIL import Image
sys.path.insert(0,str(pathlib.Path('build/texturedecoder').resolve()))

def decode(path, output):
    b=path.read_bytes(); formats=list(re.finditer(rb'PF_(?:ASTC_\d+x\d+|G8)\x00',b))
    if not formats:raise ValueError('Unsupported pixel format')
    match=formats[-1]; fmt=match.group()[:-1].decode(); i=match.start(); j=match.end()
    width,height=struct.unpack_from('<ii',b,i-16)
    _,mips,cooked,flags,count,size,offset,mw,mh,depth=struct.unpack_from('<6iQ3i',b,j)
    if width!=mw or height!=mh or depth!=1 or not (0<width<=8192 and 0<height<=8192):raise ValueError('Invalid dimensions')
    raw=path.with_suffix('.ubulk').read_bytes()
    if offset+size>len(raw) or size!=count:raise ValueError('Invalid bulk span')
    payload=raw[offset:offset+size]
    if fmt=='PF_G8':
        if size!=width*height:raise ValueError('G8 byte count')
        image=Image.frombytes('L',(width,height),payload)
    else:
        import texture2ddecoder
        bw,bh=map(int,fmt.removeprefix('PF_ASTC_').split('x'))
        if size!=((width+bw-1)//bw)*((height+bh-1)//bh)*16:raise ValueError('ASTC byte count')
        image=Image.frombytes('RGBA',(width,height),texture2ddecoder.decode_astc(payload,width,height,bw,bh),'raw','BGRA')
    output.parent.mkdir(parents=True,exist_ok=True);image.save(output)
    return dict(source=str(path),output=output.as_posix(),format=fmt,width=width,height=height,sha256=hashlib.sha256(b).hexdigest(),bulk_sha256=hashlib.sha256(raw).hexdigest())

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('root');args=parser.parse_args();root=pathlib.Path(args.root)/'all tech/FX'
    selected={'Backgrounds/Fireworks/Textures/T_LantFest_Fireworks_SmokeTrailSoft.uasset':'smoke_trail.png','Backgrounds/Fireworks/Textures/T_LantFest_Fireworks_SparkleTrail.uasset':'spark_trail.png','Backgrounds/Global/Textures/T_Smoke_9x7.uasset':'smoke_flipbook.png'}
    report=[decode(root/k,pathlib.Path('assets/vfx/exported')/v) for k,v in selected.items()]
    pathlib.Path('build/exported_motion/textures.json').write_text(json.dumps(report,indent=2)); print(json.dumps(report,indent=2))
