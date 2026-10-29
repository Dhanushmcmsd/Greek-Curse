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
	fighter.limbs.register_limb_hit(zone, amount, false)
	# Match damage accumulates toward the one award; attached limbs remain functional.
	if bool(rules.get("match_mode", false)) and limb != null and limb.state != "severed":
		limb.integrity = maxi(limb.integrity, (limb.max_integrity * 26 + 99) / 100)
		fighter.limbs.integrity[zone] = limb.integrity
		limb.refresh(rules)
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

	# ─── Amputation gating: exactly 1 per match, in round 2 when nearing conclusion ───
	var amputation_round: int = int(rules.get("amputation_round", 2))
	var in_amputation_window := true
	if bool(rules.get("match_mode", false)) and world.rounds_to_win >= 2:
		var round_almost_ends: bool = (
			world.round_index > amputation_round
			or (
				world.round_index == amputation_round
				and (
					world.round_tick >= Fx.percent(world.round_ticks, 80)
					or fighter.health <= Fx.percent(world.max_health, 25)
				)
			)
		)
		in_amputation_window = round_almost_ends

	if limb.integrity == 0 and not bool(rules.get("match_mode", false)):
		if (live and previous != "healthy") or (pending and count_hit):
			var cap: int = int(rules.get("limb_cap", 1))
			if (
				world.amputations.size() >= cap
				or (fighter.limbs.amputation_occurred and cap <= 1)
				or fighter.limbs.losses >= cap
			):
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
			elif not in_amputation_window:
				# Not yet in amputation round / window — leave limb cracked/pending
				limb.zero_pending = true
			else:
				var target_limb := zone
				var best_damaged := fighter.limbs.highest_damaged_limb()
				if best_damaged != "" and fighter.limbs.parts[best_damaged].state != "severed":
					target_limb = best_damaged
				var acc_damage: int = int(fighter.limbs.limb_damage_tracker.get(target_limb, 0))
				if acc_damage >= int(rules.get("amputation_threshold", 65)):
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
	if bool(world.limb_rules.get("match_mode", false)):
		if world.match_sever_awarded:
			return
		world.match_sever_awarded = true
	var fighter := world.fighters[victim]
	var limb: SimLimb = fighter.limbs.parts[zone]
	limb.state = "severed"
	limb.integrity = 0
	fighter.limbs.integrity[zone] = 0
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

	# ── Post-amputation stat penalties & rage compensation ──
	# Leg loss: -25% movement speed
	# Arm loss: disables 2-handed cancel moves (handled in sim_movement._try_cancel)
	# Rage: +15% damage to compensate (total modifier = 115%)
	var amputated_penalty := SimModifier.new()
	amputated_penalty.id = "amputation_status:" + zone
	amputated_penalty.expires_tick = 2147483647
	if zone.begins_with("leg"):
		amputated_penalty.speed_percent = int(world.limb_rules.get("leg_loss_speed_percent", 75))
	amputated_penalty.damage_percent = int(
		world.limb_rules.get("amputation_rage_bonus_percent", 115)
	)
	fighter.modifiers.append(amputated_penalty)
	SimModifier.fury(fighter, world.tick, world.limb_rules)
	for modifier in fighter.modifiers:
		if modifier.id == "desperate_fury":
			modifier.damage_percent = 100

	# Top off meter on sever — dramatic comeback fuel
	fighter.meter = mini(
		int(world.combat["meter_max"]),
		(
			fighter.meter
			+ Fx.percent(
				int(world.combat["meter_max"]), int(world.limb_rules["loss_meter_percent"])
			)
		)
	)

	# Wakeup invulnerability so the amputated player has a grace window
	var invuln_ticks: int = int(world.limb_rules.get("wake_up_recovery_ticks", 20))
	fighter.invulnerable_until = world.tick + invuln_ticks

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


static func award_round_end(world: SimWorld, winner: int, events: Array) -> void:
	if not bool(world.limb_rules.get("match_mode", false)):
		return
	if world.round_index != 2 or world.match_sever_awarded:
		return
	var victim := 1 - winner if winner >= 0 else 0
	var fighter := world.fighters[victim]
	var slot := fighter.limbs.highest_damaged_limb()
	if slot == "":
		return
	_sever(world, victim, 1 - victim, slot, events)


static func check_brutality_trigger(
	world: SimWorld,
	attacker: int,
	victim: int,
	move_id: String,
	final_hit_damage: int,
	events: Array
) -> bool:
	if world.match_sever_awarded:
		return false
	var defender := world.fighters[victim]
	if defender.health > 0:
		return false
	# Brutality triggers at match conclusion (round 2 or match-winning round)
	if world.round_index < world.rounds_to_win and world.wins[attacker] + 1 < world.rounds_to_win:
		return false

	var target_limb := ""
	var brutality_name := ""

	if move_id in ["mk_jc_nut_punch", "Specialmove_NutPunch"]:
		target_limb = "torso"
		brutality_name = "BRUTALITY_NUT_PUNCH"
	elif move_id in ["mk_jc_shadow_kick", "Specialmove_ShadowKick"]:
		target_limb = "torso"
		brutality_name = "BRUTALITY_TORSO_PUNCH_THROUGH"
	elif move_id in ["mk_jc_rising_elbow", "Specialmove_RisingElbow", "divine_uppercut"]:
		target_limb = "head"
		brutality_name = "BRUTALITY_DECAPITATION"
	elif move_id in ["mk_jc_sunglasses_toss", "Specialmove_SunglassesToss"]:
		target_limb = "head"
		brutality_name = "BRUTALITY_HEAD_EXPLODE"
	else:
		target_limb = defender.limbs.highest_damaged_limb()
		if target_limb == "":
			target_limb = "arm_l"
		brutality_name = "BRUTALITY_LIMB_SNAP"

	_sever(world, victim, attacker, target_limb, events)
	events[events.size() - 1].payload["brutality"] = brutality_name
	events[events.size() - 1].payload["slow_motion_ticks"] = 45
	return true
