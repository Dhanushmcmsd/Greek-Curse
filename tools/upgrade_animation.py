"""Upgrade animation data for reactive MK/Tekken-style combat."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# ─── 1. Update animation poses with much richer, more dynamic poses ───
p = ROOT / "data/animation/poses.json"
d = json.loads(p.read_text(encoding="utf-8"))

# Add many new reactive poses for MK/Tekken-style combat feel
new_poses = {
    # ─── FIGHTING STANCE ───
    "idle": {"bones": {
        "upper_arm.l": [-35, 0, -15], "upper_arm.r": [-35, 0, 15],
        "forearm.l": [-65, 0, 0], "forearm.r": [-65, 0, 0],
        "spine": [5, 0, 0], "head": [-5, 0, 0],
        "thigh.l": [-8, 0, 0], "shin.l": [12, 0, 0],
        "thigh.r": [-8, 0, 0], "shin.r": [12, 0, 0]
    }},
    # ─── WALK: wider arm swing, deeper strides ───
    "walk_a": {"bones": {
        "thigh.l": [32, 0, 0], "thigh.r": [-32, 0, 0],
        "shin.l": [15, 0, 0], "shin.r": [35, 0, 0],
        "upper_arm.l": [-38, 0, 0], "upper_arm.r": [28, 0, 0],
        "forearm.l": [-30, 0, 0], "forearm.r": [-20, 0, 0],
        "spine": [3, 4, 0]
    }},
    "walk_b": {"bones": {
        "shin.l": [35, 0, 0], "thigh.r": [5, 0, 0],
        "upper_arm.l": [-20, 0, 0], "upper_arm.r": [-20, 0, 0],
        "forearm.l": [-45, 0, 0], "forearm.r": [-45, 0, 0]
    }},
    "walk_c": {"bones": {
        "thigh.l": [-32, 0, 0], "thigh.r": [32, 0, 0],
        "shin.l": [35, 0, 0], "shin.r": [15, 0, 0],
        "upper_arm.l": [28, 0, 0], "upper_arm.r": [-38, 0, 0],
        "forearm.l": [-20, 0, 0], "forearm.r": [-30, 0, 0],
        "spine": [3, -4, 0]
    }},
    "walk_d": {"bones": {
        "shin.r": [35, 0, 0], "thigh.l": [5, 0, 0],
        "upper_arm.l": [-20, 0, 0], "upper_arm.r": [-20, 0, 0],
        "forearm.l": [-45, 0, 0], "forearm.r": [-45, 0, 0]
    }},
    # ─── BLOCK: arms crossed in front, bracing pose ───
    "block": {"bones": {
        "upper_arm.l": [-55, 0, -25], "upper_arm.r": [-55, 0, 25],
        "forearm.l": [-95, 0, 15], "forearm.r": [-95, 0, -15],
        "head": [15, 0, 0], "spine": [8, 0, 0],
        "thigh.l": [-10, 0, 0], "shin.l": [18, 0, 0],
        "thigh.r": [-10, 0, 0], "shin.r": [18, 0, 0]
    }},
    # ─── BLOCK IMPACT: pushed back with shield spark ───
    "block_impact": {"bones": {
        "upper_arm.l": [-45, 0, -30], "upper_arm.r": [-45, 0, 30],
        "forearm.l": [-85, 0, 20], "forearm.r": [-85, 0, -20],
        "head": [18, 0, 0], "spine": [14, 0, 0],
        "thigh.l": [-15, 0, 0], "shin.l": [25, 0, 0],
        "thigh.r": [-15, 0, 0], "shin.r": [25, 0, 0]
    }},
    # ─── HIT REACTIONS: directional, varied ───
    "hit_light": {"bones": {
        "spine": [-15, -8, 0], "head": [-18, -10, 0],
        "upper_arm.l": [25, 0, 10], "upper_arm.r": [25, 0, -10],
        "forearm.l": [-15, 0, 0], "forearm.r": [-15, 0, 0],
        "thigh.l": [-5, 0, 0], "thigh.r": [-5, 0, 0]
    }},
    "hit_heavy": {"bones": {
        "spine": [-32, -12, -8], "head": [-25, -15, -10],
        "upper_arm.l": [45, 0, 20], "upper_arm.r": [45, 0, -20],
        "forearm.l": [-5, 0, 0], "forearm.r": [-5, 0, 0],
        "thigh.l": [-12, 0, 0], "shin.l": [20, 0, 0],
        "thigh.r": [5, 0, 0]
    }},
    # ─── HIT GUT: body folds forward ───
    "hit_gut": {"bones": {
        "spine": [30, 0, 0], "head": [20, 0, 0],
        "upper_arm.l": [15, 0, 0], "upper_arm.r": [15, 0, 0],
        "forearm.l": [-40, 0, 0], "forearm.r": [-40, 0, 0],
        "thigh.l": [-20, 0, 0], "shin.l": [30, 0, 0],
        "thigh.r": [-20, 0, 0], "shin.r": [30, 0, 0]
    }},
    # ─── HIT HEAD SNAP: head whips sideways ───
    "hit_head_snap": {"bones": {
        "spine": [-8, -15, 0], "head": [-10, -35, -15],
        "upper_arm.l": [30, 0, 15], "upper_arm.r": [30, 0, -15],
        "forearm.l": [-10, 0, 0], "forearm.r": [-10, 0, 0]
    }},
    # ─── STAGGER: stumbling back ───
    "stagger": {"bones": {
        "head": [30, 10, 5], "spine": [28, 8, 0],
        "upper_arm.l": [25, 0, 20], "upper_arm.r": [25, 0, -20],
        "forearm.l": [-10, 0, 0], "forearm.r": [-10, 0, 0],
        "thigh.l": [-15, 0, 0], "shin.l": [30, 0, 0],
        "thigh.r": [5, 0, 0]
    }},
    # ─── DODGE: dynamic roll ───
    "dodge_roll": {"bones": {
        "thigh.l": [-75, 0, 0], "thigh.r": [-75, 0, 0],
        "shin.l": [95, 0, 0], "shin.r": [95, 0, 0],
        "spine": [25, 0, 0], "head": [15, 0, 0],
        "upper_arm.l": [-40, 0, -30], "upper_arm.r": [-40, 0, 30],
        "forearm.l": [-60, 0, 0], "forearm.r": [-60, 0, 0]
    }},
    # ─── KNOCKDOWN: dramatic fall ───
    "knockdown": {"bones": {
        "thigh.l": [-25, 0, 10], "thigh.r": [15, 0, -5],
        "shin.l": [15, 0, 0], "shin.r": [10, 0, 0],
        "spine": [-35, -10, 0], "head": [-20, -15, 0],
        "upper_arm.l": [50, 0, 25], "upper_arm.r": [50, 0, -25],
        "forearm.l": [10, 0, 0], "forearm.r": [10, 0, 0]
    }},
    # ─── GET UP: dramatic recovery ───
    "get_up": {"bones": {
        "thigh.l": [-65, 0, 0], "shin.l": [85, 0, 0],
        "thigh.r": [-30, 0, 0], "shin.r": [40, 0, 0],
        "spine": [30, 0, 0], "head": [-10, 0, 0],
        "upper_arm.l": [-40, 0, -15], "upper_arm.r": [20, 0, 15],
        "forearm.l": [-30, 0, 0]
    }},
    # ─── GRAB poses ───
    "grab_hold": {"bones": {
        "upper_arm.l": [-85, 0, -15], "upper_arm.r": [-85, 0, 15],
        "forearm.l": [-25, 0, 0], "forearm.r": [-25, 0, 0],
        "spine": [-10, 0, 0], "head": [-15, 0, 0],
        "thigh.l": [-12, 0, 0], "shin.l": [20, 0, 0]
    }},
    "grab_throw": {"bones": {
        "upper_arm.l": [-145, 0, -20], "upper_arm.r": [-145, 0, 20],
        "forearm.l": [-10, 0, 0], "forearm.r": [-10, 0, 0],
        "spine": [-20, 12, 0], "head": [-10, 0, 0],
        "thigh.l": [-20, 0, 0], "shin.l": [30, 0, 0]
    }},
    # ─── VICTORY: triumphant ───
    "victory": {"bones": {
        "upper_arm.l": [-155, 0, -20], "upper_arm.r": [-155, 0, 20],
        "forearm.l": [-10, 0, 0], "forearm.r": [-10, 0, 0],
        "head": [-15, 0, 0], "spine": [-5, 0, 0],
        "thigh.l": [-5, 0, 0], "shin.l": [8, 0, 0]
    }},
    # ─── DEFEAT: crumpled ───
    "defeat": {"bones": {
        "head": [38, 0, 10], "spine": [25, 5, 0],
        "upper_arm.l": [12, 0, 8], "upper_arm.r": [12, 0, -8],
        "forearm.l": [5, 0, 0], "forearm.r": [5, 0, 0],
        "thigh.l": [-25, 0, 0], "shin.l": [40, 0, 0],
        "thigh.r": [-10, 0, 0], "shin.r": [15, 0, 0]
    }},
    # ─── AMPUTATION REACTION: dramatic pain pose ───
    "sever_reaction": {"bones": {
        "spine": [-20, -15, -10], "head": [-30, -20, -15],
        "upper_arm.l": [60, 0, 30], "upper_arm.r": [60, 0, -30],
        "forearm.l": [0, 0, 0], "forearm.r": [0, 0, 0],
        "thigh.l": [-20, 0, 0], "shin.l": [30, 0, 0],
        "thigh.r": [-5, 0, 0], "shin.r": [10, 0, 0]
    }}
}

# Update poses
d["poses"].update(new_poses)

# Update settings for faster, more responsive combat
d["settings"].update({
    "walk_lean_degrees": 7,
    "breath_degrees": 3,
    "breath_rate": 2.5,
    "hitstop_shake_m": 0.012,
    "stump_twitch_degrees": 14,
    "stump_twitch_ticks": 18,
    "sever_reaction_ticks": 45,
    "sever_slowmo_ticks": 30,
    "sever_camera_zoom": 0.15,
    "block_impact_ticks": 8,
    "combo_shake_base": 0.006,
    "combo_shake_per_hit": 0.003,
    "combo_shake_max": 0.025,
    "hit_directional_blend": 0.6,
    "hit_zone_head_yaw": 35,
    "hit_zone_gut_pitch": 30,
    "hit_zone_arm_roll": 15,
    "hit_zone_leg_tilt": 20,
    "knockback_visual_speed": 0.38,
    "dodge_pitch_degrees": 220,
    "dodge_ticks": 10,
    "cape_spring": 0.22,
    "quirk_rate": 4.5
})

# Update unique per-character styles with more personality
d["styles"] = {
    "theron": {
        "cycle": 28, "stride": 1.1, "recoil": 1.2, "twist": 14,
        "idle": {
            "upper_arm.l": [-40, 0, -18], "forearm.l": [-70, 0, 0],
            "upper_arm.r": [-40, 0, 18], "forearm.r": [-70, 0, 0],
            "spine": [6, 0, 0], "head": [-8, 0, 0],
            "thigh.l": [-10, 0, 0], "shin.l": [15, 0, 0],
            "thigh.r": [-10, 0, 0], "shin.r": [15, 0, 0]
        }
    },
    "atalanta": {
        "cycle": 26, "stride": 1.3, "recoil": 0.9, "twist": 10,
        "idle": {
            "upper_arm.l": [-50, 0, -22], "forearm.l": [-55, 0, 0],
            "upper_arm.r": [-30, 0, 20], "forearm.r": [-75, 0, 0],
            "spine": [3, 0, 0], "head": [-5, 0, 0],
            "thigh.l": [-12, 0, 0], "shin.l": [18, 0, 0],
            "thigh.r": [-6, 0, 0], "shin.r": [10, 0, 0]
        }
    },
    "pyrrhus": {
        "cycle": 22, "stride": 0.85, "recoil": 1.5, "twist": 20,
        "idle": {
            "upper_arm.l": [-58, 0, -22], "forearm.l": [-88, 0, 0],
            "upper_arm.r": [-58, 0, 22], "forearm.r": [-88, 0, 0],
            "spine": [12, 0, 0], "head": [-4, 0, 0],
            "thigh.l": [-18, 0, 0], "shin.l": [25, 0, 0],
            "thigh.r": [-18, 0, 0], "shin.r": [25, 0, 0]
        }
    },
    "sibyl": {
        "cycle": 32, "stride": 0.75, "recoil": 0.8, "twist": 8,
        "idle": {
            "upper_arm.l": [-68, 0, -28], "forearm.l": [-32, 0, 0],
            "hand.l": [0, 0, -22], "upper_arm.r": [-22, 0, 28],
            "forearm.r": [-48, 0, 0], "spine": [-4, 0, 0],
            "head": [-6, 0, 0],
            "thigh.l": [-5, 0, 0], "shin.l": [8, 0, 0],
            "thigh.r": [-5, 0, 0], "shin.r": [8, 0, 0]
        }
    }
}

p.write_text(json.dumps(d, indent=2) + "\n", encoding="utf-8")

# ─── 2. Set limb_cap to 1 per round ───
limb_path = ROOT / "data/balance/limbs.json"
limb_data = json.loads(limb_path.read_text(encoding="utf-8"))
limb_data["limb_cap"] = 1
limb_path.write_text(json.dumps(limb_data, indent=2) + "\n", encoding="utf-8")

# ─── 3. Increase walk speed in all fighters ───
for fighter_file in (ROOT / "data/fighters").glob("*.json"):
    fd = json.loads(fighter_file.read_text(encoding="utf-8"))
    if "speed" in fd:
        fd["speed"] = min(fd["speed"] + 1, 5)
    fighter_file.write_text(json.dumps(fd, indent=2) + "\n", encoding="utf-8")

# ─── 4. Update combat balance for faster, snappier combat ───
combat_path = ROOT / "data/balance/combat.json"
cd = json.loads(combat_path.read_text(encoding="utf-8"))
cd["dodge_ticks"] = 10
cd["dodge_mm_per_tick"] = 50
cd["stagger_ticks"] = 15
combat_path.write_text(json.dumps(cd, indent=2) + "\n", encoding="utf-8")

print("DATA_UPDATE_OK")
