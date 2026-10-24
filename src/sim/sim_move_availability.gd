class_name SimMoveAvailability
extends RefCounted
## Resolve buttons into a move and a side; no presentation or device access.


static func select(fighter: SimFighter, mask: int, rules: Dictionary) -> Dictionary:
	for option in [[SimInput.ULTIMATE, "ultimate"], [SimInput.SUPER, "superpower"]]:
		if mask & int(option[0]) and not fighter.loadout.get(option[1], []).is_empty():
			return {"id": fighter.loadout[option[1]][0], "slot": "body"}
	var light := SimInput.has_bit(mask, SimInput.LIGHT)
	var heavy := SimInput.has_bit(mask, SimInput.HEAVY)
	var kick := SimInput.has_bit(mask, SimInput.KICK)
	if not light and not heavy and not kick:
		return {}
	var category := "light" if light else ("heavy" if heavy else "kick")
	var profile: String = SimBodyState.derive(fighter.limbs)["profile"]
	var arms := int(fighter.limbs.usable("arm_l")) + int(fighter.limbs.usable("arm_r"))
	var legs := int(fighter.limbs.usable("leg_l")) + int(fighter.limbs.usable("leg_r"))
	if profile == "torso_mode":
		return {"id": rules["torso_moves"][category], "slot": "torso"}
	if arms == 0 and (light or heavy):
		return {"id": rules["no_arm_moves"]["grab" if light and kick else category], "slot": "head"}
	if legs == 0 and kick:
		return {
			"id": rules["no_leg_moves"]["low" if mask & SimInput.DOWN else "normal"],
			"slot": "torso"
		}
	var forward := SimInput.RIGHT if fighter.facing == 1 else SimInput.LEFT
	var side_b := bool(mask & (SimInput.DOWN if category == "kick" else forward))
	var slot := ("leg_" if category == "kick" else "arm_") + ("r" if side_b else "l")
	if not fighter.limbs.usable(slot):
		return {}
	if light and kick:
		return {"id": "grab", "slot": slot}
	if category == "kick" and legs == 1:
		return {
			"id": rules["one_leg_moves"]["low" if mask & SimInput.DOWN else "normal"], "slot": slot
		}
	var selected: Array = fighter.loadout.get(category, [])
	var id: String = (
		rules["default_moves"][category]
		if selected.is_empty()
		else selected[mini(int(side_b), selected.size() - 1)]
	)
	return {"id": id, "slot": slot}
