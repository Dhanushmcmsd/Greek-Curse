class_name SimMoveAvailability
extends RefCounted
## Resolve buttons into a move and a side; no presentation or device access.


static func select(fighter: SimFighter, mask: int, rules: Dictionary) -> Dictionary:
	for option in [[SimInput.ULTIMATE, "ultimate"], [SimInput.SUPER, "superpower"]]:
		if mask & int(option[0]) and not fighter.loadout.get(option[1], []).is_empty():
			return {"id": fighter.loadout[option[1]][0], "slot": "body"}
	# Limb buttons never silently become a different limb/body attack.
	var profile: String = SimBodyState.derive(fighter.limbs)["profile"]
	if mask & SimInput.BODY:
		if profile == "torso_mode":
			return {"id": rules["torso_moves"]["light"], "slot": "torso"}
		return {"id": "body_headbutt", "slot": "head"}
	var light := bool(mask & SimInput.LIGHT)
	var heavy := bool(mask & SimInput.HEAVY)
	var kick := bool(mask & (SimInput.KICK | SimInput.KICK_RIGHT))
	if not light and not heavy and not kick:
		return {}
	var category := "light" if light else ("heavy" if heavy else "kick")
	var right := heavy if category != "kick" else bool(mask & SimInput.KICK_RIGHT)
	var slot := ("leg_" if category == "kick" else "arm_") + ("r" if right else "l")
	if not fighter.limbs.usable(slot):
		return {}
	if light and kick and fighter.limbs.usable("arm_r"):
		return {"id": "grab", "slot": slot}
	var command := command_move(fighter.facing, mask)
	if command != "":
		return {"id": command, "slot": "arm_l" if command == "olympian_crusher" else slot}
	var selected: Array = fighter.loadout.get(category, [])
	var id: String = (
		rules["default_moves"][category]
		if selected.is_empty()
		else selected[mini(int(right), selected.size() - 1)]
	)
	return {"id": id, "slot": slot}


static func command_move(facing: int, mask: int) -> String:
	var forward := bool(mask & (SimInput.RIGHT if facing > 0 else SimInput.LEFT))
	var back := bool(mask & (SimInput.LEFT if facing > 0 else SimInput.RIGHT))
	if mask & SimInput.DOWN:
		if mask & SimInput.KICK_RIGHT:
			return "olympian_crusher"
		if mask & SimInput.LIGHT:
			return "spartan_flurry"
		if mask & SimInput.HEAVY:
			return "divine_uppercut"
	if forward:
		if mask & SimInput.LIGHT:
			return "lightning_jab_chain"
		if mask & SimInput.HEAVY:
			return "thunder_elbow_strike"
		if mask & SimInput.KICK_RIGHT:
			return "muay_thai_flurry"
		if mask & SimInput.KICK:
			return "ghost_sweep_chain"
	if back:
		if mask & SimInput.LIGHT:
			return "phantom_flurry"
		if mask & SimInput.HEAVY:
			return "phantom_ambush"
		if mask & SimInput.KICK_RIGHT:
			return "titan_combo_kick"
	return ""
