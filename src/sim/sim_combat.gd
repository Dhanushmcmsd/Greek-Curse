class_name SimCombat
extends RefCounted
## Hit resolution: one zone, block, grab, meter, combo, and hit-stop.


static func resolve(world: SimWorld, events: Array) -> void:
	for attacker_index in world.fighters.size():
		var attacker: SimFighter = world.fighters[attacker_index]
		if attacker.state != SimFighter.State.ACTIVE or attacker.hit_w <= 0 or attacker.hit_h <= 0:
			continue
		if (
			attacker.limbs.parts.has(attacker.attack_slot)
			and not attacker.limbs.usable(attacker.attack_slot)
		):
			continue
		if attacker.hits_done >= attacker.attack_hit_count:
			continue
		if attacker.hits_done > 0 and attacker.move_age < attacker.next_hit_age:
			continue
		var defender: SimFighter = world.fighters[1 - attacker_index]
		if defender.state == SimFighter.State.KO:
			continue
		if not _window_connects(world, attacker, defender, attacker_index, events):
			continue
		_spend_hit_window(attacker)


static func _window_connects(
	world: SimWorld, attacker: SimFighter, defender: SimFighter, attacker_index: int, events: Array
) -> bool:
	var iframe_start := int(world.combat["dodge_iframe_start"])
	var iframe_end := int(world.combat["dodge_iframe_end"])
	var zone := SimHitResolver.choose_zone(
		attacker.hitbox(),
		defender.limbs.world_boxes(
			defender.x, defender.y, defender.body_width_mm, defender.height_mm, defender.pose
		),
		world.combat["zone_order"]
	)
	if zone == "":
		return false
	if (
		world.tick < defender.invulnerable_until
		or defender.in_dodge_iframe(iframe_start, iframe_end)
	):
		# An invulnerable overlap is not a hit. Keep the remaining active frames live.
		return false
	if defender.armor_hits > 0:
		defender.armor_hits -= 1
		var absorbed := SimEvent.make(
			SimEvent.Kind.BLOCK, attacker_index, 1 - attacker_index, 0, world.round_index, -1
		)
		absorbed.payload = {"zone": zone, "armored": true, "attacker_move": attacker.move_name}
		events.append(absorbed)
		return true
	_connect(world, attacker, defender, attacker_index, zone, events)
	return true


static func _spend_hit_window(attacker: SimFighter) -> void:
	attacker.hits_done += 1
	attacker.has_hit = true
	attacker.next_hit_age = attacker.move_age + attacker.attack_hit_interval


static func _connect(
	world: SimWorld,
	attacker: SimFighter,
	defender: SimFighter,
	attacker_index: int,
	zone: String,
	events: Array
) -> void:
	var split := _split(world, attacker, defender, zone)
	attacker.landed_hit = true
	var effect := SimRegrown.effects(attacker, attacker.attack_slot)
	if effect.has("squeak"):
		var quirk := SimEvent.make(
			SimEvent.Kind.LIMB_QUIRK, attacker_index, 1 - attacker_index, 0, world.round_index, -1
		)
		quirk.payload = {"quirk": "squeak", "slot": attacker.attack_slot, "tick": world.tick}
		events.append(quirk)
	var main := int(split[0])
	var limb := int(split[1])
	var blocked := bool(split[2])
	main = SimAbilities.incoming(defender, world.tick, main, false)
	if defender.shield > 0:
		var absorbed := mini(main, defender.shield)
		defender.shield -= absorbed
		main -= absorbed
		if defender.shield == 0:
			attacker.health = maxi(0, attacker.health - defender.shield_burst)
	if not blocked:
		SimAbilities.on_hit(world, attacker, defender, zone)
	defender.health -= main
	if defender.health < 0:
		defender.health = 0
	SimSeverance.hit(world, 1 - attacker_index, attacker_index, zone, limb, events)
	_fill_meter(world, attacker, Fx.percent(main, int(world.combat["meter_dealt_percent"])), events)
	_fill_meter(world, defender, Fx.percent(main, int(world.combat["meter_taken_percent"])), events)
	if attacker.attack_is_grab:
		_throw(world, attacker, defender, attacker_index, main, events)
		return
	_push(world, defender, attacker, blocked)
	if blocked:
		defender.clear_move()
		defender.state = SimFighter.State.BLOCKSTUN
		defender.state_tick = attacker.attack_blockstun
	else:
		defender.clear_move()
		defender.state = SimFighter.State.HITSTUN
		defender.state_tick = attacker.attack_hitstun
	var kind := SimEvent.Kind.BLOCK if blocked else SimEvent.Kind.HIT
	var impact := SimEvent.make(
		kind, attacker_index, 1 - attacker_index, main, world.round_index, -1
	)
	var material := "flesh"
	if defender.limbs.parts.has(zone):
		material = (
			"stone" if defender.limbs.parts[zone].regrown_id == "marble_statue_leg" else "bone"
		)
	var finisher := (
		not blocked
		and attacker.attack_hit_count > 1
		and attacker.hits_done + 1 >= attacker.attack_hit_count
	)
	var extra_stop := 2 if finisher and bool(world.combat.get("edge_attacks", false)) else 0
	impact.payload = {
		"zone": zone,
		"material": material,
		"hitstop_attacker": attacker.attack_hitstop_self + extra_stop,
		"hitstop_defender": attacker.attack_hitstop_other + extra_stop,
		"attacker_move": attacker.move_name,
		"wall_bounce": defender.wall_bounced,
		"impact_weight": 2 if finisher else (1 if attacker.attack_knockback >= 300 else 0)
	}
	events.append(impact)
	world.hitstop_remaining = maxi(world.hitstop_remaining, attacker.attack_hitstop_self)
	world.hitstop_remaining = maxi(
		world.hitstop_remaining, attacker.attack_hitstop_other + extra_stop
	)
	if defender.health <= 0:
		defender.state = SimFighter.State.KO
		defender.state_tick = 0
		var brutality_triggered := SimSeverance.check_brutality_trigger(
			world, attacker_index, 1 - attacker_index, attacker.move_name, main, events
		)
		events.append(
			SimEvent.make(
				SimEvent.Kind.KO,
				1 - attacker_index,
				attacker_index,
				0,
				world.round_index,
				attacker_index
			)
		)


