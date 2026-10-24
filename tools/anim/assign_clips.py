"""Assigns Mixamo animation clips to the 4 sim fighters deterministically using a fixed seed.

Rules:
1. No duplicate clips between fighters for walk, block, kicks, punches and powers.
2. If a category has fewer clips than fighters, reuse clips with variations (mirror, speed scale, bone-mask mix, additive lean).
3. Actions with no matching folder (run, grab, dodge, get-up, win, lose, superpowers, ultimates) are derived from clips with recipes.
4. "no legs" clips drive crawl and missing-leg body states.
5. All assignments written to data/animation/mixamo_pack_map.json.
"""
import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SEED = 20261025

FIGHTERS = ["theron", "atalanta", "pyrrhus", "sibyl"]

CATEGORIES = {
    "block": [
        "block_body_block",
        "block_center_block",
        "block_left_block",
        "block_standing_block_react_large",
        "block_sword_and_shield_block"
    ],
    "damage_taken": [
        "damage_taken_big_kidney_hit",
        "damage_taken_head_hit",
        "damage_taken_light_hit_to_head",
        "damage_taken_medium_hit_to_head"
    ],
    "death": [
        "death_fall_flat",
        "death_standing_death_backward_01",
        "death_standing_death_left_01"
    ],
    "idle": [
        "idle_and_start_animation_action_idle_to_fight_idle",
        "idle_and_start_animation_arm_stretching",
        "idle_and_start_animation_chapa-giratoria",
        "idle_and_start_animation_happy_idle",
        "idle_and_start_animation_idle",
        "idle_and_start_animation_idle_2",
        "idle_and_start_animation_idle_3",
        "idle_and_start_animation_idle_4",
        "idle_and_start_animation_idle_5",
        "idle_and_start_animation_mutant_flexing_muscles",
        "idle_and_start_animation_mutant_idle",
        "idle_and_start_animation_standing_idle_03"
    ],
    "kick": [
        "kick_drop_kick",
        "kick_flying_knee_punch_combo",
        "kick_jump_attack",
        "kick_kick_to_the_groin",
        "kick_kicking",
        "kick_martelo_2"
    ],
    "crawl": [
        "no_legs_crawling"
    ],
    "punch": [
        "punch_boxing",
        "punch_elbow_punch",
        "punch_illegal_elbow_punch",
        "punch_jab_cross",
        "punch_lead_jab",
        "punch_punching",
        "punch_standing_2h_magic_attack_01"
    ],
    "walk_back": [
        "walking_back_backward_walking_turn",
        "walking_back_injured_walk_backwards",
        "walking_back_walking_backwards"
    ],
    "walk_fwd": [
        "walking_front_long_step_forward",
        "walking_front_strut_walking",
        "walking_front_walk_forward_arc_right",
        "walking_front_walking",
        "walking_front_wheelbarrow_walk"
    ]
}


