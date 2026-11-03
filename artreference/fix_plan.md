# Severed: Trials of Olympus - Comprehensive Fix Plan

## Issues Identified

### 1. 🔴 Johnny Cage "Missing model" Error (CRITICAL)
**Root Cause**: [`content_check.gd`](file:///e:/zeus%20balls/src/core/content_check.gd) checks for models at `res://assets/generated/models/fighter_johnny_cage.glb` but this file doesn't exist. The Johnny Cage model IS at `res://assets/fighters_mixamo/fighter_johnny_cage.glb`. The content check only looks in `generated/models/` and expects exactly 4 fighters, but there are 5 JSON configs (including `johnny_cage.json`).

**Fix**: 
- Update `content_check.gd` to also check `res://assets/fighters_mixamo/` path
- Update fighter count from 4 to 5
- Add Johnny Cage to `mixamo_pack_map.json` (currently missing entirely!)

### 2. 🔴 Johnny Cage Missing from Pack Map (NO ANIMATIONS)
**Root Cause**: The `mixamo_pack_map.json` has entries for theron, atalanta, pyrrhus, sibyl but NO `johnny_cage` entry at all. This means JC has zero clip-based animations.

**Fix**: Add complete `johnny_cage` fighter section to `mixamo_pack_map.json` with all MK moves mapped.

### 3. 🟡 Theron Janky Animations / Hands Locking
**Root Cause**: Multiple issues:
- The retarget system maps bones but hand/finger bones get excluded (ALLOWED_EXCLUDED_TRACKS) causing hands to lock at rest pose during attacks
- Theron's heavy build with wide shoulders causes hand interpenetration during close-range attacks
- IK guard arm solver in `_solve_guard_arm` pulls both arms to center creating overlap

**Fix**:
- Widen guard arm offset based on shoulder width
- Add hand separation constraint during active frames
- Improve transition blending between attack phases

### 4. 🟡 Throw Mechanic Not Working  
**Root Cause**: The throw (`is_grab: true`) in `sim_combat.gd::_throw()` does swap positions and set GRAB/GRABBED states, but the input check in `sim_move_availability.gd` requires both LIGHT + KICK simultaneously (`light and kick`). The issue is that the grab never triggers because `_chosen_move` in `sim_movement.gd` uses `_wants()` which requires edge detection. For Johnny Cage, `mk_jc_throw_forward` is mapped to `light and kick` at line 46-47.

**Fix**: 
- Ensure grab input is correctly buffered and detectable 
- Add grab hold animation and throw release visuals
- Fix the grab state machine to properly animate both fighters

### 5. 🟡 Combos Not Added / No Combo System
**Root Cause**: Johnny Cage has `cancel_into` arrays in move JSONs but JC's combo chains aren't connected in `sim_move_availability.gd`. The `_try_cancel` function works but JC's move flow needs proper EX cancel mapping. The `command_move()` function only handles Greek-themed moves, not MK moves.

**Fix**:
- Connect JC combo strings through `cancel_into` chains
- Add JC-specific command moves and EX cancels  
- Ensure frame data creates smooth combos

### 6. 🟡 Cloth Doesn't Feel Like Cloth
**Root Cause**: The cape/cloth simulation in `pose_driver.gd` is a simple sine-wave rotation (`_cape_angle`) - not a cloth simulation. The spring constant is a fixed global value.

**Fix**:
- Add multi-segment cloth chain simulation
- Add velocity-reactive cloth movement
- Improve spring/damper physics for cloth bones

### 7. 🟠 External Assets are .uasset (Unreal Format)
**Note**: The files in `D:\...\Exports\` are all `.uasset` Unreal Engine format. These CANNOT be directly imported into Godot. The Mixamo animations are already in GLB format in the project.

## Execution Plan

### Phase 1: Fix Johnny Cage (Critical Path)
1. Fix `content_check.gd` to recognize Mixamo models
2. Add full `johnny_cage` section to `mixamo_pack_map.json`
3. Add `johnny_cage` to `fighter_styles.json`

### Phase 2: Fix Animations & Rigging  
4. Fix hand locking by widening IK guard positions
5. Improve attack blend transitions
6. Add cloth chain simulation

### Phase 3: Fix Combat Mechanics
7. Fix throw mechanic detection and visuals
8. Connect combo chains with EX cancels
9. Add missing UI for new fighters

> [!IMPORTANT]  
> The `.uasset` files from the MK12 export folder are Unreal Engine format and cannot be directly used in Godot. The project already has Mixamo-retargeted GLB animations for all fighters. The fixes will use the existing animation infrastructure.
