# Stage 12: Shared Skeleton Modular Fighters And Sockets

## 0. Standing rules
- Treat the revised GDD, revised Build Requirements, `docs/DECISIONS.md`, and `PROJECT_STATUS.md` as source of truth. The locked MVP and decisions override older full-game scope.
- Inspect before editing; preserve existing user work; avoid unrelated rewrites.
- Implement, run checks, fix failures, verify acceptance criteria, update the tracker, and write a handoff report.
- Do not claim a test/build/tool ran unless you actually executed it. Mark anything impossible to verify as UNVERIFIED with a reason.
- Keep `Severed_Cursor_Prompt_Pack/` read-only. Never silently weaken/delete tests to get green.
- Ask the owner only for consequential decisions or tasks that cannot be automated safely.

## 1. Role
Technical artist / character pipeline engineer.

## 2. Context
Stage 11 COMPLETE: Blender pipeline, validators, model loader and viewer exist.

## 3. Objective
Generate the shared armature, modular body parts, sockets, stump caps and the four MVP fighters (Theron, Atalanta, Pyrrhus, Sibyl) from data parameters, and make the Godot rig layer able to show/hide limbs and stumps. **Visual quality gate included.**

## 4. Prerequisites
1. Stage 11 COMPLETE.

## 5. Workspace inspection
1. `docs/ART_PIPELINE.md`, `data/art/art_config.json`, `data/fighters/*.json` (existing sim parameters), `tools/blender/lib/*`.
2. GDD 4.1-4.3 (heights/weights/cosmetics), 13.1; Build Requirements 'Sockets and stump caps'; D-006, D-010, D-012, D-021.

## 6. Implementation tasks
1. Extend `data/fighters/<id>.json` with a `body` block: `height_m`, `weight_kg`, `muscle` (0-100), proportion multipliers (shoulder width, hip width, limb length ratios, head scale), `skin_tone`, `palette_ids` (3 palettes each), and `cosmetics` list of costume part ids with parameters. Fighters: theron (2.05 m/130 kg, heavy muscle; bronze helm, scarlet cape, scarred chest), atalanta (1.78/62; braid, quiver strap, hunter leathers), pyrrhus (1.55/70 stocky wrestler; olive wreath, belt), sibyl (1.75/68; veil, robes, laurel). Update schema. Gender is cosmetic only (D-021): no stat links to model parameters except the body rules in D-022 that come from height/weight/muscle.
2. `tools/blender/lib/skeleton.py`: builds the single shared humanoid armature from a proportion table (bone names fixed per conventions; same hierarchy, same bone count, for every fighter; only rest-pose lengths/positions scale). Provide `build_armature(params) -> armature`. Rest pose is a neutral A- or T-pose chosen once and documented.
3. `tools/blender/lib/body_parts.py`: parametric generators for head, neck, torso (chest+pelvis), upper arm, forearm, hand, thigh, shin, foot using primitives; widths scale with weight/muscle, lengths with height and proportions; each part tagged with its bone and limb group. Rigid skinning: every part's vertices weight 1.0 to one bone (vertex groups), no blend weights needed. Keep faceted stylised silhouettes (broad shoulders, tapered waist, chunky hands/feet) readable at combat camera distance.
4. Sockets: Empties `SOCKET_ARM_L/R` at the shoulder joints, `SOCKET_LEG_L/R` at the hips, `SOCKET_NECK`, parented to the proper bones, with orientation and an agreed local axis convention documented. Stump caps: `STUMP_ARM_L/R`, `STUMP_LEG_L/R` hidden-by-default mesh nodes (a flat low-poly cap with a red cross-section and a small bone-white disc) sized from the fighter's limb thickness at the socket, parented to the socket; (D-010 severing happens at the socket).
5. Limb groups: `LIMB_ARM_L/R` and `LIMB_LEG_L/R` are parent nodes grouping upper+lower+hand/foot meshes so the Godot rig can hide an entire limb in one operation; clothing parts attach to the correct limb group or torso.
6. Costume generators in `tools/blender/lib/costumes.py` (helm, cape, wreath, braid, quiver strap, belt, veil, laurel, robes, leathers, scars as vertex-colour decals): small, low-poly, data-driven, palette-driven. Budget <= 5000 triangles per complete fighter including costume.
7. `tools/blender/build_fighter.py --id <id>` (and `build_fighters.py` for all four). Export `assets/generated/models/fighter_<id>.glb` including skeleton, meshes, sockets, stumps, limb groups, and `extras` (height_m, socket list). Update manifest; run preview contact sheets for all four side by side at true relative scale in `build/previews/roster.png`.
8. Godot rig layer `src/presentation/fighter_rig.gd` (`FighterRig`): load model, resolve `Skeleton3D`, sockets, limb groups, stumps; API `set_limb_visible(slot, bool)`, `show_stump(slot, bool)`, `attach_to_socket(slot, node)`, `get_socket_transform(slot)`, `apply_palette(id)`; validates that all required nodes exist and logs ERROR if not. Replace the greybox boxes in `FighterView` with `FighterRig` (keep a fallback to boxes only if the model fails to load, with a logged ERROR).
9. Validators: required node/bone names present; identical bone hierarchy across all fighters (hash of names+parents); socket positions within tolerance of expected proportions; stump caps within limb thickness +/- tolerance; triangle budgets; scale sanity (fighter height within 1% of `height_m`); no vertices below the floor by more than 1 cm; limb groups non-empty.
10. Visual quality gate: view `roster.png` and per-fighter previews (if you can view images). List concrete visual problems (silhouette, proportions, clipping, unreadable costume) and fix at least the top issues by editing parameters/generators. Record before/after notes. State clearly that automated checks do not prove good looks; the owner reviews at Checkpoint B.
11. Tests, ledger, handoff, commit.

