# Combat playtest

## HUD refresh and normal-launch fixes

The combat screen now uses two compact fighter cards, a central timer/score, readable
limb status, and separate power and ultimate meters. **U** is power; **I** is ultimate.
Starter career fighters receive a native Zeus's Wrath ultimate at 100% ULT even when
their saved equipment has no ultimate slot. Equipped ultimates still take priority;
this does not edit saves or unlock the equipment catalog. Saved custom loadouts now
use character-specific attack mappings instead of reverting to generic animations.
Zeus Bolt also uses overhead lightning instead of the old horizontal placeholder beam.
Keyboard press edges are retained until the next combat tick so very short taps are
not lost between held-key polls. Pause and round introductions clear pending edges.

Restart the running game to load these scripts. The updated HUD has rounded dark
fighter cards and a gold `[I] ULTIMATE` meter at the bottom left. Verification captures
are `build/hud_refresh_ready.png` and `build/hud_refresh_ultimate.png`.
`tools/capture_hud_refresh.gd` verifies the normal MenuHost launch with starter equipment
and injected input-handler events. Add `-- --native-input` for a manual I/J key test;
it waits at a ready meter for I, then waits for J after the strike. This fixture supplies
meter only for verification; normal matches still require earning charge.

## November 2: fight performance, transitions, thunder, and sever reactions

Close the running game and restart the editor before testing these baked animation resources.
Open `E:/zeus balls/project.godot` with the provided Godot 4.7.2 executable and press **F5**.

- Try Pyrrhus against Theron first. Alternate **A/D**, **Shift**, attacks, and **G** grabs.
  Walking, blocking, attacks, hit reactions, throws, ultimates and return-to-idle now use
  one outgoing-pose transition. The previous animation is not left playing underneath.
  Repeated hits restart reactions; hitstop holds the solved pose and transition clock.
- Build the **ULT** meter to 100%, then tap **I** with an ultimate equipped. Zeus's Wrath
  has a charge sigil followed by branching lightning from overhead on connection.
  A successful hit stuns for **60 simulation ticks (one gameplay second)**. A block
  keeps ordinary blockstun; a miss does not grant damage or stun. Olympian Barrage's
  final strike also receives the overhead finisher and one-second stun.
- Each fighter has an imported Supermove cast and distinct lightning color, branching
  pattern and sigil: Theron gold/four-point, Pyrrhus ember/three-point, Atalanta teal/seven-point,
  Sibyl violet/eight-point and Dorian cyan/five-point. Thunder audio is synchronized to impact.
  Effects reuse the supplied flare/ring artwork and new procedural lightning/sigil shaders.
  Reduced-flash settings lower intensity and omit the impact light.
- When an arm or leg is severed, the victim now plays the supplied ArmSlice/OneLegHop
  brutality reaction for the affected limb. Missing meshes stay hidden. Existing severance
  rules and gore settings still control when limb loss occurs. Reactions yield to player actions.
- Added **35 baked animation bindings** from Shared/Anim/Brutality, Shared/Anim/Reaction,
  and the character Supermove folders. Existing head/body/low-hit source reactions remain.
  Source paths and SHA256 checksums are in `data/animation/cinematic_source_manifest.json`.

Performance verification on this machine: the same headless 150-sample pose benchmark
reduced median milliseconds per fighter from Theron 1.672 to 0.630, Pyrrhus 7.006 to 0.931,
Atalanta 0.811 to 0.675, Sibyl 1.896 to 0.711, and Dorian 1.441 to 0.687.
Floor contact now uses at most 384 weighted samples per mesh surface, preserving local
extrema instead of skinning every vertex on the CPU every frame. A comparison test checks
sampled floor heights against full skin deformation across the roster. Cosmetic particles
no longer cast shadows; ultimate effects have a six-instance cap and finite lifetimes.
These CPU measurements are not a guarantee of FPS on every graphics setting or machine.
Validation: 46 focused tests passed across cinematics, hands, styles, combat repairs,
powers/grabs, abilities, severance, character fit, combat depth and rig deformation.
Godot LSP reported zero diagnostics across 93 source scripts. The rendered roster pass
confirmed 60-tick lightning stun and all three sever-reaction selections for every fighter.

Verification tools: `tools/benchmark_combat_pose.gd`, `tools/capture_cinematic_combat.gd`,
and `tests/unit/test_cinematic_combat.gd`. Rebuild new sources with
`python tools/anim/import_cinematic_motion.py "<rea folder>"`, then Godot headless
`--path . --script tools/anim/retarget_exported_motion.gd -- cinematic`.
The original export folders are never needed to play the already-baked assets.

