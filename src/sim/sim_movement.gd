class_name SimMovement
extends RefCounted
## Walk, dodge, cancel, and the vertical fall back to the floor.


static func advance(world: SimWorld, fighter: SimFighter, mask: int) -> void:
	_slide_from_impact(world, fighter)
	var profile := SimBodyState.movement(fighter, world.body_rules)
	fighter.pose = str(profile["pose"])
	if fighter.pose == "standing" and mask & SimInput.DOWN:
		fighter.pose = "crouch"
	if fighter.cooldown_ticks > 0 and fighter.state != SimFighter.State.DODGE:
		fighter.cooldown_ticks -= 1
	if fighter.attack_rearm_ticks > 0:
		fighter.attack_rearm_ticks -= 1
	fighter.blocking = false
	if fighter.state == SimFighter.State.KO:
		return
	if _counting_down(fighter):
		_tick_down(fighter)
		_gravity(world, fighter)
		return
	if fighter.state == SimFighter.State.DODGE:
		_dodge_motion(world, fighter, mask)
		return
	if _busy(fighter):
		if (
			fighter.limbs.parts.has(fighter.attack_slot)
			and not fighter.limbs.usable(fighter.attack_slot)
		):
			fighter.clear_move()
			fighter.hit_w = 0
			fighter.hit_h = 0
			fighter.state = SimFighter.State.IDLE
			return
		if _try_throw_kara(world, fighter, mask):
			_gravity(world, fighter)
			return
		if not _try_cancel(world, fighter, mask):
			_age_move(world, fighter)
			if not fighter.landed_hit:
				fighter.x += fighter.facing * fighter.attack_hop
		_gravity(world, fighter)
		return
	_move_or_block(world, fighter, mask)
	_try_start(world, fighter, mask)
	if _busy(fighter):
		fighter.x += fighter.facing * fighter.attack_hop
	_gravity(world, fighter)


static func _counting_down(fighter: SimFighter) -> bool:
	return (
		fighter.state == SimFighter.State.HITSTUN
		or fighter.state == SimFighter.State.STAGGER
		or fighter.state == SimFighter.State.BLOCKSTUN
		or fighter.state == SimFighter.State.GRAB
		or fighter.state == SimFighter.State.GRABBED
	)


static func _tick_down(fighter: SimFighter) -> void:
	fighter.state_tick -= 1
	if fighter.state_tick <= 0 and not fighter.launched:
		fighter.state = SimFighter.State.IDLE
		fighter.state_tick = 0


static func _busy(fighter: SimFighter) -> bool:
	return (
		fighter.state == SimFighter.State.STARTUP
		or fighter.state == SimFighter.State.ACTIVE
		or fighter.state == SimFighter.State.RECOVERY
	)


static func _age_move(world: SimWorld, fighter: SimFighter) -> void:
	var startup := fighter.startup_ticks
	var active_end := startup + fighter.active_ticks
	var total := active_end + fighter.recovery_ticks
	if fighter.move_age < startup:
		fighter.state = SimFighter.State.STARTUP
	elif fighter.move_age < active_end:
		fighter.state = SimFighter.State.ACTIVE
	elif fighter.move_age < total:
		fighter.state = SimFighter.State.RECOVERY
	else:
		var stagger := SimRegrown.whiff(world, fighter)
		fighter.state = SimFighter.State.STAGGER if stagger > 0 else SimFighter.State.IDLE
		fighter.clear_move()
		fighter.attack_rearm_ticks = 8 if bool(world.combat.get("edge_attacks", false)) else 0
		fighter.state_tick = stagger
		return
	fighter.state_tick = fighter.move_age
	fighter.move_age += 1


static func _move_or_block(world: SimWorld, fighter: SimFighter, mask: int) -> void:
	if _edge(world, fighter, SimInput.DODGE) and fighter.cooldown_ticks <= 0:
		return
	if (
		SimInput.has_bit(mask, SimInput.BLOCK)
		and not _attack_level(mask)
		and fighter.limbs.can_block()
	):
		fighter.blocking = true
		fighter.state = SimFighter.State.IDLE
		SimStamina.try_spend(fighter, int(world.combat["block_stamina_per_tick"]), world.combat)
		return
	var direction := 0
	if SimInput.has_bit(mask, SimInput.LEFT):
		direction -= 1
	if SimInput.has_bit(mask, SimInput.RIGHT):
		direction += 1
	if direction == 0:
		fighter.state = SimFighter.State.IDLE
		return
	fighter.state = SimFighter.State.WALK
	var speed := Fx.percent(fighter.walk_speed, SimModifier.percent_for(fighter, world.tick, true))
	speed = Fx.percent(speed, SimAbilities.speed(fighter, world.max_health))
	fighter.x += (
		direction
		* Fx.percent(speed, int(SimBodyState.movement(fighter, world.body_rules)["speed_percent"]))
	)


