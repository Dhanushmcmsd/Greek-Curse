class_name SimBodyState
extends RefCounted


static func derive(limbs: SimLimbs) -> Dictionary:
	var arms := 0
	var legs := 0
	var mask := 0
	for i in SimLimbs.LIMB_NAMES.size():
		var slot: String = SimLimbs.LIMB_NAMES[i]
		if limbs.parts[slot].state == "severed":
			mask |= 1 << i
			if i < 2:
				arms += 1
			else:
				legs += 1
	# Attached fractured legs cannot support a standing fighter either.
	var unsupported_legs := int(not limbs.usable("leg_l")) + int(not limbs.usable("leg_r"))
	var unsupported_arms := int(not limbs.usable("arm_l")) + int(not limbs.usable("arm_r"))
	var profile := "full"
	if unsupported_legs == 1:
		profile = "one_leg"
	elif unsupported_legs == 2 and unsupported_arms > 0:
		profile = "torso_mode"
	elif unsupported_legs == 2:
		profile = "no_legs"
	elif arms == 2:
		profile = "no_arms"
	elif arms == 1:
		profile = "one_arm"
	return {"profile": profile, "missing_arms": arms, "missing_legs": legs, "mask": mask}


static func movement(fighter: SimFighter, rules: Dictionary) -> Dictionary:
	return rules[derive(fighter.limbs)["profile"]]


static func apply_mask(fighter: SimFighter, mask: int) -> void:
	for i in 4:
		var slot: String = SimLimbs.LIMB_NAMES[i]
		var limb: SimLimb = fighter.limbs.parts[slot]
		limb.state = "severed" if mask & (1 << i) else "healthy"
		limb.integrity = 0 if limb.state == "severed" else limb.max_integrity
		fighter.limbs.integrity[slot] = limb.integrity
