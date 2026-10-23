extends TestBase


func test_three_hits_at_90_and_gap_91() -> void:
	for gap in [90, 91]:
		var world := ProtoFixture.world_with()
		for i in 3:
			world.tick = i * gap
			SimSeverance.hit(world, 1, 0, "arm_l", 30, [])
		var limb: SimLimb = world.fighters[1].limbs.parts["arm_l"]
		assert_eq(limb.state, "severed" if gap == 90 else "cracked", "gap %d" % gap)


func test_two_hits_zero_then_next_same_limb() -> void:
	var world := ProtoFixture.world_with()
	SimSeverance.hit(world, 1, 0, "arm_l", 45, [])
	SimSeverance.hit(world, 1, 0, "arm_l", 45, [])
	var limb: SimLimb = world.fighters[1].limbs.parts["arm_l"]
	assert_eq(limb.state, "cracked", "two hits not a severance combo")
	assert_true(limb.zero_pending, "zero pending")
	world.tick = 200
	SimSeverance.hit(world, 1, 0, "leg_l", 1, [])
	assert_eq(limb.state, "cracked", "different limb cannot consume pending")
	world.tick = 400
	SimSeverance.hit(world, 1, 0, "arm_l", 1, [])
	assert_eq(limb.state, "severed", "next same limb hit even outside chain")


func test_grace_exactly_30_not_31() -> void:
	for gap in [30, 31]:
		var world := ProtoFixture.world_with()
		for i in 3:
			world.tick = i
			SimSeverance.hit(world, 1, 0, "torso", 0, [])
		world.fighters[1].limbs.apply_limb_damage("arm_l", 50)
		world.tick = 2 + gap
		SimSeverance.hit(world, 1, 0, "arm_l", 999, [], false)
		assert_eq(
			world.fighters[1].limbs.parts["arm_l"].state,
			"severed" if gap == 30 else "cracked",
			"grace %d" % gap
		)


func test_head_never_severs_and_severed_hurtbox_disappears() -> void:
	var world := ProtoFixture.world_with()
	for i in 5:
		SimSeverance.hit(world, 1, 0, "head", 999, [])
	assert_eq(world.amputations.size(), 0, "head has no integrity")
	SimSeverance.hit(world, 1, 0, "arm_l", 999, [])
	assert_eq(world.amputations.size(), 0, "healthy limb cannot sever in one hit")
	SimSeverance.hit(world, 1, 0, "arm_l", 1, [])
	var boxes := world.fighters[1].limbs.world_boxes(0, 0, 400, 1780, "standing")
	for box in boxes:
		assert_true(box["name"] != "arm_l", "removed limb is not targetable")
