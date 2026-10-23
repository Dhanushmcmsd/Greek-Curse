# Local AI and match setup

MatchLauncher constructs validated two-fighter MatchConfig. Controllers: human_kb1/kb2, human_pad0/pad1, ai_easy/normal/hard, dummy_idle/block_always/walk_back_forth/attack_on_interval/regen_reset. Keys 1/2/3 select human-human, human-normal, normal-hard. Default is human-normal.

AI consumes detached visible observations delayed by 28/12/6 ticks (Easy/Normal/Hard). It has a separate seeded RNG and weighted move scoring by damage, startup, range, limb damage, grab versus block and visible recovery. Legal options are resolved through the same body-state move selector. No fighter-specific code or hidden future inputs. Data controls aggression, spacing and block responses. Dummies can reset through DummyController.reset.

400-match soak (2026-10-24): all roster pairings across run, sides alternate, 200 comparisons for each difficulty step. 0 failures, 1398548 ticks, 103 severances; Hard won 200/200 versus Normal, Normal won 200/200 versus Easy. Observed natural masks 0/1/3; all other masks covered by explicit matrix and AI legality tests. This large difficulty gap is provisional and should receive manual balance feedback; the soak proves ordering, not fun. Failure replays include seed, fighter ids and initial body state.
