from pathlib import Path
from lib.scene_reset import reset
from lib.materials import material
from lib.primitives import shape
from lib.export import export_glb
OUT = Path(__file__).resolve().parents[2] / "assets/generated/models"
def build():
    colors=[(.5,.03,.05),(.85,.78,.6),(.08,.045,.035),(.65,.35,.08)]
    for i in range(15):
        reset()
        mat=material("chunk",colors[i%4])
        obj=shape("CHUNK",(0,0,0),(.07+(i%3)*.02,.05,.09+(i%4)*.015),mat,kind="orb")
        obj.rotation_euler=(i*.2,i*.3,i*.1)
        export_glb(OUT / ("gore_%02d.glb" % i))
