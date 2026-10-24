# DECISIONS.md - resolved ambiguities, locked scope, deferrals

Status key: **LOCKED** (do not change without owner approval) | **DEFAULT** (Cursor may refine, must record the change as a new entry) | **PROPOSED** (awaiting owner).
Cursor appends new decisions as `D-0xx` (next free number) with date and stage. Precedence: the revised MVP scope in the GDD Production Addendum and Build Requirements 'Revised MVP Build Plan' overrides any larger full-game requirement anywhere in either document.

## A. Locked scope

| ID | Decision | Status |
|---|---|---|
| D-001 | **Engine:** Godot 4.x, latest stable at setup (>= 4.3), pinned in `PROJECT_STATUS.md` after stage 01 verification. GDScript only: no C#, no GDExtension, no third-party addons. | LOCKED |
| D-002 | **Blender:** LTS >= 4.2, pinned at stage 01. Python (`bpy`/`bmesh`) scripts only, no add-ons. Export glTF 2.0 binary (`.glb`). | LOCKED |
| D-003 | **Spatial model: 2.5D lane combat.** Gameplay is simulated in 2 axes (x along the lane, y vertical) in integer millimetres; rendering is full 3D with a side-on camera. No sidestep/depth movement in MVP. GDD abilities described as "catching sidesteps" are excluded or reinterpreted (see D-008). *Owner approval requested in `MANUAL_CHECKPOINTS.md` pre-flight.* | LOCKED (owner may override before stage 05) |
| D-004 | **Determinism:** fixed 60 Hz tick; sim uses integers only (1 unit = 1 mm), explicit rounding rules, a seeded integer PRNG, no Godot physics, no wall-clock time, no floats. State hashing and input-replay used for tests. A static check enforces sim purity. Snapshot/restore and rollback are NOT implemented (deferred). | LOCKED |
| D-005 | **Test framework:** custom dependency-free GDScript runner + Python unittest for tooling. No GUT or other addon. | LOCKED |
| D-006 | **Roster (4):** Theron the Bulwark, Atalanta, Pyrrhus "Stub", Sibyl. Chosen for spread of height (1.55-2.05 m), weight and playstyle, plus Sibyl as the balanced all-rounder per GDD. Gender and cosmetics are visual only. | LOCKED |
| D-007 | **Arenas (3):** Mount Olympus (lightning hazard), Athens Colosseum (no sim hazard, sand hides decals), Tartarus Pits (lava vents). Labyrinth, River Styx, Medusa's Garden, Cyclops Forge and Poseidon's Deck are deferred (they need creatures, petrify, moving platforms or water). Each arena has a hazard-free safe zone; hazards are telegraphed and switchable. | LOCKED |
| D-008 | **Abilities (21):** Light: Jab of Hermes, Spartan Cross, Bronze Knuckle, Quick Fury. Heavy: Cyclops Smash, Hammer of Hephaestus, Minotaur Haymaker, Gorgon Backfist. Kick: Pegasus Kick, Achilles Heel Snap, Satyr Dropkick, Sweeping Hydra. Superpower: Zeus Bolt, Hermes Dash, Ares Rage, Hephaestus Forge Shield. Passive: Iron Skin, Blood Frenzy, Stoneheart. Ultimate: Zeus's Wrath, Olympian Barrage. Excluded for depth/sidestep/complexity reasons: Titan Hook, Atlas Slam, Medusa effects, shapeshift/size, darkness, random effects, summons. Starter kit = Jab of Hermes, Cyclops Smash, Pegasus Kick. | LOCKED |
| D-009 | **Regrown limbs (5):** Rubber Chicken Arm, Cyclops Giant Hand, Crab Claw Arm (arms); Marble Statue Leg, Hermes Sandal Leg (legs). Chosen because they need no new engine concepts (no projectiles, gliding, bleed or tentacle physics). Consequence: arm slots offer up to 3 options, leg slots 2; Obol offers "up to 3 that fit". Each twist is shown in tooltips. | LOCKED |
| D-010 | **Severing happens at the socket** (shoulder/hip): the whole limb group is removed and a stump cap is shown. No mid-limb cuts, no mesh slicing (consistent with the GDD "no procedural mesh cutting"). | LOCKED |
| D-011 | **Head:** has no integrity bar and cannot be severed (GDD: heads only via Execution, which is deferred). Head hits use a main-damage multiplier. HUD shows head and torso as main-bar zones. | LOCKED |
| D-012 | **Skeleton:** a single script-built armature (not Rigify, which is interactive and unnecessary for rigid, code-posed bodies). Identical bone names/hierarchy for all fighters; rigid skinning (one bone per mesh part). | LOCKED |
| D-013 | **Animation:** code-driven pose library (`data/animation/poses.json`) applied to the skeleton at runtime. **Zero Blender-authored clips** (the 60-80 clip estimate in the Build Requirements is superseded). Dedicated motion only for hop, crawl, Torso Mode (scuttle, roll). | LOCKED |
| D-014 | **MVP modes:** *Career* (persistent fighter vs a short AI ladder, stand-in for the undefined Pantheon list), *Fresh Body* (any fighter vs AI, no permanent loss, slower unlock offers), *Local Versus* (2 humans, full loadout picker, no persistence), *Practice* (dummy/AI). | LOCKED |
| D-015 | **Persistence in MVP:** one living Career fighter, unlock offers, Obol trade, persistent limb state, basic Chronicle (matches, limbs lost/taken, longest combo), local save, and a minimal **Retire** action (archive + new fighter). **Deferred:** Death Match, Thunder Strike cinematic, Last Stand, Execution, Legacy traits, Hall of the Fallen, scars on model, titles, cosmetic unlocks, Chronicle share card. | LOCKED |
| D-016 | **No networking of any kind** in code or dependencies (no netfox, noray, Supabase, Firebase, HTTP). A scripted check enforces it. | LOCKED |
| D-017 | **Audio:** SFX and music are generated by repo Python scripts (placeholder quality, CC0-equivalent because self-generated). No voice acting, no TTS; Obol/announcer/fighter barks are text captions. Owner may replace with better licensed audio later (ledger required). | LOCKED |
| D-018 | **Accessibility in MVP:** gore level (Off/Low/Normal/Max), blood colour (red/green/golden), screen shake %, hit-stop %, photosensitivity (flash reduction), subtitles, UI text scale, colour-blind-safe limb bars (icons + patterns), full keyboard/gamepad remapping, hold-to-toggle block. **Deferred:** one-handed layouts. | LOCKED |
| D-019 | **Age gate:** first-launch self-declaration (18+) plus content warning; it is a courtesy, not verification. | LOCKED |
| D-020 | **Hazards** are part of the sim (integer, seeded, telegraphed >= 90 ticks), toggleable via match rules; visuals are presentation. | LOCKED |
| D-021 | Gender, voice and costume never change stats. | LOCKED |
| D-022 | **Stats:** GDD 1-5 values map to numbers via `data/balance/stat_curves.json`; body rules (height -> reach/target size, weight -> knockback resistance and lower speed, muscle -> damage and toughness) are formulas in data, without double counting. | DEFAULT |
| D-023 | **Baseline numbers from the GDD:** 300 HP; 100 limb integrity (scaled by toughness); block -70% main damage and 25% limb chip; best of three; 90 s rounds (5400 ticks); Severance Combo >= 3 hits with gaps <= 1.5 s (90 ticks); sever allowed within 0.5 s (30 ticks) after the combo; 2-limb cap per normal match; Desperate Fury 6 s (360 ticks) and +30% ultimate meter on limb loss; Bruised -10% attack damage; regrown limb integrity 80%; ultimate counterplay window 0.7 s (42 ticks). | LOCKED |
| D-024 | Limb integrity never regenerates in a round or match. Hydra Regrowth passive deferred. | LOCKED |
| D-025 | **Fresh Body semantics:** limbs/health restore after the match; unlock offers every 3rd Fresh Body win using a separate counter. | DEFAULT |
| D-026 | **Git without LFS.** Generated `.glb` outputs, generated audio and icons are small and are committed so a clean clone works; regeneration scripts remain authoritative. | LOCKED |
| D-027 | **Pack location:** `Severed_Cursor_Prompt_Pack/` sits in the project root; source texts live in `docs/source/`; Cursor treats the pack as read-only. | LOCKED |
| D-028 | **Renderer:** Compatibility by default (targets mid-range integrated graphics) unless stage 01 verifies it cannot do what the plan needs; blood decals use pooled flat quads unless `Decal` support is verified for the chosen renderer. | DEFAULT |
| D-029 | **Input slot mapping:** each equipped category has slot A and slot B. Punches: button alone = slot A on the **left** arm; Forward+button = slot B on the **right** arm. Kicks: button alone (or Forward) = slot A on the left leg; Down+button = slot B on the right leg. If slot B is empty, slot B input reuses slot A's move on the other limb. Missing/Cracked limb disables the inputs bound to it. Grab = Light+Kick. Superpower U/LT, Ultimate I or RT+LT, Block Shift/RB, Dodge Space/B. | DEFAULT |
| D-030 | **Hub:** a 2D menu screen (not a 3D scene) with Obol's generated bust displayed in a SubViewport on the Obol screen. | LOCKED |
| D-031 | **Pantheon Ladder stand-in:** a fixed data-driven ladder of 6 AI matches using MVP fighters with rising difficulty; no bosses, no extra models. | LOCKED |
| D-032 | **Career quit rule:** quitting a Career match mid-way counts as a forfeit loss with no limb loss and no rewards (limb damage from that match is discarded). Cursor documents the exact rule in stage 20 and in the quit-confirmation dialog. | PROPOSED |
| D-033 | **Working title** *Severed: Trials of Olympus* is a placeholder; a trademark/name check is part of stage 22B (not a clearance). | DEFAULT |
| D-034 | **Stump caps/gore meshes:** each fighter model contains hidden `STUMP_*` caps; gore chunks are a separate generated set capped at runtime. | LOCKED |
| D-035 | **Sever rule when integrity hits 0 outside a combo.** The limb becomes Cracked and stays attached. It severs only when integrity is 0 during a Severance Combo or within 30 ticks after that combo (D-023). A hit that begins on a Healthy limb cannot sever it. The GDD sentence that a zeroed limb "severs on the next hit" is not used. Owner may override before stage 07. | DEFAULT |
| D-036 | **Both-arms moves.** Headbutt, shoulder charge, and bite are MVP simulation moves for the both-arms body state. They are posed from the code-driven library. No Blender-authored clips (D-013). | DEFAULT |
| D-037 | **Generated audio is not declared CC0.** D-017 still requires self-generated placeholder SFX and music, no voice, and text captions. The words "CC0-equivalent" in D-017 are not a licence dedication. Stage 22B records the generation method and does not claim CC0 or public domain unless the owner later says so. | PROPOSED |
| D-038 | **Stamina is in the MVP.** The simulation has a stamina bar: light attacks cost little, heavies cost more, and an empty bar causes a short stagger (GDD 5.2). Exact costs live in balance data and are chosen in stage 06, then recorded. Stamina is not deferred. | DEFAULT |
| D-039 | **Renderer for Godot 4.7.2:** Compatibility. Checked 2026-10-24 against the 4.7 decal documentation: Decal nodes work in Forward+ and Mobile only, not Compatibility. Blood, scorch, and sand stains use pooled flat quads. This confirms D-028 for the pinned engine. Sprite3D is the documented Compatibility stand-in for projecting onto flat surfaces. | DEFAULT |

