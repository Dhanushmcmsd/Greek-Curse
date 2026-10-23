# Combat rules

Stage 06 rules. Numbers come from `data/`. The lane is still x and y only (D-003). Limb integrity is stored here. Severing is stage 07.

## Hit zones

Each fighter file has hurtboxes for `standing`, `crouch`, `hop`, `crawl`, and `torso`. A box is a percent of that fighter's height and body width. The prototype uses `standing`. The other poses are data for later body states.

One attack connects with one zone:

1. `head` if it overlaps.
2. Otherwise the overlapping arm or leg with the largest overlap area. Equal areas use `zone_order` in `data/balance/combat.json` (lower index wins).
3. Otherwise `torso`.

A torso hit deals the move's scaled main damage and no limb damage. A head hit multiplies that main damage by `head_main_percent` and has no integrity (D-011). An arm or leg hit deals `limb_main_percent` of the scaled main damage and the full scaled `limb_damage`. Limb damage must be the larger of those two for the starter moves. Scaling uses `Fx.percent` and the fighter's power percent.

`SimLimbs.apply_limb_damage` subtracts integrity and stops at 0. Head and torso return 0. Integrity does not regenerate (D-024). Maximum integrity is `integrity_base` times `toughness_percent[toughness]`.

## Moves

Starter moves plus `grab` live in `data/moves/`. A move has startup, active, and recovery. The active window begins when `move_age` reaches `startup_ticks`. `hit_count` and `hit_interval` allow more than one hit. Each hit spends one window, including a whiff against dodge i-frames.

`armor_hits` on the defender's current move ignores that many hits. `unblockable` ignores block. `wall_bounce` clamps the defender to the arena and sets `y` to `launch_y` when knockback crosses a wall. Gravity is `gravity_mm_per_tick` until `y` is the floor.

## Block, stamina, dodge, grab

Block is one stance. Low and high are not separate. Holding block while not attacking sets the block flag and spends `block_stamina_per_tick`. A blocked hit keeps `block_keep_percent` of the main damage (30, which is a 70 percent reduction, D-023) and chips `block_chip_percent` of the move's scaled limb damage. The defender enters blockstun for the move's `blockstun_ticks` and is pushed by `on_block_pushback`.

Stamina starts at the match rules value. Moves spend their `cost`. Regen is `stamina_regen_per_tick` except during stagger, knockout, and hit-stop. A spend that the pool cannot cover sets stamina to 0 and stagger for `stagger_ticks`.

Dodge spends `dodge_cost`, then moves `dodge_mm_per_tick` for `dodge_ticks`. I-frames are `state_tick >= dodge_iframe_start` and `state_tick < dodge_iframe_end`. Cooldown is `dodge_cooldown_ticks`.

Grab is light plus kick (`data/moves/grab.json`). It beats block, including the damage reduction. It misses during dodge i-frames. On a hit it deals full scaled damage, swaps the two x positions, and holds both fighters for `grab_ticks`.

## Combos, buffer, meter, hit-stop

`ChainRecord` on the defender counts hits. A later hit with `tick - last_hit_tick <= combo_gap_ticks` (90) continues the chain. A gap of 91 starts a new chain and clears the per-limb totals. No sever and no combo scaling.

The input buffer keeps rising edges for `input_buffer_ticks` (6). A held button starts a move only from idle. A second press is an edge, so light into light needs a new press. Cancels fire when `move_age` is at least `cancel_start` and below `cancel_end`, and the edge names a move in `cancel_into`.

Meter fills by `meter_dealt_percent` of damage dealt and `meter_taken_percent` of damage taken, capped at `meter_max`. No ultimate is spent yet.

Hit-stop sets `hitstop_remaining` from the move. While it is above 0, fighter state timers do not advance and stamina does not regenerate. The round clock still advances. Presentation reads `hitstop_remaining`.

## Replay

`snapshot_hash()` covers positions, state, health, stamina, meter, integrity, the chain, the buffer, and hit-stop. `tools/sim/replay.gd` checks `tests/golden/*.replay.json`. `tools/sim/record_replay.gd` writes the scripted prototype replay. `--record=<path>` on the match scene writes the inputs from a live session.

## Stage 07 limb rules (supersede stage 06 placeholders)

