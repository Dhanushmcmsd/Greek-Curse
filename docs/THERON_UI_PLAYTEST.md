# Theron replacement and Kenney interface

Open `E:\zeus balls\project.godot` in Godot 4.7.2 and press F6 on the main menu scene, or F5 to run the project. Stop any previously running game first so it reloads the resources.

1. The main menu should show SEVERED, an Olympus backdrop, thin square-corner gold frames, and an animated Theron preview. Credits and licences identifies Kenney's Fantasy UI Borders (CC0).
2. Choose Practice, select Theron for player 1, and start the match. A/D moves, J/K punches, L/O kicks, Shift blocks, Space dodges, G grabs. F2 opens the combo list with the directional commands.
3. Compare Sentinel Jab (J), Anvil Cross (K), Front-Line Kick (L), and Shin Stop (down + L). Try forward + J and forward + K for the replacement combinations. Cross sides and repeat.
4. Check stance, forward/backward walking, blocking, recovery, hit reactions, and the menu preview. These all use the replacement set. Career uses the same shared fighter bindings.

## What changed

All 79 default-model Theron action bindings were replaced using JohnnyCage and Shared PSA files from the supplied export folder. The manifest records exact source paths and hashes. Fifteen multi-hit moves were assembled from the new clips with contact anchors. The old animation libraries are excluded from the default Theron rig. Root/spine rotation is limited during standing actions to prevent the previous exaggerated twisting; joint lengths remain intact. Existing collision and transition constraints still apply.

The original resources are archived in `build/theron_before_boxer.zip`, not loaded by the game. Alternate cosmetic model overrides retain their existing separate retargeting path; the replacement is verified for Theron's default model.

Kenney's PNG artwork is used in the shared menu theme and fight HUD, with original licence and source links in `assets/ui/kenney_fantasy`. Main-menu previews advance at 60 pose updates per second independent of render FPS.

## Rebuilding the replacement

Run these from the project directory in order, using the Godot console executable:

1. `python tools/anim/import_theron_boxer.py "D:\05cfbdd1648afe2928109b70ab63880a4bc8f7b4 (1)\Output\Exports\rea"`
2. `godot --headless --path . --script tools/anim/retarget_exported_motion.gd -- theron_boxer`
3. `godot --headless --path . --script tools/anim/calibrate_exported_contacts.gd -- theron_boxer`
4. `godot --headless --path . --script tools/anim/build_theron_boxer_chains.gd`

Focused verification: `tests/run_all.gd -- --suite test_theron_replacement` and `--suite test_fighter_styles`. The first checks complete replacement, resource hashes, runtime binding, absence of the legacy library, and multi-hit contact counts. The second checks actual simulated hits in both facings and sampled arm lengths/body clearance across the roster. Render captures are produced by `tools/capture_kenney_theron.gd`.

These checks are not a full-game regression or a guarantee against every possible mesh collision during interrupted attacks.