## Latest: hand hierarchy, charge powers, grabs, and extra links

Close the running game/editor, reopen `E:/zeus balls/project.godot`, and press F5.
All converted assets are inside the project; the export folder is only needed to rebuild.

- **Hands:** finger/helper bones now follow corrected wrists instead of counter-rotating
  into their previous world orientation. Rebuilt the roster's attacks, chains, states,
  and reactions. Missing anatomical-chain endpoints now retain local motion safely.
  A synthetic retarget test verifies the finger relationship, alongside arm-length,
  torso-clearance, and wrist-angle regressions. No replacement character mesh was needed.
- **Power:** a separate cyan bar fills from confirmed hits. Consecutive uninterrupted
  hits add 12, 15, 18, 21, then 24 charge per hit (100 maximum). Blocks and whiffs
  grant none. Being hit resets the consecutive-hit bonus; accumulated charge remains.
  The bar glows when charge, cooldown, and stamina allow activation. Tap **U** to spend
  the charge. Cooldown seconds or LOW STAMINA explain why a full bar is not ready.
  **I** still uses the separate ultimate meter. Holding U does not repeatedly activate.
  Career fighters without an equipped super receive a native fallback; an equipped
  super takes priority. Activation has a visible ground ring and impact effect.
- **Arcade counter:** large confirmed-hit counts pop at the attacking player's left/right
  edge, exclude blocks, and reset after a break/interruption. Reduced-flash settings
  reduce the pop and meter pulse.
- **Grab:** **G** is a dedicated keyboard grab; **J + L** remains valid. Player two uses
  **Keypad 0**. Grabs now play attacker hold/release and victim animations, interpolate
  the throw instead of snapping, and fit the attacker's hands to the victim during
  the hold. Approach to grappling distance; grabs cannot reach across the arena.
- **New moves:** each fighter has two new openers that can link into their finisher:
  Theron — Bastion Palm / Granite Cross; Atalanta — Falcon Counter / Huntress Feint;
  Pyrrhus — Furnace Hammer / Cinder Heel; Sibyl — Omen Strike / Twilight Sweep;
  Dorian — Encore Cross / Spotlight Heel. All require four usable limbs.
- **New movement:** exported dodge clips for all five fighters; distinct Geras/Havik
  forward/back loops for Theron/Sibyl. Existing character movement remains bound.
- **Combo page:** F2 lists actual configured player-one keyboard keys, including the
  new links and grab. `[D/A]` means D when facing right, A when facing left.

New default commands while facing right:

- **S + D + J**: new counter opener; facing left use **S + A + J**.
- **S + A + K**: new breaker opener; facing left use **S + D + K**.
- On a landed opener, release the key and tap **K** for Theron/Pyrrhus or **O** for
  Atalanta/Sibyl/Dorian during COMBO NOW. Each link is two actual strikes.
- **U**: charged superpower; **I**: ultimate; **G**: grab; **F2**: key list.

Validation: seven new power/grab/command/link/determinism tests pass, plus 21 checks
across hand placement, fighter styles, abilities, combat repairs, and Dorian motion.
Career (5), input (3), and combat-action (3) tests also passed. Rendered charged bars,
casts, throw hold/release poses, and new attacks for all five fighters. Latest source
scan: 92 scripts, zero diagnostics. Golden replay hashes predate the new charge/input
state and were not rebaselined; this is not a claim that the complete legacy suite passes.
Rendered samples and skeleton constraints do not prove zero costume intersections.

Source provenance: `data/animation/expansion_source_manifest.json` records 34 new
bindings (10 attacks, 15 throw states, 5 dodges, 4 walk loops) and SHA-256 hashes.
No `.json` exports were found under the supplied `rea` directory; PSA data was imported
into the game's move JSON format. `tools/anim/extract_combat_sources.py` can reproduce
these intermediates from the original exports.


## November 1: effects, career, and Dorian

Close the running game **and editor**, then reopen `E:/zeus balls/project.godot`
and press F5 so renamed model imports and scripts are refreshed.

- Johnny Cage is now **Dorian — the Spotlight**. Runtime fighter, model, texture,
  animation, move, test, and tool filenames/references use `dorian`. Original
  external source paths remain intact in provenance manifests. The mesh is unchanged.
