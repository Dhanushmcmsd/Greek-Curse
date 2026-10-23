# Checkpoint A — first playable prototype

Play this before any later stage. The automated tests do not judge whether the fight feels responsive or readable.

## Launch (Windows)

The main scene is `scenes/match/match_prototype.tscn`.

From `E:\zeus balls`:

```
& "D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "E:\zeus balls"
```

The console binary is the same build and also opens a window when `--headless` is omitted:

```
& "D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path "E:\zeus balls"
```

In the Godot editor, open this folder as the project and press F5. Use Godot 4.7.2. Do not use the Godot 4.0 install.

Close the window when you are done. It stays open until you close it.

## Controls

Keyboard and two gamepads. Gamepad 0 is player 1. Gamepad 1 is player 2.

| Action | Player 1 | Player 2 | Gamepad |
|---|---|---|---|
| Move left / right | A / D | Left / Right | Left stick |
| Up (unused) | W | Up | — |
| Down (unused) | S | Down | — |
| Light | J | Numpad 1 | X |
| Heavy | K | Numpad 2 | Y |
| Kick | L | Numpad 3 | A |
| Block | Shift | Gamepad only | RB |
| Dodge | Space | Gamepad only | B |
| Restart | R | R | — |
| Hitbox debug | F1 | F1 | — |

Player 2 has no keyboard key for block or dodge in this prototype. Block and dodge do not change damage yet. Block only sets a flag. Up, down, and dodge do nothing to the fight.

## What you should see

- Two capsule fighters, Theron (orange) and Atalanta (green), on a flat lane between two walls.
- They start apart. They can only move left and right. They turn to face each other.
- Health bars, a round timer that starts at 1:30, round wins, and "Round 1".
- Light, heavy, and kick each reduce the other fighter's health when they connect. A hit flashes the body.
- F1 draws hurtboxes and the active hitbox, and shows the tick, state names, and state hash.
- A round ends on a knockout or when the timer reaches 0. First fighter to win two rounds wins the match. The banner names the winner.
- R throws the match away and starts a new one.

A scripted run of the same fight ends at tick 2040 with wins 2–0 and state hash `2183744980119554273`.

## Still frame already captured

`docs/playtest/screenshots/a_prototype.png` is one windowed frame after 90 scripted ticks, not a recording of play. The windowed Godot 4.7.2 process exited 0 and printed no `ERROR` line. The still shows the floor, both walls, both capsules close together, both health bars, `1:28`, `Round 1`, the names, and "Press R to restart". That frame is during a hit flash, so the right capsule is the cream flash color and the right bar is a little shorter. It does not prove the controls, the facing, or a finished match.

## What to return

Reply **PASS**, or paste this template:

```
Checkpoint: A   Item #:
What I did (steps):
What I expected:
What happened instead:
How often (always / sometimes / once):
Fighter(s) / arena / mode / difficulty:
Limb state or regrown limb involved (if any):
Screenshot or short clip: (attach) / Log file: (path shown in Credits or `user://logs`)
My computer: OS, CPU, GPU, RAM:
```

Stage 06 does not start until you approve this checkpoint.
