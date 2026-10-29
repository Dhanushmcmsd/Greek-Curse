# Mortal Kombat 1 (MK12) — Core Gameplay Mechanics Reference
> **Source**: Direct binary string extraction from FModel-exported `.mko` script files  
> **Files Analyzed**: `FightEngine.mko`, `SharedReactions.mko`, `TutorialDefinitions.mko`, `PassiveModifiers.mko`, `BrutalityShared.mko`, `KomboTrialModifier.mko`, `AI.mko`, `AIComboFinder.mko`, `DisablerModifiers.mko`, `SuperArmorModifier.mko`, all `Debuff/*.mko`, `UppercutModifier.mko`, `DamageOverTimeModifier.mko`, `HealingPassiveModifiers.mko`, `ResurrectionModifiers.mko`, and more  
> **Archive**: `MK12-Switch.pak` / `MK12-Switch.utoc` (291,355 files, GAME_UE4_27)

---

## Table of Contents
1. [Fight Engine Core](#1-fight-engine-core)
2. [Input System](#2-input-system)
3. [Movement & Physics](#3-movement--physics)
4. [Attack System](#4-attack-system)
5. [Blocking & Defense](#5-blocking--defense)
6. [Hit Reactions & Knockback](#6-hit-reactions--knockback)
7. [Combo System (Kombo)](#7-combo-system-kombo)
8. [Meter System](#8-meter-system)
9. [Kameo (Partner) System](#9-kameo-partner-system)
10. [Debuff / Status Effect System](#10-debuff--status-effect-system)
11. [Armor System](#11-armor-system)
12. [Throw System](#12-throw-system)
13. [Wakeup System](#13-wakeup-system)
14. [Special Moves (Supermoves / EX)](#14-special-moves-supermoves--ex)
15. [Brutality System](#15-brutality-system)
16. [Fatality / Finish Him](#16-fatality--finish-him)
17. [AI Behavior](#17-ai-behavior)
18. [Damage Scaling & Modifiers](#18-damage-scaling--modifiers)
19. [Passive Modifiers & Buffs](#19-passive-modifiers--buffs)
20. [Elemental Types](#20-elemental-types)
21. [Physics & Ragdoll](#21-physics--ragdoll)
22. [Wall & Arena Interaction](#22-wall--arena-interaction)
23. [Health & Resurrection](#23-health--resurrection)
24. [Animation & Timing Framework](#24-animation--timing-framework)

---

## 1. Fight Engine Core

**Source**: `FightEngine.mko` (136 KB)

The fight engine is the master controller that governs the entire match lifecycle. Key internal identifiers reveal its structure:

| Identifier | Purpose |
|---|---|
| `FightEngine.mko` | Root engine script, loaded for every match type |
| `MKFightEngine::CharX` | Character state management context |
| `GameContext` | Global per-frame game context object |
| `IsMatch` | Match active flag |
| `IsRoundOver` | Round termination check |
| `EndOfRound` | End-of-round event trigger |
| `FinishHim` | Finish-him state activation |
| `inishHimCondition` | Condition check for Finish Him eligibility |
| `HealthSystem` | Health management subsystem |
| `BASICALLY_FOREVER` | Infinite loop constant (used for persistent procs) |
| `ALLOWED_ON_PROC_STACK` | Flag: proc can coexist on the proc stack |
| `MOPriority_MIN_OVERRIDE` | Lowest modifier override priority |
| `MOPriority_MAX_OVERRIDE` | Highest modifier override priority |
| `PID_MY_DISABLEBLUR_PROC` | Proc ID for disabling motion blur |
| `NRSDebugData` | NRS internal debug data stream |
| `syncErrorMonitor` | Synchronization error watcher (online) |
| `LockstepSyncWait` | Lockstep online sync wait state |
| `ScriptCommon.mkh` | Shared header included by all scripts |
| `DataShared.h` | Shared C++ header bridge |

### Fight State Machine
```
Idle → [Input] → Attack / Block / Move / Jump
Attack → [Hit] → HitReaction → [Combo Window] → Next Attack
Attack → [Miss/Block] → Recovery → Idle
HitReaction → [Knockdown] → Wakeup → Idle
Any → [FinishHim] → Fatality / Brutality / Time Over
```

### Round Flow
- `PrefightChoreo.mko` — pre-fight intro choreography
- `CanPlayMidRoundQuip` — mid-fight voice quip gating
- `EndOfRound` → `PlayDefeat` animation → `Victory` state
- `ThanksForPlaying` — post-match outro

---

## 2. Input System

**Source**: `FightEngine.mko`, `TutorialDefinitions.mko`

### Input Types
| Input | Internal Name |
|---|---|
| Face button press | `FaceButtonI` |
| Held direction input | `_inputs_` |
| Forward | `_Forward` |
| Quarter-circle | `quarter_circle_[direction]` |
| Charge | `sp_chargeactive`, `sp_chargeD` |
| Super / EX | `sp_super`, `sp_sup`, `sp_u_` |
| Jump up | `jJumpUp`, `JumpForward`, `JumpBack` |
| Dash forward | `DashFwd`, `ForwardDashCancel` |
| Dash back | `DashBwd` |
| Air dash | `AirDropO` |
| Neutral | `padinfo_neutral` |

### Input Buffering
- `MinFrames` — minimum frame threshold for input registration
- `ick_window` — input window per attack (frame window)
- `EXTiming` — EX move timing window
- `_anim_hold_` — animation hold for charge inputs
- `IgnoreHeld` — flag to ignore held inputs in certain states

### Button Remapping
- `osButtonRemap` — button remap overlay system

---

## 3. Movement & Physics

**Source**: `FightEngine.mko`, `AI.mko`, `SharedReactions.mko`

### Grounded Movement
| Mechanic | Identifier |
|---|---|
| Walk forward | `_Forward` |
| Walk back | `BackwardMovgBOvers` |
| Dash forward | `DashInto`, `SafeDashW` |
| Dash back | `DashAwayFrom` |
| Crouch | `GDuck`, `ODuck` |
| Crouch cancel | `DDuck` |
| Run cancel | `CancelRun` |

### Aerial Movement
| Mechanic | Identifier |
|---|---|
| Jump up | `JumpIn` / `jJumpUp` |
| Jump forward | `JumpForward` |
| Jump back | `JumpBack` |
| Jump cancel | `JumpCancel` |
| Jump punch (air) | `JumpInPunch` |
| Jump kick (air) | `JumpKickupV` |
| Air dash | `AirDropO` |
| Air Kombo | `AirKombo` |
| Air throw | `AirThrow` |
| Jump time to apex | `jumpTimeToApex` |
| While airborne | `WhileAirborne`, `_WhileAirborne` |

### Physics Parameters
| Parameter | Identifier |
|---|---|
| Gravity value | `gravityValue` |
| Vertical velocity | `upforwardB` |
| Angular X rotation | `AngularX` |
| High speed Y | `HighSpeedY` |
| In-air damage multiplier | `in_air_multiplierB` |
| Land in ticks | `LandInTicks` |
| Land recovery | `LandReco` |
| Always pushback | `always_pushback` |
| Force away on | `forceaway_on` |
| Wall threshold | `_to_wall_in_front_threshold` |
| Wall constraints | `CONSTRAIN_WALLS`, `ConstrainWalls2` |

### Pushback
- `PushBackOn` — enables pushback on block
- `always_pushback` — forces pushback regardless of block
- `blockShake` — screen shake on blocked hit
- `lockPressure` — block pressure system

---

## 4. Attack System

**Source**: `FightEngine.mko`, `SharedReactions.mko`, `TutorialDefinitions.mko`

### Attack Categories
| Category | Identifier |
|---|---|
| Light attack | `_Light` |
| Medium attack | `nMedium` |
| Strong / Heavy | `nStrong` |
| Anti-air | `AntiAir`, `Str_AntiAir` |
| Overhead | `Overhead`, `OverHead_SlamDown` |
| Low | `LowDrop`, `lowleg_l` |
| Gut punch | `Gut1Hop`, `Gut1InPlace`, `Gut1Buckle` |
| Divekick | `Divekick`, `DiveKickAir` |
| Sweep | `FSweeX` |
| Uppercut | `Uppercut`, `xUppercut`, `RisingKnee` |
| Launcher | `Launcher`, `aLaunch` |
| Backflip kick | `ScorpionBackFlipKick` |
| Rapid fist | `gRapidFist`, `gRapidFists` |
| Spin attack | `BSpin`, `CSpin`, `OSpin` |
| Hop punch | `xHopPunch` |

### Attack Properties
| Property | Identifier |
|---|---|
| Attack collision definition | `ATTACK_COL_DEF` |
| Hit pause | `hit_pause` |
| Hit damage | `hitDam` |
| Hit props | `HitProps` |
| Damage type | `ElementalType` |
| Move boost damage | `moveBoostDamageS` |
| Kritical hit chance | `ReptileAcidKriticalHitChanceInvisible` |
| Combo window | `PID_COMBO_WINDOW_HINTS_PROC` |
| Anti-air detection | `jAntiAir` |
| Attack region list | `AttackRegionLisc` |
| Vertical victim region | `IncreaseVerticalVictimRegion` |
| Hit confirm | `HitConfirm`, `NotHitConfirm` |
| Hit advantage | `HitAdvantageb` |
| Escape special move | `ESCAPE_SPECIAL_MOVE_COMBR` |

### Krushing Blows
- `KrushingBlowC` — Krushing Blow trigger condition
- Fires when: critical hit threshold reached + specific move connected + conditions met

---

## 5. Blocking & Defense

**Source**: `FightEngine.mko`, `TutorialDefinitions.mko`, `DisablerModifiers.mko`

### Block Types
| Type | Identifier |
|---|---|
| Standing block | `Blocking1g` |
| Crouch block | `Basic_Blocking_1_J` |
| Breaker (combo escape) | `EX_Burst`, `BreakerK`, `BreakerHit`, `BREAKER_DAM` |
| Chip damage on block | `Adv_Chip` |
| Block stagger | `cStagger`, `lStagger` |
| Perfect block | `PerfectQ`, `llPerfect` |

### Defensive Options
| Option | Identifier |
|---|---|
| Flawless block | `oCorrectBlockAnimationFrom` (precise timing) |
| Armored reversal | `forceArmor`, `XArmor` |
| Parry | `_Parry`, `SnParr` |
| Reversal | `PauseReversal`, `sReversal`, `jReversal` |
| Crouch under projectile | `DuckUnderFireball` |
| Escape up (in air) | `irEscapeUp_` |
| Escape from wall | `EscapeFromWall` |
| Auto throw escape | `AutoThrowEscape` |

### Pressure System
- `GapsAndArmor` — gap checker in block strings (tutorial system)
- `bUnsafeJ[ump]` — unsafe jump-in detection
- `lockOrDuck` — option to block or duck on incoming high/low
- `Pressure` — pressure system identifier

---

## 6. Hit Reactions & Knockback

**Source**: `SharedReactions.mko` (1.46 MB — largest single script file)

### Reaction Types
| Reaction | Identifier |
|---|---|
| Generic hit reaction | `gRxGenericFacialMovesetFunction` |
| Head flattened on face | `gRxHead3FlattenedOnFace` |
| Corkscrew two spins | `gRxChest3CorkscrewTwoSpins` |
| Ring out | `gRxRingOut` |
| Null reaction | `RxNULL`, `FxRxNull` |
| Large FX reaction | `FxRxLarge` |
| Crumple | `Crumple`, `grumple`, `OverheadCrumble` |
| Gut buckle | `Gut1Buckle` |
| Stagger | `cStagge`, `lStagge` |
| Arm flail EX | `ArmFlailEX` |
| Body slash | `BodySlash` |
| Airborne reaction | `Airborne`, `gAirborne`, `RAirHi` |
| Side slam IV | `SideSlamIV` |
| Spin slam | `SpinSlam`, `SpinFlop`, `SpinFloph` |
| Flip and turn | `FlipAndTurn` |
| Fall down | `FallDown` |
| Neck snap | `NeckSnap` |
| Body ground | `BodyGround` |
| Hypnotized into | `HypnotizedInto` |

### Knockdown States
| State | Identifier |
|---|---|
| Knockdown (generic) | `KnockdownC` |
| Hard knockdown | `BHarde`, `KHard`, `OHard` |
| Delayed getup | `bIsDelayedGetup` |
| Wakeup attack | `WakeupAtta` |
| Getup from knockdown | `ExitToGetup`, `MoveFromWakeup` |
| On back (new close) | `OnBackNewClose` |
| Boss down | `BOSS_DOWN` |
| Defeat | `DEFEATED` |

### Hit Reaction Properties
| Property | Identifier |
|---|---|
| Damage group scrapes | `DMG_Group_Scrapes` |
| Blood spray | `_Spray`, `ARSpurt` |
| Decal on hit | `Decal-`, `Decals/HG1` |
| Impact FX | `GetMedBangImpactFX`, `rImpact` |
| Block FX type | `BLOCK_FX_TYPE` |
| Counter FX | `CounterFX` |
| Slow world on hit | `SlowWorldNo` (slowdown/freeze effect) |
| Time dilation | `TimeDilz`, `qTimeDil` |
| Frozen movement counter | `FrozenRxMoveCntr` |
| Drill reaction counter | `DrillRxMoveCntr` |
| Camera lock on super | `MSF_CameraLock` |

### Juggle System
| Property | Identifier |
|---|---|
| Juggle launch | `Adv_JuggF`, `Adv_JuggleCombo` |
| Juggle state | `bJuggle` |
| Air juggle flag | `OJugg` |
| Launch and land | `LaunchAndLand` |
| Pop-up | `QPopUp`, `gPopup1` |
| Anti-air jail | `AJail` |
| Less scaling | `LessScaling` |

---

## 7. Combo System (Kombo)

**Source**: `KomboTrialModifier.mko`, `TutorialDefinitions.mko`, `AIComboFinder.mko`

### Combo Building
| Mechanic | Identifier |
|---|---|
| Kombo string | `lCombo`, `SCombo`, `RComboD` |
| Attack-to-attack | `AtkToAtk` |
| Kombo window hints | `PID_COMBO_WINDOW_HINTS_PROC` |
| Window ticks | `WindowTicks` |
| Forced dash cancel | `ForwardDashCancel` |
| Jump cancel | `JumpCancel` |
| In-a-combo state | `InACombo()` |
| Combo test check | `ComboTestChe` |

### Combo Restrictions
| Restriction | Identifier |
|---|---|
| Repetitive attack penalty | `RepetitiveAttacksDecreaseDamageModifier` |
| Combo scaling multiplier | `MULTIPLIER1`, `MultiplierFromStats` |
| No-move flag | `lNoMove`, `nNoMove` |
| Kombo rules | `KomboRulesE` |
| Ten-hit kombo meter restore | `TenHitKomboRestor` |

### Juggle Combo
- Launch → Air Kombo → Ender structure
- `Adv_JuggleCombo` — advanced juggle combo
- `bJuggle` — juggle state active flag
- Damage decreases with each juggle hit

---

## 8. Meter System

**Source**: `FightEngine.mko`, `MeterAdjustModifiers.mko`, `PassiveModifiers.mko`

### Meter Types
| Meter | Identifier |
|---|---|
| EX / Super meter | `c_Meter`, `MeterBurn` |
| Kameo meter | `KameoGrdSm`, `KameoPressure` |
| Titan meter | `InnerTitanModifier` |
| Eagly meter (Peacemaker) | `PeacemakerEaglyMeterModifier` |

### Meter Gain / Spend
| Action | Identifier |
|---|---|
| Meter burn (EX move) | `MeterBurn` |
| Burst cost | `BCost` |
| Super move activation | `MB_Activate`, `pSupermove` |
| Restore meter on fire debuff | `FireAttackRestoreMeterOnFireDebuffModifier` |
| Meter adjust modifier | `MeterAdjustModifiers` |
| Unlimited super (modifier) | `UnlimitedSupY` |
| Move costs | `moveCosts` |
| Kameo od damage cap | `KAMEO_KOD_DAMAGE` |

### EX System
- `EX_Burst` — EX breaker during combo
- `Uup_EX` — EX uppercut variant
- `SAirEX` — EX air special
- `KUpEX1` — character-specific EX move
- `LungeEX` — EX lunge special
- `gGrappleInteractEX` — EX grapple interact

---

## 9. Kameo (Partner) System

**Source**: `FightEngine.mko`, `TutorialDefinitions.mko`, `KHAR_*.mko` files

### Kameo Mechanics
| Mechanic | Identifier |
|---|---|
| Kameo summon | `SKameo`, `partnerSummonProc` |
| Kameo pressure | `KameoPressure` |
| Kameo animation | `KameoAnim` |
| Kameo ground slam | `KameoGrdSm` |
| Kameo eye laser | `KAM_KAN_EyeLaser` |
| Kameo KOD damage | `KAMEO_KOD_DAMAGE` |
| MAVADO trap | `MAVADO_TRAP` |
| Spear assist | `SpearAssistModifier` |
| Sai rain | `KitanaSaiRainModifier` |
| Night stick smash | `KamDesignDataNightStickSmashB` |

### Available Kameo Characters
Cyrax, Darrius, Ferra, Frost, Goro, Jax, Janet Cage, Kano, Khameleon, Kung Lao, Mavado, Motaro, Sareena, Scorpion, Sektor, Shujinko, Sonya, Stryker, Sub-Zero, Tremor, plus all story NPCs (Baraka NPC, Ermac NPC, etc.)

---

## 10. Debuff / Status Effect System

**Sources**: `IceDebuff.mko`, `ElectricDebuff.mko`, `FireDebuff.mko`, `BloodDebuff.mko`, `ChaosDebuff.mko`, `DarkDebuff.mko`, `PhysicalDebuff.mko`, `CommonDebuff.mko`, `DamageOverTimeModifier.mko`

### Status Effect Types
| Effect | Source File | Key Properties |
|---|---|---|
| **Fire** | `FireDebuff.mko` | DoT damage, `OnFire_Small`, burn state |
| **Ice / Frozen** | `IceDebuff.mko` | `SUBZERO_DEEP_FREEZE`, frozen counter, slows movement |
| **Electric** | `ElectricDebuff.mko` | Electric stun, `ElectricCharge`, floor zap |
| **Blood** | `BloodDebuff.mko` | Ongoing drain, `BloodBurn`, health loss |
| **Chaos** | `ChaosDebuff.mko` | Random effect, `ChaosReflect` |
| **Dark** | `DarkDebuff.mko` | `DarkTorment`, `DarkSpite`, vision impair |
| **Physical** | `PhysicalDebuff.mko` | Standard physical debuff |
| **Acid** | `AcidDebuff.mko` | `AcidDebuffModifier`, DoT acid damage |
| **Magic** | `MagicDebuff.mko` | `MagicJinx`, magic drain |
| **Energy** | `EnergyDebuff.mko` | Energy drain, meter loss |
| **Poison** | `w_Poison`, `MOD_Poison` | DoT poison |

### Common Debuff Properties
| Property | Identifier |
|---|---|
| Debuff immunity | `DebuffImmunityModifier`, `ImmunityEnabled` |
| Debuff stack | `lDebuff`, `AndNoDebuffP` |
| Decay rate | `_Decay`, `decay` |
| Damage over time | `DamageOverTimeModifier` |
| Active ticks | `Active_Ticks` |
| Debuff label | `Bufflabel` |
| Apply status effect | `ApplyStatusEffect` |
| Buff stackable | `sBuffabl` |
| Buff stack count | `BuffStackl` |
| Remove buff cleanup | `RegCleanup` |

---

## 11. Armor System

**Sources**: `SuperArmorModifier.mko`, `PassiveModifiers.mko`, all `*ArmorModifier.mko`

### Armor Types
| Type | Source |
|---|---|
| Super armor | `SuperArmorModifier.mko` |
| Fire armor | `FireArmorModifier.mko` |
| Ice armor | `IceArmorModifier.mko` |
| Electric armor | `ElectricArmorModifier.mko` |
| Blood armor | `BloodArmorModifier.mko` |
| Chaos armor | `ChaosArmorModifier.mko` |
| Dark armor | `DarkArmorModifier.mko` |
| Energy armor | `EnergyArmorModifier.mko` |
| Magic armor | `MagicArmorModifier.mko` |
| Physical armor | `PhysicalArmorModifier.mko` |
| Elemental aura armor | `*ArmorAuraModifier.mko` (all elements) |

### Armor Properties
| Property | Identifier |
|---|---|
| Armor damage multiplier | `armorDamageMultiplier` |
| Force armor | `forceArmor` |
| Armor pierce | `alArmorPierC` |
| Armor active flag | `XArmor` |
| Play armor material FX | `PlayArmorMat` |
| Armor timeline | `TL_ARMOR` |
| Inner titan armor | `InnerTitanModifier` |

### Armor Behavior
- Absorbs one hit (or specified count) without interrupting the move
- `armorDamageMultiplier` — damage that still passes through
- `alArmorPierc` — certain moves bypass armor entirely
- Elemental armors apply their debuff back on the attacker when triggered

---

## 12. Throw System

**Sources**: `FightEngine.mko`, `TutorialDefinitions.mko`, `SharedReactions.mko`

### Throw Types
| Type | Identifier |
|---|---|
| Forward throw | `QGrab_Y` |
| Backward throw | `BwdThrow`, `QGrab_H` |
| Air throw | `AirThrow` |
| Command grab | `qGrappleInteract`, `GGrab` |
| Leg grab | `LegGrab`, `LegGrabj` |
| Overhead slam | `OverHead_SlamDown`, `ShadowTackleSlam` |
| Throw escape | `AutoThrowEscape`, `SUB_THROWAWAY` |

### Throw Properties
- `qGrappleInteractEX` — EX command grab variant
- `PrioritizeGrappler` — AI prefers grapple if available
- `gVampireGrab`, `gVampireGrabL` — Nitara's vampire grab (Kameo)
- Grab window: standard timing window
- `BreakableF` — throw break window active flag

---

## 13. Wakeup System

**Sources**: `FightEngine.mko`, `TutorialDefinitions.mko`

### Wakeup Options
| Option | Identifier |
|---|---|
| Normal wakeup | `Wakeup`, `Wakeupd` |
| Wakeup attack | `WakeupAtta` |
| Delayed getup | `bIsDelayedGetup` |
| Getup with duck | `st_getup_with_duck` |
| Move from wakeup | `MoveFromWakeup` |
| Wakeup tap (escape) | `wTut_Tap`, `Tut_TapAway` |
| From knockdown max | `from_knockdown_max` |

### Wakeup Timing
- Wakeup attacks are invincible during startup frames
- Punishable on block
- Delayed getup extends vulnerability window
- `Tut_BeforeLand` — wakeup action registered before landing

---

## 14. Special Moves (Supermoves / EX)

**Sources**: `FightEngine.mko`, `TutorialDefinitions.mko`, character `CHAR_*.mko` files

### Special Move Framework
| Mechanic | Identifier |
|---|---|
| Supermove activation | `Supermove`, `Supermove2` |
| Super 1 | `a1Super` |
| EX variant | `sp_super`, `Uup_EX` |
| Fatal blow / Super | `MB_Activate` |
| Teleport | `Teleport`, `MSF_TeleportInto` |
| Invincibility frames | `Invincibl` |
| Projectile | `KProjectiw` |
| Force ball slow | `ForceballSlow` |
| EX burst | `EX_Burst` |
| Stance toggle | `pStanceTog` |

### Move Properties
| Property | Identifier |
|---|---|
| Recovery | `tecovery`, `Recovery` |
| Safe move | `FSafe`, `PickSafe` |
| Unsafe jump | `bUnsafeJ` |
| Punish window | `PunishAfterSuccessful` |
| Cooldown | `COOLDOWN`, `Cooldown` |

---

## 15. Brutality System

**Source**: `BrutalityShared.mko` (109 KB), `BrutalityKombatModifier.mko`

### Brutality Mechanics
| Mechanic | Identifier |
|---|---|
| Brutality trigger | `BrutalityReaction` |
| Combo rules enforcement | `KomboRulesE` |
| Brutality combat modifier | `BrutalityKombatModifier` |
| Drop head | `DropHead`, `KnockoffHead` |

### Gore System (Brutalities)
| Gore Type | Identifier |
|---|---|
| Head explosion | `HeadExplod2` |
| Neck snap | `NeckSnap` |
| Neck break | `NeckBreak` |
| Neck slice | `NeckSlice` |
| Neck rip | `Temp/NeckRip_Inverse` |
| Jaw rip | `Dism/CutLibrary/JawRip` |
| Dismemberment | `UDismembermentCut`, `DDism`, `disNeckCut` |
| Limb cut | `LimbCutA`, `rOffLimb`, `OLimb3` |
| Waist rip | `WaistRipo` |
| Skull explode | `_SkullExplode` |
| Jelly splat | `JellySplatWorkingC` |
| No bones no meat | `_NOBONESNOMEAT`, `NoBonesNoMea` |
| Body explosion | `_BodyExplosion` |
| Blood spray | `_Spray`, `ARSpurt`, `ZDrips`, `_Drips` |
| Blood pool | `APool`, `JPool` |
| Head landing | `Head_Land` |
| Burn head | `FireHeadT`, `Fire_Hea` |
| Bone break | `_Bone_Break_` |
| Body burn | `_Burnt` |
| Torso dump | `TorsoDumK` |
| Bottom half rip | `BottomHalfR` |
| Top half | `uTopHalf` |
| Cloth sim | `aCloth` |
| Flake dissolve | `FlakeDissolvZ` |

### Brutality Conditions
- Must be the final hit of a combo
- Specific move must be used on KO hit
- Some require specific button hold during final hit
- `DismInCornerOverTicksW` — dismemberment in corner over ticks
- Slowdown on kill: `SloMo_Exit_Short`
- Gore decal system: `PawnPaint`, `VDECAL`
- Radial burst effect: `RadialBursS`

---

## 16. Fatality / Finish Him

**Sources**: `FightEngine.mko`, `FatalityKombatModifier.mko`, `FatalityPractice.mko`

### Fatality Flow
| State | Identifier |
|---|---|
| Finish Him trigger | `FinishHim`, `inishHimC` |
| Fatality kombat modifier | `FatalityKombatModifier` |
| Fatality practice mode | `FatalityPractice` |
| Stage fatality | `BackStageFatality` |
| Camera lock | `MSF_CameraLock` |
| Slow motion | `SlowWorldNo`, `SLOWDOWN` |

### Fatality Input
- Standard: directional input + button within ~10 seconds
- Practice mode available via `FatalityPractice.mko`
- Stage fatality: character-specific + stage-specific requirements

---

## 17. AI Behavior

**Source**: `AI.mko` (532 KB), `AIComboFinder.mko`, `AIButtonMasher.mko`, `AINormal.mko`, `AIScriptedEncounter.mko`

### AI Difficulty System
| Property | Identifier |
|---|---|
| Difficulty levels | `DiffLevels`, `AIDifficulty` |
| Make mistake for M[ode] | `MakeMistakeForM` |
| Spam detection | `SpamDete`, `RSpammAttempt`, `AntiSpamAdd` |
| Personality | `personality` |
| AI sensor | `EAISensor` |

### AI Decision Tree
| Decision | Identifier |
|---|---|
| Perform attack | `AIPerform`, `oAttack` |
| Block | `Abloc`, `_to_blockinR` |
| Dash toward | `DashInto`, `eToward` |
| Dash away | `DashAwayFrom` |
| Jump | `EJump`, `JumpForward` |
| Jump to counter jumping | `JumpToCounterJumping` |
| Duck/crouch | `ODuck`, `GDuck` |
| Escape from wall | `EscapeFromWall` |
| Safe move picker | `PickSafe` |
| Grappler priority | `PrioritizeGrappler` |

### AI Combo System
| Mechanic | Identifier |
|---|---|
| Combo finder | `AIComboFinder.mko` |
| Combo sequence length | `SequenceLength`, `NumMovesToLookB` |
| Follow-up actions | `Followup` |
| Respond to moves | `ForAnyResponse` |
| Keep char outside combo | `OnlyChooseAComboThatKeepsCharacterOutside` |
| Num attacks used | `NumAttack` |

### AI Range Management
| Mechanic | Identifier |
|---|---|
| Distance range | `_dist_rang` |
| Min distance | `bMinDis` |
| In desired range % | `InDesiredRangePercentageMinF` |
| Far range | `oA_Long` |
| Close range | `close`, `closeTo` |
| Zoning | `oZoning` |

---

## 18. Damage Scaling & Modifiers

**Sources**: `FightEngine.mko`, `RepetitiveAttacksDecreaseDamageModifier.mko`, `DamageOverTimeModifier.mko`, `ReflectDamageModifier.mko`

### Damage Formula
```
FinalDamage = BaseDamage × ComboScaling × ArmorMultiplier × DebuffMultiplier × LuckFactor
```

| Component | Identifier |
|---|---|
| Base damage | `hitDam` |
| Combo scaling | `MultiplierFromStats`, `MULTIPLIER1` |
| Armor multiplier | `armorDamageMultiplier` |
| In-air multiplier | `in_air_multiplierB` |
| Luck factor | `LuckFactorG`, `LuckyBuff` |
| Move boost damage | `moveBoostDamageS` |
| Reflect damage | `ReflectDamageModifier` |
| Chip damage on block | `Adv_Chip` |
| Damage over time | `DamageOverTimeModifier` |
| Current hit count | `CurrentNumberOfHitDone` |

### Damage Reduction
| Mechanic | Identifier |
|---|---|
| Repetitive attack penalty | `RepetitiveAttacksDecreaseDamageModifier` |
| Less scaling flag | `LessScaling` |
| Blood reversal | `BloodReversalModifier` |
| Kameo KOD cap | `KAMEO_KOD_DAMAGE` |

---

## 19. Passive Modifiers & Buffs

**Source**: `PassiveModifiers.mko` (144 KB)

### Healing Passives
| Mechanic | Identifier |
|---|---|
| Heal amount | `HealAmount` |
| Heal over time | `HealOverA[Time]` |
| Heal percentage | `healPercentage` |
| Regen | `AdRegen` |
| Mid-health trigger | `MidHealth` |
| When losing heal | `WhenLosingt` |

### Buff System
| Mechanic | Identifier |
|---|---|
| Buff label | `Bufflabel` |
| Buff stacks | `BuffStackl` |
| Critical hit modifier | `CriticalHi` |
| Lucky buff | `LuckyBuff` |
| Luck factor | `LuckFactorG` |
| Speed multiplier | `SpeedMultiplier` |
| Unstoppable | `UnstoppableChan` |
| Unlimited super | `UnlimitedSupY` |
| Invisibility modifier | `InvisibilityModifier` |
| Random buff on taunt | `RandomBuffOnTauntModifier` |

### Character-Specific Passives (Confirmed in .mko)
| Character | Passive | Source |
|---|---|---|
| Havik | Regen on health loss | `HavikRegenModifier` |
| Reptile | Acid kritical hit chance when invisible | `ReptileAcidKriticalHitChanceInvisibleModifier` |
| Reptile | Invisibility on EX move | `ReptileExMoveInvisibleModifier` |
| Reptile | Extended invisibility | `ReptileInvisibilityExtendedModifier` |
| Ermac | Improved mana shield | `ErmacImprovedManaShieldModifier` |
| Noob Saibot | Improved shadow clone | `NoobSaibotImprovedShadowCloneModifier` |
| Noob Saibot | Infinite Embrace Chaos | `NoobSaibotInfiniteEmbraceChaosModifier` |
| Nitara | Infinite air dashes | `NitaraInfiniteAirDashesModifier` |
| Kung Lao | Magic passive | `KungLaoMagicPassive` |
| Kung Lao | Unlimited spin | `KungLaoUnlimitedSpinModifier` |
| Omni-Man | Improved stance | `OmnimanImprovedStanceModifier` |
| Peacemaker | Eagly meter | `PeacemakerEaglyMeterModifier` |
| Peacemaker | Gun damage boost | `PeacemakerGunDamageModifier` |
| T-1000 | Meter death trigger | `T1000MeterDeathModifier` |
| Johnny Cage | Hype modifier | `JohnnyHypeModifier` |
| Sindel | Inspire modifier | `SindelInspireModifier` |
| Shang Tsung | Morph modifier | `ShangTsungMorphModifier` |
| QuanChi | Zone duration modifier | `QuanChiZoneDurationModifier` |
| Cyrax | Bomb damage boost | `CyraxBombDamageModifier` |
| Cyrax | Snare modifier | `CyraxSnareModifier` |
| Ghostface | Killer health modifier | `GhostfaceKillerHealthModifier` |
| Homelander | Stomp modifier | `HomelanderStompModifier` |
| Reiko | Improved high modifier | `ReikoImprovedHigh` |
| Takeda | Shuriken duration | `TakedaShurikenDurationModifier` |
| Takeda | Whip damage | `TakedaWhipDamageModifier` |
| Tanya | Royal charge | `TanyaRoyalChargeModifier` |
| Raiden | Electric charge | `RaidenElectricChargeModifier` |
| Shao Kahn | Improved axe buff | `ShaoKahnImprovedAxeBuffModifier` |
| Conan | Flame sword attack | `ConanFlameSwordAttackModifier` |

---

## 20. Elemental Types

**Sources**: All `*Debuff.mko`, `*Modifier.mko`, `*AuraModifier.mko`

| Element | Debuff Effect | Major Modifiers |
|---|---|---|
| **Fire** | Burns, DoT fire damage | Ball, Armor, Aura, Block, Fists, Meteor, Pillar, Storm, Floor, Orb |
| **Ice** | Slows, freezes (`SUBZERO_DEEP_FREEZE`) | Ball, Armor, Aura, Klone, Compactor, Saw Blade, Spike, Totem, Wall |
| **Electric** | Stuns, `ElectricCharge` | Ball, Charge, Cloud, Chains, Floor, Flies, Mines, Rain, Runes, Strike |
| **Blood** | DoT, `BloodBurn`, screen effect | Ball, Burn, Bubbles, Drop, Mist, Puddle, Rain, Ritual, Screen, Vortex |
| **Chaos** | Random debuff, `ChaosReflect` | Ball, Cloud, Reflect, Skull, Stalagmite, Storm, Totem |
| **Dark** | `DarkTorment`, `DarkSpite`, vision | Blade Rain, Chains, Hole, Ink Pillar, Mines, Orbital Laser, Portal, Proximity |
| **Acid** | Acid DoT | Ball, Bubbles, Bugs, Corpsedrop, Gas, Mines, Ooze, Pool, Rain, Waves |
| **Magic** | `MagicJinx`, drain | Ball, Drain, Field, Jinx, Meteor, Skull, Storm |
| **Energy** | Meter loss, energy drain | Ball, Cannon, Emitters, Mines, Shield, Storm, Vacuum |
| **Physical** | Physical damage only | Armor, Crystals, Fists, Meteor |

---

## 21. Physics & Ragdoll

**Sources**: `SharedReactions.mko`, `BrutalityShared.mko`, `FightEngine.mko`

### Ragdoll System
| Property | Identifier |
|---|---|
| Physics on | `PhysicsOn` |
| Ragdoll joint | `RD_Left1RagdollAJoint0` |
| Velocity | `Velocity` |
| Rotation | `Rotation` |
| Angular X | `AngularX` |
| Gravity value | `gravityValue` |
| Noise multiplier | `NoiseMult` |
| Emitter radius | `EmitterRadius` |
| Density | `Density` |
| Slice axis | `SliceAxis` |
| Limb blood trail | `ood_LimbTrail` |

### Hit Physics Properties
| Property | Identifier |
|---|---|
| Launch trajectory | `ATraj` |
| Slide left / right | `SlideL`, `SlideR` |
| Floor bounce | `O@RFloor` |
| Wall bounce | `OWall` |
| Land reaction | `CLand` |
| Spin flop | `SpinFlop`, `SpinFloph` |

### Bone System (Hit Detection)
| Bone Group | Identifiers |
|---|---|
| Head | `GP_Head`, `GP_Forehead`, `head_bone`, `head_` |
| Center of mass | `GP_CenterOfMass` |
| Reference | `GP_Reference` |
| Spin | `GP_Spin` |
| Spine | `Rspine` |
| Left leg | `left_leg`, `lowleg_l`, `LeftCalfRoll` |
| Left forearm | `LeftForeArm` |
| Left pinky | `LeftPinky` |
| Left ring | `LeftRing` |
| Hand | `hand_l` |
| Hips | `GP_Hips` |
| Tail | `Tail02` |

---

## 22. Wall & Arena Interaction

**Sources**: `FightEngine.mko`, `SharedReactions.mko`

### Wall Mechanics
| Mechanic | Identifier |
|---|---|
| Wall detection | `IsWallInBackOfMe` |
| Wall constraints | `CONSTRAIN_WALLS`, `ConstrainWalls2` |
| Corner carry | `sToCornerI` |
| Wall threshold | `_to_wall_in_front_threshold` |
| Wall slam | `ShadowTackleSlam` |
| Wall type check | `IsTempOrRealWallI` |
| One-side repel | `sOnOneSideWithRepel` |
| Don't repel flag | `Set_DONT_REPEL_ME_AGAINST_HIM` |
| Inside arena rules | `InsideArenaRules` |
| Wall size | `wallSize` |
| Ring out | `gRxRingOut` |
| End distance | `EndDistance` |

---

## 23. Health & Resurrection

**Sources**: `FightEngine.mko`, `ResurrectionModifiers.mko`, `HealingPassiveModifiers.mko`

### Health System
| Property | Identifier |
|---|---|
| Current life | `curLife` |
| Health left | `HealthLeft` |
| Health system | `HealthSys` |
| Health buff modifier | `HealthBuffModifier` |
| Health burn modifier | `HealthBurnModifier` |
| Health debuff modifier | `HealthDebuffModifier` |
| Health potion modifier | `HealthPotionModifier` |
| Mid-health trigger | `MidHealth` |
| If dead check | `oIfDead` |
| Instant death | `InstantDi` |
| Death buff | `edDeathBuff` |

### Healing / Resurrection
| Mechanic | Identifier |
|---|---|
| Resurrection modifier | `ResurrectionModifiers.mko` |
| Heal over time | `HealOverA` |
| Regen | `AdRegen` |
| Healing crystals | `HealingKrystalsModifier` |
| Havik regen | `HavikRegenModifier` |
| Nitara rune heal | `NitaraRuneHealModifier` |
| Blood aura heal | `BloodAuraPlusHealModifier` |
| Blood fists heal | `BloodFistsPlusHealModifier` |

---

## 24. Animation & Timing Framework

**Sources**: `FightEngine.mko`, `SharedReactions.mko`

### Animation System
| Property | Identifier |
|---|---|
| Animation frame | `CurrentFrame` |
| Frames per second | `FramesPerSecond` |
| 60Hz character | `_60hz_Char_` |
| Anim speed | `AniSpeed` |
| Anim blend ticks | `AniBlendTicks` |
| Anim to frame | `ani_to_frame_x` |
| Anim to breakout | `AniToBreakout` |
| Force next anim mirror | `ForceNextAnimMirrora` |
| Loop anim | `LoopAnim_` |
| Initial blend | `InitalBlen` |
| Mirror | `Mirror` |
| Animation hold | `_anim_hold_` |
| Back-to-idle | `BackToIdleP` |
| Visual bone | `VisualBone` |

### Timing Constants
| Timing Concept | Identifier |
|---|---|
| Tick rate | 60Hz |
| Per second | `sPerSecond` |
| Sleep 30 frames | `sleep_30` |
| Towards 30 frames | `towards_30` |
| Min frames | `MinFrames`, `mMinFrames` |
| Short delay | `ShortDelayP` |
| Time dilation | `TimeDilz` |
| Slow world | `SlowWorldNo`, `SLOWDOWN` |
| Danger time | `DangerTimeModifier` |
| Timestop | `Timestop` (Geras ability) |

### VFX Framework
| System | Identifier |
|---|---|
| Niagara system | `UNiagaraSystem` |
| FX scale | `FX_Scale` |
| VFX anchor | `VFX_Anchor` |
| Particle | `gPartic` |
| Skeletal FX | `gSkelFXVNaObj` |
| Blood decal preset | `FX/Presets/Blood/NSP_` |
| Dust footfall | `DustFootfall` |
| NS dust | `NS_Dust_` |

---

## Appendix: Key File Map

| File | Size | Role |
|---|---|---|
| `SharedReactions.mko` | 1.46 MB | All hit reaction animations & states |
| `TutorialDefinitions.mko` | 1.09 MB | All tutorial mechanics definitions |
| `AI.mko` | 532 KB | Full AI behavior tree |
| `PassiveModifiers.mko` | 144 KB | All passive buff/debuff modifiers |
| `FightEngine.mko` | 136 KB | Core fight engine controller |
| `KomboTrialModifier.mko` | 153 KB | Combo trial definitions |
| `BrutalityShared.mko` | 109 KB | All brutality gore & shared reactions |
| `CHAR_Kenshi.mko` | 3.19 MB | Largest character file (most moves) |
| `Boss_Kenshi.mko` | 3.29 MB | Largest boss file |
| `ShangTsungKlassicNinjaModifier.mko` | 542 KB | Shang Tsung ninja morphs |
| `KHAR_MadamBo.mko` | 882 KB | Madam Bo Kameo (largest Kameo file) |
| `KHAR_Tremor.mko` | 799 KB | Tremor Kameo |

---

*Generated from direct `.mko` binary string extraction via PowerShell analysis of FModel-exported MK12 Switch archive (`MK12-Switch.utoc` — 291,355 files, GAME_UE4_27).*
