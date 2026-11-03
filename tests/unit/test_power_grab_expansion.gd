extends TestBase

func test_landed_hits_charge_power_and_input_spends_it_once() -> void:
	var config := MatchConfig.new()
	config.rules["hazards"] = false
	var world := MatchLauncher.make_world(config)
	var a := world.fighters[0]
	var b := world.fighters[1]
	assert_false(SimAbilities.ready(world, a, SimAbilities.super_id(a)), "empty power unavailable")
	for strike in 8:
		a.stamina = 100
		a.clear_move()
		a.state = SimFighter.State.IDLE
		SimMovement._begin_named(world, a, "jab_of_hermes", "arm_l")
		SimCombat._connect(world, a, b, 0, "torso", [])
		world.tick += 10
	assert_eq(a.super_charge, 100, "landed offense fills and caps power")
	a.clear_move()
	a.state = SimFighter.State.IDLE
	a.stamina = 100
	world.hitstop_remaining = 0
	var power := SimAbilities.super_id(a)
	world.step([SimInput.SUPER, 0])
	assert_eq(a.move_name, power, "U input starts the power")
	assert_eq(a.super_charge, 0, "charge spent")
	assert_eq(a.ability_uses.get(power, 0), 1, "activation event exactly once")
	for tick in 60:
		world.step([SimInput.SUPER, 0])
	assert_eq(a.ability_uses.get(power, 0), 1, "holding key cannot repeat activation")


func test_whiffs_and_blocks_do_not_charge_super() -> void:
	var world := MatchLauncher.make_world(MatchConfig.new())
	var a := world.fighters[0]
	var b := world.fighters[1]
	SimMovement._begin_named(world, a, "jab_of_hermes", "arm_l")
	assert_eq(a.super_charge, 0, "starting/whiffing does not grant power")
	b.blocking = true
	SimCombat._connect(world, a, b, 0, "torso", [])
	assert_eq(a.super_charge, 0, "blocked strike does not grant power")
	assert_eq(a.confirmed_hits, 0, "blocked strike is not a confirmed hit")


func test_career_has_native_power_and_new_commands_for_both_facings() -> void:
	for id in ["theron", "atalanta", "pyrrhus", "sibyl", "dorian"]:
		var config := MatchConfig.new()
		config.fighter_ids.assign([id, "theron"])
		config.career_styles = true
		config.loadouts = [Loadout.starter(), Loadout.starter()]
		var world := MatchLauncher.make_world(config)
		var f := world.fighters[0]
		assert_true(world.abilities.has(SimAbilities.super_id(f)), "career native power")
		for facing in [-1, 1]:
			f.facing = facing
			var forward := SimInput.LEFT if facing < 0 else SimInput.RIGHT
			var back := SimInput.RIGHT if facing < 0 else SimInput.LEFT
			assert_eq(SimMoveAvailability.select(f, forward | SimInput.DOWN | SimInput.LIGHT, world.body_rules).id, id + "_counter", "new counter command")
			assert_eq(SimMoveAvailability.select(f, back | SimInput.DOWN | SimInput.HEAVY, world.body_rules).id, id + "_breaker", "new breaker command")
		for suffix in ["counter", "breaker"]:
			assert_true(ResourceLoader.exists("res://assets/animations/exported/" + id + "/" + id + "_" + suffix + ".res"), "new baked animation")


func test_grab_enters_paired_states_and_has_authored_clips() -> void:
	var world := MatchLauncher.make_world(MatchConfig.new())
	var a := world.fighters[0]
	var b := world.fighters[1]
	assert_eq(SimMoveAvailability.select(a, PlayerInput.BITS.grab, world.body_rules).id, "grab", "dedicated grab button maps to chord")
	SimMovement._begin_named(world, a, "grab", "arm_l")
	var events: Array = []
	SimCombat._connect(world, a, b, 0, "torso", events)
	assert_eq(a.state, SimFighter.State.GRAB, "attacker hold")
	assert_eq(b.state, SimFighter.State.GRABBED, "victim reaction")
	assert_true(events.any(func(event): return event.kind == SimEvent.Kind.GRAB), "visible grab event")
	for id in ["theron", "atalanta", "pyrrhus", "sibyl", "dorian"]:
		for action in ["grab_hold", "grab_throw", "grabbed"]:
			assert_true(ResourceLoader.exists("res://assets/animations/exported/" + id + "/action_" + action + ".res"), "paired clip exists")


func test_combo_commands_show_current_keys() -> void:
	assert_eq(ComboListMenu._key_command("Down + Forward + Left Punch"), "[S] + [D/A] + [J]", "key chord")
	assert_eq(ComboListMenu._key_command("Grab"), "[G]", "grab key")


func test_new_moves_link_to_finishers() -> void:
	for id in ["theron", "atalanta", "pyrrhus", "sibyl", "dorian"]:
		for suffix in ["counter", "breaker"]:
			var config := MatchConfig.new()
			config.fighter_ids.assign([id, "theron"])
			var world := MatchLauncher.make_world(config)
			var f := world.fighters[0]
			assert_true(SimMovement._begin_named(world, f, id + "_" + suffix, "arm_l"), "new opener starts")
			f.landed_hit = true
			f.hits_done = 1
			f.move_age = f.cancel_start
			f.state = SimFighter.State.RECOVERY
			var finisher := SimMovement._move_row(world, id + "_finisher")
			var mask := SimInput.KICK_RIGHT if finisher.category == "kick" else SimInput.HEAVY
			f.buffer.push(0, world.tick, 8)
			f.buffer.push(mask, world.tick + 1, 8)
			world.tick += 1
			assert_true(SimMovement._try_cancel(world, f, mask), "listed finisher links")
			assert_eq(f.move_name, id + "_finisher", "correct character finisher")


func test_new_power_state_replays_deterministically() -> void:
	var config := MatchConfig.new()
	config.rules["hazards"] = false
	var a := MatchLauncher.make_world(config)
	var b := MatchLauncher.make_world(config)
	for world in [a, b]:
		world.fighters[0].super_charge = 100
		world.fighters[0].x = -250
		world.fighters[1].x = 250
	for tick in 240:
		var mask := SimInput.SUPER if tick == 0 else PlayerInput.BITS.grab if tick == 70 else SimInput.LIGHT if tick % 30 == 0 else 0
		a.step([mask, 0])
		b.step([mask, 0])
		assert_eq(a.snapshot_hash(), b.snapshot_hash(), "new power/grab state remains deterministic")
