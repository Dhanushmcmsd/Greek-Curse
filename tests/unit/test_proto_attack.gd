extends TestBase
## Startup, one hit per swing, and integer damage for the three starter moves.


func test_jab_active_window_and_single_hit() -> void:
	var world := _touching()
	var move := ProtoFixture.move_dict("res://data/moves/jab_of_hermes.json")
	var startup := int(move["startup_ticks"])
	var expected := Fx.percent(int(move["damage"]), world.fighters[0].power_percent)
	assert_eq(expected, 21, "theron jab damage")
	for _i in startup:
		world.step([SimInput.LIGHT, 0])
		assert_eq(world.fighters[0].state, SimFighter.State.STARTUP, "startup")
		assert_eq(world.fighters[1].health, 300, "no early hit")
	world.step([0, 0])
	assert_eq(world.fighters[0].state, SimFighter.State.ACTIVE, "active starts")
	assert_eq(world.fighters[1].health, 300 - expected, "one hit")
	world.step([0, 0])
	assert_eq(world.fighters[0].state, SimFighter.State.ACTIVE, "second active frame")
	assert_eq(world.fighters[1].health, 300 - expected, "no second hit")


func test_heavy_and_kick_use_their_own_damage() -> void:
	var heavy := ProtoFixture.move_dict("res://data/moves/cyclops_smash.json")
	var kick := ProtoFixture.move_dict("res://data/moves/pegasus_kick.json")
	var world := _touching()
	assert_eq(Fx.percent(int(heavy["damage"]), 130), 47, "smash multiplier")
	assert_eq(Fx.percent(int(kick["damage"]), 130), 29, "kick multiplier")
	_hold(world, SimInput.HEAVY, int(heavy["startup_ticks"]))
	assert_eq(world.fighters[1].health, 300 - 47, "smash hit")
	world = _touching()
	_hold(world, SimInput.KICK, int(kick["startup_ticks"]))
	assert_eq(world.fighters[1].health, 300 - 29, "kick hit")
	assert_true(world.fighters[0].x != 0, "kick hop moved the attacker")


func _touching() -> SimWorld:
	var world := ProtoFixture.world_with()
	world.fighters[0].x = 0
	world.fighters[1].x = 430
	world.fighters[0].facing = 1
	world.fighters[1].facing = -1
	return world


func _hold(world: SimWorld, button: int, startup: int) -> void:
	for _i in startup:
		world.step([button, 0])
	world.step([0, 0])
