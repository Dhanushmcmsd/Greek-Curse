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
	var live := fighter.chain.is_live(world.tick, rules)
	if limb.integrity == 0:
		if (live and previous != "healthy") or (pending and count_hit):
			if fighter.limbs.losses >= int(rules["limb_cap"]):
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
				_sever(world, victim, attacker, zone, events)
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
