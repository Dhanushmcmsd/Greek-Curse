> Historical notes: superseded by [COMBAT_POLISH.md](COMBAT_POLISH.md), particularly attack timing and the end-of-round-two award.

# Combat continuation — October 28, 2026

Run `Play Updated Game.cmd` for a playable match against the normal AI, or `tools/playtest_updated.ps1`. The launcher uses the project's pinned Godot installation; GODOT_BIN can override it.

Controls: A/D move, S down, J/K left/right punch, L/O left/right kick, Shift block, Space dodge, B body attack, Escape pause. Directions follow your facing; forward is D when facing right and A when facing left. Rebound controls remain supported.

Try these commands:
- Down + Left Punch: Spartan Flurry; cancel to Forward + Right Kick: Titan Knee Rush; then Forward + Right Punch: Thunder Elbow.
- Forward + Left Kick: Ghost Sweep; Back + Left Punch: Phantom Flurry; Back + Right Punch: Phantom Ambush.
- Forward + Left Punch: Lightning Jab; Down + Left Punch: Spartan Flurry; Down + Right Punch: Divine Uppercut.
- Back + Right Kick: Titan Combo Kick.
- Down + Right Kick: Olympian Crusher (uses the left arm, costs stamina).

Tap follow-ups during the cancel windows shown in the in-game Combo List. Knee Rush now permits all four contacts before its [39,49) cancel window. Basic attacks still use your equipped moves. Costs shown are stamina, not super meter. A legal cancel is not a guarantee that every follow-up connects at every distance or through guard.

The match allows at most one sever, across both fighters. It unlocks late in round two (80% elapsed or the victim at 25% health), or in later rounds. A qualifying damaged limb and combo are still required; a sever is not forced in every match. Accumulated limb damage selects the limb, with a minimum of 65; limb state and the award survive round transitions. Remaining attacks receive a permanent +15% damage bonus without double-stacking fury. Blocked limb hits count once at 25%. Regrowth does not reset the match cap.

Incoming launch state now survives attack cancellation, lands into 20 ticks of recovery, and is included in deterministic hashes. Wall effects use actual simulation collision, so blocked attacks cannot cause false wall bounces. Real shipped Mixamo clips drive new attacks and heavy/head/light reactions. Original placeholder source names are not claimed as newly acquired animation assets.

Presentation: darker procedural marble floor on Olympus, a single bounded sever burst rather than four overlapping bursts, flash-reduction support for the sever ring, and a reachable combo button. The live combo panel now uses the shared ComboListMenu and real move data. This is a polish pass on the existing assets, not a replacement with Tekken/Mortal Kombat production-quality character or environment assets.

Verification logs are under build/continuation_*.log. The replay input recordings are preserved and their expected hashes were regenerated and replay-verified because deterministic state and combat balance changed. Tests that expected unlimited severance or temporary-only compensation were updated for the requested match rule. Render captures: build/continuation_knee.png, continuation_reaction.png, continuation_sever.png, continuation_combos.png.

Final verification: full sweep 167 passed / 2 failed before the final fixes; both failures passed focused reruns (6 animation tests, 10 prototype tests). Final combat run: 28 passed. Replay verification: 5 passed. Python validator tests: 15 passed; status-tool tests: 12 passed. Repository GDScript lint, formatting, and diff whitespace checks pass. Render capture completed without runtime errors. The prototype golden was regenerated to its new completed match (1,430 ticks); other recorded replay inputs were retained.
