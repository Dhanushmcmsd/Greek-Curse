"""Rebuild PSA intermediates used by retarget_exported_motion.gd.

Run from the project root. Optional --source-root replaces the original Char
directory recorded in the manifests. Godot runtime uses baked .res assets only.
"""
import argparse
import json
from pathlib import Path

from read_exported_psa import read_psa


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-root", type=Path)
    parser.add_argument("--export-root", type=Path, help="Relocated rea directory (includes Shared reactions)")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[2]
    for filename, subfolder in [("dorian_source_manifest.json", "dorian"),
                                ("state_source_manifest.json", ""),
                                ("locomotion_source_manifest.json", ""),
                                ("reaction_source_manifest.json", ""),
                                ("combo_source_manifest.json", ""),
                                ("expansion_source_manifest.json", ""),
                                ("cinematic_source_manifest.json", "")]:
        rows = json.loads((project / "data/animation" / filename).read_text())
        for row in rows:
            original = Path(row["source"])
            source = original
            if args.export_root:
                source = args.export_root / original.as_posix().split("/rea/", 1)[1]
            elif args.source_root and "/Char/" in original.as_posix():
                source = args.source_root / original.as_posix().split("/Char/", 1)[1]
            clip = read_psa(source)
            if clip["sha256"] != row["sha256"]:
                raise ValueError(f"Source changed: {source}")
            name = source.stem if subfolder else source.parts[-4] + "_" + source.stem
            if filename == "combo_source_manifest.json":
                name = "Combo_" + source.stem
            if filename == "expansion_source_manifest.json":
                name = "Expansion_" + source.parts[-4] + "_" + source.stem
            if filename == "cinematic_source_manifest.json":
                name = "Cinematic_" + row["fighter"] + "_" + row["action"]
            output = project / "build/exported_motion" / subfolder
            output.mkdir(parents=True, exist_ok=True)
            (output / (name + ".json")).write_text(json.dumps(clip, separators=(",", ":")))
            if subfolder == "dorian":
                (project / "build/exported_motion" / ("JohnnyRepair_" + name + ".json")).write_text(json.dumps(clip, separators=(",", ":")))
        print(f"Verified and extracted {len(rows)} clips from {filename}")


if __name__ == "__main__":
    main()
