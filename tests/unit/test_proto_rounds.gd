extends TestBase
## KO, timeout, draw replay, and best of three.

var _last_events: Array = []


func test_ko_ends_the_round_and_two_wins_end_the_match() -> void:
	var world := ProtoFixture.world_with()
	_force_ko(world)
	assert_eq(world.wins[0], 1, "first round")
	assert_eq(world.phase, SimWorld.PHASE_FIGHTING, "match continues")
	assert_eq(world.fighters[1].health, world.max_health, "next round health")
	var saw_match := false
	_force_ko(world)
	for event in _last_events:
		if event.kind == SimEvent.Kind.MATCH_END:
			saw_match = true
			assert_eq(event.winner, 0, "theron wins the match")
	assert_true(saw_match, "match end event")
	assert_eq(world.wins[0], 2, "two round wins")
	assert_eq(world.phase, SimWorld.PHASE_MATCH_OVER, "match over")


func test_timeout_gives_the_higher_health_the_round() -> void:
	var world := ProtoFixture.world_with({"round_ticks": 2})
	world.fighters[0].health = 200
	world.fighters[1].health = 100
	world.step([0, 0])
	var events := world.step([0, 0])
	var ended := false
	for event in events:
		if event.kind == SimEvent.Kind.ROUND_END:
			ended = true
			assert_eq(event.winner, 0, "higher health")
	assert_true(ended, "timeout round end")


func test_tied_timeout_replays_once_then_uses_the_rng() -> void:
	var world := ProtoFixture.world_with({"round_ticks": 3})
	for _i in 3:
		world.step([0, 0])
	assert_eq(world.wins[0] + world.wins[1], 0, "draw is not a win")
	assert_eq(world.draw_uses, 1, "one replay spent")
	assert_eq(world.round_tick, 0, "replay started")
	world.wins[1] = 1
	for _i in 3:
		world.step([0, 0])
	assert_eq(world.wins[1], 2, "seed 1 coin picks fighter 1")
	assert_eq(world.phase, SimWorld.PHASE_MATCH_OVER, "coin can end the match")


func _force_ko(world: SimWorld) -> void:
	world.fighters[0].x = 0
	world.fighters[1].x = 430
	world.fighters[1].health = 1
	world.fighters[0].state = SimFighter.State.IDLE
	world.fighters[0].clear_move()
	var move := ProtoFixture.move_dict("res://data/moves/jab_of_hermes.json")
	for _i in int(move["startup_ticks"]):
		world.step([SimInput.LIGHT, 0])
	_last_events = world.step([0, 0])
