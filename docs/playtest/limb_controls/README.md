# Explicit limb controls and one-leg motion

Player 1: J = left fist, K = right fist, L = left foot, O = right foot. B is a separate body attack. Movement directions no longer switch the attacking limb. Player 2 uses keypad 1/2 for fists, 3/6 for feet, and 7 for body attacks. Gamepad uses X/Y for fists, A/RB for feet, and LB for body attacks. Existing saved bindings merge with the new defaults; all actions remain rebindable.

A severed or fractured limb cannot start an attack. Losing the attacking limb during startup or an active window clears that strike; hit resolution independently rejects unusable limbs. Regrowth restores that limb's command and replacement-specific bonuses. Body attacks have their own input rather than silently replacing a missing limb's button. AI move selection uses the same availability rules.

Removing a replacement no longer turns the natural mesh back on. The simulation state controls whether natural meshes, replacements, or wounds are visible, and this state is reapplied after animation evaluation. Regression tests cover severing a regrown replacement on all ten models and inject legacy visibility tracks to ensure an animation cannot resurrect the original limb.

One usable leg always selects the hop profile, even with both arms absent. Hopping uses a balance pose with a repeating knee-compression, takeoff and landing cycle on the surviving side, instead of playing two-legged walking. An attached fractured leg folds away from support.

A one-leg kick retains the equipped technique and its startup, hit window and recovery duration. The surviving leg strikes, the body lands on the hip, the knee comes beneath the torso, and the fighter rises on that same foot. The final recovery blends back toward the character's idle pose. These are new procedural animation layers retargeted through the canonical bones, not additional imported motion-capture assets. Hitstop freezes the sequence; attack cancellation cannot skip its recovery. Both left- and right-leg variants are shown in the accompanying captures.

`tools/capture_limb_controls.gd` reproduces the hop/kick/fall/rise captures. `tests/unit/test_limb_controls.gd` checks individual controls, regrowth, interrupted attacks, both recovery sides, visibility on all ten models, and migration of saved bindings. The body-state matrix covers all 16 loss combinations. Replay baselines were updated for the new input semantics; recordings from older control versions are not hash-compatible.

Validation: 163 Godot tests passed, 15 Python checks passed, all 44 replays verified, and all 16 body-state scenarios moved and connected an attack.
