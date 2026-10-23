from pathlib import Path
import sys
import bpy
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_early_art as art

sentinel = bpy.data.objects.new("USER_KEEP_ME", None)
bpy.context.collection.objects.link(sentinel)
art.OUT = art.ROOT / "build/reset_fixture"
art.OUT.mkdir(parents=True, exist_ok=True)
spec = ("reset_fixture", 1.8, .45, (.5, .3, .2), (.2, .4, .5), "hunter")
art.fighter(spec)
count = len(bpy.data.objects)
art.fighter(spec)
assert len(bpy.data.objects) == count
assert bpy.data.objects.get("USER_KEEP_ME") is sentinel
print("SCENE_RESET_OK count=" + str(count))
