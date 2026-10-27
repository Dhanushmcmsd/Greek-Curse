class_name SimMovement
extends RefCounted
## Walk, dodge, cancel, and the vertical fall back to the floor.


static func advance(world: SimWorld, fighter: SimFighter, mask: int) -> void:
	var profile := SimBodyState.movement(fighter, world.body_rules)
	fighter.pose = str(profile["pose"])
	if fighter.pose == "standing" and mask & SimInput.DOWN:
		fighter.pose = "crouch"
	if fighter.cooldown_ticks > 0 and fighter.state != SimFighter.State.DODGE:
		fighter.cooldown_ticks -= 1
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
		if not _try_cancel(world, fighter):
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
	if fighter.state_tick <= 0:
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
	if fighter.state == SimFighter.State.STAGGER:
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
	_begin_named(world, fighter, chosen["id"], chosen["slot"])


static func _try_cancel(world: SimWorld, fighter: SimFighter) -> bool:
	if fighter.pose == "hop" and fighter.attack_slot.begins_with("leg"):
		return false
	if not fighter.attack_can_cancel:
		return false
	if fighter.move_age < fighter.cancel_start or fighter.move_age >= fighter.cancel_end:
		return false
	# If an arm is missing/severed, disable associated two-handed move cancels
	var has_both_arms := fighter.limbs.usable("arm_l") and fighter.limbs.usable("arm_r")
	var chosen := _chosen_move(world, fighter, 0, false)
	if chosen.is_empty() or not fighter.cancel_into.has(chosen["id"]):
		return false
	if not has_both_arms:
		var target_move_id: String = chosen["id"]
		if target_move_id in ["olympian_barrage", "grab", "hephaestus_forge_shield"]:
			return false
	_begin_named(world, fighter, chosen["id"], chosen["slot"])
	return true


static func _chosen_move(
	world: SimWorld, fighter: SimFighter, mask: int, allow_level: bool
) -> Dictionary:
	var effective := mask & (SimInput.LEFT | SimInput.RIGHT | SimInput.DOWN)
	for bit in SimInput.ATTACK_BITS:
		if _wants(world, fighter, bit, mask, allow_level):
			effective |= bit
			if not allow_level or not mask & bit:
				effective |= fighter.buffer.direction_for(bit)
	return SimMoveAvailability.select(fighter, effective, world.body_rules)


static func _wants(
	world: SimWorld, fighter: SimFighter, bit: int, mask: int, allow_level: bool
) -> bool:
	if allow_level and SimInput.has_bit(mask, bit):
		return true
	return _edge(world, fighter, bit)


static func _edge(world: SimWorld, fighter: SimFighter, bit: int) -> bool:
	return fighter.buffer.has_edge(bit, world.tick, int(world.combat["input_buffer_ticks"]))


static func _begin_named(
	world: SimWorld, fighter: SimFighter, move_id: String, slot: String
) -> void:
	var found := -1
	for index in world.moves.size():
		if str(world.moves[index]["id"]) == move_id:
			found = index
			break
	if found < 0:
		return
	var move: Dictionary = world.moves[found]
	if not SimAbilities.ready(world, fighter, move_id):
		return
	if fighter.limbs.parts.has(slot) and not fighter.limbs.usable(slot):
		return
	if not SimStamina.try_spend(fighter, int(move["cost"]), world.combat):
		return
	var scaled := Fx.percent(int(move["damage"]), fighter.power_percent)
	var scaled_limb := Fx.percent(int(move.get("limb_damage", 0)), fighter.power_percent)
	var percent := SimModifier.percent_for(fighter, world.tick)
	if fighter.limbs.parts.has(slot) and fighter.limbs.parts[slot].state == "bruised":
		percent = Fx.percent(percent, int(world.limb_rules["bruised_damage_percent"]))
	if move_id == "grab" and not (fighter.limbs.usable("arm_l") and fighter.limbs.usable("arm_r")):
		percent = Fx.percent(percent, int(world.body_rules["one_arm_grab_percent"]))
	scaled = Fx.percent(scaled, percent)
	scaled_limb = Fx.percent(scaled_limb, percent)
	fighter.attack_slot = slot
	fighter.begin_move(found + 1, move, scaled, scaled_limb)
	if fighter.frenzy_maximum > 100 and move.get("category", "") != "ultimate":
		fighter.startup_ticks = maxi(
			1, fighter.startup_ticks * 100 / SimAbilities.speed(fighter, world.max_health)
		)
	SimAbilities.begin(world, fighter, move_id)
	SimRegrown.begin(fighter, move)
	_age_move(world, fighter)
	_consume_edges(fighter, move_id)


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
	if fighter.y <= world.floor_y:
		fighter.y = world.floor_y
		return
	# Use reduced gravity scale for launched/airborne fighters to allow longer combos
	var base_gravity := int(world.combat["gravity_mm_per_tick"])
	var is_airborne := fighter.y > world.floor_y
	var launch_scale := float(world.combat.get("launch_gravity_scale", 1.0))
	var gravity := int(float(base_gravity) * launch_scale) if is_airborne else base_gravity
	# Progressive juggle gravity: each successive airborne hit adds juggle_gravity_per_tick
	var juggle_extra := int(world.combat.get("juggle_gravity_per_tick", 0))
	if is_airborne and fighter.state == SimFighter.State.HITSTUN and fighter.hits_done > 1:
		gravity += juggle_extra * mini(fighter.hits_done - 1, 4)
	fighter.y -= gravity
	if fighter.y < world.floor_y:
		fighter.y = world.floor_y
		# Landing: brief invulnerability if wakeup_invuln_ticks configured
		if fighter.state in [SimFighter.State.HITSTUN, SimFighter.State.KO]:
			var invuln := int(world.combat.get("wakeup_invuln_ticks", 0))
			if invuln > 0:
				fighter.invulnerable_until = maxi(fighter.invulnerable_until, world.tick + invuln)
