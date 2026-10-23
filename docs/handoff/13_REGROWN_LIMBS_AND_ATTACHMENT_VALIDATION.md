# Stage 13 — Regrown limbs and attachment validation

## Stage result
COMPLETE; human Checkpoint B pending.

## Changed files
Five data-defined limbs and schema; Blender builder, GLBs and manifest; SimRegrown and SimLimbs regrow/restore/re-sever hooks, move categories, modifiers and deterministic hashes; rig attachments and cosmetic quirks; regrow/attachment labs; Python/Godot attachment matrix; unit tests, five new golden replays and refreshed existing hashes; playtest launcher and checklist. MatchController now loads visual rows from selected fighter IDs. Deferred test-runner execution ensures attached nodes have a valid scene tree.

## Commands and verification
Blender build_all.py and preview_asset.py --limbs; headless Godot import; record_regrown.gd and replay regeneration; validate_attachments.py; tools/check_all.ps1 with CHECK_ASSET_REGEN=1. 93 Godot tests pass; full check log build/check13_final.log, final verification build/check13_release.log. Attachment matrix covers 40 combinations. Twenty-three replay fixtures pass. Asset manifest regeneration is byte-identical.

## Acceptance
PASS: five limbs with disclosed data effects, seeded drawbacks, compatible-only regrow, 80% normal integrity, re-sever/modifier removal, 40 rest-pose attachment cases, tooltips and deterministic replays. PASS: limb preview and ten window captures (five on Theron and Pyrrhus) inspected. Initial captures exposed a hard-coded model-selection bug; corrected and repeated. A real-contact claw regression caught its zero-base bonus; it now doubles main grab damage through block and holds 30 ticks.

## Limitations and decisions
Tolerance is explicit in validate_attachments.py: -15 mm floor, <=180 mm horizontal torso AABB intrusion for joint/clothing, no head overlap, scale 0.7–1.5. This does not prove every animated pose is free of clipping. Style, motion and gameplay feel await B. Models are original simple low-poly geometry. Squeak captions stand in for audio until stage 16. Windows logs show the environment's root certificate-store warning; game does not use networking.

## Owner action
Follow docs/playtest/CHECKPOINT_B.md. Only continue stage 14 after owner's B result and any necessary fixes.

## Next prompt to execute
14_ANIMATION_AND_CODE_DRIVEN_MOTION.md (after Checkpoint B).