static func _split(
	world: SimWorld, attacker: SimFighter, defender: SimFighter, zone: String
) -> Array:
	var main := attacker.attack_damage
	var limb := attacker.attack_limb_damage
	var scaling: Array = world.limb_rules.get("combo_damage_scaling", [100])
	if (
		not scaling.is_empty()
		and (
			world.tick - defender.chain.last_hit_tick
			<= int(world.limb_rules.get("combo_gap_ticks", 90))
		)
	):
		main = Fx.percent(main, int(scaling[mini(defender.chain.combo_hits, scaling.size() - 1)]))
	if zone == "head":
		main = Fx.percent(main, int(world.combat["head_main_percent"]))
		limb = 0
	elif zone == "torso":
		limb = 0
	else:
		main = Fx.percent(main, int(world.combat["limb_main_percent"]))
	var blocked := (
		defender.blocking and not attacker.attack_unblockable and not attacker.attack_is_grab
	)
	if blocked:
		var keep := int(world.combat["block_keep_percent"])
		if not (defender.limbs.usable("arm_l") and defender.limbs.usable("arm_r")):
			keep = int(world.body_rules["one_arm_block_keep_percent"])
		main = Fx.percent(main, keep)
		limb = Fx.percent(attacker.attack_limb_damage, 25)
	return [main, limb, blocked]


static func _throw(
	world: SimWorld,
	attacker: SimFighter,
	defender: SimFighter,
	attacker_index: int,
	main: int,
	events: Array
) -> void:
	var swap := attacker.x
	var hold := int(
		SimRegrown.effects(attacker, attacker.attack_slot).get(
			"grab_hold_ticks", world.combat["grab_ticks"]
		)
	)
	var stop := attacker.attack_hitstop_self
	attacker.x = defender.x
	defender.x = swap
	attacker.clear_move()
	defender.clear_move()
	attacker.state = SimFighter.State.GRAB
	defender.state = SimFighter.State.GRABBED
	attacker.state_tick = hold
	defender.state_tick = hold
	events.append(
		SimEvent.make(
			SimEvent.Kind.GRAB, attacker_index, 1 - attacker_index, main, world.round_index, -1
		)
	)
	world.hitstop_remaining = maxi(world.hitstop_remaining, stop)


static func _push(
	world: SimWorld, defender: SimFighter, attacker: SimFighter, blocked: bool
) -> void:
	var sign := 1 if defender.x >= attacker.x else -1
	var distance := attacker.attack_block_push if blocked else attacker.attack_knockback
	if not blocked and attacker.hits_done + 1 < attacker.attack_hit_count:
		distance = mini(distance, 45)
	var previous_x := defender.x
	var requested := Fx.percent(distance, defender.knockback_percent)
	defender.x += sign * requested
	var low := world._low(defender)
	var high := world._high(defender)
	var bounced := (
		not blocked and attacker.attack_wall_bounce and (defender.x < low or defender.x > high)
	)
	if bool(world.combat.get("edge_attacks", false)) and not blocked and not bounced:
		# Most displacement is carried as a decaying impulse after hitstop.
		# Early string contacts stay close enough for the scheduled follow-up.
		if attacker.hits_done + 1 < attacker.attack_hit_count:
			requested = mini(requested, 20)
		defender.x = previous_x + sign * (requested / 4)
		defender.knockback_velocity = sign * (requested / 4)
	elif bounced:
		defender.knockback_velocity = -sign * 35
	defender.wall_bounced = bounced
	defender.x = Fx.clamp_i(defender.x, low, high)
	# At a wall the attacker absorbs the unspent separation, preserving an escape gap.
	var unspent := maxi(0, requested - absi(defender.x - previous_x))
	if bool(world.combat.get("edge_attacks", false)) and not blocked and not bounced:
		unspent = 0
	attacker.x = Fx.clamp_i(
		attacker.x - sign * unspent, world._low(attacker), world._high(attacker)
	)
	if (
		not blocked
		and (bounced or attacker.hits_done + 1 >= attacker.attack_hit_count)
		and attacker.attack_launch_y > defender.y
	):
		if bool(world.combat.get("edge_attacks", false)):
			defender.launch_velocity = maxi(
				18, attacker.attack_launch_y / (3 + mini(defender.juggle_hits, 3))
			)
			defender.y = maxi(defender.y, world.floor_y + 1)
		else:
			defender.y = attacker.attack_launch_y
		defender.launched = true
		defender.juggle_hits += 1
	if bounced:
		defender.x = Fx.clamp_i(defender.x - sign * 160, low, high)


static func _fill_meter(world: SimWorld, fighter: SimFighter, amount: int, events: Array) -> void:
	if amount <= 0:
		return
	fighter.meter = mini(int(world.combat["meter_max"]), fighter.meter + amount)
	events.append(
		SimEvent.make(SimEvent.Kind.METER, fighter.meter, 0, amount, world.round_index, -1)
	)