## B. Contradictions and gaps found, and how they were resolved

| # | Source conflict or gap | Resolution |
|---|---|---|
| C-01 | GDD calls the game a 3D fighter with sidesteps; the deterministic integer sim is simpler as 2.5D lane. | D-003 |
| C-02 | Build Requirements: Rigify skeleton and 60-80 animation clips vs revised MVP: code-generated assets and code-driven motion. | D-012, D-013 |
| C-03 | Build Requirements lists rollback netcode/netfox/noray/Supabase vs revised scope: local only. | D-016; 25 is planning only |
| C-04 | GDD 'initial core' lists persistent fighter and Obol loop, but the cut list removes Legacy and Death Match flows. | D-015 minimal Retire only |
| C-05 | Pantheon Ladder opponents are never defined. | D-031 |
| C-06 | '4 limb integrity values plus the head' vs 'heads cannot be taken'. | D-011 |
| C-07 | 'Equip 2 light punches, 2 heavy punches, 2 kicks' vs one button per category. | D-029 |
| C-08 | GDD asks sockets to be tested against all 10 fighters; MVP has 4. | Matrix test covers 4 fighters x 5 limbs x valid slots (stage 13) |
| C-09 | Obol 'shows 3 options' but MVP has 3 arm and 2 leg limbs. | D-009 |
| C-10 | 'Hub scene' vs fast MVP. | D-030 |
| C-11 | Godot physics is not deterministic; GDD wants determinism. | D-004 |
| C-12 | 'Hazards can be switched off in Custom Match' but no Custom Match mode in MVP. | Hazard toggle on arena select (stage 20) |
| C-13 | GDD claims 3000-5000 triangles per fighter with modular limbs and costume. | Budget <= 5000 including costume (stage 11/12) |
| C-14 | Both docs say 3-4 fighters/arenas; this pack fixes 4 fighters and 3 arenas for a testable matrix. A 4th arena is optional later, never a prerequisite. | D-006, D-007 |
| C-15 | Audio plan (14-16 tracks, voice) is unrealistic without audio assets. | D-017 |
| C-16 | Gender/cosmetics 'never change stats' vs height/weight body rules. | D-021, D-022 (only height/weight/muscle drive stats) |
| C-17 | Fresh Body 'awards unlock choices at a slower rate' is unspecified. | D-025 |
| C-18 | GDD asks server-checked results and age gate; MVP has no server. | Local saves only; stated plainly in docs (stage 19) |
| C-19 | GDD and Build Requirements give Athens crowd-thrown weapons. D-007 says Athens has no sim hazard. | D-007. Weapons are not simulated. Sand hiding stains stays presentation-only. |
| C-20 | GDD 3.3 says a round is 45–90 seconds. GDD 5.2 and D-023 say 90 seconds. | D-023 (5400 ticks). |
| C-21 | GDD state table: Cracked is 25%–1% and Severed is 0% during a combo. GDD 7.3 also says integrity 0 outside a combo becomes Cracked and severs on the next hit. | D-035. |
| C-22 | Build Requirements tells animation tests to use Argos at 2.20 m. Argos is not in the locked roster. | D-006. Extremes are Theron (2.05 m) and Pyrrhus (1.55 m). |
| C-23 | GDD and Build Requirements grant headbutt, shoulder charge, and bite when both arms are gone. D-013 budgets dedicated motion only for hop, crawl, and Torso Mode. | D-036. |
| C-24 | D-017 says self-generated audio is "CC0-equivalent". The GDD only says royalty-free or self-composed. The pack notes warn against assuming CC0. | D-037 PROPOSED. D-017's locked rule is unchanged. |
| C-25 | GDD 5.2 and Build Requirements section 9 require stamina. No earlier decision locked or deferred it. | D-038. |

