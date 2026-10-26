# Combat presentation pass

The Forge now previews the selected fighter's actual elemental replacement asset. Player and socket changes refresh the preview. Combat perks remain unchanged; the UI explains that appearance follows the fighter.

Severed joints hide the legacy cut cylinders and bone sticks. A thin, recessed, procedurally textured flesh surface follows the relevant bone. Blood-color and gore settings apply. Regrown joints use a feathered proximal shell from the original limb, preserving native skin weights at the body boundary. Feathering is baked in rest space, so it stays stable during animation. The pilot and match use the same finishing code.

Combat presentation now includes warm contact flashes and sparks, blue guard rings and sparks, joint-local hits, a stronger severance burst, short attack-motion trails, directional recoil, and additive camera shake/push-in. Existing hitstop still controls timing. These are original procedural effects inspired by the provided fighting-game references.

Large placeholder chunk bursts were removed. Real detached limb geometry is baked in its current animated pose and retains normal scale within a safety bound. Blood uses small droplets, periodic wound oozing, and soft irregular stains instead of rectangular floor patches. Effect pools remain bounded and expire; reduced-flash and gore-off settings are covered by regression tests. No simulation or balance data changed.

## Visual checks

- `forge.png`: current elemental asset in all perk cards.
- `hit.png`, `block.png`, `sever.png`: distinct impact styles in the match scene.
- `wound.png`, `pilot_wounds.png`: wound treatment after severing.
- `pilot_idle.png`, `pilot_punch_jab.png`, `pilot_kick_thrust.png`: replacement joins in multiple poses.

Reproduce with Godot 4.7.2 using `--path . --script tools/capture_combat_presentation.gd` and `--path . --script tools/capture_pilot_finish.gd`. The capture harness drives explicit presentation events to make comparable frames; it is not a recorded match.

New regression tests cover all ten models' wound fitting, stable skinned seam feathering, bounded effects, gore/reduced-flash options, and camera priority. Existing tests cover all forty replacements, animation states, gameplay determinism and the pilot lifecycle.

Final validation: 153 Godot tests passed, 0 failed; 15 Python validators passed. Visual capture runs completed without script or rendering errors.
