# Missing items and review notes

The provided Python files (`build.py`, `stages_a.py`, `stages_b.py`, `stages_c.py`) described a generator but did not include `common.py`, which the generator imports. Therefore the original generator could not run as supplied. This prompt pack was assembled using the stage definitions and a reconstructed common renderer; the generated files passed the included structural validation, but this is not proof that the original missing `common.py` would have produced byte-for-byte identical output.

## Before you begin

1. **Confirm the 2.5D decision.** `DECISIONS.md` locks lane-based 2.5D combat, integer millimetres, and no sidestep/depth movement. This materially changes the feel versus a full 3D arena fighter. It is flagged for owner approval in the manual pre-flight; resolve it before stage 05.
2. **Install and verify tools.** Godot 4, Blender, Python 3, and Git must be installed and their versions verified. The pack intentionally does not install software automatically.
3. **Review stage 05/06 architecture before deep implementation.** A fully deterministic integer combat simulation is stricter than a typical Godot game. Cursor must prove the simulation can be tested independently of rendering and must not use Godot physics inside combat rules.
4. **Art quality is not guaranteed.** Blender-generated low-poly models are a repeatable baseline, not equivalent to handcrafted production art. Use the visual checkpoints to request focused generator improvements.
5. **Audio licensing statement needs care.** Do not assume procedural/self-generated audio is automatically “CC0” or public domain. Record the actual generation method and applicable terms; avoid asserting a legal status without a basis.
6. **Generated asset ownership/licensing needs review.** Do not claim that every generated asset automatically belongs to the project or is copyright-protected. Keep provenance records and verify relevant tool, font, sound, and store policies at release time.
7. **Storefront scope is not publishing automation.** Cursor can prepare release notes and checklist documents; you must approve disclosures, accept platform terms, and perform account-owner actions.
8. **Windows/Linux export still needs real validation.** The prompt pack asks for both targets, but the non-native operating system export may remain UNVERIFIED unless you can test it on that OS or CI runner.
9. **The pack is not an implemented game.** It contains sequential implementation prompts, control documents, and source-specification extracts. The actual game, assets, tests, and exports must be created by Cursor and verified.

## Scope summary
The pack's locked target is 4 fighters, 3 arenas, 21 abilities, 5 regrown limbs, and local play. Online rollback, matchmaking, ranked, four-player, co-op, spectator, and several original GDD systems remain deferred. Do not treat the optional stage 25 as an implementation stage.