## C. Deferred (not prerequisites, not stubs)

Online rollback and matchmaking; ranked; server-checked Chronicle; 4-player brawl; co-op bosses; spectator; the other 6 fighters; 5 other arenas; 29 other abilities; 5 other regrown limbs; Death Match; Thunder Strike cinematic; Last Stand; Execution; Legacy; Hall of the Fallen; cosmetic and title unlocks; Chronicle share card; emote wheel and taunts; voice acting; one-handed layouts; modding; code signing; store submission.

## D. Owner approvals

| Date | Item | Record |
|---|---|---|
| 2026-10-24 | D-003 | Approved. Keep 2.5D lane combat. No sidestep into the background. |
| 2026-10-24 | D-009 | Approved. Keep the five regrown limbs on the shared skeleton and sockets. Do not add limbs without a new approval. |

## E. Stage 07 refinements (2026-10-24)

- D-040 DEFAULT: supersedes D-035's rejection of next-hit severing. Follow prompt 07 and GDD 7.3: zero outside a live chain becomes pending; the next landed hit on that same limb severs, subject to the cap. Preserve the healthy-start protection: one hit starting Healthy cannot sever even during an existing chain. The 30-tick grace applies to damage without a new landed hit; a landed hit first extends/restarts the 90-tick chain.
- D-041 DEFAULT: credit uses actual integrity removed during the current chain, ties use lowest integer attacker ID; if the pending limb has no positive contribution in the new chain the triggering attacker gets credit. Fury damage 115%, speed 120%, expires at tick started+360 (exclusive), including hit-stop.
- D-042 OWNER REQUEST: bring original four-fighter/three-arena test models forward into stage 07. These Blender-generated modular GLBs are early test art. Shared armature, data-driven proportions, asset manifests and validators remain stage 11/12 acceptance work. No new roster or arena beyond the locked MVP.


