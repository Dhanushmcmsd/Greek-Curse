import html
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def main():
    ids=['arm_l','arm_r','leg_l','leg_r','healthy','bruised','cracked','severed','bone','flesh','stone','bronze']
    for folder in ['abilities','limbs']: ids += [p.stem for p in (ROOT/'data'/folder).glob('*.json')]
    for index,name in enumerate(ids):
        letter=html.escape(name[0].upper());pattern=''.join(f'<path d="M {x} 12 L {x} 52" stroke="#9c7847"/>' for x in range(12,54,8))
        svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><rect x="2" y="2" width="60" height="60" rx="8" fill="#141b25" stroke="#f1cb7b" stroke-width="3"/>{pattern}<circle cx="32" cy="32" r="18" fill="#141b25"/><text x="32" y="42" text-anchor="middle" font-size="28" fill="#f6eedb">{letter}</text></svg>'
        (ROOT/'assets/ui/icons'/f'{name}.svg').write_text(svg)
if __name__=='__main__':main()
