# Mixamo Rig Specification & Roster Analysis

This document details the inspection of the 10 Mixamo characters in `D:\Charecter model` and the 46 animations in `D:\charecter animation`, mapping out structural differences against the 15-bone game contract.

---

## 1. Character Asset Inventory & Metrics

| Character FBX | Skeleton Bones | Mesh Count | Vertices | Polygons | Raw Height ($Z$) | Materials |
|---|---|---|---|---|---|---|
| `Arissa.fbx` | 73 | 4 | 4,887 | 4,793 | 1.80m ($46.33$ bbox w/ rig) | `Arissa_MAT` |
| `Ch34_nonPBR.fbx` | 65 | 1 | 25,340 | 25,984 | 1.75m | `phong1` |
| `Ch39_nonPBR.fbx` | 65 | 1 | 16,211 | 16,739 | 1.82m | `Ch39_Body` |
| `Ch40_nonPBR.fbx` | 65 | 3 | 32,697 | 30,449 | 1.72m | `Ch40_body`, `Ch40_hair`, etc. |
| `Demon T Wiezzorek.fbx` | 79 | 8 | 8,574 | 12,900 | 2.10m | `Demon_MAT` |
| `Kachujin G Rosales.fbx` | 75 | 1 | 6,675 | 6,619 | 1.85m | `kachujin_MAT` |
| `Maria J J Ong.fbx` | 65 | 1 | 8,094 | 14,566 | 1.70m | `maria_M1` |
| `Nightshade J Friedrich.fbx`| 68 | 1 | 6,691 | 8,191 | 1.88m | `Nightshade_MAT` |
| `Paladin J Nordstrom.fbx` | 67 | 2 | 7,825 | 7,368 | 1.95m | `Paladin_MAT` |
| `Vampire A Lusth.fbx` | 99 | 1 | 7,870 | 15,021 | 2.05m | `Vampire_MAT1`, `Vampire_MAT_Transparent` |

---

## 2. Rig Structure & Bone Hierarchy

### Mixamo Conventions:
- **Root Node**: `Armature`
- **Prefix**: `mixamorig:`
- **Rest Pose**: Standard T-pose with arms extended along X axis, facing `-Y` or `+Y` depending on import settings.
- **Bone Count Range**: 65 standard bones up to 99 bones (with extra cape/accessory bones on Vampire, horns/wings on Demon, facial joints on Kachujin).

### Mixamo to Shared 15-Bone Mapping:

```
Mixamo Bone Name                           -> Game Shared Bone Name
-------------------------------------------------------------------
mixamorig:Hips                             -> root
mixamorig:Spine, mixamorig:Spine1, Spine2  -> spine
mixamorig:Neck, Neck1, Head, HeadTop_End   -> head
mixamorig:LeftShoulder, LeftArm            -> upper_arm.l
mixamorig:LeftForeArm                      -> forearm.l
mixamorig:LeftHand, Thumb/Index/Pinky/etc. -> hand.l
mixamorig:RightShoulder, RightArm          -> upper_arm.r
mixamorig:RightForeArm                     -> forearm.r
mixamorig:RightHand, Thumb/Index/Pinky/etc.-> hand.r
mixamorig:LeftUpLeg                        -> thigh.l
mixamorig:LeftLeg                          -> shin.l
mixamorig:LeftFoot, LeftToeBase, End       -> foot.l
mixamorig:RightUpLeg                       -> thigh.r
mixamorig:RightLeg                         -> shin.r
mixamorig:RightFoot, RightToeBase, End     -> foot.r
```

---

## 3. Gap Analysis & Pipeline Requirements

1. **Prefix & Scale**:
   - Mixamo FBX uses `mixamorig:` prefix and centimeters scale ($0.01$).
   - *Converter Action*: Strip prefix, normalize scale to meters, freeze scale/rotation transforms, snap origin to floor center between soles.
2. **Bone Weight Reduction**:
   - Mixamo models contain detailed finger, toe, clavicle, and neck bones that the game's 15-bone PoseDriver and validators do not possess.
   - *Converter Action*: Transfer all finger vertex weights to `hand`, toe weights to `foot`, clavicle weights to `spine` or `upper_arm`, neck weights to `head`.
3. **Mesh Partitioning for Amputation**:
   - Unlike the early faceted prototype (which authored separate upper/lower/end mesh objects), Mixamo meshes are single skinned meshes or layered costume pieces.
   - *Converter Action*: Split skinned meshes into discrete sub-meshes based on dominant bone assignment:
     - `ARM_UPPER_L`, `ARM_LOWER_L`, `ARM_END_L`
     - `ARM_UPPER_R`, `ARM_LOWER_R`, `ARM_END_R`
     - `LEG_UPPER_L`, `LEG_LOWER_L`, `LEG_END_L`
     - `LEG_UPPER_R`, `LEG_LOWER_R`, `LEG_END_R`
     - `TORSO`, `PELVIS`, `HEAD`
4. **Stump Caps**:
   - Mixamo meshes have no cross-section stump caps at joint boundaries.
   - *Converter Action*: Programmatically generate `CUT_<SLOT>` and `BONE_<SLOT>` geometry at joint thresholds.
5. **Sockets Creation**:
   - Sockets must be positioned at joint coordinates so regrown limbs (`rubber_chicken_arm`, `cyclops_giant_hand`, `marble_statue_leg`, etc.) attach seamlessly.
6. **Polygon Budget & Performance**:
   - Models like `Ch40` ($30\text{k}$ polys) and `Ch34` ($26\text{k}$ polys) are heavier than the prototype ($<5\text{k}$).
   - The contract and manifest budget will accommodate high-fidelity Mixamo character models while maintaining 60 FPS in Godot.
