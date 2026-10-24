# Four-fighter roster

The four original shared-skeleton models use cosmetic armour, silhouette and animation-style differences. They are stylized procedural assets under the 5,000-triangle budget, not realistic scanned or motion-captured models. Palettes do not change combat. Mirror matches resolve identical palettes to a distinct alternative.

Physical formulas apply once at MatchLauncher: weight delta = kg−80; muscle delta = muscle−60. Speed = speed curve × (100−trunc(weight delta/3))%, minimum 8 mm/tick. Power = power curve + trunc(muscle delta/10). Reach = reach curve × trunc(height×100/1800)%. Width = target-width curve + max(0,height−1800)/10 mm. Knockback = clamp(100−trunc(weight delta/2),65,120)%. Limb integrity adds trunc(muscle delta/5) after the toughness curve. Fx.percent rounds the integer products. Body-state and replacement modifiers then apply separately.

Derived base examples (before equipped passives/replacements):

- Theron: speed 18 mm/tick; power 133%; reach 120%; width 525 mm; knockback 75%; integrity bonus 7. AI style: defensive.
- Atalanta: speed 49 mm/tick; power 84%; reach 98%; width 360 mm; knockback 109%; integrity bonus -3. AI style: rushdown.
- Pyrrhus: speed 31 mm/tick; power 117%; reach 86%; width 360 mm; knockback 105%; integrity bonus 4. AI style: grappler.
- Sibyl: speed 31 mm/tick; power 99%; reach 97%; width 360 mm; knockback 106%; integrity bonus -2. AI style: zoner.

Theron emphasizes heavy armour/slow power; Atalanta is the quick hunter; Pyrrhus is the compact grappler; Sibyl has the hooded oracle silhouette and range. Style data changes idle sway, walk cycle, stride, recoil and spine twist while shared key poses preserve the modular rig. Combat AI uses the declared archetypes. The balance harness deliberately uses identical balanced controllers to compare physical stats without conflating archetype policy.

The six-trial local Career ladder reuses these bodies and three palettes as Initiate through Final Trial. It is an MVP stand-in for an undefined Pantheon list, not six new characters or bosses. Difficulty is monotonic easy/easy/normal/normal/hard/hard, with hazard-enabled later trials. Schema and semantic tests validate references and loadouts.

The full content matrix covers 4 fighters × 3 arenas × 16 body masks × 6 replacement choices (including none): 1,152 cases, 90 ticks each. The normal suite covers 144 representative cases; --suite slow expands it to the full matrix. Legacy ProtoFixture goldens intentionally retain the early reference-body setup; current MatchLauncher replays include body-derived stats, abilities and arena metadata.
