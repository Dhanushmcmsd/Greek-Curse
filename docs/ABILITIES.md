# Abilities

Generated from data/abilities. Loadouts: two light, two heavy, two kick, one superpower, passive and ultimate. U activates superpower; I ultimate; forward+attack selects B (down+kick selects B). Ultimate startup is 42 ticks. Buffs refresh by kind, never stack with themselves. Cooldowns use absolute simulation ticks, including hit-stop.

## Achilles Heel Snap
Low kick that deals bonus damage to legs.
Type: kick; cooldown 0 ticks; stamina 14; meter 0.
Effects: []

## Ares Rage
+25% damage for 6 s, but +15% damage taken.
Type: superpower; cooldown 1200 ticks; stamina 20; meter 0.
Effects: [{"kind": "buff_self", "timing": "begin", "duration": 360, "damage_percent": 125, "taken_percent": 115}]

## Blood Frenzy
Move and attack faster as main health drops.
Type: passive; cooldown 0 ticks; stamina 0; meter 0.
Effects: [{"kind": "blood_frenzy", "maximum": 135}]

## Bronze Knuckle
Armoured punch that beats opposing light attacks.
Type: light; cooldown 0 ticks; stamina 8; meter 0.
Effects: []

## Cyclops Smash
Slow overhead double fist. Causes wall bounce.
Type: heavy; cooldown 0 ticks; stamina 24; meter 0.
Effects: []

## Gorgon Backfist
Spinning counter punch that causes a short Stone Stiff slowdown.
Type: heavy; cooldown 0 ticks; stamina 24; meter 0.
Effects: [{"kind": "stone_stiff", "timing": "hit", "duration": 120, "speed_percent": 65}]

## Hammer Of Hephaestus
Downward slam with ground bounce. Large limb damage.
Type: heavy; cooldown 0 ticks; stamina 24; meter 0.
Effects: [{"kind": "ground_bounce", "timing": "hit", "amount": 250}]

## Hephaestus Forge Shield
Bronze shield absorbs 40 damage, then bursts into shrapnel.
Type: superpower; cooldown 960 ticks; stamina 20; meter 0.
Effects: [{"kind": "shield", "timing": "begin", "absorb": 40, "burst_damage": 12}]

## Hermes Dash
Short invulnerable dash through attacks.
Type: superpower; cooldown 480 ticks; stamina 20; meter 0.
Effects: [{"kind": "dash", "timing": "begin", "distance": 900, "invulnerable_ticks": 18}]

## Iron Skin
Reduces all incoming limb damage by 15%.
Type: passive; cooldown 0 ticks; stamina 0; meter 0.
Effects: [{"kind": "passive", "limb_percent": 85}]

## Jab Of Hermes
Fastest jab. Low damage. Best combo starter.
Type: light; cooldown 0 ticks; stamina 8; meter 0.
Effects: []

## Minotaur Haymaker
Charged punch with armour while charging. Big knockback.
Type: heavy; cooldown 0 ticks; stamina 24; meter 0.
Effects: []

## Olympian Barrage
A sequence of fast strikes ending in a heavy slam.
Type: ultimate; cooldown 0 ticks; stamina 0; meter 100.
Effects: [{"kind": "ground_bounce", "timing": "last_hit", "amount": 300}]

## Pegasus Kick
Fast mid kick with forward hop. Starter kick.
Type: kick; cooldown 0 ticks; stamina 14; meter 0.
Effects: []

## Quick Fury
Three fast hits. Each hit chips the same limb.
Type: light; cooldown 0 ticks; stamina 18; meter 0.
Effects: []

## Satyr Dropkick
Leaping kick with strong knockback.
Type: kick; cooldown 0 ticks; stamina 14; meter 0.
Effects: []

## Spartan Cross
Straight punch with pushback. Safe on block.
Type: light; cooldown 0 ticks; stamina 8; meter 0.
Effects: []

## Stoneheart
Limbs need 20% more damage to sever, but you move slightly slower.
Type: passive; cooldown 0 ticks; stamina 0; meter 0.
Effects: [{"kind": "passive", "integrity_percent": 120, "speed_percent": 90}]

## Sweeping Hydra
Triple low sweep. Each hit has a small limb chip.
Type: kick; cooldown 0 ticks; stamina 22; meter 0.
Effects: []

## Zeus Bolt
Fast lightning line. Chars limbs, raising limb damage taken for 5 s.
Type: superpower; cooldown 840 ticks; stamina 20; meter 0.
Effects: [{"kind": "status_limb_vulnerability", "timing": "hit", "duration": 300, "limb_percent": 125}]

## Zeus’s Wrath
Summons a huge lightning strike. High damage and a guaranteed Cracked limb.
Type: ultimate; cooldown 0 ticks; stamina 0; meter 100.
Effects: [{"kind": "force_limb_state", "timing": "hit", "state": "cracked"}]