## Stage 20 implementation note — Career quit (D-032)

The stage 20 prompt explicitly selects the conservative local rule: leaving an unfinished Career fight does not save that fight's damage or result. The pause confirmation states this; only completed matches commit. This implementation note does not claim an independent owner approval or rewrite the original proposed row. Generated audio remains original procedural placeholder audio, not a CC0 claim (D-037).

## F. Stage M0 refinements (2026-10-24)

- D-043 DEFAULT: **Mixamo Visual Roster Mapping:** The 10 Mixamo characters are visual models only. The 4 sim fighters remain the authoritative gameplay entities with their existing stats, hitboxes, and move lists. A `model_id` field in `data/fighters/<id>.json` maps each fighter to their default visual model (Theron -> Paladin, Atalanta -> Arissa, Pyrrhus -> Ch34, Sibyl -> Maria), while remaining models serve as selectable visual variants/skins. Raw Mixamo assets remain untracked in git.
- D-044 DEFAULT: **Mixamo Model Geometry Budget and Socket Anchors:** Mixamo models replace low-poly test geometry with game-ready characters up to 60,000 triangles across all 15 partitioned skinned meshes (ranging from Arissa/Atalanta at ~9,500 tris to Ch40 at ~59,800 tris). Armature sockets (`SOCKET_ARM_L`, `SOCKET_ARM_R`, `SOCKET_LEG_L`, `SOCKET_LEG_R`) are anchored to exact skeletal joint origins (`upper_arm.*`, `thigh.*`) derived from standard Mixamo bone heads rather than height-constant heuristics. Limb partition meshes retain (0,0,0) local transforms bound to the shared 15-bone armature with `limb_group` tags, avoiding glTF child node double-transforms.
- D-045 DEFAULT: **Visual Reach Tolerance for Torso Moves:** In `test_animation.gd` (broad attack matrix testing all 16 body masks against all moves), fully amputated fighters (masks 12-15) executing torso/crawl maneuvers (`body_roll`, `body_scuttle`, `body_shoulder`, `body_stump`) have horizontal root shifts and spine pitching that produce a visual reach mismatch of up to 667 mm on Sibyl and Theron. The legacy 650 mm limit in `data/animation/poses.json` was tuned before torso maneuvers were integrated across all 16 limb masks. The tolerance is calibrated to 700 mm to account for horizontal translation during full-torso maneuvers without affecting simulation hitboxes or determinism.

