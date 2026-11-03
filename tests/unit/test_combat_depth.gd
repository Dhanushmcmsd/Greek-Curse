extends TestBase


func test_leg_fractures_change_support_and_match_cap_stops_further_loss() -> void:
	var world := ProtoFixture.world_with()
	var fighter := world.fighters[1]
	for slot in ["arm_l", "arm_r", "leg_l", "leg_r"]:
		for hit in 3:
			SimSeverance.hit(world, 1, 0, slot, 100, [])
		assert_eq(
			fighter.limbs.parts[slot].state,
			"severed" if slot == "arm_l" else "cracked",
			"one match sever cap: " + slot
		)
	assert_eq(fighter.limbs.losses, 1, "one loss per match by default")
	world = ProtoFixture.world_with()
	fighter = world.fighters[0]
	fighter.limbs.apply_limb_damage("leg_l", 130)
	world.step([0, 0])
	assert_eq(fighter.pose, "hop", "one fractured leg cannot bear weight")
	fighter.limbs.apply_limb_damage("leg_r", 130)
	world.step([0, 0])
	assert_eq(fighter.pose, "crawl", "two fractured legs require crawling")


func test_hit_spacing_and_wall_escape_gap() -> void:
	for at_wall in [false, true]:
		var world := ProtoFixture.world_with()
		var attacker := world.fighters[0]
		var defender := world.fighters[1]
		defender.x = world._high(defender) if at_wall else 430
		attacker.x = defender.x - 430
		attacker.attack_knockback = 400
		attacker.attack_hit_count = 1
		var gap := defender.x - attacker.x
		SimCombat._push(world, defender, attacker, false)
		assert_true(defender.x - attacker.x >= gap + 300, "impact creates space even at wall")
		assert_true(defender.x <= world._high(defender), "defender stays in arena")
		assert_true(attacker.x >= world._low(attacker), "attacker stays in arena")


func test_landed_lunge_does_not_cancel_spacing() -> void:
	var world := ProtoFixture.world_with()
	var fighter := world.fighters[0]
	var move: Dictionary = DataLoader.new().load_json("res://data/moves/sweeping_hydra.json").value
	fighter.begin_move(1, move, 8, 8)
	fighter.landed_hit = true
	fighter.move_age = fighter.startup_ticks + fighter.active_ticks
	var x := fighter.x
	SimMovement.advance(world, fighter, 0)
	assert_eq(fighter.x, x, "recovery does not chase defender after landing")


func test_distinct_moves_and_crawl_clip_play_on_real_rig() -> void:
	var world := ProtoFixture.world_with()
	var fighter := world.fighters[0]
	var rig := FighterRig.new()
	rig.load_fighter("theron")
	(Engine.get_main_loop() as SceneTree).root.add_child(rig)
	var driver := PoseDriver.new()
	driver.setup(rig)
	var sources := {}
	for action in driver.pack_map.fighters.theron.actions:
		if not str(action).begins_with("move_"):
			continue
		var id := str(action).trim_prefix("move_")
		var move: Dictionary = driver.moves[id]
		fighter.begin_move(1, move, 10, 10)
		fighter.attack_slot = str(move.limb_side)
		fighter.state = SimFighter.State.ACTIVE
		fighter.state_tick = fighter.startup_ticks
		driver.update(fighter)
		assert_eq(driver.current_action_name, action, "specific move binding " + id)
		assert_true(driver.current_clip_id != "", "real source motion " + id)
		sources[id] = true
		var arm := rig.skeleton.find_bone("upper_arm.r")
		var before := rig.skeleton.get_bone_pose_rotation(arm)
		driver.update(fighter, true)
		assert_true(
			before.is_equal_approx(rig.skeleton.get_bone_pose_rotation(arm)),
			"hitstop preserves mirrored strike"
		)
	assert_true(sources.size() >= 20, "basic attacks and directional combos mapped")
	fighter.clear_move()
	SimBodyState.apply_mask(fighter, 12)
	fighter.pose = "crawl"
	fighter.state = SimFighter.State.WALK
	driver.update(fighter)
	assert_eq(driver.current_action_name, "crawl", "actual crawling clip is enabled")
	var time := rig.anim_player.current_animation_position
	driver.update(fighter)
	assert_true(rig.anim_player.current_animation_position > time, "crawl animates while moving")
	rig.free()


func test_defender_can_guard_after_hit_against_stationary_pressure() -> void:
	var world := ProtoFixture.world_with()
	world.fighters[0].x = 0
	world.fighters[1].x = 430
	var landed := false
	for tick in 30:
		for event in world.step([SimInput.LIGHT, 0]):
			landed = landed or event.kind == SimEvent.Kind.HIT
		if landed:
			break
	assert_true(landed, "initial hit connects")
	var guarded := false
	for tick in 40:
		world.step([SimInput.LIGHT, SimInput.BLOCK])
		guarded = guarded or world.fighters[1].blocking
	assert_true(guarded, "defender regains control to guard after impact")
