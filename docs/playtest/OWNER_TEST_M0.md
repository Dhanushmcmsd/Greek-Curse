# Owner Playtest Guide: M0 Animation & Model Verification (Checkpoint 1)

## Supported Models for `--model`
The following 10 visual model IDs are verified and supported with shared 15-bone animation retargeting:
- `theron` (Theron standard)
- `atalanta` (Atalanta standard)
- `pyrrhus` (Pyrrhus standard)
- `sibyl` (Sibyl standard)
- `skin_ch39` (Ch39 model)
- `skin_ch40` (Ch40 model)
- `skin_demon` (Demon model)
- `skin_kachujin` (Kachujin model)
- `skin_nightshade` (Nightshade model)
- `vampire_stress` (Vampire model)

## Launch Commands

```powershell
# 1. Real interactive 1v1 match scene (default models):
& "D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . scenes/match/match_prototype.tscn

# 2. Interactive match with visual model override:
& "D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . scenes/match/match_prototype.tscn -- --model=skin_demon
& "D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . scenes/match/match_prototype.tscn -- --model=skin_kachujin
& "D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . scenes/match/match_prototype.tscn -- --model=vampire_stress

# 3. Interactive Animation Lab (scrub animations, test reach, inspect clips):
& "D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . scenes/debug/animation_lab.tscn
```

## Interactive Playtest Checklist

### 1. Motion & Locomotion
- [ ] Move left/right (`A` / `D`): Legs perform fluid walking cycle; feet remain grounded to floor without floating or clipping through ground.
- [ ] Idle: Normal breathing motion without jerky torso popping.

### 2. Combat Attacks & Blocking
- [ ] Light attack (`J`): Fast jab animation plays; limb retracts cleanly.
- [ ] Heavy attack (`K`): Full body windup and strike.
- [ ] Kick (`L`): Pegasus kick executes with leg extension.
- [ ] Block (`Shift`): Guard pose raises arms into center block; blocking impact shows block reaction.

### 3. Amputation & Stumps
- [ ] In Animation Lab or Match Tools: Select a limb slot (e.g. `arm_l` or `leg_l`) and trigger severance.
- [ ] Missing limb is hidden immediately without dangling mesh artifacts.
- [ ] Bone stump cap appears at socket joint.
- [ ] When both legs are severed, fighter drops to ground and uses crawl/torso locomotion.

### 4. Regrown Replacements
- [ ] In Match Tools: Grant a replacement limb (e.g. `cyclops_giant_hand` or `marble_statue_leg`).
- [ ] Regrown attachment anchors cleanly to socket and animates with procedural quirks.
