# PROMPT_INDEX.md - execution order and dependencies

Run strictly top to bottom. Each stage requires the **previous row** COMPLETE (and any checkpoint noted resolved). Do not skip.

| # | File | Purpose | Requires | Human checkpoint after |
|---|---|---|---|---|
| 00 | `00_README_AND_EXECUTION_GUIDE.md` | Install pack, reference docs, tracker | - |  |
| 01 | `01_PROJECT_AUDIT_AND_TECHNICAL_PLAN.md` | Verify toolchain, pin versions, technical plan | 00 |  |
| 02 | `02_PROJECT_SCAFFOLD_AND_DEVELOPMENT_TOOLS.md` | Godot project, Git, test runner, validators | 01 |  |
| 03 | `03_CORE_ARCHITECTURE_AND_CODING_RULES.md` | Architecture, integer toolkit, RNG, hash, data loader, purity check | 02 |  |
| 04 | `04_PROGRESS_TRACKER_AND_HANDOFF_PROTOCOL.md` | Tracker tooling, handoff protocol | 03 |  |
| 05 | `05_FIRST_PLAYABLE_PROTOTYPE.md` | First playable (greybox) - CHECKPOINT A | 04 | A |
| 06 | `06_COMBAT_SIMULATION_AND_HIT_DETECTION.md` | Real combat sim, hit detection, determinism harness | 05 |  |
| 07 | `07_LIMB_INTEGRITY_SEVERING_AND_STUMP_CAPS.md` | Limb states, severing, credit, caps, Desperate Fury | 06 |  |
| 08 | `08_BODY_STATE_MOVEMENT_AND_INPUT.md` | Body-state movement/moves, input layer | 07 |  |
| 09 | `09_FIGHTER_AI_AND_LOCAL_1V1.md` | AI, local match setup, soak harness | 08 |  |
| 10 | `10_COMBAT_UI_FEEDBACK_AND_ROUND_FLOW.md` | HUD, round flow, feedback, pause, results stub | 09 |  |
| 11 | `11_BLENDER_PYTHON_ASSET_PIPELINE.md` | Blender pipeline framework and validators | 10 |  |
| 12 | `12_SHARED_SKELETON_MODULAR_FIGHTERS_AND_SOCKETS.md` | Shared skeleton, 4 generated fighters, sockets, stumps | 11 |  |
| 13 | `13_REGROWN_LIMBS_AND_ATTACHMENT_VALIDATION.md` | 5 regrown limbs, attachment matrix - CHECKPOINT B | 12 | B |
| 14 | `14_ANIMATION_AND_CODE_DRIVEN_MOTION.md` | Code-driven animation | 13 |  |
| 15 | `15_ARENAS_LIGHTING_CAMERA_AND_VFX.md` | 3 arenas, hazards, camera, gore/VFX | 14 |  |
| 16 | `16_AUDIO_UI_AND_ACCESSIBILITY.md` | Settings service, audio, UI theme/icons, accessibility | 15 |  |
| 17 | `17_DATA_DRIVEN_ABILITIES_AND_BALANCING.md` | 21 abilities, loadouts, balance harness | 16 |  |
| 18 | `18_FIGHTER_ROSTER_AND_MVP_CONTENT.md` | Final stats, cosmetics, career ladder data, content matrix | 17 |  |
| 19 | `19_MATCH_RESULTS_PROGRESSION_AND_SAVES.md` | Results, unlock offers, Obol, Chronicle, saves | 18 |  |
| 20 | `20_MAIN_MENU_SETTINGS_AND_GAME_FLOW.md` | Menus and full game flow - CHECKPOINT C | 19 | C |
| 21 | `21_AUTOMATED_TESTS_AND_REGRESSION_SUITE.md` | Regression suite hardening | 20 |  |
| 22 | `22_PERFORMANCE_BUG_FIXING_AND_POLISH.md` | Performance, bug burn-down, polish | 21 |  |
| 22B | `22B_LEGAL_COPYRIGHT_AND_STOREFRONT_REVIEW.md` | Legal, licences, storefront and disclosure review | 22 |  |
| 23 | `23_BUILD_EXPORT_AND_RELEASE_CHECKLIST.md` | Export, build scripts, exported-build tests - CHECKPOINT D | 22B | D |
| 24 | `24_FINAL_ACCEPTANCE_AUDIT_AND_HANDOVER.md` | Final acceptance audit and handover | 23 | Final approval |
| 25 | `25_POST_MVP_ONLINE_AND_CONTENT_EXPANSION_PLAN.md` | (Optional) post-MVP planning only | 24 |  |

## Dependency map (machine-readable; copied to `tools/status/dependencies.json` in stage 04)
```json
{
 "00": [],
 "01": [
  "00"
 ],
 "02": [
  "01"
 ],
 "03": [
  "02"
 ],
 "04": [
  "03"
 ],
 "05": [
  "04"
 ],
 "06": [
  "05"
 ],
 "07": [
  "06"
 ],
 "08": [
  "07"
 ],
 "09": [
  "08"
 ],
 "10": [
  "09"
 ],
 "11": [
  "10"
 ],
 "12": [
  "11"
 ],
 "13": [
  "12"
 ],
 "14": [
  "13"
 ],
 "15": [
  "14"
 ],
 "16": [
  "15"
 ],
 "17": [
  "16"
 ],
 "18": [
  "17"
 ],
 "19": [
  "18"
 ],
 "20": [
  "19"
 ],
 "21": [
  "20"
 ],
 "22": [
  "21"
 ],
 "22B": [
  "22"
 ],
 "23": [
  "22B"
 ],
 "24": [
  "23"
 ],
 "25": [
  "24"
 ]
}
```

## Notes
- Numeric order is the implementation order. `22B` was added to the requested file list for legal/storefront work and runs between 22 and 23.
- Stage 05 builds a minimal real simulation with greybox visuals so that a playable exists before art; 06-08 deepen it; Blender art arrives in 11-13.
- Checkpoints A-D and the final approval are the only routine owner interruptions; see `MANUAL_CHECKPOINTS.md`.
- If a checkpoint fails, Cursor writes `docs/handoff/fix_<checkpoint>_<n>.md` (a targeted fix prompt) and executes it before moving on.
