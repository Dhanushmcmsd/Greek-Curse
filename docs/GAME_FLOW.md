# Local game flow

The main scene is `scenes/menus/main.tscn`. Router owns a validated transition graph, the current MatchConfig and Career service. MenuHost destroys the previous page before displaying the next; scroll containers accommodate long pages. Match, results, setup, loadout and Obol are separate screens. Confirmation dialogs are limited to irreversible retirement/trades and leaving Career.

First launch shows an 18+ self-declaration and content warning. This is a courtesy gate, not age verification. Decline quits. The warning describes persistent Career limbs, nonpersistent Fresh Body limbs and gore controls. Both flags persist. Settings can show the warning again.

Fresh Body, Versus and Practice have fighter/model previews, palette selection, controller assignment, arena preview/hazards and per-player ability selection. A large mode banner precedes the fight. Career uses the living fighter's saved loadout and limbs and the six-opponent ladder. Results show rounds, damage, combo and amputation credits, then offers/hub or the originating setup. Rematch is available outside Career. Within non-Career fights, Replacement limbs opens the opaque Forge with images rendered from the actual limb models and their descriptions. Equipping starts a new match. Career replacements require an Obol trade.

Keyboard: Tab/Shift+Tab or directional menu navigation, Enter/Space select, Escape back/pause. Gamepad uses UI directions/accept/cancel and Start to pause. Assign separate keyboard sets or pad devices in setup. Physical-key and gamepad sources are isolated so keyboard P1 does not also drive a pad-assigned P2. Hardware gamepad comfort/focus traversal remains a Checkpoint C test.

Settings persist locally and include volumes, gore, blood colour, shake, hit-stop, flash reduction, captions, text scale, contrast, toggle block, bindings, window/fullscreen, VSync and resolution. Display changes require Keep within ten seconds or revert, including on leaving the page. Saved display options apply on next launch. A sample sound button supports volume checks. Bindings reject conflicts and can be reset.

Missing core content routes to a copyable error page. Invalid graph transitions are rejected. Save corruption produces a visible recovery message. Content checks do not cover maliciously edited files: this is an offline local prototype, not a hardened content sandbox.

## Automated checks

`tools/validate/check_ui_graph.py` checks all 21 graph states. Scene-load tests instantiate every scene. `tools/ui/menu_previews.gd` renders 19 menu pages to build/menu_*.png. Screenshots were inspected in a real Compatibility-renderer window. `--autoplay-smoke --user-profile build/final_smoke` completes an AI match through the router. `--autoplay-career --user-profile build/final_career` plays an AI match, explicitly substitutes a fixture win/sever to exercise unlock/trade, saves and reloads. `tools/sim/continue_smoke.gd` runs in a separate Godot process against that same profile and checks Continue, win and attached limb persistence. The fixture substitution never runs during normal play.

Both autoplay flags require an isolated profile. Their JSON summary is written inside that profile. Headless audio checks dispatch/data only; actual WAV playback is skipped because the Dummy audio backend leaks imported WAV resources on exit. Windowed runs exercise playback. Subjective volume/music quality is unverified until owner listening.

## Human handoff

Run `tools/playtest_checkpoint_c.ps1`. Use `docs/playtest/CHECKPOINT_C.md`. Stage 21 follows Checkpoint C feedback; this is not a packaged release or final visual-quality approval.
