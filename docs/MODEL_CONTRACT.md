# Fighter Model Contract

This document defines the strict specification that any fighter 3D asset (`.glb`) must satisfy to integrate seamlessly with the deterministic combat engine, FighterRig, PoseDriver, amputation/stump mechanics, socketed regrown limbs, and visual rendering pipeline.

---

## 1. Coordinate Space, Orientation, Scale & Floor

- **Blender Export Convention**:
  - Up: `+Z`
  - Forward: `-Y`
  - Right: `+X`
- **Godot Import Result**:
  - Up: `+Y`
  - Forward: `+Z`
  - Right: `+X`
  - Model rendering rotation: Facing `+1` rotates `+90°` toward `+X` (`-facing * 0.95` radians for 3/4 combat camera readability).
- **Origin**: Center of the floor footprint (`(0, 0, 0)`).
- **Height**: Matches `height_mm` / `body.height_m` in `data/fighters/<id>.json` within `1%`.
- **Floor Contact**:
  - Model bounding box lowest point `>= -0.015m` and `<= 0.02m`.
  - Sole vertices touch floor `Y = 0` at idle/rest.

---

## 2. Skeleton Hierarchy & Rig Contracts

The engine supports two distinct rig contracts:

### A. Rich Deform Rig Contract (`contract: "mixamo_deform"`)
For imported high-fidelity characters (Mixamo FBX source):
- **Full Anatomical Armature Retained**: Keeps all original deform bones, intermediate twist/spine bones (`Spine1`, `Spine2`, `Neck`), and facial/accessory joints (65–99 bones).
- **Soft Skinning Preserved**: Continuous skin weights are maintained across joints. Head, neck, and torso form a single unbroken mesh segment (`TORSO_HEAD`), ensuring head and neck never detach or shear under animation.
- **Canonical 15-Bone Mapping**: The 15 primary anatomical deform bones are renamed or mapped to the canonical joint identifiers (`root`, `spine`, `head`, `upper_arm.l`, `forearm.l`, `hand.l`, `upper_arm.r`, `forearm.r`, `hand.r`, `thigh.l`, `shin.l`, `foot.l`, `thigh.r`, `shin.r`, `foot.r`).
- **Modular Limb Partitioning**: The four amputatable limb branches (`arm_l`, `arm_r`, `leg_l`, `leg_r`) are cleanly partitioned into continuous skinned modular meshes tagged with `limb_group` meta (`LIMB_ARM_L`, `LIMB_ARM_R`, `LIMB_LEG_L`, `LIMB_LEG_R`), preserving intact boundary positions and skinning weights.

### B. Legacy 15-Bone Rigid Rig Contract (Fallback / Procedural Fighters)
For low-poly procedural prototype fighters:
- Exactly 15 bones sharing the standard hierarchy:

```
root (Pelvis / Floor anchor)
 ├── spine (Torso)
 │    ├── head (Neck / Head)
 │    ├── upper_arm.l
 │    │    └── forearm.l
 │    │         └── hand.l
 │    └── upper_arm.r
 │         └── forearm.r
 │              └── hand.r
 ├── thigh.l
 │    └── shin.l
 │         └── foot.l
 └── thigh.r
      └── shin.r
           └── foot.r
```

- **Rest Rotations**: Preserved on import. PoseDriver applies quaternion deltas on top of imported rest rotations.
- **Joint Limits**: Validated by `pose_validate.py` (e.g. spine `[-45, 45]`, knee `[-5, 130]`).

---

## 3. Sockets & Regrown Limb Attachments

Sockets are Empty / Node3D attachment points parented to the model root or tracking bone deformation:

- `SOCKET_ARM_L`: Left shoulder joint `(X = -width * 0.53, Z = height * 0.79)`
- `SOCKET_ARM_R`: Right shoulder joint `(X = +width * 0.53, Z = height * 0.79)`
- `SOCKET_LEG_L`: Left hip joint `(X = -width * 0.23, Z = height * 0.45)`
- `SOCKET_LEG_R`: Right hip joint `(X = +width * 0.23, Z = height * 0.45)`
- `SOCKET_NECK`: Base of head / neck `(X = 0, Z = height * 0.85)`

