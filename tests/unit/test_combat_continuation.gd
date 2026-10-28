extends TestBase


func test_directional_commands_mirror_with_facing() -> void:
	var world := MatchLauncher.make_world(MatchConfig.new())
	var fighter := world.fighters[0]
	for facing in [-1, 1]:
		fighter.facing = facing
		var forward := SimInput.RIGHT if facing == 1 else SimInput.LEFT
		var back := SimInput.LEFT if facing == 1 else SimInput.RIGHT
		for pair in [
			[forward | SimInput.KICK_RIGHT, "theron_pursuit"],
			[forward | SimInput.HEAVY, "theron_power"],
			[back | SimInput.LIGHT, "theron_retreat"],
			[back | SimInput.HEAVY, "theron_lead"]
		]:
			fighter.stamina = 100
			var chosen := SimMoveAvailability.select(fighter, pair[0], world.body_rules)
			assert_eq(chosen.id, pair[1], "facing-relative command")
			SimMovement._begin_named(world, fighter, chosen.id, chosen.slot)
			assert_eq(fighter.move_name, pair[1], "command exists in live match")
			fighter.clear_move()


func test_one_match_sever_only_after_late_second_round() -> void:
	var world := MatchLauncher.make_world(MatchConfig.new())
	var victim := world.fighters[1]
	for hit in 4:
		SimSeverance.hit(world, 1, 0, "arm_l", 40, [])
	assert_eq(world.amputations.size(), 0, "round one protected")
	world.round_index = 2
	SimSeverance.hit(world, 1, 0, "arm_l", 1, [])
	assert_eq(world.amputations.size(), 0, "early second round protected")
	victim.health = Fx.percent(world.max_health, 25)
	SimSeverance.hit(world, 1, 0, "arm_l", 1, [])
	assert_eq(world.amputations.size(), 0, "late damage does not sever early")
	SimSeverance.award_round_end(world, 0, [])
	assert_eq(world.amputations.size(), 1, "second round end awards sever")
	assert_eq(SimModifier.percent_for(victim, world.tick), 115, "rage is exactly 15 percent")
	world._reset_bodies()
	world.round_index = 3
	for hit in 4:
		SimSeverance.hit(world, 0, 1, "leg_r", 100, [])
	assert_eq(world.amputations.size(), 1, "other fighter cannot receive second sever")


func test_launch_survives_move_clear_and_lands_into_recovery() -> void:
	var world := ProtoFixture.world_with()
	var attacker := world.fighters[0]
	var defender := world.fighters[1]
	attacker.attack_launch_y = 140
	attacker.attack_hit_count = 1
	SimCombat._push(world, defender, attacker, false)
	defender.clear_move()
	defender.state = SimFighter.State.HITSTUN
	defender.state_tick = 1
	assert_true(defender.launched, "incoming launch survives outgoing move reset")
	for tick in 100:
		SimMovement.advance(world, defender, 0)
		if not defender.launched:
			break
	assert_eq(defender.y, world.floor_y, "landed")
	assert_eq(defender.state, SimFighter.State.STAGGER, "grounded recovery")
	assert_eq(defender.state_tick, 20, "20 grounded recovery ticks")


func test_block_cannot_wall_bounce() -> void:
	var world := ProtoFixture.world_with()
	var attacker := world.fighters[0]
	var defender := world.fighters[1]
	defender.x = world._high(defender)
	attacker.x = defender.x - 400
	attacker.attack_wall_bounce = true
	attacker.attack_block_push = 100
	attacker.attack_launch_y = 140
	SimCombat._push(world, defender, attacker, true)
	assert_false(defender.wall_bounced, "blocked elbow never bounces")
	assert_false(defender.launched, "blocked elbow never launches")


func test_limb_tracker_is_hashed() -> void:
	var a := ProtoFixture.world_with()
	var b := ProtoFixture.world_with()
	b.fighters[0].limbs.register_limb_hit("arm_r", 40, true)
	assert_eq(b.fighters[0].limbs.limb_damage_tracker.arm_r, 10, "quarter block damage")
	assert_true(a.hash_state() != b.hash_state(), "future sever selection is deterministic state")


