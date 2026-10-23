class_name SimMovement
extends RefCounted
## Walk, dodge, cancel, and the vertical fall back to the floor.


static func advance(world: SimWorld, fighter: SimFighter, mask: int) -> void:
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
		if not _try_cancel(world, fighter):
			_age_move(fighter)
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


static func _age_move(fighter: SimFighter) -> void:
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
		fighter.state = SimFighter.State.IDLE
		fighter.clear_move()
		return
	fighter.state_tick = fighter.move_age
	fighter.move_age += 1


static func _move_or_block(world: SimWorld, fighter: SimFighter, mask: int) -> void:
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
	fighter.x += (
		direction
		* Fx.percent(fighter.walk_speed, SimModifier.percent_for(fighter, world.tick, true))
	)


static func _attack_level(mask: int) -> bool:
	return (
		SimInput.has_bit(mask, SimInput.LIGHT)
		or SimInput.has_bit(mask, SimInput.HEAVY)
		or SimInput.has_bit(mask, SimInput.KICK)
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
	var move_id := _chosen_move(world, fighter, mask, true)
	if move_id == "":
		return
	_begin_named(world, fighter, move_id)


static func _try_cancel(world: SimWorld, fighter: SimFighter) -> bool:
	if not fighter.attack_can_cancel:
		return false
	if fighter.move_age < fighter.cancel_start or fighter.move_age >= fighter.cancel_end:
		return false
	var move_id := _chosen_move(world, fighter, 0, false)
	if move_id == "" or not fighter.cancel_into.has(move_id):
		return false
	_begin_named(world, fighter, move_id)
	return true


static func _chosen_move(
	world: SimWorld, fighter: SimFighter, mask: int, allow_level: bool
) -> String:
	var light := _wants(world, fighter, SimInput.LIGHT, mask, allow_level)
	var heavy := _wants(world, fighter, SimInput.HEAVY, mask, allow_level)
	var kick := _wants(world, fighter, SimInput.KICK, mask, allow_level)
	if light and kick:
		return "grab"
	if light:
		return "jab_of_hermes"
	if heavy:
		return "cyclops_smash"
	if kick:
		return "pegasus_kick"
	return ""


static func _wants(
	world: SimWorld, fighter: SimFighter, bit: int, mask: int, allow_level: bool
) -> bool:
	if allow_level and SimInput.has_bit(mask, bit):
		return true
	return _edge(world, fighter, bit)


static func _edge(world: SimWorld, fighter: SimFighter, bit: int) -> bool:
	return fighter.buffer.has_edge(bit, world.tick, int(world.combat["input_buffer_ticks"]))


static func _begin_named(world: SimWorld, fighter: SimFighter, move_id: String) -> void:
	var found := -1
	for index in world.moves.size():
		if str(world.moves[index]["id"]) == move_id:
			found = index
			break
	if found < 0:
		return
	var move: Dictionary = world.moves[found]
	var slot := "leg_l" if move_id == "pegasus_kick" else "arm_l"
	if not fighter.limbs.usable(slot):
		return
	if not SimStamina.try_spend(fighter, int(move["cost"]), world.combat):
		return
	var scaled := Fx.percent(int(move["damage"]), fighter.power_percent)
	var scaled_limb := Fx.percent(int(move.get("limb_damage", 0)), fighter.power_percent)
	var percent := SimModifier.percent_for(fighter, world.tick)
	if fighter.limbs.parts[slot].state == "bruised":
		percent = Fx.percent(percent, int(world.limb_rules["bruised_damage_percent"]))
	scaled = Fx.percent(scaled, percent)
	scaled_limb = Fx.percent(scaled_limb, percent)
	fighter.attack_slot = slot
	fighter.begin_move(found + 1, move, scaled, scaled_limb)
	_age_move(fighter)
	_consume_edges(fighter, move_id)


static func _consume_edges(fighter: SimFighter, move_id: String) -> void:
	if move_id == "jab_of_hermes":
		fighter.buffer.consume(SimInput.LIGHT)
	elif move_id == "cyclops_smash":
		fighter.buffer.consume(SimInput.HEAVY)
	elif move_id == "pegasus_kick":
		fighter.buffer.consume(SimInput.KICK)
	elif move_id == "grab":
		fighter.buffer.consume(SimInput.LIGHT)
		fighter.buffer.consume(SimInput.KICK)


static func _dodge_motion(world: SimWorld, fighter: SimFighter, mask: int) -> void:
	var direction := fighter.facing
	if SimInput.has_bit(mask, SimInput.LEFT):
		direction = -1
	elif SimInput.has_bit(mask, SimInput.RIGHT):
		direction = 1
	fighter.x += direction * int(world.combat["dodge_mm_per_tick"])
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
	fighter.y -= int(world.combat["gravity_mm_per_tick"])
	if fighter.y < world.floor_y:
		fighter.y = world.floor_y
