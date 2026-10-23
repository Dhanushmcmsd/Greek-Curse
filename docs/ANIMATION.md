# Code-driven animation (stage 14)

PoseDriver is presentation-only. It caches data/animation/poses.json and move anim_set references, preserves imported rest rotations and applies quaternion offsets through Skeleton3D. There are no authored clips or AnimationTree. The shared 15-bone names and per-joint limits are checked against all generated GLBs.

Attack phase selects startup before startup_ticks, active at startup_ticks through startup+active-1, and recovery starting at startup+active. state_tick is the tick actually displayed by the sim, not its already-incremented move_age. Walk blends four keys. Pause/hitstop freeze the procedural timer. Breathing, walk lean, crawl arms, hop, torso sway/roll, cracked-limb droop, stump twitch, a cape spring and replacement quirks are presentation layers; they never write the simulation.

The imported forward direction is +Z. A facing sign of +1 rotates +90 degrees toward +X; -1 faces -X. The sim also refreshes facing immediately after throw position swaps, before hitstop can freeze the next frame. Replacement sockets follow bone deformation, so posing the natural mesh and replacement use the same shoulder/hip.

Grounding caches actual rigid-skin vertices and evaluates their deformed minimum height. This corrects each fighter's root height rather than guessing one pelvis offset. Crawl/torso/dodge/KO use a height-scaled pivot to keep the body near its collision position. Intentional hop elevation is added after grounding. Independent tests evaluate actual foot vertices for a complete standing/walk cycle across all four fighters. Missing limbs are excluded from grounding and hidden by the rig.

Visual reach is reported in millimetres between the active hand/foot/head and the hitbox far edge, including the root pivot. The data tolerance is 650 mm across the full fallback/pose matrix; measured maximum was 596 mm. The normal replay measured 73 mm. This is approximate visual reach, not IK or a change to collision geometry. Headless two-fighter simulation plus pose updates measured about 1.1 ms/tick on this machine; this is not a full GPU frame-time benchmark.

## Animation lab
Run scenes/debug/animation_lab.tscn with F6. The middle selector chooses a state or move, and the slider scrubs simulation ticks. Left controls choose fighter, missing-limb mask and replacement; right controls change arena and P2 visual preview. F1 toggles collision overlays. Command-line capture flags: --autoplay --still-preview --ticks=60 --fighter=pyrrhus --pose=pegasus_kick --state-tick=8 --mask=4 --shot=res://build/example.png. For still previews, --limb=<id> grants a compatible replacement.

## Validation
python tools/anim/pose_validate.py validates names, references, joint limits and finite angles. tools/check_all.ps1 includes its negative tests. Godot covers 768 fighter/state/mask cases, 832 attack cases, exact attack boundaries, independent foot-floor geometry, missing visibility, same-tick throw facing, hitstop freeze and presentation purity. tools/anim/replay_presentation.gd replays the real golden through FighterView and confirms the simulation hash is unchanged. It reports timing and reach. Window contact sheets are in build/previews/animation_theron.png and animation_pyrrhus.png. Windows emits an environment certificate-store error; no script/render errors occurred in the validated presentation replay.