func test_knee_rush_four_contacts_cancel_into_elbow() -> void:
	var config := MatchConfig.new()
	config.loadouts = [Loadout.full(0)]
	config.rules["hazards"] = false
	var world := MatchLauncher.make_world(config)
	world.fighters[0].x = 0
	world.fighters[1].x = 430
	var fighter := world.fighters[0]
	var hits := 0
	var elbow := false
	for tick in 120:
		var mask := 0
		if tick == 0:
			mask = SimInput.RIGHT | SimInput.KICK_RIGHT
		elif fighter.move_name == "muay_thai_flurry" and fighter.move_age >= 39:
			mask = SimInput.RIGHT | SimInput.HEAVY
		var events := world.step([mask, 0])
		for event in events:
			if (
				event.kind == SimEvent.Kind.HIT
				and event.payload.get("attacker_move", "") == "muay_thai_flurry"
			):
				hits += 1
		elbow = elbow or fighter.move_name == "thunder_elbow_strike"
	assert_eq(hits, 4, "four real knee contacts")
	assert_true(elbow, "buffered directional elbow cancel starts")


func test_held_attack_does_not_restart_and_recovery_has_timer() -> void:
	var world := MatchLauncher.make_world(MatchConfig.new())
	world.hazards_enabled = false
	var fighter := world.fighters[0]
	var starts := 0
	var had_move := false
	var saw_reset := false
	for tick in 180:
		world.step([SimInput.LIGHT, 0])
		if fighter.move_id > 0 and not had_move:
			starts += 1
		had_move = fighter.move_id > 0
		saw_reset = saw_reset or fighter.attack_rearm_ticks > 0
	assert_eq(starts, 1, "held button triggers just one attack")
	assert_true(saw_reset, "8-tick reset timer after recovery")
	world.step([0, 0])
	world.step([SimInput.LIGHT, 0])
	assert_true(fighter.move_id > 0, "release and press rearms attack")


func test_round_two_award_is_global_idempotent_and_limbs_stay_usable() -> void:
	var world := MatchLauncher.make_world(MatchConfig.new())
	for victim in 2:
		for slot in SimLimbs.LIMB_NAMES:
			SimSeverance.hit(world, victim, 1 - victim, slot, 500, [])
			assert_true(
				world.fighters[victim].limbs.usable(slot), "damage does not fake missing limbs"
			)
	world.round_index = 2
	var events: Array = []
	SimSeverance.award_round_end(world, 0, events)
	SimSeverance.award_round_end(world, 1, events)
	world.round_index = 3
	SimSeverance.award_round_end(world, 1, events)
	assert_eq(world.amputations.size(), 1, "one global award even on repeated calls")
	var detached := 0
	for fighter in world.fighters:
		for limb in fighter.limbs.parts.values():
			if limb.state == "severed":
				detached += 1
	assert_eq(detached, 1, "exactly one detached limb in the entire match")


func test_ballistic_launch_rises_falls_and_recovers() -> void:
	var world := MatchLauncher.make_world(MatchConfig.new())
	var a := world.fighters[0]
	var b := world.fighters[1]
	a.attack_launch_y = 220
	a.attack_hit_count = 1
	SimCombat._push(world, b, a, false)
	b.state = SimFighter.State.HITSTUN
	b.state_tick = 20
	var peak := b.y
	for tick in 100:
		SimMovement.advance(world, b, 0)
		peak = maxi(peak, b.y)
		if not b.launched:
			break
	assert_true(peak > 300, "visible arc rather than teleport")
	assert_eq(b.y, 0, "returns to floor")
	assert_eq(b.state_tick, 20, "grounded recovery starts on landing")


func test_all_roster_combo_contacts_at_common_height() -> void:
	for opponent in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		for move in [
			"spartan_flurry",
			"muay_thai_flurry",
			"phantom_flurry",
			"lightning_jab_chain",
			"ghost_sweep_chain",
			"titan_combo_kick",
			"hoplite_sweep_chain",
			"olympian_heel_chain"
		]:
			var config := MatchConfig.new()
			config.fighter_ids.assign(["theron", opponent])
			var world := MatchLauncher.make_world(config)
			world.hazards_enabled = false
			var a := world.fighters[0]
			var b := world.fighters[1]
			a.x = -300
			b.x = 300
			b.health = 10000
			assert_eq(a.height_mm, b.height_mm, "common collision height")
			var row := {}
			for entry in world.moves:
				if entry.id == move:
					row = entry
			SimMovement._begin_named(world, a, move, str(row.limb_side))
			var contacts := 0
			for tick in 150:
				for event in world.step([0, 0]):
					if event.kind == SimEvent.Kind.HIT:
						contacts += 1
			assert_eq(contacts, int(row.get("hit_count", 1)), opponent + " " + move)


func test_active_window_survives_temporary_invulnerability() -> void:
	var world := MatchLauncher.make_world(MatchConfig.new())
	var a := world.fighters[0]
	var b := world.fighters[1]
	a.x = -225
	b.x = 225
	SimMovement._begin_named(world, a, "jab_of_hermes", "arm_l")
	a.state = SimFighter.State.ACTIVE
	b.invulnerable_until = world.tick + 1
	SimCombat.resolve(world, [])
	assert_eq(a.hits_done, 0, "invulnerability does not spend remaining active window")
	world.tick += 1
	var health := b.health
	SimCombat.resolve(world, [])
	assert_true(b.health < health, "contact lands when invulnerability ends during active frames")
	assert_eq(a.hits_done, 1, "only one hit")