- Career creation includes Dorian. Career matches enable the same fighter styles,
  new walks, guards, reactions, combo menu, and visual effects as other modes.
  Explicit custom loadouts outside career still keep their selected moves.
- Fast fighters now select the new walk instead of bypassing it with the old run.
  Walk cadence is bounded; wrists are limited relative to the forearm after IK.
- Added layered export-based flare/spike artwork, thin expanding impact rings,
  block shields, animated dust, colored hand/foot trails, and textured droplets.
  Theron: gold; Atalanta: mint; Pyrrhus: ember; Sibyl: violet; Dorian: cyan.
  Flash reduction and gore-off settings still apply.
- Foreground pillars are taller/wider, with fluting and a matte, mipmapped stone
  material derived from the backdrop reference.
- Fixed shadowed variables, enum casts, incompatible numeric branches, and unused
  fields. Intentional integer divisions are documented at their statements.
  Bound effect tweens to their nodes and guarded the delayed particle callback.

Test **Career > New fighter > Dorian**, start a match, walk A/D both ways, block
with Shift, and attack with J/K/L/O. F2 opens combos. Repeat with Theron and Atalanta.
Check both facing directions, successive hits, block impacts, and flash reduction.

See `data/art/combat_art_sources.json` for the five copied source textures/hashes.
The generated pillar asset is `assets/environment/ruins/pillar_stone.png`, made
with the built-in imagegen tool from the existing Olympus backdrop. Prompt:
"Seamless square PBR albedo of the reference temple pillar stone; flat orthographic,
evenly lit weathered charcoal-grey limestone, subtle warm-grey ochre veins, pores
and age cracks; matte, no objects, perspective, shadows, highlights, sky or text."


## Current validation

- Godot 4.7.2 import passes; language-server scan: 92 source scripts, zero diagnostics.
- Full suite: 193 passed, four failed. The obsolete forward-heavy expectation was
  updated for the signature command; its entire 16-test suite then passed.
- Three known failures remain: prototype replay hash, prototype deterministic golden
  hash, and cross-character fallback visual reach (including another fighter using
  Dorian Shadow Kick). Golden fixtures were not rewritten to hide these failures.
- Hand/wrist, career save roundtrip and styles, authored animation binding, Dorian,
  fighter styles, and combat repair suites pass. Career creation and all five
  fighters' movement, block, and combat poses were rendered and spot-checked.
- Rendered career VFX stress: 480 impacts with a bounded particle pool and no runtime
  errors. The test does not establish AAA production quality or prove every mesh
  vertex remains separated in every frame.

## Hand placement and locomotion update

Stop any running game before testing, reopen this project, and press F5. All five
fighters now bind newly converted forward walk, backward walk, and block loops
from the supplied `rea` folder. Menu previews use the same corrected pose driver
as combat.

The animation transfer now accounts for the source bind-position Y convention,
aligns clavicles and hands, and preserves original global wrist orientation when
changing parent joints. Ready/block guards stay in front of the upper body instead
of accepting an overhead collision fallback. During attacks the supporting hand
uses the fitted guard while the striking arm retains its authored motion.

Check each fighter in character select, then use A/D to walk in both directions,
Shift to block, and J/K/L/O to attack. Repeat after swapping sides. New regression
checks verify hand height/separation and the actual walk/block resource bindings
for all five fighters. This update passed 21 focused tests across hand placement,
fighter styles, Johnny animation, combat repairs, and character fit, plus rendered
menu/movement/block/combat spot checks. Costume surfaces still require visual
playtesting; these checks do not prove zero intersections in every animation frame.

Open `E:/zeus balls/project.godot` in your Godot 4.7.2 installation and press F5.
Choose Practice, select the fighters, and choose an idle or blocking dummy for player 2.
The new resources are in the project; Blender and the original export folder are not
needed to play.

For a direct Johnny-versus-idle-dummy test, run this in PowerShell:

```powershell
& 'D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --path 'E:\zeus balls' --script res://tools/playtest_combat.gd -- --fighter dorian --dummy idle
```

Replace `dorian` with `theron`, `atalanta`, `pyrrhus`, or `sibyl`.
Replace `idle` with `block_always` to test guards, or `attack_on_interval` to test
your own fighter receiving punches. This launcher disables arena hazards.
An equivalent parameterized launcher is `tools/playtest_combat.ps1`.

## Default player-one controls

