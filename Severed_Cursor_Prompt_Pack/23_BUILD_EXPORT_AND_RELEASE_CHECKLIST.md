# Stage 23: Build Export And Release Checklist

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Build and release engineer.

## 2. Context
Stages 21, 22 and 22B COMPLETE: tests green, performance/bugs addressed, legal docs prepared. `VERSION` is a dev version.

## 3. Objective
Create repeatable export presets and build scripts, produce packaged Windows and Linux builds, test the actual exported build (not the editor), assemble the release documents, and prepare the release-candidate package for **Human Checkpoint D**.

## 4. Prerequisites
1. Stage 22B COMPLETE (and 21, 22).

## 5. Workspace inspection
1. `PROJECT_STATUS.md` (pinned Godot version, export templates yes/no), `project.godot`, existing `export_presets.cfg`, `docs/release/*`, `THIRD_PARTY_LICENSES.md`, `tools/build/*`.
2. Godot documentation for the pinned version on exporting from the command line (use the installed engine's `--help` and docs knowledge; verify flags).

## 6. Implementation tasks
1. Export templates: check the installed templates for the pinned version. If missing, try the engine's supported method; if it requires the editor UI or a download that cannot be automated, stop and give the owner exact steps (Editor -> Project -> Export -> Manage Export Templates -> Download and Install; ~3 minutes; return a screenshot of 'installed' or the command `godot --version`) and mark BLOCKED until done.
2. Create `export_presets.cfg` with presets `Windows Desktop` and `Linux` (x86_64): embed PCK where practical, application name/icon (generate an icon with `tools/ui/generate_icons.py` and ledger it), version from `VERSION`, exclude dev content via export filters (`tests/`, `tools/`, `docs/`, `Severed_Cursor_Prompt_Pack/`, `scenes/debug/`, `build/`, `*.py`, source previews) while keeping data/models/audio/ui needed at runtime; strip debug in release; ensure no `res://` path used at runtime points to excluded content (verify with a script that scans `src/` and `data/` for debug/test references). **macOS is not a target.**
3. Build info: `src/core/build_info.gd` reads a generated `data/build_info.json` (version, git commit, build date UTC, Godot version) shown on the main menu/credits and written to logs.
4. `tools/build/build_release.sh` and `.ps1`: (1) verify clean git state or warn, (2) regenerate all assets and verify committed outputs unchanged (fail if generation changes tracked files unexpectedly), (3) run `tools/check_all --full`, (4) generate credits/build info, (5) export each preset via `--headless --export-release`, (6) copy `README_PLAYER.txt`/`README.md`, `LICENSE` (if owner approved; else include the draft marked clearly), `THIRD_PARTY_LICENSES.md`, `CONTENT_WARNING.md`, `RELEASE_NOTES.md`, `KNOWN_ISSUES.md` into the package, (7) zip per platform, (8) write SHA-256 checksums, (9) print a summary. The script must stop on first failure with a clear message.
5. Export smoke test of the **exported binary** (`tools/build/test_exported_build.sh/.ps1`): run the exported executable with `--headless`-compatible flags where supported or windowed with a virtual display if available, using `-- --autoplay-smoke --user-profile <temp dir>`; require exit code 0, `smoke_result.json` showing content loaded (4 fighters, 3 arenas, 21 abilities, 5 limbs), one full match completed, no 'Failed loading resource', 'ERROR' or missing-file lines in the log (scan the log). Also run `--autoplay-career`. If the exporting machine is Windows or Linux only, test only that platform's build and mark the other `UNVERIFIED` - say so in the release notes.
6. Clean-profile test: run the exported build with a fresh empty user-data location (override `APPDATA`/`XDG_DATA_HOME`/HOME or use the profile flag) to confirm first-launch flow (age gate, content warning, settings defaults) and that no files outside the user data directory are written. Corrupt-save and corrupt-settings recovery tested against the exported build.
7. Missing-resource audit: temporarily remove a data file in a copy of the build and confirm the error screen appears instead of a crash (document result), and scan the PCK file listing for expected resources.
8. Release documents: `README.md` for players and developers (install, run, controls, settings, accessibility, content warning, troubleshooting, how to find logs/saves, how to build from source with exact tool versions, how to regenerate assets, how to run tests), `RELEASE_NOTES.md` (verified features list; known issues; platform verification status), `docs/release/RELEASE_CHECKLIST.md` (checkable list incl. legal items, store page, content warning, checksums, owner approvals), and `docs/release/KNOWN_ISSUES_PUBLIC.md`.
9. Version: set `VERSION` to `0.1.0-rc1` (or per owner), tag suggestion `v0.1.0-rc1` - **do not create the tag** until the owner approves; produce `build/Severed_<version>_<platform>.zip` and checksums.
10. Prepare Checkpoint D package `docs/playtest/CHECKPOINT_D.md` pointing at the exported zip and the clean-launch procedure; commit.

## 7. Technical constraints
1. Always test the exported build, not the editor run.
2. Do not upload or publish anywhere.
3. No code signing or notarisation work (record as post-MVP item; note that unsigned Windows builds may trigger SmartScreen warnings - verify this statement only if you can; otherwise label as assumption).
4. No online dependencies in the build.

## 8. Files and outputs
1. `export_presets.cfg`, `src/core/build_info.gd`, `tools/build/*`
2. `build/Severed_<version>_{windows,linux}.zip` + checksums (uncommitted)
3. `README.md`, `RELEASE_NOTES.md`, `docs/release/RELEASE_CHECKLIST.md`, `KNOWN_ISSUES_PUBLIC.md`
4. `docs/playtest/CHECKPOINT_D.md`

## 9. Automated tests
1. Exported-build smoke + career autoplay tests (scripted, with log scan).
2. Build script dry-run tests (python unittest for the log scanner and package-content verifier: every required file present, no dev folders).
3. Package content verifier `tools/build/verify_package.py` (lists zip contents, checks required docs, absence of `tests/`, `tools/`, debug scenes, source `.blend`, `.py`).
4. Corrupt-settings/corrupt-save recovery run on exported build.

## 10. Execution and verification
1. Run `tools/build/build_release.*` end-to-end; paste the summary and checksum lines.
2. Run `tools/build/test_exported_build.*` and paste result + log-scan result.
3. Run `verify_package.py` and paste output.
4. State clearly which platform builds were actually run and which were not.

## 11. Acceptance criteria
1. Repeatable one-command build produces packages for the target platforms.
2. At least the owner's-OS exported build passes the smoke test, career autoplay and clean-profile test with zero missing-resource errors; other platform marked UNVERIFIED if not run.
3. Package contains required legal/readme files and excludes dev content.
4. Release docs complete and consistent with verified features.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/23_BUILD_EXPORT_AND_RELEASE_CHECKLIST.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No new features, no publishing/uploading, no signing, no auto-updaters, no installers beyond zip, no analytics/crash reporting services.
2. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
