from pathlib import Path
import sys
import bpy
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_early_art as art

# Test sentinels: verify default startup objects (Cube, Camera, Light), custom unowned objects,
# and unowned datablocks survive resets and exports without being purged.
sentinel = bpy.data.objects.new("USER_KEEP_ME", None)
bpy.context.collection.objects.link(sentinel)

cube_sentinel = bpy.data.objects.get("Cube")
camera_sentinel = bpy.data.objects.get("Camera")
light_sentinel = bpy.data.objects.get("Light")

user_mesh = bpy.data.meshes.new("USER_MESH_DATABLOCK")
user_mat = bpy.data.materials.new("USER_MAT_DATABLOCK")

art.OUT = art.ROOT / "build/reset_fixture"
art.OUT.mkdir(parents=True, exist_ok=True)
spec = ("reset_fixture", 1.8, .45, (.5, .3, .2), (.2, .4, .5), "hunter")
art.fighter(spec)
art.export("reset_fixture")
count = len(bpy.data.objects)
art.fighter(spec)
art.export("reset_fixture")

assert len(bpy.data.objects) == count
assert bpy.data.objects.get("USER_KEEP_ME") is sentinel
assert bpy.data.objects.get("Cube") is cube_sentinel
assert bpy.data.objects.get("Camera") is camera_sentinel
assert bpy.data.objects.get("Light") is light_sentinel
assert bpy.data.meshes.get("USER_MESH_DATABLOCK") is user_mesh
assert bpy.data.materials.get("USER_MAT_DATABLOCK") is user_mat
print("SCENE_RESET_OK count=" + str(count))
