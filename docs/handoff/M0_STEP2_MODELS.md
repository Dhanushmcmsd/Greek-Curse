# M0 Step 2 Models Handoff

## Summary
Completed Step 2 of Stage M0: Mixamo Fighter Asset Conversion and Pipeline Integration.

- **Source Asset Directory:** `D:\Charecter model` (10 Mixamo FBX models: `Arissa`, `Ch34_nonPBR`, `Ch39_nonPBR`, `Ch40_nonPBR`, `Demon T Wiezzorek`, `Kachujin G Rosales`, `Maria J J Ong`, `Nightshade J Friedrich`, `Paladin J Nordstrom`, `Vampire A Lusth`).
- **Target Export Directory:** `assets/fighters_mixamo/` (Ignored from git per repository rules).
- **Tracked Legacy Assets Intact:** `assets/fighters/` and `assets/generated/models/` remain clean and untouched.

## Decisions Recorded
- **D-043:** Mixamo visual roster mapping. The 4 sim fighters remain the authoritative gameplay entities with existing stats, hitboxes, and move lists. `model_id` in `data/fighters/<id>.json` maps visual models (Theron -> Paladin, Atalanta -> Arissa, Pyrrhus -> Ch34, Sibyl -> Maria), with others available as selectable skins.
- **D-044:** Model geometry budget up to 60,000 triangles across partitioned skinned parts. Joint sockets anchored to exact skeletal head coordinates derived from standard Mixamo bones.
- **D-045:** Visual reach tolerance calibrated to 700 mm in `data/animation/poses.json` to accommodate horizontal root translation and spine pitching during full-torso maneuvers (`body_roll`, `body_scuttle`) on fully amputated fighters without affecting sim hitboxes.

## Verification Suite Results
- `tools/check_all.ps1`: Exit code **0**
- **Godot Unit & Integration Tests:** 125 passed, 0 failed, 0 skipped.
- **Python Validators:**
  - `tools/validate/validate_all.py`: PASS (JSON schemas, arenas, sim purity, poses, assets).
  - `tools/status/status_check.py`: PASS.
- **Determinism Replay Hashes:** Determinism goldens matched identically (`test_golden_final_hash` PASS, `test_two_runs_match_every_tick` PASS).

## Visual Inspection & Renders
- Generated 60 screenshot verification renders (10 models x 6 states: `full_body`, `severed_arm_l`, `severed_arm_r`, `severed_leg_l`, `severed_leg_r`, `regrown_arm_l`) stored in `docs/playtest/screenshots/mixamo_step2/`.
- Clean boundary cuts using `bmesh.ops.edgeloop_fill` on newly severed edges only, preserving natural anatomy openings (necks, waists).
- Accessory meshes (cloaks, capes, skirts) preserve cloth weights to prevent ragged cutaways when arms are severed.
- Standard 15-bone skeleton, sockets, stump caps, and regrown attachments verified across all 10 models.
