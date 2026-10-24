from pathlib import Path
from lib.scene_reset import reset
from lib.materials import material
from lib.primitives import empty, shape
from lib.export import export_glb
from lib.arena_kit import decorate_arena
OUT = Path(__file__).resolve().parents[2] / "assets/generated/models"

def arena(name, base_rgb, trim_rgb):
    reset()
    stone = material("stone", base_rgb)
    trim = material("trim", trim_rgb)
    dark = material("shadow_stone", tuple(c * .40 for c in base_rgb))
    root = empty("ARENA_" + name.upper())
    shape("FLOOR", (0, 0, -.18), (10, 4, .35), stone, root)
    for x in [-4.65, 4.65]:
        shape("BOUNDARY", (x, 0, .12), (.16, 3.8, .24), trim, root)
    if name == "mount_olympus":
        for x in [-4, -2, 0, 2, 4]:
            shape("COLUMN_BASE", (x, 1.5, .12), (.65, .65, .24), trim, root)
            shape("COLUMN", (x, 1.5, 1.8), (.37, .37, 3.5), stone, root, "cylinder")
            shape("CAPITAL", (x, 1.5, 3.5), (.62, .62, .22), trim, root)
        shape("ENTABLATURE", (0, 1.5, 3.8), (9, .7, .3), stone, root)
    elif name == "athens_colosseum":
        for tier in range(4):
            shape("TERRACE", (0, 1.7 + tier * .55, tier * .42), (11, .65, .65), dark if tier % 2 else stone, root)
        for x in [-4, -2, 0, 2, 4]:
            shape("STANDARD", (x, 2.1, 2.1), (.045, .045, 2.4), trim, root)
            shape("BANNER", (x + .22, 2.1, 2.8), (.45, .045, .7), trim, root)
    else:
        for x in [-4, -2.7, -1.3, 1.3, 2.7, 4]:
            rock = shape("BASALT", (x, 1.6, 1.2), (.9, 1.0, 2.8 + abs(x) * .25), dark, root, "orb")
            rock.rotation_euler.y = x * .07
        for x in [-3, 3]:
            shape("VENT", (x, .65, .015), (.8, .6, .025), trim, root)
        shape("LAVA_RIVER", (0, 2.1, -.1), (10, .7, .05), trim, root)
    decorate_arena(root, name, stone, trim, dark)
    export_glb(OUT / ("arena_" + name + ".glb"))

