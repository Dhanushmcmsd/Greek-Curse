# Progression and local saves

One living Career fighter is allowed. Creation chooses one of four roster bodies, a name and palette, and grants Jab of Hermes, Cyclops Smash and Pegasus Kick. Career limbs, record, ladder position, unlocked/equipped/traded abilities and pending offers persist. Completed matches alone commit results. Leaving an unfinished Career fight discards that fight's damage/result, with a confirmation. Fresh Body wins can earn progression on the configured three-win cadence but never change Career limbs; Versus/Practice never change Career progress.

Wins generate seeded offers from the remaining pool. The first, third and fifth Career wins guarantee a superpower, passive and ultimate respectively if available. Pending offers are stored so restarting cannot reroll them. A traded ability may re-enter the offer pool. Equip limits are 2 light, 2 heavy, 2 kick, 1 superpower, 1 passive and 1 ultimate. The match receives a deep-copied resolved loadout.

Obol requires a severed slot and an earned non-starter ability. Pick the slot and ability, view up to three compatible limb cards, then confirm or decline. Three arms and two legs exist; a leg trade therefore has two choices. Accept removes the ability from pool/loadout and restores the chosen replacement at 80% of its maximum integrity, rounded by the integer sim. Marble's 150% maximum applies. Losing Stoneheart through a trade also updates the normal maximum. Starting a later match normalizes saved integrity to changed passive maxima while preserving its percentage. Declining does not mutate progress. The tooltip text is read from each limb's data. There is no currency.

Chronicle stores dated match results, round scores, longest combo and amputation credits. Retirement requires confirmation, archives the fighter/Chronicle and allows a new living fighter. A body missing all limbs may continue fighting; retirement is never forced.

## Persistence

`CareerSave` is the only Career file writer. Schema version 2 has fighter, chronicle, fallen, rng_seed_counter and fresh_body_wins fields. The fighter includes id/name/palette/created, ability pools/loadout, counters, limbs and offers. Version 1 migrates the Fresh Body counter. JSON numbers are restored to integers before comparison/simulation.

Writes validate, write/flush/close a sibling .tmp, preserve the previous valid file as .bak, then rename the temp over the destination. Tests simulate interruption before rename; the old save remains valid. On invalid JSON or invalid supported structure, the original is renamed .corrupt-<timestamp>, then a valid backup is loaded or a new-Career message is shown. Unknown versions are rejected, not overwritten silently. Identity, counters, history structure, ability/loadout references and replacement-slot compatibility are checked before UI use. This is local persistence only: no cloud, network, encryption, anti-tamper or server checks.

Default location is Godot user://; --user-profile overrides it for isolated tests. The playtest launcher uses build/playtest_profile, separate from automation profiles. Keep this folder to Continue.

Tests cover lossless round trip, backup recovery, interrupted commit, migration, deterministic guaranteed offers, protected starter kit, compatible trades, retirement and 10,000 seeded progression events (seed 901). Router autoplay plus a second process verifies Continue after trade. Name filtering is intentionally basic: 2–24 Latin/Greek letters, numbers, spaces, apostrophes/hyphens, trimming and a small replaceable blocked list; only selected combining sequences normalize, not complete Unicode NFC.