### Attachment Rules:
1. When a regrown limb is attached (`attach_regrown(slot, id)`):
   - Natural limb meshes for that slot are hidden (`mesh.visible = false`).
   - Stump meshes for that slot are hidden.
   - The regrown replacement GLB scene is instantiated and scaled proportionally:
     $$\text{scale} = \left(\frac{\text{width}}{0.45}, \frac{\text{height}}{1.80}, \frac{\text{width}}{0.45}\right)$$
   - Attached as a child under `SOCKET_<SLOT>`.
   - Sockets follow armature bone transforms via `_attachments()` without double transformation.
2. Attachment matrix tolerance (`validate_attachments.py`):
   - Socket error $\le 1\text{mm}$.
   - Lowest point $\ge -15\text{mm}$.
   - No head bounding box overlap.
   - Torso horizontal intrusion $\le 180\text{mm}$.
   - Scale factor between $0.7$ and $1.5$.

---

## 4. Logical Limb Groups & Mesh Naming Convention

`FighterRig` maps nodes and toggles mesh visibility per slot:

| Slot ID | Logical Group Node | Rendered Mesh Names | Rigid Bone Weight |
|---|---|---|---|
| `arm_l` | `LIMB_ARM_L` | `ARM_UPPER_L`, `ARM_LOWER_L`, `ARM_END_L` | `upper_arm.l`, `forearm.l`, `hand.l` |
| `arm_r` | `LIMB_ARM_R` | `ARM_UPPER_R`, `ARM_LOWER_R`, `ARM_END_R` | `upper_arm.r`, `forearm.r`, `hand.r` |
| `leg_l` | `LIMB_LEG_L` | `LEG_UPPER_L`, `LEG_LOWER_L`, `LEG_END_L` | `thigh.l`, `shin.l`, `foot.l` |
| `leg_r` | `LIMB_LEG_R` | `LEG_UPPER_R`, `LEG_LOWER_R`, `LEG_END_R` | `thigh.r`, `shin.r`, `foot.r` |
| Core / Head | - | `TORSO`, `PELVIS`, `BELT`, `HEAD`, etc. | `spine`, `root`, `head` |

- **Flattened Armature Hierarchy**: Under glTF / Godot `Skeleton3D`, meshes are flattened so nested node transforms are not applied twice.
- **Rigid Skinning**: Each vertex is assigned to its dominant bone (weight = 1.0) or minimal soft-weight scheme that preserves exact per-mesh severing.

---

## 5. Stump Cap Meshes & Amputation Mechanics

Under each `SOCKET_<SLOT>`, a child empty `STUMP_<SLOT>` contains:
- `CUT_<LIMB><SIDE>`: Circular/elliptical cross-section cap closing the flesh wound (material tinted dynamically by blood color setting).
- `BONE_<LIMB><SIDE>`: Exposed bone stump fragment (hidden when gore is disabled in accessibility settings).

### Amputation Behavior:
- When limb integrity reaches 0 and sever conditions are met:
  1. `LIMB_<SLOT>` and its constituent meshes are hidden (`visible = false`).
  2. `STUMP_<SLOT>` meshes become visible.
  3. `PoseDriver` activates stump twitching (`stump_twitch_ticks` and `stump_twitch_degrees`).
  4. Detached limb debris meshes are spawned in world space with directional physics impulse.
  5. Missing limb vertices are excluded from ground height calculation (`_ground()`).

---

## 6. Materials, Shading & Vertex Colors

- **Godot Renderer Target**: Compatibility renderer (OpenGL 3.3 / WebGL 2).
- **Shading**: Principled BSDF / StandardMaterial3D with vertex colors enabled as albedo where applicable.
- **Palettes**: `apply_palette(id)` modulates albedo color tint (e.g. `default`, `ivory`, `night`).
- **Damage Bruising**: `_tint()` applies translucent dark-red overlay (`Color(0.45, 0.2, 0.35, 0.45)`) when limb state is `bruised`.

---

## 7. Triangle & Memory Budget

- **Target per Fighter Model**: $\le 10,000$ triangles (prototyped models were $\le 5,000$; Mixamo characters with clothing and accessories range 5,000–35,000, optimized to fit performance targets).
- **Orphan Files**: Strict zero-tolerance in validator (`validate_assets.py`). Every GLB must have a manifest record with valid SHA-256 hash.
