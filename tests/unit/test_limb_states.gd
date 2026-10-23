extends TestBase


func test_all_scaled_thresholds() -> void:
	for maximum in [100, 130, 80]:
		for value in range(maximum + 1):
			var limb := SimLimb.new()
			limb.max_integrity = maximum
			limb.integrity = value
			limb.refresh({})
			var percent: int = value * 100 / maximum
			var expected := (
				"healthy" if percent > 50 else ("bruised" if percent >= 26 else "cracked")
			)
			assert_eq(limb.state, expected, "max=%d value=%d" % [maximum, value])


func test_round_preserves_limbs_match_reset_restores_and_career_carries() -> void:
	var world := ProtoFixture.world_with()
	SimSeverance.hit(world, 1, 0, "arm_l", 999, [])
	world._reset_bodies()
	assert_eq(world.fighters[1].limbs.parts["arm_l"].integrity, 0, "round never heals")
	var saved := world.export_limb_state()
	var loaded := ProtoFixture.world_with()
	loaded.setup({"initial_limb_states": saved})
	assert_eq(loaded.fighters[1].limbs.parts["arm_l"].integrity, 0, "pure data restore")
	world.reset_for_match("career")
	assert_eq(world.fighters[1].limbs.parts["arm_l"].integrity, 0, "career persists")
	world.reset_for_match("versus")
	assert_eq(world.fighters[1].limbs.parts["arm_l"].state, "healthy", "versus restores")


func test_cracked_cannot_attack_and_bruised_penalty() -> void:
	var world := ProtoFixture.world_with()
	var fighter := world.fighters[0]
	SimSeverance.hit(world, 0, 1, "arm_l", 110, [])
	world.step([SimInput.LIGHT, 0])
	assert_eq(fighter.move_id, 0, "cracked arm cannot punch")
	SimSeverance.hit(world, 0, 1, "arm_r", 110, [])
	world.step([SimInput.BLOCK, 0])
	assert_true(not fighter.blocking, "two cracked arms cannot block")
	world = ProtoFixture.world_with()
	fighter = world.fighters[0]
	SimSeverance.hit(world, 0, 1, "arm_l", 70, [])
	world.step([SimInput.LIGHT, 0])
	var full := Fx.percent(int(world.moves[0]["damage"]), fighter.power_percent)
	assert_eq(fighter.attack_damage, Fx.percent(full, 90), "bruised deals 90 percent")
