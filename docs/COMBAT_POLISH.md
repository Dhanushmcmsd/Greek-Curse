# Timed combat and round-two severance

Run `Play Updated Game.cmd` or `tools/playtest_updated.ps1` for a human-vs-AI test match. Godot 4.7.2 is pinned in PROJECT_STATUS.md; GODOT_BIN overrides the local launcher path.

## Controls and timing

A/D move; S down; J/K left/right punch; L/O left/right kick; Shift guard; Space dodge; B body; Escape pause; U super; I ultimate. Rebinding remains supported.

A held attack starts once. Release and tap for another attack. The current move occupies startup, active and recovery frames; after recovery there is an eight-tick reset. A cancel requires contact, all scheduled hits from the current move, a permitted follow-up and sufficient stamina. An unaffordable cancel no longer pretends to start and stalls the original move. The HUD displays time until the link window, COMBO NOW with its remaining time, and recovery/reset time. Simulation timers pause with hitstop.

Directions are relative to facing. Example: Down+Left Punch -> Forward+Right Kick -> Forward+Right Punch gives Spartan Flurry -> Titan Knee Rush -> Thunder Elbow. Ghost Sweep uses Forward+Left Kick, then Back+Left Punch for Phantom Flurry, then Back+Right Punch for Phantom Ambush. The Combo List shows actual startup/cancel data; tap the follow-up when COMBO NOW appears. AI releases attack buttons between decisions too.

Launches in playable matches use deterministic integer vertical velocity and gravity. Fighters rise and fall, then get 20 grounded recovery ticks and a short wake-up protection window. Blocked attacks do not launch or wall bounce.

## Exactly one detachment

The severance award occurs at the end of the second round. The round loser loses their most damaged limb; ties use a deterministic fallback. It is one event across BOTH fighters, not one per fighter. A separate persistent match flag guards against repeated event dispatch, later rounds and regrowth resetting the award. Restarting a match resets the flag.

Before the award, attached limbs can bruise but remain usable; ordinary damage does not turn both fighters into crawling figures or create apparent extra amputations. The HUD explicitly says DETACHED for the severed limb. The removed arm or leg is baked from the current skinned pose into one physical body, falls and stays visible for 12 seconds, with a short joint spray, a stump surface and ground blood. Gore-off accessibility settings still suppress blood and debris. The amputated fighter receives the existing +15% compensation.

## Visual work and limitations

Scanned PBR stone, mipmapped textures, storm-sky lighting, weathered metal, rubble, distant ruins and torch particles replace the bright greybox presentation. Tapered impact masks reduce rectangular confetti; effects respect flash-reduction settings. The project still uses its existing licensed/available character rigs and shipped Mixamo motions. It does not contain extracted Mortal Kombat assets or a reconstruction of that game's proprietary physics. See ASSET_PROVENANCE.md for the REA result and asset sources.

## Verification

Focused behavior tests: tests/unit/test_combat_continuation.gd. Capture tool: tools/capture_continuation.gd. Full suite: Godot --headless --path . --script res://tests/run_all.gd. Logs: build/polish_*.log. Replay expected hashes are refreshed because the match rules and deterministic state changed; rebaseline script independently replays each saved input stream before accepting it.

Verified on 2026-10-28 with Godot 4.7.2 and NVIDIA GTX 1650:
- Full Godot suite: 172 passed, 0 failed, 0 skipped.
- Python validators: 15 passed.
- Final presentation tests after cosmetic adjustments: 4 passed, 0 failed.
- Render capture: CONTINUATION_RENDER_OK, no script errors.
- Real-time AI match: LIVE_MATCH_OK awards=1 round=3 debris=1 rendered_frames=1376. The second-round loser had one detached leg, visible blood and one complete physical limb on the floor. Screenshots are in docs/playtest/polish.
- GDScript lint and formatting checks passed.
