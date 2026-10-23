extends TestBase


func test_all_masks_move_and_have_an_attack() -> void:
	var expected := [
		"full",
		"one_arm",
		"one_arm",
		"no_arms",
		"one_leg",
		"one_leg",
		"one_leg",
		"torso_mode",
		"one_leg",
		"one_leg",
		"one_leg",
		"torso_mode",
		"no_legs",
		"torso_mode",
		"torso_mode",
		"torso_mode"
	]
	for mask in 16:
		var world := ProtoFixture.world_with()
		var fighter := world.fighters[0]
		SimBodyState.apply_mask(fighter, mask)
		assert_eq(SimBodyState.derive(fighter.limbs)["profile"], expected[mask], "mask %d" % mask)
		var start := fighter.x
		world.step([SimInput.LEFT, 0])
		assert_true(fighter.x < start, "mask moves %d" % mask)
		var count := 0
		for input in [16, 32, 64, 18, 34, 72, 80]:
			if not SimMoveAvailability.select(fighter, input, world.body_rules).is_empty():
				count += 1
		assert_true(count > 0, "mask attacks %d" % mask)


func test_cracked_is_present_and_direction_selects_side() -> void:
	var world := ProtoFixture.world_with()
	var fighter := world.fighters[0]
	fighter.limbs.apply_limb_damage("arm_l", 130)
	assert_eq(SimBodyState.derive(fighter.limbs)["profile"], "full", "cracked is present")
	assert_true(
		SimMoveAvailability.select(fighter, 16, world.body_rules).is_empty(), "left disabled"
	)
	assert_eq(
		SimMoveAvailability.select(fighter, 18, world.body_rules)["slot"], "arm_r", "forward right"
	)
	fighter.facing = -1
	assert_eq(
		SimMoveAvailability.select(fighter, 17, world.body_rules)["slot"],
		"arm_r",
		"facing relative"
	)


func test_crawl_and_torso_attacks_connect() -> void:
	for mask in [3, 12, 15]:
		var world := ProtoFixture.world_with()
		world.fighters[0].x = 0
		world.fighters[1].x = 450
		SimBodyState.apply_mask(world.fighters[0], mask)
		var attack := SimInput.KICK if mask == 12 else SimInput.LIGHT
		for tick in 60:
			world.step([attack, 0])
		assert_true(world.fighters[1].health < 300, "body hit %d" % mask)


func test_hop_dodge_and_transition_stay_bounded() -> void:
	var world := ProtoFixture.world_with()
	var fighter := world.fighters[0]
	SimBodyState.apply_mask(fighter, 4)
	var x := fighter.x
	world.step([SimInput.DODGE | SimInput.LEFT, 0])
	assert_eq(x - fighter.x, 28, "70 percent dodge speed")
	assert_eq(fighter.pose, "hop", "hop profile")
	for mask in 16:
		SimBodyState.apply_mask(fighter, mask)
		for i in 30:
			world.step([SimInput.LEFT, 0])
		assert_true(fighter.x >= world._low(fighter), "wall clamp")
