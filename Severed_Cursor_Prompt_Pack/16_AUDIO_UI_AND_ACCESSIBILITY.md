# Stage 16: Audio Ui And Accessibility

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Audio/UI engineer and accessibility specialist.

## 2. Context
Stage 15 COMPLETE: arenas, camera, gore, VFX; `SettingsHooks` exists as a stub; HUD functional with placeholder theme.

## 3. Objective
Create the real Settings service (with persistence, validation, migration), the procedurally generated placeholder audio set and audio manager, the stone-and-bronze UI theme, generated icons, captions/subtitles and all MVP accessibility options.

## 4. Prerequisites
1. Stage 15 COMPLETE.

## 5. Workspace inspection
1. `src/core/settings_hooks.gd` and every place it is consumed.
2. GDD sections 13.2-13.3, 16.1; Build Requirements sections 6-7; D-017, D-018; `docs/ASSET_LEDGER.md`.

## 6. Implementation tasks
1. `src/persistence/settings_service.gd` (autoload `Settings`): versioned `user://settings.cfg` (ConfigFile) with schema defaults in `data/ui/settings_defaults.json`; validation + clamping of every value; migration function skeleton from version N to N+1; corrupt/unreadable file -> back up to `settings.cfg.bad`, load defaults, log WARN, never crash. Settings: master/music/sfx/ui volumes, gore level (Off/Low/Normal/Max), blood colour (red/green/golden ichor), screen shake %, hit-stop %, flash reduction (photosensitivity), subtitles on/off, UI text scale (100/125/150/200%), colour-blind-safe pattern mode (patterns always on, plus high-contrast option), hold-to-toggle block, key/gamepad bindings blob (from stage 08), fullscreen/vsync/resolution, first-launch flags (`age_gate_accepted`, `content_warning_seen`). Re-point `SettingsHooks` to this service without changing its interface; emit a `changed` signal.
2. `tools/audio/generate_sfx.py` (standard library only: `wave`, `math`, `struct`, seeded `random`): synthesises placeholder SFX deterministically (seeded) - light/heavy impacts for bone/flesh/stone/bronze, whoosh, block, dodge, grab, limb crack, sever, squelch, chunk bounce, lightning, lava, UI click/confirm/back, stamina empty, ultimate ready, round bell, KO. Output 16-bit WAV/OGG (if no encoder is available use WAV) into `assets/audio/sfx/` with a manifest listing sample rate, length, peak; peaks must stay below -1 dBFS. `tools/audio/generate_music.py`: short looping tracks per scene (menu, one per arena, win and loss stingers) in Dorian/Phrygian modes using simple waveforms and percussion noise, deterministic, 30-60 s loops with seamless loop points (verify by end-start sample continuity metric). Document honestly that this is placeholder-quality; owner decides at Checkpoint C whether to replace with better CC0/self-composed music (any replacement must be ledgered with licence).
3. `src/presentation/audio_manager.gd` (autoload `Audio`): buses Master/Music/SFX/UI created in code, volumes from Settings, polyphony cap, pitch/volume variation (seeded presentation RNG - not the sim RNG), sim-event -> sound mapping table in `data/audio/event_map.json` (material-aware impact: bone for limb hits, flesh for torso, stone for marble limb, bronze for helm/armour), music scene switching with crossfade, ducking on ultimates (later).
4. Captions/subtitles: `src/ui/caption_system.gd` showing text for notable events (announcer-style 'Greek Chorus' lines for combos, amputations, regrown limbs, round results; fighter and Obol barks as text only - **no voice acting**, D-017). Lines in `data/ui/captions_en.json`, localisation-ready keys. Obey subtitle setting and UI scale.
5. UI theme: generate a stone-and-bronze `Theme` resource procedurally (`tools/ui/build_theme.gd`: StyleBoxFlat panels with bevel colours, bronze borders, stone fills, focus styles with strong contrast, button states); fonts: use **Cinzel** (OFL) only if you can obtain it with its licence file legitimately; else a Godot-default font; record in the ledger; readable large-text option.
6. `tools/ui/generate_icons.py` (Python standard library only; write SVG, import via Godot): icons for limb slots, limb states, damage types, and for every ability and regrown limb defined **so far** (re-run in later stages); simple geometric glyph + initial; consistent bronze/stone palette; patterns for colour-blind use; list in ledger. Update the HUD body diagram to use them.
7. Accessibility pass: verify every UI element is operable by keyboard and gamepad focus, minimum text sizes at 100% scale, contrast ratio check script (`tools/ui/contrast_check.py` for theme colour pairs, WCAG AA target 4.5:1 for body text), no colour-only information, flash reduction removes full-screen flashes and strong strobing (limit changes to <= 3 per second and reduce luminance delta when enabled), shake/hit-stop sliders reach 0%.
8. Audio verification tooling: `tools/audio/validate_audio.py` (files exist, non-silent, peak limits, loop seam metric, total size budget, every `event_map` entry resolves).
9. Tests, ledger, `docs/ACCESSIBILITY.md`, commit.

## 7. Technical constraints
1. No online font/audio downloads without recorded licences; prefer fully generated assets.
2. No voice recording or TTS in the MVP.
3. Settings must be loadable even if the file is empty, partial or from a future version.
4. Audio must never be required for gameplay information (captions + visuals cover critical cues).

## 8. Files and outputs
1. `src/persistence/settings_service.gd`, `data/ui/*.json`, `data/audio/event_map.json`
2. `tools/audio/*.py`, `assets/audio/**`
3. `src/presentation/audio_manager.gd`, `src/ui/caption_system.gd`
4. `tools/ui/{build_theme.gd,generate_icons.py,contrast_check.py}`, `assets/ui/**`
5. `docs/ACCESSIBILITY.md`, ledger updates

## 9. Automated tests
1. Settings: defaults valid; round-trip save/load; clamp out-of-range; missing keys; unknown keys preserved or ignored (documented); corrupt file recovery creates `.bad` and loads defaults; migration fixture.
2. Audio validator on all generated files; determinism (regenerate -> identical hashes).
3. Event map completeness against the sim event list.
4. Caption triggering from replay events (e.g. `severance_01` yields amputation caption).
5. Contrast checker on theme pairs; icon coverage check (every ability/limb id has an icon).
6. Flash reduction test: with setting on, requested flash intensity is capped (pure function test).

## 10. Execution and verification
1. `python3 tools/audio/generate_sfx.py && python3 tools/audio/generate_music.py && python3 tools/audio/validate_audio.py` pass.
2. `python3 tools/ui/generate_icons.py` then Godot import; `tools/run_tests.sh` passes.
3. Run a headless match and confirm audio events dispatch without errors (use the dummy audio driver: `--audio-driver Dummy`).
4. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. Settings persist, validate, and recover from corruption.
2. All SFX/music generate deterministically and validate; audio manager responds to sim events.
3. Captions work; accessibility options (gore, blood colour, shake, hit-stop, flash reduction, subtitles, text scale, patterns, hold-to-toggle, remapping data) are implemented.
4. Theme and icons applied to HUD with contrast check passing.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/16_AUDIO_UI_AND_ACCESSIBILITY.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No voice acting/TTS, no external music libraries, no one-handed layouts (deferred), no in-game settings screen UI (20) - settings are changed via a debug panel only.
2. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
