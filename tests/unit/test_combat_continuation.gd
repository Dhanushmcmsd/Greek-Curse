extends TestBase


func test_directional_commands_mirror_with_facing() -> void:
	var world := MatchLauncher.make_world(MatchConfig.new())
	var fighter := world.fighters[0]
	for facing in [-1, 1]:
		fighter.facing = facing
		var forward := SimInput.RIGHT if facing == 1 else SimInput.LEFT
		var back := SimInput.LEFT if facing == 1 else SimInput.RIGHT
		for pair in [
			[forward | SimInput.KICK_RIGHT, "muay_thai_flurry"],
			[forward | SimInput.HEAVY, "thunder_elbow_strike"],
			[back | SimInput.LIGHT, "phantom_flurry"],
			[back | SimInput.HEAVY, "phantom_ambush"]
		]:
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
			"titan_combo_kick"
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
