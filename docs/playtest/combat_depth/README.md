# Combat depth and leg-support fixes

## Gameplay

The default loss cap is four limbs. Losing two arms no longer prevents later leg severing. Attached fractured legs also cease bearing weight: one usable leg gives a hop; no usable legs gives a crawl, or torso movement when arms cannot support crawling. Healthy replacement limbs restore support.

Minimum knockback is now 240 mm for light attacks, 430 mm for heavy attacks and 340 mm for kicks, before defender resistance. Existing larger values remain. Blocks have at least 90 mm of pushback. Multi-hit attacks retain small intermediate pushes and deliver their main displacement on the final hit. At arena edges, unspent displacement moves the attacker back, creating room without moving either fighter outside the arena. A landed attack stops its forward lunge during recovery. Authored launch height now works away from walls too. Rendering interpolates the impact displacement over a short interval after hitstop.

These are intentional balance changes. Stationary held attacks no longer maintain pressure indefinitely: close distance again, vary moves, or let the opponent recover. A new test verifies the defender can regain guard after an initial hit.

## Animation

Ten equippable punches and kicks have individual source motions, rather than sharing broad category bindings. Contact windows are measured from the striking hand or foot and aligned to the active hit window. Crosses use the cross portion of their source sequence. Right/left strikes mirror motion around each model's rest frame, including during hitstop.

The existing full-hierarchy crawl clip is enabled. The torso aligns horizontally and fractured knees fold under the body. Grounding excludes wound surfaces, which previously acted as false floor contacts. Missing-leg and fractured-leg captures are included, along with contact frames for Theron and Atalanta's ten attacks.

## Verification and replay compatibility

Five focused tests cover four-limb severing, fracture support, wall spacing, stopping a landed lunge, distinct moves, mirrored hitstop, crawl playback and defensive recovery. Existing animation, geometry and deterministic checks remain enabled.

All 44 replay baselines were regenerated and independently replayed for the new balance. Existing input logs were retained except the prototype and severance demonstrations, whose attackers now pursue between strikes. The prototype finishes in 1,230 ticks. Old replay hashes from the previous balance are not compatible with this revision.

`tools/anim/calibrate_move_contacts.gd` regenerates contact windows. `tools/capture_combat_depth.gd` captures crawl poses, strike poses, and a real heavy-hit sequence. In that sequence, fighter center separation increases from 520 mm to 989 mm. Strike-pose shots use explicitly selected presentation frames; the spacing sequence steps the actual simulation.

The compatibility scene `scenes/gate_a_pilot.tscn` also accepts the pilot command from the reported log. The canonical scene remains `scenes/debug/pilot_gate_a_preview.tscn`.

Final validation: 158 Godot tests passed, 15 Python validation tests passed, and all 44 replay baselines verified.