func test_armor_absorption_emits_feedback_once() -> void:
	var world := MatchLauncher.make_world(MatchConfig.new())
	var a := world.fighters[0]
	var b := world.fighters[1]
	a.x = -225
	b.x = 225
	SimMovement._begin_named(world, a, "jab_of_hermes", "arm_l")
	a.state = SimFighter.State.ACTIVE
	b.armor_hits = 1
	var events: Array = []
	SimCombat.resolve(world, events)
	SimCombat.resolve(world, events)
	assert_eq(events.size(), 1, "one visible armored impact")
	assert_true(events[0].payload.armored, "armor feedback distinguished from damage")
	assert_eq(b.armor_hits, 0, "armor consumed exactly once")


func test_attacks_damage_every_opponent_in_both_directions() -> void:
	for opponent in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		for facing in [-1, 1]:
			for move in [
				"jab_of_hermes",
				"spartan_cross",
				"pegasus_kick",
				"spartan_flurry",
				"phantom_flurry",
				"lightning_jab_chain"
			]:
				var config := MatchConfig.new()
				config.fighter_ids.assign(["theron", opponent])
				var world := MatchLauncher.make_world(config)
				world.hazards_enabled = false
				var a := world.fighters[0]
				var b := world.fighters[1]
				a.x = -225 * facing
				b.x = 225 * facing
				a.facing = facing
				var row := {}
				for entry in world.moves:
					if entry.id == move:
						row = entry
				SimMovement._begin_named(world, a, move, str(row.limb_side))
				var hits := 0
				for tick in 140:
					for event in world.step([0, 0]):
						if event.kind == SimEvent.Kind.HIT:
							hits += 1
				assert_eq(
					hits,
					int(row.get("hit_count", 1)),
					opponent + " " + move + " facing=" + str(facing)
				)


func test_heavy_hit_carries_momentum_and_stops_at_wall() -> void:
	var world := MatchLauncher.make_world(MatchConfig.new())
	var a := world.fighters[0]
	var b := world.fighters[1]
	a.x = -225
	b.x = 225
	a.attack_knockback = 400
	a.attack_hit_count = 1
	SimCombat._push(world, b, a, false)
	var first := b.x
	assert_true(first < 625, "displacement is not an instant teleport")
	assert_true(b.knockback_velocity > 0, "hit carries momentum")
	for tick in 6:
		SimMovement._slide_from_impact(world, b)
	assert_true(b.x > first, "momentum continues after hitstop")
	b.x = world._high(b) - 1
	b.knockback_velocity = 100
	SimMovement._slide_from_impact(world, b)
	assert_eq(b.x, world._high(b), "wall clamps momentum")
	assert_eq(b.knockback_velocity, 0, "no repeated wall jitter")


func test_impulse_is_hashed_and_reset_between_rounds() -> void:
	var a := MatchLauncher.make_world(MatchConfig.new())
	var b := MatchLauncher.make_world(MatchConfig.new())
	b.fighters[1].knockback_velocity = 40
	assert_true(a.hash_state() != b.hash_state(), "momentum is deterministic state")
	b._reset_bodies()
	assert_eq(b.fighters[1].knockback_velocity, 0, "round reset clears momentum")


func test_new_kick_commands_and_finisher_weight() -> void:
	assert_eq(
		SimMoveAvailability.command_move(1, SimInput.DOWN | SimInput.KICK),
		"hoplite_sweep_chain",
		"low string"
	)
	assert_eq(
		SimMoveAvailability.command_move(-1, SimInput.RIGHT | SimInput.KICK),
		"olympian_heel_chain",
		"mirrored back string"
	)
	var world := MatchLauncher.make_world(MatchConfig.new())
	world.hazards_enabled = false
	world.fighters[0].x = -250
	world.fighters[1].x = 250
	SimMovement._begin_named(world, world.fighters[0], "olympian_heel_chain", "leg_l")
	var weights: Array = []
	var pauses: Array = []
	for tick in 150:
		for event in world.step([0, 0]):
			if event.kind == SimEvent.Kind.HIT:
				weights.append(event.payload.impact_weight)
				pauses.append(event.payload.hitstop_defender)
	assert_eq(weights.size(), 2, "two contacts")
	assert_eq(weights[-1], 2, "finisher drives stronger VFX")
	assert_true(pauses[-1] > pauses[0], "finisher has more hitstop")