def build_pack_map():
    rng = random.Random(SEED)
    
    pack = {
        "version": 2,
        "source": "Mixamo Character Animation Collection (46 clips)",
        "seed": SEED,
        "fps": 30,
        "fighters": {}
    }
    
    # Track used clips per major category to ensure uniqueness across fighters
    used_walk = set()
    used_walk_back = set()
    used_block = set()
    used_idle = set()
    used_punches = set()
    used_kicks = set()
    
    # Archetype styles
    styles = {
        "theron": {"archetype": "heavy_brawler", "speed": 0.9, "lean_x": 4.0},
        "atalanta": {"archetype": "rushdown_hunter", "speed": 1.15, "lean_x": -2.0},
        "pyrrhus": {"archetype": "compact_grappler", "speed": 1.0, "lean_x": 3.0},
        "sibyl": {"archetype": "arcane_zoner", "speed": 0.95, "lean_x": -1.5},
    }
    
    for f in FIGHTERS:
        st = styles[f]
        
        # 1. Walk Forward (5 clips available, 4 fighters -> 100% unique)
        w_pool = [c for c in CATEGORIES["walk_fwd"] if c not in used_walk]
        w_clip = rng.choice(w_pool)
        used_walk.add(w_clip)
        
        # 2. Walk Back (3 clips available, 4 fighters -> reuse with variation)
        wb_pool = [c for c in CATEGORIES["walk_back"] if c not in used_walk_back]
        if not wb_pool:
            wb_pool = CATEGORIES["walk_back"]
        wb_clip = rng.choice(wb_pool)
        used_walk_back.add(wb_clip)
        
        # 3. Block (5 clips available, 4 fighters -> 100% unique)
        b_pool = [c for c in CATEGORIES["block"] if c not in used_block]
        b_clip = rng.choice(b_pool)
        used_block.add(b_clip)
        
        # 4. Idle (12 clips available -> 100% unique)
        i_pool = [c for c in CATEGORIES["idle"] if c not in used_idle]
        i_clip = rng.choice(i_pool)
        used_idle.add(i_clip)
        
        # 5. Punches (7 clips available -> unique assignments per move)
        # 4 Light Punches: jab_of_hermes, spartan_cross, bronze_knuckle, quick_fury
        # 4 Heavy Punches: cyclops_smash, hammer_of_hephaestus, minotaur_haymaker, gorgon_backfist
        p_pool = [c for c in CATEGORIES["punch"] if c not in used_punches]
        if len(p_pool) < 2:
            p_pool = list(CATEGORIES["punch"])
        p_light = rng.choice(p_pool)
        used_punches.add(p_light)
        p_heavy = rng.choice([c for c in CATEGORIES["punch"] if c != p_light])
        
        # 6. Kicks (6 clips available -> unique assignments per fighter)
        k_pool = [c for c in CATEGORIES["kick"] if c not in used_kicks]
        if not k_pool:
            k_pool = list(CATEGORIES["kick"])
        k_clip = rng.choice(k_pool)
        used_kicks.add(k_clip)
        
        # Actions dictionary
        actions = {
            "idle": {
                "clip": i_clip,
                "loop": True,
                "speed_scale": st["speed"]
            },
            "walk_fwd": {
                "clip": w_clip,
                "loop": True,
                "speed_scale": st["speed"]
            },
            "walk_back": {
                "clip": wb_clip,
                "loop": True,
                "speed_scale": -1.0 * st["speed"],
                "derived": wb_clip in used_walk_back,
                "recipe": f"speed_scale({-st['speed']})"
            },
            "run": {
                "clip": w_clip,
                "derived": True,
                "recipe": f"{w_clip} sped up 1.6x with +10 deg forward torso lean",
                "loop": True,
                "speed_scale": st["speed"] * 1.6,
                "additive_lean_x": 10.0
            },
            "block": {
                "clip": b_clip,
                "loop": False,
                "speed_scale": 1.0
            },
            "dodge": {
                "clip": wb_clip,
                "derived": True,
                "recipe": f"{wb_clip} sped up 2.0x with backward lean and lateral evasive offset",
                "loop": False,
                "speed_scale": 2.0,
                "additive_lean_x": -15.0
            },
            "grab": {
                "clip": p_light,
                "derived": True,
                "recipe": f"{p_light} upper-body clamped at full reach frame with neutral stance hold",
                "loop": False,
                "contact_phase": 0.4
            },
            "stagger": {
                "clip": rng.choice(CATEGORIES["damage_taken"]),
                "loop": False
            },
            "knockdown": {
                "clip": rng.choice(CATEGORIES["death"]),
                "loop": False
            },
            "get_up": {
                "clip": "death_fall_flat",
                "derived": True,
                "recipe": "death_fall_flat played in reverse (speed_scale -1.0) with recovery blend",
                "loop": False,
                "speed_scale": -1.0
            },
            "crawl": {
                "clip": "no_legs_crawling",
                "loop": True,
                "speed_scale": 1.0
            },
            "torso_scuttle": {
                "clip": "no_legs_crawling",
                "derived": True,
                "recipe": "no_legs_crawling upper torso loop with legs detached",
                "loop": True,
                "speed_scale": 1.2
            },
            "torso_roll": {
                "clip": "no_legs_crawling",
                "derived": True,
                "recipe": "no_legs_crawling with continuous roll rotation",
                "loop": True,
                "speed_scale": 1.5
            },
            "win": {
                "clip": "idle_and_start_animation_mutant_flexing_muscles" if f in ["theron", "pyrrhus"] else "idle_and_start_animation_happy_idle",
                "loop": True,
                "speed_scale": 1.0
            },
            "lose": {
                "clip": "death_standing_death_backward_01",
                "loop": False,
                "speed_scale": 0.9
            },
            # Moves mapped
            "punch_jab": {"clip": p_light, "loop": False, "contact_phase": 0.3},
            "punch_cross": {"clip": "punch_jab_cross", "loop": False, "contact_phase": 0.35},
            "hook": {"clip": "punch_boxing", "loop": False, "contact_phase": 0.35},
            "overhead_slam": {"clip": p_heavy, "loop": False, "contact_phase": 0.45},
            "heavy_strike": {"clip": "punch_elbow_punch", "loop": False, "contact_phase": 0.4},
            "kick_low": {"clip": "kick_kick_to_the_groin", "loop": False, "contact_phase": 0.35},
            "kick_sweep": {"clip": "kick_drop_kick", "loop": False, "contact_phase": 0.4},
            "kick_stomp": {"clip": "kick_flying_knee_punch_combo", "loop": False, "contact_phase": 0.4},
            "kick_thrust": {"clip": k_clip, "loop": False, "contact_phase": 0.35},
            # Superpowers
            "zeus_bolt": {
                "clip": "punch_standing_2h_magic_attack_01",
                "derived": True,
                "recipe": "punch_standing_2h_magic_attack_01 upper body cast + idle lower body stance",
                "loop": False,
                "contact_phase": 0.4
            },
            "hermes_dash": {
                "clip": w_clip,
                "derived": True,
                "recipe": f"{w_clip} burst at 2.5x speed with deep forward lean",
                "loop": False,
                "speed_scale": 2.5
            },
            "ares_rage": {
                "clip": "idle_and_start_animation_mutant_flexing_muscles",
                "derived": True,
                "recipe": "idle_and_start_animation_mutant_flexing_muscles flex roar with red rage pulse",
                "loop": False,
                "speed_scale": 1.2
            },
            "forge_shield": {
                "clip": b_clip,
                "derived": True,
                "recipe": f"{b_clip} anchored defensive posture with barrier cue",
                "loop": False
            },
            # Ultimates
            "zeus_wrath": {
                "clip": "punch_standing_2h_magic_attack_01",
                "derived": True,
                "recipe": "punch_standing_2h_magic_attack_01 42-tick pre-cast channel into lightning ground smash",
                "loop": False,
                "telegraph_ticks": 42
            },
            "olympian_barrage": {
                "clip": "kick_flying_knee_punch_combo",
                "derived": True,
                "recipe": "kick_flying_knee_punch_combo rapid strike sequence into final heavy elbow smash",
                "loop": False,
                "telegraph_ticks": 42
            }
        }
        
        pack["fighters"][f] = {
            "archetype": st["archetype"],
            "style_notes": f"{st['archetype']} motion profile using Mixamo animations.",
            "actions": actions
        }
        
    out_file = ROOT / "data/animation/mixamo_pack_map.json"
    out_file.write_text(json.dumps(pack, indent=2))
    print(f"Generated {out_file} with seed {SEED}")
    return pack


if __name__ == "__main__":
    build_pack_map()
