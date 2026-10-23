# Checkpoint B — your testing is needed

Stages 07–13 are implemented. This is the prompt pack's required human gate before stage 14. Allow 20–30 minutes. Judge controls, readability, clipping during motion, and whether you want this low-poly art style. Automated checks cannot decide those.

## Launch
From PowerShell in `E:\zeus balls` run `powershell -ExecutionPolicy Bypass -File tools/playtest_checkpoint_b.ps1`. This opens the regrow lab. Add `-Main` for a normal match. Or open the project in Godot 4.7.2, open `scenes/debug/regrow_lab.tscn`, and press F6 (F5 opens the main match).

## Controls
A/D move, W jump, S crouch, J light, K heavy, L kick, J+L grab, Shift block, Space dodge. J/K alone use left arm; forward+J/K use right arm. L uses left leg; S+L uses right leg. R resets. Escape pauses. 1 selects local two-player, 2 human versus AI, 3 watches AI. P2 uses arrows, numpad 1/2/3 attacks, numpad 0 block, numpad decimal dodge.

## Test checklist
1. Use the left controls to select Theron, a limb slot and a replacement. Grant starts a fresh match with that limb. Test all five, then repeat on Pyrrhus. Check socket seams, floor contact, attacks, silhouettes and tooltip benefits/drawbacks. The claw's bonus is damage through block; chicken squeak is currently a caption.
2. Right controls target P2: F2 cycles slot, F3 bruises, F4 cracks, F5 performs a three-hit chain. Check stump and detached fragment. Repeat on different slots: at most two sever per match. Natural combat must never remove a healthy limb in one hit. Debug grant intentionally bypasses loss accounting for setup.
3. The P1 missing-limb mask picker has all 16 combinations: bits 1/2 arms, 4/8 legs. Try 1, 3, 4, 12, 7 and 15. You should still move and have legal fallback attacks; one leg hops, no legs crawl, three missing limbs use torso mode. A cracked attached limb cannot attack.
4. Cycle the three arenas on the right; inspect Olympus columns, Athens stands and Tartarus rock/lava shapes. Right fighter picker is a visual preview for P2; left picker changes P1's actual fighter. Inspect all four original characters.
5. Play the main match against AI. Check combo text, health/integrity, Fury, pause, round transitions and results. Difficulty balance is provisional: the automated hard/normal/easy gap is currently large.

Reply `Checkpoint B PASS` if acceptable, or list issues with fighter, limb, arena, action and expected/actual behavior. Please mention style changes now. Stages 14 onward (animation, abilities, audio, menus, persistence and release work) remain pending.

## Automated evidence
93 Godot tests; 23 deterministic replay fixtures; 40 compatible attachment cases in Python and Godot. Earlier AI soak completed 400 matches without stalls or invariant failures. Ten window captures and limb preview inspected in `build/previews`. Rest-pose tolerances: floor -15 mm, torso horizontal AABB overlap <=180 mm to allow joints/clothing, no head intersection, scale 0.7–1.5. Motion clipping still needs human review.