static func _attack_level(mask: int) -> bool:
	return (
		SimInput.has_bit(mask, SimInput.LIGHT)
		or SimInput.has_bit(mask, SimInput.HEAVY)
		or SimInput.has_bit(mask, SimInput.KICK | SimInput.KICK_RIGHT | SimInput.BODY)
	)


static func _try_start(world: SimWorld, fighter: SimFighter, mask: int) -> void:
	if fighter.state == SimFighter.State.STAGGER or fighter.attack_rearm_ticks > 0:
		return
	if _edge(world, fighter, SimInput.DODGE) and fighter.cooldown_ticks <= 0:
		if SimStamina.try_spend(fighter, int(world.combat["dodge_cost"]), world.combat):
			fighter.buffer.consume(SimInput.DODGE)
			fighter.state = SimFighter.State.DODGE
			fighter.state_tick = 0
			_dodge_motion(world, fighter, mask)
		return
	if mask & (SimInput.SUPER | SimInput.ULTIMATE):
		var ability := SimMoveAvailability.select(fighter, mask, world.body_rules)
		if not ability.is_empty():
			_begin_named(world, fighter, ability["id"], ability["slot"])
			return
	var chosen := _chosen_move(world, fighter, mask, true)
	if chosen.is_empty():
		return
	_begin_named(world, fighter, chosen["id"], chosen["slot"], bool(chosen.get("ex", false)))


static func _try_throw_kara(world: SimWorld, fighter: SimFighter, mask: int) -> bool:
	if fighter.state != SimFighter.State.STARTUP or fighter.move_age > 3:
		return false
	if fighter.attack_is_grab:
		return false
	var chosen := _chosen_move(world, fighter, mask, true)
	if chosen.is_empty():
		return false
	var row := _move_row(world, str(chosen["id"]))
	if row.is_empty() or not bool(row.get("is_grab", false)):
		return false
	return _begin_named(world, fighter, chosen["id"], chosen["slot"], false)


static func _try_cancel(world: SimWorld, fighter: SimFighter, mask: int = 0) -> bool:
	if fighter.pose == "hop" and fighter.attack_slot.begins_with("leg"):
		return false
	if (
		bool(world.combat.get("edge_attacks", false))
		and (not fighter.landed_hit or fighter.hits_done < fighter.attack_hit_count)
	):
		return false
	if not fighter.attack_can_cancel:
		return false
	if fighter.move_age < fighter.cancel_start or fighter.move_age >= fighter.cancel_end:
		return false
	# If an arm is missing/severed, disable associated two-handed move cancels
	var has_both_arms := fighter.limbs.usable("arm_l") and fighter.limbs.usable("arm_r")
	var chosen := _chosen_move(world, fighter, mask, false)
	chosen = _resolve_cancel(world, fighter, chosen, mask)
	if chosen.is_empty():
		return false
	if (
		not fighter.cancel_into.has(chosen["id"])
		and not fighter.ex_cancel_into.has(chosen["id"])
	):
		return false
	if not has_both_arms:
		var target_move_id: String = chosen["id"]
		if (
			target_move_id
			in ["olympian_barrage", "olympian_crusher", "grab", "hephaestus_forge_shield"]
		):
			return false
	return _begin_named(
		world, fighter, chosen["id"], chosen["slot"], bool(chosen.get("ex", false))
	)


static func _resolve_cancel(
	world: SimWorld, fighter: SimFighter, chosen: Dictionary, mask: int
) -> Dictionary:
	var wants_ex := bool(mask & SimInput.SUPER) or bool(chosen.get("ex", false))
	if wants_ex:
		var special := str(chosen.get("id", ""))
		if not SimMoveAvailability.is_ex_special(special):
			special = _first_listed_special(world, fighter)
		if special != "" and (
			fighter.ex_cancel_into.has(special)
			or fighter.cancel_into.has(special)
			or SimMoveAvailability.is_ex_special(special)
		):
			var slot := str(chosen.get("slot", fighter.attack_slot))
			var row := _move_row(world, special)
			if not row.is_empty():
				slot = str(row.get("limb_side", slot))
			return {"id": special, "slot": slot, "ex": true}
	if chosen.is_empty():
		return {}
	if fighter.cancel_into.has(chosen["id"]):
		return chosen
	var follow := _string_followup(world, fighter, str(chosen["id"]))
	if follow == "":
		return {}
	var follow_row := _move_row(world, follow)
	return {
		"id": follow,
		"slot": str(follow_row.get("limb_side", chosen.get("slot", fighter.attack_slot))),
		"ex": false
	}


