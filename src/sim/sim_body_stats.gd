class_name SimBodyStats
extends RefCounted


## Physical deltas are applied once around the reference body, never cosmetic fields.
static func derive(row: Dictionary, curves: Dictionary) -> Dictionary:
	var rule: Dictionary = curves["body_rules"]
	var body: Dictionary = row["body"]
	var weight := int(body["weight_kg"]) - int(rule["reference_weight"])
	var muscle := int(body["muscle"]) - int(rule["reference_muscle"])
	var speed := Fx.percent(
		int(curves["speed_mm_per_tick"][int(row["speed"])]),
		100 - weight / int(rule["weight_speed_divisor"])
	)
	return {
		"speed": maxi(8, speed),
		"power":
		(
			int(curves["power_percent"][int(row["power"])])
			+ muscle / int(rule["muscle_power_divisor"])
		),
		"reach_percent":
		Fx.percent(
			int(curves["reach_percent"][int(row["reach"])]),
			int(row["height_mm"]) * 100 / int(rule["reference_height"])
		),
		"width":
		(
			int(curves["target_width_mm"][int(row["target_size"])])
			+ maxi(0, int(row["height_mm"]) - int(rule["reference_height"])) / 10
		),
		"knockback_percent": clampi(100 - weight / int(rule["weight_knockback_divisor"]), 65, 120),
		"toughness_bonus": muscle / int(rule["muscle_toughness_divisor"])
	}


static func apply(fighter: SimFighter, stats: Dictionary) -> void:
	fighter.walk_speed = int(stats["speed"])
	fighter.power_percent = int(stats["power"])
	fighter.body_width_mm = int(stats["width"])
	fighter.reach_percent = int(stats["reach_percent"])
	fighter.knockback_percent = int(stats["knockback_percent"])
	fighter.limbs.max_integrity += int(stats["toughness_bonus"])
	for slot in SimLimbs.LIMB_NAMES:
		var limb: SimLimb = fighter.limbs.parts[slot]
		limb.max_integrity += int(stats["toughness_bonus"])
		limb.integrity = limb.max_integrity
		fighter.limbs.integrity[slot] = limb.integrity
