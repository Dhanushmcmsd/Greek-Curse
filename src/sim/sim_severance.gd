class_name SimSeverance
extends RefCounted
## All limb loss goes through this deterministic path; presentation cannot sever.


static func hit(
	world: SimWorld,
	victim: int,
	attacker: int,
	zone: String,
	amount: int,
	events: Array,
	count_hit: bool = true
) -> void:
	var fighter := world.fighters[victim]
	var rules := world.limb_rules
	var limb: SimLimb = fighter.limbs.parts.get(zone)
	var previous := "" if limb == null else limb.state
	var pending := limb != null and limb.zero_pending
	amount = SimAbilities.incoming(fighter, world.tick, amount, true)
	var applied := fighter.limbs.apply_limb_damage(zone, amount)
	if count_hit:
		fighter.chain.note(world.tick, int(rules["combo_gap_ticks"]), zone, applied, attacker)
		_emit(
			world,
			events,
			SimEvent.Kind.COMBO_EXTENDED,
			attacker,
			victim,
			{"chain_hits": fighter.chain.combo_hits, "zone": zone}
		)
	if limb == null or limb.state == "severed":
		return
	limb.refresh(rules)
	if not fighter.limbs.usable(zone) and fighter.attack_slot == zone and fighter.move_id > 0:
		fighter.clear_move()
		fighter.hit_w = 0
		fighter.hit_h = 0
		if (
			fighter.state
			in [SimFighter.State.STARTUP, SimFighter.State.ACTIVE, SimFighter.State.RECOVERY]
		):
			fighter.state = SimFighter.State.IDLE
	var live := fighter.chain.is_live(world.tick, rules)
	if limb.integrity == 0:
		if (live and previous != "healthy") or (pending and count_hit):
			if fighter.limbs.amputation_occurred or fighter.limbs.losses >= int(rules.get("limb_cap", 1)):
				if not limb.cap_blocked:
					_emit(
						world,
						events,
						SimEvent.Kind.LIMB_CAP_BLOCKED,
						attacker,
						victim,
						{"limb": zone}
					)
				limb.cap_blocked = true
			else:
				var target_limb := zone
				var best_damaged := fighter.limbs.highest_damaged_limb()
				if best_damaged != "" and fighter.limbs.parts[best_damaged].state != "severed":
					target_limb = best_damaged
				var acc_damage: int = int(fighter.limbs.limb_damage_tracker.get(target_limb, 0))
				if acc_damage >= int(rules.get("amputation_threshold", 65)) or target_limb == zone:
					_sever(world, victim, attacker, target_limb, events)
				else:
					limb.zero_pending = true
		else:
			limb.zero_pending = true
	if limb.state != previous:
		_emit(
			world,
			events,
			SimEvent.Kind.LIMB_STATE_CHANGED,
			attacker,
			victim,
			{"limb": zone, "from": previous, "to": limb.state, "integrity": limb.integrity}
		)


static func _sever(
	world: SimWorld, victim: int, attacker: int, zone: String, events: Array
) -> void:
	var fighter := world.fighters[victim]
	var limb: SimLimb = fighter.limbs.parts[zone]
	limb.state = "severed"
	fighter.limbs.remove_modifier(zone)
	limb.regrown_id = ""
	limb.zero_pending = false
	fighter.limbs.losses += 1
	fighter.limbs.amputation_occurred = true
	var credit := fighter.chain.credit_for(zone, attacker)
	var record := {
		"limb": zone,
		"attacker": credit,
		"victim": victim,
		"tick": world.tick,
		"chain_hits": fighter.chain.combo_hits
	}
	if not limb.credited:
		world.amputations.append(record)
		limb.credited = true
	_emit(
		world,
		events,
		SimEvent.Kind.LIMB_SEVERED,
		attacker,
		victim,
		{"limb": zone, "credit": record}
	)
	# Post-amputation penalty & rage compensation:
	# - Reduce movement speed by 25% if leg lost
	# - Rage damage increase of +15% to compensate
	var amputated_penalty := SimModifier.new()
	amputated_penalty.id = "amputation_status:" + zone
	amputated_penalty.expires_tick = 2147483647
	if zone.begins_with("leg"):
		amputated_penalty.speed_percent = 75
	amputated_penalty.damage_percent = 115
	fighter.modifiers.append(amputated_penalty)
	SimModifier.fury(fighter, world.tick, world.limb_rules)
	fighter.meter = mini(
		int(world.combat["meter_max"]),
		(
			fighter.meter
			+ Fx.percent(
				int(world.combat["meter_max"]), int(world.limb_rules["loss_meter_percent"])
			)
		)
	)
	_emit(
		world,
		events,
		SimEvent.Kind.DESPERATE_FURY_STARTED,
		victim,
		attacker,
		{"expires_tick": world.tick + int(world.limb_rules["fury_ticks"]), "meter": fighter.meter}
	)


static func _emit(
	world: SimWorld, events: Array, kind: int, actor: int, victim: int, payload: Dictionary
) -> void:
	var event := SimEvent.make(kind, actor, victim, 0, world.round_index, -1)
	event.payload = payload
	event.payload["tick"] = world.tick
	events.append(event)