static func _first_listed_special(world: SimWorld, fighter: SimFighter) -> String:
	var pool: Array[String] = fighter.ex_cancel_into.duplicate()
	for entry in fighter.cancel_into:
		if entry not in pool:
			pool.append(entry)
	for move_id in pool:
		var row := _move_row(world, move_id)
		if str(row.get("category", "")) == "special":
			return move_id
	return ""


static func _string_followup(world: SimWorld, fighter: SimFighter, chosen_id: String) -> String:
	var chosen_row := _move_row(world, chosen_id)
	var chosen_cat := str(chosen_row.get("category", ""))
	if chosen_cat == "":
		return ""
	for move_id in fighter.cancel_into:
		var row := _move_row(world, move_id)
		if str(row.get("category", "")) == chosen_cat:
			return move_id
	return ""


static func _move_row(world: SimWorld, move_id: String) -> Dictionary:
	for move in world.moves:
		if str(move["id"]) == move_id:
			return move
	return {}


static func _chosen_move(
	world: SimWorld, fighter: SimFighter, mask: int, allow_level: bool
) -> Dictionary:
	var effective := mask & (SimInput.LEFT | SimInput.RIGHT | SimInput.DOWN | SimInput.SUPER)
	for bit in SimInput.ATTACK_BITS:
		if _wants(world, fighter, bit, mask, allow_level):
			effective |= bit
			if not allow_level or not mask & bit:
				effective |= fighter.buffer.direction_for(bit)
	# Throw chord: a held punch/kick plus a partner edge counts as both buttons.
	if SimInput.has_bit(mask, SimInput.LIGHT) and (
		_wants(world, fighter, SimInput.KICK, mask, allow_level)
		or SimInput.has_bit(mask, SimInput.KICK)
	):
		effective |= SimInput.LIGHT | SimInput.KICK
	if SimInput.has_bit(mask, SimInput.KICK) and (
		_wants(world, fighter, SimInput.LIGHT, mask, allow_level)
		or SimInput.has_bit(mask, SimInput.LIGHT)
	):
		effective |= SimInput.LIGHT | SimInput.KICK
	var chosen := SimMoveAvailability.select(fighter, effective, world.body_rules)
	if chosen.is_empty():
		return chosen
	for move in world.moves:
		if move["id"] == chosen["id"]:
			return chosen
	# Minimal replay/test catalogs can omit advanced directional moves.
	return SimMoveAvailability.select(
		fighter, effective & ~(SimInput.LEFT | SimInput.RIGHT | SimInput.DOWN), world.body_rules
	)


static func _wants(
	world: SimWorld, fighter: SimFighter, bit: int, mask: int, allow_level: bool
) -> bool:
	if (
		allow_level
		and not bool(world.combat.get("edge_attacks", false))
		and SimInput.has_bit(mask, bit)
	):
		return true
	return _edge(world, fighter, bit)


static func _edge(world: SimWorld, fighter: SimFighter, bit: int) -> bool:
	return fighter.buffer.has_edge(bit, world.tick, int(world.combat["input_buffer_ticks"]))


static func _begin_named(
	world: SimWorld, fighter: SimFighter, move_id: String, slot: String, as_ex: bool = false
) -> bool:
	var found := -1
	for index in world.moves.size():
		if str(world.moves[index]["id"]) == move_id:
			found = index
			break
	if found < 0:
		return false
	var move: Dictionary = world.moves[found]
	if not SimAbilities.ready(world, fighter, move_id):
		return false
	if fighter.limbs.parts.has(slot) and not fighter.limbs.usable(slot):
		return false
	if not SimStamina.try_spend(fighter, int(move["cost"]), world.combat):
		return false
	var scaled := Fx.percent(int(move["damage"]), fighter.power_percent)
	var scaled_limb := Fx.percent(int(move.get("limb_damage", 0)), fighter.power_percent)
	var percent := SimModifier.percent_for(fighter, world.tick)
	if fighter.limbs.parts.has(slot) and fighter.limbs.parts[slot].state == "bruised":
		percent = Fx.percent(percent, int(world.limb_rules["bruised_damage_percent"]))
	if move_id == "grab" and not (fighter.limbs.usable("arm_l") and fighter.limbs.usable("arm_r")):
		percent = Fx.percent(percent, int(world.body_rules["one_arm_grab_percent"]))
	scaled = Fx.percent(scaled, percent)
	scaled_limb = Fx.percent(scaled_limb, percent)
	var ex_cost := int(world.combat.get("mk_ex_meter_cost", 33))
	var use_ex := (
		as_ex
		and fighter.meter >= ex_cost
		and (
			str(move.get("category", "")) == "special"
			or SimMoveAvailability.is_ex_special(move_id)
		)
	)
	if use_ex:
		fighter.meter -= ex_cost
		scaled = Fx.percent(scaled, 125)
		scaled_limb = Fx.percent(scaled_limb, 125)
	fighter.attack_slot = slot
	fighter.begin_move(found + 1, move, scaled, scaled_limb)
	if use_ex:
		fighter.attack_is_ex = true
		fighter.startup_ticks = maxi(1, Fx.percent(fighter.startup_ticks, 70))
		fighter.armor_hits = maxi(fighter.armor_hits, 1)
	if fighter.frenzy_maximum > 100 and move.get("category", "") != "ultimate":
		fighter.startup_ticks = maxi(
			1, fighter.startup_ticks * 100 / SimAbilities.speed(fighter, world.max_health)
		)
	SimAbilities.begin(world, fighter, move_id)
	SimRegrown.begin(fighter, move)
	_age_move(world, fighter)
	_consume_edges(fighter, move_id)

	return true


