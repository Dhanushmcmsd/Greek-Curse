extends TestBase

const ROSTER = ["theron", "atalanta", "pyrrhus", "sibyl", "dorian"]


func test_full_body_combos_require_their_striking_limbs() -> void:
	for id in ROSTER:
		var config := MatchConfig.new()
		config.fighter_ids.assign([id, "theron"])
		var world := MatchLauncher.make_world(config)
		var fighter := world.fighters[0]
		fighter.limbs.parts["leg_l"].state = "severed"
		var stamina := fighter.stamina
		assert_false(SimMovement._begin_named(world, fighter, id + "_signature", "arm_r"), "no invisible kick " + id)
		assert_eq(fighter.stamina, stamina, "rejected combo costs no stamina")


func test_signature_commands_and_three_registered_hits() -> void:
	for id in ROSTER:
		var config := MatchConfig.new()
		config.fighter_ids.assign([id, "theron"])
		var world := MatchLauncher.make_world(config)
		world.hazards_enabled = false
		var a := world.fighters[0]
		var b := world.fighters[1]
		a.x = -200
		b.x = 200
		b.health = 1000
		var mask := SimInput.RIGHT | (SimInput.DOWN | SimInput.KICK_RIGHT if id == "dorian" else SimInput.HEAVY)
		var choice := SimMoveAvailability.select(a, mask, world.body_rules)
		assert_eq(choice.id, id + "_signature", "signature input " + id)
		assert_true(SimMovement._begin_named(world, a, choice.id, choice.slot), "starts")
		var hits := 0
		for tick in 110:
			for event in world.step([0, 0]):
				if event.kind == SimEvent.Kind.HIT and event.actor == 0:
					hits += 1
		assert_eq(hits, 3, "three actual contacts " + id)


func test_menu_selects_each_fighters_commands() -> void:
	var world := MatchLauncher.make_world(MatchConfig.new())
	var menu := ComboListMenu.new()
	for id in ROSTER:
		menu.populate(world.moves, id)
		assert_eq(menu.selected_fighter, id, "menu selection")
		var found := false
		for label in menu.grid.get_children():
			if label is Label and label.text == ("[S] + [D/A] + [O]" if id == "dorian" else "[D/A] + [K]"):
				found = true
		assert_true(found, "signature is discoverable " + id)
	menu.free()


func test_signature_followups_accept_a_new_button_edge() -> void:
	for id in ROSTER:
		var config := MatchConfig.new()
		config.fighter_ids.assign([id, "theron"])
		var world := MatchLauncher.make_world(config)
		var a := world.fighters[0]
		assert_true(SimMovement._begin_named(world, a, id + "_signature", "arm_r"), "signature")
		a.landed_hit = true
		a.hits_done = 3
		a.move_age = a.cancel_start
		a.state = SimFighter.State.RECOVERY
		var row := SimMovement._move_row(world, id + "_finisher")
		var mask := SimInput.KICK_RIGHT if row.category == "kick" else SimInput.HEAVY
		world.tick = 100
		a.buffer.push(0, 99, 6)
		a.buffer.push(mask, 100, 6)
		assert_true(SimMovement._try_cancel(world, a, mask), "follow-up input " + id)
		assert_eq(a.move_name, id + "_finisher", "correct finisher")


func test_live_signature_and_followup_register_four_hits() -> void:
	for id in ROSTER:
		var config := MatchConfig.new()
		config.fighter_ids.assign([id, "theron"])
		var world := MatchLauncher.make_world(config)
		world.hazards_enabled = false
		var a := world.fighters[0]
		world.fighters[1].health = 1000
		a.x = -200
		world.fighters[1].x = 200
		SimMovement._begin_named(world, a, id + "_signature", "arm_r")
		var row := SimMovement._move_row(world, id + "_finisher")
		var button := SimInput.KICK_RIGHT if row.category == "kick" else SimInput.HEAVY
		var hits := 0
		var pressed := false
		for tick in 130:
			var mask := 0
			if not pressed and a.move_name == id + "_signature" and a.move_age >= a.cancel_start and world.hitstop_remaining == 0:
				mask = button
				pressed = true
			for event in world.step([mask, 0]):
				if event.kind == SimEvent.Kind.HIT and event.actor == 0:
					hits += 1
		assert_eq(hits, 4, "signature plus follow-up lands " + id)


func test_zone_reactions_use_baked_source_and_forward_countdown() -> void:
	for id in ROSTER:
		var config := MatchConfig.new()
		config.fighter_ids.assign([id, "theron"])
		var fighter := MatchLauncher.make_world(config).fighters[0]
		var rig := FighterRig.new()
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		assert_true(rig.load_fighter(id), "rig")
		var driver := PoseDriver.new()
		driver.setup(rig)
		for zone in ["head", "torso", "leg_l"]:
			var action: String = {"head":"hit_head_snap", "torso":"reaction_gut_crumple", "leg_l":"hit_low"}[zone]
			driver.on_hit(zone, false, 1)
			fighter.state = SimFighter.State.HITSTUN
			fighter.state_tick = 24
			driver._drive_clip(fighter, true)
			assert_eq(driver.current_action_name, action, id + " zone")
			assert_true(ResourceLoader.exists("res://assets/animations/exported/" + id + "/action_" + action + ".res"), "source reaction")
			assert_near(rig.anim_player.current_animation_position, 0, 0.001, "initial impact")
			fighter.state_tick = 18
			driver._drive_clip(fighter, false)
			assert_near(rig.anim_player.current_animation_position, 0.1, 0.001, "forward time")
			driver._drive_clip(fighter, true)
			assert_near(rig.anim_player.current_animation_position, 0.1, 0.001, "freeze")
		rig.free()