## 7. Technical constraints
1. Same skeleton and socket convention for all fighters (no per-fighter special cases in code).
2. Everything is parameter-driven from data files; adding a fighter must require data only (prove by adding a temporary fifth fixture fighter in a test, then removing it).
3. <= 5000 tris per fighter; flat shaded vertex colours; no image textures.
4. Do not generate regrown limbs yet (13).

## 8. Files and outputs
1. `tools/blender/lib/{skeleton,body_parts,costumes}.py`, `tools/blender/{build_fighter,build_fighters}.py`
2. `assets/generated/models/fighter_{theron,atalanta,pyrrhus,sibyl}.glb` + manifest
3. `src/presentation/fighter_rig.gd`; updated `FighterView`
4. Validators + tests, `build/previews/roster.png` (not committed), docs/ART_PIPELINE.md updates

## 9. Automated tests
1. Asset validators (above) over all four fighters; negative fixtures.
2. Godot: load each fighter, resolve every socket/limb group/stump, hide/show each limb, assert visibility changes and no errors.
3. Determinism: regenerate and compare hashes.
4. Data-only addition test (temporary fighter fixture generates successfully).
5. Height ordering test: Pyrrhus < Sibyl < Atalanta < Theron within tolerance.

## 10. Execution and verification
1. `tools/build_assets.sh` then `tools/validate/validate_assets.py` pass.
2. `"$GODOT_BIN" --headless --path . --import`; `tools/run_tests.sh` pass.
3. Generate and inspect previews; list issues found/fixed.
4. Windowed (if possible): `model_viewer.tscn` screenshot of each fighter; else UNVERIFIED.
5. `tools/check_all.sh` exits 0.

## 11. Acceptance criteria
1. Four fighters generate deterministically from data on one shared skeleton with identical bone hierarchy.
2. Sockets, limb groups and stump caps exist and validate on all four.
3. Godot rig can hide limbs and show stumps; match scene uses real models.
4. Triangle budgets met; ledger updated.
5. Visual review notes written (owner judgement pending).

## 12. Failure handling
If any command, test, import, build, export, or acceptance criterion fails: stop the stage from being marked COMPLETE; capture the exact error and relevant logs; diagnose the smallest root cause; apply the smallest safe fix; add a regression test where applicable; rerun the failed check and relevant suite. If blocked by missing tools or permissions, document exact owner action and mark BLOCKED rather than guessing.

## 13. Handoff report
Write `docs/handoff/12_SHARED_SKELETON_MODULAR_FIGHTERS_AND_SOCKETS.md` including: stage result; changed files; actual commands run; test results; acceptance criteria PASS/FAIL/UNVERIFIED with evidence; known bugs/blockers; decisions made; owner action if any; and **Next prompt to execute** with the exact filename. Update `PROJECT_STATUS.md` truthfully.

## 14. Scope guard
1. No regrown limbs, arenas, animation clips, textures from files, or voice.
2. Do not hand-edit generated `.glb`/`.blend` files; change generators instead.
3. Do not implement deferred features: online/rollback/matchmaking/ranked, four-player brawl, co-op, spectator, additional roster/arenas/abilities/limbs beyond locked MVP, Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy, Hall of the Fallen, cosmetic unlocks, Chronicle share card, voice acting, one-handed layouts, modding, monetisation, or paid services. Keep the game free.

**Next prompt to execute:** determine from `PROMPT_INDEX.md` and `PROJECT_STATUS.md`; do not skip prerequisites.