static func _consume_edges(fighter: SimFighter, _move_id: String) -> void:
	# Consume the command that started any equipped move, not just default IDs.
	for bit in SimInput.ATTACK_BITS:
		fighter.buffer.consume(bit)


static func _dodge_motion(world: SimWorld, fighter: SimFighter, mask: int) -> void:
	var direction := fighter.facing
	if SimInput.has_bit(mask, SimInput.LEFT):
		direction = -1
	elif SimInput.has_bit(mask, SimInput.RIGHT):
		direction = 1
	fighter.x += (
		direction
		* Fx.percent(
			int(world.combat["dodge_mm_per_tick"]),
			int(SimBodyState.movement(fighter, world.body_rules)["dodge_percent"])
		)
	)
	if fighter.state_tick == 0:
		for slot in ["leg_l", "leg_r"]:
			fighter.x += direction * int(SimRegrown.effects(fighter, slot).get("dash_mm", 0))
	fighter.state_tick += 1
	if fighter.state_tick >= int(world.combat["dodge_ticks"]):
		fighter.state = SimFighter.State.IDLE
		fighter.state_tick = 0
		fighter.cooldown_ticks = int(world.combat["dodge_cooldown_ticks"])
	_gravity(world, fighter)


static func _gravity(world: SimWorld, fighter: SimFighter) -> void:
	if fighter.launched and bool(world.combat.get("edge_attacks", false)):
		fighter.y += fighter.launch_velocity
		fighter.launch_velocity -= 4 + mini(fighter.juggle_hits, 4)
		if fighter.y <= world.floor_y:
			fighter.y = world.floor_y
			fighter.launched = false
			fighter.launch_velocity = 0
			fighter.juggle_hits = 0
			if fighter.state != SimFighter.State.KO:
				fighter.state = SimFighter.State.STAGGER
				fighter.state_tick = 20
				fighter.invulnerable_until = world.tick + 12
		return
	if fighter.y <= world.floor_y:
		fighter.y = world.floor_y
		return
	# Use reduced gravity scale for launched juggle combos
	var base_gravity := int(world.combat["gravity_mm_per_tick"])
	var is_airborne := fighter.y > world.floor_y
	var is_juggle := is_airborne and fighter.launched
	var launch_pct: int = int(world.combat.get("launch_gravity_percent", 72)) if is_juggle else 100
	var gravity: int = Fx.percent(base_gravity, launch_pct)
	# Progressive juggle gravity: each successive airborne hit adds juggle_gravity_per_tick
	var juggle_extra := int(world.combat.get("juggle_gravity_per_tick", 0))
	if is_juggle and fighter.juggle_hits > 1:
		gravity += juggle_extra * mini(fighter.juggle_hits - 1, 4)
	fighter.y -= gravity
	if fighter.y <= world.floor_y:
		fighter.y = world.floor_y
		fighter.launched = false
		fighter.juggle_hits = 0
		if is_juggle and fighter.state != SimFighter.State.KO:
			fighter.state = SimFighter.State.STAGGER
			fighter.state_tick = 20
		# Landing: brief invulnerability if wakeup_invuln_ticks configured
		if fighter.state in [SimFighter.State.HITSTUN, SimFighter.State.KO] and is_juggle:
			var invuln := int(world.combat.get("wakeup_invuln_ticks", 0))
			if invuln > 0:
				fighter.invulnerable_until = maxi(fighter.invulnerable_until, world.tick + invuln)


static func _slide_from_impact(world: SimWorld, fighter: SimFighter) -> void:
	if fighter.knockback_velocity == 0:
		return
	var requested := fighter.x + fighter.knockback_velocity
	fighter.x = Fx.clamp_i(requested, world._low(fighter), world._high(fighter))
	fighter.knockback_velocity = Fx.mul_div(fighter.knockback_velocity, 3, 4)
	if requested != fighter.x or absi(fighter.knockback_velocity) < 2:
		fighter.knockback_velocity = 0
