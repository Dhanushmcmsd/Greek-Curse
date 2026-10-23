# Stage 09 — AI and local matches

## Stage result
COMPLETE. Early art improvements continued during the soak under the owner's request; stages 11/12 are not yet marked complete.

## Changed files
AIObservation/FighterAI/DummyController, difficulty/archetype data and schemas, MatchConfig/MatchLauncher, playable controller mode switching, recorder fighter metadata, full-match soak and AI tests. Added Pyrrhus/Sibyl fighter data for roster pairing.

## Commands and test results
Godot import/tests, tools/sim/soak.gd --matches=20 then --matches=400, tools/check_all.sh; windowed --ai-demo --ticks=3600. check09: 78 Godot tests passed, Python tests passed, all static/data/status checks passed. Full soak: 400 completed, 0 stalls/invariant failures, 1398548 ticks, 103 severances. Hard>Normal 200/200, Normal>Easy 200/200. build/soak_summary.json contains full counts.

## Acceptance criteria
PASS: local config supports all three controller pairings. PASS: full 400-match soak and difficulty ordering. PASS: delayed observation, legal inputs over all 16 masks, same-seed hashes, dummy patterns, config rejection, fixture move recognized without AI edits.

## Window evidence
AI scripted window ran and captured build/ai_match09.png. No script errors; the Windows engine emits a system-certificate-store diagnostic also present on headless startup, unrelated to gameplay. Human keyboard/pad feel remains checkpoint B.

## Known limitations and decisions
Difficulty separation is extremely strong, provisional until playtest. Natural soak body coverage 0/1/3; explicit matrix covers the remaining masks. No AI promises about fun. Early art pipeline now has a deterministic manifest and shared rigid skeleton; importer flattening/vertex-colour fixes are being validated under stages 11/12.

## Owner action
None now.

## Next prompt to execute
10_COMBAT_UI_FEEDBACK_AND_ROUND_FLOW.md
