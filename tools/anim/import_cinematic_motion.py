"""Extract and record playable casts/reactions from the user's PSA export library."""
import argparse
import json
from pathlib import Path
from read_exported_psa import read_psa


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("export_root", type=Path)
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[2]
    disk = args.export_root / "MK12/Content/Disk"
    files = {p.stem: p for p in (disk / "Shared/Anim").rglob("*.psa")}
    mapping, manifest = {}, []
    families = {"theron": "Geras", "pyrrhus": "Baraka", "atalanta": "JohnnyCage", "sibyl": "Havik", "dorian": "JohnnyCage"}
    for fighter, family in families.items():
        ingame = disk / "Char" / family / "Anim/Supermove/Roster/InGame"
        cast = "Supermove_InGame_Hit_Into_Flip" if fighter == "atalanta" else "Supermove_InGame_Into"
        rows = {
            "zeus_wrath": ingame / (cast + ".psa"),
            "olympian_barrage": ingame / (("Supermove_InGame_Hit_Into_Fwd" if family == "Geras" else "Supermove_InGame_Hit_Into") + ".psa"),
            "hit_electric": files["Low_F_InPlace_ElectricFloor_1"],
            "sever_arm": files["Brutality_Death_ArmSlice_Victim"],
            "sever_leg_l": files["Brutality_Death_OneLegHop"],
            "sever_leg_r": files["Brutality_Death_OneLegHop_Left"],
            "knockdown": files["High_F_Stumble_Stun_FallBack_1"],
        }
        mapping[fighter] = {}
        for action, path in rows.items():
            clip = read_psa(path)
            name = "Cinematic_" + fighter + "_" + action
            (project / "build/exported_motion" / (name + ".json")).write_text(json.dumps(clip, separators=(",", ":")))
            mapping[fighter][action] = name
            manifest.append({"fighter": fighter, "action": action, "source": path.as_posix(), "sha256": clip["sha256"], "frames": clip["frames"], "fps": clip["fps"]})
    for name, content in [("cinematic_sources.json", mapping), ("cinematic_source_manifest.json", manifest)]:
        (project / "data/animation" / name).write_text(json.dumps(content, indent=2) + "\n")
    print("Extracted", len(manifest), "cast, reaction and sever bindings")


if __name__ == "__main__":
    main()
