# Exported motion and combat pass — 2026-10-29

## What was integrated

The supplied Exports tree contains 222 ActorX PSA clips, 15,893 Unreal assets, 2,190 bulk-data files and two maps. The selected animation exports identify Ashrah-related content. These are user-supplied game exports, not original or CC0 assets. Source names and SHA-256 fingerprints are recorded in exported_motion_inventory.json and exported_texture_sources.json.

Six source attacks were retargeted to each of the four existing fighter rigs: FrontPunch_1, BackPunch_1, FrontKick_1, FrontPunch_1_2ndBackPunch, FrontPunch_1_3rdBackPunch and DuckBackPunch_1. They drive Jab of Hermes, Spartan Cross, Pegasus Kick, Thunder Elbow Strike, Phantom Ambush and Divine Uppercut. The existing gameplay move names are retained; the imported motions replace their former clips. Source helper/weapon bones do not replace the player's skeleton or attach a sword.

Spartan Flurry, Phantom Flurry and Lightning Jab Chain now use composed sequences of the exported attack clips. Short interpolated joins connect segments; measured contact anchors map those poses to scheduled simulation hits. The runtime loads 36 retargeted Animation resources. Alternate skins retain their existing compatible animation path rather than receiving position tracks built for another rig.

Decoded Texture2D bulk payloads provide a 9-by-7 smoke flipbook, sparkle texture and soft smoke-trail mask. The decoder validates dimensions, byte lengths and bulk offsets, and supports the observed G8 and ASTC formats. The flipbook supplies impact haze, the sparkle mask adds fine impact detail, and the smoke mask softens attack ribbons. Geometry, lighting and materials add stone columns and bronze braziers in front of the existing distant backdrop.

## Hit fixes

An overlap during invulnerability previously spent the strike immediately. Now remaining active frames can connect after invulnerability ends; dodge and wake-up invulnerability still prevent damage while active. Armor still absorbs a strike but emits one visible block-style impact. Repeated hits restart the reaction animation so a new confirmed contact visibly affects the defender.

Regression cases cover all four opponents, both facing directions, six attacks/combos, armor feedback, invulnerability ending inside an active window, and the existing severance restrictions. Misses outside reach, guarded damage, dodge frames and armor remain intentional mechanics.

## Reproduction

1. Run `python tools/anim/read_exported_psa.py <Exports directory> build/exported_motion`.
2. Run Godot with `--headless --path . --script res://tools/anim/retarget_exported_motion.gd`.
3. Run `calibrate_exported_contacts.gd`, then `build_exported_chains.gd` in the same tools/anim folder.
4. Texture decoding uses Pillow and texture2ddecoder 1.0.6. Install the latter into build/texturedecoder, then run `python tools/anim/decode_exported_textures.py <Exports directory>`.
5. Run `tools/capture_exported.gd` for rendered contact poses and `tools/playtest_polish.gd` for the real-time match smoke test.

The ActorX conventions were checked against the [PSK/PSA importer](https://github.com/DarklightGames/io_scene_psk_psa). ASTC decoding uses the documented [texture2ddecoder API](https://github.com/K0lb3/texture2ddecoder). No third-party importer source or decoder binary is shipped in the game.

## Validation and limits

Full Godot suite: **176 passed, zero failures, zero skipped**. Python validation: **18 passed**. GDScript lint and formatting passed. Animation pose coverage includes the 2,432-case attack matrix. Final VFX/arena adjustments were additionally rendered without shader or script errors. The live match completed with exactly one severance: `LIVE_MATCH_OK awards=1 round=3 debris=1 rendered_frames=1429`.

Logs and screenshots are in docs/playtest/exported_motion. The saved kick screenshot intentionally triggers an impact at the defender's torso to expose the effect layers; it is a presentation capture, not evidence of damage registration. Combat tests and the live match separately validate gameplay.

REA rejected the sampled Unreal package as an unsupported binary format. The specialized readers could recover PSA motion and selected texture payloads; they did not decode cooked Unreal gameplay rules, Niagara graphs or maps into equivalent Godot logic. Existing deterministic game rules remain authoritative. This is a verified integration and presentation improvement, not a claim of AAA production parity.
