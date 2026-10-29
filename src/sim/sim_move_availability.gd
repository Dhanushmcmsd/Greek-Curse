class_name SimMoveAvailability
extends RefCounted
## Resolve buttons into a move and a side; no presentation or device access.


static func select(fighter: SimFighter, mask: int, rules: Dictionary) -> Dictionary:
	# Limb buttons never silently become a different limb/body attack.
	var profile: String = SimBodyState.derive(fighter.limbs)["profile"]
	if mask & SimInput.BODY:
		if profile == "torso_mode":
			return {"id": rules["torso_moves"]["light"], "slot": "torso"}
		return {"id": "body_headbutt", "slot": "head"}
	var light := bool(mask & SimInput.LIGHT)
	var heavy := bool(mask & SimInput.HEAVY)
	var kick := bool(mask & (SimInput.KICK | SimInput.KICK_RIGHT))
	var attacking := light or heavy or kick
	# Super/ultimate only when no attack button is held so EX specials can use SUPER.
	if not attacking:
		for option in [[SimInput.ULTIMATE, "ultimate"], [SimInput.SUPER, "superpower"]]:
			if mask & int(option[0]) and not fighter.loadout.get(option[1], []).is_empty():
				return {"id": fighter.loadout[option[1]][0], "slot": "body"}
		return {}
	var category := "light" if light else ("heavy" if heavy else "kick")
	var right := heavy if category != "kick" else bool(mask & SimInput.KICK_RIGHT)
	var slot := ("leg_" if category == "kick" else "arm_") + ("r" if right else "l")
	if not fighter.limbs.usable(slot):
		return {}
	# Support MK 4-button characters (e.g. Johnny Cage)
	if fighter.fighter_id == "johnny_cage":
		var forward := bool(mask & (SimInput.RIGHT if fighter.facing > 0 else SimInput.LEFT))
		var back := bool(mask & (SimInput.LEFT if fighter.facing > 0 else SimInput.RIGHT))
		var down := bool(mask & SimInput.DOWN)
		var chosen := {}
		if light and kick and not down and fighter.limbs.usable("arm_r"):
			chosen = {"id": "mk_jc_throw_forward", "slot": "torso"}
		elif down and back and light:
			chosen = {"id": "mk_jc_nut_punch", "slot": "torso"}
		elif forward and not down and (kick or bool(mask & SimInput.KICK_RIGHT)):
			chosen = {"id": "mk_jc_shadow_kick", "slot": "leg_r"}
		elif down and back and kick:
			chosen = {"id": "mk_jc_rising_elbow", "slot": "arm_r"}
		elif down and forward and heavy:
			chosen = {"id": "mk_jc_sunglasses_toss", "slot": "head"}
		elif down:
			if light:
				chosen = {"id": "mk_jc_duck_front_punch_1", "slot": "arm_l"}
			elif heavy:
				chosen = {"id": "mk_jc_duck_back_punch_1", "slot": "arm_r"}
			elif kick:
				chosen = {"id": "mk_jc_duck_front_kick_1", "slot": "leg_l"}
			elif bool(mask & SimInput.KICK_RIGHT):
				chosen = {"id": "mk_jc_duck_back_kick_1", "slot": "leg_r"}
		elif light:
			chosen = {"id": "mk_jc_front_punch_1", "slot": "arm_l"}
		elif heavy:
			chosen = {"id": "mk_jc_back_punch_1", "slot": "arm_r"}
		elif kick:
			chosen = {"id": "mk_jc_front_kick_1", "slot": "leg_l"}
		elif bool(mask & SimInput.KICK_RIGHT):
			chosen = {"id": "mk_jc_back_kick_1", "slot": "leg_r"}
		if not chosen.is_empty():
			chosen["ex"] = _wants_ex(fighter, mask, str(chosen["id"]))
			return chosen
	if light and kick and fighter.limbs.usable("arm_r"):
		return {"id": "grab", "slot": slot}

	var command := command_move(fighter.facing, mask)
	if command != "":
		var command_id: String = fighter.moveset_aliases.get(command, command)
		return {
			"id": command_id,
			"slot": "arm_l" if command == "olympian_crusher" else slot,
			"ex": _wants_ex(fighter, mask, command_id)
		}
	var selected: Array = fighter.loadout.get(category, [])
	var id: String = (
		rules["default_moves"][category]
		if selected.is_empty()
		else selected[mini(int(right), selected.size() - 1)]
	)
	var resolved: String = fighter.moveset_aliases.get(id, id)
	return {"id": resolved, "slot": slot, "ex": _wants_ex(fighter, mask, resolved)}


static func is_ex_special(move_id: String) -> bool:
	return (
		move_id.begins_with("mk_jc_")
		and (
			move_id.contains("nut_punch")
			or move_id.contains("shadow_kick")
			or move_id.contains("rising_elbow")
			or move_id.contains("sunglasses")
		)
	)


static func _wants_ex(_fighter: SimFighter, mask: int, move_id: String) -> bool:
	if (mask & SimInput.SUPER) == 0:
		return false
	return is_ex_special(move_id)


static func command_move(facing: int, mask: int) -> String:
	var forward := bool(mask & (SimInput.RIGHT if facing > 0 else SimInput.LEFT))
	var back := bool(mask & (SimInput.LEFT if facing > 0 else SimInput.RIGHT))
	if mask & SimInput.DOWN:
		if mask & SimInput.KICK and not mask & SimInput.KICK_RIGHT:
			return "hoplite_sweep_chain"
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
		if mask & SimInput.KICK and not mask & SimInput.KICK_RIGHT:
			return "olympian_heel_chain"
		if mask & SimInput.LIGHT:
			return "phantom_flurry"
		if mask & SimInput.HEAVY:
			return "phantom_ambush"
		if mask & SimInput.KICK_RIGHT:
			return "titan_combo_kick"
	return ""
