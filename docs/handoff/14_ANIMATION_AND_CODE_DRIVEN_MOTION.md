# Stage 14 - Animation and code-driven motion

## Result
COMPLETE. Owner reported Checkpoint B defects and explicitly requested fixes followed by stage 14. This authorizes progression; it is not recorded as an unconditional owner PASS. Retest of corrected gameplay remains requested.

## Fixes to owner feedback
Standing arm hurtboxes were at 80-90% height and normal punches hit only torso. Arms now cover 45-80% height at the sides; legs reach 45%; kick targets the leg band. Ordinary unmodified jab chains sever arms on every fighter, and normal kicks damage legs. Zone-specific unit fixtures were relocated to the corrected anatomy; expected main damage now uses the existing 50% limb rule. Golden hashes were deliberately regenerated for these gameplay corrections. Existing cap, healthy-hit protection, credit and determinism tests remain.

Models now face each other using +Z to +/-X rotation. Throw swaps update facing in the same tick. Visible New match and Replacement limbs buttons exist in both main-match and results screens. The replacement dialog starts a fresh match with the chosen player's compatible limb. Button-to-world integration tests verify reset and grant. Severed fragments now copy actual posed limb meshes, including replacements.

## Stage implementation
Data-defined pose sets and joint limits; per-move anim_set; PoseDriver preserving imported rest rotations; phase-locked attacks; walk blending, body-state motion, ground/pivot correction, cracked/severed layers, cape motion and replacement quirks; animation lab with tick scrubbing and hitboxes; JSON/GLB validator and negative tests; runtime matrices and presentation replay. No authored animation or new Blender character assets.

## Commands and evidence
Godot import, tools/check_all.ps1, tools/anim/pose_validate.py, tools/anim/replay_presentation.gd, Blender build_all.py, tools/sim/soak.gd --matches=64, window captures via animation_lab and match scene. Final log build/check14_final.log: 103 Godot tests, 14 Python validator tests, 12 status tests; lint/format and validators pass. Matrices: 768 state cases and 832 attack cases. Existing 40 attachment cases and 23 replays pass. Presentation replay: 2198 ticks, hash 3900335586763293006, about 1.1 ms/tick and 73 mm maximum reach difference. Broad attack matrix maximum 596 mm within data tolerance 650 mm. Updated AI soak: 64 complete matches, 279002 ticks, 126 severs, zero failures. Difficulty gap remains large (32/32 each comparison).

Windowed key-state captures on Theron and Pyrrhus, all five replacements posed on both, and ordinary-match bruising and actual two-arm severing were inspected. Screenshots build/playtest_b_fixed.png and playtest_b_severed.png demonstrate gameplay changes. Root certificate-store diagnostic is environmental; presentation replay has no script errors. GPU frame-time profiling and user feel/style acceptance are not implied by the headless timing.

## Owner action and next prompt
Retest the fixed main match: New match and Replacement limbs are at bottom right; results also has both buttons. A/D move, J/K/L attacks, Shift block, Space dodge. A three-hit chain enables severance, but integrity must also reach zero. Instructions: docs/playtest/CHECKPOINT_B.md.

Next prompt: 15_ARENAS_LIGHTING_CAMERA_AND_VFX.md. Preserve the owner's uncommitted project.godot editor changes.
