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

## Floor, scale and combo follow-up — 2026-10-28

All playable roster collision heights and all selected visual skins now use 1.8 m. Imported GLBs retain their baked source measurements; the model root applies one uniform conversion, preserving body proportions. Controller visual metadata follows the same match height. Reach diagnostics now include the skeleton-to-model transform instead of incorrectly assuming an unscaled skeleton.

The six multi-hit commands are regression-tested against all four opponents at 600 mm center spacing: every scheduled contact must land. Attack animation sampling uses measured source-clip extension anchors for each scheduled contact. Lightning Jab Chain uses the boxing combination clip instead of stretching one lead jab across four hits. `tools/anim/calibrate_combo_contacts.gd` reproduces the measured anchors; these are a presentation calibration, not a new motion-capture set.

Olympus has a continuous flagstone floor with original generated weathered albedo, scanned micro-normal detail, mipmapped anisotropic filtering, and a long broken fade into the distant ruins. It replaces disconnected flat grey tiles. Impact effects use short asymmetric flashes, fine fading sparks, and a brief local light; the oversized concentric rings are removed from ordinary combo impacts. Accessibility settings and effect caps remain in effect.

Reference comparison: the aim is grounded contact and readable layered effects, informed by [Technicolor's MK11 gameplay-animation account](https://www.technicolorgames.com/news/for-mortal-kombat-11-technicolor-animation-games-mixes-it-up-to-keep-super-heroic-actions-grounded-in-realism/) and [Atomhawk's MK11 art/FX work](https://atomhawk.com/project/mortal-kombat-11/). The assets and shipped rigs here remain this project's own; this pass does not claim equivalent AAA production quality.

Follow-up verification: 173 Godot tests passed, 0 failed, 0 skipped; 15 Python validator tests passed; GDScript lint and formatting passed. The animation attack matrix covered 2,432 cases. The six-combo/four-opponent contact regression passed all 24 combinations. Render capture completed without script/shader errors. Real-time match: LIVE_MATCH_OK awards=1 round=3 debris=1 rendered_frames=1425. Final screenshots: docs/playtest/refinement. The full log is saved beside these screenshots. Replay hashes were regenerated and independently verified after the intentional collision-height change.
