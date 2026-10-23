"""Original faceted test roster and arenas. Run with Blender --background --python.

These early modular models are deliberately introduced before stage 11 at the
owner's request. Stage 12 adds the shared armature and rigid skinning.
"""
import json
import math
from pathlib import Path

import bpy
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from lib.scene_reset import reset
from lib.skeleton import build_armature
from lib.export import export_glb

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/generated/models"
OUT.mkdir(parents=True, exist_ok=True)


from lib.materials import material
from lib.primitives import empty, shape


def clear():
    reset()


def export(name):
    from validate_model import validate
    validate()
    export_glb(OUT / f"{name}.glb")


def fighter(row):
    clear()
    name, h, width, skin_rgb, cloth_rgb, style = row
    skin = material("skin", skin_rgb)
    cloth = material("cloth", cloth_rgb)
    gold = material("bronze", (0.73, 0.47, 0.16))
    dark = material("leather", (0.10, 0.075, 0.06))
    red = material("stump", (0.48, 0.025, 0.045))
    bone = material("bone", (0.9, 0.82, 0.61))
    root = empty("FIGHTER_" + name.upper())
    root["height_m"] = h
    root["early_test_model"] = True
    shape("TORSO", (0, 0, h * .66), (width, .27, h * .30), skin, root, "orb")
    shape("PELVIS", (0, 0, h * .46), (width * .68, .25, h * .13), cloth, root)
    shape("BELT", (0, -.015, h * .515), (width * .75, .29, .075), gold, root)
    shape("NECK", (0, 0, h * .845), (.12, .13, h * .07), skin, root, "cylinder")
    shape("HEAD", (0, -.015, h * .92), (.23, .22, h * .16), skin, root, "orb")
    for side in [-1, 1]:
        shape("EYE", (side * .052, -.112, h * .93), (.032, .018, .024), dark, root)
    shape("NOSE", (0, -.128, h * .91), (.045, .065, .06), skin, root, "orb")
    for side, sign in (("L", -1), ("R", 1)):
        for limb in ("ARM", "LEG"):
            arm = limb == "ARM"
            x, z = (sign * width * .53, h * .79) if arm else (sign * width * .23, h * .45)
            socket = empty("SOCKET_" + limb + "_" + side, (x, 0, z), root)
            group = empty("LIMB_" + limb + "_" + side, parent=socket)
            length = h * (.31 if arm else .43)
            thick = width * (.26 if arm else .30)
            shape(limb + "_UPPER_" + side, (0, 0, -length * .24),
                  (thick, thick, length * .5), skin if arm else cloth, group, "cylinder")
            shape(limb + "_LOWER_" + side, (0, -.015, -length * .70),
                  (thick * .83, thick * .85, length * .44), skin, group, "cylinder")
            shape(limb + "_END_" + side, (0, -.04, -length * .94),
                  (thick * 1.1, thick * 1.55, length * .15), gold if arm else dark, group)
            stump = empty("STUMP_" + limb + "_" + side, parent=socket)
            shape("CUT_" + limb + side, (0, 0, -.015), (thick, thick, .035), red, stump, "cylinder")
            shape("BONE_" + limb + side, (0, 0, -.035), (.035, .035, .025), bone, stump, "cylinder")
    empty("SOCKET_NECK", (0, 0, h * .85), root)
    if style == "helm":
        shape("HELM", (0, 0, h * .94), (.28, .26, h * .08), gold, root)
        shape("CREST", (0, .015, h * .98), (.055, .29, h * .04), cloth, root)
        cape = shape("CAPE", (0, .19, h * .62), (width * .92, .045, h * .43), cloth, root)
        cape.rotation_euler.x = -.12
        for sign in [-1, 1]:
            shape("PAULDRON", (sign * width * .52, 0, h * .81), (.23, .31, .13), gold, root, "orb")
    elif style == "hunter":
        strap = shape("SASH", (0, -.15, h * .68), (.065, .04, h * .32), dark, root)
        strap.rotation_euler.y = -.45
        for i in range(6):
            shape("BRAID", (.11, .10, h * .92 - i * .045), (.07, .07, .07), dark, root, "orb")
        shape("QUIVER", (.13, .20, h * .70), (.12, .13, .46), cloth, root, "cylinder")
    elif style == "wrestler":
        shape("CHAMPION_BUCKLE", (0, -.18, h * .51), (.16, .06, .12), gold, root, "orb")
        for i in range(10):
            a = i * math.tau / 10
            shape("WREATH", (.13 * math.cos(a), .12 * math.sin(a), h * .985), (.065, .04, .035), cloth, root, "orb")
    else:
        shape("VEIL", (0, .10, h * .89), (.29, .045, .32), cloth, root)
        shape("STOLE", (0, -.16, h * .67), (.16, .035, h * .31), cloth, root)
        shape("ORACLE_GEM", (0, -.20, h * .77), (.075, .04, .10), gold, root, "orb")
    build_armature(root, h, width)
    export("fighter_" + name)


def arena(name, base_rgb, trim_rgb):
    clear()
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
    export("arena_" + name)


def main():
    config = json.loads((ROOT / "data/art/early_models.json").read_text())
    for path in sorted((ROOT / "data/fighters").glob("*.json")):
        row = json.loads(path.read_text())
        body = row["body"]
        fighter((row["id"], body["height_m"], body["shoulder_width"], body["skin_tone"], body["cloth_color"], body["costume"]))
    for spec in config["arenas"]:
        arena(*spec)
    print("EARLY_ART_OK: four modular fighters and three arenas")


if __name__ == "__main__":
    main()
