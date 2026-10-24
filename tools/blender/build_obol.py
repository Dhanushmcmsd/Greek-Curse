from pathlib import Path
from lib.scene_reset import reset
from lib.primitives import empty,shape
from lib.materials import material
from lib.export import export_glb
def build():
 reset();root=empty("OBOL")
 bronze=material("bronze",(.65,.42,.16));cloth=material("cloth",(.18,.12,.29));skin=material("skin",(.48,.31,.22))
 shape("PEDESTAL",(0,0,.1),(.8,.5,.2),bronze,root)
 shape("BUST",(0,0,.55),(.7,.4,.7),cloth,root,"orb")
 shape("HEAD",(0,0,1.05),(.36,.32,.45),skin,root,"orb")
 shape("HAT",(0,0,1.25),(.48,.42,.1),bronze,root,"cylinder")
 for side in [-1,1]:
  for i in range(3):
   shape("WING",(side*(.25+i*.06),0,1.25+i*.04),(.13,.05,.08),bronze,root,"orb")
  shape("EYE",(side*.07,-.155,1.1),(.04,.02,.03),bronze,root)
 export_glb(Path(__file__).resolve().parents[2]/"assets/generated/models/npc_obol.glb")
