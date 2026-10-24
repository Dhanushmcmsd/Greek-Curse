# Owner Playtest Guide: M0 Animation & Model Verification

## Launch Command
Run the interactive match prototype or animation test lab using the pinned Godot binary:

```powershell
# Real interactive 1v1 match scene:
& "D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --path . scenes/match/match_prototype.tscn

# Or launch the interactive Animation Lab:
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
