# Architecture

Stage 03 foundation. Combat rules are not in this stage. The locked MVP stays local 1v1, 2.5D, with the five approved regrown limbs.

## Layers

Dependencies point left. A file may use the layer to its left and must not import the layer to its right.

`core` ← `sim` ← `presentation` / `ui` / `ai` / `input`

`persistence` and `progression` read core types and sim results. They do not import scenes or the renderer, and they do not change a running tick.

| Layer | May use | Must not use |
|---|---|---|
| core | Integer helpers, `Result`, `Log`, JSON files | Combat outcomes, nodes inside `src/sim` |
| sim | `core` | `Node`, physics, wall clock, floats, `rand*`, the scene tree |
| input / ai | `core`, a read-only sim snapshot | Writing health, limbs, or positions |
| presentation / ui | snapshots and events | Deciding damage or severing |
| persistence / progression | `Result`, saved data, match summaries | The live `SimWorld` internals |

`src/core/data_loader.gd` is the JSON boundary. Godot's parser returns numbers as floats. The loader converts schema integer fields to `int` before anything in `src/sim` sees them.

## Tick loop

Later stages add `SimWorld.step(inputs)`. That function is the only way sim state changes.

1. Input and AI build one `SimInput` per fighter for this tick. AI does not touch state. It only returns `SimInput`.
2. `step` copies the previous state, advances one 60 Hz tick, and appends events.
3. Presentation, UI, and audio read the new state and the event list. They do not write back.
4. Persistence stores match results and career data after the match. It does not store a raw mid-tick object graph.

There is no `SimWorld` yet. `SimConstants` only names the tick rate and the millimetre scale.

## Where later systems plug in

| System | Stage | Plug-in point |
|---|---|---|
| Integer combat | 05–06 | `SimWorld.step` |
| Limbs and severing | 07 | sim state inside `step` |
| Body state and input | 08 | `SimInput` and movement inside `step` |
| AI | 09 | produces `SimInput` from a snapshot |
| HUD | 10 | reads state and events |
| Saves and Obol | 19 | persistence after the match |
| Menus | 20 | UI, never the tick |

## Forbidden in `src/sim/`

`tools/validate/check_sim_purity.py` rejects these on any line that does not contain `# sim-purity-ok: <reason>`:

- `randf`, `randi`, `randomize`
- `Time.`, `OS.`, `Engine.`
- `get_node`, `get_tree`
- inheritance from `Node`, `Node2D`, `Node3D`, `Control`, physics bodies, or `Area3D`
- `PhysicsServer`, `RigidBody`, `CharacterBody`, `Area3D`, `HTTPRequest`, `ENet`, `WebSocket`
- float literals, the `float` type, and `Vector2(` / `Vector3(`

`Vector2i` is allowed. Allowed bases are `RefCounted` and `Resource`. A sim-purity comment is reviewed in the handoff for the stage that adds it. None are used in `src/sim` today.
