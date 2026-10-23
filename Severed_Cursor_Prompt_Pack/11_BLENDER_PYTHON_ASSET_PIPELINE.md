# Stage 11: Blender Python Asset Pipeline

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Technical artist and Blender Python pipeline developer.

## 2. Context
Stages 00-10 COMPLETE: playable greybox 1v1 with HUD. No generated art exists yet. `BLENDER_BIN` is pinned.

## 3. Objective
Build the reusable, rerunnable, safe Blender-Python generation framework (library, config, export, manifest, validation, preview) and prove it end to end with a tiny test asset imported into Godot.

## 4. Prerequisites
1. Stage 10 COMPLETE (tracker may allow starting earlier art work only if the owner asks; default is numeric order).

## 5. Workspace inspection
1. `PROJECT_STATUS.md` (Blender path/version), `docs/TECHNICAL_PLAN.md`, `docs/CONVENTIONS.md`, `docs/DECISIONS.md` (D-002, D-012, D-013, D-026).
2. GDD section 13.1 and Addendum B; Build Requirements section 2 and 'Art generation approach'.
3. Existing `tools/blender/`, `assets/` content (do not overwrite).

## 6. Implementation tasks
1. Create `tools/blender/lib/`: `cli.py` (parse args after `--`), `scene_reset.py` (idempotent: delete only objects/meshes/materials/collections whose names start with `GEN_<asset_id>` and purge orphans of that prefix; never touch other data), `primitives.py` (low-poly builders in pure `bmesh`/`bpy.data` with explicit vertex ordering: box, tapered box, capsule with N segments, tapered cylinder, wedge, cone, sphere-ish low-poly, ring, plank; all take explicit dimensions and segment counts so output is deterministic), `colors.py` (palette JSON -> vertex colour layer `Col` named attribute; flat shading), `materials.py` (one shared vertex-colour material `MAT_vcol_flat`, optional emissive/rough variants for lava/gold; no image textures), `naming.py` (enforces conventions, rejects bad names), `export.py` (glTF 2.0 binary `.glb` export with fixed settings: +Y up, apply modifiers, vertex colours exported, no cameras/lights, include custom properties as `extras`, selected collection only, no animation unless asked), `stats.py` (triangle count, bounds, vertex colour presence), `manifest.py` (writes/updates `assets/generated/manifest.json`: asset id, script, parameters hash, source script hash, output path, triangles, bounds, blender version, **deterministic content hash of the exported file**).
2. Create `data/art/art_config.json` (+schema): global palette (named colours), skin tone sets, outline/contrast rules, unit/scale rules, per-asset-type triangle budgets (fighter <= 5000 incl. costume; limb <= 600; stump <= 120; gore chunk <= 80; arena kit piece <= 400), export directory map. Scripts must read parameters from data files (`data/fighters`, `data/limbs`, `data/arenas`) not from constants in code.
3. Document conventions in `docs/ART_PIPELINE.md`: axes (state clearly: Blender Z-up, fighter faces -Y in Blender, exported glTF +Y-up; verify with a test asset how Godot orients it and record the correct sim-facing rotation in `docs/CONVENTIONS.md`), units, origins (fighter origin at feet centre), naming, socket rules, collection structure, material rules, export settings, regenerate procedure, how to open outputs in Blender for review, and the rule that generated `.glb` files are committed (D-026).
4. Create a test asset script `tools/blender/build_pipeline_test.py` (a coloured box+capsule with an Empty `SOCKET_TEST`) and run it twice to prove idempotence: the manifest hash and file hash must be identical on rerun, and object counts in the saved `.blend` (if saved to `build/blend/`) must not grow.
5. Create `tools/blender/preview_asset.py`: background render using the Workbench engine (flat/vertex colours) of a turntable contact sheet (e.g. 8 angles) plus front/side orthographic views into `build/previews/<asset_id>.png`; fall back gracefully with a clear message if rendering is impossible. Add a script that assembles contact sheets for multiple assets.
6. Create `tools/blender/validate_model.py` and a **pure-Python** GLB inspector `tools/validate/glb_inspect.py` (parses the GLB JSON chunk without Blender): extracts node names, mesh triangle counts, bounds from accessors, vertex-colour presence, scene scale, extras. `tools/validate/validate_assets.py` applies rules from `art_config.json` to every `.glb` under `assets/generated/` and to the manifest (budget, naming, required nodes, hash matches manifest, no NaN bounds, no missing files, no orphan files not in manifest). Hook into `validate_all.py`.
7. Godot side: confirm the importer handles the test asset (`--import`), write `src/presentation/model_loader.gd` (loads a `.glb` PackedScene, finds nodes by name, returns a typed `ModelInfo`), and a debug scene `scenes/debug/model_viewer.tscn` that displays any generated asset and orbit-cycles through the manifest.
8. Add `tools/blender/build_all.py` (runs every `build_*.py` in a defined order via subprocess to reduce Blender start-up cost? - prefer a single Blender session executing multiple builders when safe) and `tools/build_assets.sh/.ps1` wrappers that regenerate everything, then run the validators.
9. Ledger: record Blender, scripts and any fonts in `docs/ASSET_LEDGER.md` (script-generated: creation method, source script, date, licence of the output = project licence; note Blender itself is GPL but its output is not encumbered - mark for legal review stage 22B).
10. Tests, handoff, commit.

## 7. Technical constraints
1. Blender Python (`bpy`, `bmesh`) only; no add-ons, no external mesh libraries, no downloaded models, no generative-AI asset tools.
2. Scripts must be idempotent and must not modify unrelated data in the `.blend` or on disk.
3. Deterministic: no `random` unseeded, no timestamps in outputs, stable iteration order.
4. Do not promise professional quality; the pipeline's job is repeatability and validation.

## 8. Files and outputs
1. `tools/blender/lib/*.py`, `tools/blender/{build_pipeline_test,preview_asset,validate_model,build_all}.py`
2. `tools/validate/{glb_inspect,validate_assets}.py`
3. `data/art/art_config.json` + schema
4. `assets/generated/` test asset + `manifest.json`
5. `src/presentation/model_loader.gd`, `scenes/debug/model_viewer.tscn`
6. `docs/ART_PIPELINE.md`; ledger entries

## 9. Automated tests
1. Python unit tests for `glb_inspect` using a tiny hand-built GLB fixture and the real test asset.
2. Validator negative tests: over-budget mesh, missing socket, bad name, hash mismatch each fail.
3. Idempotence test script `tools/blender/test_idempotence.py` (runs builder twice, compares hashes) wired into `tools/check_all`.
4. Godot test: loads the test asset, finds `SOCKET_TEST`, reports expected bounds.

## 10. Execution and verification
1. Run the test-asset builder twice with `$BLENDER_BIN --background --python ...` and show identical hashes.
2. Run `tools/validate/validate_assets.py` -> pass; run negative tests -> expected failures.
3. Run the preview script and view the PNG (describe what you see; if you cannot view images say so).
4. `"$GODOT_BIN" --headless --path . --import` then `tools/run_tests.sh` pass.
5. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. One command regenerates the test asset deterministically and validators pass.
2. Rerunning produces identical files and no duplicate objects.
3. Godot imports and loads the asset; orientation convention verified and documented.
4. Preview rendering works or is explicitly UNVERIFIED with reason.

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/11_BLENDER_PYTHON_ASSET_PIPELINE.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No fighters, limbs, arenas yet (12, 13, 15).
2. No animation, no textures from files, no external assets.
3. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
