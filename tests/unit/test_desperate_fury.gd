extends TestBase


func test_duration_refresh_and_meter() -> void:
	var world := ProtoFixture.world_with()
	for i in 3:
		SimSeverance.hit(world, 1, 0, "arm_l", 30, [])
	var fighter := world.fighters[1]
	assert_eq(fighter.meter, 30, "thirty percent")
	assert_eq(SimModifier.percent_for(fighter, 359), 115, "active at last tick")
	assert_eq(SimModifier.percent_for(fighter, 360), 100, "expired at end")
	world.tick = 100
	for i in 3:
		SimSeverance.hit(world, 1, 0, "leg_l", 30, [])
	assert_eq(fighter.modifiers.size(), 1, "refresh without stacking")
	assert_eq(fighter.modifiers[0].expires_tick, 460, "refreshes expiry")
	assert_eq(fighter.meter, 60, "second loss fills again")
	assert_eq(SimModifier.percent_for(fighter, 459, true), 120, "speed modifier")


func test_speed_uses_fury_and_expires_during_hitstop() -> void:
	var world := ProtoFixture.world_with()
	var fighter := world.fighters[0]
	SimModifier.fury(fighter, 0, world.limb_rules)
	var start := fighter.x
	world.step([SimInput.LEFT, 0])
	assert_eq(start - fighter.x, Fx.percent(fighter.walk_speed, 120), "speed applied")
	world.tick = 359
	world.hitstop_remaining = 2
	world.step([0, 0])
	assert_eq(SimModifier.percent_for(fighter, world.tick), 100, "simulation clock lifetime")
