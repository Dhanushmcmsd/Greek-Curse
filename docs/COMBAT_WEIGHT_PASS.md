# Combat weight, roster styles and arm correction — 2026-10-29

This pass adds pillar mist, exported attack coverage, distinct default fighting styles, impact momentum, and corrective arm posing. It replaces Theron's default lead punch and its legacy Jab of Hermes clip. It does not claim parity with a AAA production or that cooked Mortal Kombat gameplay code was imported.

## Fighting styles

Each default fighter has four individual strikes and four composed strings (32 distinct move definitions). Theron uses slower Bulwark strikes; Atalanta uses faster Huntress kick strings; Pyrrhus uses Warbrand power combinations; Sibyl uses Oracle palm/sweep sequences. Startup, recovery, hit intervals, costs and damage differ. The in-game combo list shows the current player's style and commands. Explicitly equipped custom/career loadouts retain their selected abilities.

- Left/Right Punch and Left/Right Kick: character-specific basic attacks.
- Down + Left Punch: pressure string.
- Forward + Left Punch or Right Kick: pursuit string.
- Back + Left Punch or Left/Right Kick: reversal string.
- Forward/Down + Left Kick: sweep string.
- Shared uppercut, grapple, body attacks and equipped powers remain available.

The exported motions are retargeted to each fighter's skeleton, rather than sharing one rig's animation resource. Anatomical segment alignment corrects differing source/target rest poses. During exported attacks, a two-bone arm solve keeps the non-striking hand in guard, preserves limb lengths, prevents elbow locking, and aligns the wrist with the forearm. Per-contact limb metadata distinguishes kick and punch beats in mixed strings. Short startup pose blending reduces snaps into attacks. The source's torso, hips and legs retain the motion style.

## Timing, weight and environment

Contact-gated cancels still require confirmed hits and all scheduled contacts. Quick Fury's cancel window now opens after its third hit. The jab has a seven-frame startup in the shared data, with separate character-specific defaults. Knockback uses a decaying deterministic impulse after hitstop, with reduced displacement between contacts and a wall clamp. Juggle lift declines with repeated launches. Finishers add hitstop and select stronger VFX on confirmed contacts. Momentum is hashed and reset between rounds.

Six staggered smoke-atlas layers drift across the pillar bases. The existing matching stone floor, original backdrop, imported impact textures and layered effects remain in use.

## Reference evidence

[Kombat Akademy](https://github.com/RedRaptor10/kombat-akademy) is a strategy/reference website, not a fighting-engine implementation. Its move-list dataset records startup, active, recovery, cancel frames and advantage; its combo data records ordered strings and links. Ashrah's Heaven's Palm entry, for example, lists 7 startup, 2 active and 19 recovery frames. These distinctions informed this game's timing model and style tuning. No engine, physics implementation or source assets were taken from that repository.

The supplied `script/CHAR_Ashrah.mko` is a compiled binary (1,961,521 bytes; SHA-256 `fe77794a6ae886d9255247356ac0225035e691a722c7e7ec91bd05532ae3ffb3`). Readable strings include `Cancel`, `bCancel=`, `gJumpFwdCancelJF`, `GutJuggleMid` and `- CANCEL FRAME*`. They are evidence of identifiers only; they do not reveal executable rules, frame values or a reliable decompilation. No .mko executable is shipped. See `ashrah_script_symbols.json` for offsets.

The selected PSA source names and hashes are recorded in `exported_motion_inventory.json`; per-fighter assignments are in `data/animation/fighter_styles.json`. These are user-supplied source-derived assets, not original or CC0 artwork.

## Reproduction

1. `python tools/anim/read_exported_psa.py <Exports directory> build/exported_motion`
2. Run Godot headless with `--script res://tools/anim/retarget_exported_motion.gd`, then `calibrate_exported_contacts.gd`, then `build_exported_chains.gd`.
3. Run the retarget tool with `-- styles`, then `calibrate_fighter_styles.gd`, then the chain builder with `-- styles`.
4. Run `tools/capture_fighter_styles.gd` with rendering enabled. Run `tools/playtest_polish.gd` for a timed live match.
5. Run `--headless --path . --script res://tests/run_all.gd` and `python -m unittest discover -s tools/validate -p 'test_*.py'`.

Always retarget/calibrate raw clips before composing strings. The chain builder samples and blends existing clips; repeatedly composing self-referential shared strings without regenerating the raw sources is not supported.

## Validation

The dedicated style tests cover distinct input resolution, exact contact counts in both directions, custom-loadout preservation, and arm lengths/wrist placement throughout all 32 attacks. Combat regression tests cover invulnerability, armor, hit registration across the roster, wall momentum, finisher hitstop and single-severance rules. Replay baselines were regenerated after intentional timing/state changes and independently verified with ReplayCheck. Full-suite results and rendered/live evidence are saved in `docs/playtest/combat_weight` after completion.

Screenshots are contact-pose presentation captures. They do not replace the simulation tests or live match. This test pass checks gameplay and rendering correctness, not a subjective guarantee that every animation is production quality on every alternate skin.

Final release check: **183 Godot tests passed, zero failures, zero skips; 18 Python tests passed; GDScript lint passed.** Rendered style capture: STYLE_RENDER_OK. Live match: LIVE_MATCH_OK awards=1 round=2 debris=1 rendered_frames=1429. Tested with Godot 4.7.2 on the local NVIDIA GTX 1650 Compatibility renderer. Logs and 16 contact captures are in docs/playtest/combat_weight. Baked animations now load directly; repeated fallback source clips are retargeted once per rig load.
