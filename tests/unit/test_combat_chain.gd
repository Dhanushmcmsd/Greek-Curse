extends TestBase
## Combo gap, cancel window, and hit-stop.


func test_gap_of_90_continues_and_91_breaks() -> void:
	var chain := ChainRecord.new()
	chain.combo_hits = 2
	chain.last_hit_tick = 10
	chain.note(100, 90, "arm_l", 4)
	assert_eq(chain.combo_hits, 3, "gap of 90 continues")
	assert_eq(chain.limb_damage[0], 4, "limb total")
	chain.note(191, 90, "arm_r", 9)
	assert_eq(chain.combo_hits, 1, "gap of 91 starts a new chain")
	assert_eq(chain.limb_damage[1], 9, "new chain total")
	assert_eq(chain.limb_damage[0], 0, "old limb total cleared")


func test_cancel_window_is_half_open() -> void:
	var world := _pair()
	world.step([SimInput.LIGHT, 0])
	while world.fighters[0].move_age < 10 and world.fighters[0].state != SimFighter.State.IDLE:
		world.step([0, 0])
	assert_eq(world.fighters[0].move_age, 10, "window is open")
	world.step([SimInput.HEAVY, 0])
	assert_eq(world.fighters[0].move_name, "cyclops_smash", "heavy cancel")
	var late := _pair()
	late.step([SimInput.LIGHT, 0])
	while late.fighters[0].move_age < 20 and late.fighters[0].state != SimFighter.State.IDLE:
		late.step([0, 0])
	late.step([SimInput.HEAVY, 0])
	assert_eq(late.fighters[0].move_name, "jab_of_hermes", "cancel has closed")


func test_hitstop_pauses_both_state_timers() -> void:
	var world := _pair()
	world.fighters[0].state = SimFighter.State.STARTUP
	world.fighters[1].state = SimFighter.State.STARTUP
	world.fighters[0].state_tick = 4
	world.fighters[1].state_tick = 7
	world.fighters[0].startup_ticks = 12
	world.fighters[1].startup_ticks = 12
	world.fighters[0].move_age = 4
	world.fighters[1].move_age = 7
	world.hitstop_remaining = 2
	world.step([0, 0])
	world.step([0, 0])
	assert_eq(world.fighters[0].state_tick, 4, "attacker paused")
	assert_eq(world.fighters[1].state_tick, 7, "defender paused")
	assert_eq(world.hitstop_remaining, 0, "freeze ended")
	world.step([0, 0])
	assert_eq(world.fighters[0].move_age, 5, "timers resume together")


func _pair() -> SimWorld:
	var world := ProtoFixture.world_with()
	world.fighters[0].x = 0
	world.fighters[1].x = 430
	return world
