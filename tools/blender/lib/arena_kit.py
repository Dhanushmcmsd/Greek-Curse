"""Shared modular details. Every placement is deterministic and generated locally."""
from .primitives import shape

def decorate_arena(root, name, stone, trim, dark):
    for x in range(-4,5):
        for y in [-1,0,1]:
            shape("TILE", (x,y,-.006), (.98,.98,.02), stone, root)
    for x in [-4.3,4.3]:
        shape("BRAZIER_BASE",(x,1.1,.35),(.3,.3,.7),dark,root,"cylinder")
        shape("BRAZIER_BOWL",(x,1.1,.75),(.55,.55,.2),trim,root,"orb")
        for i in range(3):
            shape("FLAME",(x+(i-1)*.08,1.1,.95),(.12,.15,.4-i*.06),trim,root,"orb")
    if name == "mount_olympus":
        for i in range(15):
            shape("CLOUD",(-6+i*.85,3.5,-.7+(i%3)*.14),(1.8,1,.7),stone,root,"orb")
    elif name == "athens_colosseum":
        for tier in range(3):
            for i in range(19):
                shape("CROWD",(-4.7+i*.52,2.1+tier*.55,.7+tier*.42),(.2,.2,.35),trim if i%3 else dark,root,"orb")
    else:
        for i in range(12):
            shape("LAVA_CRACK",(-4.6+i*.83,1.4,-.002),(.07,.7,.02),trim,root)
