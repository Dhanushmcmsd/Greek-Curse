# Asset ledger

2026-10-24: all seven assets/generated/models/*.glb generated locally by tools/blender/build_early_art.py using Blender 5.2.3 LTS primitives and original costume/arena layouts. No external art, fonts, textures or audio. Project output licence remains an owner decision at stage 22B; no CC0 claim. Blender tool licence is distinct from the output.

## Polish and stage 15–16 generated assets
Original procedural fighter detail, modular arena kit and 15 gore chunks: tools/blender, no external source assets. Reference images guide themes only. Audio is original deterministic placeholder synthesis, not third-party CC0; tools/audio scripts and manifests record generation. UI glyph SVGs and stone/bronze theme generated locally; Godot default font used, no downloaded fonts.

## Animation Assets (Stage A0)
- Pack Name: Universal Animation Library (Vol. 1 & Vol. 2)
- Author: Quaternius (https://quaternius.com / https://www.patreon.com/quaternius)
- Licence: CC0 1.0 Universal Public Domain Dedication (https://creativecommons.org/publicdomain/zero/1.0/)
- Files Used: `UAL1_Standard.glb`, `UAL2_Standard.glb` (non-root-motion standard humanoid variants). Retargeted to project 15-bone shared humanoid rig.

## Mixamo Character and Animation Assets (Stage M0)
- Source: Adobe Mixamo (https://www.mixamo.com)
- Licence: Adobe Terms of Use (Free for use in games and commercial projects; redistribution of raw assets is prohibited).
- Raw Input Locations: Local directories `D:\Charecter model\` (10 character FBXs) and `D:\charecter animation\` (46 animation FBXs). Kept strictly out of git via `.gitignore`.
- Storage & Rebuild: Processed models are stored locally under `assets/fighters/` (.gitignored). Rebuild command: `D:\blender\blender.exe --background --python tools/blender/mixamo_to_fighter.py`.
- Manifest & Ledger: All processed outputs are verified via SHA-256 manifests.