- A / D: move. S: crouch.
- J / K: left / right punch. L / O: left / right kick.
- Shift: block. Space: dodge. B: body attack.
- F2 or the **Combo list** button: pause combat and open the combo menu.
  Use its fighter dropdown to browse all five fighters. Escape closes it.
- R or **New match**: reset in the direct playtest. Escape outside a panel: pause.
- Custom bindings in Settings take precedence over the default attack keys above.

## New signature combos

While facing right, hold D and tap K for Theron, Atalanta, Pyrrhus, or Sibyl.
While facing left, use A + K instead. These are respectively **Bulwark Breaker**,
**Huntress Crescent**, **Forge Rush**, and **Oracle Spiral**.

Dorian's **Hollywood Double Take** is S + D + O while facing right, or S + A + O
while facing left. Hold the directions and tap the attack key; no motion-input
sequence is required. Each signature costs 20 stamina and plays three strikes.
All four limbs must be usable because these are full-body combinations.

For the optional fourth-hit follow-up, release the attack button, wait until the
third strike connects and **COMBO NOW** appears, then tap:

- Theron / Pyrrhus: K.
- Atalanta / Sibyl / Johnny: O.

The link window is short (8 simulation frames). You can tap just before it opens
to use the input buffer. A whiff does not unlock the follow-up. Do not hold the
attack key continuously; follow-ups require a new press.

## Repeatable checks

1. With an idle dummy, approach until a standing punch reaches. Open F2 and confirm
   the selected fighter's signature and input are listed. Close the menu.
2. Perform the signature. Expect three hit events/reactions, followed by recovery.
   Repeat with the listed follow-up. Reset with R between trials if stamina or health is low.
3. Try standing punches and crouching kicks. Head hits should recoil the upper body,
   torso hits should fold the body, and leg hits should disturb the leg/stance.
   Repeated hits must restart reactions, not reverse them. Hitstop should freeze both poses.
4. Repeat with the blocking dummy. Expect block-impact motion rather than an unblocked
   hit reaction. Watch the wrists, forearms, elbows, knees, and shins through recovery.
5. Use the attacking dummy and let yourself be hit, then hold Shift. Compare hit and
   guard reactions. Walk to the other side and repeat to verify facing.
6. Run the same checks with all five fighters. At close range, watch chest overlap
   as well as each character's own limbs. Cloth and costume surfaces need visual review too.

## What changed and what was checked

- Corrected the defender animation clock: stun/throw `state_tick` counts down and
  is no longer used as elapsed animation time. KO has its own forward playback age.
- Added 30 retargeted head/body/low/stagger reaction resources from
  `rea/MK12/Content/Disk/Shared/Anim/Reaction`, with source hashes recorded.
- Added five exported attack finishers and five three-hit stitched signature clips.
  Strike markers match the simulation's three hit times. Missing limbs reject the
  full-body combo before stamina is spent.
- Added torso/forearm and opposing-limb clearance correction that preserves joint
  lengths. Extreme, unreachable cross-body poses recover to an exterior arm pose.
  A bounded presentation correction also separates fighters' torsos during close contact.
- Replaced the generic combo menu's mixed roster listing with a fighter dropdown,
  fighter-specific commands, signature descriptions, and follow-up instructions.
- Focused tests: 23 passing across combat repairs, Johnny animation, fighter styles,
  character fit, and combat presentation. The former fixed-wrist guard assertions
  now test actual torso clearance and unchanged joint lengths instead.
- Sampled 2,896 attack/reaction poses: worst forearm/torso capsule penetration below
  5 mm; minimum sampled opposing shin-centerline distance 12 cm. Captured in-engine
  gameplay and menus for all fighters. Godot import and direct launch pass.

These are capsule and sampled-pose checks, not a proof that every costume vertex
can never intersect during every possible limb/fighter combination. Johnny still
uses the existing placeholder mesh. The old full-suite golden-hash/fallback-reach
issues documented in `combat_animation_update.md` were not rebaselined here.

## Rebuild exported assets

`python tools/anim/extract_combat_sources.py` verifies source hashes and rebuilds
intermediates. Use `--export-root` with a relocated `rea` directory if needed.
Run `retarget_exported_motion.gd -- states` for reactions;
`retarget_exported_motion.gd -- combos`, then `calibrate_exported_contacts.gd -- combos`,
then `build_exported_chains.gd -- combos` for the new signatures.
Use Godot's `--headless --path . --script res://tools/anim/...` invocation for each tool.

