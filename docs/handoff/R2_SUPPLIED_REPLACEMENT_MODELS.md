# R2 — Supplied Replacement Models Integration

## Overview
Successfully imported, fitted, and articulated the 20 supplied stylized elemental arm and leg models from `d:\Elemental_Limbs_10_Characters\Elemental_Limbs` across the 10 Mixamo characters. The replacement models are integrated via non-destructive shared-skeleton skinning, preserving intact Mixamo character skeletons, soft skin deformation, continuous locomotion and combat animation playback, amputation mechanics, and 100% deterministic simulation replay hashes.

---

## 1. Asset Inventory & Provenance
- Cataloged in `docs/art/SUPPLIED_REPLACEMENT_MODELS.md`.
- **Source Location**: `d:\Elemental_Limbs_10_Characters\Elemental_Limbs` (configured via `tools/blender/mixamo_paths.json`).
- **Retention & License Policy**: In accordance with the project asset ledger, derived from Adobe Mixamo humanoid models (Adobe Terms of Use; redistribution prohibited). Kept strictly local and git-ignored under `assets/limbs_elemental/` via `.gitignore`.
- **Limb Coverage**:
  - 10 character pairs (Right Arm and Right Leg), each themed to an elemental visual style:
    - `atalanta` (Arissa): Phoenix Ember
    - `theron` (Paladin): Solar Relic
    - `pyrrhus` (Ch34): Glacial Quartz
    - `sibyl` (Maria): Soulglass
    - `skin_ch39` (Ch39): Storm Conductor
    - `skin_ch40` (Ch40): Abyssal Coral
    - `skin_demon` (Demon): Obsidian Magma
    - `skin_kachujin` (Kachujin): Ancient Root
    - `skin_nightshade` (Nightshade): Void Thorn
    - `vampire_stress` (Vampire): Blood Ossuary
  - Symmetrically mirrored left-side equivalents (`_l`) generated across the sagittal plane ($X \to -X$) with inverted normals and mapped left-side bone chains (`upper_arm.l`, `thigh.l`, etc.), yielding **40 independent rigged GLBs** registered in `assets/limbs_elemental/limbs_manifest.json`.

---

## 2. Rigging & Shared-Skeleton Binding Architecture
- **Non-Destructive Binding**: Rather than relying on arbitrary socket-relative scaling (`base_scale = width/0.45, height/1.80`), elemental replacement limbs are bound directly to the character's evaluated `Skeleton3D` deform skeleton (`Skeleton3D.add_child(limb_mesh); limb_mesh.skeleton = NodePath("..")`).
- **Deformation & Motion Driving**: Replacement limbs follow natural Mixamo animation clips seamlessly (idle, forward walk, backward walk, jab, kick, block, hit reactions).
- **Presentation Mapping & Fallback**:
  - `FighterRig.gd` resolves compatible elemental replacements based on the active character `loaded_fighter_model_id` and limb slot.
  - Legacy prototype limbs (`rubber_chicken_arm`, `hermes_sandal_leg`, etc.) remain fully functional as socket-attached fallbacks for backwards compatibility and mechanical testing.
  - Gameplay mechanics (integrity rules, speed/reach/damage modifiers, combat simulation hashes) remain completely decoupled from visual geometry.

---

## 3. Shared Attachment Lifecycle & Pilot Controls
- Shared state machine strictly enforced across runtime and preview:
  $$\text{NATURAL} \longrightarrow \text{SEVERED (stump cap)} \longrightarrow \text{REPLACED (stump hidden)} \longrightarrow \text{RE-SEVERED / RESET}$$
- Integrated into `PilotGateAPreview` (`src/presentation/pilot_gate_a_preview.gd`):
  - `[1]`: Toggle Left Arm Sever
  - `[2]`: Toggle Left Leg Sever
  - `[3]`: Toggle Regrown Arm
  - `[4]`: Toggle Regrown Leg
  - `[V]`: Toggle Visual Variant (Elemental Phoenix Ember vs Legacy Prototype)
  - `[F]`: Flip Combat Facing (+X vs -X)
  - `[C]`: Toggle Camera (Front Combat vs Profile)
  - `[SPACE]`: Cycle Animation Action
  - `[M]`: Toggle Intact / Partitioned Model

---

## 4. Verification & Test Evidence
- **Godot Regression Suite**: **139 passed, 0 failed, 0 skipped**.
  - Added `tests/unit/test_elemental_limbs.gd`: verifies 40 manifest entries, shared skeleton binding on Atalanta and Theron, natural/stump visibility toggling, and multi-timestamp animation pose continuity.
  - `test_gate_a_pilot.gd` and `test_attachment_matrix.gd` pass with zero regressions.
- **Python Validators & Status**: All 14 tests in `tools/validate` and 12 tests in `tools/status` pass cleanly.
- **Code Quality**: `gdlint` and `gdformat` verified clean across all modified presentation files.
- **Verification Command**: `powershell -ExecutionPolicy Bypass -File tools/check_all.ps1` returned exit code 0 (`check_all: PASS`).
