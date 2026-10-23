# Stage 10 - Combat HUD and round flow

## Stage result
COMPLETE.

## Changed files
SettingsHooks, RoundFlow, CombatHud/BodyDiagram and modular scenes, PauseMenu/ResultsStub, generated pattern textures, presentation feedback and tests.

## Commands and test results
Generate patterns; Godot import; windowed full-health, severing and results fixtures; tools/check_all.sh with CHECK_ASSET_REGEN=1. Final log build/check10_12.log: 83 Godot tests passed, 0 failed/skipped, Python validator/tool tests passed, lint/format/data/purity/status PASS; asset rebuild idempotence PASS.

## Acceptance
PASS: HUD resources/body patterns+icons/combo/Fury/credit. PASS: RoundFlow table, pause no-step hash and scene construction. PASS: replay-driven sever credit. PASS: results from full scripted match. PASS: settings-scaled shake/visual freeze and flash/gore hooks.

## Visual evidence
Inspected build/hud_final.png, hud_sever10.png, hud_results10.png. Fixed bar overlap, added results background and adjusted camera. Final full-health capture clearly shows separated standing models and unoccluded fighter names. Runtime graphics/feel remains owner checkpoint B.

## Known limitations / decisions
Settings backing store and menus remain later stages. Hit-stop setting scales cosmetic posing only; simulation hit-stop remains deterministic. No new gameplay decision. Engine startup certificate-store diagnostic persists in this sandbox.

## Owner action
None now.

## Next prompt to execute
11_BLENDER_PYTHON_ASSET_PIPELINE.md