`data/balance/limbs.json` owns integrity and severance values. Floor(integrity*100/max): >50 Healthy, 26..50 Bruised, 0..25 attached Cracked. Only the severance resolver sets Severed; zero alone never means removed. Head/torso have no limb object. Removed groups have no hurtbox.

A defender's chain includes landed blocked/unblocked hits; 90 ticks continues and 91 restarts. Three hits qualifies. New hits update the chain before sever evaluation. Non-hit damage may use the chain through last_hit+30 inclusive. Zero outside that window sets pending; next same-limb landed hit severs even after a long gap. A hit starting Healthy cannot sever. Match loss cap defaults to 2; further zero limbs remain Cracked and cap_blocked. No integrity regeneration between rounds.

Credit sums actual integrity removed per attacker per limb per chain. Equal totals choose the smallest integer attacker ID. Each limb is credited once per match. Results record limb/attacker/victim/tick/chain_hits. Career input/export persists body damage, while a new match clears credit/cap counters. Fresh Body, Versus and Practice match reset restore integrity.

Bruised attacking limb applies 90% damage. Cracked/Severed limb cannot attack; block needs one usable arm. Fury refreshes one modifier (115% damage, 120% speed) for 360 simulation ticks; no stacking, includes hit-stop. Loss adds 30% of maximum meter, clamped to maximum. Modifiers apply at move startup.

Events are SimEvent objects: actor/other are attacker/victim indices, payload always includes tick. `COMBO_EXTENDED`: chain_hits, zone. `LIMB_STATE_CHANGED`: limb, from, to, integrity. `LIMB_SEVERED`: limb, credit record. `DESPERATE_FURY_STARTED`: expires_tick, meter. `LIMB_CAP_BLOCKED`: limb, emitted once per limb. Order is combo, sever/cap, Fury if severed, state change.

The stage 06 golden input log is unchanged; its hashes are regenerated because limb flags, contributions, modifiers and records now participate. `severance_01` exercises three real jab contacts at ticks 5,22,39.

## Stage 08 body and input rules

Missing means Severed, not Cracked. Profile precedence: >=3 missing -> torso_mode; two missing legs -> no_legs; one missing leg -> one_leg; two missing arms -> no_arms; one missing arm -> one_arm; otherwise full. Combined arm/leg restrictions are applied independently of movement profile. Data speeds: full/arm profiles 100%, hop 65%, crawl 35%, torso 25%; dodge 100/70/40/55%. Cracked disables its attack but retains its movement presence. Both unusable arms permit headbutt/shoulder/bite even if still attached. No usable legs permit stump/sweep.

J/K alone use left arm; forward+J/K right arm; L uses left leg, down+L right leg. Missing bound side is ignored, never silently remapped. One remaining leg offers flying/low kicks. Torso fallback always attacks. One usable arm grab 65% damage and block keeps 50% main damage. All values/move mappings live in body_states.json. Input buffering stores direction at the button edge. Hold-to-toggle is entirely in PlayerInput. Key remap export/import has no save service yet.

Replay initial_limb_states is optional and backwards-compatible. The recorder captures hashes every 30 ticks. All 16 fixture masks have replay files and matrix evidence of movement and actual damage.

## Stage 13 regrown limbs
Regrow requires a Severed compatible slot, restores 80% of normal toughness-scaled maximum, and replaces the limb permanently. Marble maximum is 150% of normal; its starting integrity is still 80% of normal. Replacement modifiers are removed on re-sever and restored with career state. Existing once-per-slot credit and match loss cap still apply.

SimRegrown.begin extends chicken light reach to 130%, gives giant-hand heavies 140% damage, marble kicks 125% damage, and claw grabs 200% main damage (including through block). The claw holds both fighters for 30 ticks; ordinary grab has zero limb chip, so the claw benefit deliberately scales main damage rather than multiplying zero. SimRegrown.whiff applies chicken heavy self-stagger 18 ticks; claw missed grabs have seeded 25% chance of 30 ticks self-stagger. Actual contacts, not dodge/armor windows, suppress the whiff penalty.

SimModifier speed factors are marble 80%, Hermes 125%. Hermes adds 180 mm on dodge startup and, every 180 ticks while walking, has seeded 10% chance of a 200 mm left/right zoom. Giant arm hurtbox scales to 140%. All values and disclosure lines are data-driven. Chicken emits a squeak caption, giant hand waves, marble poses and claw/wing/beak parts wobble; audio comes in stage 16. No cosmetic transform affects sim.
