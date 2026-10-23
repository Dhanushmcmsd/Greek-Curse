extends TestBase


func test_cap_from_data() -> void:
	for cap in [1, 2, 3]:
		var world := ProtoFixture.world_with()
		world.limb_rules["limb_cap"] = cap
		for slot in SimLimbs.LIMB_NAMES:
			for i in 3:
				SimSeverance.hit(world, 1, 0, slot, 40, [])
		assert_eq(world.amputations.size(), cap, "data cap")
		assert_true(world.fighters[1].limbs.parts["leg_r"].cap_blocked, "last limb blocked")
		assert_eq(world.fighters[1].limbs.parts["leg_r"].state, "cracked", "cap keeps attached")


func test_random_chains_are_bounded_and_deterministic() -> void:
	var random := SimRng.new(327)
	for trial in 30:
		var a := ProtoFixture.world_with()
		var b := ProtoFixture.world_with()
		for i in 100:
			var gap := random.range_i(0, 120)
			var zone: String = SimLimbs.LIMB_NAMES[random.range_i(0, 4)]
			var damage := random.range_i(0, 100)
			for world in [a, b]:
				world.tick += gap
				SimSeverance.hit(world, 1, 0, zone, damage, [])
			assert_eq(a.hash_state(), b.hash_state(), "paired hash")
			assert_true(a.amputations.size() <= 2, "cap invariant")
			for limb in a.fighters[1].limbs.parts.values():
				assert_true(limb.integrity >= 0, "nonnegative")
